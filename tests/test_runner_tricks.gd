extends TrickTest
## The aerial tricks of the runner's motor (game/core) in the air: a flip chosen by the
## push, turns as long as the button is held, twists tapped on the jump, what a trick
## forbids meanwhile, and their names.

# --- Starting a trick ---


func test_the_pushed_direction_chooses_the_flip() -> void:
	var pushes: Array[Vector3] = [FORWARD, BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.ZERO]
	var flips: Array[AirTrick.Flip] = [FRONT_FLIP, BACKFLIP, SIDE_FLIP, SIDE_FLIP, SPIN]
	var sides: Array[int] = [1, 1, -1, 1, 1]
	for index: int in pushes.size():
		var context: String = "push %s" % pushes[index]
		var body: MotorBody = _launched()
		body.step(_push(FORWARD))
		assert_null(body.motor.current_trick(), context + ": no trick before the press")

		body.step(_trick(pushes[index]))

		var trick: AirTrick = body.motor.current_trick()
		assert_not_null(trick, context + ": a trick starts")
		if trick == null:
			continue
		assert_eq(trick.flip, flips[index], context + ": its flip")
		if flips[index] == SIDE_FLIP:
			assert_eq(trick.side, sides[index], context + ": to the side pushed")
		assert_false(trick.finished, context + ": under way")

	# Measured against the speed, not the world: a runner flying to the right that pushes
	# to the right does a front flip; one almost still takes its push for the front.
	var aside: MotorBody = _launched()
	aside.velocity = Vector3.RIGHT * _tuning.top_speed + Vector3.UP * LAUNCH
	aside.step(_trick(Vector3.RIGHT))
	assert_eq(_flip_of(aside), FRONT_FLIP, "along its speed: a front flip")
	var still: MotorBody = _launched(0.0)
	still.step(_trick(Vector3.LEFT))
	assert_eq(_flip_of(still), FRONT_FLIP, "almost still: its push is the front")


func test_a_trick_does_not_start_on_the_ground() -> void:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "a runner on the ground")

	for push: Vector3 in [FORWARD, BACK, Vector3.ZERO]:
		body.step(_trick(push))
		assert_null(body.motor.current_trick(), "nothing starts, push %s" % push)
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
		for push: Vector3 in [FORWARD, BACK, Vector3.ZERO]:
			body.step(_trick(push))
			assert_null(body.motor.current_trick(), "%s: nothing starts, push %s" % [state, push])


func test_a_trick_does_not_change_the_trajectory() -> void:
	var tricking: MotorBody = _launched()
	var plain: MotorBody = _launched()
	var tricks_seen: int = 0
	var steps: int = 0

	while not plain.on_floor and steps < MANY_STEPS:
		# The same push for both, changing along the flight; one presses the trick, again
		# and again, and holds it.
		var push: Vector3 = BACK.rotated(Vector3.UP, 0.5 * sin(steps * 0.2))
		var intent: MoveIntent = _holding(push)
		intent.trick_pressed = steps % 20 == 1
		tricking.step(intent)
		plain.step(_push(push))
		tricks_seen += int(tricking.motor.is_in_a_trick())
		var context: String = "step %d" % steps
		assert_almost_eq(tricking.position, plain.position, Vector3.ONE * TOLERANCE, context)
		steps += 1

	assert_gt(tricks_seen, TURN_STEPS, "one runner was in a trick for most of the flight")
	assert_true(tricking.on_floor, "both land")
	assert_eq(tricking.position, plain.position, "at the same place")
	assert_eq(tricking.velocity, plain.velocity, "at the same velocity")


# --- Turns ---


func test_releasing_the_button_finishes_the_current_turn() -> void:
	var body: MotorBody = _high()
	body.step(_trick(BACK))
	var trick: AirTrick = body.motor.current_trick()
	assert_eq(_flip_of(body), BACKFLIP, "a runner that just started a backflip")

	# Released in the middle of the first turn, pressed and released again: the turn goes
	# on to its end.
	for step: int in range(1, TURN_STEPS):
		var intent: MoveIntent = _holding(BACK) if step < TURN_STEPS / 2 else _push(BACK)
		intent.trick_pressed = step == TURN_STEPS - 5
		intent.trick_held = intent.trick_held or intent.trick_pressed
		body.step(intent)
		assert_true(body.motor.is_in_a_trick(), "step %d of the turn: under way" % step)
	assert_same(body.motor.current_trick(), trick, "the same trick all along")
	body.step(_push(BACK))

	assert_false(body.motor.is_in_a_trick(), "the backflip is over at the end of the turn")
	assert_true(trick.finished)
	assert_eq(trick.turns, 1, "with one turn")
	assert_eq(trick.finished_at, body.motor.steps, "dated by this step")


