extends GutTest
## Landings (game/core): above the fall height that asks for it, a slide pressed just
## before the floor makes a roll, anything else a hard landing. The tuning is the fixed
## one of MotorBody.

const STEP: float = MotorBody.STEP
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const ROLLING: RunnerMotor.State = RunnerMotor.State.ROLLING
const HARD_LANDING: RunnerMotor.State = RunnerMotor.State.HARD_LANDING
const GROUNDED: RunnerMotor.State = RunnerMotor.State.GROUNDED
## The durations of the fixed tuning, in fixed steps at 60 steps per second: the roll
## window (0.20 s), the roll (0.5 s) and the hard landing (0.35 s). Written out on
## purpose, not computed: a change of rounding must fail here.
const ROLL_WINDOW_STEPS: int = 12
const ROLL_STEPS: int = 30
const HARD_LANDING_STEPS: int = 21
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600
const NEVER: int = -1


func test_a_successful_roll_keeps_the_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: float = tuning.roll_fall_height * 1.5
	var landing_step: int = _landing_step(tuning, high)

	var body: MotorBody = _land(tuning, high, landing_step - ROLL_WINDOW_STEPS)
	var pressed_last: MotorBody = _land(tuning, high, landing_step)

	assert_eq(pressed_last.motor.state, ROLLING, "pressed at the very step of the landing")
	assert_eq(body.motor.state, ROLLING, "pressed at the first step of the window")
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "the speed is kept")
	for i: int in ROLL_STEPS - 1:
		body.step(_run(Vector3.ZERO))
		assert_eq(body.motor.state, ROLLING, "still rolling at step %d" % i)
		assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "at the same speed")
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "then the runner is back on its feet")
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "nothing was lost")


func test_a_hard_landing_costs_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var kept: float = tuning.top_speed * tuning.hard_landing_speed_ratio

	var body: MotorBody = _land(tuning, tuning.roll_fall_height * 1.5)

	assert_eq(body.motor.state, HARD_LANDING)
	assert_almost_eq(body.horizontal_speed(), kept, TOLERANCE, "cut down to the tuned share")
	for i: int in HARD_LANDING_STEPS - 1:
		body.step(_run(FORWARD))
		assert_eq(body.motor.state, HARD_LANDING, "still landing at step %d" % i)
		assert_almost_eq(body.horizontal_speed(), kept, TOLERANCE, "pushing forward gives no more")
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "then the runner runs again")
	assert_gt(body.horizontal_speed(), kept, "and picks up speed")

	var slow: MotorBody = _dropped(tuning, tuning.roll_fall_height * 1.5)
	slow.velocity = FORWARD * tuning.top_speed / 2.0
	_fall_to_the_floor(slow)
	assert_eq(slow.motor.state, HARD_LANDING)
	assert_almost_eq(slow.horizontal_speed(), kept / 2.0, TOLERANCE, "the same share when slower")

	# From under the height that asks for a roll, a leap that tops above it.
	var leaping: MotorBody = _dropped(tuning, tuning.roll_fall_height * 0.75)
	leaping.velocity.y = sqrt(tuning.rise_gravity * tuning.roll_fall_height)
	_fall_to_the_floor(leaping)
	assert_eq(leaping.motor.state, HARD_LANDING, "the fall is measured from the highest point")


func test_a_slide_pressed_too_early_gives_no_roll() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: float = tuning.roll_fall_height * 1.5
	var too_early: int = _landing_step(tuning, high) - ROLL_WINDOW_STEPS - 1

	var body: MotorBody = _land(tuning, high, too_early)

	assert_eq(body.motor.state, HARD_LANDING, "one step before the window: a hard landing")


func test_a_slide_held_since_before_the_window_gives_no_roll() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: float = tuning.roll_fall_height * 1.5
	var too_early: int = _landing_step(tuning, high) - ROLL_WINDOW_STEPS - 1

	var body: MotorBody = _land(tuning, high, too_early, MANY_STEPS)

	assert_eq(body.motor.state, HARD_LANDING, "holding is not pressing: a hard landing")


func test_a_small_fall_is_landed_normally() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var low: float = tuning.roll_fall_height * 0.75
	var landing_step: int = _landing_step(tuning, low)

	var body: MotorBody = _land(tuning, low)
	var pressing: MotorBody = _land(tuning, low, landing_step - 1)

	assert_eq(body.motor.state, GROUNDED, "no hard landing")
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "no speed lost")
	assert_eq(pressing.motor.state, GROUNDED, "and no roll, even with the slide pressed")
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "it runs on")
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE)


func test_no_jump_during_a_hard_landing() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _land(tuning, tuning.roll_fall_height * 1.5)
	assert_eq(body.motor.state, HARD_LANDING)

	for i: int in HARD_LANDING_STEPS - 1:
		body.step(_jump(i == 0))
		assert_eq(body.motor.state, HARD_LANDING, "no jump at step %d" % i)
		assert_eq(body.velocity.y, 0.0, "it stays on the floor")

	body.step(_jump(false))
	assert_eq(body.motor.state, GROUNDED, "the refused jump does not start afterwards")
	body.step(_jump(true))
	assert_eq(body.motor.state, RunnerMotor.State.RISING, "a new press jumps, once landed")


func test_jumping_during_a_roll_keeps_the_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: float = tuning.roll_fall_height * 1.5
	var body: MotorBody = _land(tuning, high, _landing_step(tuning, high) - 1)
	assert_eq(body.motor.state, ROLLING)
	var roll_speed: float = body.horizontal_speed()

	body.step(_jump(true))

	assert_eq(body.motor.state, RunnerMotor.State.RISING, "it jumps")
	var grounded: MotorBody = MotorBody.new(tuning)
	grounded.step(_jump(true))
	assert_eq(body.velocity.y, grounded.velocity.y, "as strong as a jump from a standstill")
	assert_almost_eq(body.horizontal_speed(), roll_speed, TOLERANCE, "with the speed of the roll")


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## Going forward with the jump held down, pressed at this step or not.
func _jump(pressed: bool) -> MoveIntent:
	var intent: MoveIntent = _run(FORWARD)
	intent.jump_pressed = pressed
	intent.jump_held = true
	return intent


## A body in the air, `height` above the floor, going forward at the top speed.
func _dropped(tuning: MovementTuning, height: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, height)
	body.velocity = FORWARD * tuning.top_speed
	return body


## Lets a body in the air come down, pushing forward as fast as it goes, up to its first
## step on the floor.
func _fall_to_the_floor(body: MotorBody) -> void:
	var pace: float = minf(body.horizontal_speed() / body.motor.tuning.top_speed, 1.0)
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_run(FORWARD * pace))
		steps += 1
	body.step(_run(FORWARD * pace))


## The index of the first step at which a body dropped from `height` is seen on the
## floor by its motor.
func _landing_step(tuning: MovementTuning, height: float) -> int:
	var body: MotorBody = _dropped(tuning, height)
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	return steps


## Drops a body from `height` and returns it right after its first step on the floor.
## The slide is pressed at the step `press_step`, if any, and held for `held_steps`.
func _land(
	tuning: MovementTuning, height: float, press_step: int = NEVER, held_steps: int = 1
) -> MotorBody:
	var body: MotorBody = _dropped(tuning, height)
	for i: int in _landing_step(tuning, height) + 1:
		var intent: MoveIntent = _run(FORWARD)
		intent.slide_pressed = i == press_step
		intent.slide_held = press_step != NEVER and i >= press_step and i < press_step + held_steps
		body.step(intent)
	return body
