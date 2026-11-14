# Competences

What each owner masters of the concepts applied in this project. Updated by the
sparring partner at the end of every session (`.agents/skills/sparring/SKILL.md`); the
owners may correct it by hand.

Levels: `discovered` (has heard of it), `applied` (uses it with the pattern in front of
them), `mastered` (explains why, chooses between alternatives, spots a misuse). An empty
cell means not assessed yet.

| Concept | Where it is applied | Jimmy | Last session |
| ------- | ------------------- | ----- | ------------ |
| Character state machine (detection, state, exits) | `game/core/`, first applied by `docs/specs/movement-base.md` | discovered | 2026-11-12 |
| Coyote time and jump buffer | `game/core/`, first applied by `docs/specs/movement-base.md` | discovered | 2026-11-12 |
| Facts (`player`) versus decisions (`core`) | `game/core/`, `game/player/` | discovered | 2026-11-12 |
| Intents, fixed step and replayed tests | `game/core/`, `tests/` | discovered | 2026-11-12 |
| Input map (named actions, physical keys) | `project.godot` | discovered | 2026-11-12 |
| Timing tolerances on other moves (roll, wall-jump) | `docs/specs/movement-ground.md` and `docs/specs/movement-walls.md` | discovered | 2026-11-12 |
| Reactive test pilot versus a recorded sequence, and proving it can fail | `tests/`, first applied by `docs/specs/reactive-replays.md` | discovered | 2026-11-12 |
| State crossings: what each move becomes in the air, under a ceiling, after another | `game/core/`, first reviewed by `docs/specs/movement-walls.md` | discovered | 2026-11-13 |
| Combo economy: guards against repetition, risk against reward | `game/core/`, first applied by `docs/specs/flow-combo.md` | discovered | 2026-11-14 |
| Dated events produced by the simulation and counted by another state | `game/core/`, first applied by `docs/specs/flow-combo.md` | discovered | 2026-11-14 |
| Composing tricks from building blocks rather than a fixed list | `game/core/`, first applied by `docs/specs/air-tricks.md` | discovered | 2026-11-14 |
| Small object state machines driven by dated messages | `game/core/`, first applied by `docs/specs/sabotage.md` | discovered | 2026-11-14 |
| A round state in `core` fed by dated messages, ready for the network | `game/core/`, first applied by `docs/specs/local-duel.md` | discovered | 2026-11-14 |
| Separating a gesture (input presentation) from its recipe (logic) | `game/core/`, `game/player/`, first applied by `docs/specs/trick-gestures.md` | discovered | 2026-11-14 |
