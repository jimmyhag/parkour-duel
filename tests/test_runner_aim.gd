extends TrickTest
## Aiming, in the runner's motor (game/core): it slows the runner down on the ground,
## changes nothing in the air, and starts no trick. The runner slows down, never the
## world: the motor knows no clock.

## Steps a runner at the top speed is given to come down to the top speed of an aim.
const SLOWING_STEPS: int = 30
## Steps of a long aim, and of the run that follows it.
const LONG_STEPS: int = 90


func test_aiming_slows_the_runner_down_on_the_ground() -> void:
	var aiming: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var running: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	assert_almost_eq(aiming.horizontal_speed(), _tuning.top_speed, TOLERANCE, "at top speed")
	var aim_speed: float = _tuning.top_speed * _tuning.aim_speed_ratio

	var slowest: float = INF
	for step: int in LONG_STEPS:
		aiming.step(_aim(FORWARD))
		running.step(_push(FORWARD))
		slowest = minf(slowest, aiming.horizontal_speed())
		assert_gte(aiming.horizontal_speed(), aim_speed - TOLERANCE, "never under the aim speed")
		if step == SLOWING_STEPS:
			assert_almost_eq(aiming.horizontal_speed(), aim_speed, TOLERANCE, "down to it")

	assert_almost_eq(aiming.horizontal_speed(), aim_speed, TOLERANCE, "it stays there")
	assert_eq(aiming.motor.state, RunnerMotor.State.GROUNDED, "on the ground all along")
	assert_almost_eq(running.horizontal_speed(), _tuning.top_speed, TOLERANCE, "the other runs")
	var behind: float = aiming.position.z - running.position.z
	assert_gt(behind, 2.0, "aiming cost the runner its advance")

	# Once the aim is released, the runner goes back up to its top speed.
	for step: int in SLOWING_STEPS:
		aiming.step(_push(FORWARD))
	assert_almost_eq(aiming.horizontal_speed(), _tuning.top_speed, TOLERANCE, "back to top speed")


func test_aiming_changes_nothing_in_the_air() -> void:
	var aiming: MotorBody = _launched()
	var plain: MotorBody = _launched()
	var steps: int = 0

	while not plain.on_floor and steps < MANY_STEPS:
		# The same push for both, changing along the flight; one aims, then lets go, then
		# aims again.
		var push: Vector3 = FORWARD.rotated(Vector3.UP, 0.6 * sin(steps * 0.2))
		var intent: MoveIntent = _aim(push) if steps % 24 < 16 else _push(push)
		aiming.step(intent)
		plain.step(_push(push))
		var context: String = "step %d" % steps
		assert_eq(aiming.position, plain.position, context + ": the same place")
		assert_eq(aiming.velocity, plain.velocity, context + ": the same velocity")
		steps += 1

	assert_gt(steps, 30, "a long flight")
	assert_true(aiming.on_floor, "both land")
	assert_eq(aiming.position, plain.position, "at the same place")


func test_no_trick_while_aiming() -> void:
	# In the air, aiming: pressing the trick, again and again, starts nothing.
	var body: MotorBody = _high()
	for step: int in 20:
		var intent: MoveIntent = _aim(BACK)
		intent.trick_pressed = step % 5 == 0
		intent.trick_held = true
		body.step(intent)
		assert_null(body.motor.current_trick(), "step %d: no trick starts" % step)

	# Released, the aim no longer holds the trick back.
	body.step(_trick(BACK))
	var trick: AirTrick = body.motor.current_trick()
	assert_not_null(trick, "without aiming, a trick starts")

	# A trick under way goes on to its end when the runner starts aiming.
	for step: int in range(1, TURN_STEPS):
		var intent: MoveIntent = _aim(BACK)
		intent.trick_held = step < TURN_STEPS / 2
		body.step(intent)
		assert_true(body.motor.is_in_a_trick(), "step %d of the turn: under way" % step)
	body.step(_aim(BACK))
	assert_not_null(trick)
	if trick != null:
		assert_true(trick.finished, "the trick finished its turn")
		assert_eq(trick.turns, 1, "with one turn")


## The aim held, pushing `direction`.
func _aim(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _push(direction)
	intent.aim_held = true
	return intent
