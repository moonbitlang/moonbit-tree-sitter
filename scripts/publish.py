import re
import shutil
from pathlib import Path
import json
import subprocess


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
    if (path / "moon.mod.json").exists():
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
            if ".c" in file.suffixes or ".h" in file.suffixes:
                shutil.copy(file, dst_pkg / file.name)
                continue
            if ".mbt" in file.suffixes:
                if file.stem.endswith("_test"):
                    continue
                else:
                    shutil.copy(file, dst / file)


def main():
    publish_path = Path("publish")
    if publish_path.exists():
        shutil.rmtree("publish")

    publish_path.mkdir()
    moon_mod_json = json.loads(Path("moon.mod.json").read_text())
    clean_deps = {}
    for name, spec in moon_mod_json.get("deps", {}).items():
        if (
            name.startswith("tonyfettes/tree_sitter_")
            and name != "tonyfettes/tree_sitter_language"
        ):
            continue
        clean_deps[name] = spec
    moon_mod_json["deps"] = clean_deps
    (publish_path / "moon.mod.json").write_text(
        json.dumps(
            moon_mod_json,
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )
    shutil.copy("README.md", publish_path / "README.md")
    shutil.copy("LICENSE", publish_path / "LICENSE")
    copy_source(Path("src"), publish_path)

    subprocess.run(
        ["moon", "check", "--target", "native"], cwd=publish_path, check=True
    )
    for d in [".mooncakes", "target", "_build"]:
        p = publish_path / d
        if p.exists():
            shutil.rmtree(p)


if __name__ == "__main__":
    main()
