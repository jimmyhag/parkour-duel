class_name FlowState
extends RefCounted
## The flow of one runner: the gauge its moves fill and the speed it gives, the combo
## that chains them and its multiplier, the style score of the run and the ammunition its
## style points give. It counts
## only from what the motor announces (RunnerEvent), the speed and the ground contact
## the motor knows, and the orders of the course: respawn, restart, finish, and the
## sabotages that hit the runner. A shot spends its ammunition. Time is counted in fixed
## steps. Nothing is saved to disk.

## The gauge, in points: from 0 to the value of a tier times the number of tiers.
var gauge: float = 0.0
var ammo: int = 0
## Style points earned since the last ammunition, towards the next one. Kept through
## the combos and the falls, even with the most ammunition held.
var ammo_progress: int = 0
## The style score of the run: the sum of the points of its moves, multiplied.
var style_score: int = 0
## The best style score of a finished run of the session.
var best_style_score: int = 0
## The run is finished: nothing counts until it restarts.
var frozen: bool = false
## The move last judged, and how many times it was among the last moves of the combo,
## itself included (0 once the combo is over).
var repeated_move: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
var repeat_count: int = 0
## What the displays announce: the moves judged in the session, the last one and the
## points it earned (0 for a move worth nothing); the tiers crossed upwards in the
## session and the last one; the combos broken by an error in the session.
var moves_counted: int = 0
var last_move: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
var last_points: int = 0
var tiers_crossed: int = 0
var last_tier_crossed: int = 0
var combos_broken: int = 0
## The moves counted at the last step that counted any, and the points each one earned.
var step_moves: Array[RunnerEvent] = []
var step_points: Array[int] = []
## The tricks counted in the session, the perfect landings among them, and the crashes.
var tricks_landed: int = 0
var perfect_landings: int = 0
var crashes: int = 0
## The sabotages that hit the runner in the session.
var sabotages: int = 0
var tuning: MovementTuning

var _steps_per_second: int
## Moves of the combo under way that were worth something: 0 out of a combo.
var _combo_moves: int = 0
## The last moves of the combo that were worth something, the oldest first, each one by
## what tells it apart from the others: what a move is judged against.
var _last_moves: Array[String] = []
## The last tricks that were worth something, the oldest first, each one by its recipe:
## what a trick is judged against, whatever the moves between them.
var _last_tricks: Array[String] = []
## No move has been counted yet at the step under way.
var _fresh_step: bool = false
## Steps spent on the ground since the last move of the combo that was worth something.
var _steps_on_the_ground: int = 0
## Steps the runner has stood still on the ground, in a row.
var _steps_stopped: int = 0


func _init(movement_tuning: MovementTuning, steps_per_second: int) -> void:
	tuning = movement_tuning
	_steps_per_second = steps_per_second


## One fixed step of the runner: the messages its motor sent at this step, its
## real horizontal speed (m/s), and whether it is on its feet on the ground. On the
## ground the delay of the combo runs, and its end keeps the last moves and the last
## tricks that the repetition judges against; the moves are counted; a runner that stays
## still has stopped. The gauge drops at a step spent out
## of a combo from its start to its end.
func step(events: Array[RunnerEvent], horizontal_speed: float, on_foot: bool) -> void:
	if frozen:
		return
	var was_in_combo: bool = in_combo()
	if was_in_combo and on_foot:
		_steps_on_the_ground += 1
		if _steps_on_the_ground >= _steps(tuning.flow_chain_delay):
			_end_the_combo(false)
	_fresh_step = true
	for event: RunnerEvent in events:
		_count(event, horizontal_speed)
	_watch_for_a_stop(horizontal_speed, on_foot)
	if not was_in_combo and not in_combo():
		gauge = maxf(gauge - tuning.flow_decay / _steps_per_second, 0.0)


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
	_steps_stopped = 0


## A new run: everything from zero, but the best style score of the session.
func restart() -> void:
	frozen = false
	gauge = 0.0
	ammo = 0
	ammo_progress = 0
	style_score = 0
	_end_the_combo()
	_steps_stopped = 0


## The run is over: the flow freezes, and its style score may be the best of the session.
func finish() -> void:
	if frozen:
		return
	frozen = true
	best_style_score = maxi(best_style_score, style_score)


## A shot spends `amount` ammunition: false, and nothing spent, without enough.
func spend(amount: int) -> bool:
	if amount > ammo:
		return false
	ammo -= amount
	return true


## Counts the targets of the course the runner `runner` runs on, after they played their
## step: a sabotage whose effect hit it is an error.
func follow_targets(board: TargetBoard, runner: int) -> void:
	if board.hit(runner):
		sabotaged()


## The runner was hit by a sabotage: an error, like a hard landing; the combo is broken
## and the gauge loses one tier. It loses nothing else.
func sabotaged() -> void:
	if frozen:
		return
	sabotages += 1
	_break_the_combo()
	gauge = maxf(gauge - tuning.flow_tier_value, 0.0)


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


