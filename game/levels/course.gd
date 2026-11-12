class_name Course
extends Node3D
## A timed course, and the place where the layers meet: it owns the state of the run
## (game/core), listens to the lines and the checkpoints (game/world), brings the
## runner (game/player) back when the rule of game/core says so, and feeds the displays
## (game/ui). It reads no input and decides nothing: it executes.
## Expected children: Player, StartLine, FinishLine, Checkpoints (one Checkpoint per
## section, numbered from 0), Hud/RaceHud and Hud/DebugOverlay.

## The altitude under which a runner has fallen off the course.
@export var fall_limit: float = 0.0

var race: RaceState

var _checkpoints: Dictionary[int, Checkpoint] = {}

@onready var player: Player = $Player as Player
@onready var _start_line: RaceLine = $StartLine as RaceLine
@onready var _finish_line: RaceLine = $FinishLine as RaceLine
@onready var _race_hud: RaceHud = $Hud/RaceHud as RaceHud
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay


func _ready() -> void:
	# Fixed steps per second of game time, whatever the speed of the engine's clock.
	race = RaceState.new(roundi(Engine.physics_ticks_per_second / Engine.time_scale))
	for child: Node in $Checkpoints.get_children():
		var checkpoint: Checkpoint = child as Checkpoint
		_checkpoints[checkpoint.index] = checkpoint
		checkpoint.reached.connect(race.reach_checkpoint)
	_start_line.crossed.connect(race.cross_start_line)
	_finish_line.crossed.connect(race.cross_finish_line)
	_race_hud.race = race
	_debug_overlay.motor = player.motor
	player.stepped.connect(_on_player_stepped)
	respawn()


## Brings the runner back to the last checkpoint reached, at rest. The timer is not
## touched.
func respawn() -> void:
	player.teleport(_checkpoints[race.last_checkpoint].global_transform)


## One fixed step of the runner has passed.
func _on_player_stepped(intent: MoveIntent) -> void:
	var altitude: float = player.global_position.y
	if race.apply_respawn_rule(altitude, fall_limit, intent) != RaceState.RespawnOrder.NONE:
		respawn()
	race.tick()
