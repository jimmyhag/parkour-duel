class_name Player
extends CharacterBody3D
## The runner's body. At every fixed step it asks its intent source for an intent,
## gives it to the motor of game/core with what it observes (floor, real velocity), and
## applies the velocity the motor wants. It decides nothing about the movement itself.

## Emitted at the end of every fixed step, with the intent the runner just followed.
signal stepped(intent: MoveIntent)

const RELOAD_TUNING: StringName = &"reload_tuning"
## Where the visor sits on the capsule, as a share of its height.
const VISOR_HEIGHT_RATIO: float = 0.8

## The tuning resource; its capsule and camera values replace the ones of the scene.
@export var tuning: MovementTuning

var motor: RunnerMotor
## Replaceable: the inputs by default, a sequence written in advance in the tests.
var intent_source: IntentSource

@onready var camera_rig: CameraRig = $CameraRig as CameraRig
@onready var _collider: CollisionShape3D = $CollisionShape3D as CollisionShape3D
@onready var _visual: Node3D = $Visual as Node3D
@onready var _body: MeshInstance3D = $Visual/Body as MeshInstance3D
@onready var _visor: MeshInstance3D = $Visual/Visor as MeshInstance3D


func _ready() -> void:
	motor = RunnerMotor.new(tuning)
	intent_source = InputIntentSource.new(camera_rig)
	camera_rig.target = self
	apply_tuning(tuning)


func _physics_process(delta: float) -> void:
	var intent: MoveIntent = intent_source.next_intent()
	velocity = motor.step(intent, is_on_floor(), velocity, delta)
	move_and_slide()
	_turn_towards_movement(delta)
	stepped.emit(intent)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(RELOAD_TUNING):
		reload_tuning()


## Makes the runner, its capsule and its camera use this tuning from now on.
func apply_tuning(new_tuning: MovementTuning) -> void:
	tuning = new_tuning
	motor.tuning = tuning
	camera_rig.tuning = tuning
	var half_height: float = tuning.capsule_height / 2.0
	var shape: CapsuleShape3D = _collider.shape as CapsuleShape3D
	shape.height = tuning.capsule_height
	shape.radius = tuning.capsule_radius
	_collider.position.y = half_height
	var mesh: CapsuleMesh = _body.mesh as CapsuleMesh
	mesh.height = tuning.capsule_height
	mesh.radius = tuning.capsule_radius
	_body.position.y = half_height
	var visor_height: float = tuning.capsule_height * VISOR_HEIGHT_RATIO
	_visor.position = Vector3(0.0, visor_height, -tuning.capsule_radius)


## Reads the tuning file again, so that a value changed on disk applies without
## restarting the game.
func reload_tuning() -> void:
	var path: String = tuning.resource_path
	if path.is_empty():
		return
	var fresh: MovementTuning = (
		ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as MovementTuning
	)
	if fresh != null:
		apply_tuning(fresh)


## Puts the runner at `spawn`, at rest, facing its -Z axis, with the camera in its back.
func teleport(spawn: Transform3D) -> void:
	var yaw: float = spawn.basis.get_euler().y
	global_position = spawn.origin
	velocity = Vector3.ZERO
	motor.reset()
	_visual.rotation.y = yaw
	camera_rig.face(yaw)
	reset_physics_interpolation()


func _turn_towards_movement(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.is_zero_approx():
		return
	var facing: float = atan2(-horizontal.x, -horizontal.z)
	_visual.rotation.y = rotate_toward(_visual.rotation.y, facing, tuning.turn_speed * delta)
