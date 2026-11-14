class_name RoundState
extends RefCounted
## The state of one round of a duel between runner 0 (the player) and runner 1 (its
## opponent): the countdown, the race, then its end and its winner. It sees nothing but
## dated messages (RoundMessage): the start, the checkpoints reached, the finishes and
## the time limit. The first runner over the finish line wins; two at the same step are
## told apart by their style score, and the same score is a draw. At the time limit, if
## nobody finished, the farthest checkpoint wins, then the style score, then a draw.

enum Phase { COUNTDOWN, RUNNING, FINISHED }

const RUNNERS: int = 2
## The winner of a draw, or of a round not over.
const NO_WINNER: int = -1
## A step not reached yet: a finish, the start or the end of the round.
const NOT_YET: int = -1
const CENTISECONDS_PER_SECOND: int = 100


## What the messages said of one runner.
class Record:
	## The farthest checkpoint reached, and the step at which each one was reached.
	var checkpoint: int = 0
	var reached: Dictionary[int, int] = {}
	var finish_step: int = NOT_YET
	## The style score its last message carried.
	var style_score: int = 0


var phase: Phase = Phase.COUNTDOWN
var start_step: int = NOT_YET
var end_step: int = NOT_YET
var winner: int = NO_WINNER
var records: Array[Record] = []

var _steps_per_second: int


func _init(steps_per_second: int) -> void:
	_steps_per_second = steps_per_second
	for runner: int in RUNNERS:
		records.append(Record.new())


## A dated message: the state changes as it says, if it still may.
func receive(message: RoundMessage) -> void:
	match message.kind:
		RoundMessage.Kind.START:
			if phase == Phase.COUNTDOWN:
				phase = Phase.RUNNING
				start_step = message.step
		RoundMessage.Kind.CHECKPOINT:
			if phase == Phase.RUNNING:
				_reach(message)
		RoundMessage.Kind.FINISH, RoundMessage.Kind.TIME_LIMIT:
			if _is_the_end(message):
				_end(message)


## The runners may move while the race is on, and only then.
func runners_may_move() -> bool:
	return phase == Phase.RUNNING


func has_finished(runner: int) -> bool:
	return records[runner].finish_step != NOT_YET


## The step at which `runner` crossed the finish line; NOT_YET if it did not.
func finish_step(runner: int) -> int:
	return records[runner].finish_step


## Whether the two runners have a checkpoint in common past the start.
func has_gap(runner: int) -> bool:
	return _last_common_checkpoint(runner) > 0


## How long after its opponent `runner` reached their last common checkpoint, in
## hundredths of a second as the two timers showed them then (negative: before it); 0
## without one.
func gap_centiseconds(runner: int) -> int:
	var common: int = _last_common_checkpoint(runner)
	if common <= 0:
		return 0
	var other: Record = records[_opponent(runner)]
	return centiseconds(records[runner].reached[common]) - centiseconds(other.reached[common])


## A number of fixed steps as hundredths of a second, rounded down.
func centiseconds(steps: int) -> int:
	@warning_ignore("integer_division")
	return steps * CENTISECONDS_PER_SECOND / _steps_per_second


## A finish or the time limit ends the round while it runs; once it is over, only the
## message of another runner at the very step it ended still counts: they arrived
## together.
func _is_the_end(message: RoundMessage) -> bool:
	if phase == Phase.RUNNING:
		return true
	return phase == Phase.FINISHED and message.step == end_step


func _reach(message: RoundMessage) -> void:
	var record: Record = records[message.runner]
	record.style_score = message.style_score
	if message.checkpoint > record.checkpoint:
		record.checkpoint = message.checkpoint
		record.reached[message.checkpoint] = message.step


func _end(message: RoundMessage) -> void:
	var record: Record = records[message.runner]
	record.style_score = message.style_score
	if message.kind == RoundMessage.Kind.FINISH:
		record.finish_step = message.step
	phase = Phase.FINISHED
	end_step = message.step
	winner = _judge()


## Who wins, from what the messages said: the first to finish; at the time limit, the
## farthest; then the style score; then nobody.
func _judge() -> int:
	var first: Record = records[0]
	var second: Record = records[1]
	if has_finished(0) != has_finished(1):
		return 0 if has_finished(0) else 1
	if has_finished(0) and first.finish_step != second.finish_step:
		return 0 if first.finish_step < second.finish_step else 1
	if not has_finished(0) and first.checkpoint != second.checkpoint:
		return 0 if first.checkpoint > second.checkpoint else 1
	if first.style_score != second.style_score:
		return 0 if first.style_score > second.style_score else 1
	return NO_WINNER


func _last_common_checkpoint(runner: int) -> int:
	var mine: Record = records[runner]
	var theirs: Record = records[_opponent(runner)]
	var common: int = 0
	for index: int in mine.reached:
		if theirs.reached.has(index):
			common = maxi(common, index)
	return common


func _opponent(runner: int) -> int:
	return RUNNERS - 1 - runner
