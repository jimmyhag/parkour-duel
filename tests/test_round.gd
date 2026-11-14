extends GutTest
## The round of a duel (game/core): its clock, which counts the countdown down and then
## the time limit, and its state, fed by dated messages only (RoundMessage): the start,
## the checkpoints reached, the finishes and the time limit. Runner 0 is the player, 1
## its opponent. The tuning is the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const PLAYER: int = 0
const OPPONENT: int = 1
## The values of the fixed tuning in fixed steps at 60 per second, written out on purpose:
## one number of the countdown, and the time limit of a round.
const DIGIT_STEPS: int = 60
const LIMIT_STEPS: int = 10800
const RUNNING: RoundState.Phase = RoundState.Phase.RUNNING
const FINISHED: RoundState.Phase = RoundState.Phase.FINISHED
const FALL_LIMIT: float = -8.0
const ALTITUDE: float = 0.0

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_countdown_precedes_the_race() -> void:
	var clock: RoundClock = RoundClock.new(_tuning, STEPS_PER_SECOND)
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	assert_eq(round_state.phase, RoundState.Phase.COUNTDOWN, "a round starts with its countdown")
	assert_eq(clock.countdown(), 3, "3 first")
	var shown: Array[int] = [clock.countdown()]
	var go_at: int = -1
	var moved_before_go: bool = false

	for step: int in 4 * DIGIT_STEPS + 10:
		moved_before_go = moved_before_go or (go_at < 0 and round_state.runners_may_move())
		if clock.tick() == RoundClock.Event.GO:
			assert_eq(go_at, -1, "GO once")
			go_at = clock.steps
			round_state.receive(RoundMessage.start(clock.race_steps()))
		shown.append(clock.countdown())

	assert_false(moved_before_go, "nobody may move before GO")
	assert_eq(go_at, 3 * DIGIT_STEPS, "GO after three numbers of one second each")
	assert_eq(shown.count(3), DIGIT_STEPS, "3 for a second")
	assert_eq(shown.count(2), DIGIT_STEPS, "2 for a second")
	assert_eq(shown.count(1), DIGIT_STEPS, "1 for a second")
	assert_eq(shown.count(0), DIGIT_STEPS, "GO for a second")
	assert_eq(shown.slice(0, 4 * DIGIT_STEPS), _countdown_in_order(), "in that order")
	assert_eq(shown[shown.size() - 1], RoundClock.NO_COUNTDOWN, "then nothing")
	assert_eq(round_state.phase, RUNNING, "the race is on")
	assert_true(round_state.runners_may_move(), "both runners may move at GO")
	assert_eq(round_state.start_step, 0, "the start, dated at the step of GO")
	# Both lanes start their timer on the message of the start: at the same step.
	var races: Array[RaceState] = [RaceState.new(STEPS_PER_SECOND), RaceState.new(STEPS_PER_SECOND)]
	for race: RaceState in races:
		race.cross_start_line()
	for step: int in 30:
		for race: RaceState in races:
			race.tick()
	assert_eq(races[0].elapsed_steps, races[1].elapsed_steps, "the two timers agree")


func test_the_first_to_finish_wins() -> void:
	var round_state: RoundState = _running_round()
	round_state.receive(RoundMessage.checkpoint_reached(OPPONENT, 1, 300, 100))
	round_state.receive(RoundMessage.finish(PLAYER, 1800, 500))
	assert_eq(round_state.phase, FINISHED, "the round is over at the first finish")
	assert_eq(round_state.winner, PLAYER, "the player wins")
	assert_eq(round_state.finish_step(PLAYER), 1800, "in its time")
	assert_false(round_state.has_finished(OPPONENT), "the opponent did not finish")

	round_state.receive(RoundMessage.finish(OPPONENT, 1801, 9000))

	assert_eq(round_state.winner, PLAYER, "a finish one step later changes nothing")
	assert_false(round_state.has_finished(OPPONENT), "it does not count")

	var other: RoundState = _running_round()
	other.receive(RoundMessage.finish(OPPONENT, 1700, 0))
	assert_eq(other.winner, OPPONENT, "the opponent wins the same way")


func test_a_finish_at_the_same_step_is_decided_by_style() -> void:
	var round_state: RoundState = _running_round()
	round_state.receive(RoundMessage.finish(OPPONENT, 1800, 700))
	round_state.receive(RoundMessage.finish(PLAYER, 1800, 900))
	assert_eq(round_state.winner, PLAYER, "the higher style score wins")
	assert_true(round_state.has_finished(OPPONENT), "both finished")

	var reversed: RoundState = _running_round()
	reversed.receive(RoundMessage.finish(PLAYER, 1800, 900))
	reversed.receive(RoundMessage.finish(OPPONENT, 1800, 1200))
	assert_eq(reversed.winner, OPPONENT, "whatever the order of the messages")

	var even: RoundState = _running_round()
	even.receive(RoundMessage.finish(PLAYER, 1800, 900))
	even.receive(RoundMessage.finish(OPPONENT, 1800, 900))
	assert_eq(even.phase, FINISHED)
	assert_eq(even.winner, RoundState.NO_WINNER, "same score: a draw")


