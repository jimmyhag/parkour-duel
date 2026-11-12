"""Test gate: run the GUT suite headless and fail unless every test passed.

GUT exits 0 when a filter matches no script, so the exit code alone is not enough:
the run must also end with GUT's "All tests passed" summary.

Usage: python tools/run_tests.py <godot-binary> [filter]
  filter: only the test scripts whose file name contains this text are run.
"""

from __future__ import annotations

import subprocess
import sys

from repo import ROOT

SUCCESS_MARKER = "All tests passed!"


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print(__doc__)
        return 2
    godot = sys.argv[1]
    command = [
        godot,
        "--headless",
        "--path",
        str(ROOT),
        "-s",
        "addons/gut/gut_cmdln.gd",
        "-gdisable_colors",
        "-gexit",
    ]
    if len(sys.argv) == 3:
        command.append(f"-gselect={sys.argv[2]}")

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    assert process.stdout is not None
    passed = False
    for line in process.stdout:
        sys.stdout.write(line)
        if SUCCESS_MARKER in line:
            passed = True
    returncode = process.wait()

    if returncode != 0:
        print(f"test: GUT exited with code {returncode}")
        return 1
    if not passed:
        print("test: no test ran to a passing summary (wrong filter, or no test found)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
