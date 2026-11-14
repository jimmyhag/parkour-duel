class_name ChaseIntentSource
extends IntentSource
## The intents of a runner of the chase: those of its source, without what the chase does
## not have. No aim and no shot: there is no weapon and no target; no return to a
## checkpoint and no restart: a fall is the only way back to the start point.

var _source: IntentSource


func _init(source: IntentSource) -> void:
	_source = source


func next_intent() -> MoveIntent:
	var intent: MoveIntent = _source.next_intent()
	intent.aim_held = false
	intent.aim_direction = Vector3.ZERO
	intent.shoot_pressed = false
	intent.respawn_requested = false
	intent.restart_requested = false
	return intent
