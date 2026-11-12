class_name Checkpoint
extends Area3D
## A place of a course where a fallen runner comes back. Its origin is the respawn
## point, on the ground; its -Z axis points towards what comes next. It only reports
## that a runner went through: the course decides what it means. Its collision mask
## must hold the runners' layer and nothing else.

signal reached(index: int)

## Its rank along the course: 0 on the start platform, then one more per section.
@export var index: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	reached.emit(index)
