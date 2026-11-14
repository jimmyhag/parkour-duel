class_name RoundMessage
extends RefCounted
## A dated message of a round of a duel (RoundState): the start, a checkpoint reached by
## a runner, a runner's finish, or the time limit as it reaches a runner. The step is
## counted from the start of the race (GO); a runner's message carries its style score
## of the moment. Only these messages change the state of a round; tomorrow they will
## come from the network in the same form.

enum Kind { START, CHECKPOINT, FINISH, TIME_LIMIT }

## The runner of a message that is nobody's: the start.
const NOBODY: int = -1

var kind: Kind
var step: int
var runner: int = NOBODY
## The checkpoint reached, for a message of the kind CHECKPOINT.
var checkpoint: int = 0
var style_score: int = 0


func _init(
	message_kind: Kind,
	at_step: int,
	runner_id: int = NOBODY,
	checkpoint_index: int = 0,
	style: int = 0
) -> void:
	kind = message_kind
	step = at_step
	runner = runner_id
	checkpoint = checkpoint_index
	style_score = style


## The race starts, at GO.
static func start(at_step: int) -> RoundMessage:
	return RoundMessage.new(Kind.START, at_step)


static func checkpoint_reached(
	runner_id: int, index: int, at_step: int, style: int
) -> RoundMessage:
	return RoundMessage.new(Kind.CHECKPOINT, at_step, runner_id, index, style)


static func finish(runner_id: int, at_step: int, style: int) -> RoundMessage:
	return RoundMessage.new(Kind.FINISH, at_step, runner_id, 0, style)


static func time_limit(runner_id: int, at_step: int, style: int) -> RoundMessage:
	return RoundMessage.new(Kind.TIME_LIMIT, at_step, runner_id, 0, style)
