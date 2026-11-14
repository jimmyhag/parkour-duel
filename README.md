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

The game opens on its start screen: SOLO PRACTICE, DUEL VS GHOST, DUEL VS BOT (see
"Local duel" below) and TRICK PARK (see "Trick Park" below). Solo practice is the test course, a short timed run made of grey
blocks: a start
platform and its start line, a straight to gather speed with a bridge in its middle, a
series of short jumps, a
series of long jumps that need both the run-up and a held jump, steps to climb, a low
passage (a run-up, a ramp going down, then an obstacle too low to stand under: slide),
a big drop (higher than what a landing forgives: roll), a ledge too high to jump onto
(mantle), a gap too long to jump with a wall along it (wall run), a void between two
walls facing each other with its far side higher (wall jumps), and a last combination
of a low obstacle, a gap along a wall and a ledge before the finish line. The walls
meant to be run along are blue-grey. Four blocks glow orange: they are targets (see
"Shooting and sabotage" below). The timer starts at the start line and stops at the finish line; the best
time of the session stays on screen, from one solo practice to the next (nothing is
saved to disk). Each section opens with
a checkpoint: falling off the course brings the runner back to the last one reached,
and the timer keeps running.

Every value of the feel (speeds, gravities, coyote time, jump buffer, slide, roll,
hard landing, momentum, mantle, wall run, wall jump, flow, tricks, sabotage, camera) is in
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
| Turn the camera (not while the trick is held) | Mouse | Right stick |
| Jump (hold to jump higher) | Space | A |
| Slide (hold), roll (press just before a high landing), pose a trick (press just before the ground) | Left Ctrl | B, or RB |
| Trick: hold to draw it, release in the air to start it | F | LB |
| Draw a trick, the trick held | Mouse | Right stick |
| Aim (hold) | Right mouse button | Left trigger (LT) |
| Shoot, while aiming | Left mouse button | Right trigger (RT) |
| Back to the last checkpoint | R | Y |
| Restart the course (solo practice only) | Backspace | Back (Select) |
| Back to the start screen, which frees the mouse | Escape | Start |
| Menus: change the choice | Up and Down arrows, or W and S | Left stick, or the cross |
| Menus: take the choice | Space | A |
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

Tricks are drawn, then posed. Hold the trick button: the camera stops turning, the
mouse or the right stick draws instead, and a round pad in the middle of the screen
shows the trace as it goes. A quick stroke chooses the flip: up a front flip, down a
backflip, left or right a side flip that way. The same stroke again adds a turn (double,
then triple, no more); going back between two strokes is not read, even round a short
turn. An arc of 100 degrees or more after a front flip or a backflip adds a twist (two
per turn at most; a bigger arc, from 300 degrees, two at once), whether it starts with a
straight part or not, and a stroke that curls into such an arc is the flip and the
twist; a whole circle on its own is a flat spin (360), and each circle after it a turn
more (720, 1080). On the right stick, a stroke is a flick (push it, even at 60 %, and
let it spring back: the stroke ends as the stick is back in its dead zone) and an arc is
the stick rolled round its rim. On the pad, each stroke read gets an arrow, each twist
and each spin a coloured arc; the name of the recipe shows under the pad (and above the
flow gauge), or ? while nothing reads yet; when the trick is complete, the hand at rest,
the border of the pad turns green and thickens: that is the trick that will start. Every
threshold of the drawing is in the tuning file (group Tricks). The trick starts as the button is released, if the runner is
in the air (after a jump, a wall jump or a fall from a ledge; not along a wall, in a
mantle or while aiming) and has done no trick in this jump yet: draw while running,
then release just after the jump. Released on the ground, nothing starts and the
drawing is forgotten; a drawing that does not read starts nothing. A press without
drawing starts the trick of the context, worth half a front flip: a front flip when
running, a backflip at a stop or just after a wall jump, a side flip away from the wall
when leaving a wall run. A turn takes 0.35 s and each twist adds 0.3 s: a single fits
in a jump on the flat; measured with the tuning file, a held jump on the flat lasts 36
fixed steps, so a single with a twist (39 steps) asks for a small drop, and a double (42
steps) for a drop or a wall jump. One trick per jump. A finished trick must be posed: press the slide at most 0.25 s before
touching the ground, PERFECT within the last 0.1 s (more points, and a little speed, up
to the top speed plus that gain). No press within that window, or the trick not over at
the ground, is a CRASH (a hard landing that breaks the combo, and the trick earns
nothing); a press too early is lost, and can be made again. The press that poses is a
slide press like any other: a high fall rolls (the press that poses a trick rolls within
the whole landing window), and on the flat, held, it starts a slide
(a perfect one within its own window). A trick finished before a wall run or a mantle
pays at its start, without a press. Points: front flip and backflip 200, side flip and
spin 250, the trick of the context 100; a double times 2.5, a triple times 4, each
twist 150 more; PERFECT 50 % more; then, as any move of the flow, the same recipe (flip,
turns, twists) again is worth less, and the combo multiplies. The flow judges a move
against its last ten moves, and a combo that ends by its delay keeps them: a break on
the ground does not make the same tricks new again (an error, a fall or a restart
does). A trick changes nothing
to the flight, but no wall run and no mantle starts before it is over; during a trick,
jump never makes the runner jump.

