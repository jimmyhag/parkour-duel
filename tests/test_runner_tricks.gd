extends TrickTest
## The aerial tricks of the runner's motor (game/core) in the air: the trick drawn starts
## as the button is released in the air, the trick of the context when nothing was
## drawn, one trick per jump, what a trick forbids meanwhile, and their names.

# --- Drawing and releasing ---


func test_the_trick_starts_when_the_button_is_released_in_the_air() -> void:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	# A backflip drawn on the ground, the pad going down, then a jump, the button held.
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	for step: int in 6:
		gesture.step(Vector2.DOWN * 0.2, MotorBody.STEP)
		body.step(_drawing(gesture.recipe(), FORWARD))
	var jump: MoveIntent = _drawing(gesture.recipe(), FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	body.step(jump)
	for step: int in 3:
		var holding: MoveIntent = _drawing(gesture.recipe(), FORWARD)
		holding.jump_held = true
		body.step(holding)
	assert_eq(body.motor.state, RunnerMotor.State.RISING, "a runner in the air")
	assert_null(body.motor.current_trick(), "nothing started while the button is held")

	var release: MoveIntent = _release(gesture.recipe(), FORWARD)
	release.jump_held = true
	body.step(release)

	var trick: AirTrick = body.motor.current_trick()
	assert_not_null(trick, "a trick starts at the step of the release")
	if trick == null:
		return
	assert_eq(trick.name(), "BACKFLIP", "the backflip drawn")
	assert_false(trick.recipe.context, "not the trick of the context")
	assert_true(body.motor.is_in_a_trick(), "under way")


func test_without_a_gesture_the_trick_of_the_context_starts() -> void:
	var nothing_drawn: TrickRecipe = TrickRecipe.of_the_context()

	# Running forward: a front flip.
	var running: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var jump: MoveIntent = _push(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	running.step(jump)
	running.step(_release(nothing_drawn, FORWARD))
	_assert_context_trick(running, FRONT_FLIP, "running forward")

	# Just after a wall jump: a backflip.
	var wall_jumping: MotorBody = _beside_a_wall()
	wall_jumping.step(_push(FORWARD))
	assert_eq(wall_jumping.motor.state, RunnerMotor.State.WALL_RUNNING, "a wall run")
	var off_the_wall: MoveIntent = _push(FORWARD)
	off_the_wall.jump_pressed = true
	off_the_wall.jump_held = true
	wall_jumping.step(off_the_wall)
	assert_eq(wall_jumping.motor.state, RunnerMotor.State.RISING, "then a wall jump")
	wall_jumping.step(_release(nothing_drawn, FORWARD))
	_assert_context_trick(wall_jumping, BACKFLIP, "just after a wall jump")

	# Leaving a wall run at its left: a side flip to the right, away from the wall.
	var leaving: MotorBody = _beside_a_wall()
	leaving.step(_push(FORWARD))
	leaving.step(_release(nothing_drawn, LEFT_WALL))
	assert_eq(leaving.motor.state, RunnerMotor.State.FALLING, "a runner off its wall run")
	_assert_context_trick(leaving, SIDE_FLIP, "leaving a wall run")
	if leaving.motor.current_trick() != null:
		assert_eq(leaving.motor.current_trick().recipe.side, 1, "to the right, away from it")

	# At a stop: a backflip.
	var still: MotorBody = MotorBody.new(_tuning)
	still.step(_push(Vector3.ZERO))
	var hop: MoveIntent = _push(Vector3.ZERO)
	hop.jump_pressed = true
	hop.jump_held = true
	still.step(hop)
	still.step(_release(nothing_drawn))
	_assert_context_trick(still, BACKFLIP, "at a stop")

	# Worth half a front flip.
	var front_flip: int = TrickRecipe.drawn(FRONT_FLIP).points(_tuning)
	assert_eq(TrickRecipe.of_the_context(FRONT_FLIP).points(_tuning), front_flip / 2)


func test_one_trick_per_jump() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _launched()
	var landing: int = _landing_step(_launched)
	var second: int = TURN_STEPS + 3
	for step: int in landing + 1:
		var intent: MoveIntent = _push(Vector3.ZERO)
		if step == 0:
			intent = _release(_backflip())
		elif step > TURN_STEPS and step < second:
			intent = _drawing(_front_flip())
		elif step == second:
			intent = _release(_front_flip())
		intent.slide_pressed = step == landing - 2
		_follow(body, flow, intent)
		if step == TURN_STEPS:
			assert_true(body.motor.current_trick().finished, "a runner that finished a trick")
		if step == second:
			var trick: AirTrick = body.motor.current_trick()
			assert_eq(trick.name(), "BACKFLIP", "no second trick starts")
			assert_false(body.motor.is_in_a_trick(), "nothing under way")

	_assert_kinds(body, [TRICK])
	assert_eq(flow.tricks_landed, 1, "one trick paid")


# --- Where a trick starts ---


func test_a_trick_does_not_start_on_the_ground() -> void:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "a runner on the ground")

	for recipe: TrickRecipe in [_backflip(), _front_flip(), TrickRecipe.of_the_context()]:
		body.step(_release(recipe, FORWARD))
		assert_null(body.motor.current_trick(), "nothing starts: %s" % recipe.name())
		body.step(_push(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "it stays on the ground")


func test_a_trick_does_not_start_in_a_wall_run_or_a_mantle() -> void:
	var along: MotorBody = _beside_a_wall()
	along.step(_push(FORWARD))
	assert_eq(along.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")
	var climbing: MotorBody = MotorBody.new(_tuning, IN_THE_AIR)
	climbing.put_ledge_ahead(_tuning.mantle_min_height * 1.5)
	climbing.step(_push(FORWARD))
	assert_eq(climbing.motor.state, RunnerMotor.State.MANTLING, "a runner in a mantle")

	for body: MotorBody in [along, climbing]:
		var state: String = RunnerMotor.State.keys()[body.motor.state]
		for recipe: TrickRecipe in [_backflip(), TrickRecipe.of_the_context()]:
			body.step(_release(recipe, FORWARD))
			assert_null(body.motor.current_trick(), "%s: nothing starts" % state)


func test_a_trick_does_not_change_the_trajectory() -> void:
	var tricking: MotorBody = _launched()
	var plain: MotorBody = _launched()
	var tricks_seen: int = 0
	var steps: int = 0

	while not plain.on_floor and steps < MANY_STEPS:
		# The same push for both, changing along the flight; one draws, releases a double
		# backflip, then draws again.
		var push: Vector3 = BACK.rotated(Vector3.UP, 0.5 * sin(steps * 0.2))
		var intent: MoveIntent = _drawing(_backflip(2), push)
		if steps == 3:
			intent = _release(_backflip(2), push)
		tricking.step(intent)
		plain.step(_push(push))
		tricks_seen += int(tricking.motor.is_in_a_trick())
		var context: String = "step %d" % steps
		assert_almost_eq(tricking.position, plain.position, Vector3.ONE * TOLERANCE, context)
		steps += 1

	assert_eq(tricks_seen, 2 * TURN_STEPS, "one runner was in a double for part of the flight")
	assert_true(tricking.on_floor, "both land")
	assert_eq(tricking.position, plain.position, "at the same place")


# --- What a trick forbids ---


func test_a_twist_near_the_ground_does_not_start_a_jump() -> void:
	var landing: int = _landing_step(_launched, BACK)
	# The backflip ends two steps before the ground; the jump is pressed during it, within
	# the jump buffer of the landing (0.12 s, 7 steps). The slide poses the trick.
	var start: int = landing - TURN_STEPS - 2
	var press: int = landing - 5
	var tricking: MotorBody = _launched()
	var plain: MotorBody = _launched()

	for step: int in landing + 3:
		var intent: MoveIntent = _release(_backflip(), BACK) if step == start else _push(BACK)
		intent.jump_pressed = step == press
		intent.jump_held = step == press
		intent.slide_pressed = step == landing - 4
		tricking.step(intent)
		var same_without_a_trick: MoveIntent = _push(BACK)
		same_without_a_trick.jump_pressed = intent.jump_pressed
		same_without_a_trick.jump_held = intent.jump_held
		same_without_a_trick.slide_pressed = intent.slide_pressed
		plain.step(same_without_a_trick)
		if step == press:
			assert_true(tricking.motor.is_in_a_trick(), "the jump is pressed during the trick")
			assert_eq(tricking.motor.jump_buffer_left(), 0.0, "and is not remembered")
		if step == landing:
			assert_eq(plain.motor.state, RunnerMotor.State.RISING, "without a trick: a jump")
			assert_eq(tricking.motor.state, RunnerMotor.State.GROUNDED, "with one: it lands")
			_assert_kinds(tricking, [TRICK])
		if step >= landing:
			assert_true(tricking.on_floor, "step %d: it does not jump" % step)


func test_during_a_trick_the_jump_does_not_start_a_wall_jump() -> void:
	var tricking: MotorBody = _beside_a_wall()
	var plain: MotorBody = _beside_a_wall()
	var away: Vector3 = LEFT_WALL
	for body: MotorBody in [tricking, plain]:
		body.step(_push(FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")
	# It leaves the wall, and one of them starts a trick as it does.
	tricking.step(_release(_backflip(), away))
	plain.step(_push(away))
	assert_true(tricking.motor.is_in_a_trick(), "in a trick, just off the wall run")
	assert_gt(tricking.motor.wall_jump_time_left(), 0.0, "while a jump is still a wall jump")

	var jump: MoveIntent = _push(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	tricking.step(jump)
	plain.step(jump)

	assert_eq(plain.motor.state, RunnerMotor.State.RISING, "without a trick: a wall jump")
	assert_eq(tricking.motor.state, RunnerMotor.State.FALLING, "with one: no wall jump")
	assert_eq(tricking.motor.events.size(), 0, "nothing announced")
	tricking.step(_push(FORWARD))
	assert_eq(tricking.motor.state, RunnerMotor.State.FALLING, "not even a step later")


func test_no_wall_run_or_mantle_during_a_trick() -> void:
	# Along a wall, from the step after the trick started.
	var tricking: MotorBody = _high()
	var plain: MotorBody = _high()
	tricking.step(_release(_front_flip(), FORWARD))
	plain.step(_push(FORWARD))
	for body: MotorBody in [tricking, plain]:
		body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	var towards_the_wall: Vector3 = (FORWARD + Vector3.LEFT).normalized()
	for step: int in range(1, TURN_STEPS + 1):
		var push: Vector3 = FORWARD if step % 2 == 0 else towards_the_wall
		tricking.step(_push(push))
		plain.step(_push(push))
		if step == 1:
			var state: RunnerMotor.State = plain.motor.state
			assert_eq(state, RunnerMotor.State.WALL_RUNNING, "without a trick: a wall run")
		if step < TURN_STEPS:
			var state: RunnerMotor.State = tricking.motor.state
			assert_eq(state, RunnerMotor.State.FALLING, "step %d: in the air" % step)
	assert_false(tricking.motor.is_in_a_trick(), "the trick is over")
	assert_eq(tricking.motor.state, RunnerMotor.State.WALL_RUNNING, "and the wall run starts")

	# Facing a ledge within reach at every step: the face of a block right in front, its
	# top a mantle's height above the feet, kept so all along the flight.
	var climbing: MotorBody = _high()
	var twin: MotorBody = _high()
	climbing.step(_release(_front_flip(), FORWARD))
	twin.step(_push(FORWARD))
	var reach: float = _tuning.mantle_min_height * 1.5
	for step: int in range(1, TURN_STEPS + 1):
		var push: Vector3 = (
			FORWARD if step % 2 == 0 else (FORWARD + Vector3.LEFT * 0.3).normalized()
		)
		for body: MotorBody in [climbing, twin]:
			body.put_ledge_ahead(reach)
			body.step(_push(push))
		if step == 1:
			var state: RunnerMotor.State = twin.motor.state
			assert_eq(state, RunnerMotor.State.MANTLING, "without a trick: a mantle")
		if step < TURN_STEPS:
			var state: RunnerMotor.State = climbing.motor.state
			assert_eq(state, RunnerMotor.State.FALLING, "step %d: no mantle" % step)
	assert_false(climbing.motor.is_in_a_trick(), "the trick is over")
	assert_eq(climbing.motor.state, RunnerMotor.State.MANTLING, "and the mantle starts")


# --- Names ---


func test_the_name_of_a_trick_is_composed_of_its_bricks() -> void:
	var flips: Array[TrickRecipe.Flip] = [BACKFLIP, BACKFLIP, SIDE_FLIP, FRONT_FLIP, BACKFLIP, SPIN]
	var turns: Array[int] = [1, 2, 3, 1, 4, 2]
	var twists: Array[int] = [0, 1, 0, 2, 0, 0]
	var names: Array[String] = [
		"BACKFLIP",
		"DOUBLE BACKFLIP FULL",
		"TRIPLE SIDE FLIP",
		"FRONT FLIP DOUBLE FULL",
		"4X BACKFLIP",
		"720",
	]
	for index: int in names.size():
		var trick: AirTrick = AirTrick.new(
			TrickRecipe.drawn(flips[index], turns[index], twists[index]),
			FORWARD,
			TURN_STEPS,
			TWIST_STEPS
		)
		assert_eq(trick.name(), names[index])

	# The names that go on: more turns, more twists, more degrees.
	assert_eq(TrickRecipe.drawn(BACKFLIP, 5, 4).name(), "5X BACKFLIP 4X FULL")
	assert_eq(TrickRecipe.drawn(SPIN, 3).name(), "1080")


func _assert_context_trick(body: MotorBody, flip: TrickRecipe.Flip, context: String) -> void:
	var trick: AirTrick = body.motor.current_trick()
	assert_not_null(trick, context + ": a trick starts")
	if trick == null:
		return
	assert_true(trick.recipe.context, context + ": the trick of the context")
	assert_eq(trick.recipe.flip, flip, context + ": its flip")
	assert_eq(trick.recipe.turns, 1, context + ": one turn")
	assert_eq(trick.points(_tuning), _tuning.trick_points_context, context + ": its points")
