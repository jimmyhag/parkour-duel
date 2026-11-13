extends GutTest
## The wall run and the wall jump (game/core): in the air, fast enough, high enough,
## pushing along a wall, the runner runs along it for a while, falling slowly; a jump
## sends it away from the wall and up, and the same wall is refused until the ground or
## another wall. The walls are facts set by the test. The tuning is the fixed one of
## MotorBody; the runners go along -Z.

const STEP: float = MotorBody.STEP
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
const FALLING: RunnerMotor.State = RunnerMotor.State.FALLING
const RISING: RunnerMotor.State = RunnerMotor.State.RISING
## The windows of the fixed tuning in fixed steps at 60 steps per second: the wall run
## (1.2 s), the wall jump after leaving the wall (0.10 s) and the jump buffer (0.12 s).
## Written out on purpose, not computed.
const WALL_RUN_STEPS: int = 72
const GRACE_STEPS: int = 6
const BUFFER_STEPS: int = 7
## The normals of a wall at the left of a runner going along -Z, and at its right.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const RIGHT_WALL: Vector3 = Vector3.LEFT
const A_WALL: int = 1
const ANOTHER_WALL: int = 2
## A wall close to the runner's side, and tall.
const CLOSE: float = 0.3
const TALL: float = 10.0
## Far above the floor: nothing in these tests lands unless it is meant to.
const HIGH: float = 100.0
const SOME_STEPS: int = 10


func test_the_wall_run_starts_by_itself_along_a_wall() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	for normal: Vector3 in [LEFT_WALL, RIGHT_WALL]:
		var body: MotorBody = _beside_a_wall(tuning, tuning.top_speed, normal)

		body.step(_run(FORWARD))

		assert_eq(body.motor.state, WALL_RUNNING, "along the wall of normal %s" % normal)

	# A wall that leans a little is still a wall.
	var leaning: Vector3 = LEFT_WALL.rotated(Vector3.FORWARD, deg_to_rad(10.0))
	var along_a_leaning_wall: MotorBody = _beside_a_wall(tuning, tuning.top_speed, leaning)
	along_a_leaning_wall.step(_run(FORWARD))
	assert_eq(along_a_leaning_wall.motor.state, WALL_RUNNING, "a wall leaning by 10 degrees")

	# Only along a wall close enough, tall enough and near enough to vertical, with the
	# runner high enough above the ground and pushing along the wall.
	var too_far: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
	too_far.wall_distance = tuning.wall_run_distance * 1.5
	var too_short: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
	too_short.wall_height = tuning.wall_run_min_wall_height * 0.5
	var steep: Vector3 = LEFT_WALL.rotated(Vector3.FORWARD, deg_to_rad(30.0))
	var too_steep: MotorBody = _beside_a_wall(tuning, tuning.top_speed, steep)
	var too_low: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
	too_low.position.y = tuning.wall_run_min_height * 0.5
	var cases: Dictionary[String, MotorBody] = {
		"a wall too far": too_far,
		"a wall too short": too_short,
		"a wall leaning by 30 degrees": too_steep,
		"too close to the ground": too_low,
	}
	for context: String in cases:
		var body: MotorBody = cases[context]
		body.step(_run(FORWARD))
		assert_eq(body.motor.state, FALLING, context + ": no wall run")
	var mostly_into: Vector3 = (FORWARD - LEFT_WALL * 2.0).normalized()
	for direction: Vector3 in [Vector3.ZERO, -LEFT_WALL, mostly_into]:
		var body: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
		body.step(_run(direction))
		assert_eq(
			body.motor.state, FALLING, "pushing %s, not along the wall: no wall run" % direction
		)


func test_no_wall_run_without_speed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var too_slow: float = tuning.wall_run_start_speed - 0.1
	var body: MotorBody = _beside_a_wall(tuning, too_slow)
	var pace: Vector3 = FORWARD * too_slow / tuning.top_speed

	var falling_speed: float = body.velocity.y
	for i: int in SOME_STEPS:
		body.step(_run(pace))
		assert_eq(body.motor.state, FALLING, "still falling at step %d" % i)
		var gained: float = falling_speed - body.velocity.y
		assert_almost_eq(gained, tuning.fall_gravity * STEP, TOLERANCE, "normally, step %d" % i)
		falling_speed = body.velocity.y


