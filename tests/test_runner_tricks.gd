extends TrickTest
## The aerial tricks of the runner's motor (game/core) in the air: the trick drawn starts
## as the button is released in the air, or on the ground with the full jump the release
## makes where a jump is allowed (nothing elsewhere), the trick of the context when
## nothing was drawn, one trick per jump, what a trick forbids meanwhile, and their names.

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

	# Leaving a wall run at its left: a side flip to the right, away from the wall; the
	# release jumps off the wall too (decision 28 of docs/specs/trick-gestures.md).
	var leaving: MotorBody = _beside_a_wall()
	leaving.step(_push(FORWARD))
	leaving.step(_release(nothing_drawn, LEFT_WALL))
	assert_eq(leaving.motor.state, RunnerMotor.State.RISING, "a runner off its wall run")
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


func test_releasing_the_button_on_the_ground_jumps_and_starts_the_trick() -> void:
	# A backflip drawn on the ground, then the trick button released, the jump never
	# pressed; beside it, the same runner jumping with the jump held up to the top.
	var tricking: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var plain: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	for step: int in 4:
		tricking.step(_drawing(_backflip(), FORWARD))
		plain.step(_push(FORWARD))
	assert_eq(tricking.motor.state, RunnerMotor.State.GROUNDED, "a runner on the ground")

	tricking.step(_release(_backflip(), FORWARD))
	plain.step(_jump(FORWARD))

	assert_eq(tricking.motor.state, RunnerMotor.State.RISING, "it jumps at the release")
	assert_almost_eq(tricking.velocity, plain.velocity, Vector3.ONE * TOLERANCE, "a jump")
	var trick: AirTrick = tricking.motor.current_trick()
	assert_not_null(trick, "a trick starts at the same step")
	if trick != null:
		assert_eq(trick.name(), "BACKFLIP", "the backflip drawn")
		assert_false(trick.recipe.context, "not the trick of the context")
	assert_true(tricking.motor.is_in_a_trick(), "under way")
	# The trick is the move: the jump that carries it is not one more.
	_assert_kinds(tricking, [])

	# A full jump: it flies as the jump held up to its top does.
	var steps: int = 0
	while not plain.on_floor and steps < MANY_STEPS:
		tricking.step(_push(FORWARD))
		var flight: MoveIntent = _push(FORWARD)
		flight.jump_held = plain.motor.state == RunnerMotor.State.RISING
		plain.step(flight)
		var context: String = "step %d" % steps
		assert_almost_eq(tricking.position, plain.position, Vector3.ONE * TOLERANCE, context)
		steps += 1
	assert_true(tricking.on_floor, "both land together")

	# Within the coyote time, just off the floor: the same.
	var leaving: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	leaving.has_floor = false
	leaving.on_floor = false
	leaving.step(_drawing(_backflip(), FORWARD))
	assert_eq(leaving.motor.state, RunnerMotor.State.FALLING, "a runner off the floor")
	assert_gt(leaving.motor.coyote_time_left(), 0.0, "within the coyote time")
	leaving.step(_release(_backflip(), FORWARD))
	assert_eq(leaving.motor.state, RunnerMotor.State.RISING, "it jumps at the release")
	assert_true(leaving.motor.is_in_a_trick(), "and the trick starts")

	# A drawing that cannot be read starts nothing, not even the jump.
	var unread: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	unread.step(_release(null, FORWARD))
	assert_eq(unread.motor.state, RunnerMotor.State.GROUNDED, "a drawing not read: no jump")
	assert_null(unread.motor.current_trick(), "and no trick")


func test_without_a_gesture_on_the_ground_the_jump_starts_the_trick_of_the_context() -> void:
	var nothing_drawn: TrickRecipe = TrickRecipe.of_the_context()

	# Running forward: a front flip.
	var running: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	running.step(_drawing(nothing_drawn, FORWARD))
	running.step(_release(nothing_drawn, FORWARD))
	assert_eq(running.motor.state, RunnerMotor.State.RISING, "running forward: it jumps")
	_assert_context_trick(running, FRONT_FLIP, "running forward")

	# At a stop: a backflip.
	var still: MotorBody = MotorBody.new(_tuning)
	still.step(_push(Vector3.ZERO))
	still.step(_release(nothing_drawn))
	assert_eq(still.motor.state, RunnerMotor.State.RISING, "at a stop: it jumps")
	_assert_context_trick(still, BACKFLIP, "at a stop")


