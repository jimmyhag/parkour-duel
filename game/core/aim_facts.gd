class_name AimFacts
extends RefCounted
## What the player layer observed under the reticle at one fixed step: the target that
## the first thing on the line of the reticle belongs to (NO_TARGET for anything else, or
## for nothing), and how far it is from the runner's eyes, in m. The shot is decided from
## these facts only.

var target: int = SabotageTarget.NO_TARGET
var distance: float = INF


func _init(aimed_target: int = SabotageTarget.NO_TARGET, aimed_distance: float = INF) -> void:
	target = aimed_target
	distance = aimed_distance