func test_the_wall_run_slows_the_fall() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var along_the_wall: MotorBody = _wall_runner(tuning, tuning.top_speed)
	var in_the_air: MotorBody = MotorBody.new(tuning, HIGH)
	in_the_air.velocity = FORWARD * tuning.top_speed
	in_the_air.step(_run(FORWARD))
	# Fewer steps than the free fall takes to reach its fastest.
	var steps: int = 48

	for i: int in steps:
		along_the_wall.step(_run(FORWARD))
		in_the_air.step(_run(FORWARD))
		assert_eq(along_the_wall.motor.state, WALL_RUNNING, "still along the wall at step %d" % i)

	var lost_along_the_wall: float = HIGH - along_the_wall.position.y
	var lost_in_the_air: float = HIGH - in_the_air.position.y
	assert_gt(lost_along_the_wall, 0.0, "the runner goes down along the wall")
	var share: float = tuning.wall_run_gravity / tuning.fall_gravity
	assert_almost_eq(lost_along_the_wall, lost_in_the_air * share, TOLERANCE, "at its own gravity")
	assert_lt(lost_along_the_wall, lost_in_the_air / 2.0, "much less than in a free fall")

	# A runner still rising goes on with the gravity of its jump: no wall run climbs.
	var rising: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
	rising.velocity.y = tuning.wall_jump_up_speed
	rising.step(_run(FORWARD))
	assert_eq(rising.motor.state, WALL_RUNNING)
	var climbed: float = tuning.wall_jump_up_speed - rising.velocity.y
	assert_almost_eq(climbed, tuning.rise_gravity * STEP, TOLERANCE, "rising as a jump does")


func test_momentum_above_top_speed_is_kept_in_a_wall_run() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var fast: float = tuning.top_speed * 1.5
	var pushing: MotorBody = _wall_runner(tuning, fast)
	var pushing_halfway: MotorBody = _wall_runner(tuning, fast)
	var coasting: MotorBody = _wall_runner(tuning, fast)
	var pressing_on_the_wall: MotorBody = _wall_runner(tuning, fast)
	var mostly_into: Vector3 = (FORWARD - LEFT_WALL * 2.0).normalized()

	for i: int in WALL_RUN_STEPS - 1:
		pushing.step(_run(FORWARD))
		pushing_halfway.step(_run(FORWARD * 0.5))
		coasting.step(_run(Vector3.ZERO))
		pressing_on_the_wall.step(_run(mostly_into))
		var context: String = "at step %d" % i
		for body: MotorBody in [pushing, pushing_halfway, coasting, pressing_on_the_wall]:
			assert_eq(body.motor.state, WALL_RUNNING, "along the wall " + context)
			assert_almost_eq(
				body.horizontal_speed(), fast, TOLERANCE, "at the same speed " + context
			)
	assert_almost_eq(pushing.velocity.dot(FORWARD), fast, TOLERANCE, "all of it along the wall")

	# What the wall run does not take, a collision may: under its least speed, the
	# runner leaves the wall.
	var slowed_down: MotorBody = _wall_runner(tuning, fast)
	slowed_down.velocity = FORWARD * tuning.wall_run_stop_speed * 0.9
	slowed_down.step(_run(FORWARD))
	assert_eq(slowed_down.motor.state, FALLING, "slowed down under the least speed: off the wall")

	var faster_than_the_cap: MotorBody = _wall_runner(tuning, tuning.max_horizontal_speed * 2.0)
	for i: int in SOME_STEPS:
		faster_than_the_cap.step(_run(FORWARD))
		var speed: float = faster_than_the_cap.horizontal_speed()
		assert_almost_eq(speed, tuning.max_horizontal_speed, TOLERANCE, "capped at step %d" % i)


func test_the_wall_run_stops_at_the_end_of_its_duration() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _wall_runner(tuning, tuning.top_speed)
	var steps: int = 1
	while steps < WALL_RUN_STEPS:
		body.step(_run(FORWARD))
		assert_eq(body.motor.state, WALL_RUNNING, "still along the wall at step %d" % steps)
		steps += 1
	var falling_speed: float = body.velocity.y

	body.step(_run(FORWARD))

	assert_eq(body.motor.state, FALLING, "one step more: the runner leaves the wall")
	var gained: float = falling_speed - body.velocity.y
	assert_almost_eq(gained, tuning.fall_gravity * STEP, TOLERANCE, "and falls as in the air")

	# 1.21 s at 60 steps per second is 72.6 steps: 73 to the nearest step, 72 if truncated.
	var longer: MovementTuning = MotorBody.fixed_tuning()
	longer.wall_run_duration = 1.21
	var longer_run: MotorBody = _wall_runner(longer, longer.top_speed)
	for i: int in WALL_RUN_STEPS:
		longer_run.step(_run(FORWARD))
	assert_eq(longer_run.motor.state, WALL_RUNNING, "the 73rd step of 1.21 s is still along it")
	longer_run.step(_run(FORWARD))
	assert_eq(longer_run.motor.state, FALLING, "not the 74th")


