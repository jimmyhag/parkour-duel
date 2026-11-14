class_name Course
extends Lane
## The course of solo practice: one lane, its runner, its own targets to shoot, and the
## displays and the sounds of its runner (game/ui). It records each run as the ghost of a
## duel replays it (GhostRun) and gives the session its finished runs; the best time and
## the best style score shown are the session's.
## Expected children, besides the lane's: Player, Hud/RaceHud, Hud/FlowHud,
## Hud/Crosshair, Hud/DebugOverlay, FlowSounds and SabotageSounds.

## The identity of the runner of the course: the player.
const RUNNER: int = 0

## What the game remembers from one mode to the next; to set before the course enters the
## tree, a session of its own otherwise.
var session: Session = Session.new()

## The run under way, as the ghost would replay it.
var _run: GhostRun = GhostRun.new()

@onready var _race_hud: RaceHud = $Hud/RaceHud as RaceHud
@onready var _flow_hud: FlowHud = $Hud/FlowHud as FlowHud
@onready var _crosshair: Crosshair = $Hud/Crosshair as Crosshair
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay
@onready var _flow_sounds: FlowSounds = $FlowSounds as FlowSounds
@onready var _sabotage_sounds: SabotageSounds = $SabotageSounds as SabotageSounds


func _ready() -> void:
	runner_id = RUNNER
	super()
	if session.has_solo_run():
		race.best_steps = session.best_run.race_steps
	flow.best_style_score = session.best_style_score
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
	player.stepped.connect(_record)
	checkpoint_reached.connect(_on_checkpoint_reached_by_the_run)
	restarted.connect(_on_restarted)
	finished.connect(_on_finished)


## Where the visible body is after this step, in the lane, until the finish line.
func _record(intent: MoveIntent) -> void:
	if race.phase == RaceState.Phase.FINISHED:
		return
	var acted: bool = not intent.direction.is_zero_approx()
	acted = acted or intent.jump_pressed or intent.slide_pressed
	_run.record(global_transform.affine_inverse() * player.visual_transform(), acted)


func _on_checkpoint_reached_by_the_run(index: int) -> void:
	_run.reach(index)


func _on_restarted() -> void:
	_run = GhostRun.new()


func _on_finished() -> void:
	_run.finish(race.elapsed_steps, flow.style_score)
	session.offer(_run)
	session.best_style_score = maxi(session.best_style_score, flow.best_style_score)
