class_name SabotageTarget
extends RefCounted
## One target of a course that a shot can sabotage, as a small state machine driven by
## dated messages (SabotageMessage) and counted in fixed steps: ready; hit, it warns for
## a while; then its effect lasts the time of its type; then it comes back to its place
## and rests; then it is ready again. Its scene (game/world) only shows what this machine
## says: whether the object is out of its place (`displaced`), and its state.
## Its zone is where its object goes or stands, and the space a runner on it takes: a
## runner in it as the effect starts is hit. Its place is the volume of its object alone:
## the object never moves into a runner, it waits for its place to be free. An object that
## leaves its place does not start its effect while a runner is in the air above it; an
## effect delayed so then also waits for nobody to be in its zone (a runner landing back
## on it and running off is not hit). It lasts its full time from its real start.

## A platform vanishes and a bridge falls away: they leave their place. An obstacle
## falls onto the way and a barrier rises across it: they come onto the way.
enum Kind { PLATFORM, BRIDGE, OBSTACLE, BARRIER }
## RECOVERING: the effect is over, and the object waits for its place to be free to come
## back.
enum State { READY, WARNING, SABOTAGED, RECOVERING, RESTING }

## The identity of no target.
const NO_TARGET: int = 0
## The metadata under which the bodies of a target's scene hold its identity, and the
## lane it belongs to: what the player layer reads off the first thing on the line of the
## reticle.
const META: StringName = &"sabotage_target"
const LANE_META: StringName = &"sabotage_lane"

## Its identity in its course, stable from one run to the next; never NO_TARGET.
var id: int
var kind: Kind
var state: State = State.READY
## The object is out of its place: vanished, fallen away, fallen onto the way or risen.
var displaced: bool = false
## The runners hit at the step just played: the ones in its zone as its effect started.
var hits: Array[int] = []
## What the presentation announces: the warnings, the effects and the returns of the
## session.
var warnings: int = 0
var effects: int = 0
var returns: int = 0
var tuning: MovementTuning

var _steps_per_second: int
## Steps left of the warning, of the effect or of the rest under way.
var _steps_left: int = 0
## Its effect was delayed by a runner in the air above it: it now waits for an empty zone.
var _delayed: bool = false


func _init(
	target_id: int, target_kind: Kind, movement_tuning: MovementTuning, steps_per_second: int
) -> void:
	id = target_id
	kind = target_kind
	tuning = movement_tuning
	_steps_per_second = steps_per_second


func is_ready() -> bool:
	return state == State.READY


## The ammunition a shot at it costs.
func cost() -> int:
	match kind:
		Kind.PLATFORM:
			return tuning.sabotage_cost_platform
		Kind.BRIDGE:
			return tuning.sabotage_cost_bridge
		Kind.OBSTACLE:
			return tuning.sabotage_cost_obstacle
	return tuning.sabotage_cost_barrier


## How long its effect lasts, in s.
func effect_duration() -> float:
	match kind:
		Kind.PLATFORM:
			return tuning.sabotage_duration_platform
		Kind.BRIDGE:
			return tuning.sabotage_duration_bridge
		Kind.OBSTACLE:
			return tuning.sabotage_duration_obstacle
	return tuning.sabotage_duration_barrier


## A message of sabotage: a ready target it names is hit and starts its warning. Any
## other message changes nothing; it says whether the target took it.
func receive(message: SabotageMessage) -> bool:
	if message.target != id or state != State.READY:
		return false
	state = State.WARNING
	_steps_left = _steps(tuning.sabotage_warning)
	warnings += 1
	return true


## One fixed step, with the runners that are in its zone, whether its place is free, and
## whether a runner is in the air above it. The warning over, the effect starts and hits
## the runners in its zone; a platform or a bridge waits for nobody to be in the air above
## it first, and once delayed so, for nobody to be in its zone. An object that comes onto
## the way does so once its place is free; one that left its place comes back once it is
## free. Then it rests.
func step(
	runners_in_zone: Array[int], place_free: bool, runner_in_the_air_above: bool = false
) -> void:
	hits.clear()
	var free: bool = place_free
	match state:
		State.WARNING:
			_steps_left -= 1
			if _steps_left > 0:
				return
			if leaves_its_place() and runner_in_the_air_above:
				_delayed = true
			elif not _delayed or runners_in_zone.is_empty():
				_start_the_effect(runners_in_zone, free)
		State.SABOTAGED:
			displaced = displaced or free
			_steps_left -= 1
			if _steps_left <= 0:
				_come_back(free)
		State.RECOVERING:
			_come_back(free)
		State.RESTING:
			_steps_left -= 1
			if _steps_left <= 0:
				state = State.READY


## Seconds left of the warning, of the effect or of the rest under way; 0 when ready or
## waiting to come back.
func time_left() -> float:
	if state == State.READY or state == State.RECOVERING:
		return 0.0
	return float(maxi(_steps_left, 0)) / _steps_per_second


## Ready, in its place, as at the start of a run.
func reset() -> void:
	state = State.READY
	displaced = false
	hits.clear()
	_steps_left = 0
	_delayed = false


## A platform and a bridge leave their place; an obstacle and a barrier come onto the
## way.
static func leaves_its_place_when(of_kind: Kind) -> bool:
	return of_kind == Kind.PLATFORM or of_kind == Kind.BRIDGE


func leaves_its_place() -> bool:
	return leaves_its_place_when(kind)


func _start_the_effect(runners_in_zone: Array[int], free: bool) -> void:
	_delayed = false
	state = State.SABOTAGED
	_steps_left = _steps(effect_duration())
	effects += 1
	hits = runners_in_zone.duplicate()
	displaced = leaves_its_place() or free


## The effect is over: an object that left its place comes back if its place is free,
## and waits otherwise; one that came onto the way goes back where it came from, where
## nobody stands. Then it rests.
func _come_back(free: bool) -> void:
	if displaced and leaves_its_place() and not free:
		state = State.RECOVERING
		return
	displaced = false
	state = State.RESTING
	_steps_left = _steps(tuning.sabotage_cooldown)
	returns += 1


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _steps(seconds: float) -> int:
	return roundi(seconds * _steps_per_second)
