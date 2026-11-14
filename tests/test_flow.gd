extends GutTest
## The flow (game/core): the gauge the moves fill, the combo that chains them and its
## multiplier, the ammunition and the style score, counted from a list of dated messages
## alone, without physics. The tuning is the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const JUMP: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
const SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.SLIDE
const PERFECT_SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.PERFECT_SLIDE
const ROLL: RunnerEvent.Kind = RunnerEvent.Kind.ROLL
const MANTLE: RunnerEvent.Kind = RunnerEvent.Kind.MANTLE
const WALL_RUN: RunnerEvent.Kind = RunnerEvent.Kind.WALL_RUN
const WALL_JUMP: RunnerEvent.Kind = RunnerEvent.Kind.WALL_JUMP
const HARD_LANDING: RunnerEvent.Kind = RunnerEvent.Kind.HARD_LANDING
## Moves that never follow themselves in this order.
const VARIED: Array[RunnerEvent.Kind] = [JUMP, SLIDE, ROLL, MANTLE, WALL_RUN, WALL_JUMP]
## The chain delay of the fixed tuning (2 s), and its stop duration (1 s), in fixed steps
## at 60 steps per second. Written out on purpose, not computed.
const CHAIN_STEPS: int = 120
const STOP_STEPS: int = 60
## The horizontal speed of a runner at the top speed of the fixed tuning, in m/s.
const RUNNING: float = 9.0
const TOLERANCE: float = 0.001

var _tuning: MovementTuning
## The fixed step of the messages written by the test.
var _step: int = 0


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()
	_step = 0


func test_the_same_move_repeated_in_a_row_is_worth_less_and_less() -> void:
	var flow: FlowState = _flow()
	_move(flow, ROLL)
	assert_true(flow.in_combo(), "a runner in a combo")

	var worth: Array[int] = []
	for i: int in 4:
		_move(flow, JUMP)
		worth.append(flow.last_points)

	assert_eq(worth[0], 50, "the first jump is worth all its points")
	assert_eq(worth[1], 25, "the second half of them")
	assert_eq(worth[2], 0, "the third nothing")
	assert_eq(worth[3], 0, "nor the ones after")
	assert_eq(flow.style_score, 100 + 50 + 25, "the style score adds what they are worth")
	assert_eq(flow.repeated_move, JUMP, "the jump is the repeated move")
	assert_eq(flow.repeat_count, 4, "four times in a row")


func test_another_move_resets_the_repetition() -> void:
	var flow: FlowState = _flow()
	_move(flow, JUMP)
	_move(flow, JUMP)
	assert_eq(flow.last_points, 25, "two jumps in a row")

	_move(flow, SLIDE)
	assert_eq(flow.last_points, 50, "the slide is worth all its points")
	_move(flow, JUMP)

	assert_eq(flow.last_points, 50, "and the jump after it too")
	assert_eq(flow.repeat_count, 1, "the jump counts from one again")


func test_a_repeated_move_worth_nothing_still_extends_the_combo() -> void:
	var flow: FlowState = _flow()
	for i: int in 3:
		_move(flow, JUMP)
	assert_eq(flow.last_points, 0, "the jump is worth nothing any more")
	_wait(flow, CHAIN_STEPS - 1)
	assert_true(flow.in_combo(), "the combo is still on, at the last step of its delay")
	assert_eq(flow.multiplier(), 1)

	_move(flow, JUMP)

	assert_eq(flow.last_points, 0, "the jump is still worth nothing")
	assert_true(flow.in_combo(), "the combo goes on")
	assert_eq(flow.multiplier(), 2, "the jump was the fourth move of the combo")
	_wait(flow, CHAIN_STEPS - 1)
	assert_true(flow.in_combo(), "its delay started again at that jump")
	_move(flow, SLIDE)
	assert_eq(flow.last_points, 50 * 2, "the next move is counted at the new multiplier")


