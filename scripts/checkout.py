#!/usr/bin/env python3
"""Manage tree-sitter grammar dependencies."""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

GRAMMARS_JSON = Path("grammars.json")
GRAMMARS_LOCK = Path("grammars.lock.json")
GRAMMARS_DIR = Path("src", "grammars")


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, data):
    Path(path).write_text(json.dumps(data, indent=2) + "\n")


def git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, check=True)


def git_output(*args, cwd=None):
    r = subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    )
    return r.stdout.strip()


def default_branch(dest):
    """Determine the default branch of the remote."""
    try:
        ref = git_output("symbolic-ref", "refs/remotes/origin/HEAD", cwd=dest)
        return ref.removeprefix("refs/remotes/origin/")
    except subprocess.CalledProcessError:
        for name in ("main", "master"):
            try:
                git_output("rev-parse", f"origin/{name}", cwd=dest)
                return name
            except subprocess.CalledProcessError:
                continue
        raise RuntimeError(f"cannot determine default branch for {dest}")


def install(args):
    """Clone grammars at the exact revisions specified in grammars.lock.json."""
    grammars = read_json(GRAMMARS_JSON)
    lock = read_json(GRAMMARS_LOCK)

    for name in grammars:
        locked = lock.get(name)
        if not locked:
            print(f"warning: {name} not in lock file, skipping (run 'update' first)")
            continue

        dest = GRAMMARS_DIR / name
        url = locked["url"]
        rev = locked["rev"]
        branch = locked.get("branch")

        if dest.exists():
            try:
                current = git_output("rev-parse", "HEAD", cwd=dest)
                if current == rev:
                    print(f"{name}: up to date")
                    continue
            except subprocess.CalledProcessError:
                pass
            print(f"{name}: checking out {rev[:12]}")
            try:
                git("fetch", "origin", cwd=dest)
                git("checkout", rev, cwd=dest)
            except subprocess.CalledProcessError:
                print(f"{name}: re-cloning")
                shutil.rmtree(dest)
                clone_args = ["clone", url, str(dest)]
                if branch:
                    clone_args.extend(["-b", branch])
                git(*clone_args)
                git("checkout", rev, cwd=dest)
        else:
            print(f"{name}: cloning at {rev[:12]}")
            clone_args = ["clone", url, str(dest)]
            if branch:
                clone_args.extend(["-b", branch])
            git(*clone_args)
            git("checkout", rev, cwd=dest)


def update(args):
    """Fetch latest revisions and update grammars.lock.json."""
    grammars = read_json(GRAMMARS_JSON)
    lock = {}

    for name, info in sorted(grammars.items()):
        dest = GRAMMARS_DIR / name
        url = info["url"]
        branch = info.get("branch")

        if dest.exists():
            print(f"{name}: fetching")
            git("fetch", "origin", cwd=dest)
        else:
            print(f"{name}: cloning")
            clone_args = ["clone", url, str(dest)]
            if branch:
                clone_args.extend(["-b", branch])
            git(*clone_args)

        ref = branch or default_branch(dest)
        git("checkout", f"origin/{ref}", cwd=dest)

        rev = git_output("rev-parse", "HEAD", cwd=dest)
        entry = {"url": url, "rev": rev}
        if branch:
            entry["branch"] = branch
        lock[name] = entry

    write_json(GRAMMARS_LOCK, lock)
    print(f"\nUpdated {GRAMMARS_LOCK}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("install", help="Clone grammars at locked revisions")
    sub.add_parser("update", help="Fetch latest and update lock file")

    args = parser.parse_args()
    GRAMMARS_DIR.mkdir(parents=True, exist_ok=True)
    {"install": install, "update": update}[args.command](args)


if __name__ == "__main__":
    main()
