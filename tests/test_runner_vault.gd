extends GutTest
## The vault (game/core, docs/specs/vault.md): on the ground, running fast enough towards a
## low and thin obstacle within reach, with room behind it, the runner passes over it
## without a button, and comes out on the other side on the ground, in the same direction,
## having kept most of its speed. The tuning is the fixed one of MotorBody; the runners go
## along -Z.

const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const VAULTING: RunnerMotor.State = RunnerMotor.State.VAULTING
const GROUNDED: RunnerMotor.State = RunnerMotor.State.GROUNDED
const VAULT: RunnerEvent.Kind = RunnerEvent.Kind.VAULT
## The vault of the fixed tuning (0.4 s), in fixed steps at 60 steps per second. Written
## out on purpose, not computed.
const VAULT_STEPS: int = 24
## The low wall of the scenarios: 1 m high, 0.4 m deep; where it stands at the start,
## before the runner: out of reach.
const WALL_HEIGHT: float = 1.0
const WALL_DEPTH: float = 0.4
const START_DISTANCE: float = 2.0
## The speed of the scenarios: a run, and a walk.
const RUN_SPEED: float = 6.0
const WALK_SPEED: float = 2.0
## Too high, and too deep, for the fixed tuning.
const TOO_HIGH: float = 1.6
const TOO_DEEP: float = 3.0
## Steps enough for a runner to reach the wall, and more than any vault lasts.
const MANY_STEPS: int = 120
const STEPS_PER_SECOND: int = 60


func test_a_low_and_thin_obstacle_is_vaulted_at_a_run() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, WALL_DEPTH)

	var steps: int = _run_until_it_vaults(body, RUN_SPEED)
	assert_eq(body.motor.state, VAULTING, "the runner vaults, without a button")
	# Where its front was as the step started: what it observed.
	var front: float = body.position.z - body.velocity.z * MotorBody.STEP - tuning.capsule_radius
	assert_lte(front - body.ledge_face, tuning.vault_reach + TOLERANCE, "with the wall in reach")
	var vault_steps: int = 0
	var exit_velocity: Vector3 = Vector3.ZERO
	while body.motor.state == VAULTING and steps < MANY_STEPS:
		vault_steps += 1
		exit_velocity = body.velocity
		assert_gt(
			body.position.y + TOLERANCE,
			body.ledge_top if _is_over(body) else 0.0,
			"over the wall, the feet are above its top (step %d)" % vault_steps
		)
		body.step(_run(FORWARD * RUN_SPEED / tuning.top_speed))
		steps += 1

	assert_eq(vault_steps, VAULT_STEPS, "for the tuned time")
	assert_eq(body.motor.state, GROUNDED, "then it runs on")
	assert_true(body.on_floor, "on the ground")
	assert_almost_eq(body.position.y, 0.0, TOLERANCE, "the ground behind the wall")
	assert_lt(body.position.z, body.ledge_face - WALL_DEPTH, "on the other side of the wall")
	var kept: float = RUN_SPEED * tuning.vault_speed_kept
	var horizontal: Vector3 = Vector3(exit_velocity.x, 0.0, exit_velocity.z)
	assert_almost_eq(horizontal.length(), kept, TOLERANCE, "at 90 % of its speed")
	assert_almost_eq(horizontal.normalized(), FORWARD, Vector3.ONE * TOLERANCE, "the same way")

	# A jump asked for as the wall comes within reach comes first: the runner jumps.
	var jumper: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, WALL_DEPTH)
	var direction: Vector3 = FORWARD * RUN_SPEED / tuning.top_speed
	while jumper.position.z - tuning.capsule_radius - jumper.ledge_face > tuning.vault_reach:
		jumper.step(_run(direction))
	jumper.step(_jump(direction))
	assert_eq(jumper.motor.state, RunnerMotor.State.RISING, "a jump asked for comes first")


func test_too_slow_no_vault() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _running_at_a_wall(tuning, WALK_SPEED, WALL_HEIGHT, WALL_DEPTH)

	for i: int in MANY_STEPS:
		body.step(_run(FORWARD * WALK_SPEED / tuning.top_speed))
		assert_ne(body.motor.state, VAULTING, "no vault at step %d" % i)

	assert_almost_eq(
		body.position.z, body.ledge_face + tuning.capsule_radius, TOLERANCE, "stopped at the wall"
	)


