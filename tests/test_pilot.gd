extends ReplayTest
## The test pilot (tests/pilot_intent_source.gd), on small courses built here, that it
## has never seen: it must read the world to clear them, and it must be able to fail.
## What must be within or out of the runner's reach is sized from the tuning; the other
## lengths are arbitrary.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const NEAR: float = 0.05
const FORWARD: Vector3 = Vector3.FORWARD


## A small course: blocks laid one after the other along -Z from the origin, with voids
## between them where the test wants, and a goal.
class Track:
	extends Node3D

	const WIDTH: float = 4.0
	## How far the blocks go down under the altitude 0.
	const DEPTH: float = 1.0
	const WORLD_LAYER: int = 1
	const RUNNER_LAYER: int = 2
	const WALL_THICKNESS: float = 1.0

	## How far the course goes along -Z so far.
	var length: float = 0.0

	## Adds a block whose top is at the altitude `top`, `width` wide, and returns the
	## middle of its top.
	func add_block(block_length: float, top: float = 0.0, width: float = WIDTH) -> Vector3:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(width, top + DEPTH, block_length)
		var block: StaticBody3D = StaticBody3D.new()
		block.collision_layer = WORLD_LAYER
		block.add_child(_collider(box))
		block.position = Vector3(0.0, (top - DEPTH) / 2.0, -length - block_length / 2.0)
		add_child(block)
		length += block_length
		return Vector3(0.0, top, block.position.z)

	func add_void(void_length: float) -> void:
		length += void_length

	## Hangs a beam across the course over the point `over`: `beam_length` long, its
	## underside `clearance` above that point, `thickness` thick.
	func add_beam(over: Vector3, beam_length: float, clearance: float, thickness: float) -> void:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(WIDTH, thickness, beam_length)
		var beam: StaticBody3D = StaticBody3D.new()
		beam.collision_layer = WORLD_LAYER
		beam.add_child(_collider(box))
		beam.position = over + Vector3.UP * (clearance + thickness / 2.0)
		add_child(beam)

	## Stands a wall, one block, along the last `wall_length` metres of the course, from
	## under the blocks up to the altitude `top`. Its face, turned towards the middle of
	## the course, stands at `face` across it: a negative `face` puts the wall at the
	## left of a runner going along -Z, a positive one at its right.
	func add_wall(face: float, wall_length: float, top: float) -> void:
		var bottom: float = -DEPTH * 2.0
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(WALL_THICKNESS, top - bottom, wall_length)
		var wall: StaticBody3D = StaticBody3D.new()
		wall.collision_layer = WORLD_LAYER
		wall.add_child(_collider(box))
		var middle: float = face + signf(face) * WALL_THICKNESS / 2.0
		wall.position = Vector3(middle, (top + bottom) / 2.0, -length + wall_length / 2.0)
		add_child(wall)

	## Adds a goal across the course, `width` wide, standing on the point `at`.
	func add_goal(at: Vector3, width: float = WIDTH) -> Area3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(width, WIDTH, DEPTH)
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


## What a test sees of a runner that the pilot leads under a beam.
class UnderTheBeam:
	var run: PilotedRun
	var runner: Player
	## Steps at which the slide was pressed.
	var presses: int = 0
	## Steps, from the first press until the whole body of the runner is out from under
	## the beam, at which the slide was not held.
	var steps_let_go: int = 0
	## Steps at which the whole body of the runner was under the beam, and those of them
	## at which the runner was not low.
	var steps_under: int = 0
	var steps_standing_under: int = 0

	var _beam_middle: float
	var _beam_half_length: float

	## `a_runner` must already be where its run starts. The beam lies across the course,
	## `beam_length` long, its middle at `beam_middle` along the course.
	func _init(
		track: Track, a_runner: Player, goal: Area3D, beam_middle: float, beam_length: float
	) -> void:
		runner = a_runner
		_beam_middle = beam_middle
		_beam_half_length = beam_length / 2.0
		run = PilotedRun.new(runner, goal, track)
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(intent: MoveIntent) -> void:
		var radius: float = runner.tuning.capsule_radius
		# How far past the middle of the beam the runner is: the course goes along -Z.
		var past_the_middle: float = _beam_middle - runner.global_position.z
		var is_out: bool = past_the_middle > _beam_half_length + radius
		presses += int(intent.slide_pressed)
		steps_let_go += int(presses > 0 and not is_out and not intent.slide_held)
		if absf(past_the_middle) < _beam_half_length - radius:
			steps_under += 1
			steps_standing_under += int(not runner.motor.is_low())


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
	assert_eq(run.slide_requests, 0, "and the slide is never asked for: no fall is high")
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


func test_the_pilot_slides_under_a_low_obstacle_it_does_not_know() -> void:
	var over_a_seam: UnderTheBeam = _course_under_a_beam(0.0, 0.0)
	var over_a_crack: UnderTheBeam = _course_under_a_beam(3.0 * Track.WIDTH, 0.85)

	await _play([over_a_seam.run, over_a_crack.run])

	for attempt: UnderTheBeam in [over_a_seam, over_a_crack]:
		var context: String = "over a crack: " if attempt == over_a_crack else "over a seam: "
		var run: PilotedRun = attempt.run
		assert_eq(run.outcome, PilotedRun.Outcome.REACHED, context + "the end is reached")
		assert_gt(run.steps_sliding, 0, context + "by sliding")
		assert_eq(attempt.presses, 1, context + "in one go: a single press of the slide")
		assert_eq(attempt.steps_let_go, 0, context + "held until the runner is out from under")
		assert_gt(attempt.steps_under, 0, context + "the runner went under the beam")
		assert_eq(attempt.steps_standing_under, 0, context + "and was low all the way")
		assert_eq(run.jumps, 0, context + "without a jump")
		var state: RunnerMotor.State = attempt.runner.motor.state
		assert_eq(state, RunnerMotor.State.GROUNDED, context + "and the runner stands at the end")


