extends TrickTest
## The risk of the aerial tricks of the runner's motor (game/core): a turn asks for more
## height than a jump on the flat gives, so that a trick is never a loop without risk,
## and the perfect landings do not raise the speed without end. The tests of the risk
## weigh the tuning of the project, the one the player plays with.

## Fixed steps in one minute.
const MINUTE: int = 3600
## How many steps after the take-off a riskless player presses the trick, in turn: from
## with the jump to the most a turn and a perfect window allowed before the amendment.
const PRESS_OFFSETS: int = 10
const PERFECT_LANDINGS: int = 10


## What a minute of jumps earned.
class Minute:
	var style: int = 0
	var tricks_paid: int = 0
	var crashes: int = 0
	var jumps: int = 0


func test_a_flip_does_not_fit_in_a_jump_on_the_flat() -> void:
	var tuning: MovementTuning = _project_tuning()
	for push: Vector3 in [FORWARD, BACK, Vector3.LEFT, Vector3.ZERO]:
		var context: String = "push %s" % push
		var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)

		var trick: AirTrick = _jump_with_a_trick(body, null, 0.0, push)

		assert_not_null(trick, context + ": a trick started with the jump")
		var kinds: Array = body.motor.events.map(func(event: RunnerEvent) -> int: return event.kind)
		assert_eq(kinds, [RunnerEvent.Kind.CRASH], context + ": the ground before the end: a crash")
		assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, context)


func test_a_drop_high_enough_allows_a_flip() -> void:
	var tuning: MovementTuning = _project_tuning()
	var drop: float = _drop_for_a_turn(tuning)
	assert_gt(drop, 0.0, "a turn asks for a drop")
	var fall: float = tuning.jump_height + drop
	assert_lt(fall, tuning.roll_fall_height, "lower than what asks for a roll")
	for push: Vector3 in [FORWARD, BACK, Vector3.LEFT, Vector3.ZERO]:
		var context: String = "push %s, drop %.2f m" % [push, drop]
		var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)

		var trick: AirTrick = _jump_with_a_trick(body, null, drop, push)

		var kinds: Array = body.motor.events.map(func(event: RunnerEvent) -> int: return event.kind)
		assert_eq(kinds, [TRICK], context + ": the trick is posed")
		assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, context + ": standing")
		if trick != null:
			assert_eq(trick.turns, 1, context + ": one turn")


func test_a_riskless_loop_on_the_flat_earns_nothing() -> void:
	var tuning: MovementTuning = _project_tuning()
	var plain: Minute = _hop_for_a_minute(tuning, false)
	var tricking: Minute = _hop_for_a_minute(tuning, true)
	assert_gt(plain.jumps, 60, "a runner that jumps again and again on the flat")
	assert_gt(tricking.jumps, 30, "and one that adds a trick to every jump")

	assert_eq(tricking.tricks_paid, 0, "no trick earned anything")
	assert_gt(tricking.crashes, 30, "they all crashed")
	assert_lt(tricking.style, plain.style, "less style than jumping without a trick")
	assert_lt(tricking.style, tuning.flow_points_per_ammo, "not even one ammunition")


func test_perfect_landings_in_a_row_do_not_raise_the_speed_without_end() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var drop: float = _drop_for_a_turn(_tuning)
	var gain: float = _tuning.trick_perfect_speed_gain
	var perfect: int = 0
	var fastest: float = 0.0

	# Jump after jump, from block to lower block, a trick with each jump.
	for landing: int in PERFECT_LANDINGS:
		var top: float = body.motor.top_speed()
		var trick: AirTrick = _jump_with_a_trick(body, flow, drop, FORWARD)
		perfect += int(trick != null and trick.perfect)
		fastest = maxf(fastest, body.horizontal_speed())
		var limit: float = maxf(top, body.motor.top_speed()) + gain + TOLERANCE
		assert_lte(
			body.horizontal_speed(),
			limit,
			"landing %d: within the top speed and the gain" % landing
		)

	assert_eq(perfect, PERFECT_LANDINGS, "ten perfect landings")
	assert_gt(fastest, _tuning.top_speed, "the gain is felt")
	assert_lt(fastest, _tuning.max_horizontal_speed - 5.0, "far from the absolute cap")


## A minute of a runner on the flat that jumps whenever it stands, holding the jump to
## its top; with `tricks`, it presses the trick at every jump, with it or up to nine
## steps after it, in turn.
func _hop_for_a_minute(tuning: MovementTuning, tricks: bool) -> Minute:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var flow: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	var minute: Minute = Minute.new()
	var since_take_off: int = -1
	var press_after: int = 0
	for step: int in MINUTE:
		var intent: MoveIntent = _push(FORWARD)
		var state: RunnerMotor.State = body.motor.state
		if state == RunnerMotor.State.GROUNDED:
			intent.jump_pressed = true
			intent.jump_held = true
			since_take_off = 0
			press_after = minute.jumps % PRESS_OFFSETS
		elif state == RunnerMotor.State.RISING:
			intent.jump_held = true
			since_take_off += 1
		else:
			since_take_off += 1
		if tricks and since_take_off == press_after:
			intent.trick_pressed = true
			intent.trick_held = true
		_follow(body, flow, intent)
		for event: RunnerEvent in body.motor.events:
			minute.tricks_paid += int(event.kind == TRICK)
			minute.crashes += int(event.kind == RunnerEvent.Kind.CRASH)
			minute.jumps += int(event.kind == RunnerEvent.Kind.JUMP)
	minute.style = flow.style_score
	return minute
