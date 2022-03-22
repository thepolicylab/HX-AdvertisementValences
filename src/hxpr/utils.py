"""
Some simple utility functions
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from .types import FilenameType

DEFAULT_FILENAMES = (
    ".git",
    ".here",
    "pyproject.toml",
    "poetry.lock",
    "setup.py",
)

@lru_cache
def here(base_dir: FilenameType | None = None, filenames: list[str] | None = None) -> Path:
    """
    A version of R's `here` command that looks up the directory tree for one of several
    possible files. Returns the first directory that contains one of those files.

    Args:
        base_dir: The base directory from which to start the search. If None, uses cwd
        filenames: The filenames to look for. If None, uses the DEFAULT_FILENAMES

    Returns:
        The first directory which is a (grand-)parent of `base_dir` (or `base_dir`)
        itself which contains one of the `filenames`

    Raises:
        ValueError: No valid directory contains any fo the files
    """
    filenames = filenames or DEFAULT_FILENAMES
    this_dir = Path(base_dir) if base_dir else Path.cwd()
    next_dir = this_dir.parent
    while True:
        if any((this_dir / filename).exists() for filename in filenames):
            return this_dir

        next_dir = this_dir.parent
        if next_dir == this_dir:
            break
        this_dir = next_dir

    raise ValueError("No valid directory found")
