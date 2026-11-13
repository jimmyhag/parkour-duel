class_name Player
extends CharacterBody3D
## The runner's body. At every fixed step it asks its intent source for an intent,
## gives it to the motor of game/core with the facts it observes (RunnerFacts), and
## applies what the motor decides: the velocity it wants, and a capsule as low as its
## state says. It decides nothing about the movement itself.

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
	velocity = motor.step(intent, _observe(), delta)
	_fit_capsule()
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
	_set_capsule_height(_wanted_capsule_height())
	(_collider.shape as CapsuleShape3D).radius = tuning.capsule_radius
	(_body.mesh as CapsuleMesh).radius = tuning.capsule_radius
	_visor.position.z = -tuning.capsule_radius


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


## Puts the runner at `spawn`, standing and at rest, facing its -Z axis, with the camera
## in its back.
func teleport(spawn: Transform3D) -> void:
	var yaw: float = spawn.basis.get_euler().y
	global_position = spawn.origin
	velocity = Vector3.ZERO
	motor.reset()
	_fit_capsule()
	_visual.rotation.y = yaw
	camera_rig.face(yaw)
	reset_physics_interpolation()


## What the motor needs to know about the body and the world around it.
func _observe() -> RunnerFacts:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.on_floor = is_on_floor()
	facts.velocity = velocity
	facts.altitude = global_position.y
	if facts.on_floor:
		facts.floor_normal = _normal_of_the_ground_underfoot()
	facts.can_stand = not motor.is_low() or _has_headroom()
	return facts


## The normal of the ground right under the runner's feet, probed straight down as deep
## as the steepest floor can be under a capsule that rests on it; straight up when there
## is no ground there. The contact the body reports is not used: over the edge of a
## block it is tilted like a slope, and the edge of a block is not a slope.
func _normal_of_the_ground_underfoot() -> Vector3:
	var reach: Vector3 = Vector3.UP * tuning.capsule_radius
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + reach, global_position - reach, collision_mask, [get_rid()]
	)
	var ground: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty():
		return Vector3.UP
	var normal: Vector3 = ground["normal"]
	return normal


## Whether the capsule, low as it is, could rise to its standing height where it is.
func _has_headroom() -> bool:
	var rise: float = tuning.capsule_height - tuning.slide_capsule_height
	return not test_move(global_transform, Vector3.UP * rise)


## The height the state of the runner asks for: low in a slide and in a roll.
func _wanted_capsule_height() -> float:
	return tuning.slide_capsule_height if motor.is_low() else tuning.capsule_height


## Gives the capsule the height its state asks for, if it does not have it yet.
func _fit_capsule() -> void:
	var height: float = _wanted_capsule_height()
	if not is_equal_approx((_collider.shape as CapsuleShape3D).height, height):
		_set_capsule_height(height)


## Changes the height of the capsule, the one that collides and the one that is seen,
## without moving its feet.
func _set_capsule_height(height: float) -> void:
	(_collider.shape as CapsuleShape3D).height = height
	_collider.position.y = height / 2.0
	(_body.mesh as CapsuleMesh).height = height
	_body.position.y = height / 2.0
	_visor.position.y = height * VISOR_HEIGHT_RATIO


func _turn_towards_movement(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.is_zero_approx():
		return
	var facing: float = atan2(-horizontal.x, -horizontal.z)
	_visual.rotation.y = rotate_toward(_visual.rotation.y, facing, tuning.turn_speed * delta)