func test_the_wall_run_stops_when_the_wall_stops() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _wall_runner(tuning, tuning.top_speed)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, WALL_RUNNING)

	body.remove_wall()
	body.step(_run(FORWARD))

	assert_eq(body.motor.state, FALLING, "the runner leaves the wall")
	assert_lt(body.velocity.y, 0.0, "and falls")


func test_pushing_away_from_the_wall_detaches() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var mostly_along: Vector3 = (FORWARD * 2.0 + LEFT_WALL).normalized()
	var into_the_wall: Vector3 = -LEFT_WALL
	for direction: Vector3 in [mostly_along, into_the_wall]:
		var staying: MotorBody = _wall_runner(tuning, tuning.top_speed)
		staying.step(_run(direction))
		assert_eq(staying.motor.state, WALL_RUNNING, "pushing %s keeps the runner on" % direction)

	var mostly_away: Vector3 = (FORWARD + LEFT_WALL * 2.0).normalized()
	for direction: Vector3 in [LEFT_WALL, mostly_away]:
		var body: MotorBody = _wall_runner(tuning, tuning.top_speed)
		body.step(_run(direction))
		assert_eq(body.motor.state, FALLING, "pushing %s away from the wall detaches" % direction)


func test_the_wall_jump_pushes_away_from_the_wall() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var fast: float = tuning.top_speed * 1.5
	var body: MotorBody = _wall_runner(tuning, fast)

	body.step(_jump(true))

	assert_eq(body.motor.state, RISING, "the runner jumps")
	assert_true(body.motor.jumped_off_a_wall, "off the wall")
	assert_almost_eq(body.velocity.y, tuning.wall_jump_up_speed, TOLERANCE, "upwards")
	var away: float = body.velocity.dot(LEFT_WALL)
	assert_almost_eq(away, tuning.wall_jump_away_speed, TOLERANCE, "away from the wall")
	var along: float = body.velocity.dot(FORWARD)
	assert_almost_eq(along, fast, TOLERANCE, "keeping its speed along the wall")

	# Released early, the jump rises less high, as a jump from the floor does.
	var held: MotorBody = _wall_runner(tuning, tuning.top_speed)
	var released: MotorBody = _wall_runner(tuning, tuning.top_speed)
	held.step(_jump(true))
	released.step(_jump(true))
	held.remove_wall()
	released.remove_wall()
	var start: float = held.position.y
	var held_top: float = start
	var released_top: float = start
	for i: int in WALL_RUN_STEPS:
		held.step(_jump(false))
		released.step(_run(FORWARD))
		held_top = maxf(held_top, held.position.y)
		released_top = maxf(released_top, released.position.y)
	assert_lt(released_top - start, (held_top - start) / 2.0, "released early, it rises less")


func test_the_wall_jump_remains_possible_just_after_detaching() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var in_time: MotorBody = _detached(tuning, GRACE_STEPS - 1)
	var too_late: MotorBody = _detached(tuning, GRACE_STEPS)

	in_time.step(_jump(true))
	too_late.step(_jump(true))

	assert_eq(in_time.motor.state, RISING, "at the last step of the grace: a jump")
	assert_true(in_time.motor.jumped_off_a_wall, "off the wall it left")
	assert_almost_eq(in_time.velocity.dot(LEFT_WALL), tuning.wall_jump_away_speed, TOLERANCE)
	assert_almost_eq(in_time.velocity.y, tuning.wall_jump_up_speed, TOLERANCE)
	assert_eq(too_late.motor.state, FALLING, "one step later: no jump")
	assert_false(too_late.motor.jumped_off_a_wall)
	assert_lt(too_late.velocity.y, 0.0, "it keeps falling")


