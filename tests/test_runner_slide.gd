extends GutTest
## The slide (game/core): how it starts, how its speed evolves on the flat and on a
## slope, how it ends, and what a low ceiling changes. The tuning is the fixed one of
## MotorBody.

const STEP: float = MotorBody.STEP
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const SLIDING: RunnerMotor.State = RunnerMotor.State.SLIDING
const GROUNDED: RunnerMotor.State = RunnerMotor.State.GROUNDED
const FALLING: RunnerMotor.State = RunnerMotor.State.FALLING
## More steps than any slide of these tests lasts.
const MANY_STEPS: int = 600


func test_the_slide_starts_on_the_floor_with_enough_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var fast: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var just_enough: MotorBody = MotorBody.running(tuning, FORWARD, tuning.slide_min_speed)
	assert_eq(fast.motor.state, GROUNDED, "standing while the slide is not held")

	fast.step(_slide(FORWARD))
	just_enough.step(_slide(FORWARD))

	assert_eq(fast.motor.state, SLIDING, "it slides")
	assert_eq(just_enough.motor.state, SLIDING, "the least speed is enough")


func test_the_slide_is_refused_without_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var too_slow: float = tuning.slide_min_speed - 0.1
	var body: MotorBody = MotorBody.running(tuning, FORWARD, too_slow)
	var pace: Vector3 = FORWARD * too_slow / tuning.top_speed

	for i: int in 10:
		body.step(_slide(pace))
		assert_eq(body.motor.state, GROUNDED, "still standing at step %d" % i)
	assert_almost_eq(body.horizontal_speed(), too_slow, TOLERANCE, "and running as before")


func test_the_slide_does_not_start_in_the_air() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = MotorBody.new(tuning, 1000.0)
	body.velocity = FORWARD * tuning.top_speed

	for i: int in 10:
		body.step(_slide(FORWARD))
		assert_eq(body.motor.state, FALLING, "still falling at step %d" % i)


func test_holding_the_slide_while_landing_starts_it() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = MotorBody.new(tuning, tuning.roll_fall_height / 4.0)
	body.velocity = FORWARD * tuning.top_speed

	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_slide(FORWARD))
		assert_eq(body.motor.state, FALLING, "falling until the floor")
		steps += 1
	body.step(_slide(FORWARD))

	assert_eq(body.motor.state, SLIDING, "it slides at its first step on the floor")
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, 0.1, "with the speed it had")


func test_the_slide_slows_down_on_the_flat_then_the_runner_stands_up() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var loss: float = tuning.slide_deceleration * STEP

	var seen: float = body.horizontal_speed()
	var seen_before: float = seen
	var sliding_steps: int = 0
	body.step(_slide(FORWARD))
	while body.motor.state == SLIDING and sliding_steps < MANY_STEPS:
		assert_almost_eq(seen - body.horizontal_speed(), loss, TOLERANCE, "at the tuned pace")
		seen_before = seen
		seen = body.horizontal_speed()
		sliding_steps += 1
		body.step(_slide(FORWARD))

	assert_gt(sliding_steps, 0, "it slid")
	assert_eq(body.motor.state, GROUNDED, "then it stands up")
	assert_lt(seen, tuning.slide_stop_speed, "once under the least speed of a slide")
	assert_gte(seen_before, tuning.slide_stop_speed, "and not before")


func test_the_slide_accelerates_downhill() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var steps: int = 10

	var body: MotorBody = _slider_on_a_slope(tuning, 20.0)
	var previous: float = body.horizontal_speed()
	for i: int in steps:
		body.step(_slide(FORWARD))
		assert_eq(body.motor.state, SLIDING, "it stays on the slope at step %d" % i)
		assert_gt(body.horizontal_speed(), previous, "faster at step %d" % i)
		previous = body.horizontal_speed()
	assert_almost_eq(body.velocity.dot(body.floor_normal), 0.0, TOLERANCE, "it follows the slope")

	# The pull is the fall gravity along the slope: nothing else sets it.
	var gain: float = _speed_gained(_slider_on_a_slope(tuning, 20.0), steps)
	assert_gt(gain, 0.0)
	assert_gt(_speed_gained(_slider_on_a_slope(tuning, 30.0), steps), gain, "steeper, faster")
	var heavier: MovementTuning = MotorBody.fixed_tuning()
	heavier.fall_gravity = tuning.fall_gravity * 2.0
	assert_gt(_speed_gained(_slider_on_a_slope(heavier, 20.0), steps), gain, "heavier, faster")


