extends TrickTest
## What the landing makes of the aerial tricks of the runner's motor (game/core): paid
## on the ground or at the start of a wall run, perfect just before the ground, a crash
## before the end of a turn, and their points counted by the flow.

# --- Landing, crash and points ---


func test_a_finished_trick_pays_at_the_landing() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	assert_true(flow.in_combo(), "a runner in a combo")
	var body: MotorBody = _launched()
	var landing: int = _landing_step(_launched, Vector3.ZERO)
	var moves: int = flow.moves_counted

	for step: int in landing:
		_follow(body, flow, _trick(BACK) if step == 0 else _push(Vector3.ZERO))
		if step == TURN_STEPS:
			assert_true(body.motor.current_trick().finished, "a backflip finished in the air")
	assert_eq(flow.moves_counted, moves, "nothing counted in the air")
	_follow(body, flow, _push(Vector3.ZERO))

	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "it lands")
	_assert_kinds(body, [TRICK])
	if body.motor.events.is_empty():
		return
	var event: RunnerEvent = body.motor.events[0]
	assert_eq(event.step, body.motor.steps, "dated by the step of the landing")
	assert_eq(event.trick.name(), "BACKFLIP")
	assert_false(event.trick.perfect, "finished long before the ground")
	assert_eq(flow.last_move, TRICK, "the flow counts it")
	assert_eq(flow.last_points, 200, "for its points")
	assert_eq(flow.style_score, 150 + 200)
	assert_null(body.motor.current_trick(), "the jump has no trick left")


func test_an_unfinished_trick_on_the_ground_is_a_crash() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	flow.gauge = 1.5 * _tuning.flow_tier_value
	var body: MotorBody = _launched()
	var landing: int = _landing_step(_launched, Vector3.ZERO)
	var start: int = landing - 10

	# Even with the slide pressed within the window of a roll.
	for step: int in landing + 1:
		var intent: MoveIntent = _trick(BACK) if step == start else _push(Vector3.ZERO)
		intent.slide_pressed = step == landing - 2
		intent.slide_held = step >= landing - 2
		_follow(body, flow, intent)
		if step == landing - 1:
			assert_true(body.motor.is_in_a_trick(), "its turn is not over")

	assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, "a hard landing")
	_assert_kinds(body, [RunnerEvent.Kind.CRASH])
	var slowed: float = _tuning.top_speed * _tuning.hard_landing_speed_ratio
	assert_lt(body.horizontal_speed(), slowed, "which costs the speed")
	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_almost_eq(flow.gauge, 0.5 * _tuning.flow_tier_value, TOLERANCE, "a tier lost")
	assert_eq(flow.style_score, 150, "the trick earns nothing")
	assert_null(body.motor.current_trick(), "nothing is left of it")


func test_a_trick_finished_just_before_the_ground_is_perfect() -> void:
	var landing: int = _landing_step(_launched, Vector3.ZERO)
	# Finished at the edge of the window, the perfect window before the ground.
	var start: int = landing - TURN_STEPS - PERFECT_STEPS
	for speed: float in [_tuning.top_speed, _tuning.max_horizontal_speed - 0.5]:
		var context: String = "at %.1f m/s" % speed
		var flow: FlowState = _flow()
		var tricking: MotorBody = _launched(speed)
		var plain: MotorBody = _launched(speed)
		for step: int in landing + 1:
			var push: Vector3 = BACK if step == start else Vector3.ZERO
			var intent: MoveIntent = _push(push)
			intent.trick_pressed = step == start
			intent.trick_held = intent.trick_pressed
			_follow(tricking, flow, intent)
			plain.step(_push(push))

		_assert_kinds(tricking, [TRICK])
		if tricking.motor.events.is_empty():
			continue
		assert_true(tricking.motor.events[0].trick.perfect, context + ": a perfect landing")
		assert_eq(flow.last_points, 300, context + ": the bonus on top")
		var gained: float = tricking.horizontal_speed() - plain.horizontal_speed()
		var cap: float = _tuning.max_horizontal_speed
		var gain: float = _tuning.trick_perfect_speed_gain
		if speed + gain <= cap:
			assert_almost_eq(gained, gain, TOLERANCE, context + ": the speed gains the gain")
		else:
			assert_lt(gained, gain, context + ": a gain held back")
			var landed: float = cap - _tuning.ground_deceleration / STEPS_PER_SECOND
			var speed_now: float = tricking.horizontal_speed()
			assert_almost_eq(speed_now, landed, TOLERANCE, context + ": by the absolute cap")


func test_a_trick_finished_too_early_is_not_perfect() -> void:
	var landing: int = _landing_step(_launched, Vector3.ZERO)
	var start: int = landing - TURN_STEPS - PERFECT_STEPS - 1
	var flow: FlowState = _flow()
	var tricking: MotorBody = _launched()
	var plain: MotorBody = _launched()
	for step: int in landing + 1:
		var push: Vector3 = BACK if step == start else Vector3.ZERO
		var intent: MoveIntent = _push(push)
		intent.trick_pressed = step == start
		intent.trick_held = intent.trick_pressed
		_follow(tricking, flow, intent)
		plain.step(_push(push))

	_assert_kinds(tricking, [TRICK])
	if tricking.motor.events.is_empty():
		return
	assert_false(tricking.motor.events[0].trick.perfect, "not perfect")
	assert_eq(flow.last_points, 200, "its points, no bonus")
	assert_eq(tricking.velocity, plain.velocity, "and no gain")