func test_a_jump_requested_just_before_the_wall_gives_a_wall_jump() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var in_time: MotorBody = _jumping_towards_a_wall(tuning, BUFFER_STEPS)
	var too_early: MotorBody = _jumping_towards_a_wall(tuning, BUFFER_STEPS + 1)

	assert_eq(in_time.motor.state, RISING, "at the first step along the wall: a jump")
	assert_true(in_time.motor.jumped_off_a_wall, "off the wall")
	assert_almost_eq(in_time.velocity.dot(LEFT_WALL), tuning.wall_jump_away_speed, TOLERANCE)
	assert_almost_eq(in_time.velocity.y, tuning.wall_jump_up_speed, TOLERANCE)
	assert_eq(too_early.motor.state, WALL_RUNNING, "asked too early: a wall run, no jump")
	assert_false(too_early.motor.jumped_off_a_wall)


func test_the_same_wall_is_refused_twice_in_a_row() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _flying_off_a_wall(tuning, A_WALL)

	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	for i: int in SOME_STEPS:
		body.step(_run(FORWARD))
		assert_ne(body.motor.state, WALL_RUNNING, "no wall run along it at step %d" % i)

	# Nor a jump asked just before it: a refused wall gives no wall jump either.
	var jumping: MotorBody = _flying_off_a_wall(tuning, A_WALL)
	jumping.step(_jump(true))
	jumping.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	jumping.step(_jump(false))
	assert_false(jumping.motor.jumped_off_a_wall, "no wall jump off it")
	assert_ne(jumping.motor.state, WALL_RUNNING, "and no wall run")


func test_another_wall_is_accepted() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _flying_off_a_wall(tuning, A_WALL)

	body.set_wall(ANOTHER_WALL, RIGHT_WALL, CLOSE, TALL)
	body.step(_run(FORWARD))

	assert_eq(body.motor.state, WALL_RUNNING, "a wall run along the other wall")

	# Once the runner ran along another wall, the first one is accepted again.
	body.step(_jump(true))
	assert_true(body.motor.jumped_off_a_wall, "a wall jump off the other wall")
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, WALL_RUNNING, "back along the first wall")


func test_touching_the_ground_allows_the_same_wall_again() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var low: float = tuning.roll_fall_height / 2.0
	var body: MotorBody = _wall_runner(tuning, tuning.top_speed, low)
	body.remove_wall()
	var steps: int = 0
	while not body.on_floor and steps < WALL_RUN_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "the runner touched the ground")

	body.step(_jump(true))
	assert_eq(body.motor.state, RISING, "it jumps")
	while body.position.y < tuning.wall_run_min_height and steps < 2 * WALL_RUN_STEPS:
		body.step(_jump(false))
		steps += 1
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	body.step(_jump(false))

	assert_eq(body.motor.state, WALL_RUNNING, "along the same wall again")


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


## A body in the air at `altitude`, going forward at `speed`, beside a tall wall close
## to its side whose normal is `normal`.
func _beside_a_wall(
	tuning: MovementTuning, speed: float, normal: Vector3 = LEFT_WALL, altitude: float = HIGH
) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, altitude)
	body.velocity = FORWARD * speed
	body.set_wall(A_WALL, normal, CLOSE, TALL)
	return body


## A body that has just started to run along a wall at its left, at `speed`.
func _wall_runner(tuning: MovementTuning, speed: float, altitude: float = HIGH) -> MotorBody:
	var body: MotorBody = _beside_a_wall(tuning, speed, LEFT_WALL, altitude)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, WALL_RUNNING, "a wall runner")
	return body


## A body that left its wall `steps_off` steps ago, without jumping.
func _detached(tuning: MovementTuning, steps_off: int) -> MotorBody:
	var body: MotorBody = _wall_runner(tuning, tuning.top_speed)
	body.remove_wall()
	for i: int in steps_off:
		body.step(_run(FORWARD))
	assert_eq(body.motor.state, FALLING, "off the wall")
	return body


## A body in the air that asks for a jump, then finds a wall beside it `steps` steps
## later; it is returned right after that first step along the wall.
func _jumping_towards_a_wall(tuning: MovementTuning, steps: int) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, HIGH)
	body.velocity = FORWARD * tuning.top_speed
	body.step(_jump(true))
	for i: int in steps - 1:
		body.step(_jump(false))
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	body.step(_jump(false))
	return body


## A body that has just jumped off the wall `id` at its left, and flies away from it.
func _flying_off_a_wall(tuning: MovementTuning, id: int) -> MotorBody:
	var body: MotorBody = _beside_a_wall(tuning, tuning.top_speed)
	body.wall_id = id
	body.step(_run(FORWARD))
	body.step(_jump(true))
	assert_true(body.motor.jumped_off_a_wall, "a wall jump")
	body.remove_wall()
	for i: int in SOME_STEPS:
		body.step(_jump(false))
	return body
