extends CourseTest
## The flow on the test course (game/levels): what the course gives it (the moves of its
## runner, the returns to a checkpoint, the restarts) and the sections that must stay
## clearable at the speed of the highest tier. Played without a screen in the real
## physics, faster than real time with the same fixed step of 1/60 s (see ReplayTest).

const WALL_RUN_MOVE: RunnerEvent.Kind = RunnerEvent.Kind.WALL_RUN
const WALL_JUMP_MOVE: RunnerEvent.Kind = RunnerEvent.Kind.WALL_JUMP
## The sections a faster runner could overshoot.
const FAST_SECTIONS: Array[int] = [LONG_JUMPS, WALL_RUN, ZIGZAG, FINAL]
const TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
## The first step of the steps section: a block 5 m deep, whose face stands across the
## way of a runner coming from the checkpoint of the section.
const FIRST_STEP: String = "Blocks/Step1"
## Steps a runner from the checkpoint of the steps section takes to reach that face and
## stay against it.
const TO_THE_FIRST_STEP: int = 150
## The stop duration of the tuning of the project (1 s), in fixed steps at 60 per second.
const STOP_STEPS: int = 60


## What a test sees of the flow of a runner, step by step: the highest its gauge went,
## and the wall runs it counted.
class FlowWatch:
	var highest_gauge: float = 0.0
	var wall_runs: int = 0

	var _flow: FlowState
	var _moves_seen: int = 0

	func _init(course: Course) -> void:
		_flow = course.flow
		course.player.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		highest_gauge = maxf(highest_gauge, _flow.gauge)
		if _flow.moves_counted > _moves_seen and _flow.last_move == WALL_RUN_MOVE:
			wall_runs += 1
		_moves_seen = _flow.moves_counted


## Keeps the speed bonus of the highest tier on a runner, whatever its gauge, and sees
## how fast it went.
class FullSpeed:
	var fastest: float = 0.0

	var _runner: Player
	var _bonus: float

	func _init(runner: Player) -> void:
		_runner = runner
		var bonuses: Array[float] = runner.tuning.flow_tier_speed_bonus
		_bonus = bonuses[runner.tuning.flow_tier_count - 1]
		_runner.motor.top_speed_bonus = _bonus
		# After the course, which gives the motor the bonus of the gauge at every step.
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		_runner.motor.top_speed_bonus = _bonus
		var speed: float = Vector2(_runner.velocity.x, _runner.velocity.z).length()
		fastest = maxf(fastest, speed)


func test_crossing_the_finish_line_freezes_the_flow() -> void:
	var attempt: SectionRun = _section_run(FINAL)
	var watch: FlowWatch = FlowWatch.new(attempt.course)

	await _play([attempt.run])

	_assert_cleared(attempt)
	var flow: FlowState = attempt.course.flow
	assert_gt(watch.highest_gauge, 0.0, "the runner earned flow on the way")
	assert_gt(flow.style_score, 0, "and a style score")
	assert_true(flow.frozen, "past the real finish line, the flow is frozen")
	assert_eq(flow.best_style_score, flow.style_score, "its style score is the best of the session")


func test_a_runner_pushing_against_a_wall_is_stopped() -> void:
	# With the tuning of the project, and with an acceleration that asks, at every step,
	# for more than the stop speed: what counts is the speed the physics leaves.
	var hard_push: MovementTuning = (load(TUNING) as MovementTuning).duplicate() as MovementTuning
	hard_push.ground_acceleration = 4.0 * hard_push.ground_acceleration
	var push_per_step: float = hard_push.ground_acceleration / STEPS_PER_SECOND
	assert_gt(push_per_step, hard_push.flow_stop_speed, "a push stronger than the stop speed")
	var courses: Array[Course] = []
	var spacing: float = 0.0
	for variant: MovementTuning in [null, hard_push]:
		var course: Course = _add_course(courses.size() * spacing)
		spacing = 2.0 * PilotedRun.bounds_of_the_blocks(course).size.x
		if variant != null:
			course.player.apply_tuning(variant)
		_start_at(course, STEPS)
		var straight_ahead: ScriptedIntentSource = ScriptedIntentSource.new()
		course.player.intent_source = straight_ahead.hold(FORWARD, false, 1000)
		courses.append(course)
	await _wait_steps(TO_THE_FIRST_STEP)
	for course: Course in courses:
		var runner: Player = course.player
		var face: float = _bounds_of(course.get_node(FIRST_STEP)).end.z
		assert_true(runner.is_on_floor(), "a runner on the ground")
		var gap: float = runner.global_position.z - face
		assert_almost_eq(gap, runner.tuning.capsule_radius, NEAR, "against the face of a wall")
		_count(course.flow, WALL_RUN_MOVE)
		assert_true(course.flow.in_combo(), "in a combo")

	await _wait_steps(STOP_STEPS - 5)
	for course: Course in courses:
		assert_true(course.flow.in_combo(), "just before the stop duration, the combo is on")

	await _wait_steps(10)
	for index: int in courses.size():
		var context: String = "pushing %s: " % ["as tuned", "hard"][index]
		var flow: FlowState = courses[index].flow
		assert_false(flow.in_combo(), context + "the combo is broken")
		assert_eq(flow.combos_broken, 1, context + "by a stop")


