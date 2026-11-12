extends GutTest
## The test course (game/levels), played without a screen in the real physics. Each
## section is replayed from its checkpoint with a sequence of intents written in
## advance, with the tuning of movement_tuning.tres: a tuning or a course that makes a
## section impossible fails here.

const MAIN_SCENE_SETTING: String = "application/run/main_scene"
const COURSE_SCENE: String = "res://game/levels/test_course.tscn"
const TUNING: String = "res://game/core/movement_tuning.tres"
const TUNING_COPY: String = "user://movement_tuning_under_test.tres"
const RESPAWN: StringName = &"respawn"
const RESTART: StringName = &"restart"
const RELOAD_TUNING: StringName = &"reload_tuning"
const FORWARD: Vector3 = Vector3.FORWARD

## The checkpoints, by the section they open.
const RUN_UP: int = 0
const SHORT_JUMPS: int = 1
const LONG_JUMPS: int = 2
const STEPS: int = 3
const CHECKPOINT_NAMES: Array[String] = ["RunUp", "ShortJumps", "LongJumps", "Steps"]

## Steps during which a jump is held: a little longer than its rise.
const JUMP_STEPS: int = 20
## Steps left to the runner to come to rest after a sequence.
const SETTLE_STEPS: int = 30
## Steps a runner takes to fall under the course and come back.
const FALL_STEPS: int = 90
## A runner that went below this altitude left the top of the blocks: it fell.
const BELOW_THE_BLOCKS: float = -0.5
## Standing at the edge of the first long jump, 20 cm before the void.
const FIRST_LONG_JUMP_EDGE: Vector3 = Vector3(0.0, 0.0, -49.3)
## Beside the course, over the void.
const OVER_THE_VOID: Vector3 = Vector3(12.0, 0.0, -20.0)
const NEAR: float = 0.05


func after_each() -> void:
	if FileAccess.file_exists(TUNING_COPY):
		DirAccess.remove_absolute(TUNING_COPY)


func test_the_main_scene_is_the_test_course() -> void:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	assert_eq(main_scene, COURSE_SCENE)

	var root: Node = (load(main_scene) as PackedScene).instantiate()
	add_child_autofree(root)

	assert_true(root is Course, "the test course")
	assert_true(root.get_node_or_null("Player") is Player, "a runner")
	assert_true(root.get_node_or_null("StartLine") is RaceLine, "a start line")
	assert_true(root.get_node_or_null("FinishLine") is RaceLine, "a finish line")
	for index: int in CHECKPOINT_NAMES.size():
		var checkpoint: Checkpoint = (
			root.get_node_or_null("Checkpoints/" + CHECKPOINT_NAMES[index]) as Checkpoint
		)
		assert_not_null(checkpoint, "a checkpoint for the section %s" % CHECKPOINT_NAMES[index])
		if checkpoint != null:
			assert_eq(checkpoint.index, index, "numbered along the course")


func test_falling_below_the_course_brings_back_to_the_last_checkpoint() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	await _wait_steps(SETTLE_STEPS)
	var checkpoint: Checkpoint = _checkpoint(course, SHORT_JUMPS)
	var steps_before: int = course.race.elapsed_steps

	var elsewhere: Basis = Basis(Vector3.UP, 2.0)
	course.player.teleport(Transform3D(elsewhere, OVER_THE_VOID))
	var lowest: float = await _replay(course, ScriptedIntentSource.new(), FALL_STEPS)

	assert_lt(lowest, BELOW_THE_BLOCKS, "it fell")
	_assert_at_rest_at(course, checkpoint)
	var visual: Node3D = course.player.get_node("Visual") as Node3D
	var onwards: Vector3 = -checkpoint.global_basis.z
	assert_almost_eq(-visual.global_basis.z, onwards, Vector3.ONE * NEAR, "facing what comes next")
	var camera: Camera3D = course.player.camera_rig.get_node("Camera3D") as Camera3D
	var to_camera: Vector3 = camera.global_position - course.player.global_position
	assert_lt(to_camera.normalized().dot(onwards), -0.9, "the camera is in its back")
	assert_eq(course.race.phase, RaceState.Phase.RUNNING, "the run goes on")
	var counted: int = course.race.elapsed_steps - steps_before
	assert_eq(counted, FALL_STEPS, "the timer counted every step of the fall")


func test_returning_to_the_checkpoint_works_at_any_time() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	var checkpoint: Checkpoint = _checkpoint(course, SHORT_JUMPS)

	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, false, 20), 0)
	assert_true(course.player.is_on_floor(), "running on the floor")
	assert_gt(course.player.velocity.length(), 1.0)
	_trigger(RESPAWN)
	await _wait_steps(SETTLE_STEPS)
	_assert_at_rest_at(course, checkpoint)

	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, true, 12), 0)
	assert_false(course.player.is_on_floor(), "in the air")
	assert_gt(course.player.global_position.y, 1.0)
	_trigger(RESPAWN)
	await _wait_steps(SETTLE_STEPS)
	_assert_at_rest_at(course, checkpoint)


## Not a scenario of the spec: the restart action of its decision 14, seen from the
## course (the rule itself is tested in test_race_state.gd).
func test_restarting_the_course_brings_the_runner_back_to_the_start() -> void:
	var course: Course = _add_course()
	_start_at(course, STEPS)
	await _wait_steps(SETTLE_STEPS)
	assert_gt(course.race.elapsed_steps, 0, "the timer is running")

	_trigger(RESTART)
	await _wait_steps(SETTLE_STEPS)

	_assert_at_rest_at(course, _checkpoint(course, RUN_UP))
	assert_eq(course.race.phase, RaceState.Phase.NOT_STARTED, "before the start line again")
	assert_eq(course.race.elapsed_steps, 0, "timer at zero")


