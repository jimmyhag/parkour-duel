class_name TrickTest
extends GutTest
## Base of the test scripts of the aerial tricks of the runner's motor (game/core): the
## runners they throw in the air, the intents they give them, and the flow that follows
## them as the course does. The tuning is the fixed one of MotorBody; the runners go
## along -Z.

const STEPS_PER_SECOND: int = 60
const PROJECT_TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const BACK: Vector3 = Vector3.BACK
const TOLERANCE: float = 0.001
const FRONT_FLIP: AirTrick.Flip = AirTrick.Flip.FRONT_FLIP
const BACKFLIP: AirTrick.Flip = AirTrick.Flip.BACKFLIP
const SIDE_FLIP: AirTrick.Flip = AirTrick.Flip.SIDE_FLIP
const SPIN: AirTrick.Flip = AirTrick.Flip.SPIN
const TRICK: RunnerEvent.Kind = RunnerEvent.Kind.TRICK
## The turn of the fixed tuning (0.65 s), and the perfect window (0.15 s), in fixed steps
## at 60 steps per second. Written out on purpose, not computed.
const TURN_STEPS: int = 39
const PERFECT_STEPS: int = 9
## The upward speed of a launched runner: its fall stays under the height of a roll.
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


## One step at which the motor announced `kind`, the runner in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, _tuning.top_speed, false)


## The motor of `body` announced these kinds at the step it just played, in this order,
## and nothing else.
func _assert_kinds(body: MotorBody, kinds: Array[RunnerEvent.Kind]) -> void:
	var announced: Array[RunnerEvent.Kind] = []
	for event: RunnerEvent in body.motor.events:
		announced.append(event.kind)
		if event.kind == TRICK:
			assert_not_null(event.trick, "a trick message carries its trick")
	assert_eq(announced, kinds, "the messages of the step")


## The tuning of the project, the one the player plays with: what the tests of the risk
## of a trick weigh.
func _project_tuning() -> MovementTuning:
	return load(PROJECT_TUNING) as MovementTuning


## The drop, in m, under the floor a runner jumps from, that a trick of one turn pressed
## with a held jump needs to be over before the ground, computed from `tuning`: the fall
## from the top of the jump lasts what the turn lasts beyond the rise, plus two fixed
## steps (a body seen on the floor one step after it reached it, and a step of margin).
func _drop_for_a_turn(tuning: MovementTuning) -> float:
	var rise: float = sqrt(2.0 * tuning.jump_height / tuning.rise_gravity)
	var fall: float = tuning.trick_turn_duration + 2.0 / STEPS_PER_SECOND - rise
	return maxf(0.5 * tuning.fall_gravity * fall * fall - tuning.jump_height, 0.0)


## From the ground, a held jump with a trick pressed `press_after` steps after the
## take-off (0: with the jump) pushing `push`, over a floor `drop` lower than the one it
## leaves, `twists` jump presses once the top of the jump is passed, then the landing,
## the flow following if there is one: returns the trick, if one started.
func _jump_with_a_trick(
	body: MotorBody,
	flow: FlowState,
	drop: float,
	push: Vector3,
	twists: int = 0,
	press_after: int = 0
) -> AirTrick:
	var take_off: MoveIntent = _trick(push) if press_after == 0 else _push(FORWARD)
	take_off.jump_pressed = true
	take_off.jump_held = true
	_play(body, flow, take_off)
	body.floor_height -= drop
	var steps: int = 0
	var presses: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		steps += 1
		var intent: MoveIntent = _trick(push) if steps == press_after else _push(FORWARD)
		intent.jump_held = body.motor.state == RunnerMotor.State.RISING
		if body.motor.state == RunnerMotor.State.FALLING and presses < twists:
			intent.jump_pressed = true
			presses += 1
		_play(body, flow, intent)
	var trick: AirTrick = body.motor.current_trick()
	_play(body, flow, _push(FORWARD))
	for event: RunnerEvent in body.motor.events:
		if event.trick != null:
			trick = event.trick
	return trick


## From the ground, a run, then a jump off a block with a backflip pressed at the
## take-off and `twists` jump presses once the top of the jump is passed, then the
## landing: returns the trick.
func _jump_with_a_backflip(body: MotorBody, flow: FlowState, twists: int) -> AirTrick:
	for step: int in 12:
		_follow(body, flow, _push(FORWARD))
	return _jump_with_a_trick(body, flow, _drop_for_a_turn(_tuning), BACK, twists)


## One step of the body, followed by the flow if there is one.
func _play(body: MotorBody, flow: FlowState, intent: MoveIntent) -> void:
	if flow == null:
		body.step(intent)
	else:
		_follow(body, flow, intent)


## A body just above the floor, thrown up at LAUNCH and forward at `speed`: its flight
## leaves time for a turn, and its fall stays under the height of a roll.
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
func _landing_step(make: Callable, push: Vector3) -> int:
	var body: MotorBody = make.call()
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_push(push))
		steps += 1
	return steps


func _flip_of(body: MotorBody) -> int:
	var trick: AirTrick = body.motor.current_trick()
	return -1 if trick == null else trick.flip


func _push(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## The trick pressed at this step, and held.
func _trick(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.trick_pressed = true
	intent.trick_held = true
	return intent


## The trick held, not pressed.
func _holding(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.trick_held = true
	return intent
