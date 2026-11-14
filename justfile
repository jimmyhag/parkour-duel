# Task runner. `just check` is the gate, locally and in CI.
# Recipes only call Godot or a Python tool of tools/, so the same line runs under
# cmd.exe and sh.

# cmd.exe on Windows (sh is not guaranteed to be on PATH); sh elsewhere.
[windows]
set shell := ["cmd.exe", "/c"]

# The Godot 4 editor binary (version in .godot-version). Override with the GODOT
# environment variable. On Windows the console wrapper is the one that waits and prints.
godot := env("GODOT", if os_family() == "windows" { "godot_console" } else { "godot" })

# The Python that creates .venv, then the tools installed inside it.
system_python := if os_family() == "windows" { "python" } else { "python3" }
venv_bin := if os_family() == "windows" { ".venv\\Scripts\\" } else { ".venv/bin/" }
python := venv_bin + "python"

# List the available recipes
default:
    @just --list

# Install the tooling of a fresh checkout or worktree: .venv, then Godot's import cache
setup: && import
    {{ system_python }} -m venv .venv
    {{ python }} -m pip install --quiet --disable-pip-version-check -r requirements-dev.txt

# Start the game locally
dev:
    {{ godot }} --path .

# Run the test suite once; `just test <filter>` runs a subset
test *args: import
    {{ python }} tools/run_tests.py {{ godot }} {{ args }}

# Run only the course replays, the test scripts whose name starts with test_course
test-course: import
    {{ python }} tools/run_tests.py {{ godot }} --course

# The tests of the edit loop: every test script but the course replays
_test-edit-loop: import
    {{ python }} tools/run_tests.py {{ godot }} --edit-loop

# Refresh Godot's import cache (global classes, imported resources)
import:
    {{ godot }} --headless --path . --import

# Type-check every script, strict: typing warnings are errors (project.godot, [debug])
typecheck: import
    {{ python }} tools/typecheck.py {{ godot }}

# Lint and formatting of every script; any finding fails (gdtoolkit defaults)
lint:
    {{ venv_bin }}gdlint game tests
    {{ venv_bin }}gdformat --check game tests

# Layer boundaries, dead files, course replay names, .claude/ mirror (tools/check_structure.py)
deadcode:
    {{ python }} tools/check_structure.py

# Edit-loop gate, run after every change: every test but the course replays
preflight: typecheck lint _test-edit-loop deadcode

# Export the Windows and Linux release builds, then start the host platform's one
build:
    {{ python }} tools/export.py {{ godot }}

# Download the pinned export templates the build needs (once per machine, about 1 GB)
fetch-templates:
    {{ python }} tools/fetch_godot.py templates

# The commit gate: preflight with every test (course replays included), then the builds
check: typecheck lint test deadcode build
