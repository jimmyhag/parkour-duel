class_name TrickTest
extends GutTest
## Base of the test scripts of the aerial tricks of the runner's motor (game/core): the
## runners they throw in the air, the intents they give them, and the flow that follows
## them as the course does. The tuning is the fixed one of MotorBody; the runners go
## along -Z.

const STEPS_PER_SECOND: int = 60
const FORWARD: Vector3 = Vector3.FORWARD
const BACK: Vector3 = Vector3.BACK
const TOLERANCE: float = 0.001
const FRONT_FLIP: AirTrick.Flip = AirTrick.Flip.FRONT_FLIP
const BACKFLIP: AirTrick.Flip = AirTrick.Flip.BACKFLIP
const SIDE_FLIP: AirTrick.Flip = AirTrick.Flip.SIDE_FLIP
const SPIN: AirTrick.Flip = AirTrick.Flip.SPIN
const TRICK: RunnerEvent.Kind = RunnerEvent.Kind.TRICK
## The turn of the fixed tuning (0.45 s), and the perfect window (0.15 s), in fixed steps
## at 60 steps per second. Written out on purpose, not computed.
const TURN_STEPS: int = 27
const PERFECT_STEPS: int = 9
## The upward speed of a launched runner: its fall stays under the height of a roll.
const LAUNCH: float = 14.0
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


## From the ground, a jump with a backflip pressed at the take-off, `twists` jump presses
## once the top of the jump is passed, then the landing: returns the trick.
func _jump_with_a_backflip(body: MotorBody, flow: FlowState, twists: int) -> AirTrick:
	for step: int in 12:
		_follow(body, flow, _push(FORWARD))
	var take_off: MoveIntent = _trick(BACK)
	take_off.jump_pressed = true
	take_off.jump_held = true
	_follow(body, flow, take_off)
	var trick: AirTrick = body.motor.current_trick()
	var steps: int = 0
	var presses: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		steps += 1
		var intent: MoveIntent = _push(FORWARD)
		intent.jump_held = body.motor.state == RunnerMotor.State.RISING
		if body.motor.state == RunnerMotor.State.FALLING and presses < twists:
			intent.jump_pressed = true
			presses += 1
		_follow(body, flow, intent)
	_follow(body, flow, _push(FORWARD))
	return trick


## The index of the step at which a body made by `make`, pushing nowhere, stops rising.
func _apex_step(make: Callable) -> int:
	var body: MotorBody = make.call()
	var steps: int = 0
	while body.velocity.y > 0.0 and steps < MANY_STEPS:
		body.step(_push(Vector3.ZERO))
		steps += 1
	return steps


## The highest altitude a body made by `make` reaches, pushing nowhere.
func _top_of_the_flight(make: Callable) -> float:
	var body: MotorBody = make.call()
	var top: float = body.position.y
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_push(Vector3.ZERO))
		top = maxf(top, body.position.y)
		steps += 1
	return top


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
