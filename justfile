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
setup:
    {{ system_python }} -m venv .venv
    {{ python }} -m pip install --quiet --disable-pip-version-check -r requirements-dev.txt
    {{ godot }} --headless --path . --import

# Start the game locally
dev:
    {{ godot }} --path .

# Run the test suite once; `just test <filter>` runs a subset
test *args: import
    {{ python }} tools/run_tests.py {{ godot }} {{ args }}

# Refresh Godot's import cache (global classes, imported resources)
import:
    {{ godot }} --headless --path . --import

# Type-check every script, strict: typing warnings are errors (project.godot, [debug])
typecheck: import
    {{ python }} tools/typecheck.py {{ godot }}

# Lint; warnings fail
lint:
    @echo "TO DEFINE: the linter with warnings as errors" && exit 1

# Dead code and dependency boundaries
deadcode:
    @echo "TO DEFINE: the dead-code and boundaries tool" && exit 1

# Edit-loop gate, run after every change (check stays the gate before a commit)
preflight: typecheck lint test deadcode

# Everything that must pass before a commit: preflight plus the build and the slow suites
check: preflight
    @echo "TO DEFINE: the production build and anything too slow for preflight" && exit 1
