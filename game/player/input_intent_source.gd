class_name InputIntentSource
extends IntentSource
## The default intent source: reads the actions of the input map and turns the stick
## or the keys into a direction in the world, relative to where the camera looks. While
## the trick button is held, the mouse and the right stick draw on the pad of the trick
## (TrickGesture), brought to its one scale: the mouse at the scale of the sensitivity of
## the camera, and the right stick as a speed, as the tuning says, with how far it is
## pushed; the stick back in its dead zone lets go of the pad. The
## drawing starts afresh at each press of the button; the pad on the screen reads it
## (drawing). It reads the device of its camera rig only (InputDevice): any device alone,
## the keyboard and the mouse or the gamepad in a split screen.

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

## The drawing of the trick: what the pad on the screen shows.
var drawing: TrickGesture

var _camera_rig: CameraRig
## The right stick was out of its dead zone at the last step it drew.
var _stick_pushed: bool = false


func _init(camera_rig: CameraRig) -> void:
	_camera_rig = camera_rig
	drawing = TrickGesture.new(camera_rig.tuning)


func next_intent() -> MoveIntent:
	var deadzone: float = _camera_rig.tuning.stick_deadzone
	var stick: Vector2 = Input.get_vector(
		_own(MOVE_LEFT), _own(MOVE_RIGHT), _own(MOVE_FORWARD), _own(MOVE_BACK), deadzone
	)
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, _camera_rig.view_yaw())
	intent.jump_pressed = Input.is_action_just_pressed(_own(JUMP))
	intent.jump_held = Input.is_action_pressed(_own(JUMP))
	intent.slide_pressed = Input.is_action_just_pressed(_own(SLIDE))
	intent.slide_held = Input.is_action_pressed(_own(SLIDE))
	_draw(intent)
	intent.aim_held = Input.is_action_pressed(_own(AIM))
	intent.shoot_pressed = Input.is_action_just_pressed(_own(SHOOT))
	intent.respawn_requested = Input.is_action_just_pressed(_own(RESPAWN))
	intent.restart_requested = Input.is_action_just_pressed(_own(RESTART))
	return intent


## The action to read for `action` on the device of the camera rig.
func _own(action: StringName) -> StringName:
	return InputDevice.action(action, _camera_rig.device)


## The trick button held or released at this step: the pad moves by what the mouse and
## the right stick did since the last step, and the intent carries what the drawing reads.
func _draw(intent: MoveIntent) -> void:
	var tuning: MovementTuning = _camera_rig.tuning
	var mouse: Vector2 = _camera_rig.take_pad_motion()
	intent.trick_held = Input.is_action_pressed(_own(TRICK))
	intent.trick_released = Input.is_action_just_released(_own(TRICK))
	if Input.is_action_just_pressed(_own(TRICK)):
		drawing.reset()
		_stick_pushed = false
	if not intent.trick_held and not intent.trick_released:
		return
	var delta: float = _camera_rig.get_physics_process_delta_time()
	var stick: Vector2 = Input.get_vector(
		_own(LOOK_LEFT), _own(LOOK_RIGHT), _own(LOOK_UP), _own(LOOK_DOWN), tuning.stick_deadzone
	)
	var radians: float = tuning.camera_mouse_sensitivity * tuning.trick_pad_units_per_radian
	var pad: Vector2 = mouse * radians
	pad += stick * tuning.trick_pad_stick_speed * delta
	var let_go: bool = _stick_pushed and stick.is_zero_approx()
	_stick_pushed = not stick.is_zero_approx()
	drawing.tuning = tuning
	drawing.step(pad, delta, let_go, stick.length())
	# Held, what the drawing reads; released, the trick validated last.
	intent.trick_recipe = drawing.validated_recipe() if intent.trick_released else drawing.recipe()