func test_the_multiplier_rises_every_four_moves() -> void:
	var flow: FlowState = _flow()
	assert_eq(flow.multiplier(), 1, "x1 before any move")
	var moves: Array[RunnerEvent.Kind] = [
		JUMP, SLIDE, ROLL, MANTLE, WALL_RUN, WALL_JUMP, PERFECT_SLIDE, JUMP
	]
	var points: Array[int] = [50, 50, 100, 100, 150, 150, 150, 50]

	for index: int in moves.size():
		_wait(flow, STOP_STEPS)
		_move(flow, moves[index])
		var expected: int = 1 if index < 4 else 2
		assert_eq(
			flow.last_points, points[index] * expected, "move %d counted x%d" % [index, expected]
		)

	assert_eq(flow.multiplier(), 3, "eight moves: the next one will be x3")
	assert_eq(flow.style_score, (50 + 50 + 100 + 100) + 2 * (150 + 150 + 150 + 50))


func test_the_multiplier_does_not_go_above_its_maximum() -> void:
	var flow: FlowState = _flow()
	for index: int in 12:
		_move(flow, VARIED[index % VARIED.size()])
	assert_eq(flow.multiplier(), 4, "a runner at the highest multiplier")

	for index: int in 4:
		var kind: RunnerEvent.Kind = VARIED[index % VARIED.size()]
		_move(flow, kind)
		assert_eq(flow.last_points, _points(kind) * 4, "move %d counted x4" % index)
		assert_eq(flow.multiplier(), 4, "and the multiplier stays at x4")


func test_the_combo_ends_without_penalty_after_the_delay_on_the_ground() -> void:
	var flow: FlowState = _flow()
	for index: int in 4:
		_move(flow, VARIED[index])
	var gauge: float = flow.gauge
	var score: int = flow.style_score
	_wait(flow, CHAIN_STEPS - 1)
	assert_true(flow.in_combo(), "still in the combo one step before the end of the delay")
	assert_eq(flow.multiplier(), 2)

	_wait(flow, 1)

	assert_false(flow.in_combo(), "the combo is over")
	assert_eq(flow.multiplier(), 1, "the multiplier is back to x1")
	assert_almost_eq(flow.gauge, gauge, TOLERANCE, "the gauge lost nothing")
	assert_eq(flow.style_score, score, "nor the style score")
	assert_eq(flow.combos_broken, 0, "the combo ended, it was not broken")
	_move(flow, WALL_JUMP)
	assert_eq(flow.last_points, 150, "the next move starts a new combo, at x1")


func test_a_hard_landing_does_not_take_the_gauge_below_zero() -> void:
	var flow: FlowState = _flow()
	flow.gauge = _tuning.flow_tier_value * 0.4
	assert_lt(flow.gauge, _tuning.flow_tier_value, "a gauge under the value of one tier")

	_move(flow, HARD_LANDING, 0.0, true)

	assert_eq(flow.gauge, 0.0, "the gauge is at zero")


func test_stopping_breaks_the_combo() -> void:
	var flow: FlowState = _flow()
	for index: int in 4:
		_move(flow, VARIED[index])
	_move(flow, ROLL)
	_wait(flow, STOP_STEPS - 1, true, 0.5)
	assert_true(flow.in_combo(), "one step before the end of the stop, the combo is on")
	assert_eq(flow.combos_broken, 0)

	_wait(flow, 1, true, 0.5)

	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1, "by an error")
	assert_eq(flow.multiplier(), 1, "the multiplier is back to x1")
	assert_eq(flow.repeat_count, 0, "and the repetition to zero")
	_move(flow, ROLL)
	assert_eq(flow.last_points, 100, "the roll is worth all its points again")

	# At the speed of a stop, but not under it, or under it in the air: no stop.
	for case: int in 2:
		var other: FlowState = _flow()
		_move(other, WALL_RUN)
		var on_foot: bool = case == 0
		var speed: float = _tuning.flow_stop_speed if on_foot else 0.5
		_wait(other, CHAIN_STEPS - 1, on_foot, speed)
		var context: String = "at the speed of a stop" if on_foot else "slow in the air"
		assert_true(other.in_combo(), context + ": the combo goes on")
		assert_eq(other.combos_broken, 0, context + ": nothing broken")


