class_name CourseTest
extends ReplayTest
## Base of the test scripts that play the test course (game/levels) without a screen:
## where its sections are, how a runner is put at one of them, and what a section
## cleared by the test pilot shows.

const COURSE_SCENE: String = "res://game/levels/test_course.tscn"

## The checkpoints, by the section they open.
const RUN_UP: int = 0
const SHORT_JUMPS: int = 1
const LONG_JUMPS: int = 2
const STEPS: int = 3
const LOW_PASSAGE: int = 4
const BIG_DROP: int = 5
const CHECKPOINT_NAMES: Array[String] = [
	"RunUp", "ShortJumps", "LongJumps", "Steps", "LowPassage", "BigDrop"
]

## Steps left to the runner to come to rest after a sequence.
const SETTLE_STEPS: int = 30
const NEAR: float = 0.05


## One section of a course of its own, run by the test pilot.
class SectionRun:
	var course: Course
	var section: int
	var run: PilotedRun
	## Where the section ends: the next checkpoint, or the finish line.
	var goal: Area3D
	## The tuning the runner obeys instead of the one of the project, if any.
	var variant: MovementTuning


## Adds a test course, `aside` metres beside the place where the scene puts it.
func _add_course(aside: float = 0.0) -> Course:
	var course: Course = (load(COURSE_SCENE) as PackedScene).instantiate() as Course
	course.position.x = aside
	add_child_autofree(course)
	return course


func _checkpoint(course: Course, index: int) -> Checkpoint:
	return course.get_node("Checkpoints/" + CHECKPOINT_NAMES[index]) as Checkpoint


## Puts the runner at a checkpoint as if it had run there: the race is on.
func _start_at(course: Course, checkpoint: int) -> void:
	course.race.cross_start_line()
	course.race.reach_checkpoint(checkpoint)
	course.respawn()


## A fresh course, `aside` metres beside the usual place, whose runner waits at the
## checkpoint of `section` for the test pilot to lead it to the end of the section: the
## next checkpoint, or the finish line after the last one. With a `variant`, the runner
## obeys it instead of the tuning of the project.
func _section_run(section: int, variant: MovementTuning = null, aside: float = 0.0) -> SectionRun:
	var attempt: SectionRun = SectionRun.new()
	attempt.section = section
	attempt.variant = variant
	attempt.course = _add_course(aside)
	if variant != null:
		attempt.course.player.apply_tuning(variant)
	# The run-up is played as the game starts: before the start line, race not started.
	if section != RUN_UP:
		_start_at(attempt.course, section)
	var goal: Area3D = attempt.course.get_node("FinishLine") as RaceLine
	if section + 1 < CHECKPOINT_NAMES.size():
		goal = _checkpoint(attempt.course, section + 1)
	attempt.goal = goal
	attempt.run = PilotedRun.new(attempt.course.player, goal, attempt.course)
	return attempt


## What a cleared section shows: the runner reached the end of the section without
## falling and stands there, on the ground of its goal and no lower, and the race
## followed.
func _assert_cleared(attempt: SectionRun) -> void:
	var tuning_name: String = "tuning of the project"
	if attempt.variant != null:
		tuning_name = attempt.variant.resource_name
	var context: String = "%s, %s: " % [CHECKPOINT_NAMES[attempt.section], tuning_name]
	var race: RaceState = attempt.course.race
	var runner: Player = attempt.course.player
	if attempt.variant != null:
		assert_same(runner.motor.tuning, attempt.variant, context + "the runner obeys the variant")
	var reached: PilotedRun.Outcome = PilotedRun.Outcome.REACHED
	assert_eq(attempt.run.outcome, reached, context + "the goal is reached without falling")
	assert_true(runner.is_on_floor(), context + "and the runner stands on the course")
	var above_its_goal: float = runner.global_position.y - attempt.goal.global_position.y
	assert_almost_eq(above_its_goal, 0.0, NEAR, context + "at the altitude of its goal")
	if attempt.section + 1 < CHECKPOINT_NAMES.size():
		assert_eq(race.phase, RaceState.Phase.RUNNING, context + "the race is on")
		var next: int = attempt.section + 1
		assert_eq(race.last_checkpoint, next, context + "the next checkpoint is reached")
	else:
		assert_eq(race.phase, RaceState.Phase.FINISHED, context + "the finish line was crossed")


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
	var step: float = course.player.get_physics_process_delta_time()
	assert_almost_eq(step, 1.0 / STEPS_PER_SECOND, 0.000001, "a fixed step lasts 1/60 s")
	return lowest


func _distance_to(course: Course, checkpoint: Checkpoint) -> float:
	return course.player.global_position.distance_to(checkpoint.global_position)


func _assert_at_rest_at(course: Course, checkpoint: Checkpoint) -> void:
	assert_lt(_distance_to(course, checkpoint), NEAR, "at the checkpoint %s" % checkpoint.name)
	assert_lt(course.player.velocity.length(), NEAR, "at rest")
