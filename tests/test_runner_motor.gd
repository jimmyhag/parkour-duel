extends GutTest
## The runner's logic (game/core): run, jump, coyote time, jump buffer, air control.
## The tuning is fixed here on purpose: these tests check the rules, not the values the
## owner tunes in movement_tuning.tres.

const STEP: float = 1.0 / 60.0
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const SETTLE_STEPS: int = 60
## The windows of the tuning below, in fixed steps at 60 steps per second: durations
## are rounded to the nearest step (0.10 s is 6 steps, 0.12 s is 7 steps). Written out
## on purpose, not computed: a change of rounding must fail here.
const COYOTE_STEPS: int = 6
const BUFFER_STEPS: int = 7


## A runner over a flat floor at height 0, playing the part of the player layer: it
## feeds the motor with what it observes and moves by the velocity the motor returns.
class Body:
	var motor: RunnerMotor
	var velocity: Vector3 = Vector3.ZERO
	var height: float = 0.0
	var apex: float = 0.0
	var has_floor: bool = true
	var on_floor: bool = true

	func _init(tuning: MovementTuning, start_height: float = 0.0) -> void:
		motor = RunnerMotor.new(tuning)
		height = start_height
		on_floor = start_height <= 0.0

	func step(intent: MoveIntent) -> void:
		var facts: RunnerFacts = RunnerFacts.new()
		facts.on_floor = on_floor
		facts.velocity = velocity
		facts.altitude = height
		velocity = motor.step(intent, facts, STEP)
		height += velocity.y * STEP
		on_floor = has_floor and height <= 0.0 and velocity.y <= 0.0
		if on_floor:
			height = 0.0
			velocity.y = 0.0
		apex = maxf(apex, height)

	func horizontal_speed() -> float:
		return Vector2(velocity.x, velocity.z).length()


func test_the_runner_accelerates_up_to_top_speed() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = Body.new(tuning)
	var steps_to_top: int = ceili(tuning.top_speed / (tuning.ground_acceleration * STEP))

	var previous: float = 0.0
	for i: int in steps_to_top - 1:
		body.step(_intent(FORWARD))
		assert_gt(body.horizontal_speed(), previous, "faster at step %d" % i)
		previous = body.horizontal_speed()

	for i: int in SETTLE_STEPS:
		body.step(_intent(FORWARD))
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "top speed")
	body.step(_intent(FORWARD))
	assert_almost_eq(body.horizontal_speed(), tuning.top_speed, TOLERANCE, "and it stays")
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED)


func test_the_runner_stops_when_the_intent_ceases() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = _body_at_top_speed(tuning)
	var braking: float = tuning.ground_deceleration * STEP
	var steps_to_stop: int = ceili(tuning.top_speed / braking)

	var previous: float = body.horizontal_speed()
	for i: int in steps_to_stop - 1:
		body.step(_intent(Vector3.ZERO))
		assert_almost_eq(previous - body.horizontal_speed(), braking, TOLERANCE, "step %d" % i)
		previous = body.horizontal_speed()
	assert_gt(body.horizontal_speed(), 0.0, "not stopped before the braking time")

	body.step(_intent(Vector3.ZERO))
	body.step(_intent(Vector3.ZERO))
	assert_eq(body.horizontal_speed(), 0.0, "stopped")


func test_a_half_pushed_stick_gives_a_reduced_top_speed() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = Body.new(tuning)

	for i: int in SETTLE_STEPS:
		body.step(_intent(FORWARD * 0.5))

	assert_almost_eq(body.horizontal_speed(), tuning.top_speed * 0.5, TOLERANCE)


func test_a_held_jump_reaches_the_tuned_height() -> void:
	var tuning: MovementTuning = _tuning()

	var apex: float = _apex_of_a_jump(tuning, SETTLE_STEPS)

	assert_almost_eq(apex, tuning.jump_height, tuning.jump_height * 0.05)


func test_a_jump_released_early_rises_less_high() -> void:
	var tuning: MovementTuning = _tuning()

	var held_apex: float = _apex_of_a_jump(tuning, SETTLE_STEPS)
	var released_apex: float = _apex_of_a_jump(tuning, 1)

	assert_gt(released_apex, 0.0, "it still leaves the floor")
	assert_lt(released_apex, held_apex * 0.5, "clearly lower than a held jump")


func test_the_jump_remains_possible_during_coyote_time() -> void:
	var tuning: MovementTuning = _tuning()
	var grounded: Body = Body.new(tuning)
	grounded.step(_intent(Vector3.ZERO, true, true))
	var body: Body = _body_at_top_speed(tuning)

	_leave_the_floor(body, COYOTE_STEPS - 1)
	body.step(_intent(FORWARD, true, true))

	assert_eq(body.motor.state, RunnerMotor.State.RISING, "the jump starts")
	assert_eq(body.velocity.y, grounded.velocity.y, "as strong as a jump from the floor")


