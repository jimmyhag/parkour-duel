class_name RunnerEvent
extends RefCounted
## A dated message from the runner's motor: a move it started, or a hard landing, at one
## of its fixed steps. The flow counts from these messages only; tomorrow the opponent's
## will come from the network in the same form.

enum Kind {
	JUMP,
	SLIDE,
	PERFECT_SLIDE,
	ROLL,
	MANTLE,
	WALL_RUN,
	WALL_JUMP,
	HARD_LANDING,
}

var kind: Kind
## The fixed step of the motor at which it happened.
var step: int


func _init(event_kind: Kind, at_step: int) -> void:
	kind = event_kind
	step = at_step
