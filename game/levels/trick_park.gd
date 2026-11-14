class_name TrickPark
extends Node3D
## The Trick Park: a wide flat ground with blocks of 1, 2, 3, 5 and 8 m to jump from, two
## walls face to face and a wall to run along, to try the tricks at every height. No
## timer, no target, no opponent: it owns the flow of its runner and shows it, and brings
## the runner back to its start point when it falls off or asks for it (the rule of
## RaceState). The menu action asks to leave it. It reads no input of the game itself.
## Expected children: Spawn, Blocks, Walls, Player, Hud/FlowHud, Hud/DebugOverlay and
## FlowSounds.

## The menu action was pressed: whoever started the park may close it.
signal menu_requested

const MENU: StringName = &"menu"

## The altitude under which a runner has fallen off the park.
@export var fall_limit: float = 0.0

var flow: FlowState
var player: Player

## Holds the rule that brings the runner back; there is no race.
var _rule: RaceState

@onready var _spawn: Node3D = $Spawn as Node3D
@onready var _flow_hud: FlowHud = $Hud/FlowHud as FlowHud
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay
@onready var _flow_sounds: FlowSounds = $FlowSounds as FlowSounds


func _ready() -> void:
	var steps_per_second: int = roundi(Engine.physics_ticks_per_second / Engine.time_scale)
	player = $Player as Player
	flow = FlowState.new(player.tuning, steps_per_second)
	_rule = RaceState.new(steps_per_second)
	_rule.restartable = false
	_flow_hud.flow = flow
	_flow_hud.motor = player.motor
	_flow_sounds.flow = flow
	_debug_overlay.motor = player.motor
	_debug_overlay.flow = flow
	player.stepped.connect(_on_player_stepped)
	respawn()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(MENU):
		menu_requested.emit()


## Brings the runner back to the start point, at rest.
func respawn() -> void:
	player.teleport(_spawn.global_transform)


## One fixed step of the runner has passed: back to the start point if it fell or asked
## for it (the flow loses its combo and its gauge), then the flow counts the step and
## gives its speed bonus back to the motor.
func _on_player_stepped(intent: MoveIntent) -> void:
	var altitude: float = player.global_position.y
	if _rule.apply_respawn_rule(altitude, fall_limit, intent) != RaceState.RespawnOrder.NONE:
		respawn()
		flow.respawn()
	flow.tuning = player.tuning
	flow.follow(player.motor)
