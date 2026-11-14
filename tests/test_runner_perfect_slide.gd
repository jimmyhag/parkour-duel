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
## Close enough to the floor, falling, for a slide pressed now to be within the window.
const JUST_ABOVE_THE_FLOOR: float = 0.3

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


func test_perfect_slides_do_not_raise_the_speed_without_end() -> void:
	var flow: FlowState = FlowState.new(_tuning, 60)
	# A gauge at tier 2: the repeated moves soon earn nothing, the bonus stays.
	flow.gauge = 2.5 * _tuning.flow_tier_value
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var gain: float = _tuning.perfect_slide_speed_gain
	var perfect_slides: int = 0
	var fastest_over_the_limit: float = -INF
	var one_step_of_slide: float = _tuning.slide_deceleration * MotorBody.STEP
	# The last perfect slide: how far it ended from the top speed of the moment plus the
	# gain, once its first step of slide is taken off, and the flow bonus it had.
	var last_gap: float = INF
	var last_bonus: float = 0.0
	var steps: int = 0
	var slide_held: bool = false

	# Jump, press the slide just before the floor and hold it, land in a perfect slide,
	# jump again out of it: ten times, on the flat.
	while perfect_slides < 10 and steps < MANY_STEPS * 10:
		var intent: MoveIntent = _run(FORWARD)
		var state: RunnerMotor.State = body.motor.state
		if state == SLIDING or state == RunnerMotor.State.GROUNDED:
			intent.jump_pressed = true
			intent.jump_held = true
		elif state == RunnerMotor.State.FALLING:
			# Once pressed, held down to the floor.
			var near: bool = body.velocity.y < 0.0 and body.position.y < JUST_ABOVE_THE_FLOOR
			intent.slide_held = slide_held or near
			intent.slide_pressed = intent.slide_held and not slide_held
		slide_held = intent.slide_held
		var bonus: float = body.motor.top_speed_bonus
		var limit_of_the_step: float = body.motor.top_speed() + gain
		body.step(intent)
		flow.follow(body.motor)
		steps += 1
		for event: RunnerEvent in body.motor.events:
			if event.kind == PERFECT_SLIDE:
				perfect_slides += 1
				last_gap = body.horizontal_speed() - (limit_of_the_step - one_step_of_slide)
				last_bonus = bonus
		var limit: float = body.motor.top_speed() + gain
		fastest_over_the_limit = maxf(fastest_over_the_limit, body.horizontal_speed() - limit)

	assert_eq(perfect_slides, 10, "ten perfect slides")
	assert_gt(last_bonus, 0.0, "the last one with the bonus of the flow")
	assert_lte(
		fastest_over_the_limit,
		TOLERANCE,
		"never faster than the top speed of the moment plus the gain"
	)
	assert_almost_eq(last_gap, 0.0, TOLERANCE, "the last one up to it, bonus included")

	# A runner already faster than that keeps its speed, without any gain.
	var low: float = _tuning.roll_fall_height / 4.0
	var faster: float = _tuning.top_speed + 2.0 * gain
	var landing_step: int = _landing_step(low, faster)
	var fast: MotorBody = _land(low, faster, landing_step - 1)
	_assert_announced(fast, PERFECT_SLIDE, "a perfect slide, already fast")
	var kept: float = faster - one_step_of_slide
	assert_almost_eq(fast.horizontal_speed(), kept, TOLERANCE, "keeps its speed, no gain")


func test_the_gain_of_a_perfect_slide_respects_the_absolute_cap() -> void:
	# A cap under the top speed plus the gain: the gain alone would take the runner past it.
	_tuning.max_horizontal_speed = _tuning.top_speed + _tuning.perfect_slide_speed_gain / 2.0
	var low: float = _tuning.roll_fall_height / 4.0
	var almost_the_cap: float = _tuning.top_speed
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
