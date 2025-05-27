import json
from pathlib import Path
import subprocess
import shutil
import os
import re
import argparse
import concurrent.futures
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


MOON_HOME = os.getenv("MOON_HOME", None)
if MOON_HOME is None:
    MOON_HOME = Path.home() / ".moon"
else:
    MOON_HOME = Path(MOON_HOME)
VERSION = "0.1.16"


include_directories = [
    (Path(".") / "bindings" / "tinycc" / "include").absolute(),
]


class Metadata:
    version: str
    license: str
    description: str
    repository: str
    commit: str

    def __init__(
        self,
        version: str,
        license: str,
        description: str,
        repository: str,
        commit: str,
    ):
        self.version = version
        self.license = license
        self.description = description
        self.repository = repository
        self.commit = commit


class Grammar:
    metadata: Metadata
    name: str
    scope: str
    path: Path
    stubs: list[str]
    files: list[str]
    external_files: list[Path]
    file_types: list[str]

    def __init__(
        self,
        name: str,
        path: Path,
        metadata: Metadata,
        external_files: list[Path] = [],
        file_types: list[Path] = [],
    ):
        self.name = name
        self.path = path
        self.metadata = metadata
        self.stubs = []
        self.files = []
        src_path = path / "src"
        for file in src_path.iterdir():
            if file.suffix == ".c":
                self.stubs.append(str(file.relative_to(src_path)))
            self.files.append(str(file.relative_to(src_path)))
        self.stubs.sort()
        self.files.sort()
        self.external_files = external_files
        self.file_types = file_types

    def tree_sitter_generate(self):
        subprocess.run(
            ["tree-sitter", "generate"], cwd=self.path, check=True, capture_output=True
        )

    def tree_sitter_build_wasm(self):
        subprocess.run(
            ["tree-sitter", "build", "--wasm"],
            cwd=self.path,
            check=True,
            capture_output=True,
        )
        return list(self.path.glob("*.wasm"))[0]

    def generate_gitignore_to(self, destination: Path):
        content = "\n".join(self.files) + "\n"
        destination.write_text(content)

    def generate_moon_mod_json_to(self, destination: Path, version: str, wasm: str):
        moon_mod_json = {
            "name": f"tonyfettes/tree_sitter_{self.name}",
            "version": version,
            "deps": {
                "tonyfettes/tree_sitter_language": "0.1.1",
            },
            "repository": self.metadata.repository,
            "license": "Apache-2.0",
            "include": self.files + ["binding.mbt", "moon.pkg.json", wasm],
        }
        destination.write_text(json.dumps(moon_mod_json, indent=2) + "\n")

    def generate_moon_pkg_json_to(self, destination: Path):
        moon_pkg_json = {
            "import": ["tonyfettes/tree_sitter_language"],
            "targets": {"binding.mbt": ["native"]},
            "native_stub": self.stubs,
            "support-targets": ["native"],
        }
        destination.write_text(json.dumps(moon_pkg_json, indent=2) + "\n")

    def generate_binding_native_mbt_to(self, parser: Path, destination: Path):
        logger.info(f"Parsing function name from {parser}")
        function_name_regex = re.compile(
            r"TS_PUBLIC\s+const\s+TSLanguage\s*\*\s*(\w+)\(void\)\s+"
        )
        parser_source = parser.read_text()
        function_name_match = function_name_regex.search(parser_source)
        function_name = function_name_match.group(1)
        content = f"""///|
pub extern "c" fn language() -> @tree_sitter_language.Language = "{function_name}"
"""
        destination.write_text(content)

    def perform_c_include_to(
        self, destination: Path, file: Path, relocations: dict[Path, Path] = {}
    ):
        system_include_pattern = re.compile(r"#\s*include\s+<([^>]+)>")
        relative_include_pattern = re.compile(r"#\s*include\s+\"([^\"]+)\"")
        already_included: set[Path] = set()

        def read_file(file: Path) -> list[str]:
            return file.read_text().splitlines()

        def try_include(include_path: str) -> list[str]:
            for include_dir in include_directories:
                include_file = include_dir / include_path
                if include_file.exists():
                    if include_file in already_included:
                        return []
                    already_included.add(include_file)
                    return include_file.read_text().splitlines()
            raise FileNotFoundError(f"Could not find include file {include_path}")

        def process_file(lines: list[str]):
            expanded_lines: list[str] = []
            for line in lines:
                match = relative_include_pattern.match(line)
                if match:
                    if match.group(1):
                        include_file = match.group(1)
                        include_file_in_grammar = (
                            (self.path / "src" / include_file)
                            .resolve()
                            .relative_to(Path.cwd())
                        )
                        if include_file_in_grammar in relocations:
                            mangled_file = relocations[include_file_in_grammar]
                            expanded_lines.append(
                                f'#include "{mangled_file.relative_to(destination)}"'
                            )
                        else:
                            expanded_lines.append(line)
                    else:
                        expanded_lines.append(line)
                    continue
                match = system_include_pattern.match(line)
                if match:
                    try:
                        included_lines = try_include(match.group(1))
                        expanded_lines.extend(
                            ["#ifdef __TINYC__"]
                            + process_file(included_lines)
                            + ["#else", line, "#endif"]
                        )
                    except FileNotFoundError:
                        expanded_lines.append(line)
                else:
                    expanded_lines.append(line)
            return expanded_lines

        original_lines = read_file(destination / file)
        expanded_lines = process_file(original_lines)
        (destination / file).write_text("\n".join(expanded_lines))

    def generate_binding_to(self, destination: Path):
        self.tree_sitter_generate()
        version: str = VERSION
        if destination.exists():
            if (destination / "moon.mod.json").exists():
                moon_mod_json = json.loads((destination / "moon.mod.json").read_text())
                if "version" in moon_mod_json:
                    version = moon_mod_json["version"]
            shutil.rmtree(destination)
        shutil.copytree(self.path / "src", destination)
        relocations = {}
        for file in self.external_files:
            shutil.copyfile(file, destination / file.name)
            relocations[file] = destination / file.name
        for file in destination.rglob("*.h"):
            self.perform_c_include_to(
                destination, file.relative_to(destination), relocations
            )
        for file in destination.rglob("*.c"):
            self.perform_c_include_to(
                destination, file.relative_to(destination), relocations
            )
        wasm_path = self.tree_sitter_build_wasm()
        shutil.copyfile(wasm_path, destination / wasm_path.name)
        self.generate_binding_native_mbt_to(
            destination / "parser.c", destination / "binding.mbt"
        )
        self.generate_gitignore_to(destination / ".gitignore")
        self.generate_moon_mod_json_to(
            destination / "moon.mod.json", version, wasm=wasm_path.name
        )
        self.generate_moon_pkg_json_to(destination / "moon.pkg.json")


