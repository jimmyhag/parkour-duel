class_name ChaseMessage
extends RefCounted
## A dated message of a chase (ChaseState): a round starts, at GO; a gesture of the cat
## catches the mouse (docs/specs/chase-tag.md: who, when, which gesture); or the time of the
## round is up. The step is counted from the start of the match, the same for every round.
## Only these messages change the state of a chase; tomorrow they will come from the
## network in the same form.

enum Kind { START, CATCH, TIME_UP }

var kind: Kind
var step: int
## Of a catch: the player whose gesture caught, and the gesture.
var player: int = ChaseState.NOBODY
var gesture: Tag.Gesture = Tag.Gesture.TOUCH


func _init(message_kind: Kind, at_step: int) -> void:
	kind = message_kind
	step = at_step


## A round starts, at GO.
static func start(at_step: int) -> ChaseMessage:
	return ChaseMessage.new(Kind.START, at_step)


## The gesture `by_gesture` of the player `by_player` catches the other one, while it
## reaches.
static func catch(at_step: int, by_player: int, by_gesture: Tag.Gesture) -> ChaseMessage:
	var message: ChaseMessage = ChaseMessage.new(Kind.CATCH, at_step)
	message.player = by_player
	message.gesture = by_gesture
	return message


## The time of the round is up.
static func time_up(at_step: int) -> ChaseMessage:
	return ChaseMessage.new(Kind.TIME_UP, at_step)