func test_a_fall_off_the_course_empties_the_gauge_and_keeps_the_rest() -> void:
	var flow: FlowState = _flow()
	flow.gauge = _tuning.flow_tier_value - 10.0
	_move(flow, WALL_RUN)
	_move(flow, WALL_RUN)
	assert_eq(flow.ammo, 1, "a runner with ammunition")
	assert_gt(flow.gauge, 0.0, "gauge")
	assert_eq(flow.style_score, 150 + 75, "and a style score")
	assert_true(flow.in_combo())

	flow.respawn()

	assert_eq(flow.gauge, 0.0, "the gauge is at zero")
	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_eq(flow.ammo, 1, "the ammunition stays")
	assert_eq(flow.style_score, 150 + 75, "and the style score")
	_move(flow, WALL_RUN)
	assert_eq(flow.last_points, 150, "the repetition is back to zero")


func test_the_gauge_does_not_drop_during_a_combo() -> void:
	var flow: FlowState = _flow()
	flow.gauge = _tuning.flow_tier_value / 2.0 - 150.0
	_move(flow, WALL_RUN)
	var half_a_tier: float = _tuning.flow_tier_value / 2.0
	assert_almost_eq(flow.gauge, half_a_tier, TOLERANCE, "a gauge at half a tier, in a combo")

	# On the ground and in the air in turn, at changing speeds, within the delay.
	for i: int in CHAIN_STEPS - 1:
		_wait(flow, 1, i % 20 < 10, RUNNING * (1.0 + 0.5 * sin(i)))
		assert_almost_eq(flow.gauge, half_a_tier, TOLERANCE, "unchanged at step %d" % i)

	assert_true(flow.in_combo(), "the combo is still on")
	_wait(flow, CHAIN_STEPS)
	assert_lt(flow.gauge, half_a_tier, "once the combo is over, it drops")


func test_the_gauge_drops_slowly_out_of_a_combo() -> void:
	var flow: FlowState = _flow()
	flow.gauge = flow.max_gauge()
	assert_almost_eq(flow.gauge, 3000.0, TOLERANCE, "a full gauge")
	assert_false(flow.in_combo(), "out of a combo")

	_wait(flow, 5 * STEPS_PER_SECOND, true)
	assert_almost_eq(flow.gauge, 2500.0, 0.01, "five seconds on the ground: half a tier lost")
	_wait(flow, 5 * STEPS_PER_SECOND, false)

	assert_almost_eq(flow.gauge, 2000.0, 0.01, "ten seconds, on the ground or not: one tier")
	_wait(flow, 30 * STEPS_PER_SECOND)
	assert_eq(flow.gauge, 0.0, "and never below zero")


func test_the_gauge_does_not_go_above_its_maximum() -> void:
	var flow: FlowState = _flow()
	flow.gauge = flow.max_gauge() - 10.0
	_move(flow, ROLL)
	assert_eq(flow.gauge, flow.max_gauge(), "a full gauge, in a combo")
	var score: int = flow.style_score

	_move(flow, WALL_RUN)

	assert_eq(flow.gauge, flow.max_gauge(), "the gauge stays full")
	assert_eq(flow.style_score, score + 150, "the style score gains the points of the move")


func test_the_speed_bonus_follows_the_gauge_down() -> void:
	var flow: FlowState = _flow()
	flow.gauge = flow.max_gauge()
	assert_eq(flow.tier(), 3, "a runner at tier 3")
	assert_almost_eq(flow.speed_bonus(), 0.15, TOLERANCE, "with the bonus of tier 3")
	assert_false(flow.in_combo(), "without a combo")

	_wait(flow, 1)

	assert_lt(flow.gauge, 3000.0, "the gauge went under tier 3")
	assert_eq(flow.tier(), 2)
	assert_almost_eq(flow.speed_bonus(), 0.10, TOLERANCE, "the bonus is the one of tier 2")
	_wait(flow, 10 * STEPS_PER_SECOND)
	assert_eq(flow.tier(), 1)
	assert_almost_eq(flow.speed_bonus(), 0.05, TOLERANCE, "then of tier 1")
	_wait(flow, 10 * STEPS_PER_SECOND)
	assert_eq(flow.tier(), 0)
	assert_eq(flow.speed_bonus(), 0.0, "then none")


