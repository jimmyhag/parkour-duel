"""Type gate: every GDScript file must load without a parse or type error.

Godot does the checking (`--check-only --script`). The strictness comes from the
[debug] section of project.godot, where the typing warnings are raised to errors.

Usage: python tools/typecheck.py <godot-binary>
"""

from __future__ import annotations

import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

from repo import ROOT, iter_files, rel, res

ERROR_MARKERS = ("SCRIPT ERROR", "ERROR:")


def check(godot: str, script_res_path: str) -> tuple[bool, str]:
    result = subprocess.run(
        [godot, "--headless", "--path", str(ROOT), "--check-only", "--script", script_res_path],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=300,
        check=False,
    )
    output = result.stdout + result.stderr
    ok = result.returncode == 0 and not any(marker in output for marker in ERROR_MARKERS)
    return ok, output


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    godot = sys.argv[1]
    scripts = list(iter_files(".gd"))
    workers = min(8, os.cpu_count() or 1)
    with ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(pool.map(lambda path: check(godot, res(path)), scripts))

    failed = 0
    for path, (ok, output) in zip(scripts, results):
        if ok:
            continue
        failed += 1
        print(f"--- {rel(path)}")
        for line in output.splitlines():
            if line.strip() and not line.startswith("Godot Engine v"):
                print(line)
    print(f"typecheck: {len(scripts)} script(s), {failed} with errors")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