func test_the_jump_is_refused_after_coyote_time() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = _body_at_top_speed(tuning)

	_leave_the_floor(body, COYOTE_STEPS)
	var before: float = body.velocity.y
	body.step(_intent(FORWARD, true, true))

	assert_eq(body.motor.state, RunnerMotor.State.FALLING, "no jump")
	assert_lt(body.velocity.y, before, "it keeps falling")


## 0.11 s at 60 steps per second is 6.6 steps: 7 to the nearest step, 6 if truncated.
## The steps are written out on purpose, as above.
func test_a_duration_is_rounded_to_the_nearest_step() -> void:
	var tuning: MovementTuning = _tuning()
	tuning.coyote_time = 0.11
	var at_the_seventh_step: Body = _body_at_top_speed(tuning)
	var at_the_eighth_step: Body = _body_at_top_speed(tuning)

	_leave_the_floor(at_the_seventh_step, 6)
	at_the_seventh_step.step(_intent(FORWARD, true, true))
	_leave_the_floor(at_the_eighth_step, 7)
	at_the_eighth_step.step(_intent(FORWARD, true, true))

	var accepted: RunnerMotor.State = at_the_seventh_step.motor.state
	assert_eq(accepted, RunnerMotor.State.RISING, "accepted at the seventh step in the air")
	var refused: RunnerMotor.State = at_the_eighth_step.motor.state
	assert_eq(refused, RunnerMotor.State.FALLING, "refused at the eighth")


func test_a_jump_requested_just_before_landing_starts_on_landing() -> void:
	var tuning: MovementTuning = _tuning()
	var landing_step: int = _first_grounded_step(tuning)

	var body: Body = _fall_and_request_jump(tuning, landing_step - BUFFER_STEPS)

	assert_eq(body.motor.state, RunnerMotor.State.RISING, "it jumps at the first step on the floor")
	assert_gt(body.velocity.y, 0.0)


func test_a_jump_requested_too_early_before_landing_is_forgotten() -> void:
	var tuning: MovementTuning = _tuning()
	var landing_step: int = _first_grounded_step(tuning)

	var body: Body = _fall_and_request_jump(tuning, landing_step - BUFFER_STEPS - 1)

	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "no jump")
	assert_eq(body.velocity.y, 0.0)


func test_one_press_gives_only_one_jump() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = Body.new(tuning)
	body.step(_intent(Vector3.ZERO, true, true))
	assert_eq(body.motor.state, RunnerMotor.State.RISING, "the first jump starts")

	var previous: float = body.velocity.y
	for i: int in COYOTE_STEPS:
		body.step(_intent(Vector3.ZERO, true, true))
		assert_lt(body.velocity.y, previous, "no second jump at air step %d" % i)
		previous = body.velocity.y


func test_air_control_is_weaker_than_on_the_ground() -> void:
	var tuning: MovementTuning = _tuning()
	var steps: int = 10
	var in_the_air: Body = Body.new(tuning, 1000.0)
	var on_the_ground: Body = Body.new(tuning)

	for i: int in steps:
		in_the_air.step(_intent(FORWARD))
		on_the_ground.step(_intent(FORWARD))

	assert_gt(in_the_air.horizontal_speed(), 0.0, "the air still gives some control")
	assert_lt(in_the_air.horizontal_speed(), on_the_ground.horizontal_speed())
	var expected: float = tuning.air_acceleration * steps * STEP
	assert_almost_eq(in_the_air.horizontal_speed(), expected, TOLERANCE)


func test_the_fall_speed_is_capped() -> void:
	var tuning: MovementTuning = _tuning()
	var body: Body = Body.new(tuning, 100000.0)
	var steps: int = ceili(tuning.max_fall_speed / (tuning.fall_gravity * STEP)) * 4

	var fastest: float = 0.0
	for i: int in steps:
		body.step(_intent(Vector3.ZERO))
		fastest = minf(fastest, body.velocity.y)

	assert_eq(body.motor.state, RunnerMotor.State.FALLING)
	assert_almost_eq(fastest, -tuning.max_fall_speed, TOLERANCE, "it reaches the cap, no more")
	assert_almost_eq(body.velocity.y, -tuning.max_fall_speed, TOLERANCE, "and stays there")


