class_name SnapshotBuffer
extends RefCounted
## The snapshots of the runner of the other machine of an online chase (RunnerSnapshot), as
## they arrive, and what is shown of it at each fixed step (docs/specs/online-chase.md,
## decision 3): the runner as it was the delay of the interpolation before the newest
## snapshot, in between the two snapshots around that date, so that it moves on smoothly
## though the packets come irregularly or not at all. The date shown goes on by one step per
## step, a little faster or slower to keep the delay, never back; with nothing newer, the
## newest snapshot stays. A snapshot older than the last one shown, already there, or dated
## absurdly far past the newest is ignored.

## How far past the newest snapshot a new one may be dated, in steps (a minute), and how
## far behind the date it should show the date shown may fall before it jumps there.
const MOST_STEPS_AHEAD: int = 3600
const FARTHEST_BEHIND: float = 60.0
## How much of its gap with the date it should show the date shown makes up at each step,
## and the slowest and the fastest it goes, in steps per step.
const CATCH_UP: float = 0.1
const SLOWEST: float = 0.5
const FASTEST: float = 2.0
## The most snapshots kept.
const KEPT: int = 120

## The snapshot shown last was put somewhere since the one shown before it.
var placed_anew: bool = false

var _snapshots: Array[RunnerSnapshot] = []
## The date shown, in the steps of the other machine; negative before the first.
var _date: float = -1.0
var _last_shown_step: int = -1
var _placement: int = -1


## Keeps each of `snapshots` to be shown, unless it is ignored; how many were kept.
func receive_all(snapshots: Array[RunnerSnapshot]) -> int:
	var kept: int = 0
	for snapshot: RunnerSnapshot in snapshots:
		kept += int(receive(snapshot))
	return kept


## Keeps `snapshot` to be shown, unless it is ignored; whether it was kept.
func receive(snapshot: RunnerSnapshot) -> bool:
	if snapshot.step <= _last_shown_step:
		return false
	if not _snapshots.is_empty() and snapshot.step > newest_step() + MOST_STEPS_AHEAD:
		return false
	var index: int = _snapshots.size()
	while index > 0 and _snapshots[index - 1].step >= snapshot.step:
		if _snapshots[index - 1].step == snapshot.step:
			return false
		index -= 1
	_snapshots.insert(index, snapshot)
	if _snapshots.size() > KEPT:
		_snapshots.pop_front()
	return true


## The date of the newest snapshot kept; -1 before the first.
func newest_step() -> int:
	return -1 if _snapshots.is_empty() else _snapshots.back().step


## The date shown, in the steps of the other machine; negative before the first snapshot.
func date() -> float:
	return _date


## One fixed step on: the runner to show now, `delay` steps before the newest snapshot (in
## steps, fractions allowed); null before the first snapshot.
func show_next(delay: float) -> RunnerSnapshot:
	if _snapshots.is_empty():
		return null
	var wanted: float = newest_step() - delay
	if _date < 0.0 or wanted - _date > FARTHEST_BEHIND:
		_date = wanted
	else:
		_date += clampf(1.0 + (wanted - _date - 1.0) * CATCH_UP, SLOWEST, FASTEST)
	var shown: RunnerSnapshot = _at(_date)
	placed_anew = _placement >= 0 and shown.placement != _placement
	_placement = shown.placement
	return shown


## The runner at the date `at`: between the two snapshots around it; the first or the newest
## outside them. The snapshots before the earlier of the two are dropped.
func _at(at: float) -> RunnerSnapshot:
	var first: RunnerSnapshot = _snapshots.front()
	if at <= first.step:
		_last_shown_step = first.step
		return first
	var newest: RunnerSnapshot = _snapshots.back()
	if at >= newest.step:
		_last_shown_step = newest.step
		_snapshots = [newest]
		return newest
	var after: int = 1
	while _snapshots[after].step < at:
		after += 1
	var from: RunnerSnapshot = _snapshots[after - 1]
	var to: RunnerSnapshot = _snapshots[after]
	_snapshots = _snapshots.slice(after - 1)
	_last_shown_step = from.step
	var weight: float = (at - from.step) / float(to.step - from.step)
	return RunnerSnapshot.between(from, to, weight)