func test_too_high_or_too_deep_no_vault() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var high: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, TOO_HIGH, WALL_DEPTH)
	var deep: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, TOO_DEEP)

	for body: MotorBody in [high, deep]:
		var context: String = "%.1f m high, %.1f m deep: " % [body.ledge_top, body.ledge_depth]
		for i: int in MANY_STEPS:
			body.step(_run(FORWARD * RUN_SPEED / tuning.top_speed))
			assert_ne(body.motor.state, VAULTING, context + "no vault at step %d" % i)
		var against: float = body.ledge_face + tuning.capsule_radius
		assert_almost_eq(body.position.z, against, TOLERANCE, context + "stopped at it")

	# Just inside the limits, it vaults.
	var near_an_end: float = 0.01
	var limits: MotorBody = _running_at_a_wall(
		tuning,
		RUN_SPEED,
		tuning.vault_max_height - near_an_end,
		tuning.vault_max_depth - near_an_end
	)
	_run_until_it_vaults(limits, RUN_SPEED)
	assert_eq(limits.motor.state, VAULTING, "the highest and deepest obstacle is vaulted")
	var lowest: MotorBody = _running_at_a_wall(
		tuning, RUN_SPEED, tuning.vault_min_height + near_an_end, WALL_DEPTH
	)
	_run_until_it_vaults(lowest, RUN_SPEED)
	assert_eq(lowest.motor.state, VAULTING, "and so is the lowest")


func test_no_vault_without_room_behind() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, WALL_DEPTH)
	body.room_behind = false

	for i: int in MANY_STEPS:
		body.step(_run(FORWARD * RUN_SPEED / tuning.top_speed))
		assert_ne(body.motor.state, VAULTING, "no vault at step %d" % i)


func test_the_vault_goes_to_the_end() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var body: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, WALL_DEPTH)
	var steps: int = _run_until_it_vaults(body, RUN_SPEED)
	assert_eq(body.motor.state, VAULTING, "a vault under way")

	# Asked at every step while the vault has time left; the step that follows it is the
	# runner's again.
	var vault_steps: int = 0
	while body.motor.state == VAULTING and steps < MANY_STEPS:
		vault_steps += 1
		var asking: MoveIntent = _run(FORWARD * RUN_SPEED / tuning.top_speed)
		if vault_steps < VAULT_STEPS:
			asking.jump_pressed = true
			asking.jump_held = true
			asking.slide_pressed = true
			asking.slide_held = true
		body.step(asking)
		steps += 1

	assert_eq(vault_steps, VAULT_STEPS, "neither the jump nor the slide cut it short")
	assert_eq(body.motor.state, GROUNDED, "the runner stands")
	assert_lt(body.position.z, body.ledge_face - WALL_DEPTH, "on the other side")
	var position: float = body.position.z
	body.step(_run(FORWARD))
	assert_eq(body.motor.state, GROUNDED, "the jumps asked during the vault are forgotten")
	assert_eq(body.velocity.y, 0.0, "it stays on the ground")
	assert_lt(body.position.z, position, "and sets off again")
	body.step(_jump(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.RISING, "a new jump takes it into the air")


func test_the_vault_is_a_flow_move() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var flow: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	var body: MotorBody = _running_at_a_wall(tuning, RUN_SPEED, WALL_HEIGHT, WALL_DEPTH)
	assert_false(flow.in_combo(), "no combo")

	var steps: int = 0
	while body.motor.state != VAULTING and steps < MANY_STEPS:
		body.step(_run(FORWARD * RUN_SPEED / tuning.top_speed))
		flow.follow(body.motor)
		steps += 1

	assert_eq(body.motor.state, VAULTING, "the runner vaults")
	assert_eq(body.motor.events.size(), 1, "one message")
	if body.motor.events.size() == 1:
		assert_eq(body.motor.events[0].kind, VAULT, "a vault")
		assert_eq(body.motor.events[0].step, body.motor.steps, "dated by the step it started")
	assert_eq(flow.last_move, VAULT, "the flow counted a vault")
	assert_eq(flow.last_points, 150, "for 150 points, x1")
	assert_eq(flow.style_score, 150, "in the style score")
	assert_true(flow.in_combo(), "it starts a combo")

	# Subject to the repetition, as any move.
	var again: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	var vault: Array[RunnerEvent] = [RunnerEvent.new(VAULT, 0)]
	again.step(vault, RUN_SPEED, false)
	again.step(vault, RUN_SPEED, false)
	assert_eq(again.last_points, 75, "a second vault in a row is worth half")


## Steps `body` at `speed` along -Z until it vaults, or for many steps: how many.
func _run_until_it_vaults(body: MotorBody, speed: float) -> int:
	var steps: int = 0
	while body.motor.state != VAULTING and steps < MANY_STEPS:
		body.step(_run(FORWARD * speed / body.motor.tuning.top_speed))
		steps += 1
	return steps


## A body on the floor that runs at `speed` along -Z, a block across its way out of reach,
## `height` high and `depth` deep.
func _running_at_a_wall(
	tuning: MovementTuning, speed: float, height: float, depth: float
) -> MotorBody:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, speed)
	body.put_block_ahead(START_DISTANCE, height, depth)
	return body


## The axis of `body` is over the block.
func _is_over(body: MotorBody) -> bool:
	return (
		body.position.z < body.ledge_face and body.position.z > body.ledge_face - body.ledge_depth
	)


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


func _jump(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.jump_pressed = true
	intent.jump_held = true
	return intent