def git_submodule_url(path: Path) -> str:
    try:
        url = subprocess.run(
            ["git", "config", f"submodule.{path}.url"],
            capture_output=True,
            check=True,
            text=True,
        )
        url = url.stdout.strip()
    except subprocess.CalledProcessError:
        raise ValueError(f"Could not find submodule URL for {path}")
    return url


def git_submodule_commit(path: Path) -> str:
    try:
        commit = subprocess.run(
            ["git", "submodule", "status", path],
            capture_output=True,
            check=True,
            text=True,
        )
        commit = commit.stdout.strip().split(" ")[0]
    except Exception as e:
        raise ValueError(f"Could not get commit hash for {path}: {e}")

    return commit


def git_clean(path: Path):
    try:
        subprocess.run(
            ["git", "clean", "-fd"],
            cwd=path,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "clean", "-fdX"],
            cwd=path,
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["git", "reset", "--hard"],
            cwd=path,
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to clean git repository at {path}: {e}")


def generate_binding(project: Path, bindings: Path):
    if not project.exists():
        raise FileNotFoundError(f"{project} does not exist")

    try:
        tree_sitter_path = project / "tree-sitter.json"
        if not tree_sitter_path.exists():
            raise FileNotFoundError(f"{tree_sitter_path} does not exist")
        if (project / "package.json").exists():
            logger.info(f"Installing npm dependencies for {project}")
            try:
                subprocess.run(
                    ["npm", "install"], cwd=project, check=True, capture_output=True
                )
            except subprocess.CalledProcessError as e:
                pass
        tree_sitter_dict = json.loads(tree_sitter_path.read_text())
        metadata_dict = tree_sitter_dict["metadata"]
        metadata_links_dict = metadata_dict["links"]
        submodule_commit = git_submodule_commit(project)
        metadata = Metadata(
            version=metadata_dict["version"],
            license=metadata_dict["license"],
            description=metadata_dict["description"],
            repository=metadata_links_dict["repository"],
            commit=submodule_commit,
        )
        grammars = tree_sitter_dict["grammars"]
        for grammar_dict in grammars:
            grammar_name = grammar_dict["name"]
            grammar_path = "."
            if "path" in grammar_dict:
                grammar_path = grammar_dict["path"]
            grammar_path: Path = project / grammar_path
            grammar_external_files = []
            for external_file in (
                grammar_dict["external-files"]
                if "external-files" in grammar_dict
                else []
            ):
                external_file_path: Path = project / external_file
                if not external_file_path.exists():
                    raise FileNotFoundError(
                        f"{external_file_path} does not exist, but is listed in tree-sitter.json"
                    )
                grammar_external_files.append(external_file_path)
            grammar_dict = Grammar(
                name=grammar_name,
                path=grammar_path,
                external_files=grammar_external_files,
                file_types=(
                    grammar_dict["file-types"] if "file-types" in grammar_dict else []
                ),
                metadata=metadata,
            )
            binding_root: Path = (bindings / f"tree_sitter_{grammar_name}").resolve()
            logger.info(f"Generating binding for {grammar_name}")
            grammar_dict.generate_binding_to(binding_root)

            logger.info(f"Building binding for {grammar_name}")
            subprocess.run(
                ["moon", "build", "--target", "native"],
                cwd=binding_root,
                check=True,
                capture_output=True,
            )
    except Exception as e:
        logger.error(f"Error generating binding for {project}: {e}")
        raise e
    finally:
        logger.info(f"Finished generating binding for {grammar_name}, cleaning")
        git_clean(project)


def main():
    parser = argparse.ArgumentParser(
        description="Generate bindings for tree-sitter grammars"
    )
    parser.add_argument(
        "path",
        type=Path,
        nargs="*",  # accept multiple paths
        default=None,
        help="Path to the grammars directory",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=os.cpu_count(),
        help="Number of worker threads to use (default: number of CPU cores)",
    )
    args = parser.parse_args()

    # Create a thread pool executor
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = []
        if args.path:
            # Process each path provided
            for p in args.path:
                future = executor.submit(generate_binding, p, Path("src", "languages"))
                futures.append((p, future))
        else:
            # Multiple grammars case (default behavior when no path is specified)
            for path_item in Path("src", "grammars").iterdir():
                if not path_item.is_dir():
                    continue

                # Submit each grammar to the thread pool
                future = executor.submit(
                    generate_binding, path_item, Path("src", "languages")
                )
                futures.append((path_item, future))

        # Wait for all futures to complete and handle any exceptions
        for path_item, future in futures:
            try:
                future.result()
            except Exception as e:
                logger.error(f"Error generating binding for {path_item}: {e}")


if __name__ == "__main__":
    main()
