class_name GhostRun
extends RefCounted
## A solo run as the ghost replays it: where the visible body was (its transform in its
## lane) at every fixed step, from the step before the runner first acted to its finish;
## the frame at which it reached each checkpoint; its finish, its time and its style
## score. Frame n is where the body was after n steps of the run: the ghost of a duel
## shows it n steps after GO. Positions, not intents, are replayed: a replay that does not
## depend on the physics. Nothing is saved to disk.

const NOT_FINISHED: int = -1

var frames: Array[Transform3D] = []
var checkpoint_frames: Dictionary[int, int] = {}
var finish_frame: int = NOT_FINISHED
## Its time from the start line to the finish line, and its style score.
var race_steps: int = RaceState.NO_TIME
var style_score: int = 0

## The runner acted at least once: the run has begun.
var _begun: bool = false


## Where the body is after one more fixed step, and whether the runner acted at it.
## Until it first acts, only the last frame is kept: the run begins where it waited.
func record(frame: Transform3D, acted: bool) -> void:
	if is_finished():
		return
	if not _begun and not acted:
		frames.clear()
	_begun = _begun or acted
	frames.append(frame)


## The runner reached the checkpoint `index` at the last frame recorded.
func reach(index: int) -> void:
	if not is_finished() and not checkpoint_frames.has(index):
		checkpoint_frames[index] = frames.size() - 1


## The runner crossed the finish line at the last frame recorded, in `steps` from the
## start line, with `style` points.
func finish(steps: int, style: int) -> void:
	if is_finished() or frames.is_empty():
		return
	finish_frame = frames.size() - 1
	race_steps = steps
	style_score = style


func is_finished() -> bool:
	return finish_frame != NOT_FINISHED


## Where the body was at frame `index`; past the end, where it finished.
func frame(index: int) -> Transform3D:
	return frames[clampi(index, 0, frames.size() - 1)]
