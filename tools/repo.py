"""Shared helpers for the gate tools: where the project's own files live."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterator

ROOT = Path(__file__).resolve().parent.parent

# Folders that hold the project's own GDScript, scenes and resources.
SOURCE_DIRS = ("game", "tests")

# Never scanned: caches, tooling, vendored add-ons, build output, agent worktrees.
SKIPPED_DIRS = {".git", ".godot", ".venv", ".claude", "addons", "build", "__pycache__"}


def iter_files(*suffixes: str, dirs: tuple[str, ...] = SOURCE_DIRS) -> Iterator[Path]:
    """Yield the project files with one of the suffixes, sorted, as absolute paths."""
    found: list[Path] = []
    for top in dirs:
        base = ROOT / top
        if not base.is_dir():
            continue
        for current, subdirs, files in os.walk(base):
            subdirs[:] = [d for d in subdirs if d not in SKIPPED_DIRS]
            for name in files:
                if name.endswith(suffixes):
                    found.append(Path(current) / name)
    yield from sorted(found)


def rel(path: Path) -> str:
    """Path relative to the repository root, with forward slashes."""
    return path.relative_to(ROOT).as_posix()


def res(path: Path) -> str:
    """The Godot resource path of a project file."""
    return "res://" + rel(path)
