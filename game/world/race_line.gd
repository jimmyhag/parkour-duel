class_name RaceLine
extends Area3D
## A start or a finish line. It only reports that a runner crossed it: the course
## decides what it means. Its collision mask must hold the runners' layer and nothing
## else.

signal crossed


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	crossed.emit()
