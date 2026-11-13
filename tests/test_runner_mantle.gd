extends GutTest
## The mantle (game/core): in the air, pushing towards a ledge whose top is within the
## tuned heights and free, the runner climbs it and ends up standing on it. The tuning
## is the fixed one of MotorBody.

const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const MANTLING: RunnerMotor.State = RunnerMotor.State.MANTLING
const GROUNDED: RunnerMotor.State = RunnerMotor.State.GROUNDED
## The mantle of the fixed tuning (0.35 s), in fixed steps at 60 steps per second.
## Written out on purpose, not computed.
const MANTLE_STEPS: int = 21
## Where the runner is when it reaches the face: half a metre above its floor.
const IN_THE_AIR: float = 0.5
## How close to an end of the range of heights a ledge is put.
const NEAR_AN_END: float = 0.01
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600


func test_the_runner_mantles_onto_a_ledge_within_reach() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var middle: float = (tuning.mantle_min_height + tuning.mantle_max_height) / 2.0
	# Just inside both ends of the range: a ledge exactly at an end depends on rounding.
	var lowest: float = tuning.mantle_min_height + NEAR_AN_END
	var highest: float = tuning.mantle_max_height - NEAR_AN_END
	for height: float in [lowest, middle, highest]:
		var context: String = "a ledge %.2f m above the feet: " % height
		var body: MotorBody = _against_a_ledge(tuning, height)

		body.step(_run(FORWARD))
		assert_eq(body.motor.state, MANTLING, context + "the runner climbs")
		var steps: int = 1
		while body.motor.state == MANTLING and steps < MANY_STEPS:
			body.step(_run(FORWARD))
			steps += 1

		assert_eq(steps, MANTLE_STEPS, context + "for the tuned time")
		assert_eq(body.motor.state, GROUNDED, context + "then it stands")
		assert_true(body.on_floor, context + "on a floor")
		assert_almost_eq(
			body.position.y, body.ledge_top, TOLERANCE, context + "on top of the ledge"
		)
		assert_lt(body.position.z, body.ledge_face, context + "past its edge")
		var exit_speed: float = tuning.mantle_exit_speed
		assert_almost_eq(
			body.horizontal_speed(), exit_speed, TOLERANCE, context + "at the exit speed"
		)
		assert_almost_eq(body.velocity.normalized(), FORWARD, Vector3.ONE * TOLERANCE, "forwards")

	# A ledge lower than the range is not within reach: a runner rising along its face
	# does not climb it, it rises past its top.
	var rising: MotorBody = _against_a_ledge(tuning, tuning.mantle_min_height - NEAR_AN_END)
	rising.velocity.y = tuning.wall_jump_up_speed
	rising.step(_run(FORWARD))
	assert_ne(rising.motor.state, MANTLING, "a ledge under the range is not climbed")


func test_a_ledge_too_high_is_not_climbed() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	# A falling runner only sees its ledge get higher.
	var just_too_high: float = tuning.mantle_max_height + NEAR_AN_END
	for height: float in [just_too_high, tuning.mantle_max_height * 2.0]:
		var context: String = "a ledge %.2f m above the feet: " % height
		var body: MotorBody = _against_a_ledge(tuning, height)

		var steps: int = 0
		while not body.on_floor and steps < MANY_STEPS:
			body.step(_run(FORWARD))
			assert_ne(body.motor.state, MANTLING, context + "no mantle at step %d" % steps)
			steps += 1

		assert_true(body.on_floor, context + "the runner falls back")
		assert_almost_eq(body.position.y, 0.0, TOLERANCE, context + "to the floor it left")