## A move earns its points, worth less for each time it is among the last moves of the
## combo (a trick: among the last tricks), multiplied by the multiplier the combo had
## before it. A move worth nothing earns
## nothing, does not go on with the combo and does not count for the multiplier. A jump
## without enough speed is no move at all. A hard landing and a crash are errors, and
## cost one tier.
func _count(event: RunnerEvent, horizontal_speed: float) -> void:
	var kind: RunnerEvent.Kind = event.kind
	if kind == RunnerEvent.Kind.HARD_LANDING or kind == RunnerEvent.Kind.CRASH:
		crashes += int(kind == RunnerEvent.Kind.CRASH)
		_break_the_combo()
		gauge = maxf(gauge - tuning.flow_tier_value, 0.0)
		return
	var least_speed: float = tuning.top_speed * tuning.flow_jump_min_speed_share
	if kind == RunnerEvent.Kind.JUMP and horizontal_speed < least_speed:
		return
	var move: String = _identity(event)
	var judged: Array[String] = _last_moves if event.trick == null else _last_tricks
	var times: int = judged.count(move)
	repeated_move = kind
	repeat_count = times + 1
	var points: int = roundi(_points(event) * _repetition_share(times)) * multiplier()
	moves_counted += 1
	last_move = kind
	last_points = points
	_announce(event, points)
	if points <= 0:
		return
	_combo_moves += 1
	_steps_on_the_ground = 0
	_last_moves.append(move)
	while _last_moves.size() > tuning.flow_repetition_window:
		_last_moves.pop_front()
	if event.trick != null:
		_last_tricks.append(move)
		while _last_tricks.size() > tuning.trick_repetition_window:
			_last_tricks.pop_front()
	style_score += points
	_earn_ammo(points)
	_fill(points)


## The share of its points a move is worth, for the times it is among the last moves.
func _repetition_share(times: int) -> float:
	match times:
		0:
			return 1.0
		1:
			return tuning.flow_second_time_share
	return tuning.flow_later_times_share


## Style points go towards the next ammunition: each slice of them gives one, up to the
## most the runner may hold, and what is over goes towards the next one.
func _earn_ammo(points: int) -> void:
	ammo_progress += points
	if tuning.flow_points_per_ammo <= 0:
		return
	while ammo_progress >= tuning.flow_points_per_ammo:
		ammo_progress -= tuning.flow_points_per_ammo
		ammo = mini(ammo + 1, tuning.flow_max_ammo)


## What tells a move apart from the others for the repetition: its kind; for a trick, its
## flip, its turns and its twists.
func _identity(event: RunnerEvent) -> String:
	var kind: String = RunnerEvent.Kind.keys()[event.kind]
	if event.trick == null:
		return kind
	return kind + " " + event.trick.identity()


## What the displays announce of a move counted at this step, with its points.
func _announce(event: RunnerEvent, points: int) -> void:
	if _fresh_step:
		_fresh_step = false
		step_moves.clear()
		step_points.clear()
	step_moves.append(event)
	step_points.append(points)
	if event.trick != null:
		tricks_landed += 1
		perfect_landings += int(event.trick.perfect)


## The points of a move, before the repetition and the multiplier: a trick has its own.
func _points(event: RunnerEvent) -> int:
	if event.trick != null:
		return event.trick.points(tuning)
	var kind: RunnerEvent.Kind = event.kind
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


## The gauge gains `points`, up to its maximum; a tier crossed upwards is announced.
func _fill(points: int) -> void:
	var before: int = tier()
	gauge = minf(gauge + points, max_gauge())
	var after: int = tier()
	if after > before:
		tiers_crossed += 1
		last_tier_crossed = after


## A runner on its feet slower than the stop speed for the stop duration has stopped: an
## error, once per stop.
func _watch_for_a_stop(horizontal_speed: float, on_foot: bool) -> void:
	if not on_foot or horizontal_speed >= tuning.flow_stop_speed:
		_steps_stopped = 0
		return
	_steps_stopped += 1
	if _steps_stopped == _steps(tuning.flow_stop_duration):
		_break_the_combo()


## An error: the combo is over, broken.
func _break_the_combo() -> void:
	if in_combo():
		combos_broken += 1
	_end_the_combo()


## The combo is over: its multiplier back to x1; its last moves and its last tricks
## forgotten, unless it ended by its delay (`forget` false): the repetition goes on across
## combos.
func _end_the_combo(forget: bool = true) -> void:
	_combo_moves = 0
	_steps_on_the_ground = 0
	if forget:
		_last_moves.clear()
		_last_tricks.clear()
	repeat_count = 0


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _steps(seconds: float) -> int:
	return roundi(seconds * _steps_per_second)
