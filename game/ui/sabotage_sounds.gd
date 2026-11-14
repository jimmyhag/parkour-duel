class_name SabotageSounds
extends Node
## The sounds of the shot and of the targets, played from what game/core counted: a shot
## fired, a target hit that starts its warning, the start of an effect, a target back in
## its place.

## The weapon of the runner, and the targets of its course.
var shooter: Shooter
var targets: TargetBoard

## What was already played: the counts at the last refresh.
var _shots_seen: int = 0
var _warnings_seen: int = 0
var _effects_seen: int = 0
var _returns_seen: int = 0

@onready var _shot: AudioStreamPlayer = $Shot as AudioStreamPlayer
@onready var _warning: AudioStreamPlayer = $Warning as AudioStreamPlayer
@onready var _effect: AudioStreamPlayer = $Effect as AudioStreamPlayer
@onready var _return: AudioStreamPlayer = $Return as AudioStreamPlayer


func _process(_delta: float) -> void:
	refresh()


## Plays the sound of each event counted since the last refresh.
func refresh() -> void:
	if shooter != null and shooter.shots != _shots_seen:
		_shots_seen = shooter.shots
		_shot.play()
	if targets == null:
		return
	var warnings: int = 0
	var effects: int = 0
	var returns: int = 0
	for target: SabotageTarget in targets.targets.values():
		warnings += target.warnings
		effects += target.effects
		returns += target.returns
	if warnings != _warnings_seen:
		_warning.play()
	if effects != _effects_seen:
		_effect.play()
	if returns != _returns_seen:
		_return.play()
	_warnings_seen = warnings
	_effects_seen = effects
	_returns_seen = returns
