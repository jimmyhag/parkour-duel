# parkour-duel

A stylish 3D parkour game played as a 1v1 duel on two mirrored courses, built with
Godot 4 and statically typed GDScript, for PC players first (Steam). Each runner's
weapon never hurts the opponent: it only sabotages their scenery, and tricks are what
refill it. `parkour-duel` is a code name. The owner tests by playing: if moving alone
does not feel good, nothing else will.

Code and identifiers are in English. All user-facing text is in English for now; other
languages are an owner's decision, not taken yet.

This file is the single source of project rules for every contributor, human or AI
assistant. `CLAUDE.md` and `GEMINI.md` only import it: edit this file, not them.

## Getting started

- Godot 4.7.2, standard edition (GDScript, not .NET): the version is in
  `.godot-version`. The `godot` command must be on `PATH` (on Windows, `godot_console`
  too: it is the one that waits and prints), or the `GODOT` environment variable must
  point to the editor binary. Python 3.13 (`.python-version`) runs the gate tools and
  the GDScript linter. [`just`](https://github.com/casey/just) runs everything.
- `just setup` installs a fresh checkout or worktree: it creates `.venv` with the
  pinned tooling of `requirements-dev.txt` and builds Godot's import cache. `just dev`
  starts the game; in the editor, F5 does the same. No secret is needed and there is no
  server: the project runs entirely on the local machine.
- `just fetch-templates`, once per machine: downloads the export templates the release
  builds of `just check` need (about 1 GB, checksum verified).

## Contributing workflow

- Never push to the default branch. Work on a branch and open a pull request: CI runs
  `just check`.
- Merge only when CI is green. Merging deploys nothing.
- The rules below are enforced by the gates (types, lint, tests, dead code and
  boundaries) wherever a tool can enforce them. When one of them blocks you, fix the
  code. Do not relax the configuration of a gate, and do not skip, delete or weaken a
  test to make a change pass; if a rule is truly wrong, say so in the pull request and
  change it in a dedicated commit.
- What tooling cannot check is still mandatory: the business invariants and the
  conventions described here.
- One pull request per coherent change, with what was verified and what was not.
- A request is specified before it is built: the sparring partner (`.agents/README.md`)
  challenges it with an owner and leaves a spec in `docs/specs/` (starting with
  `**Statut : 🟡 Prêt pour le dev**`). The implementation turns each scenario into a
  test of the same name: the English equivalent of the scenario title, in snake case
  after `test_`. When all tests pass and the implementation is complete, the developer
  (human or AI) updates the spec file to `**Statut : 🟢 Implémenté**`.
- One exception to the spec rule, for tuning the feel: a change that only edits values
  of the tuning resource, without a line of code, needs no spec, developer or inspector.
  It still goes through a branch, a pull request and a green CI, and its description
  says what the owner felt and which values changed. As soon as code changes, the full
  circuit applies.
- The feel of the game is the one thing no gate can check. Every report lists what only
  the owner can judge with the controller in hand.

## Commands

`just check` is the gate: it must pass locally and in CI before every commit, and it
runs every test. `just preflight` is the fast subset for the edit loop: run it after
every change, `check` before the commit.

The tests come in two tiers (`docs/specs/test-tiers.md`). The **course replays**, the
test scripts whose file name starts with `test_course`, replay the course or one of its
sections with the test pilot or the bot: they are the slow ones, and `just preflight`
leaves them out. Every test that loads a course scene (a scene of `game/levels/`),
directly or through a helper such as `CourseTest`, lives in such a script; `just
deadcode` refuses one that does not. Time limits on the owner's machine: 30 s for
`just preflight`, 90 s for `just check`, builds included.

| Command            | Purpose                                                    |
| ------------------ | ---------------------------------------------------------- |
| `just setup`       | Install a fresh checkout or worktree (`.venv`, import cache) |
| `just dev`         | Start the game                                             |
| `just test`        | Every test once (GUT, headless); `just test <filter>` runs the test scripts whose file name contains the filter |
| `just test-course` | Only the course replays (`test_course*`)                   |
| `just typecheck`   | Every script loaded by Godot with the typing warnings raised to errors |
| `just lint`        | `gdlint` and `gdformat --check`; any finding fails. `.venv/bin/gdformat <file>` (`.venv\Scripts\gdformat` on Windows) formats a file |
| `just deadcode`    | Layer boundaries, dead files, course replay names and the `.claude/` mirror (`tools/check_structure.py`) |
| `just preflight`   | typecheck + lint + every test but the course replays + deadcode: the edit-loop gate |
| `just build`       | Export the Windows and Linux release builds, then start the host platform's one headless |
| `just check`       | typecheck + lint + every test + deadcode + build: the commit gate |

A tier, like a filter, fails when it runs no test or when GUT's summary does not say
that every test passed.

Read-only commands, safe for a reviewer: `just typecheck`, `just lint`, `just test`,
`just test-course`, `just deadcode`. `just build` writes to `build/`, which Git ignores.

## Business invariants (non-negotiable)

To be written after the first sparring session. One numbered sentence per invariant,
each one something a test or the inspector can check.

## Architecture

The game logic is strictly separated from its presentation: the logic is testable
without the engine's scene tree, which is what makes the gates useful today and the
network possible later. Layers are the folders of `game/`; a folder appears with its
first file.

| Layer | Role | May import |
| ----- | ---- | ---------- |
| `game/core/` | Pure logic: player state machine, flow gauge, round rules, score, ammunition, state of the sabotageable objects. No scene node, no input. | nothing |
| `game/player/` | Physics controller (`CharacterBody3D`), camera, input read and turned into intents passed to `core` | `core` |
| `game/world/` | Platforms, traps, destructible objects, checkpoints | `core` |
| `game/ui/` | HUD, menus | `core` |
| `game/net/` | Transport and synchronisation (roadmap step 5); the only layer that knows the network transport | `core` |
| `game/levels/` | Course scenes and their data; the place where the other layers are assembled | `core`, `player`, `world`, `ui`, `net` |
| `tests/` | Headless tests | anything |

`just deadcode` enforces the table: a reference by path, by uid or by `class_name` to a
layer outside the "May import" column fails, as do a scene, a node type or an input
type in `core/`, and a network transport class or `@rpc` outside `net/`. The tool only
sees literal references: load resources with a full literal path, `preload` or a
`class_name`, never with a path built at run time.

Simulation rules, in place from the first movement prototype so that online play can
come later:

- Inputs are converted into **intents** (a simple typed structure) before they reach
  the simulation. Tomorrow those intents will come from the network.
- The simulation advances in **fixed steps** (`_physics_process`), never on frame time.
- Every sabotage event is a **dated message** (who, which target, when), not a direct
  call between two players.
- Every tuning value of the feel (speeds, gravity, tolerance windows) lives in one
  single tuning resource, editable without touching the code.

### Ports and adapters

There is no external service before roadmap step 5: no server, no backend, no account.
When one appears (the network transport, then Steam), these rules apply:

- Every external service goes through a contract written with `core` types only, and
  lives in `game/net/`.
- Every contract has at least two adapters: a real one and a fake one. The fake is
  deterministic: injected clock, injected latency, recorded calls.
- A single composition root chooses the adapters and injects them. Nothing else
  references an adapter.
- Contract tests: one shared suite run against every adapter of a contract.
- Expected failures are returned as a typed result, never signalled by a crash or a
  pushed error.
- No dead code: a script, a scene or a resource appears with its first consumer.

### Layout

```
game/               the game, one folder per layer (table above)
  core/             runner motor, intents, the facts the player observes, race state,
                    and the tuning resource
  player/           the runner's scene: body, camera rig, intents read from the inputs,
                    and what the body observes around it (floor, walls, ledges)
  world/            checkpoints and race lines
  ui/               timer display and debug display
  levels/           course scenes; test_course.tscn is the main scene for now
addons/gut/         GUT 9.7.1, the test framework (vendored, MIT, not exported)
tests/              headless tests, one script per subject: test_<subject>.gd; the other
                    scripts are their helpers (written sequences of intents, test pilot,
                    a runner without a scene, the bases of the replay and course tests)
tools/              the gate tools (Python, standard library only)
.agents/            the roles AI assistants play and the skills they load (README.md)
.claude/            copies of .agents/ for Claude Code (kept identical by the gate)
docs/specs/         one spec per request, written by the sparring partner
docs/harness/       what each full round of the harness taught, with the agents' reports
assets/             models, animations and sounds, with CREDITS.md
```

Do not create empty folders: a folder appears with its first file.

## Working rules

- Versions are resolved with the registry at install time, never from memory:
  `pip index versions <package>` for the Python tooling, the release page of the
  project for Godot and its add-ons (`gh release list --repo <owner>/<name>`).
- Read the official documentation of a tool before configuring it. Report any
  incompatibility instead of working around it.
- Never say "it works" without having run it.
- No secret in the repository, ever. Configuration comes from `project.godot` and from
  the tuning resource; there is no environment configuration.
- No asset without a verified licence: every file of `assets/` has its line in
  `assets/CREDITS.md` (source, author, licence). No model, animation or sound is
  created here: primitives while prototyping, then free packs.
- Keyboard bindings use physical keys, and every action exists on keyboard and mouse
  and on gamepad.
- Every wall of a level is a single block (one physics object): the runner's motor
  recognises a wall by its object, so a wall made of two blocks could be climbed twice.
  A wall that must not be run along goes in the `no_wall_run` group.
- What the player observes for the motor never depends on where the visible body
  looks: the visible body is presentation only.

## Out of scope

- Anything from a later roadmap step while an earlier one is not validated by the
  owner (the roadmap is in `README.md`).
- Any server, backend, account or paid service before roadmap step 5, and any Steam
  commitment before the owner decides it.
- Mobile: nothing is developed for it now, and nothing may block it later (few
  buttons, light rendering, highlighted targets).
- Free destruction of the scenery: only predefined, highlighted objects can be
  sabotaged.
- Creating 3D models, animations, sounds or music.
- Cosmetics, leaderboards, modes with more than two players, a course editor.
