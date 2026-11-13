extends GutTest
## Where the moves of game/core meet: a low runner neither runs along a wall nor
## mantles, a wall run does not mantle, the fall of a wall run counts from its highest
## point, and a runner kept low by a ceiling keeps moving and lands by the rule of the
## roll. The tuning is the fixed one of MotorBody; the runners go along -Z.

const STEP: float = MotorBody.STEP
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
const MANTLING: RunnerMotor.State = RunnerMotor.State.MANTLING
const FALLING: RunnerMotor.State = RunnerMotor.State.FALLING
const SLIDING: RunnerMotor.State = RunnerMotor.State.SLIDING
const HARD_LANDING: RunnerMotor.State = RunnerMotor.State.HARD_LANDING
## The hard landing of the fixed tuning (0.35 s) in fixed steps, written out on purpose.
const HARD_LANDING_STEPS: int = 21
## The normal of a wall at the left of a runner going along -Z.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const A_WALL: int = 1
const CLOSE: float = 0.3
const TALL: float = 10.0
const SOME_STEPS: int = 5
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600


func test_no_wall_run_or_mantle_while_low() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var low: MotorBody = _low_in_the_air(tuning)
	# The same runner standing: what the facts allow when the runner is not low.
	var standing: MotorBody = _low_in_the_air(tuning)
	standing.can_stand = true
	standing.step(_run(FORWARD))
	assert_false(standing.motor.is_low(), "with room, the runner stands up in the air")
	var height: float = (tuning.mantle_min_height + tuning.mantle_max_height) / 2.0

	for body: MotorBody in [low, standing]:
		body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	low.step(_run(FORWARD))
	standing.step(_run(FORWARD))
	assert_eq(standing.motor.state, WALL_RUNNING, "standing, it would run along the wall")
	for i: int in SOME_STEPS:
		assert_ne(low.motor.state, WALL_RUNNING, "low, no wall run at step %d" % i)
		assert_true(low.motor.is_low(), "and still low")
		low.step(_run(FORWARD))

	standing = _low_in_the_air(tuning)
	standing.can_stand = true
	standing.step(_run(FORWARD))
	for body: MotorBody in [low, standing]:
		body.remove_wall()
		body.put_ledge_ahead(height)
	low.step(_run(FORWARD))
	standing.step(_run(FORWARD))
	assert_eq(standing.motor.state, MANTLING, "standing, it would mantle")
	for i: int in SOME_STEPS:
		assert_ne(low.motor.state, MANTLING, "low, no mantle at step %d" % i)
		assert_true(low.motor.is_low(), "and still low")
		low.step(_run(FORWARD))


func test_no_mantle_during_a_wall_run() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var height: float = (tuning.mantle_min_height + tuning.mantle_max_height) / 2.0
	var motor: RunnerMotor = RunnerMotor.new(tuning)
	var velocity: Vector3 = FORWARD * tuning.top_speed
	var altitude: float = height * 4.0
	velocity = motor.step(_run(FORWARD), _beside_a_wall(velocity, altitude), STEP)
	assert_eq(motor.state, WALL_RUNNING, "a wall run")

	for i: int in SOME_STEPS:
		var facts: RunnerFacts = _beside_a_wall(velocity, altitude)
		_put_a_ledge_ahead(facts, height)
		velocity = motor.step(_run(FORWARD), facts, STEP)
		assert_eq(motor.state, WALL_RUNNING, "still along the wall at step %d" % i)

	# Once off the wall, the same ledge is climbed.
	var off_the_wall: RunnerFacts = _beside_a_wall(velocity, altitude)
	off_the_wall.wall_id = RunnerFacts.NO_WALL
	off_the_wall.wall_normal = Vector3.ZERO
	_put_a_ledge_ahead(off_the_wall, height)
	motor.step(_run(FORWARD), off_the_wall, STEP)
	assert_eq(motor.state, FALLING, "the runner leaves the wall first")
	motor.step(_run(FORWARD), off_the_wall, STEP)
	assert_eq(motor.state, MANTLING, "then it mantles")


func test_the_fall_height_counts_from_a_wall_run() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: float = tuning.roll_fall_height * 1.5
	var left_at_once: MotorBody = _wall_runner(tuning, high)
	left_at_once.remove_wall()

	# One that slid down the wall to lower than the height that asks for a roll before
	# it let go: the fall still counts from where the wall run started.
	var slid_down: MotorBody = _wall_runner(tuning, tuning.roll_fall_height * 1.25)
	var steps: int = 0
	while slid_down.motor.state == WALL_RUNNING and not slid_down.on_floor and steps < MANY_STEPS:
		slid_down.step(_run(FORWARD))
		steps += 1
	assert_lt(slid_down.position.y, tuning.roll_fall_height, "it let go low")
	assert_false(slid_down.on_floor, "before the ground")

	# One that fell from higher onto the wall: the fall counts from before the wall run.
	var fell_onto_it: MotorBody = MotorBody.new(tuning, tuning.roll_fall_height * 1.25)
	fell_onto_it.velocity = FORWARD * tuning.top_speed
	while fell_onto_it.position.y > tuning.roll_fall_height * 0.75 and steps < MANY_STEPS:
		fell_onto_it.step(_run(FORWARD))
		steps += 1
	fell_onto_it.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	fell_onto_it.step(_run(FORWARD))
	assert_eq(fell_onto_it.motor.state, WALL_RUNNING, "it caught the wall low")

	for body: MotorBody in [left_at_once, slid_down, fell_onto_it]:
		steps = 0
		while not body.on_floor and steps < MANY_STEPS:
			body.step(_run(FORWARD))
			steps += 1
		body.step(_run(FORWARD))
		assert_eq(body.motor.state, HARD_LANDING, "landed without a roll: a hard landing")


