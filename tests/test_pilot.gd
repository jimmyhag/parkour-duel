extends ReplayTest
## The test pilot (tests/pilot_intent_source.gd), on small courses built here, that it
## has never seen: it must read the world to clear them, and it must be able to fail.
## What must be within or out of the runner's reach is sized from the tuning; the other
## lengths are arbitrary.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const NEAR: float = 0.05


## A small course: blocks laid one after the other along -Z from the origin, with voids
## between them where the test wants, and a goal.
class Track:
	extends Node3D

	const WIDTH: float = 4.0
	## How far the blocks go down under the altitude 0.
	const DEPTH: float = 1.0
	const WORLD_LAYER: int = 1
	const RUNNER_LAYER: int = 2

	## How far the course goes along -Z so far.
	var length: float = 0.0

	## Adds a block whose top is at the altitude `top`, and returns the middle of its top.
	func add_block(block_length: float, top: float = 0.0) -> Vector3:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(WIDTH, top + DEPTH, block_length)
		var block: StaticBody3D = StaticBody3D.new()
		block.collision_layer = WORLD_LAYER
		block.add_child(_collider(box))
		block.position = Vector3(0.0, (top - DEPTH) / 2.0, -length - block_length / 2.0)
		add_child(block)
		length += block_length
		return Vector3(0.0, top, block.position.z)

	func add_void(void_length: float) -> void:
		length += void_length

	## Adds a goal across the course, standing on the point `at`.
	func add_goal(at: Vector3) -> Area3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(WIDTH, WIDTH, DEPTH)
		var goal: Area3D = Area3D.new()
		goal.collision_layer = 0
		goal.collision_mask = RUNNER_LAYER
		goal.monitorable = false
		goal.add_child(_collider(box))
		goal.position = at + Vector3.UP * WIDTH / 2.0
		add_child(goal)
		return goal

	func _collider(shape: Shape3D) -> CollisionShape3D:
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = shape
		return collider


func test_the_pilot_clears_a_course_it_does_not_know() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var jump_height: float = runner.tuning.jump_height
	var start: Vector3 = track.add_block(7.3)
	track.add_void(_jump_range(runner.tuning) / 2.0)
	var landing: Vector3 = track.add_block(8.6, -jump_height / 4.0)
	var end: Vector3 = track.add_block(6.4, landing.y + jump_height / 2.0)
	var goal: Area3D = track.add_goal(end)
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the end is reached, without falling")
	assert_eq(run.jumps, 2, "one jump over the void, one onto the step, no other")
	assert_almost_eq(runner.global_position.y, end.y, NEAR, "and the runner stands on the step")


func test_an_impassable_gap_stops_the_pilot() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var start: Vector3 = track.add_block(7.3)
	track.add_void(_jump_range(runner.tuning) * 2.0)
	var goal: Area3D = track.add_goal(track.add_block(6.4))
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.FELL, "the runner fell")
	assert_false(run.goal_reached, "and the end is not reached")
	assert_eq(run.jumps, 1, "although the pilot jumped where the floor stops")


func test_the_pilot_does_not_jump_without_a_reason() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var start: Vector3 = track.add_block(11.2)
	# A second block at the same height: the floor goes on over the joint, and well past
	# the goal.
	var goal: Area3D = track.add_goal(track.add_block(13.7))
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the runner ran to the goal")
	assert_eq(run.jumps, 0, "without a jump")
	assert_eq(run.steps_in_the_air, 0, "and without ever leaving the floor")


func test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var start: Vector3 = track.add_block(9.4)
	var goal: Area3D = track.add_goal(track.add_block(5.1, runner.tuning.jump_height * 2.0))
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.OUT_OF_STEPS, "the wall stops the runner")
	assert_eq(run.jumps, 0, "and the pilot does not jump at it")
	assert_almost_eq(runner.global_position.y, start.y, NEAR, "it stands at the foot of the wall")


func _add_track() -> Track:
	var track: Track = Track.new()
	add_child_autofree(track)
	return track


func _add_runner(track: Track) -> Player:
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	track.add_child(runner)
	return runner


## How far a held jump carries a runner at top speed over level ground, from the tuning.
func _jump_range(tuning: MovementTuning) -> float:
	var take_off_speed: float = sqrt(2.0 * tuning.rise_gravity * tuning.jump_height)
	var rise_seconds: float = take_off_speed / tuning.rise_gravity
	var fall_seconds: float = sqrt(2.0 * tuning.jump_height / tuning.fall_gravity)
	return tuning.top_speed * (rise_seconds + fall_seconds)
