from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

from prepare import prepare


def get_pkg_file(path: Path) -> Path | None:
    """Find the package config file (moon.pkg.json or moon.pkg)."""
    if (path / "moon.pkg.json").exists():
        return path / "moon.pkg.json"
    if (path / "moon.pkg").exists():
        return path / "moon.pkg"
    return None


def collect_package(path: Path) -> list[Path]:
    if path.name == ".mooncakes":
        return []
    if (path / "moon.mod").exists():
        return []
    if get_pkg_file(path) is not None:
        pkgs = [path]
        for entry in path.iterdir():
            if entry.is_dir():
                pkgs.extend(collect_package(entry))
        return pkgs
    return []


def find_balanced_end(text: str, start: int) -> int:
    """Starting from an opening bracket/brace at `start`, find the position
    after the matching closing bracket/brace, handling nesting and strings."""
    openers = {"[", "{"}
    closer_of = {"]": "[", "}": "{"}
    stack = [text[start]]
    i = start + 1
    while i < len(text) and stack:
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                if text[i] == "\\":
                    i += 1
                i += 1
        elif c in openers:
            stack.append(c)
        elif c in closer_of:
            if stack and stack[-1] == closer_of[c]:
                stack.pop()
        i += 1
    return i


def transform_moon_pkg(content: str) -> tuple[str, list[str] | None]:
    """Transform a moon.pkg file for publishing.

    Removes test imports and pre-build option.
    Returns (transformed_content, native_stub_files_or_none).
    """
    # Extract native-stub value before modifying
    native_stub = None
    m = re.search(r'"native-stub"\s*:\s*\[([^\]]*)\]', content)
    if m:
        native_stub = re.findall(r'"([^"]*)"', m.group(1))

    # Remove test import blocks: `import { ... } for "test"`
    content = re.sub(
        r"\nimport\s*\{[^}]*\}\s*for\s*\"test\"\s*\n?",
        "\n",
        content,
    )

    # Remove pre-build from options
    m = re.search(r'"pre-build"\s*:\s*[\[\{]', content)
    if m:
        # Find start of the line containing "pre-build"
        line_start = content.rfind("\n", 0, m.start()) + 1
        # Find the value (the [ or {)
        value_start = m.end() - 1
        value_end = find_balanced_end(content, value_start)
        # Skip trailing comma and whitespace
        end = value_end
        while end < len(content) and content[end] in " \t":
            end += 1
        if end < len(content) and content[end] == ",":
            end += 1
        if end < len(content) and content[end] == "\n":
            end += 1
        content = content[:line_start] + content[end:]

    # Clean up multiple blank lines
    content = re.sub(r"\n{3,}", "\n\n", content)

    return content, native_stub


def transform_moon_pkg_json(content: str) -> tuple[str, list[str] | None]:
    """Transform a moon.pkg.json file for publishing."""
    data = json.loads(content)
    data.pop("pre-build", None)
    data.pop("test-import", None)
    native_stub = data.get("native-stub")
    result = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    return result, native_stub


def copy_source(src: Path, dst: Path):
    pkgs: list[Path] = collect_package(src)
    for pkg in pkgs:
        print(f"Copying package {pkg}")
        pkg_file = get_pkg_file(pkg)
        assert pkg_file is not None

        content = pkg_file.read_text(encoding="utf-8")
        if pkg_file.name == "moon.pkg.json":
            transformed, native_stub = transform_moon_pkg_json(content)
        else:
            transformed, native_stub = transform_moon_pkg(content)

        dst_pkg = dst / pkg
        dst_pkg.mkdir(parents=True, exist_ok=True)
        (dst_pkg / pkg_file.name).write_text(transformed, encoding="utf-8")

        for file in pkg.iterdir():
            if not file.is_file():
                continue
            if file.name in ("moon.pkg.json", "moon.pkg"):
                continue
            if file.name.startswith("tree-sitter#"):
                # Regenerate the flattened tree-sitter sources for the release.
                continue
            if ".c" in file.suffixes or ".h" in file.suffixes:
                shutil.copy(file, dst_pkg / file.name)
                continue
            if ".mbt" in file.suffixes:
                if file.stem.endswith("_test"):
                    continue
                else:
                    shutil.copy(file, dst / file)


def prepare_main(publish_path: Path):
    """Prepare the main module (tonyfettes/tree_sitter) for publishing."""
    manifest = Path("moon.mod").read_text(encoding="utf-8")
    # Grammar modules are used only by tests; retain the shared language type.
    manifest = re.sub(
        r'^[ \t]*"tonyfettes/tree_sitter_(?!language@)[^"\n]+",?[ \t]*\n',
        "",
        manifest,
        flags=re.MULTILINE,
    )
    (publish_path / "moon.mod").write_text(manifest, encoding="utf-8")
    shutil.copy("README.md", publish_path / "README.md")
    shutil.copy("LICENSE", publish_path / "LICENSE")
    copy_source(Path("src"), publish_path)
    prepare(publish_path / "src")


def publish_main(command: list[str]):
    """Prepare and publish the main module (tonyfettes/tree_sitter)."""
    # A staging directory under the checkout inherits its packaging ignore rules.
    with TemporaryDirectory(prefix="tree-sitter-publish-") as folder:
        publish_path = Path(folder)
        prepare_main(publish_path)
        subprocess.run(command, cwd=publish_path, check=True)


def publish_language(command: list[str]):
    """Publish the language definition (tonyfettes/tree_sitter_language)."""
    language_path = Path("src", "language")
    subprocess.run(command, cwd=language_path, check=True)


def publish_languages(command: list[str]):
    """Publish all generated language bindings."""
    languages_path = Path("src", "languages")
    failed = []
    for lang_dir in sorted(languages_path.iterdir()):
        if not lang_dir.is_dir():
            continue
        if not (lang_dir / "moon.mod").exists():
            continue
        print(f"Processing {lang_dir.name}", flush=True)
        try:
            subprocess.run(
                command, cwd=lang_dir, check=True, capture_output=True, text=True
            )
        except subprocess.CalledProcessError as e:
            print(e.stdout + e.stderr, flush=True)
            failed.append(lang_dir.name)
    if failed:
        raise SystemExit(f"Grammar package checks failed: {', '.join(failed)}")


def main():
    parser = argparse.ArgumentParser(
        description="Publish tree-sitter MoonBit packages"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate the package with Mooncakes without publishing it.",
    )
    parser.add_argument(
        "target",
        nargs="*",
        help="What to publish: language, languages, or main (default: all)",
    )
    args = parser.parse_args()

    all_targets = ("language", "languages", "main")
    targets = args.target or all_targets
    for target in targets:
        if target not in all_targets:
            parser.error(f"unknown target {target!r}; choose from {', '.join(all_targets)}")
    command = ["moon", "publish"]
    if args.dry_run:
        command.append("--dry-run")
    if "language" in targets:
        publish_language(command)
    if "languages" in targets:
        publish_languages(command)
    if "main" in targets:
        publish_main(command)


if __name__ == "__main__":
    main()
