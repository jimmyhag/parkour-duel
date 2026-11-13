extends CourseTest
## The two sections of the test course (game/levels) that ask for the ground moves: the
## low passage, cleared by sliding under its obstacle, and the big drop, landed by
## rolling. Played without a screen in the real physics by the test pilot, faster than
## real time with the same fixed step of 1/60 s (see ReplayTest).

const SLIDING: RunnerMotor.State = RunnerMotor.State.SLIDING
const ROLLING: RunnerMotor.State = RunnerMotor.State.ROLLING
const HARD_LANDING: RunnerMotor.State = RunnerMotor.State.HARD_LANDING
const FORWARD: Vector3 = Vector3.FORWARD
## The obstacle of the low passage.
const LOW_OBSTACLE: String = "Blocks/LowBeam"


## Runs forward, and holds the slide for as long as the floor goes down under its runner.
class SlopeSlider:
	extends IntentSource

	var steps_sliding_downhill: int = 0
	## Steps the runner spent off the floor between the top of the slope and its bottom.
	var steps_off_the_slope: int = 0
	## The horizontal speed of the runner as its slide started down the slope.
	var speed_at_the_top: float = 0.0
	## The runner went down a slope, and stands on level ground again.
	var is_past_the_slope: bool = false

	var _runner: Player

	func _init(runner: Player) -> void:
		_runner = runner

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = Vector3.FORWARD
		var on_floor: bool = _runner.is_on_floor()
		var downhill: bool = on_floor and _runner.get_floor_normal().dot(intent.direction) > NEAR
		intent.slide_held = downhill
		if steps_sliding_downhill > 0 and not is_past_the_slope and not on_floor:
			steps_off_the_slope += 1
		if downhill and _runner.motor.state == RunnerMotor.State.SLIDING:
			if steps_sliding_downhill == 0:
				speed_at_the_top = Vector2(_runner.velocity.x, _runner.velocity.z).length()
			steps_sliding_downhill += 1
		is_past_the_slope = steps_sliding_downhill > 0 and on_floor and not downhill
		return intent


func test_the_low_passage_can_be_cleared_by_sliding() -> void:
	var attempt: SectionRun = _section_run(LOW_PASSAGE)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(attempt.run.steps_sliding, 0, "the runner slid")


## The proof, in the real physics, that the low passage has a ramp going down and that a
## slide follows it and gains speed on it: the player layer reports the slope of the
## floor, game/core does the rest.
func test_a_slide_gains_speed_on_the_ramp_of_the_low_passage() -> void:
	var course: Course = _add_course()
	_start_at(course, LOW_PASSAGE)
	var runner: Player = course.player
	var slider: SlopeSlider = SlopeSlider.new(runner)
	runner.intent_source = slider
	var budget: int = _step_budget(course, _checkpoint(course, BIG_DROP))

	var fastest: float = 0.0
	var steps: int = 0
	while not slider.is_past_the_slope and steps < budget:
		await get_tree().physics_frame
		fastest = maxf(fastest, _horizontal_speed(runner))
		steps += 1

	assert_true(slider.is_past_the_slope, "the runner slid down a ramp, to level ground")
	var start_altitude: float = _checkpoint(course, LOW_PASSAGE).global_position.y
	assert_lt(runner.global_position.y, start_altitude - NEAR, "lower than where it started")
	assert_eq(slider.steps_off_the_slope, 0, "without ever leaving the floor")
	var speed_at_the_bottom: float = _horizontal_speed(runner)
	assert_gt(speed_at_the_bottom, slider.speed_at_the_top + NEAR, "faster at the bottom")
	assert_gt(fastest, runner.tuning.top_speed + NEAR, "and faster than it can run")


## The ledge is the edge of the big drop. Both runners are launched from its checkpoint
## faster than the top speed: on the way to the edge the floor takes less speed from a
## slide than from a run, so nothing but a push down can make the slider land shorter.
func test_sliding_off_a_ledge_does_not_push_the_runner_down() -> void:
	var courses: Array[Course] = [_add_course()]
	courses.append(_add_course(2.0 * PilotedRun.bounds_of_the_blocks(courses[0]).size.x))
	for course: Course in courses:
		_start_at(course, BIG_DROP)
	await _wait_steps(SETTLE_STEPS)
	var slider: Player = courses[0].player
	var runner: Player = courses[1].player
	var budget: int = _step_budget(courses[0], courses[0].get_node("FinishLine") as RaceLine)
	var launch_speed: float = slider.tuning.top_speed * 1.5
	var ledge_altitude: float = slider.global_position.y
	slider.velocity = FORWARD * launch_speed
	runner.velocity = FORWARD * launch_speed
	slider.intent_source = ScriptedIntentSource.new().slide(FORWARD, budget)
	runner.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, budget)

	# Each one is followed from the ledge, through the air, to the floor it lands on.
	var flights: Array[float] = [0.0, 0.0]
	var flew: Array[bool] = [false, false]
	var states_on_the_ledge: Array[RunnerMotor.State] = [SLIDING, SLIDING]
	var landed: int = 0
	var steps: int = 0
	while landed < flights.size() and steps < budget:
		await get_tree().physics_frame
		steps += 1
		landed = 0
		for index: int in flights.size():
			var body: Player = slider if index == 0 else runner
			if not body.is_on_floor():
				flew[index] = true
			elif not flew[index]:
				states_on_the_ledge[index] = body.motor.state
			elif flights[index] == 0.0:
				flights[index] = body.global_position.dot(FORWARD)
			landed += int(flights[index] != 0.0)

	assert_eq(landed, 2, "both left the ledge and landed")
	assert_lt(slider.global_position.y, ledge_altitude - NEAR, "lower than the ledge")
	assert_lt(runner.global_position.y, ledge_altitude - NEAR, "both of them")
	assert_eq(states_on_the_ledge[0], SLIDING, "one slid off the ledge")
	assert_eq(states_on_the_ledge[1], RunnerMotor.State.GROUNDED, "the other ran off it")
	assert_gte(flights[0], flights[1], "the one that slides lands at least as far")