func test_holding_the_button_chains_the_turns() -> void:
	var body: MotorBody = _high()
	body.step(_trick(BACK))
	var trick: AirTrick = body.motor.current_trick()

	# Held up to the middle of the second turn, then released.
	var middle_of_the_second: int = TURN_STEPS + TURN_STEPS / 2
	for step: int in range(1, 2 * TURN_STEPS):
		body.step(_holding(BACK) if step < middle_of_the_second else _push(BACK))
		assert_true(body.motor.is_in_a_trick(), "step %d: under way" % step)
		if step == TURN_STEPS:
			assert_eq(trick.turns, 2, "held as the first turn ends: a second one starts")
	body.step(_push(BACK))

	assert_false(body.motor.is_in_a_trick(), "over at the end of the second turn")
	assert_eq(trick.turns, 2, "with two turns")
	assert_eq(trick.name(), "DOUBLE BACKFLIP")


# --- Twists ---


func test_a_jump_press_during_a_flip_adds_a_twist() -> void:
	var twisting: MotorBody = _high()
	var plain: MotorBody = _high()
	for body: MotorBody in [twisting, plain]:
		body.step(_trick(BACK))
	var trick: AirTrick = twisting.motor.current_trick()
	assert_eq(_flip_of(twisting), BACKFLIP, "a runner in a backflip")

	var twist_step: int = 5
	var steps: int = 0
	while plain.motor.is_in_a_trick() and steps < MANY_STEPS:
		steps += 1
		var intent: MoveIntent = _push(BACK)
		intent.jump_pressed = steps == twist_step
		intent.jump_held = steps >= twist_step and steps < twist_step + 3
		twisting.step(intent)
		plain.step(_push(BACK))
		if steps == twist_step:
			assert_eq(trick.twists, 1, "the jump pressed: the backflip gains a twist")
		assert_eq(twisting.motor.is_in_a_trick(), plain.motor.is_in_a_trick(), "step %d" % steps)

	assert_eq(steps, TURN_STEPS, "the twist did not make the trick last longer")
	assert_true(trick.finished, "it ends with the one without a twist")
	assert_eq(trick.twists, 1, "with its twist")
	assert_eq(trick.name(), "BACKFLIP FULL")


func test_twists_do_not_exceed_their_maximum_per_turn() -> void:
	var body: MotorBody = _high()
	body.step(_trick(BACK))
	var trick: AirTrick = body.motor.current_trick()

	# Three presses in the first turn, held on to a second turn.
	for step: int in range(1, TURN_STEPS):
		var intent: MoveIntent = _holding(BACK)
		intent.jump_pressed = step in [3, 8, 13]
		body.step(intent)

	assert_eq(trick.twists, 2, "two twists in the turn, not three")
	# The next turn takes twists of its own.
	for step: int in range(TURN_STEPS, TURN_STEPS + 5):
		var intent: MoveIntent = _holding(BACK)
		intent.jump_pressed = step == TURN_STEPS + 2
		body.step(intent)
	assert_eq(trick.turns, 2, "a second turn")
	assert_eq(trick.twists, 3, "with a twist of its own")


func test_no_twist_on_a_side_flip_or_a_spin() -> void:
	for push: Vector3 in [Vector3.LEFT, Vector3.ZERO]:
		var body: MotorBody = _high()
		body.step(_trick(push))
		var trick: AirTrick = body.motor.current_trick()
		var context: String = AirTrick.Flip.keys()[trick.flip]
		assert_true(trick.flip == SIDE_FLIP or trick.flip == SPIN, context)

		for step: int in range(1, 10):
			var intent: MoveIntent = _holding(push)
			intent.jump_pressed = step % 3 == 0
			body.step(intent)

		assert_eq(trick.twists, 0, context + ": no twist")
		assert_eq(body.motor.state, RunnerMotor.State.FALLING, context + ": and no jump")


