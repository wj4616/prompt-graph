#!/usr/bin/env python3
"""Memory subsystem helper for prompt-graph-v2.

Reads and writes YAML files under a memory directory. AP-V6 graceful-degrade:
every error path returns silently with empty stdout / exit 0. Never raises
to the orchestrator. The orchestrator treats empty output as "memory unavailable"
and proceeds without personalization.

Subcommands:
  read  --memory-dir DIR --key KEY                   # prints file contents to stdout
  write --memory-dir DIR --key KEY --value VALUE     # writes value as the file body

The orchestrator (not this helper) computes the memory directory:
  1. env PROMPT_GRAPH_MEMORY_DIR if set
  2. else $HOME/.claude/projects/$(echo "$HOME" | sed 's|/|-|g')/memory/
  3. else $HOME/.claude/skills/prompt-graph-v2/memory/ (skill-local fallback)
"""
import argparse
import os
import sys


def _validate_key(key):
    """Reject keys containing path-traversal patterns. Memory keys are flat
    filenames by contract — anything containing '/', '\\', or '..' is a
    misuse and must be rejected at the boundary."""
    if "/" in key or "\\" in key or ".." in key:
        return False
    return True


def cmd_read(args):
    if not _validate_key(args.key):
        return  # silent graceful-degrade
    path = os.path.join(args.memory_dir, args.key)
    try:
        # O_NOFOLLOW guards against symlink-target reads (e.g., a malicious
        # symlink to ~/.ssh/id_rsa). On Linux this triggers ELOOP and lands
        # in the OSError graceful-degrade path.
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    except (FileNotFoundError, IsADirectoryError, PermissionError, OSError):
        return  # silent graceful-degrade
    try:
        with os.fdopen(fd, "r", encoding="utf-8") as f:
            content = f.read()
    except (PermissionError, OSError, UnicodeDecodeError):
        return  # silent graceful-degrade
    sys.stdout.write(content)


def cmd_write(args):
    if not _validate_key(args.key):
        return  # silent graceful-degrade
    try:
        os.makedirs(args.memory_dir, exist_ok=True)
    except (PermissionError, OSError):
        return  # silent graceful-degrade
    path = os.path.join(args.memory_dir, args.key)
    try:
        # O_NOFOLLOW + mode 0600. If a hostile symlink exists at `path`, this
        # raises ELOOP and we graceful-degrade. Mode 0600 protects the file
        # body which may carry sensitive preferences.
        fd = os.open(
            path,
            os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW,
            0o600,
        )
    except (PermissionError, OSError):
        return  # silent graceful-degrade
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(args.value)
            if not args.value.endswith("\n"):
                f.write("\n")
    except (PermissionError, OSError):
        return  # silent graceful-degrade


def main():
    p = argparse.ArgumentParser(prog="memory_helper")
    sub = p.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("read")
    r.add_argument("--memory-dir", required=True)
    r.add_argument("--key", required=True)
    r.set_defaults(fn=cmd_read)

    w = sub.add_parser("write")
    w.add_argument("--memory-dir", required=True)
    w.add_argument("--key", required=True)
    w.add_argument("--value", required=True)
    w.set_defaults(fn=cmd_write)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