func test_the_run_up_section_can_be_cleared() -> void:
	var course: Course = _add_course()
	var run: ScriptedIntentSource = ScriptedIntentSource.new().hold(FORWARD, false, 145)

	var lowest: float = await _replay(course, run)

	assert_eq(course.race.phase, RaceState.Phase.RUNNING, "the start line was crossed")
	assert_eq(course.race.last_checkpoint, SHORT_JUMPS, "the next checkpoint is reached")
	assert_gt(lowest, BELOW_THE_BLOCKS, "without falling")
	assert_true(course.player.is_on_floor(), "and the runner stands on the course")


func test_the_short_jumps_section_can_be_cleared() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	var run: ScriptedIntentSource = ScriptedIntentSource.new()
	run.hold(FORWARD, false, 40).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 23).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 24).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 28)

	var lowest: float = await _replay(course, run)

	assert_eq(course.race.last_checkpoint, LONG_JUMPS, "the next checkpoint is reached")
	assert_gt(lowest, BELOW_THE_BLOCKS, "without falling")
	assert_true(course.player.is_on_floor(), "and the runner stands on the course")


func test_the_long_jumps_section_can_be_cleared() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	var run: ScriptedIntentSource = ScriptedIntentSource.new()
	run.hold(FORWARD, false, 75).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 61).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 29)

	var lowest: float = await _replay(course, run)

	assert_eq(course.race.last_checkpoint, STEPS, "the next checkpoint is reached")
	assert_gt(lowest, BELOW_THE_BLOCKS, "without falling")
	assert_true(course.player.is_on_floor(), "and the runner stands on the course")


func test_a_long_jump_without_run_up_fails() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	course.player.teleport(Transform3D(Basis.IDENTITY, FIRST_LONG_JUMP_EDGE))
	await _wait_steps(SETTLE_STEPS)
	assert_true(course.player.is_on_floor(), "standing at the edge")
	var jump: ScriptedIntentSource = ScriptedIntentSource.new().hold(FORWARD, true, 40)

	var lowest: float = await _replay(course, jump, FALL_STEPS)

	assert_lt(lowest, BELOW_THE_BLOCKS, "it fell into the void")
	assert_eq(course.race.last_checkpoint, LONG_JUMPS, "the far side was not reached")
	_assert_at_rest_at(course, _checkpoint(course, LONG_JUMPS))


func test_the_steps_section_leads_to_the_finish() -> void:
	var course: Course = _add_course()
	_start_at(course, STEPS)
	var run: ScriptedIntentSource = ScriptedIntentSource.new()
	run.hold(FORWARD, false, 43).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 14).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 15).hold(FORWARD, true, JUMP_STEPS)
	run.hold(FORWARD, false, 40)

	var lowest: float = await _replay(course, run)

	assert_eq(course.race.phase, RaceState.Phase.FINISHED, "the finish line was crossed")
	assert_gt(lowest, BELOW_THE_BLOCKS, "without falling")
	assert_true(course.player.is_on_floor(), "and the runner stands on the course")


func test_reloading_the_tuning_applies_the_new_values() -> void:
	var tuning: MovementTuning = (load(TUNING) as MovementTuning).duplicate() as MovementTuning
	assert_eq(ResourceSaver.save(tuning, TUNING_COPY), OK, "a tuning file the test may edit")
	var course: Course = _add_course()
	course.player.apply_tuning(load(TUNING_COPY) as MovementTuning)
	var slower: float = tuning.top_speed / 3.0

	tuning.top_speed = slower
	assert_eq(ResourceSaver.save(tuning, TUNING_COPY), OK, "the file changes on disk")
	_trigger(RELOAD_TUNING)
	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, false, SETTLE_STEPS), 0)

	assert_almost_eq(course.player.tuning.top_speed, slower, 0.001, "the new value is read")
	assert_almost_eq(course.player.velocity.length(), slower, 0.01, "and the runner obeys it")


func _add_course() -> Course:
	var course: Course = (load(COURSE_SCENE) as PackedScene).instantiate() as Course
	add_child_autofree(course)
	return course


func _checkpoint(course: Course, index: int) -> Checkpoint:
	return course.get_node("Checkpoints/" + CHECKPOINT_NAMES[index]) as Checkpoint


## Puts the runner at a checkpoint as if it had run there: the race is on.
func _start_at(course: Course, checkpoint: int) -> void:
	course.race.cross_start_line()
	course.race.reach_checkpoint(checkpoint)
	course.respawn()


func _wait_steps(steps: int) -> void:
	for i: int in steps:
		await get_tree().physics_frame


## Gives the sequence to the runner, waits for it to be played and for the runner to
## settle, and returns the lowest altitude the runner went through.
func _replay(
	course: Course, source: ScriptedIntentSource, settle_steps: int = SETTLE_STEPS
) -> float:
	course.player.intent_source = source
	var lowest: float = course.player.global_position.y
	for i: int in source.length() + settle_steps:
		await get_tree().physics_frame
		lowest = minf(lowest, course.player.global_position.y)
	return lowest


func _assert_at_rest_at(course: Course, checkpoint: Checkpoint) -> void:
	var offset: Vector3 = course.player.global_position - checkpoint.global_position
	assert_lt(offset.length(), NEAR, "at the checkpoint %s" % checkpoint.name)
	assert_lt(course.player.velocity.length(), NEAR, "at rest")


func _trigger(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
