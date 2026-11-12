class_name CameraRig
extends SpringArm3D
## Free third-person camera: the mouse or the right stick turns it around the runner,
## and the spring arm pulls it closer when an obstacle comes between them. The camera
## is not part of the simulation: it follows frame time, and the interpolated position
## of its target.

const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const RELEASE_MOUSE: StringName = &"release_mouse"

## The node the camera turns around.
var target: Node3D
var tuning: MovementTuning:
	set(value):
		tuning = value
		spring_length = tuning.camera_distance


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector(
		LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, tuning.stick_deadzone
	)
	var stick_turn: Vector2 = -stick * tuning.camera_stick_speed * delta
	turn(stick_turn.x, stick_turn.y)
	var feet: Vector3 = target.get_global_transform_interpolated().origin
	global_position = feet + Vector3.UP * tuning.camera_look_height


func _unhandled_input(event: InputEvent) -> void:
	var captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed(RELEASE_MOUSE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.is_pressed() and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and captured:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var mouse_turn: Vector2 = -motion.screen_relative * tuning.camera_mouse_sensitivity
		turn(mouse_turn.x, mouse_turn.y)


## Turns the view, in radians: a positive yaw turns left, a positive pitch looks up.
func turn(yaw: float, pitch: float) -> void:
	rotation.y = wrapf(rotation.y + yaw, -PI, PI)
	var lowest: float = -deg_to_rad(tuning.camera_look_down_limit)
	var highest: float = deg_to_rad(tuning.camera_look_up_limit)
	rotation.x = clampf(rotation.x + pitch, lowest, highest)


## Puts the camera behind the back of a runner that faces `yaw`.
func face(yaw: float) -> void:
	rotation.y = yaw


## The direction the camera looks at, as a rotation around the vertical axis.
func view_yaw() -> float:
	return rotation.y
