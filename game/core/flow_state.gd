class_name FlowState
extends RefCounted
## The flow of one runner: the gauge its moves fill, the combo that chains them and its
## multiplier, the ammunition the gauge gives, and the style score of the run. It counts
## only from what the motor announces (RunnerEvent), the speed and the ground contact
## the motor knows, and the orders of the course: respawn, restart, finish. Time is
## counted in fixed steps. Nothing is saved to disk.

## The gauge, in points: from 0 to the value of a tier times the number of tiers.
var gauge: float = 0.0
var ammo: int = 0
## The style score of the run: the sum of the points of its moves, multiplied.
var style_score: int = 0
## The best style score of a finished run of the session.
var best_style_score: int = 0
## The run is finished: nothing counts until it restarts.
var frozen: bool = false
## The move last counted, and how many times in a row it was (0 after an error).
var repeated_move: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
var repeat_count: int = 0
## What the displays announce: the moves counted in the session, the last one and the
## points it earned; the tiers crossed upwards in the session and the last one; the
## combos broken by an error in the session.
var moves_counted: int = 0
var last_move: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
var last_points: int = 0
var tiers_crossed: int = 0
var last_tier_crossed: int = 0
var combos_broken: int = 0
var tuning: MovementTuning

var _steps_per_second: int
## Moves of the combo under way: 0 out of a combo.
var _combo_moves: int = 0
## Steps spent on the ground since the last move of the combo.
var _steps_on_the_ground: int = 0
## Steps the runner has stood still on the ground, in a row.
var _steps_stopped: int = 0
## Points earned beyond a full gauge since it is full, and not turned into ammunition
## yet.
var _beyond_full: float = 0.0


func _init(movement_tuning: MovementTuning, steps_per_second: int) -> void:
	tuning = movement_tuning
	_steps_per_second = steps_per_second


## One fixed step of the runner: the messages its motor sent at this step, its
## real horizontal speed (m/s), and whether it is on its feet on the ground. On the
## ground the delay of the combo runs, and its end resets the repetition; the moves are
## counted; a runner that stays still has stopped. The gauge drops at a step spent out
## of a combo from its start to its end. What was earned beyond a full gauge only counts
## while it stays full.
func step(events: Array[RunnerEvent], horizontal_speed: float, on_foot: bool) -> void:
	if frozen:
		return
	var was_in_combo: bool = in_combo()
	if was_in_combo and on_foot:
		_steps_on_the_ground += 1
		if _steps_on_the_ground >= _steps(tuning.flow_chain_delay):
			_combo_moves = 0
			repeat_count = 0
	for event: RunnerEvent in events:
		_count(event.kind, horizontal_speed)
	_watch_for_a_stop(horizontal_speed, on_foot)
	if not was_in_combo and not in_combo():
		gauge = maxf(gauge - tuning.flow_decay / _steps_per_second, 0.0)
	if gauge < max_gauge():
		_beyond_full = 0.0


## Counts the fixed step the motor just played, then gives the motor the speed bonus of
## the gauge: what the course does at every step.
func follow(motor: RunnerMotor) -> void:
	step(motor.events, motor.real_speed(), motor.is_on_foot())
	motor.top_speed_bonus = speed_bonus()


## The runner fell off the course or asked for its last checkpoint: the gauge empties and
## the combo is broken; the ammunition and the style score stay.
func respawn() -> void:
	if frozen:
		return
	_break_the_combo()
	gauge = 0.0
	_beyond_full = 0.0
	_steps_stopped = 0


## A new run: everything from zero, but the best style score of the session.
func restart() -> void:
	frozen = false
	gauge = 0.0
	ammo = 0
	style_score = 0
	_combo_moves = 0
	_steps_on_the_ground = 0
	_steps_stopped = 0
	_beyond_full = 0.0
	repeat_count = 0


## The run is over: the flow freezes, and its style score may be the best of the session.
func finish() -> void:
	if frozen:
		return
	frozen = true
	best_style_score = maxi(best_style_score, style_score)


func in_combo() -> bool:
	return _combo_moves > 0


## What the next move of the combo is multiplied by: x1 at its start, one more every few
## moves, up to the highest.
func multiplier() -> int:
	@warning_ignore("integer_division")
	var raised: int = _combo_moves / maxi(tuning.flow_moves_per_multiplier, 1)
	return mini(1 + raised, maxi(tuning.flow_max_multiplier, 1))


## The highest tier the gauge reached: 0 under the first one.
func tier() -> int:
	if tuning.flow_tier_value <= 0.0:
		return 0
	return mini(floori(gauge / tuning.flow_tier_value), tuning.flow_tier_count)


