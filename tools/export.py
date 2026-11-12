"""Build gate: export the release builds headless, then start the one this machine can run.

Godot's exit code does not reliably report a failed export, so each export must also
leave its binary and its .pck behind and print no error. The build of the host platform
is then started headless for a few frames and must quit cleanly.

Usage: python tools/export.py <godot-binary>
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from repo import ROOT

BUILD = ROOT / "build"

# preset name in export_presets.cfg -> (output binary, platform it runs on)
PRESETS = {
    "Windows Desktop": (BUILD / "windows" / "parkour-duel.exe", "win32"),
    "Linux": (BUILD / "linux" / "parkour-duel.x86_64", "linux"),
}
ERROR_MARKERS = ("ERROR:", "SCRIPT ERROR")
SMOKE_FRAMES = 60


def run(command: list[str]) -> tuple[int, str]:
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=900,
        check=False,
    )
    return result.returncode, result.stdout + result.stderr


def report(output: str) -> None:
    for line in output.splitlines():
        if line.strip():
            print("    " + line)


def export(godot: str, preset: str, binary: Path) -> bool:
    shutil.rmtree(binary.parent, ignore_errors=True)
    binary.parent.mkdir(parents=True)
    code, output = run(
        [godot, "--headless", "--path", str(ROOT), "--export-release", preset, str(binary)]
    )
    pck = binary.with_suffix(".pck")
    problems: list[str] = []
    if code != 0:
        problems.append(f"Godot exited with code {code}")
    if any(marker in output for marker in ERROR_MARKERS):
        problems.append("Godot printed an error")
    for produced in (binary, pck):
        if not produced.is_file() or produced.stat().st_size == 0:
            problems.append(f"{produced.relative_to(ROOT).as_posix()} was not produced")
    if problems:
        print(f"build: {preset}: FAILED ({'; '.join(problems)})")
        report(output)
        return False
    size = (binary.stat().st_size + pck.stat().st_size) >> 20
    print(f"build: {preset}: {binary.relative_to(ROOT).as_posix()} ({size} MiB with its .pck)")
    return True


def smoke(preset: str, binary: Path) -> bool:
    code, output = run([str(binary), "--headless", "--quit-after", str(SMOKE_FRAMES)])
    if code != 0 or any(marker in output for marker in ERROR_MARKERS):
        print(f"build: {preset}: the exported game FAILED to run {SMOKE_FRAMES} frames (code {code})")
        report(output)
        return False
    print(f"build: {preset}: the exported game ran {SMOKE_FRAMES} frames headless")
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    godot = sys.argv[1]
    BUILD.mkdir(exist_ok=True)
    (BUILD / ".gdignore").touch()

    ok = True
    for preset, (binary, platform) in PRESETS.items():
        exported = export(godot, preset, binary)
        ok = ok and exported
        if exported and sys.platform == platform:
            ok = smoke(preset, binary) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
