"""Test gate: run the GUT suite headless and fail unless every test passed.

GUT exits 0 when a filter matches no script, so the exit code alone is not enough:
the run must also end with GUT's "All tests passed" summary.

Two tiers (docs/specs/test-tiers.md): the course replays are the test scripts whose
file name starts with COURSE_REPLAY_PREFIX (tools/repo.py). GUT can select scripts but
not exclude them, so a tier is handed to GUT as its explicit list of scripts.

Every test script belongs to exactly one tier, so the whole suite is the two tiers, run
side by side in two headless runs of the project, which only read the import cache and
write different user:// files. Each run must pass on its own. The output of each is
printed whole as soon as it is over; a run that lasts more than TIER_TIMEOUT seconds is
stopped, and what it printed is shown.

Usage: python tools/run_tests.py <godot-binary> [--edit-loop | --course | filter]
  (nothing)    every test script: both tiers, side by side.
  --edit-loop  every test script but the course replays (`just preflight`).
  --course     only the course replays (`just test-course`).
  filter       only the test scripts whose file name contains this text.
"""

from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

from repo import ROOT, TESTS_DIR, is_course_replay, is_test_script, iter_files, res

SUCCESS_MARKER = "All tests passed!"
# Far above the slowest tier (about a minute): only a run that hangs reaches it.
TIER_TIMEOUT = 600

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


def gut_command(godot: str) -> list[str]:
    return [
        godot,
        "--headless",
        "--path",
        str(ROOT),
        "-s",
        "addons/gut/gut_cmdln.gd",
        "-gdisable_colors",
        "-gexit",
    ]


def tier_arguments(title: str, scripts: list[str]) -> list[str]:
    """Announces a tier and its scripts; GUT's arguments that run only them."""
    print(f"test: {title}, {len(scripts)} script(s)")
    for script in scripts:
        print(f"  {script.removeprefix('res://')}")
    # An empty -gdir replaces the directories of .gutconfig.json: only the list runs.
    return ["-gdir=", "-gtest=" + ",".join(scripts)]


def verdict(returncode: int, passed: bool, title: str = "") -> bool:
    prefix = f"test: {title}: " if title else "test: "
    if returncode != 0:
        print(f"{prefix}GUT exited with code {returncode}")
        return False
    if not passed:
        print(f"{prefix}no test ran to a passing summary (wrong filter, or no test found)")
        return False
    return True


def run_streamed(command: list[str]) -> bool:
    """Runs GUT, printing its output as it comes."""
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
    return verdict(process.wait(), passed)


def stop(process: subprocess.Popen[str]) -> None:
    """Stops a run and what it started (on Windows, godot_console starts Godot)."""
    if sys.platform == "win32":
        subprocess.run(
            ["taskkill", "/T", "/F", "/PID", str(process.pid)], capture_output=True, check=False
        )
    else:
        process.kill()


def run_captured(command: list[str]) -> tuple[int, str]:
    """Runs GUT and returns its exit code and its output; a run that hangs is stopped."""
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    try:
        output, _ = process.communicate(timeout=TIER_TIMEOUT)
    except subprocess.TimeoutExpired:
        stop(process)
        # Communicating again keeps what the run printed before it was stopped.
        output, _ = process.communicate()
        return 1, output + f"\ntest: stopped after {TIER_TIMEOUT} s\n"
    return process.returncode, output


def run_every_tier(godot: str) -> bool:
    """Both tiers side by side; each one's output whole, as soon as it is over."""
    commands: list[tuple[str, list[str]]] = []
    for title, course_replays in TIERS.values():
        scripts = tier_scripts(course_replays)
        if scripts:
            commands.append((title, gut_command(godot) + tier_arguments(title, scripts)))
    if not commands:
        print("test: no test script found")
        return False
    ok = True
    with ThreadPoolExecutor(max_workers=len(commands)) as pool:
        runs = {pool.submit(run_captured, command): title for title, command in commands}
        for run in as_completed(runs):
            returncode, output = run.result()
            print(f"test: --- {runs[run]} ---")
            sys.stdout.write(output)
            sys.stdout.flush()
            ok = verdict(returncode, SUCCESS_MARKER in output, runs[run]) and ok
    return ok


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print(__doc__)
        return 2
    godot = sys.argv[1]
    if len(sys.argv) == 2:
        return 0 if run_every_tier(godot) else 1
    command = gut_command(godot)
    if sys.argv[2] in TIERS:
        title, course_replays = TIERS[sys.argv[2]]
        scripts = tier_scripts(course_replays)
        if not scripts:
            print(f"test: {title}, 0 script(s)")
            print("test: no test script in this tier")
            return 1
        command += tier_arguments(title, scripts)
    else:
        command.append(f"-gselect={sys.argv[2]}")
    return 0 if run_streamed(command) else 1


if __name__ == "__main__":
    sys.exit(main())
