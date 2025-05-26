import shutil
from pathlib import Path
import json
import subprocess


def collect_package(path: Path) -> list[str]:
    if path.name == ".mooncakes":
        return []
    if (path / "moon.mod.json").exists():
        return []
    if (path / "moon.pkg.json").exists():
        pkgs = [path]
        for entry in path.iterdir():
            if entry.is_dir():
                pkgs.extend(collect_package(entry))
        return pkgs
    return []


def copy_source(src: Path, dst: Path):
    pkgs: list[Path] = collect_package(src)
    for pkg in pkgs:
        print(f"Copying package {pkg}")
        moon_pkg_json = json.loads((pkg / "moon.pkg.json").read_text())
        if "pre-build" in moon_pkg_json:
            moon_pkg_json.pop("pre-build")
        if "test-import" in moon_pkg_json:
            moon_pkg_json.pop("test-import")
        dst_pkg = dst / pkg
        dst_pkg.mkdir(parents=True, exist_ok=True)
        (dst_pkg / "moon.pkg.json").write_text(
            json.dumps(moon_pkg_json, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        native_stub = (
            moon_pkg_json["native-stub"] if "native-stub" in moon_pkg_json else None
        )
        for file in pkg.iterdir():
            if not file.is_file():
                continue
            if file.name == "moon.pkg.json":
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
    shutil.rmtree(publish_path / ".mooncakes")
    shutil.rmtree(publish_path / "target")


if __name__ == "__main__":
    main()
