class_name WallRun
extends RefCounted
## Whether the wall beside the runner, as its facts tell of it, may be run along: what the
## motor reads before it starts a wall run, and at every step of one.


## Whether a runner that observed `facts`, going at `velocity` and pushing `direction`, may
## start a wall run along the wall beside it, unless it is `refused`: a wall that can be run
## along (runnable), high enough above the ground, at a speed along it enough to start (what
## goes towards the wall does not count: too steep an approach gives no wall run, and leaves
## the wall free), and the runner pushes, anywhere but away from the wall. The speed along
## the wall is what tells a wall run from a mantle on a face pushed into.
static func starts(
	facts: RunnerFacts, velocity: Vector3, direction: Vector3, refused: int, tuning: MovementTuning
) -> bool:
	if facts.wall_id == RunnerFacts.NO_WALL or facts.wall_id == refused:
		return false
	if not runnable(facts, tuning):
		return false
	if facts.ground_clearance < tuning.wall_run_min_height:
		return false
	var away: Vector3 = Vector3(facts.wall_normal.x, 0.0, facts.wall_normal.z).normalized()
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var along: Vector3 = horizontal - away * horizontal.dot(away)
	if along.length() < tuning.wall_run_start_speed:
		return false
	# Any push but one away from the wall: along it, towards it or straight into it.
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z)
	return not wish.is_zero_approx() and not Push.away(direction, away, tuning.push_split_angle)


## Whether the wall `facts` tell of is close enough, near enough to vertical and tall
## enough to be run along.
static func runnable(facts: RunnerFacts, tuning: MovementTuning) -> bool:
	if facts.wall_normal.is_zero_approx():
		return false
	if facts.wall_distance > tuning.wall_run_distance:
		return false
	if facts.wall_height < tuning.wall_run_min_wall_height:
		return false
	var tilt: float = absf(facts.wall_normal.normalized().y)
	return tilt <= sin(deg_to_rad(tuning.wall_run_max_tilt))