func test_the_low_passage_stops_a_standing_runner() -> void:
	var attempt: SectionRun = _section_run(LOW_PASSAGE)
	attempt.run.pilot_slides = false

	await _play([attempt.run])

	var runner: Player = attempt.course.player
	var out_of_steps: PilotedRun.Outcome = PilotedRun.Outcome.OUT_OF_STEPS
	assert_eq(attempt.run.outcome, out_of_steps, "the runner never gets through")
	assert_eq(attempt.run.slide_requests, 0, "it never asked for the slide")
	assert_false(attempt.run.goal_reached, "the checkpoint of the big drop is not reached")
	assert_eq(attempt.course.race.last_checkpoint, LOW_PASSAGE, "nor counted by the race")
	assert_true(runner.is_on_floor(), "it stands on the course")
	assert_lt(runner.velocity.length(), NEAR, "stopped")
	var obstacle: AABB = _bounds_of(attempt.course.get_node(LOW_OBSTACLE))
	var before_the_obstacle: float = runner.global_position.z - obstacle.end.z
	var radius: float = runner.tuning.capsule_radius
	assert_almost_eq(before_the_obstacle, radius, NEAR, "against the obstacle")


func test_the_big_drop_leads_to_the_finish() -> void:
	var attempt: SectionRun = _section_run(BIG_DROP)

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_gt(attempt.run.steps_rolling, 0, "the runner rolled")
	assert_eq(attempt.run.steps_landing_hard, 0, "and did not land hard")


func test_the_roll_saves_time_on_the_big_drop() -> void:
	var rolling: SectionRun = _section_run(BIG_DROP)
	var spacing: float = 2.0 * PilotedRun.bounds_of_the_blocks(rolling.course).size.x
	var landing_hard: SectionRun = _section_run(BIG_DROP, null, spacing)
	landing_hard.run.pilot_slides = false

	await _play([rolling.run, landing_hard.run])

	_assert_cleared(rolling)
	_assert_cleared(landing_hard)
	assert_gt(rolling.run.steps_rolling, 0, "one runner rolled")
	assert_eq(landing_hard.run.slide_requests, 0, "the other never pressed the slide")
	assert_gt(landing_hard.run.steps_landing_hard, 0, "and landed hard")
	var steps_rolling: int = rolling.course.race.elapsed_steps
	var steps_landing_hard: int = landing_hard.course.race.elapsed_steps
	assert_lt(steps_rolling, steps_landing_hard, "the one that rolls finishes in fewer steps")


func test_returning_to_the_checkpoint_stands_the_runner_up() -> void:
	var states: Array[RunnerMotor.State] = [SLIDING, ROLLING, HARD_LANDING]
	var spacing: float = 0.0
	for index: int in states.size():
		var state: RunnerMotor.State = states[index]
		var state_name: String = RunnerMotor.State.keys()[state]
		var section: int = LOW_PASSAGE if state == SLIDING else BIG_DROP
		var attempt: SectionRun = _section_run(section, null, index * spacing)
		spacing = 2.0 * PilotedRun.bounds_of_the_blocks(attempt.course).size.x
		attempt.run.pilot_slides = state != HARD_LANDING
		var runner: Player = attempt.course.player
		var standing: float = runner.tuning.capsule_height

		while runner.motor.state != state and not attempt.run.is_over:
			await get_tree().physics_frame
			attempt.run.observe_step()
		assert_eq(runner.motor.state, state, "the pilot led the runner to %s" % state_name)
		if runner.motor.is_low():
			assert_lt(_capsule_height(runner), standing, "%s: its capsule is low" % state_name)

		runner.intent_source = ScriptedIntentSource.new().request_respawn()
		await _wait_steps(1)
		var height: float = _capsule_height(runner)
		assert_almost_eq(height, standing, NEAR, "%s: back with a standing capsule" % state_name)
		await _wait_steps(SETTLE_STEPS)

		_assert_at_rest_at(attempt.course, _checkpoint(attempt.course, section))
		var grounded: RunnerMotor.State = RunnerMotor.State.GROUNDED
		assert_eq(runner.motor.state, grounded, "after %s: standing" % state_name)
		height = _capsule_height(runner)
		assert_almost_eq(height, standing, NEAR, "after %s: its capsule stands" % state_name)


## The steps a run from where the runner of `course` is to `goal` may last: as many
## times the time its distance takes at top speed as a piloted run is given.
func _step_budget(course: Course, goal: Area3D) -> int:
	var distance: float = course.player.global_position.distance_to(goal.global_position)
	var seconds_at_top_speed: float = distance / course.player.tuning.top_speed
	return PilotedRun.BUDGET_MARGIN * ceili(seconds_at_top_speed * STEPS_PER_SECOND)


func _horizontal_speed(runner: Player) -> float:
	return Vector2(runner.velocity.x, runner.velocity.z).length()


func _capsule_height(runner: Player) -> float:
	var collider: CollisionShape3D = runner.get_node("CollisionShape3D") as CollisionShape3D
	return (collider.shape as CapsuleShape3D).height


## The box that holds a block, in the world.
func _bounds_of(block: Node) -> AABB:
	var collider: CollisionShape3D = block.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
