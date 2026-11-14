extends TrickTest
## What the landing makes of the aerial trick of the runner's motor (game/core): posed by
## a slide pressed just before the ground, perfect at the last moment, a crash without
## the press or before its end, paid without a press at the start of a wall run or a
## mantle, and its points counted by the flow.

# --- Posing the trick ---


func test_pressing_within_the_window_poses_the_trick() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	assert_true(flow.in_combo(), "a runner in a combo")
	var landing: int = _landing_step(_launched)
	var moves: int = flow.moves_counted
	# Pressed at the edge of the landing window, before the perfect window.
	var press: int = landing - LANDING_STEPS

	var body: MotorBody = _fly(_launched, flow, _backflip(), 0, press)

	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "it lands, standing")
	_assert_kinds(body, [TRICK])
	assert_eq(flow.moves_counted, moves + 1, "counted once, at the landing")
	if body.motor.events.is_empty() or body.motor.events[0].trick == null:
		return
	var event: RunnerEvent = body.motor.events[0]
	assert_eq(event.step, body.motor.steps, "dated by the step of the landing")
	assert_eq(event.trick.name(), "BACKFLIP")
	assert_false(event.trick.perfect, "pressed before the perfect window")
	assert_eq(flow.last_points, 200, "its points")
	assert_eq(flow.style_score, 150 + 200)
	assert_null(body.motor.current_trick(), "the jump has no trick left")


func test_pressing_at_the_last_moment_gives_a_perfect() -> void:
	var landing: int = _landing_step(_launched)
	# Pressed at the edge of the perfect window.
	var press: int = landing - PERFECT_STEPS
	var top: float = _tuning.top_speed
	var gain: float = _tuning.trick_perfect_speed_gain
	# At the top speed: the whole gain; a little faster: up to the top speed plus the gain;
	# much faster: no gain; under an absolute cap close above the top speed: up to the cap.
	var speeds: Array[float] = [top, top + 0.5, top + 5.0, top]
	var caps: Array[float] = [_tuning.max_horizontal_speed, 22.0, 22.0, top + 0.4]
	var gains: Array[float] = [gain, 0.5, 0.0, 0.4]
	for index: int in speeds.size():
		_tuning.max_horizontal_speed = caps[index]
		var context: String = "at %.1f m/s, cap %.1f m/s" % [speeds[index], caps[index]]
		var flow: FlowState = _flow()
		var make: Callable = _launched.bind(speeds[index])
		var tricking: MotorBody = _fly(make, flow, _backflip(), 0, press)
		var plain: MotorBody = _fly(make, null, null, -1, press)

		_assert_kinds(tricking, [TRICK])
		if tricking.motor.events.is_empty():
			continue
		assert_true(tricking.motor.events[0].trick.perfect, context + ": a perfect landing")
		assert_eq(flow.last_points, 300, context + ": the bonus on top")
		var gained: float = tricking.horizontal_speed() - plain.horizontal_speed()
		assert_almost_eq(gained, gains[index], TOLERANCE, context + ": the speed gained")


func test_not_pressing_is_a_crash() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	flow.gauge = 1.5 * _tuning.flow_tier_value
	var landing: int = _landing_step(_launched)
	# A backflip long finished, the slide pressed just before the landing window opens.
	var body: MotorBody = _fly(_launched, flow, _backflip(), 0, landing - LANDING_STEPS - 1)

	assert_true(body.motor.state == RunnerMotor.State.HARD_LANDING, "a hard landing")
	_assert_kinds(body, [CRASH])
	assert_false(flow.in_combo(), "the combo is broken")
	assert_almost_eq(flow.gauge, 0.5 * _tuning.flow_tier_value, TOLERANCE, "a tier lost")
	assert_eq(flow.style_score, 150, "the trick earns nothing")
	assert_eq(flow.tricks_landed, 0, "it is not counted")

	var untouched: MotorBody = _fly(_launched, null, _backflip(), 0)
	_assert_kinds(untouched, [CRASH])


func test_a_press_too_early_is_lost() -> void:
	# High above the floor, the trick long finished: the slide pressed long before the
	# ground, and never again.
	var landing: int = _landing_step(_high)
	var press: int = landing - 3 * LANDING_STEPS
	assert_gt(press, TURN_STEPS, "pressed after the trick is over")
	var flow: FlowState = _flow()
	var body: MotorBody = _high()
	for step: int in landing + 1:
		var intent: MoveIntent = _release(_backflip()) if step == 0 else _push(Vector3.ZERO)
		intent.slide_pressed = step == press
		intent.slide_held = step >= press
		_follow(body, flow, intent)

	_assert_kinds(body, [CRASH])
	assert_eq(flow.tricks_landed, 0, "the trick earns nothing")


