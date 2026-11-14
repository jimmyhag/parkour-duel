class_name Crossfade
extends RefCounted
## The blend of the animations of the character (docs/specs/animation-polish.md, decision
## 3): how much each state of its animation tree shows, from 0 to 1, the weights making a
## whole. The state asked for comes in its blend time, frame by frame, and every other one
## goes as much, in proportion to what it shows: a blend cut short by another one goes on
## from where it got to, and no weight ever jumps, but into a state that comes at once (a
## blend time of 0). Only weights are given to it: it plays nothing.

## How much each state shows; a state never asked for shows nothing.
var weights: Dictionary[StringName, float] = {}
## The state asked for last, and the time its blend takes, in s.
var _wanted: StringName = &""
var _blend_time: float = 0.0


## Asks for `state`, in `blend_time` s from what is shown now; whether it comes from
## nothing (its clip then starts again): a state still blending out comes back from where
## it is. The state asked for already goes on in the blend time it was asked in.
func go_to(state: StringName, blend_time: float) -> bool:
	if state == _wanted:
		return false
	_wanted = state
	_blend_time = blend_time
	return weight(state) <= 0.0


## Moves the weights `delta` s on: the state asked for comes, the others go.
func advance(delta: float) -> void:
	if _wanted.is_empty():
		return
	var before: float = weight(_wanted)
	var after: float = 1.0
	if _blend_time > 0.0:
		after = minf(before + delta / _blend_time, 1.0)
	var left: float = 1.0 - before
	for state: StringName in weights:
		if state != _wanted:
			weights[state] = weights[state] * (1.0 - after) / left if left > 0.0 else 0.0
	weights[_wanted] = after


## How much `state` shows, from 0 to 1.
func weight(state: StringName) -> float:
	return weights.get(state, 0.0)