func test_the_time_limit_is_decided_by_checkpoint() -> void:
	var clock: RoundClock = RoundClock.new(_tuning, STEPS_PER_SECOND)
	var time_up_at: int = -1
	for step: int in 3 * DIGIT_STEPS + LIMIT_STEPS + 5:
		if clock.tick() == RoundClock.Event.TIME_UP:
			time_up_at = clock.race_steps()
	assert_eq(time_up_at, LIMIT_STEPS, "the time is up three minutes after GO")

	var farther: RoundState = _running_round()
	farther.receive(RoundMessage.checkpoint_reached(PLAYER, 4, 2000, 3000))
	farther.receive(RoundMessage.checkpoint_reached(OPPONENT, 5, 2500, 100))
	_time_is_up(farther, 3000, 100)
	assert_eq(farther.phase, FINISHED, "the round is over")
	assert_eq(farther.winner, OPPONENT, "the farthest checkpoint wins, whatever the style")

	var same_checkpoint: RoundState = _running_round()
	same_checkpoint.receive(RoundMessage.checkpoint_reached(PLAYER, 5, 2000, 0))
	same_checkpoint.receive(RoundMessage.checkpoint_reached(OPPONENT, 5, 1000, 0))
	_time_is_up(same_checkpoint, 800, 600)
	assert_eq(same_checkpoint.winner, PLAYER, "then the style score")

	var even: RoundState = _running_round()
	even.receive(RoundMessage.checkpoint_reached(PLAYER, 5, 2000, 0))
	even.receive(RoundMessage.checkpoint_reached(OPPONENT, 5, 1000, 0))
	_time_is_up(even, 600, 600)
	assert_eq(even.winner, RoundState.NO_WINNER, "then a draw")


func test_no_restart_in_a_duel() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	race.restartable = false
	race.cross_start_line()
	race.reach_checkpoint(3)
	for step: int in 100:
		race.tick()
	var restart: MoveIntent = MoveIntent.new()
	restart.restart_requested = true

	var order: RaceState.RespawnOrder = race.apply_respawn_rule(ALTITUDE, FALL_LIMIT, restart)

	assert_eq(order, RaceState.RespawnOrder.NONE, "nothing happens")
	assert_eq(race.phase, RaceState.Phase.RUNNING, "the race goes on")
	assert_eq(race.elapsed_steps, 100, "the timer is not touched")
	assert_eq(race.last_checkpoint, 3, "nor the checkpoint")
	var respawn: MoveIntent = MoveIntent.new()
	respawn.respawn_requested = true
	var back: RaceState.RespawnOrder = race.apply_respawn_rule(ALTITUDE, FALL_LIMIT, respawn)
	assert_eq(back, RaceState.RespawnOrder.RESPAWN, "the return to the checkpoint stays")


func test_the_round_knows_the_gap_at_the_last_common_checkpoint() -> void:
	var round_state: RoundState = _running_round()
	assert_false(round_state.has_gap(PLAYER), "no common checkpoint yet")
	round_state.receive(RoundMessage.checkpoint_reached(OPPONENT, 1, 300, 0))
	assert_false(round_state.has_gap(PLAYER), "the player has not reached it")
	# The timers then show 5.00 s and 6.23 s.
	round_state.receive(RoundMessage.checkpoint_reached(PLAYER, 1, 374, 0))
	assert_eq(round_state.gap_centiseconds(PLAYER), 123, "the player 1.23 s after the opponent")
	assert_eq(round_state.gap_centiseconds(OPPONENT), -123, "the opponent 1.23 s before")
	round_state.receive(RoundMessage.checkpoint_reached(PLAYER, 2, 500, 0))
	assert_eq(round_state.gap_centiseconds(PLAYER), 123, "the last common one is still the first")
	round_state.receive(RoundMessage.checkpoint_reached(OPPONENT, 2, 548, 0))
	assert_eq(round_state.gap_centiseconds(PLAYER), -80, "then the second")


func _running_round() -> RoundState:
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	return round_state


## The time is up: one message per runner, with its style score.
func _time_is_up(round_state: RoundState, player_style: int, opponent_style: int) -> void:
	round_state.receive(RoundMessage.time_limit(PLAYER, LIMIT_STEPS, player_style))
	round_state.receive(RoundMessage.time_limit(OPPONENT, LIMIT_STEPS, opponent_style))


func _countdown_in_order() -> Array[int]:
	var order: Array[int] = []
	for number: int in [3, 2, 1, 0]:
		for step: int in DIGIT_STEPS:
			order.append(number)
	return order
