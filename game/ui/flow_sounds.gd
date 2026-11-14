class_name FlowSounds
extends Node
## The sounds of the flow and of the tricks, played from what the flow counted: a trick
## posed, a perfect landing (instead of a trick posed), a crash, a tier crossed upwards,
## a combo broken.

## The flow to listen to.
var flow: FlowState

## What was already played: the counts of the flow at the last refresh.
var _tricks_seen: int = 0
var _perfects_seen: int = 0
var _crashes_seen: int = 0
var _tiers_seen: int = 0
var _breaks_seen: int = 0

@onready var _trick_landed: AudioStreamPlayer = $TrickLanded as AudioStreamPlayer
@onready var _perfect_landing: AudioStreamPlayer = $PerfectLanding as AudioStreamPlayer
@onready var _crash: AudioStreamPlayer = $Crash as AudioStreamPlayer
@onready var _tier_crossed: AudioStreamPlayer = $TierCrossed as AudioStreamPlayer
@onready var _combo_broken: AudioStreamPlayer = $ComboBroken as AudioStreamPlayer


func _process(_delta: float) -> void:
	refresh()


## Plays the sound of each event the flow counted since the last refresh.
func refresh() -> void:
	if flow == null:
		return
	if flow.perfect_landings != _perfects_seen:
		_perfect_landing.play()
	elif flow.tricks_landed != _tricks_seen:
		_trick_landed.play()
	if flow.crashes != _crashes_seen:
		_crash.play()
	if flow.tiers_crossed != _tiers_seen:
		_tier_crossed.play()
	if flow.combos_broken != _breaks_seen:
		_combo_broken.play()
	_perfects_seen = flow.perfect_landings
	_tricks_seen = flow.tricks_landed
	_crashes_seen = flow.crashes
	_tiers_seen = flow.tiers_crossed
	_breaks_seen = flow.combos_broken
