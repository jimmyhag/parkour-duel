extends CourseTest
## The four sections of the test course (game/levels) that ask for the wall moves: the
## ledge, climbed by a mantle; the gap along a wall, crossed by a wall run; the zigzag
## between two walls, crossed by wall jumps; and the final combination, which mixes the
## moves up to the finish line. Played without a screen in the real physics by the test
## pilot, faster than real time with the same fixed step of 1/60 s (see ReplayTest).

const MANTLING: RunnerMotor.State = RunnerMotor.State.MANTLING
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
const ANGLE_TOLERANCE: float = 0.01


## What a test sees of the body one sees of a runner: how far it leaned to its left
## (positive) or to its right while it ran along a wall, and where the wall was.
class Lean:
	var leftmost: float = 0.0
	var rightmost: float = 0.0
	## A wall run along a wall at the runner's left, and one at its right.
	var ran_along_a_left_wall: bool = false
	var ran_along_a_right_wall: bool = false

	var _runner: Player
	var _visual: Node3D

	func _init(runner: Player) -> void:
		_runner = runner
		_visual = runner.get_node("Visual") as Node3D
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		var away: Vector3 = _runner.motor.wall_run_normal()
		if away.is_zero_approx():
			return
		var right: Vector3 = -_visual.global_basis.z.cross(Vector3.UP)
		ran_along_a_left_wall = ran_along_a_left_wall or away.dot(right) > 0.0
		ran_along_a_right_wall = ran_along_a_right_wall or away.dot(right) < 0.0
		leftmost = maxf(leftmost, _visual.rotation.z)
		rightmost = minf(rightmost, _visual.rotation.z)


func test_the_ledge_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(LEDGE)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(attempt.run.steps_mantling, 0, "the runner mantled")


func test_the_gap_can_be_cleared_by_wall_running() -> void:
	var attempt: SectionRun = _section_run(WALL_RUN)
	var runner: Player = attempt.course.player
	var lean: Lean = Lean.new(runner)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(attempt.run.steps_wall_running, 0, "the runner ran along the wall")
	# The capsule one sees leans towards the wall, then straightens up.
	var tuned: float = deg_to_rad(runner.tuning.wall_run_lean)
	assert_true(lean.ran_along_a_left_wall, "the wall was at the runner's left")
	assert_almost_eq(lean.leftmost, tuned, ANGLE_TOLERANCE, "it leaned to its left, towards it")
	assert_almost_eq(lean.rightmost, 0.0, ANGLE_TOLERANCE, "and never to its right")
	var visual: Node3D = runner.get_node("Visual") as Node3D
	assert_almost_eq(visual.rotation.z, 0.0, ANGLE_TOLERANCE, "upright again at the end")


func test_the_zigzag_can_be_cleared_by_wall_jumps() -> void:
	var attempt: SectionRun = _section_run(ZIGZAG)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(attempt.run.wall_jumps, 1, "the runner jumped from wall to wall")


func test_the_final_combination_leads_to_the_finish() -> void:
	var attempt: SectionRun = _section_run(FINAL)

	await _play([attempt.run])

	_assert_cleared(attempt)
	var run: PilotedRun = attempt.run
	assert_gt(run.steps_sliding, 0, "on the way, the runner slid")
	assert_gt(run.steps_wall_running, 0, "ran along a wall")
	assert_gt(run.steps_mantling, 0, "and mantled")


func test_returning_to_the_checkpoint_works_from_the_mantle_and_the_wall_run() -> void:
	var cases: Array[String] = ["mantle", "wall run", "flight of a wall jump"]
	var sections: Array[int] = [LEDGE, WALL_RUN, ZIGZAG]
	var spacing: float = 0.0
	for index: int in cases.size():
		var context: String = cases[index]
		var section: int = sections[index]
		var attempt: SectionRun = _section_run(section, null, index * spacing)
		spacing = 2.0 * PilotedRun.bounds_of_the_blocks(attempt.course).size.x
		var runner: Player = attempt.course.player
		var standing: float = runner.tuning.capsule_height

		while not _is_in(runner, index) and not attempt.run.is_over:
			await get_tree().physics_frame
			attempt.run.observe_step()
		assert_true(_is_in(runner, index), "the pilot led the runner into the " + context)

		runner.intent_source = ScriptedIntentSource.new().request_respawn()
		await _wait_steps(SETTLE_STEPS)

		_assert_at_rest_at(attempt.course, _checkpoint(attempt.course, section))
		var grounded: RunnerMotor.State = RunnerMotor.State.GROUNDED
		assert_eq(runner.motor.state, grounded, "after the %s: standing" % context)
		var collider: CollisionShape3D = runner.get_node("CollisionShape3D") as CollisionShape3D
		var height: float = (collider.shape as CapsuleShape3D).height
		assert_almost_eq(height, standing, NEAR, "after the %s: its capsule stands" % context)
		var visual: Node3D = runner.get_node("Visual") as Node3D
		assert_almost_eq(visual.rotation.z, 0.0, ANGLE_TOLERANCE, "and does not lean")


## Whether the runner is in the move of the case `index`: a mantle, a wall run, or the
## flight that follows a wall jump.
func _is_in(runner: Player, index: int) -> bool:
	match index:
		0:
			return runner.motor.state == MANTLING
		1:
			return runner.motor.state == WALL_RUNNING
	return runner.motor.jumped_off_a_wall