func test_a_trick_pays_at_the_start_of_a_wall_run() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _high()
	_follow(body, flow, _trick(FORWARD))
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	for step: int in range(1, TURN_STEPS):
		_follow(body, flow, _push(FORWARD))
	assert_true(body.motor.is_in_a_trick(), "a trick along a wall")

	_follow(body, flow, _push(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "finished, the runner wall runs")
	_assert_kinds(body, [TRICK, RunnerEvent.Kind.WALL_RUN])
	if body.motor.events.is_empty():
		return
	assert_false(body.motor.events[0].trick.perfect, "no perfect along a wall")
	assert_eq(flow.style_score, 200 + 150, "the trick pays, then the wall run")


func test_the_points_of_a_composed_trick() -> void:
	var flow: FlowState = _flow()
	assert_eq(flow.multiplier(), 1, "a runner at x1, before the first move of its combo")
	var body: MotorBody = _high()
	var landing: int = _landing_step(_high, Vector3.ZERO)
	# A backflip held into its second turn, a twist in the first, finished just before a
	# landing that asks for a roll.
	var start: int = landing - 2 * TURN_STEPS - 3
	for step: int in landing + 1:
		var intent: MoveIntent = _push(BACK if step == start else Vector3.ZERO)
		intent.trick_pressed = step == start
		intent.trick_held = step >= start and step < start + TURN_STEPS + 5
		intent.jump_pressed = step == start + 5
		intent.slide_pressed = step == landing - 1
		intent.slide_held = step >= landing - 1
		_follow(body, flow, intent)

	_assert_kinds(body, [TRICK, RunnerEvent.Kind.ROLL])
	if body.motor.events.is_empty():
		return
	var trick: AirTrick = body.motor.events[0].trick
	assert_eq(trick.name(), "DOUBLE BACKFLIP FULL")
	assert_true(trick.perfect, "posed perfect")
	assert_eq(trick.points(_tuning), 750, "(2 x 200 + 100) x 1.5")
	assert_eq(flow.style_score, 750 + 100, "the flow counts 750, then the roll")


func test_a_trick_that_changes_one_brick_is_not_a_repetition() -> void:
	var worth: Array[int] = []
	var full_value: Array[int] = []
	for twists: int in [1, 0]:
		var flow: FlowState = _flow()
		var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
		var first: AirTrick = _jump_with_a_backflip(body, flow, 0)
		assert_eq(first.name(), "BACKFLIP", "a runner that just posed a backflip")
		var second: AirTrick = _jump_with_a_backflip(body, flow, twists)
		assert_true(flow.in_combo(), "in the same combo")
		assert_eq(flow.last_move, TRICK, "the second backflip is counted")
		worth.append(flow.last_points)
		# Jump, trick, jump, trick: the fourth move of the combo, counted at x1.
		full_value.append(second.points(_tuning))

	assert_eq(worth[0], full_value[0], "a backflip with a twist after it: all its points")
	assert_eq(worth[1], roundi(full_value[1] / 2.0), "the same backflip again: half of them")


func test_a_fall_off_the_course_loses_the_tricks_of_the_jump() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _launched()
	for step: int in TURN_STEPS + 1:
		_follow(body, flow, _trick(BACK) if step == 0 else _push(Vector3.ZERO))
	assert_true(body.motor.current_trick().finished, "a runner that finished a trick in the air")

	# What the course does when the runner falls off it: back at its checkpoint, at rest.
	body.motor.reset()
	flow.respawn()
	body.position = Vector3.ZERO
	body.velocity = Vector3.ZERO
	body.on_floor = true
	for step: int in 10:
		_follow(body, flow, _push(Vector3.ZERO))
		for event: RunnerEvent in body.motor.events:
			assert_ne(event.kind, TRICK, "step %d: no trick paid" % step)

	assert_null(body.motor.current_trick(), "the trick is lost")
	assert_eq(flow.style_score, 0, "it earned nothing")


func test_the_big_fall_still_asks_for_a_roll() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	var body: MotorBody = _high()
	var landing: int = _landing_step(_high, Vector3.ZERO)
	var start: int = landing - TURN_STEPS - 3
	assert_gt(HIGH, _tuning.roll_fall_height, "a fall higher than a roll asks for")

	for step: int in landing + 1:
		_follow(body, flow, _trick(BACK) if step == start else _push(Vector3.ZERO))

	assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, "no roll: a hard landing")
	_assert_kinds(body, [TRICK, RunnerEvent.Kind.HARD_LANDING])
	if body.motor.events.is_empty():
		return
	assert_true(body.motor.events[0].trick.perfect, "even after a perfect trick")
	assert_eq(flow.style_score, 150 + 300, "which pays")
	assert_false(flow.in_combo(), "before the hard landing breaks the combo")
