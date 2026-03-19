#!/usr/bin/env python3
"""Run moon check and then ASAN-enabled tests via run-asan.py."""

import subprocess
import sys
from pathlib import Path


def main():
    repo_root = Path(__file__).resolve().parent.parent
    subprocess.run(["moon", "check", "--target", "native"], check=True, cwd=repo_root)
    result = subprocess.run(
        [
            sys.executable,
            str(repo_root / "scripts" / "run-asan.py"),
            "--repo-root",
            str(repo_root),
            "--pkg",
            "src/moon.pkg",
        ],
        cwd=repo_root,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
