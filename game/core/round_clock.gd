class_name RoundClock
extends RefCounted
## The clock of a round of a duel, in fixed steps: the countdown (3, 2, 1, each for the
## time of the tuning), GO, then the time limit of the race. It only counts: the start at
## GO and the time limit are dated messages (RoundMessage) that the duel gives the round.

enum Event { NONE, GO, TIME_UP }

## The numbers counted down before GO.
const NUMBERS: int = 3
## What the countdown shows: GO, or nothing any more.
const GO: int = 0
const NO_COUNTDOWN: int = -1

## Steps since the round began, with its countdown.
var steps: int = 0

var _number_steps: int
var _limit_steps: int


func _init(tuning: MovementTuning, steps_per_second: int) -> void:
	_number_steps = maxi(roundi(tuning.round_countdown_number_time * steps_per_second), 1)
	_limit_steps = roundi(tuning.round_time_limit * steps_per_second)


## One fixed step: what happens at it.
func tick() -> Event:
	steps += 1
	if steps == _countdown_steps():
		return Event.GO
	if steps == _countdown_steps() + _limit_steps:
		return Event.TIME_UP
	return Event.NONE


## The number the countdown shows (3, 2, 1), GO during the time of one number after it,
## then NO_COUNTDOWN.
func countdown() -> int:
	if steps < _countdown_steps():
		@warning_ignore("integer_division")
		return NUMBERS - steps / _number_steps
	if steps < _countdown_steps() + _number_steps:
		return GO
	return NO_COUNTDOWN


## Steps since GO; 0 before it.
func race_steps() -> int:
	return maxi(steps - _countdown_steps(), 0)


func _countdown_steps() -> int:
	return NUMBERS * _number_steps
