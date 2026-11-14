extends GutTest
## The perfect slide (game/core): a slide that starts within a short window around a
## landing gains speed, and the motor announces it as a perfect slide; a high landing
## stays a roll. The tuning is the fixed one of MotorBody; the runners go along -Z.

const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const SLIDING: RunnerMotor.State = RunnerMotor.State.SLIDING
const SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.SLIDE
const PERFECT_SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.PERFECT_SLIDE
## The perfect slide window of the fixed tuning (0.15 s), in fixed steps at 60 steps per
## second. Written out on purpose, not computed.
const WINDOW_STEPS: int = 9
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600
const NEVER: int = -1

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_a_slide_started_right_at_the_landing_is_perfect() -> void:
	var low: float = _tuning.roll_fall_height / 4.0
	var landing_step: int = _landing_step(low, _tuning.top_speed)
	var plain: MotorBody = _land(low, _tuning.top_speed, 0)

	for press_step: int in [landing_step - WINDOW_STEPS, landing_step - 1, landing_step]:
		var context: String = "pressed %d steps before the floor" % (landing_step - press_step)
		var body: MotorBody = _land(low, _tuning.top_speed, press_step)

		assert_eq(body.motor.state, SLIDING, context + ": it slides")
		_assert_announced(body, PERFECT_SLIDE, context)
		var gain: float = body.horizontal_speed() - plain.horizontal_speed()
		assert_almost_eq(gain, _tuning.perfect_slide_speed_gain, TOLERANCE, context + ": faster")
		assert_almost_eq(body.velocity.normalized(), FORWARD, Vector3.ONE * TOLERANCE, "forwards")

	assert_eq(plain.motor.state, SLIDING, "pressed long before the floor, held: it slides")
	_assert_announced(plain, SLIDE, "pressed long before the floor")
	var too_early: MotorBody = _land(low, _tuning.top_speed, landing_step - WINDOW_STEPS - 1)
	_assert_announced(too_early, SLIDE, "pressed one step before the window")
	var same: float = too_early.horizontal_speed() - plain.horizontal_speed()
	assert_almost_eq(same, 0.0, TOLERANCE, "one step before the window: no gain")


func test_a_slide_started_right_after_the_landing_is_perfect() -> void:
	var low: float = _tuning.roll_fall_height / 4.0
	var plain: MotorBody = _slide_after_landing(low, WINDOW_STEPS + 1)
	assert_eq(plain.motor.state, SLIDING, "one step after the window: it slides")
	_assert_announced(plain, SLIDE, "one step after the window")

	for steps_after: int in [1, WINDOW_STEPS]:
		var context: String = "pressed %d steps after the landing" % steps_after
		var body: MotorBody = _slide_after_landing(low, steps_after)

		assert_eq(body.motor.state, SLIDING, context + ": it slides")
		_assert_announced(body, PERFECT_SLIDE, context)
		var gain: float = body.horizontal_speed() - plain.horizontal_speed()
		assert_almost_eq(gain, _tuning.perfect_slide_speed_gain, TOLERANCE, context + ": faster")


func test_a_slide_out_of_the_window_is_a_plain_slide() -> void:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	for i: int in WINDOW_STEPS * 2:
		body.step(_run(FORWARD))
	assert_almost_eq(body.horizontal_speed(), _tuning.top_speed, TOLERANCE, "a runner on the floor")

	body.step(_slide(FORWARD, true))

	assert_eq(body.motor.state, SLIDING, "it slides")
	_assert_announced(body, SLIDE, "a slide long after any landing")
	var one_step_of_slide: float = _tuning.slide_deceleration * MotorBody.STEP
	var expected: float = _tuning.top_speed - one_step_of_slide
	assert_almost_eq(body.horizontal_speed(), expected, TOLERANCE, "without any gain")


func test_the_gain_of_a_perfect_slide_respects_the_absolute_cap() -> void:
	var low: float = _tuning.roll_fall_height / 4.0
	var almost_the_cap: float = (
		_tuning.max_horizontal_speed - _tuning.perfect_slide_speed_gain / 2.0
	)
	var landing_step: int = _landing_step(low, almost_the_cap)

	var body: MotorBody = _land(low, almost_the_cap, landing_step - 1)

	_assert_announced(body, PERFECT_SLIDE, "a perfect slide")
	var cap: float = _tuning.max_horizontal_speed
	assert_almost_eq(body.horizontal_speed(), cap, TOLERANCE, "up to the absolute cap, no more")
	for i: int in 10:
		body.step(_slide(FORWARD, false))
		assert_lte(body.horizontal_speed(), cap + TOLERANCE, "nor later, step %d" % i)


func test_a_big_fall_gives_a_roll_not_a_perfect_slide() -> void:
	var high: float = _tuning.roll_fall_height * 1.5
	var landing_step: int = _landing_step(high, _tuning.top_speed)

	for press_step: int in [landing_step - WINDOW_STEPS, landing_step - 1]:
		var context: String = "pressed %d steps before the floor" % (landing_step - press_step)
		var body: MotorBody = _land(high, _tuning.top_speed, press_step)

		assert_eq(body.motor.state, RunnerMotor.State.ROLLING, context + ": it rolls")
		_assert_announced(body, RunnerEvent.Kind.ROLL, context)
		var speed: float = body.horizontal_speed()
		assert_almost_eq(speed, _tuning.top_speed, TOLERANCE, context + ": with the speed it had")


## The motor of `body` announced `kind` at the step it just played, and nothing else.
func _assert_announced(body: MotorBody, kind: RunnerEvent.Kind, context: String) -> void:
	var kinds: Array[String] = []
	for event: RunnerEvent in body.motor.events:
		kinds.append(RunnerEvent.Kind.keys()[event.kind])
	var expected: Array[String] = [RunnerEvent.Kind.keys()[kind]]
	assert_eq(kinds, expected, context + ": announced")


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


func _slide(direction: Vector3, pressed: bool) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.slide_pressed = pressed
	intent.slide_held = true
	return intent


## A body in the air, `height` above the floor, going forward at `speed`.
func _dropped(height: float, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, height)
	body.velocity = FORWARD * speed
	return body


## The index of the first step at which a body dropped from `height` is seen on the
## floor by its motor.
func _landing_step(height: float, speed: float) -> int:
	var body: MotorBody = _dropped(height, speed)
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	return steps


## Drops a body from `height` going forward at `speed`, and returns it right after its
## first step on the floor. The slide is pressed at the step `press_step` and held from
## then on.
func _land(height: float, speed: float, press_step: int) -> MotorBody:
	var body: MotorBody = _dropped(height, speed)
	for i: int in _landing_step(height, speed) + 1:
		if press_step != NEVER and i >= press_step:
			body.step(_slide(FORWARD, i == press_step))
		else:
			body.step(_run(FORWARD))
	return body


## Drops a body from `height` at the top speed, lets it run on after its landing, and
## presses the slide `steps_after` steps after the landing; returns it right after.
func _slide_after_landing(height: float, steps_after: int) -> MotorBody:
	var body: MotorBody = _land(height, _tuning.top_speed, NEVER)
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "landed on its feet")
	for i: int in steps_after - 1:
		body.step(_run(FORWARD))
	body.step(_slide(FORWARD, true))
	return body