func test_the_pilot_does_not_slide_without_a_reason() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var start: Vector3 = track.add_block(10.7)
	var goal: Area3D = track.add_goal(track.add_block(14.9))
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the runner ran to the goal")
	assert_eq(run.slide_requests, 0, "without ever asking for the slide")
	assert_eq(run.steps_sliding, 0, "and without sliding")


func test_the_pilot_clears_walls_it_does_not_know() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var tuning: MovementTuning = runner.tuning
	var gap: float = _jump_range(tuning) * 1.3
	# Above any jump, within a mantle.
	var ledge: float = (tuning.jump_height + tuning.mantle_max_height) / 2.0
	var close: float = tuning.capsule_radius + tuning.wall_run_distance / 2.0
	var tall: float = ledge + tuning.capsule_height * 3.0
	var start: Vector3 = track.add_block(7.3)
	track.add_block(6.2, ledge)
	track.add_void(gap)
	track.add_wall(-close, gap, tall)
	track.add_block(6.1, ledge)
	track.add_void(gap)
	track.add_wall(-close, gap, tall)
	track.add_wall(close + _wall_jump_reach(tuning) * 3.0 / 4.0, gap, tall)
	var wide: float = Track.WIDTH * 3.0
	var end: Vector3 = track.add_block(9.6, ledge, wide)
	var goal: Area3D = track.add_goal(end, wide)
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the end is reached, without falling")
	assert_almost_eq(runner.global_position.y, end.y, NEAR, "the runner stands on the last block")
	assert_gt(run.steps_mantling, 0, "it mantled")
	assert_gt(run.steps_wall_running, 0, "ran along a wall")
	assert_gt(run.wall_jumps, 0, "and jumped off one")


func test_the_pilot_does_not_wall_run_without_a_reason() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var tuning: MovementTuning = runner.tuning
	var start: Vector3 = track.add_block(11.2)
	var goal: Area3D = track.add_goal(track.add_block(13.7))
	var close: float = tuning.capsule_radius + tuning.wall_run_distance / 2.0
	track.add_wall(-close, track.length, tuning.capsule_height * 3.0)
	runner.teleport(Transform3D(Basis.IDENTITY, start))

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the runner ran to the goal")
	assert_eq(run.steps_in_the_air, 0, "without ever leaving the floor")
	assert_eq(run.jumps, 0, "without a jump")
	assert_eq(run.steps_wall_running, 0, "and without running along the wall")


func test_the_pilot_releases_the_jump_so_as_not_to_overshoot_its_landing() -> void:
	var track: Track = _add_track()
	var runner: Player = _add_runner(track)
	var tuning: MovementTuning = runner.tuning
	var fast: float = tuning.top_speed * 1.5
	# The range of a held jump at that speed: the short block ends well before it.
	var held_range: float = _jump_range(tuning) * fast / tuning.top_speed
	var start: Vector3 = track.add_block(2.3)
	track.add_void(held_range / 4.0)
	var short_block: Vector3 = track.add_block(held_range / 2.0)
	var goal: Area3D = track.add_goal(short_block)
	runner.teleport(Transform3D(Basis.IDENTITY, start))
	runner.velocity = FORWARD * fast
	var released: Array[bool] = [false]
	runner.stepped.connect(
		func(intent: MoveIntent) -> void:
			var rising: bool = runner.motor.state == RunnerMotor.State.RISING
			released[0] = released[0] or (rising and not intent.jump_held)
	)

	var run: PilotedRun = await _pilot_to(runner, goal, track)

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the runner lands on the short block")
	assert_almost_eq(runner.global_position.y, short_block.y, NEAR, "and stands on it")
	assert_eq(run.jumps, 1, "with one jump")
	assert_true(released[0], "released before its top")


## A small course barred by a beam too low to stand under, high enough for a slide and
## too tall to jump over, `aside` metres beside the usual place, with a runner for the
## pilot to lead under it. Under the beam the floor is cut by a crack as wide as
## `crack_share` of the body of the runner: at 0, two blocks that touch.
func _course_under_a_beam(aside: float, crack_share: float) -> UnderTheBeam:
	var track: Track = _add_track()
	track.position.x = aside
	var runner: Player = _add_runner(track)
	var tuning: MovementTuning = runner.tuning
	var start: Vector3 = track.add_block(12.3)
	var before_the_crack: Vector3 = track.add_block(2.3)
	track.add_void(crack_share * 2.0 * tuning.capsule_radius)
	var after_the_crack: Vector3 = track.add_block(2.3)
	var under_the_beam: Vector3 = (before_the_crack + after_the_crack) / 2.0
	var clearance: float = (tuning.slide_capsule_height + tuning.capsule_height) / 2.0
	var beam_length: float = 2.7
	track.add_beam(under_the_beam, beam_length, clearance, tuning.jump_height * 2.0)
	var goal: Area3D = track.add_goal(track.add_block(9.8))
	runner.teleport(Transform3D(Basis.IDENTITY, track.position + start))
	return UnderTheBeam.new(track, runner, goal, under_the_beam.z, beam_length)


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


## How far a jump off a wall carries a runner away from it before it falls back to the
## height it jumped from, from the tuning.
func _wall_jump_reach(tuning: MovementTuning) -> float:
	var rise_seconds: float = tuning.wall_jump_up_speed / tuning.rise_gravity
	var top: float = tuning.wall_jump_up_speed * rise_seconds / 2.0
	var fall_seconds: float = sqrt(2.0 * top / tuning.fall_gravity)
	return tuning.wall_jump_away_speed * (rise_seconds + fall_seconds)
