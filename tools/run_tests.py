"""Test gate: run the GUT suite headless and fail unless every test passed.

GUT exits 0 when a filter matches no script, so the exit code alone is not enough:
the run must also end with GUT's "All tests passed" summary.

Two tiers (docs/specs/test-tiers.md): the course replays are the test scripts whose
file name starts with COURSE_REPLAY_PREFIX (tools/repo.py). GUT can select scripts but
not exclude them, so a tier is handed to GUT as its explicit list of scripts.

Usage: python tools/run_tests.py <godot-binary> [--edit-loop | --course | filter]
  (nothing)    every test script (GUT finds them with .gutconfig.json).
  --edit-loop  every test script but the course replays (`just preflight`).
  --course     only the course replays (`just test-course`).
  filter       only the test scripts whose file name contains this text.
"""

from __future__ import annotations

import subprocess
import sys

from repo import ROOT, TESTS_DIR, is_course_replay, is_test_script, iter_files, res

SUCCESS_MARKER = "All tests passed!"

TIERS = {
    "--edit-loop": ("every test script but the course replays", False),
    "--course": ("the course replays", True),
}


def tier_scripts(course_replays: bool) -> list[str]:
    """The res:// paths of the test scripts of one tier, sorted like GUT sorts them."""
    return [
        res(path)
        for path in iter_files(".gd", dirs=(TESTS_DIR,))
        if is_test_script(path) and is_course_replay(path) == course_replays
    ]


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
    if len(sys.argv) == 3 and sys.argv[2] in TIERS:
        title, course_replays = TIERS[sys.argv[2]]
        scripts = tier_scripts(course_replays)
        print(f"test: {title}, {len(scripts)} script(s)")
        for script in scripts:
            print(f"  {script.removeprefix('res://')}")
        if not scripts:
            print("test: no test script in this tier")
            return 1
        # An empty -gdir replaces the directories of .gutconfig.json: only the list runs.
        command += ["-gdir=", "-gtest=" + ",".join(scripts)]
    elif len(sys.argv) == 3:
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