Shooting and sabotage: hold the aim to bring the camera over the right shoulder; a
reticle appears in the middle of the screen. Aiming slows the runner down on the ground,
running, sliding or rolling (to 60 % of its top speed), and starts no trick; in the air
it changes nothing; time itself never slows down. Shooting fires at whatever is in the
middle of the screen, once the aim has been held for a quarter of a second without a
break, counted on the ground only and again for every shot (so every shot costs that
much slowed running; the count waits in the air), and only at a target: one of the orange blocks, within 60 m,
ready, and paid for with the ammunition the flow gives (the platform, the obstacle and
the barrier cost one, the bridge two). The reticle shows a ring on a target the shot
would hit, and a slash on one the ammunition does not pay for; otherwise a shot does
nothing and costs nothing. A target hit flashes red for 1 s, then its effect lasts a few
seconds: the platform of the long jumps vanishes (5 s), the bridge of the run-up falls
away and leaves a 10 m gap no jump crosses (6 s), an obstacle falls onto the way after
the big drop (6 s: too high to jump over, jump at it and climb over it), a barrier rises across the low passage
(4 s: jump at it and climb over it). Then it comes back, never onto a runner (it waits
for its place to be free), rests for 3 s and glows again. A runner where the effect
starts is sabotaged: its combo is broken and its gauge loses a tier, as on a hard
landing. A platform or a bridge whose warning is over waits while a runner is in the air
above it; once delayed so, it also waits for its zone to be empty, so that a runner
landing back on it and running off is not hit (a runner standing on it when a warning
ends without delay is hit). In solo
practice the runner shoots its own scenery, to practise; in a duel, only the
opponent's.

Local duel: two identical copies of the course side by side, 4 m apart, the player's on
the left. Choose DUEL VS BOT, or DUEL VS GHOST once a solo run is finished in the
session. A countdown (3, 2, 1, GO) holds both runners at their start; both timers start
at GO, and both runners start with 2 ammunition (a rematch gives them again). The first
over the finish line wins; at the same step, the higher style score; the same score is a
draw. Against the bot, after 3 minutes, if nobody finished, the farthest checkpoint
wins, then the style score. Against the ghost there is no time limit: the round ends
when the ghost crosses the finish line, and a player not finished by then loses. The ghost, half transparent, replays the best solo run of
the session step by step: it touches nothing and shoots nothing. The bot, orange, runs
the course with the pilot the tests use, towards the next checkpoint, does no trick,
and sabotages a target of your lane when it has the ammunition, the target is within
its range and on a clear line from its head and you are less than 25 m before it and getting closer: it aims for 0.8 s,
slowed like any runner that aims, then shoots. It never sabotages the same target twice
before you reach a new checkpoint, and does not start an aim when a jump comes before
the aim would end. Only the
targets of the opposing lane can be shot, from as far as the section before them. Next
to your timer, the gap with the opponent at your last common checkpoint (+1.24: you
are behind). Restarting does not exist in a duel: the result screen offers REMATCH
(everything from zero, the countdown again) and MENU; Escape or Back also goes back to
the start screen. The opponent's flow and ammunition show only on the debug display
(F3).

Trick Park: a flat esplanade of 120 m by 120 m, to try the tricks at every height.
Grey blocks of 1, 2, 3, 5 and 8 m stand in a row ahead of the start point; the 5 m and
8 m ones are climbed by lighter, narrower steps of 2.5 m, the others by a jump or a mantle. To the
left, two blue-grey walls 4 m apart face each other, for wall jumps; to the right, a
long blue-grey wall to run along. No timer, no target, no opponent: the flow, its
display and its sounds are there. R or Y brings the runner back to the start point,
Escape or Start back to the start screen.

## Roadmap

| Step | Content | Status |
| ---- | ------- | ------ |
| 0 | Repository, Godot skeleton, harness and gates | done |
| 1 | Solo movement prototype | done: validated by the owner on 2026-11-14 |
| 2 | Tricks and flow | built: the flow gauge and combo (`docs/specs/flow-combo.md`), the aerial tricks and the sounds (`docs/specs/air-tricks.md`), then tricks drawn and posed, and the Trick Park (`docs/specs/trick-gestures.md`); chained without validation on the owner's delegation (2026-11-14), judged at stop point 3 |
| 3 | Shooting and sabotage | built: aiming, shooting and the four sabotageable targets, on the runner's own course (`docs/specs/sabotage.md`); chained without validation on the owner's delegation, judged at stop point 3 |
| 4 | Local duel (ghost, then bot) | built: two lanes side by side, the start screen, the ghost of the best solo run, the bot, the round, the result and the rematch (`docs/specs/local-duel.md`); chained without validation on the owner's delegation, judged at stop point 3 |
| 5 | Online PVP | not started |
| 6 | Art, audio, menus, release | not started |
