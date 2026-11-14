extends CourseTest
## The test course (game/levels), played without a screen in the real physics. Each
## section is run from its checkpoint by the test pilot, which looks at the world and
## decides at every step: with the tuning of movement_tuning.tres, then with one value
## of it changed by 10 %. A tuning or a course that makes a section impossible fails
## here. The sections that ask for the ground moves have their own tests in
## test_course_ground.gd. The tests of this file run faster than real time, with the
## same fixed step of 1/60 s (see ReplayTest).

const MAIN_SCENE_SETTING: String = "application/run/main_scene"
const TUNING: String = "res://game/core/movement_tuning.tres"
const TUNING_COPY: String = "user://movement_tuning_under_test.tres"
const RESPAWN: StringName = &"respawn"
const RESTART: StringName = &"restart"
const RELOAD_TUNING: StringName = &"reload_tuning"
const FORWARD: Vector3 = Vector3.FORWARD

## The tuning range in which every section stays clearable: one value at a time, 10 %
## more, then 10 % less.
const VARIANT_FACTORS: Array[float] = [1.1, 0.9]

## Steps a runner takes to fall under the course and come back.
const FALL_STEPS: int = 90
## A runner that went below this altitude left the top of the blocks: it fell.
const BELOW_THE_BLOCKS: float = -0.5
## Standing at the edge of the first long jump, 20 cm before the void.
const FIRST_LONG_JUMP_EDGE: Vector3 = Vector3(0.0, 0.0, -49.3)
## Beside the course, over the void.
const OVER_THE_VOID: Vector3 = Vector3(12.0, 0.0, -20.0)
## Steps during which a pressed action stays down.
const TAP_STEPS: int = 3


func after_each() -> void:
	Input.action_release(RESPAWN)
	Input.action_release(RESTART)
	if FileAccess.file_exists(TUNING_COPY):
		DirAccess.remove_absolute(TUNING_COPY)


func test_the_test_course_has_its_runner_lines_and_checkpoints() -> void:
	# The game opens on its start screen (test_course_menus.gd), which starts this course
	# for solo practice.
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	assert_ne(main_scene, COURSE_SCENE, "no longer the main scene")

	var root: Node = (load(COURSE_SCENE) as PackedScene).instantiate()
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
	var inputs: IntentSource = course.player.intent_source

	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, false, 20), 0)
	assert_true(course.player.is_on_floor(), "running on the floor")
	assert_gt(course.player.velocity.length(), 1.0)
	course.player.intent_source = inputs
	await _tap(RESPAWN)
	await _wait_steps(SETTLE_STEPS)
	_assert_at_rest_at(course, checkpoint)

	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, true, 12), 0)
	assert_false(course.player.is_on_floor(), "in the air")
	assert_gt(course.player.global_position.y, 1.0)
	course.player.intent_source = inputs
	await _tap(RESPAWN)
	await _wait_steps(SETTLE_STEPS)
	_assert_at_rest_at(course, checkpoint)


func test_a_respawn_does_not_touch_the_timer() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	var checkpoint: Checkpoint = _checkpoint(course, SHORT_JUMPS)
	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, false, 20), 0)
	assert_gt(_distance_to(course, checkpoint), 1.0, "the runner left the checkpoint")
	var steps_before: int = course.race.elapsed_steps

	var back: ScriptedIntentSource = ScriptedIntentSource.new().request_respawn()
	await _replay(course, back)

	_assert_at_rest_at(course, checkpoint)
	assert_eq(course.race.phase, RaceState.Phase.RUNNING, "the run goes on")
	var counted: int = course.race.elapsed_steps - steps_before
	assert_eq(counted, back.length() + SETTLE_STEPS, "the timer counted every step, no more")


func test_a_sequence_of_intents_can_request_the_return_to_the_checkpoint() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	var checkpoint: Checkpoint = _checkpoint(course, LONG_JUMPS)
	await _replay(course, ScriptedIntentSource.new().hold(FORWARD, false, 40), 0)
	assert_gt(_distance_to(course, checkpoint), 3.0, "far from the last checkpoint")

	await _replay(course, ScriptedIntentSource.new().request_respawn())

	_assert_at_rest_at(course, checkpoint)
	assert_false(Input.is_action_pressed(RESPAWN), "no key was involved")


