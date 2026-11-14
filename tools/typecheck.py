"""Type gate: every GDScript file must load without a parse or type error.

Godot does the checking: tools/typecheck.gd loads every script of the project in one
headless Godot process, as `--check-only --script` loads one, so that a script several
others need is read and compiled once. The strictness comes from the [debug] section of
project.godot, where the typing warnings are raised to errors.

The run passes only when Godot exits cleanly, prints no error, and reports that it loaded
every script it was given.

Usage: python tools/typecheck.py <godot-binary>
"""

from __future__ import annotations

import subprocess
import sys

from repo import ROOT, iter_files, res

ERROR_MARKERS = ("SCRIPT ERROR", "ERROR:")
# The script Godot runs, by its file path: tools/ is hidden from Godot's import (.gdignore).
RUNNER = ROOT / "tools" / "typecheck.gd"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    godot = sys.argv[1]
    scripts = [res(path) for path in iter_files(".gd")]
    result = subprocess.run(
        [godot, "--headless", "--path", str(ROOT), "-s", str(RUNNER), "--", *scripts],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=300,
        check=False,
    )
    output = result.stdout + result.stderr
    summary = f"typecheck: {len(scripts)} script(s) loaded, 0 not valid"
    ok = (
        result.returncode == 0
        and summary in output
        and not any(marker in output for marker in ERROR_MARKERS)
    )
    if not ok:
        for line in output.splitlines():
            if line.strip() and not line.startswith("Godot Engine v"):
                print(line)
        print(f"typecheck: Godot exited with code {result.returncode}")
    print(f"typecheck: {len(scripts)} script(s), {'no error' if ok else 'FAILED'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
