class_name InputIntentSource
extends IntentSource
## The default intent source: reads the actions of the input map and turns the stick
## or the keys into a direction in the world, relative to where the camera looks.

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const JUMP: StringName = &"jump"
const SLIDE: StringName = &"slide"
const RESPAWN: StringName = &"respawn"
const RESTART: StringName = &"restart"

var _camera_rig: CameraRig


func _init(camera_rig: CameraRig) -> void:
	_camera_rig = camera_rig


func next_intent() -> MoveIntent:
	var deadzone: float = _camera_rig.tuning.stick_deadzone
	var stick: Vector2 = Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK, deadzone)
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, _camera_rig.view_yaw())
	intent.jump_pressed = Input.is_action_just_pressed(JUMP)
	intent.jump_held = Input.is_action_pressed(JUMP)
	intent.slide_held = Input.is_action_pressed(SLIDE)
	intent.respawn_requested = Input.is_action_just_pressed(RESPAWN)
	intent.restart_requested = Input.is_action_just_pressed(RESTART)
	return intent
