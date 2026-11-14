class_name ChaseState
extends RefCounted
## The state of a chase between player 0 and player 1: a match of rounds, in each of which
## one player is the cat and the other the mouse. It sees nothing but dated messages
## (ChaseMessage): the start of a round at GO, the contact of the cat with the mouse, the
## end of the time of the round. A contact before the time is up wins the round for the
## cat; the time up wins it for the mouse. The roles swap at the start of every round
## after the first, where player 0 is the cat; the first to win the rounds of the tuning
## wins the match. It holds the flow of each player, which starts from zero with every
## round and freezes at its end.

enum Phase { COUNTDOWN, RUNNING, ROUND_OVER, MATCH_OVER }
enum Role { CAT, MOUSE }

const PLAYERS: int = 2
## The winner of a round or of a match not over.
const NOBODY: int = -1
## A step not reached yet: the start or the end of a round.
const NOT_YET: int = -1
const CENTISECONDS_PER_SECOND: int = 100

var phase: Phase = Phase.COUNTDOWN
## The cat of the round under way, or of the last one played.
var cat: int = 0
## The rounds started so far.
var round_number: int = 0
## The rounds each player won.
var score: Array[int] = []
var start_step: int = NOT_YET
var end_step: int = NOT_YET
## Who won the last round over, and in which role; NOBODY while a round is on.
var round_winner: int = NOBODY
var round_winner_role: Role = Role.CAT
## Who won the match; NOBODY while it is not over.
var winner: int = NOBODY
## The flow of each player.
var flows: Array[FlowState] = []
var tuning: MovementTuning

var _steps_per_second: int


func _init(chase_tuning: MovementTuning, steps_per_second: int) -> void:
	tuning = chase_tuning
	_steps_per_second = steps_per_second
	for player: int in PLAYERS:
		score.append(0)
		flows.append(FlowState.new(tuning, steps_per_second))


## A dated message: the state changes as it says, if it still may.
func receive(message: ChaseMessage) -> void:
	match message.kind:
		ChaseMessage.Kind.START:
			if phase == Phase.COUNTDOWN or phase == Phase.ROUND_OVER:
				_start(message.step)
		ChaseMessage.Kind.CONTACT:
			if phase == Phase.RUNNING and message.step < _time_up_step():
				_end(cat, Role.CAT, message.step)
		ChaseMessage.Kind.TIME_UP:
			if phase == Phase.RUNNING:
				_end(mouse(), Role.MOUSE, message.step)


## The players may move while a round is on, and only then.
func players_may_move() -> bool:
	return phase == Phase.RUNNING


func mouse() -> int:
	return PLAYERS - 1 - cat


## The role of `player` in the round under way; between two rounds, in the coming one.
func role(player: int) -> Role:
	var its_cat: int = mouse() if phase == Phase.ROUND_OVER else cat
	return Role.CAT if player == its_cat else Role.MOUSE


## The time left in the round at the match step `at_step`, in s: the whole time of a
## round before it starts and between two rounds, the time left at its end once the match
## is over.
func seconds_left(at_step: int) -> float:
	return _steps_left(at_step) / float(_steps_per_second)


## The time left in the round at the match step `at_step`, in hundredths of a second,
## rounded down.
func centiseconds_left(at_step: int) -> int:
	@warning_ignore("integer_division")
	return _steps_left(at_step) * CENTISECONDS_PER_SECOND / _steps_per_second


## The fixed steps a round lasts.
func round_steps() -> int:
	return roundi(tuning.chase_round_time * _steps_per_second)


func _steps_left(at_step: int) -> int:
	match phase:
		Phase.RUNNING:
			return clampi(_time_up_step() - at_step, 0, round_steps())
		Phase.MATCH_OVER:
			return clampi(_time_up_step() - end_step, 0, round_steps())
	return round_steps()


func _time_up_step() -> int:
	return start_step + round_steps()


## A round starts: the roles swap after the first, and the flows start from zero.
func _start(at_step: int) -> void:
	if phase == Phase.ROUND_OVER:
		cat = mouse()
	phase = Phase.RUNNING
	round_number += 1
	start_step = at_step
	end_step = NOT_YET
	round_winner = NOBODY
	for flow: FlowState in flows:
		flow.restart()


## The round is won by `player` in the role `role`: the match is too if it has the rounds
## of the tuning. The flows freeze.
func _end(player: int, player_role: Role, at_step: int) -> void:
	score[player] += 1
	round_winner = player
	round_winner_role = player_role
	end_step = at_step
	phase = Phase.ROUND_OVER
	if score[player] >= tuning.chase_rounds_to_win:
		phase = Phase.MATCH_OVER
		winner = player
	for flow: FlowState in flows:
		flow.finish()
