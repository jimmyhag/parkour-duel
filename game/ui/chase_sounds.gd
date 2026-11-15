class_name ChaseSounds
extends Node
## The sounds of the gestures of the cat (docs/specs/chase-tag.md), played from what
## game/core says: an impact when a gesture catches the mouse (the cat wins a round), a
## short sound when one misses (it stops reaching while the round is still on). A gesture
## that stops reaching once the round is over, the one that caught among them, is no miss.

## The chase, and the motor of each of its runners.
var chase: ChaseState
var motors: Array[RunnerMotor] = []

## What was already played: the end of the last round the cat won, and the last gesture of
## each motor seen missing.
var _caught_at: int = ChaseState.NOT_YET
var _missed: Array[Tag] = []

@onready var _catch: AudioStreamPlayer = $Catch as AudioStreamPlayer
@onready var _miss: AudioStreamPlayer = $Miss as AudioStreamPlayer


func _process(_delta: float) -> void:
	refresh()


## Plays the sound of each catch and of each miss since the last refresh.
func refresh() -> void:
	var won: bool = chase != null and chase.round_winner != ChaseState.NOBODY
	if won and chase.round_winner_role == ChaseState.Role.CAT and chase.end_step != _caught_at:
		_caught_at = chase.end_step
		_catch.play()
	var running: bool = chase == null or chase.phase == ChaseState.Phase.RUNNING
	_missed.resize(motors.size())
	for index: int in motors.size():
		var gesture: Tag = motors[index].tag
		if gesture == null or gesture == _missed[index]:
			continue
		if not running:
			# Over before it missed: it never will.
			_missed[index] = gesture
		elif gesture.phase != Tag.Phase.REACHING:
			_missed[index] = gesture
			_miss.play()
