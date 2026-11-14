class_name Ghost
extends Node3D
## The ghost of a duel: the body of a runner in the opponent's colour and half
## transparent (the Mixamo character, RunnerCharacter, when its files are there; the
## capsule and its visor otherwise), put at every step where the visible body of a
## recorded run was (GhostRun, game/core), showing the animation recorded with it. It has
## no physics body: it touches nothing, nothing touches it, and it has no flow.

## The tuning whose capsule it takes.
@export var tuning: MovementTuning

## The character it takes, if its files are there; a path where there is none keeps the
## capsule. To set before the ghost enters the tree.
var character_model: String = RunnerCharacter.MODEL

var _character: RunnerCharacter = null

@onready var _body: MeshInstance3D = $Body as MeshInstance3D
@onready var _visor: MeshInstance3D = $Visor as MeshInstance3D


func _ready() -> void:
	var capsule: CapsuleMesh = _body.mesh as CapsuleMesh
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	_body.position.y = tuning.capsule_height / 2.0
	_visor.position = Vector3(0.0, tuning.capsule_height * Player.VISOR_HEIGHT_RATIO, 0.0)
	_visor.position.z = -tuning.capsule_radius
	_character = RunnerCharacter.create(character_model, tuning.capsule_height)
	if _character != null:
		add_child(_character)
		_character.wear(capsule.material)
		_body.visible = false
		_visor.visible = false


## Where the visible body was, in the world, how it was turned, and what it showed.
func show_at(frame: Transform3D, animation: RunnerAnimation) -> void:
	global_transform = frame
	reset_physics_interpolation()
	if _character != null:
		_character.play(animation)