func test_the_course_earns_flow() -> void:
	var attempt: SectionRun = _section_run(WALL_RUN)
	var watch: FlowWatch = FlowWatch.new(attempt.course)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(watch.wall_runs, 0, "the flow counted a wall run")
	var points: int = attempt.course.player.tuning.flow_points_wall_run
	assert_gte(watch.highest_gauge, float(points), "the gauge gained the points of a wall run")


func test_the_course_stays_clearable_at_full_speed() -> void:
	var attempts: Array[SectionRun] = []
	var runs: Array[PilotedRun] = []
	var speeds: Array[FullSpeed] = []
	var spacing: float = 0.0
	for section: int in FAST_SECTIONS:
		var attempt: SectionRun = _section_run(section, null, attempts.size() * spacing)
		if attempts.is_empty():
			spacing = 2.0 * PilotedRun.bounds_of_the_blocks(attempt.course).size.x
		attempts.append(attempt)
		runs.append(attempt.run)
		speeds.append(FullSpeed.new(attempt.course.player))

	await _play(runs)

	for index: int in attempts.size():
		var attempt: SectionRun = attempts[index]
		_assert_cleared(attempt)
		var runner: Player = attempt.course.player
		var context: String = CHECKPOINT_NAMES[attempt.section]
		var tier_speed: float = runner.tuning.top_speed * 1.15
		assert_almost_eq(runner.motor.top_speed(), tier_speed, 0.001, context + ": at tier 3")
		assert_gt(speeds[index].fastest, runner.tuning.top_speed * 1.1, context + ": and as fast")


func test_returning_to_the_checkpoint_on_request_empties_the_gauge() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	await _wait_steps(SETTLE_STEPS)
	var flow: FlowState = course.flow
	flow.gauge = 1.5 * course.player.tuning.flow_tier_value
	_count(flow, WALL_RUN_MOVE)
	assert_true(flow.in_combo(), "a runner with gauge, in a combo")
	assert_gt(flow.gauge, 0.0)

	await _replay(course, ScriptedIntentSource.new().request_respawn(), 0)

	assert_eq(flow.gauge, 0.0, "the gauge is at zero")
	assert_false(flow.in_combo(), "the combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_eq(course.player.motor.top_speed(), course.player.tuning.top_speed, "no speed bonus")


func test_restarting_resets_everything() -> void:
	var course: Course = _add_course()
	_start_at(course, SHORT_JUMPS)
	var flow: FlowState = course.flow
	_count(flow, WALL_RUN_MOVE)
	_count(flow, WALL_JUMP_MOVE)
	flow.finish()
	assert_eq(flow.best_style_score, 300, "a first run, finished")
	await _replay(course, ScriptedIntentSource.new().request_restart(), 0)
	assert_false(flow.frozen, "a new run")
	_start_at(course, SHORT_JUMPS)
	flow.gauge = course.player.tuning.flow_tier_value - 100.0
	_count(flow, WALL_RUN_MOVE)
	assert_true(flow.in_combo(), "a runner with gauge, a combo")
	assert_eq(flow.ammo, 1, "ammunition")
	assert_eq(flow.style_score, 150, "and a style score")

	await _replay(course, ScriptedIntentSource.new().request_restart(), 0)

	assert_eq(course.race.phase, RaceState.Phase.NOT_STARTED, "the course restarted")
	assert_eq(flow.gauge, 0.0, "the gauge is at zero")
	assert_false(flow.in_combo(), "no combo")
	assert_eq(flow.multiplier(), 1)
	assert_eq(flow.ammo, 0, "no ammunition")
	assert_eq(flow.style_score, 0, "a style score at zero")
	assert_eq(flow.best_style_score, 300, "the best style score of the session stays")
	_count(flow, WALL_RUN_MOVE)
	assert_eq(flow.last_points, 150, "and the repetition starts from zero")


## One step at which the motor announced `kind`, given to the flow of a course as its
## runner would give it, in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, flow.tuning.top_speed, false)


## The box that holds a block, in the world.
func _bounds_of(block: Node) -> AABB:
	var collider: CollisionShape3D = block.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
