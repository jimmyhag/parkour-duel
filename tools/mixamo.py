"""Copy the Mixamo files the game uses into assets/mixamo/, which Git ignores.

Mixamo's characters and animations are free to use in a game, not to redistribute, and
the repository is public: they never go into it (docs/specs/character-animations.md).
Each owner downloads them from mixamo.com (README, "The animated character") and runs
this command on the download folder. It copies the character and the animations the game
uses under fixed names, extracts the one clip of the pistol pack the game uses, and writes
next to each file the import settings Godot reads: the character with its mesh and its
textures, and of every other file only its skeleton and its animation (one copy of the
mesh in the game). Nothing of the downloaded files is executed: they are only copied.

When one file is missing, nothing is copied and the command fails, naming it. A file
already copied with the same content is left alone, with its settings, so that Godot does
not import it again.

Usage: python tools/mixamo.py <download-folder> [--into <folder>]
  --into  where to copy (assets/mixamo/ by default; the tests copy elsewhere).

Under cmd.exe, a folder written between quotes with a backslash at its end arrives with
a quote at its end: the backslash escaped the closing quote. That quote is dropped.
"""

from __future__ import annotations

import filecmp
import shutil
import sys
import zipfile
from pathlib import Path
from typing import Callable

from repo import ROOT

DESTINATION = ROOT / "assets" / "mixamo"

# The character: the only file whose mesh is imported.
CHARACTER = ("Ch08_nonPBR.fbx", "ch08_nonpbr.fbx")
# The animations, as mixamo.com names them, and the name each one takes once copied.
ANIMATIONS = {
    "Idle.fbx": "idle.fbx",
    "Running.fbx": "running.fbx",
    "Jump.fbx": "jump.fbx",
    "Falling Idle.fbx": "falling_idle.fbx",
    "Landing.fbx": "landing.fbx",
    "Hard Landing.fbx": "hard_landing.fbx",
    "Falling To Roll.fbx": "falling_to_roll.fbx",
    "Running Slide.fbx": "running_slide.fbx",
    "Backflip.fbx": "backflip.fbx",
    # The walk and the sprint of the locomotion (docs/specs/locomotion-blend.md),
    # downloaded without the character ("Without Skin"): only their animation is used.
    "Walking.fbx": "walking.fbx",
    "Sprint.fbx": "sprint.fbx",
    # The vault and the mantle (docs/specs/vault.md), downloaded without the character.
    "Vault One Hand.fbx": "vault_one_hand.fbx",
    "Vault Two Hands.fbx": "vault_two_hands.fbx",
    "Ledge Pull Up.fbx": "ledge_pull_up.fbx",
    # The jog of the locomotion, the jump from a run and the landing that runs on
    # (docs/specs/motion-weight.md), downloaded without the character. The faster runs
    # measured for it (Fast Run, Two Cycle Sprint, Running Quickly) are not used.
    "Jogging.fbx": "jogging.fbx",
    "Running Jump.fbx": "running_jump.fbx",
    "Land To Run.fbx": "land_to_run.fbx",
}
# The pistol pack, and the clips taken out of it (skeleton and animation only).
PACK = "Pistol_Handgun Locomotion Pack.zip"
PACK_CLIPS = {"pistol idle.fbx": "pistol_idle.fbx"}

# The mesh nodes of the character, as Godot names them in every file that holds it: the
# import of an animation skips them.
CHARACTER_MESHES = (
    "Ch08_Beard",
    "Ch08_Body",
    "Ch08_Eyelashes",
    "Ch08_Hair",
    "Ch08_Hoodie",
    "Ch08_Pants",
    "Ch08_Sneakers",
)

# Godot's import settings (a .import file without its [remap] path and uid, which Godot
# adds). FBX through ufbx (fbx/importer=0).
CHARACTER_SETTINGS = """[remap]

importer="scene"
type="PackedScene"

[params]

animation/import=false
fbx/importer=0
"""

ANIMATION_SETTINGS = """[remap]

importer="scene"
type="PackedScene"

[params]

fbx/importer=0
fbx/embedded_image_handling=0
_subresources={
"nodes": {
%s
}
}
"""


def animation_settings() -> str:
    skipped = ",\n".join(
        f'"PATH:Skeleton3D/{mesh}": {{"import/skip_import": true}}' for mesh in CHARACTER_MESHES
    )
    return ANIMATION_SETTINGS % skipped


def pack_member(pack: zipfile.ZipFile, clip: str) -> zipfile.ZipInfo | None:
    """The member of the pack whose file name is `clip`, wherever it sits in the zip."""
    for member in pack.infolist():
        if not member.is_dir() and member.filename.replace("\\", "/").split("/")[-1] == clip:
            return member
    return None


def download_folder(argument: str) -> Path:
    """The download folder named by `argument`, without the quote cmd.exe leaves at the
    end of a quoted folder that ends with a backslash."""
    return Path(argument.strip().rstrip('"'))


def missing_files(downloads: Path) -> list[str]:
    missing = [
        name for name in (CHARACTER[0], *ANIMATIONS) if not (downloads / name).is_file()
    ]
    pack_path = downloads / PACK
    if not pack_path.is_file():
        return [*missing, PACK]
    with zipfile.ZipFile(pack_path) as pack:
        missing += [f"{PACK}: {clip}" for clip in PACK_CLIPS if pack_member(pack, clip) is None]
    return missing


def place(target: Path, settings: str, write: Callable[[], bool]) -> bool:
    """Writes the file with `write` unless `target` already holds it, then its settings.
    Whether it was written."""
    written = write()
    if written:
        target.with_name(target.name + ".import").write_text(settings, encoding="utf-8")
    return written


def copy_file(source: Path, target: Path, settings: str) -> bool:
    def write() -> bool:
        if target.is_file() and filecmp.cmp(source, target, shallow=False):
            return False
        shutil.copyfile(source, target)
        return True

    return place(target, settings, write)


def extract_clip(pack: zipfile.ZipFile, member: zipfile.ZipInfo, target: Path) -> bool:
    def write() -> bool:
        content = pack.read(member)
        if target.is_file() and target.read_bytes() == content:
            return False
        target.write_bytes(content)
        return True

    return place(target, animation_settings(), write)


def main() -> int:
    arguments = sys.argv[1:]
    destination = DESTINATION
    if len(arguments) == 3 and arguments[1] == "--into":
        destination = Path(arguments[2])
        arguments = arguments[:1]
    if len(arguments) != 1:
        print(__doc__)
        return 2
    downloads = download_folder(arguments[0])
    missing = missing_files(downloads)
    if missing:
        print(f"mixamo: missing in {downloads}, nothing copied:")
        for name in missing:
            print(f"  {name}")
        return 1

    destination.mkdir(parents=True, exist_ok=True)
    copied = 0
    copied += copy_file(downloads / CHARACTER[0], destination / CHARACTER[1], CHARACTER_SETTINGS)
    for name, target in ANIMATIONS.items():
        copied += copy_file(downloads / name, destination / target, animation_settings())
    with zipfile.ZipFile(downloads / PACK) as pack:
        for clip, target in PACK_CLIPS.items():
            member = pack_member(pack, clip)
            assert member is not None
            copied += extract_clip(pack, member, destination / target)
    total = 1 + len(ANIMATIONS) + len(PACK_CLIPS)
    print(f"mixamo: {copied} file(s) copied, {total - copied} already there, in {destination}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
