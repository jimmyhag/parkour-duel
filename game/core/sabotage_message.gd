class_name SabotageMessage
extends RefCounted
## A dated message of sabotage: which runner shot, which target of its course (its
## identity there), and at which fixed step of the shooter. Only these messages change
## the state of a target; tomorrow they will come from the network in the same form.

## The runner that shot.
var shooter: int
## The identity of the target in its course.
var target: int
## The fixed step of the shooter at which it shot.
var step: int


func _init(shooter_id: int, target_id: int, at_step: int) -> void:
	shooter = shooter_id
	target = target_id
	step = at_step