func test_no_mantle_without_pushing_towards_the_ledge() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var height: float = (tuning.mantle_min_height + tuning.mantle_max_height) / 2.0
	var mostly_aside: Vector3 = (Vector3.RIGHT * 2.0 + FORWARD).normalized()
	var directions: Array[Vector3] = [Vector3.ZERO, Vector3.RIGHT, Vector3.BACK, mostly_aside]
	for direction: Vector3 in directions:
		var context: String = "pushing %s: " % direction
		var body: MotorBody = _against_a_ledge(tuning, height)

		for i: int in 10:
			body.step(_run(direction))
			assert_ne(body.motor.state, MANTLING, context + "no mantle at step %d" % i)

	# Pushing mostly towards the ledge is pushing towards it.
	var almost: MotorBody = _against_a_ledge(tuning, height)
	almost.step(_run((FORWARD * 2.0 + Vector3.RIGHT).normalized()))
	assert_eq(almost.motor.state, MANTLING, "pushing mostly towards the ledge climbs it")


func test_no_mantle_if_the_top_is_blocked() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var height: float = (tuning.mantle_min_height + tuning.mantle_max_height) / 2.0
	var body: MotorBody = _against_a_ledge(tuning, height)
	body.ledge_clear = false

	for i: int in 10:
		body.step(_run(FORWARD))
		assert_ne(body.motor.state, MANTLING, "no mantle at step %d" % i)


func test_the_mantle_goes_to_the_end() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var height: float = tuning.mantle_max_height - NEAR_AN_END
	var body: MotorBody = _against_a_ledge(tuning, height)
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, MANTLING, "a mantle under way")

	var steps: int = 1
	while body.motor.state == MANTLING and steps < MANY_STEPS:
		var asking: MoveIntent = _run(FORWARD)
		asking.jump_pressed = true
		asking.jump_held = true
		asking.slide_pressed = true
		asking.slide_held = true
		body.step(asking)
		steps += 1

	assert_eq(steps, MANTLE_STEPS, "neither the jump nor the slide cut it short")
	assert_eq(body.motor.state, GROUNDED, "the runner stands")
	assert_almost_eq(body.position.y, body.ledge_top, TOLERANCE, "on top of the ledge")
	assert_lt(body.position.z, body.ledge_face, "past its edge")
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "and the jumps asked during the mantle are forgotten")
	assert_eq(body.velocity.y, 0.0, "it stays on the ledge")

	# A mantle is a contact with the ground: one reached by a fall from high sets off
	# standing, even when the mantle ends a step before the floor is felt under the feet
	# (as the real physics may report it).
	var fallen: MotorBody = MotorBody.new(tuning, tuning.roll_fall_height * 2.0)
	fallen.has_ledge = true
	fallen.ledge_face = fallen.position.z - tuning.capsule_radius
	fallen.ledge_top = tuning.roll_fall_height / 2.0
	steps = 0
	while fallen.motor.state != MANTLING and steps < MANY_STEPS:
		# Straight down past the top, then towards the face.
		var beside_the_face: bool = fallen.position.y < fallen.ledge_top
		fallen.step(_run(FORWARD if beside_the_face else Vector3.ZERO))
		steps += 1
	assert_eq(fallen.motor.state, MANTLING, "after a high fall, a mantle")
	fallen.has_floor = false
	while fallen.motor.state == MANTLING and steps < MANY_STEPS:
		fallen.step(_run(FORWARD))
		steps += 1
	assert_eq(fallen.motor.state, RunnerMotor.State.FALLING, "over, before the floor is felt")
	fallen.has_floor = true
	while not fallen.on_floor and steps < MANY_STEPS:
		fallen.step(_run(FORWARD))
		steps += 1
	fallen.step(_run(FORWARD))
	assert_eq(fallen.motor.state, GROUNDED, "then it stands on the ledge: no hard landing")
	assert_almost_eq(fallen.position.y, fallen.ledge_top, TOLERANCE)


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## A body in the air, stopped against the face of a ledge whose top is `height` above
## its feet.
func _against_a_ledge(tuning: MovementTuning, height: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, IN_THE_AIR)
	body.put_ledge_ahead(height)
	return body
