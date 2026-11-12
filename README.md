# parkour-duel

Code name for a stylish 3D parkour game played as a 1v1 duel: two runners on mirrored
courses, each armed with a weapon that never hurts the opponent and only sabotages
their scenery. Tricks fill a flow gauge; flow gives speed and ammunition.

Built with Godot 4 and statically typed GDScript. PC first.

## Running the game

Requires Godot 4.7 (standard edition, GDScript). Open the folder in the Godot editor
and press F5, or from a terminal at the repository root:

```sh
godot --path .
```

The game starts on the test course, a short timed run made of grey blocks: a start
platform and its start line, a straight to gather speed, a series of short jumps, a
series of long jumps that need both the run-up and a held jump, steps to climb, and the
finish line. The timer starts at the start line and stops at the finish line; the best
time of the session stays on screen (nothing is saved to disk). Each section opens with
a checkpoint: falling off the course brings the runner back to the last one reached,
and the timer keeps running.

Every value of the feel (speeds, gravities, coyote time, jump buffer, camera) is in
`game/core/movement_tuning.tres`. When the game runs from the project folder, F4 reads
that file again without restarting.

## Working on the project

The rules, the commands and the architecture are in [AGENTS.md](AGENTS.md); the way
the AI assistants work (spec, developer, inspector) is in
[.agents/README.md](.agents/README.md). In short, with
[`just`](https://github.com/casey/just) and Python 3.13 installed:

```sh
just setup            # once per checkout: tooling and Godot import cache
just fetch-templates  # once per machine: export templates for the builds (about 1 GB)
just preflight        # after every change: types, lint, tests, boundaries
just check            # before every commit: preflight and the release builds
```

## Controls

Keyboard keys are bound by their position, not by the letter they print: "W, A, S, D"
below are the keys at those places on a QWERTY keyboard (Z, Q, S, D on an AZERTY one).

| Action | Keyboard and mouse | Gamepad |
| ------ | ------------------ | ------- |
| Move | W, A, S, D | Left stick |
| Turn the camera | Mouse | Right stick |
| Jump (hold to jump higher) | Space | A, or LB |
| Slide (no effect yet) | Left Ctrl | B, or RB |
| Back to the last checkpoint | R | Y |
| Restart the course | Backspace | Back (Select) |
| Release the mouse (a click takes it back) | Escape | none |
| Debug display (state, speeds, timers) | F3 | none |
| Reload the tuning file | F4 | none |

There is no sprint button: the runner accelerates up to its top speed, and a stick
pushed halfway gives half of it.

## Roadmap

| Step | Content | Status |
| ---- | ------- | ------ |
| 0 | Repository, Godot skeleton, harness and gates | done |
| 1 | Solo movement prototype | next |
| 2 | Tricks and flow | not started |
| 3 | Shooting and sabotage | not started |
| 4 | Local duel (ghost, then bot) | not started |
| 5 | Online PVP | not started |
| 6 | Art, audio, menus, release | not started |