func test_a_press_too_early_can_be_made_again() -> void:
	var landing: int = _landing_step(_high)
	var flow: FlowState = _flow()
	var body: MotorBody = _high()
	for step: int in landing + 1:
		var intent: MoveIntent = _release(_backflip()) if step == 0 else _push(Vector3.ZERO)
		intent.slide_pressed = step == landing - 3 * LANDING_STEPS or step == landing - 10
		_follow(body, flow, intent)

	_assert_kinds(body, [TRICK, RunnerEvent.Kind.ROLL])
	assert_eq(flow.tricks_landed, 1, "the trick is posed")


func test_an_unfinished_trick_on_the_ground_is_a_crash_even_with_the_press() -> void:
	var flow: FlowState = _flow()
	var landing: int = _landing_step(_launched)
	# A double backflip started too late, the slide pressed within the perfect window.
	var start: int = landing - 2 * TURN_STEPS + 3
	var body: MotorBody = _fly(_launched, flow, _backflip(2), start, landing - 2)

	_assert_kinds(body, [CRASH])
	assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, "a hard landing")
	assert_eq(flow.tricks_landed, 0, "the trick earns nothing")


func test_an_unfinished_trick_on_the_ground_is_a_crash() -> void:
	var flow: FlowState = _flow()
	_count(flow, RunnerEvent.Kind.WALL_RUN)
	flow.gauge = 1.5 * _tuning.flow_tier_value
	var landing: int = _landing_step(_launched)

	var body: MotorBody = _fly(_launched, flow, _backflip(), landing - 10)

	assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, "a hard landing")
	_assert_kinds(body, [CRASH])
	var slowed: float = _tuning.top_speed * _tuning.hard_landing_speed_ratio
	assert_lt(body.horizontal_speed(), slowed, "which costs the speed")
	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_almost_eq(flow.gauge, 0.5 * _tuning.flow_tier_value, TOLERANCE, "a tier lost")
	assert_eq(flow.style_score, 150, "the trick earns nothing")
	assert_null(body.motor.current_trick(), "nothing is left of it")


func test_a_trick_posed_in_a_big_fall_rolls() -> void:
	assert_gt(HIGH, _tuning.roll_fall_height, "a fall higher than a roll asks for")
	var flow: FlowState = _flow()
	var landing: int = _landing_step(_high)

	var body: MotorBody = _fly(_high, flow, _backflip(), 0, landing - 4)

	_assert_kinds(body, [TRICK, RunnerEvent.Kind.ROLL])
	assert_eq(body.motor.state, RunnerMotor.State.ROLLING, "it rolls")
	if body.motor.events.size() == 2:
		assert_true(body.motor.events[0].trick.perfect, "posed perfect")
	assert_eq(flow.style_score, 300 + 100, "the trick pays, then the roll")


func test_a_trick_posed_on_the_flat_starts_a_slide() -> void:
	var flow: FlowState = _flow()
	assert_gt(_tuning.top_speed, _tuning.slide_min_speed, "fast enough to slide")
	var landing: int = _landing_step(_launched)

	var body: MotorBody = _fly(_launched, flow, _backflip(), 0, landing - 3, true)

	_assert_kinds(body, [TRICK, RunnerEvent.Kind.PERFECT_SLIDE])
	assert_eq(body.motor.state, RunnerMotor.State.SLIDING, "it slides")
	body.step(_slide())
	assert_eq(body.motor.state, RunnerMotor.State.SLIDING, "and goes on sliding, held")


