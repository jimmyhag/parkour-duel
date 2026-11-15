class_name ChaseIntentSource
extends IntentSource
## The intents of a runner of the chase: those of its source, without what the chase does
## not have. No aim and no shot: there is no weapon and no target; their buttons are the
## gestures of the cat (docs/specs/chase-tag.md): the shot pressed is the touch, the aim
## pressed (not held: a new press each time) is the dive. No return to a checkpoint and no
## restart: a fall is the only way back to the start point.

var _source: IntentSource
## The aim was held at the step before.
var _aim_was_held: bool = false


func _init(source: IntentSource) -> void:
	_source = source


func next_intent() -> MoveIntent:
	var intent: MoveIntent = _source.next_intent()
	intent.touch_pressed = intent.touch_pressed or intent.shoot_pressed
	intent.dive_pressed = intent.dive_pressed or (intent.aim_held and not _aim_was_held)
	_aim_was_held = intent.aim_held
	intent.aim_held = false
	intent.aim_direction = Vector3.ZERO
	intent.shoot_pressed = false
	intent.respawn_requested = false
	intent.restart_requested = false
	return intent