func test_releasing_the_slide_stands_the_runner_up() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _slider(tuning, tuning.top_speed)
	for i: int in 30:
		body.step(_slide(FORWARD))
	assert_eq(body.motor.state, SLIDING, "sliding while the slide is held")
	var slid_down_to: float = body.horizontal_speed()

	body.step(_run(FORWARD))

	assert_eq(body.motor.state, GROUNDED, "it stands up")
	assert_gt(body.horizontal_speed(), slid_down_to, "and runs: it picks up speed again")
	for i: int in 60:
		body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED)
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "up to the top speed")


func test_the_runner_stays_low_under_a_low_ceiling() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _slider(tuning, tuning.top_speed)
	body.can_stand = false

	for i: int in 10:
		body.step(_run(FORWARD))
		assert_eq(body.motor.state, SLIDING, "still low at step %d, slide released" % i)

	body.can_stand = true
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "it stands up as soon as there is room")


func test_the_runner_does_not_get_stuck_under_a_low_ceiling() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _slider(tuning, tuning.top_speed)
	body.can_stand = false

	var slowest: float = body.horizontal_speed()
	for i: int in MANY_STEPS:
		body.step(_slide(FORWARD))
		slowest = minf(slowest, body.horizontal_speed())
	var there: Vector3 = body.position
	body.step(_slide(FORWARD))

	assert_eq(body.motor.state, SLIDING, "still low")
	assert_almost_eq(
		slowest, tuning.slide_stop_speed, TOLERANCE, "never slower than the least speed"
	)
	assert_almost_eq(body.horizontal_speed(), tuning.slide_stop_speed, TOLERANCE, "it keeps it")
	var advance: float = (body.position - there).dot(FORWARD)
	assert_almost_eq(advance, tuning.slide_stop_speed * STEP, TOLERANCE, "and keeps going forward")


func test_no_jump_under_a_low_ceiling() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _slider(tuning, tuning.top_speed)
	body.can_stand = false

	var jump: MoveIntent = _slide(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	body.step(jump)

	assert_eq(body.motor.state, SLIDING, "no jump")
	assert_eq(body.velocity.y, 0.0, "it stays on the floor")


func test_jumping_while_sliding_keeps_the_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var faster: float = tuning.top_speed * 1.5
	var jumper: MotorBody = _slider(tuning, faster)
	var slider: MotorBody = _slider(tuning, faster)

	var jump: MoveIntent = _slide(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	jumper.step(jump)
	slider.step(_slide(FORWARD))

	assert_eq(jumper.motor.state, RunnerMotor.State.RISING, "a jump")
	var grounded: MotorBody = MotorBody.new(tuning)
	grounded.step(jump)
	assert_eq(jumper.velocity.y, grounded.velocity.y, "as strong as a jump from a standstill")
	assert_gt(jumper.horizontal_speed(), tuning.top_speed, "faster than the top speed")
	var slide_speed: float = slider.horizontal_speed()
	assert_almost_eq(jumper.horizontal_speed(), slide_speed, TOLERANCE, "the speed of the slide")


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## Going in `direction` with the slide held down (not pressed at this step).
func _slide(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.slide_held = true
	return intent


## A body that has just started to slide forward at about `speed`.
func _slider(tuning: MovementTuning, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, speed)
	body.step(_slide(FORWARD))
	return body


## A body sliding forward at the top speed down a slope of `degrees`.
func _slider_on_a_slope(tuning: MovementTuning, degrees: float) -> MotorBody:
	var body: MotorBody = _slider(tuning, tuning.top_speed)
	var angle: float = deg_to_rad(degrees)
	body.position = Vector3.ZERO
	body.floor_normal = Vector3(0.0, cos(angle), -sin(angle))
	return body


## The horizontal speed a body gains over `steps` steps of slide.
func _speed_gained(body: MotorBody, steps: int) -> float:
	var before: float = body.horizontal_speed()
	for i: int in steps:
		body.step(_slide(FORWARD))
	return body.horizontal_speed() - before
