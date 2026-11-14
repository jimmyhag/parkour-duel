class_name Course
extends Node3D
## A timed course, and the place where the layers meet: it owns the state of the run, the
## flow of its runner, its weapon and the targets of the course (game/core), listens to
## the lines and the checkpoints (game/world), brings the runner (game/player) back when
## the rule of game/core says so, gives the flow what the runner's motor announced and
## the motor the speed bonus of the flow, gives the targets the runners in their zones
## and the weapon what the runner aims at, lets the target blocks (game/world) show what
## their targets say, and feeds the displays and the sounds (game/ui). It reads no input
## and decides nothing: it executes.
## Expected children: Player, StartLine, FinishLine, Checkpoints (one Checkpoint per
## section, numbered from 0), Targets (one TargetBlock per target), Hud/RaceHud,
## Hud/FlowHud, Hud/Crosshair, Hud/DebugOverlay, FlowSounds and SabotageSounds.

## The identity of the runner of the course: who shoots, and who the targets hit.
const RUNNER: int = 1

## The altitude under which a runner has fallen off the course.
@export var fall_limit: float = 0.0

var race: RaceState
var flow: FlowState
var targets: TargetBoard
var shooter: Shooter

var _checkpoints: Dictionary[int, Checkpoint] = {}
var _blocks: Array[TargetBlock] = []

@onready var player: Player = $Player as Player
@onready var _start_line: RaceLine = $StartLine as RaceLine
@onready var _finish_line: RaceLine = $FinishLine as RaceLine
@onready var _race_hud: RaceHud = $Hud/RaceHud as RaceHud
@onready var _flow_hud: FlowHud = $Hud/FlowHud as FlowHud
@onready var _crosshair: Crosshair = $Hud/Crosshair as Crosshair
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay
@onready var _flow_sounds: FlowSounds = $FlowSounds as FlowSounds
@onready var _sabotage_sounds: SabotageSounds = $SabotageSounds as SabotageSounds


func _ready() -> void:
	# Fixed steps per second of game time, whatever the speed of the engine's clock.
	var steps_per_second: int = roundi(Engine.physics_ticks_per_second / Engine.time_scale)
	race = RaceState.new(steps_per_second)
	flow = FlowState.new(player.tuning, steps_per_second)
	targets = TargetBoard.new()
	shooter = Shooter.new(RUNNER, player.tuning)
	for child: Node in $Checkpoints.get_children():
		var checkpoint: Checkpoint = child as Checkpoint
		_checkpoints[checkpoint.index] = checkpoint
		checkpoint.reached.connect(race.reach_checkpoint)
	for child: Node in $Targets.get_children():
		var block: TargetBlock = child as TargetBlock
		block.target = SabotageTarget.new(
			block.target_id, block.kind, player.tuning, steps_per_second
		)
		targets.add(block.target)
		_blocks.append(block)
	_start_line.crossed.connect(race.cross_start_line)
	_finish_line.crossed.connect(_on_finish_line_crossed)
	_race_hud.race = race
	_race_hud.flow = flow
	_flow_hud.flow = flow
	_flow_hud.motor = player.motor
	_crosshair.shooter = shooter
	_flow_sounds.flow = flow
	_sabotage_sounds.shooter = shooter
	_sabotage_sounds.targets = targets
	_debug_overlay.motor = player.motor
	_debug_overlay.flow = flow
	_debug_overlay.shooter = shooter
	_debug_overlay.targets = targets
	player.stepped.connect(_on_player_stepped)
	respawn()


## Brings the runner back to the last checkpoint reached, at rest. The timer is not
## touched.
func respawn() -> void:
	player.teleport(_checkpoints[race.last_checkpoint].global_transform)


## One fixed step of the runner has passed: the respawn rule first, then the flow counts
## the step (nothing of it after a return to a checkpoint) and gives its speed bonus back
## to the motor; then the targets play their step, and their effects may hit the runner;
## then the weapon follows what the runner aims at, and its shot reaches the targets.
## Everything obeys the tuning the runner obeys. A restart puts every target back.
func _on_player_stepped(intent: MoveIntent) -> void:
	var altitude: float = player.global_position.y
	var order: RaceState.RespawnOrder = race.apply_respawn_rule(altitude, fall_limit, intent)
	if order != RaceState.RespawnOrder.NONE:
		respawn()
	if order == RaceState.RespawnOrder.RESTART:
		flow.restart()
		targets.reset()
	elif order == RaceState.RespawnOrder.RESPAWN:
		flow.respawn()
	flow.tuning = player.tuning
	flow.follow(player.motor)
	_step_the_targets()
	shooter.tuning = player.tuning
	shooter.follow(intent, player.aim_facts, player.motor.steps, targets, flow)
	for block: TargetBlock in _blocks:
		block.focused = shooter.shootable_target() == block.target_id
		block.follow()
	race.tick()


## Every target plays its step with the runners in its zone, then the flow counts the
## effects that hit its runner.
func _step_the_targets() -> void:
	targets.set_tuning(player.tuning)
	for block: TargetBlock in _blocks:
		var inside: Array[int] = []
		if block.holds(player):
			inside.append(RUNNER)
		block.target.step(inside)
	flow.follow_targets(targets, RUNNER)


func _on_finish_line_crossed() -> void:
	race.cross_finish_line()
	if race.phase == RaceState.Phase.FINISHED:
		flow.finish()
