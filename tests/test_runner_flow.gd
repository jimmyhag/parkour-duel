extends GutTest
## The moves the runner's motor announces (game/core), counted by the flow as the course
## counts them: at every fixed step the flow follows the motor, and gives it back the
## speed bonus of its gauge. The tuning is the fixed one of MotorBody; the runners go
## along -Z.

const STEPS_PER_SECOND: int = 60
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const JUMP: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
const SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.SLIDE
const PERFECT_SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.PERFECT_SLIDE
const ROLL: RunnerEvent.Kind = RunnerEvent.Kind.ROLL
const MANTLE: RunnerEvent.Kind = RunnerEvent.Kind.MANTLE
const WALL_RUN: RunnerEvent.Kind = RunnerEvent.Kind.WALL_RUN
const WALL_JUMP: RunnerEvent.Kind = RunnerEvent.Kind.WALL_JUMP
const HARD_LANDING: RunnerEvent.Kind = RunnerEvent.Kind.HARD_LANDING
## The chain delay of the fixed tuning (2 s), and half of it, in fixed steps at 60 steps
## per second. Written out on purpose, not computed.
const CHAIN_STEPS: int = 120
const HALF_CHAIN_STEPS: int = 60
## Steps a runner stays on its feet between two moves on the flat: past the window of a
## perfect slide (0.15 s, 9 steps).
const STEPS_ON_FOOT_BETWEEN_MOVES: int = 12
## A wall at the left of a runner going along -Z, close to its side, and tall.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const A_WALL: int = 1
const CLOSE: float = 0.3
const TALL: float = 10.0
## High enough above the floor for a wall run.
const ALONG_A_WALL: float = 3.0
## Where a runner is when it reaches the face of a ledge: half a metre above its floor.
const IN_THE_AIR: float = 0.5
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 1200

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_every_move_started_earns_its_points() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _beside_a_wall()
	assert_eq(flow.gauge, 0.0, "the gauge is empty")
	assert_false(flow.in_combo(), "no combo")

	_follow(body, flow, _run(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a wall run starts")
	_assert_announced(body, WALL_RUN)
	assert_eq(flow.last_move, WALL_RUN, "the flow counted it")
	assert_eq(flow.last_points, 150, "for the points of a wall run, x1")
	assert_almost_eq(flow.gauge, 150.0, TOLERANCE, "the gauge gained them")
	assert_eq(flow.style_score, 150, "and the style score")

	# Every other move, at the step it starts.
	var moves: Dictionary[RunnerEvent.Kind, MotorBody] = {
		JUMP: _jumping(_tuning.top_speed),
		SLIDE: _sliding_on_the_flat(),
		PERFECT_SLIDE: _sliding_at_a_landing(),
		ROLL: _rolling(),
		MANTLE: _mantling(),
		WALL_JUMP: _jumping_off_a_wall(),
	}
	var points: Dictionary[RunnerEvent.Kind, int] = {
		JUMP: 50, SLIDE: 50, PERFECT_SLIDE: 150, ROLL: 100, MANTLE: 100, WALL_JUMP: 150
	}
	for kind: RunnerEvent.Kind in moves:
		var context: String = RunnerEvent.Kind.keys()[kind]
		var mover: MotorBody = moves[kind]
		_assert_announced(mover, kind)
		var counted: FlowState = _flow()
		counted.follow(mover.motor)
		assert_eq(counted.last_move, kind, context + ": counted")
		assert_eq(counted.style_score, points[kind], context + ": for its points")


func test_a_jump_without_run_up_does_not_count() -> void:
	var too_slow: float = _tuning.top_speed * _tuning.flow_jump_min_speed_share - 0.1
	var flow: FlowState = _flow()
	_count(flow, WALL_RUN)
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, too_slow)
	for i: int in HALF_CHAIN_STEPS:
		_follow(body, flow, _run(FORWARD * too_slow / _tuning.top_speed))
	assert_true(flow.in_combo(), "a runner in a combo")
	var chain_left: float = flow.chain_time_left()
	assert_gt(chain_left, 0.0)
	assert_lt(chain_left, _tuning.flow_chain_delay, "half of its delay spent on the ground")

	_follow(body, flow, _jump(FORWARD * too_slow / _tuning.top_speed))

	assert_eq(body.motor.state, RunnerMotor.State.RISING, "it jumps")
	_assert_announced(body, JUMP)
	assert_eq(flow.last_move, WALL_RUN, "the jump is not counted")
	assert_eq(flow.style_score, 150, "it earns nothing")
	assert_eq(flow.chain_time_left(), chain_left, "and does not extend the combo")
	assert_eq(flow.repeat_count, 1, "nor count as a repeat")

	# At half the top speed it counts.
	var counted: FlowState = _flow()
	var fast_enough: MotorBody = _jumping(_tuning.top_speed * _tuning.flow_jump_min_speed_share)
	counted.follow(fast_enough.motor)
	assert_eq(counted.style_score, 50, "a jump at half the top speed counts")


func test_a_wall_jump_does_not_also_count_as_a_jump() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = _beside_a_wall()
	_follow(body, flow, _run(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a runner along a wall")

	_follow(body, flow, _jump(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.RISING, "it jumps")
	_assert_announced(body, WALL_JUMP)
	assert_eq(flow.last_move, WALL_JUMP, "the wall jump is counted")
	assert_eq(flow.moves_counted, 2, "and nothing else")
	assert_eq(flow.style_score, 150 + 150, "a wall run and a wall jump")


func test_alternating_jump_and_slide_on_the_flat_does_not_fill_the_gauge_without_end() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var worth: Array[int] = []
	var moves_when_the_combo_ended: int = -1
	var steps_on_foot: int = 0
	var last_was_a_jump: bool = false
	var steps: int = 0

	# On the flat: run a little, jump, land, run a little, slide with a new press, jump out
	# of the slide, and so on.
	while moves_when_the_combo_ended < 0 and steps < MANY_STEPS * 10:
		var intent: MoveIntent = _run(FORWARD)
		match body.motor.state:
			RunnerMotor.State.SLIDING:
				intent = _jump(FORWARD)
			RunnerMotor.State.GROUNDED:
				steps_on_foot += 1
				if steps_on_foot > STEPS_ON_FOOT_BETWEEN_MOVES:
					intent = _slide(FORWARD) if last_was_a_jump else _jump(FORWARD)
			_:
				steps_on_foot = 0
		var was_in_combo: bool = flow.in_combo()
		_follow(body, flow, intent)
		steps += 1
		for event: RunnerEvent in body.motor.events:
			assert_true(event.kind == JUMP or event.kind == SLIDE, "only jumps and slides")
			last_was_a_jump = event.kind == JUMP
			worth.append(flow.last_points)
		if was_in_combo and not flow.in_combo():
			moves_when_the_combo_ended = worth.size()

	var first_four: Array[int] = [50, 50, 25, 25]
	assert_eq(worth.slice(0, 4), first_four, "the first four moves: all, all, half, half")
	assert_gt(moves_when_the_combo_ended, 8, "then several more moves")
	var after_the_fourth: Array[int] = worth.slice(4, moves_when_the_combo_ended)
	var most: int = after_the_fourth.max()
	assert_eq(most, 0, "from the fifth move on, none is worth anything")
	assert_eq(flow.combos_broken, 0, "and the combo ends, by its delay")
	assert_almost_eq(flow.gauge, 150.0, 1.0, "the gauge kept what the first four gave")


func test_a_held_slide_counts_only_once() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var slides_started: int = 0
	var slides_counted: int = 0

	# The slide pressed once and held down; the jump pressed whenever the runner can.
	for step: int in 5 * STEPS_PER_SECOND:
		var intent: MoveIntent = _run(FORWARD)
		intent.slide_held = true
		intent.slide_pressed = step == 0
		var before: RunnerMotor.State = body.motor.state
		if before == RunnerMotor.State.SLIDING or before == RunnerMotor.State.GROUNDED:
			intent.jump_pressed = true
			intent.jump_held = true
		_follow(body, flow, intent)
		var sliding: bool = body.motor.state == RunnerMotor.State.SLIDING
		slides_started += int(sliding and before != RunnerMotor.State.SLIDING)
		for event: RunnerEvent in body.motor.events:
			slides_counted += int(event.kind == SLIDE or event.kind == PERFECT_SLIDE)

	assert_gt(slides_started, 3, "the runner slid again and again")
	assert_eq(slides_counted, 1, "only the first slide counts")


func test_the_delay_does_not_run_in_the_air() -> void:
	var flow: FlowState = _flow()
	for kind: RunnerEvent.Kind in [JUMP, SLIDE, MANTLE, WALL_RUN]:
		_count(flow, kind)
	assert_eq(flow.multiplier(), 2, "a runner in a combo, at x2")
	var height: float = 100.0
	var body: MotorBody = _dropped(height, _tuning.top_speed)
	var landing_step: int = _landing_step(height, _tuning.top_speed)
	assert_gt(landing_step, CHAIN_STEPS, "that falls for longer than the delay")

	for i: int in landing_step + 1:
		var intent: MoveIntent = _run(FORWARD)
		# In the air, the slide pressed just before the floor, and pushes that change.
		intent.direction = FORWARD.rotated(Vector3.UP, 0.3 * sin(i))
		intent.slide_pressed = i == landing_step - 1
		intent.slide_held = intent.slide_pressed
		_follow(body, flow, intent)
		if i < landing_step:
			assert_true(flow.in_combo(), "the combo waits in the air, step %d" % i)

	assert_eq(body.motor.state, RunnerMotor.State.ROLLING, "it lands in a roll")
	assert_eq(flow.last_move, ROLL, "the roll is counted")
	assert_eq(flow.last_points, 100 * 2, "in the combo, at x2")
	assert_true(flow.in_combo(), "the combo goes on")


func test_a_hard_landing_breaks_the_combo_and_costs_a_tier() -> void:
	var flow: FlowState = _flow()
	for kind: RunnerEvent.Kind in [JUMP, SLIDE, MANTLE, WALL_RUN, WALL_RUN]:
		_count(flow, kind)
	flow.gauge = 1.5 * _tuning.flow_tier_value
	assert_eq(flow.multiplier(), 2, "a runner in a combo, at x2")
	var body: MotorBody = _dropped(_tuning.roll_fall_height * 1.5, _tuning.top_speed)

	while not body.on_floor:
		_follow(body, flow, _run(FORWARD))
	_follow(body, flow, _run(FORWARD))

	assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, "a hard landing")
	_assert_announced(body, HARD_LANDING)
	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_eq(flow.multiplier(), 1, "the multiplier is back to x1")
	assert_eq(flow.repeat_count, 0, "the repetition to zero")
	var lost: float = 1.5 * _tuning.flow_tier_value - flow.gauge
	assert_almost_eq(lost, _tuning.flow_tier_value, TOLERANCE, "and the gauge lost one tier")


func test_every_tier_raises_the_top_speed() -> void:
	var flow: FlowState = _flow()
	flow.gauge = 2.5 * _tuning.flow_tier_value
	assert_eq(flow.tier(), 2, "a runner at tier 2")
	var boosted: float = _tuning.top_speed * 1.10
	var body: MotorBody = MotorBody.new(_tuning)

	var fastest: float = 0.0
	for i: int in 2 * STEPS_PER_SECOND:
		_follow(body, flow, _run(FORWARD))
		fastest = maxf(fastest, body.horizontal_speed())

	assert_eq(flow.tier(), 2, "still at tier 2")
	assert_almost_eq(body.horizontal_speed(), boosted, TOLERANCE, "the top speed plus 10 %")
	assert_almost_eq(fastest, boosted, TOLERANCE, "and never more")

	# Never above the absolute cap.
	var capped: MovementTuning = MotorBody.fixed_tuning()
	capped.max_horizontal_speed = _tuning.top_speed * 1.05
	var at_the_cap: FlowState = FlowState.new(capped, STEPS_PER_SECOND)
	at_the_cap.gauge = 2.5 * _tuning.flow_tier_value
	var held: MotorBody = MotorBody.new(capped)
	for i: int in 2 * STEPS_PER_SECOND:
		_follow(held, at_the_cap, _run(FORWARD))
		assert_lte(held.horizontal_speed(), capped.max_horizontal_speed + TOLERANCE, "step %d" % i)
	var cap: float = capped.max_horizontal_speed
	assert_almost_eq(held.horizontal_speed(), cap, TOLERANCE, "at the cap")


func _flow() -> FlowState:
	return FlowState.new(_tuning, STEPS_PER_SECOND)


## One step of the body, followed by the flow, as the course does it.
func _follow(body: MotorBody, flow: FlowState, intent: MoveIntent) -> void:
	body.step(intent)
	flow.follow(body.motor)


## One step at which the motor announced `kind`, the runner in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, _tuning.top_speed, false)


## The motor of `body` announced `kind` at the step it just played, and nothing else.
func _assert_announced(body: MotorBody, kind: RunnerEvent.Kind) -> void:
	var context: String = RunnerEvent.Kind.keys()[kind]
	assert_eq(body.motor.events.size(), 1, context + ": one message")
	if body.motor.events.size() != 1:
		return
	var event: RunnerEvent = body.motor.events[0]
	assert_eq(event.kind, kind, context + ": of its kind")
	assert_eq(event.step, body.motor.steps, context + ": dated by the step it started at")


func _run(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


func _jump(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.jump_pressed = true
	intent.jump_held = true
	return intent


func _slide(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = _run(direction)
	intent.slide_pressed = true
	intent.slide_held = true
	return intent


## A body in the air beside a wall at its left, at the top speed.
func _beside_a_wall() -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, ALONG_A_WALL)
	body.velocity = FORWARD * _tuning.top_speed
	body.set_wall(A_WALL, LEFT_WALL, CLOSE, TALL)
	return body


## A body on the floor that just jumped, running at `speed`.
func _jumping(speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, speed)
	body.step(_jump(FORWARD * speed / _tuning.top_speed))
	return body


## A body that just started to slide, on a floor it stands on for long.
func _sliding_on_the_flat() -> MotorBody:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	for i: int in STEPS_PER_SECOND:
		body.step(_run(FORWARD))
	body.step(_slide(FORWARD))
	return body


## A body that just landed from a small fall with the slide pressed as it touched the
## floor.
func _sliding_at_a_landing() -> MotorBody:
	var height: float = _tuning.roll_fall_height / 4.0
	var body: MotorBody = _dropped(height, _tuning.top_speed)
	var landing_step: int = _landing_step(height, _tuning.top_speed)
	for i: int in landing_step:
		body.step(_run(FORWARD))
	body.step(_slide(FORWARD))
	return body


## A body that just landed from a high fall in a roll.
func _rolling() -> MotorBody:
	var height: float = _tuning.roll_fall_height * 1.5
	var body: MotorBody = _dropped(height, _tuning.top_speed)
	var landing_step: int = _landing_step(height, _tuning.top_speed)
	for i: int in landing_step:
		body.step(_slide(FORWARD) if i == landing_step - 1 else _run(FORWARD))
	body.step(_run(FORWARD))
	return body


## A body that just started to climb a ledge.
func _mantling() -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, IN_THE_AIR)
	body.put_ledge_ahead(_tuning.mantle_min_height * 1.5)
	body.step(_run(FORWARD))
	return body


## A body that ran along a wall and just jumped off it.
func _jumping_off_a_wall() -> MotorBody:
	var body: MotorBody = _beside_a_wall()
	body.step(_run(FORWARD))
	body.step(_jump(FORWARD))
	return body


## A body in the air, `height` above the floor, going forward at `speed`.
func _dropped(height: float, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, height)
	body.velocity = FORWARD * speed
	return body


## The index of the first step at which a body dropped from `height` is seen on the
## floor by its motor.
func _landing_step(height: float, speed: float) -> int:
	var body: MotorBody = _dropped(height, speed)
	var steps: int = 0
	while not body.on_floor and steps < MANY_STEPS:
		body.step(_run(FORWARD))
		steps += 1
	return steps