## The share of the top speed the runner gains at the tier of the moment.
func speed_bonus() -> float:
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var current: int = tier()
	if current == 0 or bonuses.is_empty():
		return 0.0
	return bonuses[mini(current, bonuses.size()) - 1]


## Seconds left on the ground for the next move to go on with the combo; 0 out of one.
func chain_time_left() -> float:
	if not in_combo():
		return 0.0
	var steps_left: int = maxi(_steps(tuning.flow_chain_delay) - _steps_on_the_ground, 0)
	return float(steps_left) / _steps_per_second


## The most the gauge holds.
func max_gauge() -> float:
	return tuning.flow_tier_value * tuning.flow_tier_count


## A move earns its points, worth less when it repeats the one before, multiplied by the
## multiplier the combo had before it; it goes on with the combo even when it is worth
## nothing. A jump without enough speed is no move at all. A hard landing is an error,
## and costs one tier.
func _count(kind: RunnerEvent.Kind, horizontal_speed: float) -> void:
	if kind == RunnerEvent.Kind.HARD_LANDING:
		_break_the_combo()
		gauge = maxf(gauge - tuning.flow_tier_value, 0.0)
		return
	var least_speed: float = tuning.top_speed * tuning.flow_jump_min_speed_share
	if kind == RunnerEvent.Kind.JUMP and horizontal_speed < least_speed:
		return
	if repeat_count > 0 and kind == repeated_move:
		repeat_count += 1
	else:
		repeated_move = kind
		repeat_count = 1
	var points: int = roundi(_points(kind) * _repetition_share()) * multiplier()
	_combo_moves += 1
	_steps_on_the_ground = 0
	style_score += points
	_fill(points)
	moves_counted += 1
	last_move = kind
	last_points = points


## What the move counted now is worth, as a share of its points, for the times in a row
## it was made.
func _repetition_share() -> float:
	match repeat_count:
		1:
			return 1.0
		2:
			return tuning.flow_second_time_share
	return tuning.flow_later_times_share


## The points of a move, before the repetition and the multiplier.
func _points(kind: RunnerEvent.Kind) -> int:
	var points: Dictionary[RunnerEvent.Kind, int] = {
		RunnerEvent.Kind.JUMP: tuning.flow_points_jump,
		RunnerEvent.Kind.SLIDE: tuning.flow_points_slide,
		RunnerEvent.Kind.PERFECT_SLIDE: tuning.flow_points_perfect_slide,
		RunnerEvent.Kind.ROLL: tuning.flow_points_roll,
		RunnerEvent.Kind.MANTLE: tuning.flow_points_mantle,
		RunnerEvent.Kind.WALL_RUN: tuning.flow_points_wall_run,
		RunnerEvent.Kind.WALL_JUMP: tuning.flow_points_wall_jump,
	}
	return points[kind]


## The gauge gains `points`, up to its maximum; every tier it crosses upwards gives one
## ammunition, up to the most the runner may hold. Full, it keeps what goes beyond: each
## time that reaches the value of a tier, one more ammunition, and the count goes on
## with what is left over.
func _fill(points: int) -> void:
	var before: int = tier()
	var room: float = max_gauge() - gauge
	gauge = minf(gauge + points, max_gauge())
	var after: int = tier()
	if after > before:
		ammo = mini(ammo + after - before, tuning.flow_max_ammo)
		tiers_crossed += 1
		last_tier_crossed = after
	if points <= room or tuning.flow_tier_value <= 0.0:
		return
	_beyond_full += points - room
	while _beyond_full >= tuning.flow_tier_value:
		_beyond_full -= tuning.flow_tier_value
		ammo = mini(ammo + 1, tuning.flow_max_ammo)


## A runner on its feet slower than the stop speed for the stop duration has stopped: an
## error, once per stop.
func _watch_for_a_stop(horizontal_speed: float, on_foot: bool) -> void:
	if not on_foot or horizontal_speed >= tuning.flow_stop_speed:
		_steps_stopped = 0
		return
	_steps_stopped += 1
	if _steps_stopped == _steps(tuning.flow_stop_duration):
		_break_the_combo()


## An error: the combo is over, its multiplier back to x1, and the repetition to zero.
func _break_the_combo() -> void:
	if in_combo():
		combos_broken += 1
	_combo_moves = 0
	_steps_on_the_ground = 0
	repeat_count = 0


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _steps(seconds: float) -> int:
	return roundi(seconds * _steps_per_second)