func test_the_same_intents_give_the_same_result() -> void:
	var tuning: MovementTuning = _tuning()
	var first: RunnerMotor = RunnerMotor.new(tuning)
	var second: RunnerMotor = RunnerMotor.new(tuning)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 20261112

	var differences: int = 0
	var states_seen: Dictionary[RunnerMotor.State, bool] = {}
	var on_floor: bool = true
	var observed: Vector3 = Vector3.ZERO
	for i: int in 2000:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = Vector3(random.randf_range(-1, 1), 0, random.randf_range(-1, 1))
		intent.jump_pressed = random.randf() < 0.05
		intent.jump_held = random.randf() < 0.5
		intent.slide_pressed = random.randf() < 0.05
		intent.slide_held = intent.slide_pressed or random.randf() < 0.5
		if random.randf() < 0.03:
			on_floor = not on_floor
		var facts: RunnerFacts = RunnerFacts.new()
		facts.on_floor = on_floor
		facts.velocity = observed
		# Any world: floors at any altitude, tilted any way, with or without headroom.
		facts.altitude = random.randf_range(0.0, 10.0)
		var tilt: Vector3 = Vector3(
			random.randf_range(-0.5, 0.5), 1.0, random.randf_range(-0.5, 0.5)
		)
		facts.floor_normal = tilt.normalized()
		facts.can_stand = random.randf() < 0.9
		var wanted: Vector3 = first.step(intent, facts, STEP)
		var twin: Vector3 = second.step(intent, facts, STEP)
		if wanted != twin or first.state != second.state:
			differences += 1
		states_seen[first.state] = true
		# What a collision would do: the body does not always get the velocity it wanted.
		observed = wanted * random.randf_range(0.5, 1.0)
		if random.randf() < 0.05:
			# What a push would do: a velocity the runner did not ask for.
			observed += Vector3(random.randf_range(-20, 20), 0, random.randf_range(-20, 20))

	assert_eq(differences, 0, "same state and same velocity at every step")
	assert_eq(states_seen.size(), RunnerMotor.State.size(), "the sequence visits every state")


func _tuning() -> MovementTuning:
	var tuning: MovementTuning = MovementTuning.new()
	tuning.top_speed = 9.0
	tuning.ground_acceleration = 30.0
	tuning.ground_deceleration = 45.0
	tuning.air_acceleration = 14.0
	tuning.jump_height = 1.6
	tuning.rise_gravity = 32.0
	tuning.fall_gravity = 44.0
	tuning.jump_release_velocity_ratio = 0.45
	tuning.max_fall_speed = 40.0
	tuning.coyote_time = 0.10
	tuning.jump_buffer_time = 0.12
	tuning.slide_min_speed = 5.0
	tuning.slide_stop_speed = 2.5
	tuning.slide_deceleration = 4.0
	tuning.slide_turn_speed = 1.0
	tuning.roll_fall_height = 4.0
	tuning.roll_window = 0.20
	tuning.roll_duration = 0.5
	tuning.hard_landing_speed_ratio = 0.35
	tuning.hard_landing_duration = 0.35
	tuning.momentum_deceleration = 6.0
	tuning.max_horizontal_speed = 22.0
	return tuning


func _intent(direction: Vector3, jump_pressed: bool = false, jump_held: bool = false) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	intent.jump_pressed = jump_pressed
	intent.jump_held = jump_held
	return intent


func _body_at_top_speed(tuning: MovementTuning) -> Body:
	var body: Body = Body.new(tuning)
	for i: int in SETTLE_STEPS:
		body.step(_intent(FORWARD))
	return body


## The highest point of a jump from the floor whose button is held for `held_steps`.
func _apex_of_a_jump(tuning: MovementTuning, held_steps: int) -> float:
	var body: Body = Body.new(tuning)
	body.step(_intent(Vector3.ZERO, true, true))
	var steps: int = 1
	while not body.on_floor and steps < 10 * SETTLE_STEPS:
		body.step(_intent(Vector3.ZERO, false, steps < held_steps))
		steps += 1
	return body.apex


## The floor ends under a running body, which then spends `air_steps` steps in the air
## without asking for a jump.
func _leave_the_floor(body: Body, air_steps: int) -> void:
	body.has_floor = false
	body.step(_intent(FORWARD))
	for i: int in air_steps:
		body.step(_intent(FORWARD))


## The index of the first step at which a body dropped from 3 m is seen on the floor.
func _first_grounded_step(tuning: MovementTuning) -> int:
	var body: Body = Body.new(tuning, 3.0)
	var steps: int = 0
	while not body.on_floor and steps < 10 * SETTLE_STEPS:
		body.step(_intent(Vector3.ZERO))
		steps += 1
	return steps


## Drops a body from 3 m, with one jump press at `press_step`, and returns it right
## after its first step on the floor.
func _fall_and_request_jump(tuning: MovementTuning, press_step: int) -> Body:
	var body: Body = Body.new(tuning, 3.0)
	var landing_step: int = _first_grounded_step(tuning)
	for i: int in landing_step + 1:
		body.step(_intent(Vector3.ZERO, i == press_step))
	return body
