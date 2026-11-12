"""Download the pinned Godot pieces from the official release, checksum verified.

The version comes from .godot-version, the expected SHA-512 from
tools/godot-checksums.txt (copied from the release's SHA512-SUMS.txt).

Usage:
  python tools/fetch_godot.py templates        export templates for the Windows and
                                               Linux builds, into Godot's user folder
  python tools/fetch_godot.py editor <dir>     the Linux editor binary, as <dir>/godot
                                               (what CI runs)
"""

from __future__ import annotations

import hashlib
import os
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

from repo import ROOT

RELEASES = "https://github.com/godotengine/godot/releases/download"
TEMPLATE_FILES = (
    "version.txt",
    "windows_release_x86_64.exe",
    "windows_release_x86_64_console.exe",
    "linux_release.x86_64",
)


def version() -> str:
    return (ROOT / ".godot-version").read_text(encoding="utf-8").strip()


def expected_checksum(file_name: str) -> str:
    for line in (ROOT / "tools" / "godot-checksums.txt").read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[1] == file_name:
            return parts[0]
    raise SystemExit(f"fetch: no checksum for {file_name} in tools/godot-checksums.txt")


def download(file_name: str, folder: Path) -> Path:
    url = f"{RELEASES}/{version()}/{file_name}"
    target = folder / file_name
    digest = hashlib.sha512()
    print(f"fetch: downloading {url}", flush=True)
    with urllib.request.urlopen(url, timeout=120) as response, target.open("wb") as out:
        while chunk := response.read(1 << 20):
            digest.update(chunk)
            out.write(chunk)
    if digest.hexdigest() != expected_checksum(file_name):
        target.unlink()
        raise SystemExit(f"fetch: SHA-512 mismatch for {file_name}, file deleted")
    print(f"fetch: {file_name} verified ({target.stat().st_size >> 20} MiB)", flush=True)
    return target


def templates_dir() -> Path:
    folder = version().replace("-", ".")
    if os.name == "nt":
        return Path(os.environ["APPDATA"]) / "Godot" / "export_templates" / folder
    data_home = os.environ.get("XDG_DATA_HOME") or str(Path.home() / ".local" / "share")
    return Path(data_home) / "godot" / "export_templates" / folder


def fetch_templates() -> None:
    destination = templates_dir()
    if all((destination / name).is_file() for name in TEMPLATE_FILES):
        print(f"fetch: export templates already in {destination}")
        return
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        archive = download(f"Godot_v{version()}_export_templates.tpz", Path(temp))
        with zipfile.ZipFile(archive) as bundle:
            for name in TEMPLATE_FILES:
                (destination / name).write_bytes(bundle.read(f"templates/{name}"))
    print(f"fetch: export templates installed in {destination}")


def fetch_editor(destination: Path) -> None:
    binary = destination / "godot"
    if binary.is_file():
        print(f"fetch: editor already at {binary}")
        return
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        archive = download(f"Godot_v{version()}_linux.x86_64.zip", Path(temp))
        with zipfile.ZipFile(archive) as bundle:
            binary.write_bytes(bundle.read(f"Godot_v{version()}_linux.x86_64"))
    binary.chmod(0o755)
    print(f"fetch: editor installed at {binary}")


def main() -> int:
    arguments = sys.argv[1:]
    if arguments == ["templates"]:
        fetch_templates()
    elif len(arguments) == 2 and arguments[0] == "editor":
        fetch_editor(Path(arguments[1]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
