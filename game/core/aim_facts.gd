class_name AimFacts
extends RefCounted
## What the player layer observed under the reticle at one fixed step: the target that
## the first thing on the line of the reticle belongs to (NO_TARGET for anything else, or
## for nothing), the lane that target belongs to (by the runner that runs it), and how
## far it is from the runner's eyes, in m. The shot is decided from these facts only.

var target: int = SabotageTarget.NO_TARGET
var distance: float = INF
var lane: int = 0


func _init(
	aimed_target: int = SabotageTarget.NO_TARGET, aimed_distance: float = INF, aimed_lane: int = 0
) -> void:
	target = aimed_target
	distance = aimed_distance
	lane = aimed_lane
