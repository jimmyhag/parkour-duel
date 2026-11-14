class_name Ghost
extends Node3D
## The ghost of a duel: the body of a runner in the opponent's colour and half
## transparent (the Mixamo character, RunnerCharacter, when its files are there; the
## capsule and its visor otherwise), put at every step where the visible body of a
## recorded run was (GhostRun, game/core), showing the animation recorded with it; between
## two steps, it is shown in between, as the runners are. It has no physics body: it
## touches nothing, nothing touches it, and it has no flow.

## A move this long from one step to the next is no run but a jump (a run that starts
## again, a respawn), in m: the ghost is shown there at once.
const JUMP: float = 2.0

## The tuning whose capsule it takes.
@export var tuning: MovementTuning

## The character it takes, if its files are there; a path where there is none keeps the
## capsule. To set before the ghost enters the tree.
var character_model: String = RunnerCharacter.MODEL

var _character: RunnerCharacter = null
## The ghost has been put somewhere already.
var _placed: bool = false

@onready var _body: MeshInstance3D = $Body as MeshInstance3D
@onready var _visor: MeshInstance3D = $Visor as MeshInstance3D


func _ready() -> void:
	var capsule: CapsuleMesh = _body.mesh as CapsuleMesh
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	_body.position.y = tuning.capsule_height / 2.0
	_visor.position = Vector3(0.0, tuning.capsule_height * Player.VISOR_HEIGHT_RATIO, 0.0)
	_visor.position.z = -tuning.capsule_radius
	_character = RunnerCharacter.create(character_model, tuning)
	if _character != null:
		add_child(_character)
		_character.wear(capsule.material)
		_body.visible = false
		_visor.visible = false


## Where the visible body was, in the world, how it was turned, and what it showed: shown
## moving there from where it was, unless it jumped.
func show_at(frame: Transform3D, animation: RunnerAnimation) -> void:
	var jumped: bool = not _placed or global_position.distance_to(frame.origin) >= JUMP
	global_transform = frame
	if jumped:
		reset_physics_interpolation()
	_placed = true
	if _character != null:
		_character.play(animation)
