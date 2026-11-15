extends GutTest
## The tempo of the runner's motor (game/core) with the tuning of the project, the one the
## player plays with (docs/specs/realistic-tempo.md): a run at the speed of a real runner,
## a lower jump that flies longer, a shorter and slower wall run, and a smaller speed bonus
## of the flow. The values of the spec are written out on purpose; the rules behind them
## are tested with the fixed tuning of MotorBody elsewhere. The runners go along -Z.

const TUNING: String = "res://game/core/movement_tuning.tres"
const STEP: float = MotorBody.STEP
const STEPS_PER_SECOND: int = 60
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
## The values of the spec, in m/s, s and m.
const TOP_SPEED: float = 6.5
const TIME_TO_TOP_SPEED: float = 0.4
const TIME_TO_STOP: float = 0.25
const JUMP_HEIGHT: float = 1.2
const FLIGHT_TIME: float = 0.72
const LEAST_JUMP_LENGTH: float = 4.5
const WALL_RUN_START_SPEED: float = 4.8
const LONGEST_WALL_RUN: float = 1.0
const TIER_3_TOP_SPEED: float = 7.15
## How far "about" a time of the spec may be, in s: three fixed steps.
const ABOUT: float = 0.05
## More steps than any move of these tests lasts.
const MANY_STEPS: int = 600
## A wall at the left of a runner going along -Z, close to its side, and tall; far above
## the floor, where no wall run lands.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const A_WALL: int = 1
const CLOSE: float = 0.3
const TALL: float = 10.0
const HIGH: float = 100.0

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = load(TUNING) as MovementTuning


func test_the_run_tops_out_at_a_human_speed() -> void:
	var body: MotorBody = MotorBody.new(_tuning)

	var steps: int = 0
	while body.horizontal_speed() < _tuning.top_speed - TOLERANCE and steps < MANY_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	var to_the_top: float = steps * STEP
	for i: int in STEPS_PER_SECOND:
		body.step(_run(FORWARD))
	var top: float = body.horizontal_speed()
	steps = 0
	while body.horizontal_speed() > 0.0 and steps < MANY_STEPS:
		body.step(_run(Vector3.ZERO))
		steps += 1
	var to_a_stop: float = steps * STEP

	assert_almost_eq(top, TOP_SPEED, TOLERANCE, "it runs at 6.5 m/s")
	assert_almost_eq(to_the_top, TIME_TO_TOP_SPEED, ABOUT, "reached in about 0.4 s")
	assert_almost_eq(to_a_stop, TIME_TO_STOP, ABOUT, "stopped in about 0.25 s")


func test_the_jump_is_lower_and_flies_longer() -> void:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var start: Vector3 = body.position
	var take_off: MoveIntent = _run(FORWARD)
	take_off.jump_pressed = true
	take_off.jump_held = true
	body.step(take_off)
	var steps: int = 1
	var apex: float = body.position.y
	while not body.on_floor and steps < MANY_STEPS:
		var flight: MoveIntent = _run(FORWARD)
		flight.jump_held = body.motor.state == RunnerMotor.State.RISING
		body.step(flight)
		steps += 1
		apex = maxf(apex, body.position.y)

	assert_true(body.on_floor, "back on the ground")
	assert_almost_eq(apex, JUMP_HEIGHT, 0.01, "it rose 1.2 m")
	assert_almost_eq(steps * STEP, FLIGHT_TIME, ABOUT, "it flew about 0.72 s")
	var length: float = start.distance_to(Vector3(body.position.x, start.y, body.position.z))
	assert_gte(length, LEAST_JUMP_LENGTH, "it covered at least 4.5 m")


func test_the_wall_run_is_shorter_and_slower() -> void:
	assert_almost_eq(_tuning.wall_run_start_speed, WALL_RUN_START_SPEED, TOLERANCE, "4.8 m/s")
	var just_too_slow: MotorBody = _beside_a_wall(WALL_RUN_START_SPEED - 0.05)
	just_too_slow.step(_run(FORWARD * just_too_slow.horizontal_speed() / _tuning.top_speed))
	assert_eq(just_too_slow.motor.state, RunnerMotor.State.FALLING, "under 4.8 m/s: no wall run")
	var just_fast_enough: MotorBody = _beside_a_wall(WALL_RUN_START_SPEED + 0.01)
	just_fast_enough.step(_run(FORWARD * just_fast_enough.horizontal_speed() / _tuning.top_speed))
	var running: RunnerMotor.State = just_fast_enough.motor.state
	assert_eq(running, RunnerMotor.State.WALL_RUNNING, "from 4.8 m/s: a wall run")

	# At the top speed, pushing along the wall, never jumping: the longest wall run.
	var body: MotorBody = _beside_a_wall(_tuning.top_speed)
	var steps: int = 0
	body.step(_run(FORWARD))
	while body.motor.state == RunnerMotor.State.WALL_RUNNING and steps < MANY_STEPS:
		steps += 1
		body.step(_run(FORWARD))

	assert_gt(steps, 0, "a wall run")
	assert_lte(steps * STEP, LONGEST_WALL_RUN + TOLERANCE, "at most 1.0 s")
	assert_gte(steps * STEP, LONGEST_WALL_RUN - ABOUT, "and about all of it at the top speed")


func test_the_flow_speed_bonus_is_reduced() -> void:
	var flow: FlowState = FlowState.new(_tuning, STEPS_PER_SECOND)
	flow.gauge = flow.max_gauge()
	assert_eq(flow.tier(), _tuning.flow_tier_count, "a runner at tier 3")
	var body: MotorBody = MotorBody.new(_tuning)

	# The flow follows the runner, its gauge kept full: out of a combo, it drops at every
	# step.
	var fastest: float = 0.0
	for i: int in 2 * STEPS_PER_SECOND:
		body.step(_run(FORWARD))
		flow.follow(body.motor)
		flow.gauge = flow.max_gauge()
		body.motor.top_speed_bonus = flow.speed_bonus()
		fastest = maxf(fastest, body.horizontal_speed())

	assert_eq(flow.tier(), _tuning.flow_tier_count, "still at tier 3")
	assert_almost_eq(body.horizontal_speed(), TIER_3_TOP_SPEED, TOLERANCE, "it runs at 7.15 m/s")
	assert_almost_eq(fastest, TIER_3_TOP_SPEED, TOLERANCE, "and never faster")


## A body high in the air beside a wall at its left, going along it at `speed`.
func _beside_a_wall(speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, HIGH)
	body.velocity = FORWARD * speed
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	return body


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent
