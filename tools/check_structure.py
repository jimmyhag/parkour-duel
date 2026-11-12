"""Structure gate: layer boundaries, dead files, and the .claude/ mirror.

1. Boundaries. Every file of game/ belongs to a layer (game/<layer>/). A file may only
   reference its own layer and the layers LAYERS allows, whether by path, by uid or by
   class_name. core/ holds pure logic: no scene, no node, no input. Network transport
   classes are only allowed in net/. tests/ may reference anything.
2. Dead files. Every script, scene and resource of game/ (and every helper script of
   tests/) must be reachable from project.godot or from a test script.
3. Mirror. .claude/agents and .claude/skills are copies of .agents/ on this project;
   they must stay identical to their source.

The references this tool sees are literal: a full `res://` path, a `uid://`, a relative
path in a string, or a class_name used as an identifier. A path built at run time is
invisible to it.

Usage: python tools/check_structure.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path, PurePosixPath

from repo import ROOT, iter_files, rel

# layer -> the other layers it may reference
LAYERS: dict[str, set[str]] = {
    "core": set(),
    "player": {"core"},
    "world": {"core"},
    "ui": {"core"},
    "net": {"core"},
    "levels": {"core", "player", "world", "ui", "net"},
}

CORE_BASE_CLASSES = {"RefCounted", "Resource", "Object"}

# Scene and input types core/ must not mention.
CORE_FORBIDDEN = re.compile(
    r"\b(?:Input|InputMap|InputEvent\w*|Node|Node2D|Node3D|Control|CanvasItem|SceneTree"
    r"|PackedScene|CharacterBody3D|RigidBody3D|StaticBody3D|AnimatableBody3D|Area3D"
    r"|Camera3D|Viewport)\b"
)

# Network transport, only allowed in net/.
NETWORK_CLASSES = {
    "ENetConnection",
    "ENetMultiplayerPeer",
    "ENetPacketPeer",
    "HTTPClient",
    "HTTPRequest",
    "MultiplayerAPI",
    "MultiplayerAPIExtension",
    "MultiplayerPeer",
    "MultiplayerPeerExtension",
    "MultiplayerSpawner",
    "MultiplayerSynchronizer",
    "OfflineMultiplayerPeer",
    "PacketPeer",
    "PacketPeerDTLS",
    "PacketPeerStream",
    "PacketPeerUDP",
    "SceneMultiplayer",
    "StreamPeer",
    "StreamPeerTCP",
    "StreamPeerTLS",
    "TCPServer",
    "UDPServer",
    "WebRTCDataChannel",
    "WebRTCMultiplayerPeer",
    "WebRTCPeerConnection",
    "WebSocketMultiplayerPeer",
    "WebSocketPeer",
}
NETWORK_CODE = re.compile(
    r"@rpc\b|\brpc(?:_id)?\s*\(|\bmultiplayer\b|\b(?:" + "|".join(sorted(NETWORK_CLASSES)) + r")\b"
)

IDENTIFIER = re.compile(r"\b[A-Za-z_]\w*\b")
RES_PATH = re.compile(r"res://[^\"'\s\])]+")
UID = re.compile(r"uid://[a-z0-9]+")
CLASS_NAME = re.compile(r"^\s*class_name\s+(\w+)", re.MULTILINE)
EXTENDS = re.compile(r"^\s*(?:class_name\s+\w+\s+)?extends\s+(\w+)", re.MULTILINE)
SCENE_CLASS_ATTR = re.compile(r"\b(?:type|script_class)=\"(\w+)\"")
RESOURCE_SUFFIXES = (".gd", ".tscn", ".tres")


def split_gdscript(text: str) -> tuple[str, list[tuple[int, str]]]:
    """Return the code with comments and string contents blanked (same line layout),
    and the string literals with their line number."""
    code: list[str] = []
    strings: list[tuple[int, str]] = []
    line = 1
    i = 0
    length = len(text)
    while i < length:
        char = text[i]
        if char == "#":
            while i < length and text[i] != "\n":
                i += 1
            continue
        if char in "\"'":
            quote = char * 3 if text.startswith(char * 3, i) else char
            start_line = line
            i += len(quote)
            literal: list[str] = []
            while i < length and not text.startswith(quote, i):
                if text[i] == "\\" and i + 1 < length:
                    literal.append(text[i : i + 2])
                    i += 2
                    continue
                if text[i] == "\n":
                    if len(quote) == 1:
                        break
                    line += 1
                    code.append("\n")
                literal.append(text[i])
                i += 1
            if text.startswith(quote, i):
                i += len(quote)
            strings.append((start_line, "".join(literal)))
            code.append('""')
            continue
        if char == "\n":
            line += 1
        code.append(char)
        i += 1
    return "".join(code), strings


class ProjectFile:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.rel = rel(path)
        self.text = path.read_text(encoding="utf-8")
        parts = PurePosixPath(self.rel).parts
        self.is_test = parts[0] == "tests"
        self.layer = parts[1] if parts[0] == "game" and len(parts) > 2 else None
        self.is_script = self.rel.endswith(".gd")
        self.code = ""
        self.strings: list[tuple[int, str]] = []
        if self.is_script:
            self.code, self.strings = split_gdscript(self.text)
        self.class_name: str | None = None
        match = CLASS_NAME.search(self.code)
        if match:
            self.class_name = match.group(1)

    def own_uid(self) -> str | None:
        if self.is_script:
            sidecar = self.path.with_name(self.path.name + ".uid")
            if sidecar.is_file():
                found = UID.search(sidecar.read_text(encoding="utf-8"))
                return found.group(0) if found else None
            return None
        found = UID.search(self.text.split("\n", 1)[0])
        return found.group(0) if found else None


def resolve_relative(source: ProjectFile, literal: str) -> str | None:
    """A relative path in a script string, as a repository-relative path."""
    if "://" in literal or not literal.endswith(RESOURCE_SUFFIXES):
        return None
    base = PurePosixPath(source.rel).parent
    parts: list[str] = []
    for part in (base / literal).parts:
        if part == "..":
            if not parts:
                return None
            parts.pop()
        elif part != ".":
            parts.append(part)
    return "/".join(parts)


class Project:
    def __init__(self) -> None:
        self.files = [ProjectFile(path) for path in iter_files(*RESOURCE_SUFFIXES)]
        self.by_rel = {f.rel: f for f in self.files}
        self.by_uid = {uid: f for f in self.files if (uid := f.own_uid())}
        self.by_class = {f.class_name: f for f in self.files if f.class_name}

    def references(self, source: ProjectFile) -> list[tuple[int, ProjectFile, str]]:
        """Every project file the source refers to: (line, target, how)."""
        found: list[tuple[int, ProjectFile, str]] = []

        def add(line: int, target: ProjectFile | None, how: str) -> None:
            if target is not None and target is not source:
                found.append((line, target, how))

        if source.is_script:
            for line, literal in source.strings:
                for path in RES_PATH.findall(literal):
                    add(line, self.by_rel.get(path.removeprefix("res://")), path)
                for uid in UID.findall(literal):
                    add(line, self.by_uid.get(uid), uid)
                relative = resolve_relative(source, literal)
                if relative:
                    add(line, self.by_rel.get(relative), literal)
            for number, code_line in enumerate(source.code.split("\n"), start=1):
                for name in IDENTIFIER.findall(code_line):
                    add(number, self.by_class.get(name), f"class {name}")
        else:
            for number, text_line in enumerate(source.text.split("\n"), start=1):
                for path in RES_PATH.findall(text_line):
                    add(number, self.by_rel.get(path.removeprefix("res://")), path)
                if number > 1:
                    for uid in UID.findall(text_line):
                        add(number, self.by_uid.get(uid), uid)
                for name in SCENE_CLASS_ATTR.findall(text_line):
                    add(number, self.by_class.get(name), f"class {name}")
        return found


def check_boundaries(project: Project) -> list[str]:
    problems: list[str] = []
    for source in project.files:
        if source.is_test:
            continue
        if source.layer is None:
            problems.append(f"{source.rel}:1: file outside any layer (expected game/<layer>/...)")
            continue
        if source.layer not in LAYERS:
            problems.append(
                f"{source.rel}:1: unknown layer '{source.layer}' (declare it in LAYERS of "
                "tools/check_structure.py, in a dedicated commit)"
            )
            continue

        allowed = LAYERS[source.layer] | {source.layer}
        for line, target, how in project.references(source):
            if target.is_test:
                problems.append(f"{source.rel}:{line}: game code references a test file ({how})")
            elif target.layer not in allowed:
                problems.append(
                    f"{source.rel}:{line}: layer '{source.layer}' may not reference layer "
                    f"'{target.layer}' ({how} -> {target.rel})"
                )

        if source.layer == "core":
            problems.extend(check_core_purity(project, source))
        if source.layer != "net":
            problems.extend(check_no_network(source))
    return problems


def check_core_purity(project: Project, source: ProjectFile) -> list[str]:
    problems: list[str] = []
    if source.rel.endswith(".tscn"):
        return [f"{source.rel}:1: core/ holds pure logic, a scene does not belong there"]
    if not source.is_script:
        return problems
    match = EXTENDS.search(source.code)
    if match:
        base = match.group(1)
        base_file = project.by_class.get(base)
        if base not in CORE_BASE_CLASSES and (base_file is None or base_file.layer != "core"):
            line = source.code.count("\n", 0, match.start(1)) + 1
            allowed = ", ".join(sorted(CORE_BASE_CLASSES))
            problems.append(
                f"{source.rel}:{line}: a core/ script extends {allowed} or another core/ "
                f"class, not {base}"
            )
    for number, code_line in enumerate(source.code.split("\n"), start=1):
        for name in sorted(set(CORE_FORBIDDEN.findall(code_line))):
            if EXTENDS.match(code_line):
                continue
            problems.append(
                f"{source.rel}:{number}: core/ may not use scene or input type {name}"
            )
    return problems


def check_no_network(source: ProjectFile) -> list[str]:
    problems: list[str] = []
    if source.is_script:
        for number, code_line in enumerate(source.code.split("\n"), start=1):
            for found in sorted(set(NETWORK_CODE.findall(code_line))):
                problems.append(
                    f"{source.rel}:{number}: network transport ({found.strip()}) is only "
                    "allowed in game/net/"
                )
    else:
        for number, text_line in enumerate(source.text.split("\n"), start=1):
            for name in SCENE_CLASS_ATTR.findall(text_line):
                if name in NETWORK_CLASSES:
                    problems.append(
                        f"{source.rel}:{number}: network transport ({name}) is only allowed "
                        "in game/net/"
                    )
    return problems


def check_dead_files(project: Project) -> list[str]:
    settings = (ROOT / "project.godot").read_text(encoding="utf-8")
    roots: list[ProjectFile] = []
    for path in RES_PATH.findall(settings):
        target = project.by_rel.get(path.removeprefix("res://"))
        if target:
            roots.append(target)
    for uid in UID.findall(settings):
        target = project.by_uid.get(uid)
        if target:
            roots.append(target)
    for candidate in project.files:
        if candidate.is_test and Path(candidate.rel).name.startswith("test_"):
            roots.append(candidate)

    reachable: set[str] = set()
    pending = list(roots)
    while pending:
        current = pending.pop()
        if current.rel in reachable:
            continue
        reachable.add(current.rel)
        pending.extend(target for _, target, _ in project.references(current))

    return [
        f"{candidate.rel}:1: dead file, reachable neither from project.godot nor from a test"
        for candidate in project.files
        if candidate.rel not in reachable
    ]


def normalized(path: Path) -> bytes:
    return path.read_bytes().replace(b"\r\n", b"\n")


def check_claude_mirror() -> list[str]:
    agents = ROOT / ".agents"
    claude = ROOT / ".claude"
    if not agents.is_dir():
        return []
    pairs: dict[Path, Path] = {}  # copy -> source
    for source in sorted(agents.glob("*.md")):
        if source.read_text(encoding="utf-8").startswith("---"):
            pairs[claude / "agents" / source.name] = source
    for source in sorted((agents / "skills").glob("*/**/*")):
        if source.is_file():
            pairs[claude / "skills" / source.relative_to(agents / "skills")] = source
    # A copy whose source has gone is caught from the other side.
    for copy in sorted((claude / "agents").glob("*")):
        if copy.is_file():
            pairs.setdefault(copy, agents / copy.name)
    for copy in sorted((claude / "skills").rglob("*")):
        if copy.is_file():
            pairs.setdefault(copy, agents / "skills" / copy.relative_to(claude / "skills"))

    problems: list[str] = []
    for copy, source in sorted(pairs.items()):
        if not source.is_file():
            problems.append(f"{rel(copy)}:1: no source file {rel(source)} in .agents/")
        elif not copy.is_file():
            problems.append(f"{rel(source)}:1: missing copy {rel(copy)}")
        elif normalized(copy) != normalized(source):
            problems.append(f"{rel(copy)}:1: differs from its source {rel(source)}")
    return problems


def main() -> int:
    project = Project()
    sections = (
        ("boundaries", check_boundaries(project)),
        ("dead files", check_dead_files(project)),
        (".claude mirror", check_claude_mirror()),
    )
    total = 0
    for title, problems in sections:
        total += len(problems)
        for problem in problems:
            print(problem)
        print(f"structure: {title}: {len(problems)} problem(s)")
    print(f"structure: {len(project.files)} file(s) checked")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
