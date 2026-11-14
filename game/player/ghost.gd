class_name Ghost
extends Node3D
## The ghost of a duel: the capsule of a runner, with its visor, in the opponent's colour
## and half transparent, put at every step where the visible body of a recorded run was
## (GhostRun, game/core). It has no physics body: it touches nothing, nothing touches it,
## and it has no flow.

## The tuning whose capsule it takes.
@export var tuning: MovementTuning

@onready var _body: MeshInstance3D = $Body as MeshInstance3D
@onready var _visor: MeshInstance3D = $Visor as MeshInstance3D


func _ready() -> void:
	var capsule: CapsuleMesh = _body.mesh as CapsuleMesh
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	_body.position.y = tuning.capsule_height / 2.0
	_visor.position = Vector3(0.0, tuning.capsule_height * Player.VISOR_HEIGHT_RATIO, 0.0)
	_visor.position.z = -tuning.capsule_radius


## Where the visible body was, in the world, and how it was turned.
func show_at(frame: Transform3D) -> void:
	global_transform = frame
	reset_physics_interpolation()
