class_name TrickTest
extends GutTest
## Base of the test scripts of the aerial tricks of the runner's motor (game/core): the
## runners they throw in the air, the intents they give them (the trick button released
## with a recipe, the slide pressed to pose it), and the flow that follows them as the
## course does. The tuning is the fixed one of MotorBody; the runners go along -Z.

const STEPS_PER_SECOND: int = 60
const PROJECT_TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const BACK: Vector3 = Vector3.BACK
const TOLERANCE: float = 0.001
const FRONT_FLIP: TrickRecipe.Flip = TrickRecipe.Flip.FRONT_FLIP
const BACKFLIP: TrickRecipe.Flip = TrickRecipe.Flip.BACKFLIP
const SIDE_FLIP: TrickRecipe.Flip = TrickRecipe.Flip.SIDE_FLIP
const SPIN: TrickRecipe.Flip = TrickRecipe.Flip.SPIN
const TRICK: RunnerEvent.Kind = RunnerEvent.Kind.TRICK
const CRASH: RunnerEvent.Kind = RunnerEvent.Kind.CRASH
## The turn (0.35 s) and the twist (0.15 s) of the fixed tuning, its landing window
## (0.25 s) and its perfect window (0.1 s), in fixed steps at 60 steps per second.
## Written out on purpose, not computed.
const TURN_STEPS: int = 21
const TWIST_STEPS: int = 9
const LANDING_STEPS: int = 15
const PERFECT_STEPS: int = 6
## The upward speed of a launched runner: its flight leaves time for a double, and its
## fall stays under the height of a roll.
const LAUNCH: float = 15.5
## High enough above the floor for a flight of many turns.
const HIGH: float = 40.0
## More steps than any flight of these tests lasts.
const MANY_STEPS: int = 1200
## A wall at the left of a runner going along -Z, close to its side, and tall.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const A_WALL: int = 1
const CLOSE: float = 0.3
const TALL: float = 10.0
## High enough above the floor for a wall run.
const ALONG_A_WALL: float = 3.0
## Where a runner is when it reaches the face of a ledge: half a metre above its floor.
const IN_THE_AIR: float = 0.5

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func _flow() -> FlowState:
	return FlowState.new(_tuning, STEPS_PER_SECOND)


## One step of the body, followed by the flow, as the course does it.
func _follow(body: MotorBody, flow: FlowState, intent: MoveIntent) -> void:
	body.step(intent)
	flow.follow(body.motor)


## One step of the body, followed by the flow if there is one.
func _play(body: MotorBody, flow: FlowState, intent: MoveIntent) -> void:
	if flow == null:
		body.step(intent)
	else:
		_follow(body, flow, intent)


## One step at which the motor announced `kind`, the runner in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, _tuning.top_speed, false)


## The motor of `body` announced these kinds at the step it just played, in this order,
## and nothing else.
func _assert_kinds(body: MotorBody, kinds: Array[RunnerEvent.Kind]) -> void:
	_assert_events(body.motor.events, kinds)


func _assert_events(events: Array[RunnerEvent], kinds: Array[RunnerEvent.Kind]) -> void:
	var announced: Array[RunnerEvent.Kind] = []
	for event: RunnerEvent in events:
		announced.append(event.kind)
		if event.kind == TRICK:
			assert_not_null(event.trick, "a trick message carries its trick")
	assert_eq(announced, kinds, "the messages of the step")


## The tuning of the project, the one the player plays with: what the tests of the risk
## of a trick weigh.
func _project_tuning() -> MovementTuning:
	return load(PROJECT_TUNING) as MovementTuning


## A body just above the floor, thrown up at LAUNCH and forward at `speed`: its flight
## leaves time for a double, and its fall stays under the height of a roll.
func _launched(speed: float = -1.0) -> MotorBody:
	if speed < 0.0:
		speed = _tuning.top_speed
	var body: MotorBody = MotorBody.new(_tuning, 0.01)
	body.velocity = FORWARD * speed + Vector3.UP * LAUNCH
	return body


## A body in the air beside a wall at its left, at the top speed.
func _beside_a_wall() -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, ALONG_A_WALL)
	body.velocity = FORWARD * _tuning.top_speed
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	return body


## A body high above the floor, thrown up and forward at the top speed: its flight lasts
## many turns.
func _high() -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, HIGH)
	body.velocity = FORWARD * _tuning.top_speed + Vector3.UP * LAUNCH
	return body


## The index of the step at which the motor of a body made by `make` sees the floor, the
## runner pushing `push` all along.
func _landing_step(make: Callable, push: Vector3 = Vector3.ZERO) -> int:
	var body: MotorBody = make.call()
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_push(push))
		steps += 1
	return steps


## A flight of a body made by `make`, followed by the flow if there is one: `recipe`
## released at the step `release`, the slide pressed at the step `press` (and held from
## it if `hold`), up to the step of the landing, played: what the motor announced there.
func _fly(
	make: Callable,
	flow: FlowState,
	recipe: TrickRecipe,
	release: int,
	press: int = -1,
	hold: bool = false
) -> MotorBody:
	var body: MotorBody = make.call()
	var landing: int = _landing_step(make)
	for step: int in landing + 1:
		var intent: MoveIntent = _release(recipe) if step == release else _push(Vector3.ZERO)
		intent.slide_pressed = step == press
		intent.slide_held = step == press or (hold and press >= 0 and step >= press)
		_play(body, flow, intent)
	return body


func _flip_of(body: MotorBody) -> int:
	var trick: AirTrick = body.motor.current_trick()
	return -1 if trick == null else trick.recipe.flip


func _push(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## The trick button held at this step, its drawing reading `recipe`.
func _drawing(recipe: TrickRecipe, direction: Vector3 = Vector3.ZERO) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.trick_held = true
	intent.trick_recipe = recipe
	return intent


## The trick button released at this step, its drawing reading `recipe`.
func _release(recipe: TrickRecipe, direction: Vector3 = Vector3.ZERO) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.trick_released = true
	intent.trick_recipe = recipe
	return intent


## The slide pressed at this step, and held.
func _slide(direction: Vector3 = Vector3.ZERO) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.slide_pressed = true
	intent.slide_held = true
	return intent


func _backflip(turns: int = 1, twists: int = 0) -> TrickRecipe:
	return TrickRecipe.drawn(BACKFLIP, turns, twists)


func _front_flip() -> TrickRecipe:
	return TrickRecipe.drawn(FRONT_FLIP)
