extends GutTest
## Momentum (game/core): a horizontal speed above the top speed is not taken away at
## once. The air keeps it, the floor brings it back down slowly, and an absolute cap
## bounds it. The tuning is the fixed one of MotorBody.

const STEP: float = MotorBody.STEP
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001


func test_momentum_above_top_speed_is_kept_in_the_air() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var fast: float = tuning.top_speed * 1.5
	var pushing: MotorBody = _in_the_air(tuning, fast)
	var pushing_halfway: MotorBody = _in_the_air(tuning, fast)
	var coasting: MotorBody = _in_the_air(tuning, fast)
	var turning: MotorBody = _in_the_air(tuning, fast)

	for i: int in 60:
		pushing.step(_run(FORWARD))
		pushing_halfway.step(_run(FORWARD * 0.5))
		coasting.step(_run(Vector3.ZERO))
		turning.step(_run(Vector3.RIGHT))
		var context: String = "at step %d" % i
		assert_almost_eq(pushing.horizontal_speed(), fast, TOLERANCE, "pushing forward " + context)
		assert_almost_eq(pushing_halfway.horizontal_speed(), fast, TOLERANCE, "halfway " + context)
		assert_almost_eq(coasting.horizontal_speed(), fast, TOLERANCE, "pushing nothing " + context)
	# Kept without changing direction: turning costs speed, as it does under the top speed.
	assert_lt(turning.horizontal_speed(), fast, "pushing aside, some speed went into the turn")
	assert_gt(turning.velocity.dot(Vector3.RIGHT), 0.0, "and the runner did turn")


func test_momentum_comes_down_slowly_on_the_floor() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var loss: float = tuning.momentum_deceleration * STEP
	# Half a step of loss more than a round number of steps above the top speed.
	var fast: float = tuning.top_speed * 1.5 + loss / 2.0
	var body: MotorBody = MotorBody.new(tuning)
	body.velocity = FORWARD * fast
	var steps_to_top: int = ceili((fast - tuning.top_speed) / loss)

	var previous: float = fast
	for i: int in steps_to_top - 1:
		body.step(_run(FORWARD))
		assert_almost_eq(previous - body.horizontal_speed(), loss, TOLERANCE, "step %d" % i)
		previous = body.horizontal_speed()
	assert_gt(body.horizontal_speed(), tuning.top_speed, "not back to the top speed at once")

	for i: int in 10:
		body.step(_run(FORWARD))
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "then it stays there")

	var braking: MotorBody = MotorBody.new(tuning)
	braking.velocity = FORWARD * fast
	braking.step(_run(Vector3.ZERO))
	var braked: float = fast - braking.horizontal_speed()
	assert_almost_eq(braked, tuning.ground_deceleration * STEP, TOLERANCE, "braking is unchanged")


func test_the_horizontal_speed_has_an_absolute_cap() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var cap: float = tuning.max_horizontal_speed
	var body: MotorBody = _slider_on_a_steep_slope(tuning, cap - 1.0)

	var fastest: float = body.horizontal_speed()
	for i: int in 60:
		body.step(_slide(FORWARD))
		assert_eq(
			body.motor.state, RunnerMotor.State.SLIDING, "the slope still pulls at step %d" % i
		)
		fastest = maxf(fastest, body.horizontal_speed())
	assert_almost_eq(fastest, cap, TOLERANCE, "it reaches the cap, no more")
	assert_almost_eq(body.horizontal_speed(), cap, TOLERANCE, "and stays there")

	var pushed: MotorBody = _in_the_air(tuning, cap * 2.0)
	pushed.step(_run(FORWARD))
	assert_almost_eq(pushed.horizontal_speed(), cap, TOLERANCE, "whatever pushed the runner")


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


func _slide(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.slide_held = true
	return intent


## A body far above the floor, going forward at `speed`.
func _in_the_air(tuning: MovementTuning, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning, 1000.0)
	body.velocity = FORWARD * speed
	return body


## A body sliding forward at about `speed` down a slope of 30 degrees.
func _slider_on_a_steep_slope(tuning: MovementTuning, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning)
	var angle: float = deg_to_rad(30.0)
	body.floor_normal = Vector3(0.0, cos(angle), -sin(angle))
	body.velocity = FORWARD * speed
	body.step(_slide(FORWARD))
	return body