func test_restarting_the_course_brings_the_runner_back_to_the_start() -> void:
	var course: Course = _add_course()
	_start_at(course, STEPS)
	await _wait_steps(SETTLE_STEPS)
	assert_gt(course.race.elapsed_steps, 0, "the timer is running")

	await _tap(RESTART)
	await _wait_steps(SETTLE_STEPS)

	_assert_at_rest_at(course, _checkpoint(course, RUN_UP))
	assert_eq(course.race.phase, RaceState.Phase.NOT_STARTED, "before the start line again")
	assert_eq(course.race.elapsed_steps, 0, "timer at zero")


func test_the_run_up_section_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(RUN_UP)

	await _play([attempt.run])

	_assert_cleared(attempt)


func test_the_short_jumps_section_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(SHORT_JUMPS)

	await _play([attempt.run])

	_assert_cleared(attempt)


func test_the_long_jumps_section_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(LONG_JUMPS)

	await _play([attempt.run])

	_assert_cleared(attempt)


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


func test_the_steps_section_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(STEPS)

	await _play([attempt.run])

	_assert_cleared(attempt)


func test_the_sections_can_be_cleared_with_a_top_speed_changed_by_10_percent() -> void:
	var variants: Array[MovementTuning] = []
	for factor: float in VARIANT_FACTORS:
		var variant: MovementTuning = _copy_of_the_tuning("top speed x %.1f" % factor)
		variant.top_speed *= factor
		variants.append(variant)

	await _assert_every_section_is_cleared_with(variants)


func test_the_sections_can_be_cleared_with_a_rise_gravity_changed_by_10_percent() -> void:
	var variants: Array[MovementTuning] = []
	for factor: float in VARIANT_FACTORS:
		var variant: MovementTuning = _copy_of_the_tuning("rise gravity x %.1f" % factor)
		variant.rise_gravity *= factor
		variants.append(variant)

	await _assert_every_section_is_cleared_with(variants)


func test_the_sections_can_be_cleared_with_a_fall_gravity_changed_by_10_percent() -> void:
	var variants: Array[MovementTuning] = []
	for factor: float in VARIANT_FACTORS:
		var variant: MovementTuning = _copy_of_the_tuning("fall gravity x %.1f" % factor)
		variant.fall_gravity *= factor
		variants.append(variant)

	await _assert_every_section_is_cleared_with(variants)


func test_the_sections_can_be_cleared_with_a_jump_height_changed_by_10_percent() -> void:
	var variants: Array[MovementTuning] = []
	for factor: float in VARIANT_FACTORS:
		var variant: MovementTuning = _copy_of_the_tuning("jump height x %.1f" % factor)
		variant.jump_height *= factor
		variants.append(variant)

	await _assert_every_section_is_cleared_with(variants)


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


## The tuning of the project in a copy in memory, named after what a test changes in
## it: nothing is written to the file.
func _copy_of_the_tuning(variant_name: String) -> MovementTuning:
	var variant: MovementTuning = (load(TUNING) as MovementTuning).duplicate() as MovementTuning
	variant.resource_name = variant_name
	return variant


## Plays every section with each variant of the tuning and checks that every one is
## cleared. The runs are played at the same time, each on its own course: the courses
## stand side by side, one course width of void between two of them.
func _assert_every_section_is_cleared_with(variants: Array[MovementTuning]) -> void:
	var attempts: Array[SectionRun] = []
	var runs: Array[PilotedRun] = []
	var spacing: float = 0.0
	for variant: MovementTuning in variants:
		for section: int in CHECKPOINT_NAMES.size():
			var attempt: SectionRun = _section_run(section, variant, attempts.size() * spacing)
			if attempts.is_empty():
				spacing = 2.0 * PilotedRun.bounds_of_the_blocks(attempt.course).size.x
			attempts.append(attempt)
			runs.append(attempt.run)

	await _play(runs)

	for attempt: SectionRun in attempts:
		_assert_cleared(attempt)


## Holds an action of the input map down for a few fixed steps, as a finger would.
func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _wait_steps(TAP_STEPS)
	Input.action_release(action)


## Sends the press of an action to the nodes that listen to input events.
func _trigger(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
