class_name InputIntentSource
extends IntentSource
## The default intent source: reads the actions of the input map and turns the stick
## or the keys into a direction in the world, relative to where the camera looks. While
## the trick button is held, the mouse and the right stick draw on the pad of the trick
## (TrickGesture), brought to its one scale: a pixel of the mouse, and the right stick as
## a speed, as the tuning says. The drawing starts afresh at each press of the button.

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const JUMP: StringName = &"jump"
const SLIDE: StringName = &"slide"
const TRICK: StringName = &"trick"
const AIM: StringName = &"aim"
const SHOOT: StringName = &"shoot"
const RESPAWN: StringName = &"respawn"
const RESTART: StringName = &"restart"

var _camera_rig: CameraRig
var _gesture: TrickGesture


func _init(camera_rig: CameraRig) -> void:
	_camera_rig = camera_rig
	_gesture = TrickGesture.new(camera_rig.tuning)


func next_intent() -> MoveIntent:
	var deadzone: float = _camera_rig.tuning.stick_deadzone
	var stick: Vector2 = Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK, deadzone)
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, _camera_rig.view_yaw())
	intent.jump_pressed = Input.is_action_just_pressed(JUMP)
	intent.jump_held = Input.is_action_pressed(JUMP)
	intent.slide_pressed = Input.is_action_just_pressed(SLIDE)
	intent.slide_held = Input.is_action_pressed(SLIDE)
	_draw(intent)
	intent.aim_held = Input.is_action_pressed(AIM)
	intent.shoot_pressed = Input.is_action_just_pressed(SHOOT)
	intent.respawn_requested = Input.is_action_just_pressed(RESPAWN)
	intent.restart_requested = Input.is_action_just_pressed(RESTART)
	return intent


## The trick button held or released at this step: the pad moves by what the mouse and
## the right stick did since the last step, and the intent carries what the drawing reads.
func _draw(intent: MoveIntent) -> void:
	var tuning: MovementTuning = _camera_rig.tuning
	var mouse: Vector2 = _camera_rig.take_pad_motion()
	intent.trick_held = Input.is_action_pressed(TRICK)
	intent.trick_released = Input.is_action_just_released(TRICK)
	if Input.is_action_just_pressed(TRICK):
		_gesture.reset()
	if not intent.trick_held and not intent.trick_released:
		return
	var delta: float = _camera_rig.get_physics_process_delta_time()
	var stick: Vector2 = Input.get_vector(
		LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, tuning.stick_deadzone
	)
	var pad: Vector2 = mouse * tuning.trick_pad_mouse_scale
	pad += stick * tuning.trick_pad_stick_speed * delta
	_gesture.tuning = tuning
	_gesture.step(pad, delta)
	intent.trick_recipe = _gesture.recipe()