func test_releasing_the_button_where_no_jump_is_allowed_starts_nothing() -> void:
	# A roll and a hard landing, from above the height of a roll, the slide pressed just
	# before the ground or not at all.
	var rolling: MotorBody = _dropped(true)
	assert_eq(rolling.motor.state, RunnerMotor.State.ROLLING, "a runner in a roll")
	var hard: MotorBody = _dropped(false)
	assert_eq(hard.motor.state, RunnerMotor.State.HARD_LANDING, "a runner in a hard landing")
	# A slide under a low ceiling.
	var low: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	low.step(_slide(FORWARD))
	low.can_stand = false
	low.step(_push(FORWARD))
	assert_eq(low.motor.state, RunnerMotor.State.SLIDING, "a runner low under a ceiling")
	# A runner that aims, on its feet.
	var aiming: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)

	for body: MotorBody in [rolling, hard, low, aiming]:
		var state: String = RunnerMotor.State.keys()[body.motor.state]
		var release: MoveIntent = _release(_backflip(), FORWARD)
		release.aim_held = body == aiming
		body.step(release)
		assert_true(body.on_floor, "%s: it does not jump" % state)
		assert_ne(body.motor.state, RunnerMotor.State.RISING, "%s: not rising" % state)
		assert_null(body.motor.current_trick(), "%s: nothing starts" % state)
		_assert_kinds(body, [])

	# The drawing is forgotten: back on its feet, a jump starts no trick.
	low.can_stand = true
	for body: MotorBody in [rolling, hard, low, aiming]:
		var state: String = RunnerMotor.State.keys()[body.motor.state]
		var steps: int = 0
		while body.motor.state != RunnerMotor.State.GROUNDED and steps < MANY_STEPS:
			body.step(_push(FORWARD))
			steps += 1
		body.step(_jump(FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.RISING, "%s, then a jump" % state)
		for step: int in TURN_STEPS:
			body.step(_push(FORWARD))
			assert_null(body.motor.current_trick(), "%s: no trick in the jump" % state)


func test_releasing_the_button_in_a_wall_run_makes_the_wall_jump_and_the_trick() -> void:
	# Decision 28 of docs/specs/trick-gestures.md: the wall jump of the jump button.
	var tricking: MotorBody = _beside_a_wall()
	var jumping: MotorBody = _beside_a_wall()
	for body: MotorBody in [tricking, jumping]:
		body.step(_push(FORWARD))
		body.step(_drawing(_backflip(), FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")

	tricking.step(_release(_backflip(), FORWARD))
	jumping.step(_jump(FORWARD))

	_assert_a_trick_wall_jump(tricking, jumping, "BACKFLIP", "in a wall run")


func test_just_after_the_wall_the_trick_button_still_makes_the_wall_jump() -> void:
	var tricking: MotorBody = _beside_a_wall()
	var jumping: MotorBody = _beside_a_wall()
	for body: MotorBody in [tricking, jumping]:
		body.step(_push(FORWARD))
		# The wall ends: the runner leaves it, and may still jump off it for a while.
		body.remove_wall()
		body.step(_drawing(_backflip(), FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.FALLING, "a runner off its wall run")
		assert_gt(body.motor.wall_jump_time_left(), 0.0, "within the grace of a wall jump")

	tricking.step(_release(_backflip(), FORWARD))
	jumping.step(_jump(FORWARD))

	_assert_a_trick_wall_jump(tricking, jumping, "BACKFLIP", "just after the wall")
	# Past the grace, the release starts the trick without a jump.
	var late: MotorBody = _beside_a_wall()
	late.step(_push(FORWARD))
	late.remove_wall()
	while late.motor.wall_jump_time_left() > 0.0:
		late.step(_push(FORWARD))
	late.step(_release(_backflip(), FORWARD))
	assert_eq(late.motor.state, RunnerMotor.State.FALLING, "past the grace: no wall jump")
	assert_true(late.motor.is_in_a_trick(), "the trick starts all the same")


func test_without_a_gesture_in_a_wall_run_the_exit_makes_a_side_flip() -> void:
	var tricking: MotorBody = _beside_a_wall()
	var jumping: MotorBody = _beside_a_wall()
	for body: MotorBody in [tricking, jumping]:
		body.step(_push(FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")

	tricking.step(_release(TrickRecipe.of_the_context(), FORWARD))
	jumping.step(_jump(FORWARD))

	_assert_a_trick_wall_jump(tricking, jumping, "SIDE FLIP", "nothing drawn")
	var trick: AirTrick = tricking.motor.current_trick()
	if trick != null:
		assert_true(trick.recipe.context, "the trick of the context")
		assert_eq(trick.recipe.side, 1, "to the right, away from the wall at the left")


func test_a_trick_does_not_start_in_a_wall_run_or_a_mantle() -> void:
	var along: MotorBody = _beside_a_wall()
	along.step(_push(FORWARD))
	assert_eq(along.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")
	var climbing: MotorBody = MotorBody.new(_tuning, IN_THE_AIR)
	climbing.put_ledge_ahead(_tuning.mantle_min_height * 1.5)
	climbing.step(_push(FORWARD))
	assert_eq(climbing.motor.state, RunnerMotor.State.MANTLING, "a runner in a mantle")

	for recipe: TrickRecipe in [_backflip(), TrickRecipe.of_the_context()]:
		climbing.step(_release(recipe, FORWARD))
		assert_null(climbing.motor.current_trick(), "in a mantle: nothing starts")
	# Along a wall, the release jumps off it first (decision 28 of
	# docs/specs/trick-gestures.md): the trick never turns along the wall.
	along.step(_release(_backflip(), FORWARD))
	assert_not_null(along.motor.current_trick(), "released along a wall: a trick")
	assert_eq(along.motor.state, RunnerMotor.State.RISING, "off the wall, not along it")


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
	# Off a wall by the wall jump of a trick (decision 28 of docs/specs/trick-gestures.md),
	# then beside the wall in front, the jump pressed: nothing, as if it was not.
	var tricking: MotorBody = _beside_a_wall()
	var plain: MotorBody = _beside_a_wall()
	for body: MotorBody in [tricking, plain]:
		body.step(_push(FORWARD))
		assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner in a wall run")
		body.step(_release(_backflip(), FORWARD))
		assert_true(body.motor.is_in_a_trick(), "in a trick, off the wall")
		body.set_wall(A_WALL + 1, -LEFT_WALL, CLOSE, TALL)

	var jump: MoveIntent = _push(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	tricking.step(jump)
	plain.step(_push(FORWARD))

	assert_eq(tricking.motor.events.size(), 0, "nothing announced")
	var same: Vector3 = Vector3.ONE * TOLERANCE
	assert_almost_eq(tricking.velocity, plain.velocity, same, "no wall jump")
	tricking.step(_push(FORWARD))
	plain.step(_push(FORWARD))
	assert_almost_eq(tricking.velocity, plain.velocity, same, "not even a step later")


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


## `tricking` released the trick button at the step it just played, `jumping` pressed the
## jump: both jumped off the wall the same, and the trick `named` started with it; the
## wall jump of the trick is not a move of its own.
func _assert_a_trick_wall_jump(
	tricking: MotorBody, jumping: MotorBody, named: String, context: String
) -> void:
	assert_eq(tricking.motor.state, RunnerMotor.State.RISING, context + ": it jumps")
	var same: Vector3 = Vector3.ONE * TOLERANCE
	assert_almost_eq(tricking.velocity, jumping.velocity, same, context + ": the wall jump")
	_assert_kinds(tricking, [])
	var trick: AirTrick = tricking.motor.current_trick()
	assert_not_null(trick, context + ": a trick starts at the same step")
	if trick != null:
		assert_eq(trick.name(), named, context + ": the trick released")
	# A full wall jump: it flies as the one of the jump button held up to its top does.
	for step: int in TURN_STEPS:
		tricking.step(_push(FORWARD))
		var flight: MoveIntent = _push(FORWARD)
		flight.jump_held = true
		jumping.step(flight)
	assert_almost_eq(tricking.position, jumping.position, same, context + ": a full one")


## The jump pressed at this step, and held.
func _jump(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.jump_pressed = true
	intent.jump_held = true
	return intent


## A runner dropped from a metre above the height of a roll, played until it lands: it
## rolls if `roll`, the slide pressed just before the ground, and lands hard otherwise.
func _dropped(roll: bool) -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, _tuning.roll_fall_height + 1.0)
	var pressed: bool = false
	var steps: int = 0
	while not body.motor.is_on_the_ground() and steps < MANY_STEPS:
		var intent: MoveIntent = _push(Vector3.ZERO)
		if roll and not pressed and body.position.y < 1.0:
			intent.slide_pressed = true
			pressed = true
		body.step(intent)
		steps += 1
	return body
