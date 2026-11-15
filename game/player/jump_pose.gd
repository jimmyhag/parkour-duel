class_name JumpPose
extends RefCounted
## The pose of the character in a jump (docs/specs/motion-weight.md, decision 6): the clip of
## the jump does not play, it shows where the runner is in the jump
## (RunnerAnimation.jump_position_of), from the take-off to the top of the clip, then to its
## approach of the ground; between two fixed steps, at every frame, in between. Only times
## are given to it: it plays nothing.

## Of each jump, when it is at its top, in s of its file: its hips at their highest.
const TOPS: Dictionary[RunnerAnimation.Clip, float] = {
	RunnerAnimation.Clip.JUMP: 0.37,
	RunnerAnimation.Clip.RUNNING_JUMP: 0.33,
}

## The state of the tree of the jump shown last (empty before the first).
var state: StringName = &""
## Where its clip was at the last two fixed steps, in s from the start of its part.
var _before: float = 0.0
var _now: float = 0.0


## Where the clip of the jump `clip`, of which the part `cut` is kept (from its start to its
## end, in s of its file), is when the runner is at `position` in the jump: in s from the
## start of that part.
static func time_in(clip: RunnerAnimation.Clip, cut: Vector2, position: float) -> float:
	var top: float = RunnerAnimation.TOP_OF_THE_JUMP
	var at: float = lerpf(cut.x, TOPS[clip], position / top)
	if position > top:
		at = lerpf(TOPS[clip], cut.y, (position - top) / (1.0 - top))
	return at - cut.x


## The jump shown by the state `shown` is at `time` at this fixed step; from there at once
## when it comes from nothing (`fresh`) or from another jump.
func follow(shown: StringName, time: float, fresh: bool) -> void:
	_before = time if fresh or shown != state else _now
	_now = time
	state = shown


## Where the clip of the jump is shown, `fraction` (0 to 1) of the way from the last fixed step
## to the next one.
func time_at(fraction: float) -> float:
	return lerpf(_before, _now, fraction)
