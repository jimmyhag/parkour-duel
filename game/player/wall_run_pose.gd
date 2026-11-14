class_name WallRunPose
extends RefCounted
## How the character's body lies against the wall it runs along
## (docs/specs/animation-polish.md, decision 4): it runs, its whole body rolled about the
## way it runs, through the middle of the body, its feet towards the wall and its head away
## from it; and it is moved across by one offset, from the roll, from how far the wall is
## and from the run it plays (a blend of clips, as fast as the runner goes along the wall),
## that puts the part of its run nearest the wall WALL_GAP from the wall's face: its feet
## brush the wall, no part of it goes behind. The offset follows the roll as it comes and
## goes, and nothing else: no sway from one key of the run to the next. Measured from the
## places of the bones of the clips of the run, it reads no file.

## How far the part of the body nearest the wall stays from its face, in m.
const WALL_GAP: float = 0.05

## For each clip of the run, every place a bone goes through, in the frame of the body
## (across, positive at its right, and up from its feet), in m.
var _runs: Array[PackedVector2Array] = []


## The pose of a body whose clips of the run go each through the places of `runs`, each one
## across (positive at the runner's right) and up from its feet, in m.
static func measure(runs: Array[PackedVector2Array]) -> WallRunPose:
	var pose: WallRunPose = WallRunPose.new()
	pose._runs = runs
	return pose


## Where the body is put, in the frame of the runner facing -Z, rolled by `roll` (radians,
## positive: its head to its left) about the way it runs, through the middle of the
## standing body, and moved across towards the wall its feet point to, the wall being
## `wall_distance` m from the side of the capsule (as far as a wall run allows at most),
## its clips of the run weighed by `weights`. Upright and in place without a roll.
func placed(
	roll: float, wall_distance: float, weights: PackedFloat32Array, tuning: MovementTuning
) -> Transform3D:
	var middle: Vector3 = Vector3.UP * tuning.capsule_height / 2.0
	var turn: Basis = Basis(Vector3.BACK, roll)
	var across: Vector3 = Vector3.RIGHT * offset(roll, wall_distance, weights, tuning)
	return Transform3D(turn, middle - turn * middle + across)


## How far the body is moved across, in m, positive to the runner's right: towards the wall
## its feet point to, as far as puts the part of its run nearest the wall WALL_GAP from it
## once the body has wholly rolled, and as much of that as it has rolled.
func offset(
	roll: float, wall_distance: float, weights: PackedFloat32Array, tuning: MovementTuning
) -> float:
	var full: float = deg_to_rad(tuning.wall_run_body_roll)
	if is_zero_approx(roll) or full <= 0.0:
		return 0.0
	var way: float = signf(roll)
	var gap: float = clampf(wall_distance, 0.0, tuning.wall_run_distance)
	var reached: float = reach(way * full, weights, tuning)
	var room: float = tuning.capsule_radius + gap - WALL_GAP - reached
	return way * minf(absf(roll) / full, 1.0) * room


## How far the run weighed by `weights` reaches, across, towards the wall its feet point
## to, the body rolled by `roll` (not 0) about the middle of the standing body, in place, in
## m from the middle of the runner: the reach of each clip, weighed (the first clip alone
## when nothing weighs).
func reach(roll: float, weights: PackedFloat32Array, tuning: MovementTuning) -> float:
	var total: float = 0.0
	var reached: float = 0.0
	for run: int in _runs.size():
		var weight: float = weights[run] if run < weights.size() else 0.0
		total += weight
		reached += weight * _reach_of(_runs[run], roll, tuning)
	if total <= 0.0:
		return _reach_of(_runs[0], roll, tuning) if not _runs.is_empty() else 0.0
	return reached / total


## How far the places `places` reach towards the wall the feet point to, rolled by `roll`.
static func _reach_of(places: PackedVector2Array, roll: float, tuning: MovementTuning) -> float:
	var middle: float = tuning.capsule_height / 2.0
	var way: float = signf(roll)
	var farthest: float = -INF
	for place: Vector2 in places:
		var across: float = place.x * cos(roll) - (place.y - middle) * sin(roll)
		farthest = maxf(farthest, way * across)
	return farthest if farthest > -INF else 0.0
