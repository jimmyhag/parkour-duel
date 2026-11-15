class_name Crossfade
extends RefCounted
## The blend of the animations of the character (docs/specs/animation-polish.md, decision
## 3): how much each state of its animation tree shows, from 0 to 1, the weights making a
## whole. The state asked for comes in its blend time, frame by frame, along an eased curve
## that starts and ends at a speed of nothing (docs/specs/motion-weight.md, decision 8), and
## every other one goes as much, in proportion to what it showed as the blend started: a
## blend cut short by another one goes on from where it got to, and no weight ever jumps,
## but into a state that comes at once (a blend time of 0). Only weights are given to it:
## it plays nothing.

## The steepest slope of the eased curve (eased), in the middle of a blend: a weight moves
## at most this many times as fast as along a straight line.
const STEEPEST: float = 1.5

## How much each state shows; a state never asked for shows nothing.
var weights: Dictionary[StringName, float] = {}
## The state asked for last, and the time its blend takes, in s; how far the blend has gone
## along its curve (0 to 1), and the weights as it started.
var _wanted: StringName = &""
var _blend_time: float = 0.0
var _progress: float = 1.0
var _from: Dictionary[StringName, float] = {}


## How far an eased blend has gone, from 0 to 1, when `progress` (0 to 1) of its time has
## passed: slowly at its start and at its end, half of it at mid-way.
static func eased(progress: float) -> float:
	return smoothstep(0.0, 1.0, progress)


## Asks for `state`, in `blend_time` s from what is shown now; whether it comes from
## nothing (its clip then starts again): a state still blending out comes back from where
## it is. The state asked for already goes on in the blend time it was asked in.
func go_to(state: StringName, blend_time: float) -> bool:
	if state == _wanted:
		return false
	_wanted = state
	_blend_time = blend_time
	_progress = 0.0
	_from = weights.duplicate()
	return weight(state) <= 0.0


## Moves the weights `delta` s on: the state asked for comes, the others go.
func advance(delta: float) -> void:
	if _wanted.is_empty():
		return
	_progress = minf(_progress + delta / _blend_time, 1.0) if _blend_time > 0.0 else 1.0
	var shown: float = eased(_progress)
	var start: float = _from.get(_wanted, 0.0)
	for state: StringName in _from:
		if state != _wanted:
			weights[state] = _from[state] * (1.0 - shown)
	weights[_wanted] = start + (1.0 - start) * shown


## How much `state` shows, from 0 to 1.
func weight(state: StringName) -> float:
	return weights.get(state, 0.0)