func test_a_twist_near_the_ground_does_not_start_a_jump() -> void:
	var landing: int = _landing_step(_launched, BACK)
	# The backflip ends two steps before the ground; the jump is pressed during it, within
	# the jump buffer of the landing (0.12 s, 7 steps).
	var start: int = landing - TURN_STEPS - 2
	var press: int = landing - 5
	var tricking: MotorBody = _launched()
	var plain: MotorBody = _launched()

	for step: int in landing + 3:
		var intent: MoveIntent = _push(BACK)
		intent.trick_pressed = step == start
		intent.trick_held = intent.trick_pressed
		intent.jump_pressed = step == press
		intent.jump_held = step == press
		tricking.step(intent)
		var same_without_a_trick: MoveIntent = _push(BACK)
		same_without_a_trick.jump_pressed = intent.jump_pressed
		same_without_a_trick.jump_held = intent.jump_held
		plain.step(same_without_a_trick)
		if step == press:
			assert_true(tricking.motor.is_in_a_trick(), "the jump is pressed during the trick")
			assert_eq(tricking.motor.jump_buffer_left(), 0.0, "and is not remembered")
		if step == landing:
			assert_eq(plain.motor.state, RunnerMotor.State.RISING, "without a trick: a jump")
			assert_eq(tricking.motor.state, RunnerMotor.State.GROUNDED, "with one: it lands")
			var trick: AirTrick = tricking.motor.current_trick()
			assert_true(trick == null or trick.finished, "the trick was over")
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
	tricking.step(_trick(away))
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


# --- Chaining in the air ---


func test_a_second_trick_in_the_same_jump_is_worth_more() -> void:
	var body: MotorBody = _high()
	var landing: int = _landing_step(_high, Vector3.ZERO)
	var flow: FlowState = _flow()
	# Two backflips of one turn in a row, the second pressed as soon as the first is over.
	var second: int = TURN_STEPS + 1
	for step: int in landing:
		var intent: MoveIntent = _push(BACK if step == 0 or step == second else Vector3.ZERO)
		intent.trick_pressed = step == 0 or step == second
		intent.trick_held = intent.trick_pressed
		_follow(body, flow, intent)
		if step == TURN_STEPS:
			assert_true(body.motor.current_trick().finished, "a runner that finished a trick")
		if step == second:
			assert_eq(body.motor.current_trick().rank, 2, "a second one starts in the same jump")
	var slide: MoveIntent = _push(Vector3.ZERO)
	slide.slide_pressed = true
	slide.slide_held = true
	_follow(body, flow, slide)

	_assert_kinds(body, [TRICK, TRICK, RunnerEvent.Kind.ROLL])
	if body.motor.events.size() < 2:
		return
	var first: AirTrick = body.motor.events[0].trick
	var then: AirTrick = body.motor.events[1].trick
	assert_eq(first.name(), then.name(), "the same trick twice")
	assert_false(first.perfect or then.perfect, "neither perfect")
	assert_eq(first.points(_tuning), 200, "the first is worth its points")
	assert_eq(then.points(_tuning), 300, "the second, the bonus of the chain in the air on top")


func test_no_wall_run_or_mantle_during_a_trick() -> void:
	# Along a wall, from the step after the trick started.
	var tricking: MotorBody = _high()
	var plain: MotorBody = _high()
	tricking.step(_trick(FORWARD))
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

	# Facing a ledge, around the top of a flight: the trick covers it.
	var start: int = _apex_step(_launched) - 14
	var climbing: MotorBody = _launched()
	var conditions_met: int = 0
	var top: float = 0.0
	for step: int in start + TURN_STEPS + 2:
		climbing.step(_trick(FORWARD) if step == start else _push(FORWARD))
		if step == start:
			climbing.put_ledge_ahead(_top_of_the_flight(_launched) + 0.95 - climbing.position.y)
			top = climbing.ledge_top
		if step <= start or not climbing.motor.is_in_a_trick():
			continue
		var height: float = top - climbing.position.y
		var state: RunnerMotor.State = climbing.motor.state
		assert_eq(state, RunnerMotor.State.FALLING, "step %d: no mantle" % step)
		var within: bool = (
			height >= _tuning.mantle_min_height and height <= _tuning.mantle_max_height
		)
		conditions_met += int(within)
	assert_gt(conditions_met, TURN_STEPS - 3, "against the face, within reach of a mantle")
	assert_eq(climbing.motor.state, RunnerMotor.State.MANTLING, "once the trick is over: a mantle")


# --- Names ---


func test_the_name_of_a_trick_is_composed_of_its_bricks() -> void:
	var pushes: Array[Vector3] = [BACK, BACK, Vector3.LEFT, FORWARD, BACK, Vector3.ZERO]
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
		var trick: AirTrick = AirTrick.new(pushes[index], FORWARD, TURN_STEPS, 1)
		trick.turns = turns[index]
		trick.twists = twists[index]
		assert_eq(trick.name(), names[index])

	# The names that go on: more turns, more twists, more degrees.
	var many: AirTrick = AirTrick.new(BACK, FORWARD, TURN_STEPS, 1)
	many.turns = 5
	many.twists = 4
	assert_eq(many.name(), "5X BACKFLIP 4X FULL")
	var spin: AirTrick = AirTrick.new(Vector3.ZERO, FORWARD, TURN_STEPS, 1)
	spin.turns = 3
	assert_eq(spin.name(), "1080")