func test_the_runner_does_not_get_stuck_over_a_crack_under_a_low_ceiling() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var slow: MotorBody = _low_in_the_air(tuning)
	slow.velocity = FORWARD * tuning.slide_stop_speed / 4.0
	var stopped: MotorBody = _low_in_the_air(tuning)
	stopped.velocity = Vector3.ZERO

	slow.step(_run(FORWARD))
	var least: float = tuning.slide_stop_speed
	assert_almost_eq(
		slow.velocity.dot(FORWARD), least, TOLERANCE, "pushing: off at the least speed"
	)
	for i: int in SOME_STEPS:
		slow.step(_run(FORWARD))
		stopped.step(_run(Vector3.ZERO))
		for body: MotorBody in [slow, stopped]:
			var context: String = "%s at step %d: " % ["slow" if body == slow else "stopped", i]
			assert_eq(body.motor.state, FALLING, context + "in the air")
			assert_true(body.motor.is_low(), context + "low")
		assert_gt(slow.velocity.dot(FORWARD), least, "pushing, it goes on faster, step %d" % i)
		var forward: float = stopped.velocity.dot(FORWARD)
		assert_almost_eq(
			forward, least, TOLERANCE, "stopped dead, off the way it went, step %d" % i
		)


func test_a_big_fall_landed_under_a_low_ceiling_without_a_roll_is_hard() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var drop: float = tuning.roll_fall_height * 1.25
	var body: MotorBody = _low_in_the_air(tuning)
	var rolling: MotorBody = _low_in_the_air(tuning)
	for falling: MotorBody in [body, rolling]:
		falling.floor_height = -drop
		falling.has_floor = true
	var landing_step: int = _steps_to_the_floor(tuning, drop)

	for i: int in landing_step + 1:
		body.step(_run(FORWARD))
		var pressing: MoveIntent = _run(FORWARD)
		pressing.slide_pressed = i == landing_step - 1
		pressing.slide_held = pressing.slide_pressed
		rolling.step(pressing)

	assert_eq(rolling.motor.state, RunnerMotor.State.ROLLING, "pressed in time: a roll")
	assert_eq(body.motor.state, HARD_LANDING, "not pressed: a hard landing")
	var kept: float = tuning.top_speed * tuning.hard_landing_speed_ratio
	assert_almost_eq(body.horizontal_speed(), kept, TOLERANCE, "which costs speed")
	for i: int in HARD_LANDING_STEPS - 1:
		assert_true(body.motor.is_low(), "low through the hard landing, step %d" % i)
		body.step(_run(FORWARD))
		assert_gte(body.horizontal_speed(), tuning.slide_stop_speed - TOLERANCE, "never stuck")
	assert_eq(body.motor.state, HARD_LANDING)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, SLIDING, "still no room once it is over: low, sliding")

	body.can_stand = true
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "up as soon as there is room")
	assert_false(body.motor.is_low())


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## A body that slid off its floor at the top speed where a ceiling keeps it low: it is
## low in the air.
func _low_in_the_air(tuning: MovementTuning) -> MotorBody:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var slide: MoveIntent = _run(FORWARD)
	slide.slide_pressed = true
	slide.slide_held = true
	body.step(slide)
	assert_eq(body.motor.state, SLIDING, "a slide")
	body.can_stand = false
	body.has_floor = false
	# The first step leaves the floor, the second one is in the air.
	body.step(_run(FORWARD))
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, FALLING, "off the floor")
	assert_true(body.motor.is_low(), "low")
	return body


## A body that has just started to run along a wall at its left, at `altitude`.
func _wall_runner(tuning: MovementTuning, altitude: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, altitude)
	body.velocity = FORWARD * tuning.top_speed
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, WALL_RUNNING, "a wall runner")
	return body


## What the player layer would report of a runner in the air at `altitude`, far above
## the ground, beside a tall wall at its left.
func _beside_a_wall(velocity: Vector3, altitude: float) -> RunnerFacts:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.velocity = velocity
	facts.altitude = altitude
	facts.wall_id = A_WALL
	facts.wall_normal = LEFT_WALL
	facts.wall_distance = CLOSE
	facts.wall_height = TALL
	return facts


## Adds a ledge right in front of the runner, its top `height` above its feet and free.
func _put_a_ledge_ahead(facts: RunnerFacts, height: float) -> void:
	facts.ledge_normal = Vector3.BACK
	facts.ledge_height = height
	facts.ledge_clear = true


## The steps a body low in the air, at the altitude 0 with no vertical speed, takes to
## fall `drop` metres: the index of its first step on the floor.
func _steps_to_the_floor(tuning: MovementTuning, drop: float) -> int:
	var body: MotorBody = _low_in_the_air(tuning)
	body.floor_height = -drop
	body.has_floor = true
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	return steps
