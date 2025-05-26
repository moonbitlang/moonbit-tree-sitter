#!/usr/bin/env python3

from pathlib import PurePath, Path, PurePosixPath
import re
from typing import Optional

class Project:
    include: list[Path]
    source: Path
    target: Path
    prefix: str
    copied: set[Path]

    def __init__(
        self, source: Path, target: Path, include: list[Path] = [], prefix: str = ""
    ):
        self.source = source
        self.target = target
        self.include = include
        self.prefix = prefix
        self.copied = set()

    def mangle(self, source: PurePath) -> str:
        return "#".join([self.prefix, *source.parts])

    def relocate(self, source: Path, content: str) -> str:
        include_directories = [(self.source / source).parent, *self.include]
        headers = []

        def relocate(header: PurePosixPath) -> PurePosixPath:
            for directory in include_directories:
                resolved = ((directory / header).resolve()).relative_to(
                    self.source.resolve()
                )
                if not (self.source / resolved).exists():
                    continue
                relocated = self.mangle(resolved)
                if not (self.target / relocated).exists():
                    self.copy(resolved, relocate=False)
                    headers.append(resolved)
                return PurePosixPath(relocated)
            print(f"Warning: {header} not found")
            return header

        def replace(match: re.Match) -> str:
            indent = match.group("indent")
            header: str = match.group("header")
            relocated = relocate(PurePosixPath(header))
            return f'#{indent}include "{relocated.as_posix()}"'

        content = re.sub(r'#(?P<indent>\s*)include "(?P<header>.*?)"', replace, content)

        for source in headers:
            self.copy(source)

        return content

    def condition(self, condition: str, content: str) -> str:
        return f"""#if {condition}
{content}
#endif
"""

    def copy(
        self,
        source: Path,
        relocate: bool = True,
        condition: Optional[str] = None,
    ):
        target = self.mangle(source)
        content = (self.source / source).read_text(encoding="utf-8")
        if relocate:
            content = self.relocate(source, content)
        if condition is not None:
            content = self.condition(condition, content)
        print(f"COPY {self.source / source} -> {self.target / target}")
        (self.target / target).write_text(content, encoding="utf-8")
        self.copied.add(Path(target))


def configure(project: Project):
    project.copy(Path("lib") / "src" / "lib.c")


def main():
    source = Path("src") / "tree-sitter"
    target = Path("src")
    target.mkdir(parents=True, exist_ok=True)
    include = [source / "lib" / "include", source / "lib" / "src"]
    project = Project(source, target, include=include, prefix="tree-sitter")
    configure(project)


if __name__ == "__main__":
    main()
