class_name WallRunPose
extends RefCounted
## How the clip of the wall run is laid against the wall the runner runs along
## (docs/specs/character-animations.md, decision 12), from the bones of the clip, measured,
## not assumed. Its wall is on the side of its feet, its head leaning away. At each frame,
## its body is moved across, towards that side, so that its bone nearest the wall stays on
## one plane, the clip's own wall: a foot planted on it, most of the time. The clip is
## mirrored along a wall on the other side, and the character is moved across so that
## this plane stands a few centimetres from the real wall: no bone behind it, the feet
## almost touching it. Only measures are given to it: it reads no file.

## How far the bone nearest the wall stays from its face, in m: the feet almost touch it.
const WALL_GAP: float = 0.05

## The side of the clip's wall, the side of its feet: NONE when they are not on one side
## of the head.
var side: RunnerAnimation.WallSide = RunnerAnimation.WallSide.NONE
## At each frame of the clip, how far its body is moved towards its wall.
var shifts: PackedFloat32Array = []
## How far from the middle of the body, once moved, the clip's wall is.
var reach: float = 0.0


## The pose measured from `frames`: at each frame of the clip, the position across of each
## of its bones, positive at the runner's right; `feet` and `head` are bone indices. The
## side of its wall is the side where its feet are, on average over the clip, from its
## head.
static func measure(
	frames: Array[PackedFloat32Array], feet: PackedInt32Array, head: int
) -> WallRunPose:
	var pose: WallRunPose = WallRunPose.new()
	var feet_from_the_head: float = 0.0
	for across: PackedFloat32Array in frames:
		var feet_across: float = 0.0
		for foot: int in feet:
			feet_across += across[foot]
		feet_from_the_head += feet_across / feet.size() - across[head]
	if is_zero_approx(feet_from_the_head):
		return pose
	var at_the_right: bool = feet_from_the_head > 0.0
	pose.side = RunnerAnimation.WallSide.RIGHT if at_the_right else RunnerAnimation.WallSide.LEFT
	var towards: float = way(pose.side)
	var nearest: PackedFloat32Array = []
	for across: PackedFloat32Array in frames:
		var farthest: float = -INF
		for bone: float in across:
			farthest = maxf(farthest, bone * towards)
		nearest.append(farthest)
		pose.reach = maxf(pose.reach, farthest)
	for farthest: float in nearest:
		pose.shifts.append(pose.reach - farthest)
	return pose


## Whether the clip plays mirrored along a wall at `wall_side`: when its own wall is on the
## other side.
func mirrors(wall_side: RunnerAnimation.WallSide) -> bool:
	if wall_side == RunnerAnimation.WallSide.NONE or side == RunnerAnimation.WallSide.NONE:
		return false
	return wall_side != side


## How far towards the wall the character is moved, in m, the clip being `scale` times as
## large as measured, beside a wall `wall_distance` m from the side of the capsule (as far
## as a wall run allows at most): what puts the clip's wall WALL_GAP from the real one.
## Nothing without a side.
func offset(scale: float, wall_distance: float, tuning: MovementTuning) -> float:
	if side == RunnerAnimation.WallSide.NONE:
		return 0.0
	var gap: float = clampf(wall_distance, 0.0, tuning.wall_run_distance)
	return tuning.capsule_radius + gap - WALL_GAP - reach * scale


## The way across of `towards`: 1 at the runner's right, -1 at its left.
static func way(towards: RunnerAnimation.WallSide) -> float:
	return 1.0 if towards == RunnerAnimation.WallSide.RIGHT else -1.0
