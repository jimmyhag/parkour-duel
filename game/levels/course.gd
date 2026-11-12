class_name Course
extends Node3D
## A timed course, and the place where the layers meet: it owns the state of the run
## (game/core), listens to the lines and the checkpoints (game/world), brings the
## runner (game/player) back when it falls, and feeds the displays (game/ui).
## Expected children: Player, StartLine, FinishLine, Checkpoints (one Checkpoint per
## section, numbered from 0), Hud/RaceHud and Hud/DebugOverlay.

const RESPAWN: StringName = &"respawn"
const RESTART: StringName = &"restart"

## The altitude under which a runner has fallen off the course.
@export var fall_limit: float = 0.0

var race: RaceState

var _checkpoints: Dictionary[int, Checkpoint] = {}
var _respawn_requested: bool = false
var _restart_requested: bool = false

@onready var player: Player = $Player as Player
@onready var _start_line: RaceLine = $StartLine as RaceLine
@onready var _finish_line: RaceLine = $FinishLine as RaceLine
@onready var _race_hud: RaceHud = $Hud/RaceHud as RaceHud
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay


func _ready() -> void:
	race = RaceState.new(Engine.physics_ticks_per_second)
	for child: Node in $Checkpoints.get_children():
		var checkpoint: Checkpoint = child as Checkpoint
		_checkpoints[checkpoint.index] = checkpoint
		checkpoint.reached.connect(race.reach_checkpoint)
	_start_line.crossed.connect(race.cross_start_line)
	_finish_line.crossed.connect(race.cross_finish_line)
	_race_hud.race = race
	_debug_overlay.motor = player.motor
	respawn()


func _physics_process(_delta: float) -> void:
	if _restart_requested:
		race.restart()
		respawn()
	elif _respawn_requested or player.global_position.y < fall_limit:
		respawn()
	_restart_requested = false
	_respawn_requested = false
	race.tick()


func _unhandled_input(event: InputEvent) -> void:
	# The requests wait for the next fixed step: the simulation never moves in between.
	if event.is_action_pressed(RESPAWN):
		_respawn_requested = true
	elif event.is_action_pressed(RESTART):
		_restart_requested = true


## Brings the runner back to the last checkpoint reached, at rest. The timer is not
## touched.
func respawn() -> void:
	player.teleport(_checkpoints[race.last_checkpoint].global_transform)
