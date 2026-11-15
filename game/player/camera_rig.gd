class_name CameraRig
extends SpringArm3D
## Free third-person camera: the mouse or the right stick turns it around the runner,
## and the spring arm pulls it closer when an obstacle comes between them: the arm
## carries a sphere, so the camera stays at a distance from a wall instead of sinking
## into it. While the runner aims, the camera goes over its right shoulder and narrows
## its field of view, so that the centre of the screen, where the reticle is, shows what
## the runner aims at. While the trick button is held, the mouse and the right stick draw
## the trick instead: the camera keeps still, and the motion of the mouse is kept for the
## drawing (take_pad_motion). As the body of the runner goes down to the ground (a dive,
## lying after it) and back up, the camera goes down and up with it, smoothed
## (docs/specs/chase-tag-polish.md, decision 4). The camera is not part of the simulation:
## it follows frame time, and the interpolated position of its target. It obeys its device only
## (InputDevice): any device alone; in a split screen, the mouse and the keyboard, or the
## right stick of the gamepad, and the camera of the gamepad's player ignores the mouse.

const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const RELEASE_MOUSE: StringName = &"release_mouse"
const TRICK: StringName = &"trick"

## The node the camera turns around.
var target: Node3D
## The device whose inputs turn the camera and draw the trick.
var device: InputDevice.Kind = InputDevice.Kind.ANY
## The runner aims: the camera goes over its shoulder.
var aiming: bool = false
## How low the body of the runner is, from 0 on its feet to 1 lying (RunnerAnimation).
var lowered: float = 0.0
var tuning: MovementTuning:
	set(value):
		tuning = value
		spring_length = tuning.camera_distance
		(shape as SphereShape3D).radius = tuning.camera_collision_radius
		_look_height = look_height(lowered, tuning)

## How far the camera is over the shoulder: 0 behind the back, 1 over the shoulder.
var _aim_blend: float = 0.0
## The field of view of the camera when the runner does not aim, in degrees.
var _usual_fov: float = 0.0
## The motion of the mouse while the trick button was held, not taken yet, in pixels.
var _pad_motion: Vector2 = Vector2.ZERO
## How high above the feet of the runner the camera looks from, in m.
var _look_height: float = 0.0

@onready var _camera: Camera3D = $Camera3D as Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_usual_fov = _camera.fov


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector(
		_own(LOOK_LEFT), _own(LOOK_RIGHT), _own(LOOK_UP), _own(LOOK_DOWN), tuning.stick_deadzone
	)
	if not is_drawing():
		var stick_turn: Vector2 = -stick * tuning.camera_stick_speed * delta
		turn(stick_turn.x, stick_turn.y)
	var blend_step: float = 1.0
	if tuning.aim_camera_blend_time > 0.0:
		blend_step = delta / tuning.aim_camera_blend_time
	_aim_blend = move_toward(_aim_blend, 1.0 if aiming else 0.0, blend_step)
	var wanted: float = look_height(lowered, tuning)
	_look_height = followed_height(_look_height, wanted, delta, tuning.tag_camera_follow)
	var feet: Vector3 = target.get_global_transform_interpolated().origin
	# The right of the view stays horizontal: looking up or down turns around it.
	var shoulder: Vector3 = global_basis.x * tuning.aim_camera_offset * _aim_blend
	global_position = feet + Vector3.UP * _look_height + shoulder
	_camera.fov = lerpf(_usual_fov, tuning.aim_camera_fov, _aim_blend)


func _unhandled_input(event: InputEvent) -> void:
	if device == InputDevice.Kind.GAMEPAD:
		return
	var captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed(RELEASE_MOUSE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.is_pressed() and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion:
		move_with_the_mouse(event as InputEventMouseMotion, captured)


## What a motion of the mouse does: while the trick button is held, it draws (kept for the
## drawing, captured or not); otherwise, if the mouse is `captured`, it turns the camera.
func move_with_the_mouse(motion: InputEventMouseMotion, captured: bool) -> void:
	if is_drawing():
		_pad_motion += motion.screen_relative
	elif captured:
		var mouse_turn: Vector2 = -motion.screen_relative * tuning.camera_mouse_sensitivity
		turn(mouse_turn.x, mouse_turn.y)


## The trick button is held: the mouse and the right stick draw the trick.
func is_drawing() -> bool:
	return Input.is_action_pressed(_own(TRICK))


## The motion of the mouse kept for the drawing since it was last taken, in pixels of the
## screen (x to the right, y down); nothing is kept of it afterwards.
func take_pad_motion() -> Vector2:
	var motion: Vector2 = _pad_motion
	_pad_motion = Vector2.ZERO
	return motion


## Turns the view, in radians: a positive yaw turns left, a positive pitch looks up.
func turn(yaw: float, pitch: float) -> void:
	rotation.y = wrapf(rotation.y + yaw, -PI, PI)
	var lowest: float = -deg_to_rad(tuning.camera_look_down_limit)
	var highest: float = deg_to_rad(tuning.camera_look_up_limit)
	rotation.x = clampf(rotation.x + pitch, lowest, highest)


## Puts the camera behind the back of a runner that faces `yaw`.
func face(yaw: float) -> void:
	rotation.y = yaw


## How high above the feet of a runner whose body is `lowered` (0 on its feet, 1 lying) the
## camera should look from, in m.
static func look_height(lowered_by: float, with: MovementTuning) -> float:
	return lerpf(with.camera_look_height, with.tag_camera_down_height, lowered_by)


## The height the camera looks from `delta` s after it was `height`, on its way to `wanted`:
## smoothed, closer by the same share in the same time, so that it never jumps (at once
## without a time to follow, `follow`).
static func followed_height(height: float, wanted: float, delta: float, follow: float) -> float:
	if follow <= 0.0:
		return wanted
	return lerpf(height, wanted, 1.0 - exp(-delta / follow))


## The camera at the end of the arm: the eye the reticle is the centre of.
func camera() -> Camera3D:
	return _camera


## The direction the camera looks at, as a rotation around the vertical axis.
func view_yaw() -> float:
	return rotation.y


## The action to read for `action` on the device of the rig.
func _own(action: StringName) -> StringName:
	return InputDevice.action(action, device)
