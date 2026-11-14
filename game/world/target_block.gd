class_name TargetBlock
extends Node3D
## A block of the scenery that a shot can sabotage: a platform that vanishes, a bridge
## that falls away, an obstacle that falls onto the way, a barrier that rises across it.
## It decides nothing: it shows what the state machine of its target (SabotageTarget,
## game/core) says, which the course gives it. Ready, it is highlighted, and brighter
## still under the reticle when it can be shot; during the warning it flashes; otherwise
## it looks like any block. Its body holds the identity of its target, for the shot to
## read it; its zone tells the course which runners are where its object goes or stands.
## Expected children: Body (a StaticBody3D with its CollisionShape3D and MeshInstance3D),
## and Zone (an Area3D whose mask holds the runners' layer and nothing else).

## The physics layers of project.godot: the blocks the runners stand on, and what the
## reticle sees.
const WORLD_LAYER: int = 1
const TARGETS_LAYER: int = 3
const BLOCK_COLOR: Color = Color(0.55, 0.55, 0.58)
const HIGHLIGHT_COLOR: Color = Color(1.0, 0.55, 0.15)
const WARNING_COLOR: Color = Color(1.0, 0.15, 0.1)
## How bright the highlight is, and under the reticle.
const HIGHLIGHT_ENERGY: float = 0.6
const FOCUS_ENERGY: float = 2.5
## How long the warning stays lit, then dark, in s.
const FLASH_SECONDS: float = 0.1

## Its identity in its course: stable, and different from every other target's.
@export var target_id: int = SabotageTarget.NO_TARGET
@export var kind: SabotageTarget.Kind = SabotageTarget.Kind.PLATFORM
## For an object that comes onto the way: where its body goes from its place, in m.
@export var travel: Vector3 = Vector3.ZERO
## Its body is solid in its place: a barrier rests in the ground, and is not.
@export var solid_at_rest: bool = true

## The state machine it shows; the course gives it.
var target: SabotageTarget
## The reticle is on it and it can be shot.
var focused: bool = false

var _material: StandardMaterial3D = StandardMaterial3D.new()
## Where its body stands in its place.
var _home: Vector3
## The time it has shown, in s: what its flashes follow.
var _clock: float = 0.0

@onready var _body: StaticBody3D = $Body as StaticBody3D
@onready var _mesh: MeshInstance3D = $Body/MeshInstance3D as MeshInstance3D
@onready var _zone: Area3D = $Zone as Area3D


func _ready() -> void:
	_home = _body.position
	_body.set_meta(SabotageTarget.META, target_id)
	_mesh.material_override = _material
	follow()
	refresh()


func _process(delta: float) -> void:
	_clock += delta
	refresh(_clock)


## Whether `body` is in its zone.
func holds(body: Node3D) -> bool:
	return _zone.overlaps_body(body)


## Puts its body where its target says: in its place; or, displaced, gone (a platform, a
## bridge) or moved onto the way (an obstacle, a barrier). A body that is there stops a
## shot; it is solid where the runners can stand on it or run into it.
func follow() -> void:
	var displaced: bool = target != null and target.displaced
	var leaves: bool = SabotageTarget.leaves_its_place_when(kind)
	var there: bool = not (displaced and leaves)
	_body.position = _home + travel if displaced and not leaves else _home
	_body.visible = there
	_body.set_collision_layer_value(WORLD_LAYER, there and (displaced or solid_at_rest))
	_body.set_collision_layer_value(TARGETS_LAYER, there)


## Gives its body the look of its state, at `clock` seconds of its flashes.
func refresh(clock: float = 0.0) -> void:
	var state: SabotageTarget.State = SabotageTarget.State.READY
	if target != null:
		state = target.state
	var lit: bool = state == SabotageTarget.State.READY
	var colour: Color = HIGHLIGHT_COLOR
	var energy: float = FOCUS_ENERGY if focused else HIGHLIGHT_ENERGY
	if state == SabotageTarget.State.WARNING:
		lit = fmod(clock, 2.0 * FLASH_SECONDS) < FLASH_SECONDS
		colour = WARNING_COLOR
		energy = FOCUS_ENERGY
	_material.albedo_color = colour if lit else BLOCK_COLOR
	_material.emission_enabled = lit
	_material.emission = colour
	_material.emission_energy_multiplier = energy if lit else 0.0