func test_a_trick_pays_at_the_start_of_a_wall_run_without_a_press() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _high()
	_follow(body, flow, _release(_front_flip(), FORWARD))
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	for step: int in range(1, TURN_STEPS):
		_follow(body, flow, _push(FORWARD))
	assert_true(body.motor.is_in_a_trick(), "a trick along a wall")

	_follow(body, flow, _push(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "finished, the runner wall runs")
	_assert_kinds(body, [TRICK, RunnerEvent.Kind.WALL_RUN])
	if body.motor.events.is_empty() or body.motor.events[0].trick == null:
		return
	assert_false(body.motor.events[0].trick.perfect, "no perfect along a wall")
	assert_eq(flow.style_score, 200 + 150, "the trick pays, then the wall run")


func test_a_trick_pays_at_the_start_of_a_mantle() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _high()
	var reach: float = _tuning.mantle_min_height * 1.5
	_follow(body, flow, _release(_front_flip(), FORWARD))
	# A ledge within reach right in front, all along the trick.
	for step: int in range(1, TURN_STEPS):
		body.put_ledge_ahead(reach)
		_follow(body, flow, _push(FORWARD))
	assert_true(body.motor.is_in_a_trick(), "a trick in front of a ledge within reach")
	body.put_ledge_ahead(reach)

	_follow(body, flow, _push(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.MANTLING, "finished, the runner climbs")
	_assert_kinds(body, [TRICK, RunnerEvent.Kind.MANTLE])
	if body.motor.events.is_empty() or body.motor.events[0].trick == null:
		return
	assert_false(body.motor.events[0].trick.perfect, "no perfect on a ledge")
	assert_eq(flow.style_score, 200 + 100, "the trick pays, then the mantle")


func test_a_fall_off_the_course_loses_the_tricks_of_the_jump() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _launched()
	for step: int in TURN_STEPS + 1:
		_follow(body, flow, _release(_backflip()) if step == 0 else _push(Vector3.ZERO))
	assert_true(body.motor.current_trick().finished, "a runner that finished a trick in the air")

	# What the course does when the runner falls off it: back at its checkpoint, at rest.
	body.motor.reset()
	flow.respawn()
	body.position = Vector3.ZERO
	body.velocity = Vector3.ZERO
	body.on_floor = true
	for step: int in 10:
		_follow(body, flow, _slide() if step == 0 else _push(Vector3.ZERO))
		for event: RunnerEvent in body.motor.events:
			assert_ne(event.kind, TRICK, "step %d: no trick paid" % step)

	assert_null(body.motor.current_trick(), "the trick is lost")
	assert_eq(flow.style_score, 0, "it earned nothing")


# --- Points and variety ---


func test_the_points_follow_the_difficulty() -> void:
	var recipes: Array[TrickRecipe] = [
		_backflip(),
		TrickRecipe.drawn(SIDE_FLIP, 1, 0, -1),
		TrickRecipe.of_the_context(FRONT_FLIP),
		_backflip(2),
		_backflip(1, 1),
	]
	var points: Array[int] = []
	for recipe: TrickRecipe in recipes:
		# Each one the first move of its combo, posed without a perfect, high enough above
		# the floor for any of them.
		var flow: FlowState = _flow()
		var landing: int = _landing_step(_high)
		var body: MotorBody = _fly(_high, flow, recipe, 0, landing - LANDING_STEPS)
		var paid: bool = body.motor.events.size() > 0 and body.motor.events[0].kind == TRICK
		assert_true(paid, recipe.name() + ": posed")
		points.append(flow.step_points[0] if paid else -1)

	assert_eq(points, [200, 250, 100, 500, 350] as Array[int])
	# A double with a twist, a triple; a spin is worth a side flip.
	assert_eq(_backflip(2, 1).points(_tuning), 650)
	assert_eq(_backflip(3).points(_tuning), 800)
	assert_eq(TrickRecipe.drawn(SPIN).points(_tuning), 250)


func test_two_different_recipes_are_not_a_repetition() -> void:
	var worth: Array[int] = []
	var full_value: Array[int] = []
	for twists: int in [1, 0]:
		var flow: FlowState = _flow()
		var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
		var first: AirTrick = _hop_with_a_trick(body, flow, _backflip())
		assert_eq(first.name(), "BACKFLIP", "a runner that just posed a backflip")
		var second: AirTrick = _hop_with_a_trick(body, flow, _backflip(1, twists))
		assert_true(flow.in_combo(), "in the same combo")
		assert_eq(flow.last_move, TRICK, "the second trick is counted")
		worth.append(flow.last_points)
		# Jump, trick, jump, trick: the fourth move of the combo, counted at x1.
		full_value.append(second.points(_tuning))

	assert_eq(worth[0], full_value[0], "a backflip with a twist after it: all its points")
	assert_eq(worth[1], roundi(full_value[1] / 2.0), "the same backflip again: half of them")


## From the ground, a held jump off a floor 2 m higher than the one it lands on, `recipe`
## released at the take-off, the slide pressed at every step of the fall: returns the
## trick paid, null if none.
func _hop_with_a_trick(body: MotorBody, flow: FlowState, recipe: TrickRecipe) -> AirTrick:
	var take_off: MoveIntent = _release(recipe, FORWARD)
	take_off.jump_pressed = true
	take_off.jump_held = true
	_follow(body, flow, take_off)
	body.floor_height -= 2.0
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		var intent: MoveIntent = _push(FORWARD)
		intent.jump_held = body.motor.state == RunnerMotor.State.RISING
		intent.slide_pressed = body.motor.state == RunnerMotor.State.FALLING
		_follow(body, flow, intent)
		steps += 1
	_follow(body, flow, _push(FORWARD))
	for event: RunnerEvent in body.motor.events:
		if event.trick != null:
			return event.trick
	return null
