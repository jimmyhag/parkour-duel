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
series of long jumps that need both the run-up and a held jump, steps to climb, a low
passage (a run-up, a ramp going down, then an obstacle too low to stand under: slide),
a big drop (higher than what a landing forgives: roll), a ledge too high to jump onto
(mantle), a gap too long to jump with a wall along it (wall run), a void between two
walls facing each other with its far side higher (wall jumps), and a last combination
of a low obstacle, a gap along a wall and a ledge before the finish line. The walls
meant to be run along are blue-grey. The timer starts at the start line and stops at the finish line; the best
time of the session stays on screen (nothing is saved to disk). Each section opens with
a checkpoint: falling off the course brings the runner back to the last one reached,
and the timer keeps running.

Every value of the feel (speeds, gravities, coyote time, jump buffer, slide, roll,
hard landing, momentum, mantle, wall run, wall jump, flow, tricks, camera) is in
`game/core/movement_tuning.tres`. When the game
runs from the project folder, F4 reads that file again without restarting.

## Working on the project

The rules, the commands and the architecture are in [AGENTS.md](AGENTS.md); the way
the AI assistants work (spec, developer, inspector) is in
[.agents/README.md](.agents/README.md). In short, with
[`just`](https://github.com/casey/just) and Python 3.13 installed:

```sh
just setup            # once per checkout: tooling and Godot import cache
just fetch-templates  # once per machine: export templates for the builds (about 1 GB)
just preflight        # after every change: types, lint, tests but the course replays, boundaries
just test-course      # the course replays alone
just check            # before every commit: every test, course replays included, and the release builds
```

## Controls

Keyboard keys are bound by their position, not by the letter they print: "W, A, S, D"
below are the keys at those places on a QWERTY keyboard (Z, Q, S, D on an AZERTY one).

| Action | Keyboard and mouse | Gamepad |
| ------ | ------------------ | ------- |
| Move | W, A, S, D | Left stick |
| Turn the camera | Mouse | Right stick |
| Jump (hold to jump higher) | Space | A, or LB |
| Slide (hold), roll (press just before a high landing) | Left Ctrl | B, or RB |
| Trick, in the air (hold for more turns) | Left Shift | X |
| Back to the last checkpoint | R | Y |
| Restart the course | Backspace | Back (Select) |
| Release the mouse (a click takes it back) | Escape | none |
| Debug display (state, speeds, timers) | F3 | none |
| Reload the tuning file | F4 | none |

There is no sprint button: the runner accelerates up to its top speed. With a stick,
the speed aimed at is proportional to how far the stick is pushed beyond its dead
zone: a stick pushed halfway gives a little less than half of the top speed.

Slide: hold the slide button on the ground while running fast enough, or hold it while
landing. The runner gets low and passes under low obstacles. A slide takes no
acceleration from the stick: it slows down on flat ground, speeds up on a slope going
down, and only turns slowly. It ends when the button is released or when it gets too
slow; after a slide that got too slow, release the button and press it again to slide
once more. Under a low obstacle the runner stays low until there is room to stand up,
and cannot jump. With room above, jumping out of a slide keeps its speed.

Roll: a fall from high enough must be rolled. Press the slide button shortly before
touching the ground: the runner rolls and keeps its speed, and can jump out of the
roll. A button held since earlier does not count, it has to be pressed. Without the
press the landing is hard: most of the speed is lost, and for a moment the runner stays
slow and cannot jump. Nothing hurts the runner.

Momentum: a speed above the top speed (out of a slide down a slope, for example) is
kept in the air and only comes back down slowly on the ground while a direction is
held. Letting go of the stick brakes as usual.

The wall moves have no button of their own: they start by themselves from what the
runner does in the air.

Mantle: jump at a ledge too high to jump onto and keep pushing towards it. If its top
is within reach and free, the runner climbs onto it and stands there, setting off at
a reduced speed whatever speed it came with. The climb goes to the end: jump and slide
do nothing meanwhile.

Wall run: in the air, fast enough along the wall and high enough above the ground,
push anywhere but away from a wall beside you: along it, diagonally towards it, or
straight into it. Coming at the wall nearly head-on, too slow along it, gives no wall
run and leaves the wall free for later; a ledge within reach is then climbed instead. The runner runs along it for a moment, falling slowly, and keeps its speed; the
capsule leans towards the wall. The run ends after a while, where the wall
ends, if the runner gets too slow, when you push away from the wall, or on the ground.
A runner that is low (sliding, rolling, or under a low ceiling) neither runs along a
wall nor mantles.

Wall jump: press jump during a wall run, or just after leaving the wall, or just before
reaching it. The runner jumps up and away from the wall, keeping its speed along it;
releasing the button early makes the jump lower, as on the ground. The same wall
cannot be run along twice in a row: touch the ground or run along another wall first.
Jumping from one wall to the one facing it, again and again, climbs between them.

Tricks: in the air, after a jump, a wall jump or a fall from a ledge, press the trick
button. The direction pushed at that moment, measured against where the runner is
going, chooses the flip: ahead a front flip, behind a backflip, to a side a side flip,
no push a flat spin. One turn takes a little less than half a second; while the button
is held when a turn ends, another one starts, and once it is released the body finishes
the turn under way. During a front flip or a backflip, each press of jump adds a twist
(two at most per turn); during a trick, jump never makes the runner jump. A trick
changes nothing to the flight, but no wall run and no mantle starts before it is over.
Another press after a trick starts another one in the same jump, worth more. The tricks
pay at the landing, as moves of the flow: a trick finished just before the ground is
PERFECT (more points, a little speed); touching the ground before the end of a turn is
a CRASH (a hard landing that breaks the combo, and the tricks of the jump are lost). A
high fall still asks for a roll.

## Roadmap

| Step | Content | Status |
| ---- | ------- | ------ |
| 0 | Repository, Godot skeleton, harness and gates | done |
| 1 | Solo movement prototype | done: validated by the owner on 2026-11-14 |
| 2 | Tricks and flow | in progress: the flow gauge and combo (`docs/specs/flow-combo.md`), then the aerial tricks and the sounds (`docs/specs/air-tricks.md`), are built; the owner has not validated the step yet |
| 3 | Shooting and sabotage | not started |
| 4 | Local duel (ghost, then bot) | not started |
| 5 | Online PVP | not started |
| 6 | Art, audio, menus, release | not started |
