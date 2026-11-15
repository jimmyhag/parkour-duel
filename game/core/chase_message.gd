class_name ChaseMessage
extends RefCounted
## A dated message of a chase (ChaseState): a round starts, at GO; the cat touches the
## mouse; or the time of the round is up. The step is counted from the start of the
## match, the same for every round. Only these messages change the state of a chase;
## tomorrow they will come from the network in the same form.

enum Kind { START, CONTACT, TIME_UP }

var kind: Kind
var step: int


func _init(message_kind: Kind, at_step: int) -> void:
	kind = message_kind
	step = at_step


## A round starts, at GO.
static func start(at_step: int) -> ChaseMessage:
	return ChaseMessage.new(Kind.START, at_step)


## The bodies of the cat and of the mouse touch.
static func contact(at_step: int) -> ChaseMessage:
	return ChaseMessage.new(Kind.CONTACT, at_step)


## The time of the round is up.
static func time_up(at_step: int) -> ChaseMessage:
	return ChaseMessage.new(Kind.TIME_UP, at_step)
