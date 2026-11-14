class_name CameraRig
extends SpringArm3D
## Free third-person camera: the mouse or the right stick turns it around the runner,
## and the spring arm pulls it closer when an obstacle comes between them: the arm
## carries a sphere, so the camera stays at a distance from a wall instead of sinking
## into it. While the runner aims, the camera goes over its right shoulder and narrows
## its field of view, so that the centre of the screen, where the reticle is, shows what
## the runner aims at. While the trick button is held, the mouse and the right stick draw
## the trick instead: the camera keeps still, and the motion of the mouse is kept for the
## drawing (take_pad_motion). The camera is not part of the simulation: it follows frame
## time, and the interpolated position of its target.

const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const RELEASE_MOUSE: StringName = &"release_mouse"
const TRICK: StringName = &"trick"

## The node the camera turns around.
var target: Node3D
## The runner aims: the camera goes over its shoulder.
var aiming: bool = false
var tuning: MovementTuning:
	set(value):
		tuning = value
		spring_length = tuning.camera_distance
		(shape as SphereShape3D).radius = tuning.camera_collision_radius

## How far the camera is over the shoulder: 0 behind the back, 1 over the shoulder.
var _aim_blend: float = 0.0
## The field of view of the camera when the runner does not aim, in degrees.
var _usual_fov: float = 0.0
## The motion of the mouse while the trick button was held, not taken yet, in pixels.
var _pad_motion: Vector2 = Vector2.ZERO

@onready var _camera: Camera3D = $Camera3D as Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_usual_fov = _camera.fov


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector(
		LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, tuning.stick_deadzone
	)
	if not is_drawing():
		var stick_turn: Vector2 = -stick * tuning.camera_stick_speed * delta
		turn(stick_turn.x, stick_turn.y)
	var blend_step: float = 1.0
	if tuning.aim_camera_blend_time > 0.0:
		blend_step = delta / tuning.aim_camera_blend_time
	_aim_blend = move_toward(_aim_blend, 1.0 if aiming else 0.0, blend_step)
	var feet: Vector3 = target.get_global_transform_interpolated().origin
	# The right of the view stays horizontal: looking up or down turns around it.
	var shoulder: Vector3 = global_basis.x * tuning.aim_camera_offset * _aim_blend
	global_position = feet + Vector3.UP * tuning.camera_look_height + shoulder
	_camera.fov = lerpf(_usual_fov, tuning.aim_camera_fov, _aim_blend)


func _unhandled_input(event: InputEvent) -> void:
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
	return Input.is_action_pressed(TRICK)


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


## The camera at the end of the arm: the eye the reticle is the centre of.
func camera() -> Camera3D:
	return _camera


## The direction the camera looks at, as a rotation around the vertical axis.
func view_yaw() -> float:
	return rotation.y
