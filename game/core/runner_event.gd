class_name RunnerEvent
extends RefCounted
## A dated message from the runner's motor: a move it started, a trick its landing paid,
## a hard landing or a crash, at one of its fixed steps. The flow counts from these
## messages only; tomorrow the opponent's will come from the network in the same form.

enum Kind {
	JUMP,
	SLIDE,
	PERFECT_SLIDE,
	ROLL,
	MANTLE,
	WALL_RUN,
	WALL_JUMP,
	HARD_LANDING,
	TRICK,
	CRASH,
}

var kind: Kind
## The fixed step of the motor at which it happened.
var step: int
## The trick paid, for a message of the kind TRICK; null otherwise.
var trick: AirTrick


func _init(event_kind: Kind, at_step: int, paid_trick: AirTrick = null) -> void:
	kind = event_kind
	step = at_step
	trick = paid_trick