func test_crossing_a_tier_upwards_gives_ammunition() -> void:
	var flow: FlowState = _flow()
	flow.gauge = _tuning.flow_tier_value - 40.0
	assert_eq(flow.ammo, 0, "a runner without ammunition, just under the first tier")

	_move(flow, JUMP)

	assert_eq(flow.tier(), 1, "the jump crossed the first tier")
	assert_eq(flow.ammo, 1, "it has one ammunition")
	assert_eq(flow.tiers_crossed, 1)
	assert_eq(flow.last_tier_crossed, 1)
	_move(flow, SLIDE)
	assert_eq(flow.ammo, 1, "a move that crosses no tier gives none")
	# Back under the tier, then over it again.
	_wait(flow, CHAIN_STEPS + 2 * STEPS_PER_SECOND)
	assert_eq(flow.tier(), 0, "under the first tier again")
	_move(flow, WALL_RUN)
	assert_eq(flow.tier(), 1, "and over it again")
	assert_eq(flow.ammo, 2, "crossing it again gives another one")


func test_ammunition_does_not_go_above_its_maximum() -> void:
	var flow: FlowState = _flow()
	flow.ammo = _tuning.flow_max_ammo
	flow.gauge = _tuning.flow_tier_value - 40.0

	_move(flow, JUMP)

	assert_eq(flow.tier(), 1, "the gauge crossed a tier upwards")
	assert_eq(flow.ammo, 3, "the runner still has the most it may hold")


func test_at_the_finish_the_flow_freezes() -> void:
	var flow: FlowState = _flow()
	for index: int in 5:
		_move(flow, VARIED[index])
	assert_true(flow.in_combo(), "a runner in a combo")
	var gauge: float = flow.gauge
	var score: int = flow.style_score

	flow.finish()
	for index: int in VARIED.size():
		_move(flow, VARIED[index])
		_wait(flow, STEPS_PER_SECOND)
	_move(flow, HARD_LANDING, 0.0, true)
	_wait(flow, 20 * STEPS_PER_SECOND, true, 0.0)
	flow.respawn()

	assert_true(flow.frozen, "the flow is frozen")
	assert_eq(flow.style_score, score, "its style score no longer changes")
	assert_almost_eq(flow.gauge, gauge, TOLERANCE, "nor its gauge")
	assert_eq(flow.best_style_score, score, "the run is the best of the session")


func test_the_best_style_score_of_the_session_is_kept() -> void:
	var flow: FlowState = _flow()
	_move(flow, WALL_RUN)
	_move(flow, WALL_JUMP)
	flow.finish()
	assert_eq(flow.best_style_score, 300, "a first run")
	flow.restart()
	_move(flow, WALL_RUN)

	flow.finish()

	assert_eq(flow.style_score, 150, "a second run with a lower score")
	assert_eq(flow.best_style_score, 300, "the best style score is the one of the first")
	flow.restart()
	for index: int in 5:
		_move(flow, VARIED[index])
	flow.finish()
	assert_eq(flow.best_style_score, 600, "a higher one replaces it")


func _flow() -> FlowState:
	return FlowState.new(_tuning, STEPS_PER_SECOND)


## One fixed step at which the motor announced `kind`, the runner going at `speed`, on
## its feet on the ground or not (a move starts off them, a hard landing on them).
func _move(
	flow: FlowState, kind: RunnerEvent.Kind, speed: float = RUNNING, on_foot: bool = false
) -> void:
	_step += 1
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, _step)]
	flow.step(events, speed, on_foot)


## Fixed steps at which the motor announced nothing.
func _wait(flow: FlowState, steps: int, on_foot: bool = true, speed: float = RUNNING) -> void:
	var none: Array[RunnerEvent] = []
	for i: int in steps:
		_step += 1
		flow.step(none, speed, on_foot)


func _points(kind: RunnerEvent.Kind) -> int:
	match kind:
		JUMP, SLIDE:
			return 50
		ROLL, MANTLE:
			return 100
	return 150
