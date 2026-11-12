extends GutTest
## The state of a run (game/core): timer in fixed steps, checkpoints, best time, and
## the rule that sends a runner back to a checkpoint or to the start.

const STEPS_PER_SECOND: int = 60
## The altitude under which a runner has fallen off the course.
const FALL_LIMIT: float = -8.0


func test_the_timer_starts_when_crossing_the_start_line() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	_tick(race, 10)
	assert_eq(race.phase, RaceState.Phase.NOT_STARTED)
	assert_eq(race.elapsed_steps, 0, "nothing counts before the start line")

	race.cross_start_line()
	_tick(race, 90)

	assert_eq(race.phase, RaceState.Phase.RUNNING)
	assert_eq(race.elapsed_steps, 90, "one per fixed step")
	assert_eq(race.centiseconds(race.elapsed_steps), 150, "90 steps at 60 per second")


func test_the_timer_stops_at_the_finish_line() -> void:
	var race: RaceState = _running_race()
	_tick(race, 120)

	race.cross_finish_line()
	_tick(race, 30)

	assert_eq(race.phase, RaceState.Phase.FINISHED)
	assert_eq(race.elapsed_steps, 120, "the final time no longer changes")


func test_the_best_time_of_the_session_is_kept() -> void:
	var race: RaceState = _running_race()
	assert_eq(race.best_steps, RaceState.NO_TIME, "no best time before a first finish")
	_tick(race, 100)
	race.cross_finish_line()
	assert_eq(race.best_steps, 100)

	race.restart()
	race.cross_start_line()
	_tick(race, 130)
	race.cross_finish_line()

	assert_eq(race.elapsed_steps, 130)
	assert_eq(race.best_steps, 100, "a slower run does not replace the best time")

	race.restart()
	race.cross_start_line()
	_tick(race, 80)
	race.cross_finish_line()
	assert_eq(race.best_steps, 80, "a faster one does")


func test_a_reached_checkpoint_becomes_the_respawn_point() -> void:
	var race: RaceState = _running_race()
	assert_eq(race.last_checkpoint, 0, "the start is the first respawn point")

	race.reach_checkpoint(1)

	assert_eq(race.last_checkpoint, 1)


func test_a_checkpoint_already_passed_does_not_move_the_respawn_back() -> void:
	var race: RaceState = _running_race()
	race.reach_checkpoint(1)
	race.reach_checkpoint(2)

	race.reach_checkpoint(1)

	assert_eq(race.last_checkpoint, 2)


func test_restarting_resets_the_timer_and_keeps_the_best_time() -> void:
	var race: RaceState = _running_race()
	race.reach_checkpoint(2)
	_tick(race, 100)
	race.cross_finish_line()
	race.restart()
	race.cross_start_line()
	race.reach_checkpoint(1)
	_tick(race, 40)

	race.restart()

	assert_eq(race.phase, RaceState.Phase.NOT_STARTED)
	assert_eq(race.elapsed_steps, 0)
	assert_eq(race.last_checkpoint, 0, "back to the start")
	assert_eq(race.best_steps, 100, "the best time survives")
	_tick(race, 10)
	assert_eq(race.elapsed_steps, 0, "and the timer waits for the start line")


func test_going_below_the_fall_limit_requests_a_respawn() -> void:
	var race: RaceState = _running_race()
	race.reach_checkpoint(2)
	_tick(race, 50)
	var no_request: MoveIntent = MoveIntent.new()
	var above: RaceState.RespawnOrder = race.apply_respawn_rule(
		FALL_LIMIT + 0.1, FALL_LIMIT, no_request
	)
	assert_eq(above, RaceState.RespawnOrder.NONE, "nothing above the limit")

	var below: RaceState.RespawnOrder = race.apply_respawn_rule(
		FALL_LIMIT - 0.1, FALL_LIMIT, no_request
	)

	assert_eq(below, RaceState.RespawnOrder.RESPAWN, "a respawn below it")
	assert_eq(race.last_checkpoint, 2, "at the last checkpoint")
	assert_eq(race.phase, RaceState.Phase.RUNNING, "the run goes on")
	assert_eq(race.elapsed_steps, 50, "and the timer is not touched")

	var request: MoveIntent = MoveIntent.new()
	request.respawn_requested = true
	var on_request: RaceState.RespawnOrder = race.apply_respawn_rule(0.0, FALL_LIMIT, request)
	assert_eq(on_request, RaceState.RespawnOrder.RESPAWN, "a respawn on request too")
	assert_eq(race.elapsed_steps, 50, "still without touching the timer")


func test_restarting_wins_over_respawning() -> void:
	var race: RaceState = _running_race()
	race.reach_checkpoint(2)
	_tick(race, 50)
	var both: MoveIntent = MoveIntent.new()
	both.respawn_requested = true
	both.restart_requested = true

	var order: RaceState.RespawnOrder = race.apply_respawn_rule(FALL_LIMIT - 0.1, FALL_LIMIT, both)

	assert_eq(order, RaceState.RespawnOrder.RESTART, "the course is restarted")
	assert_eq(race.phase, RaceState.Phase.NOT_STARTED)
	assert_eq(race.elapsed_steps, 0, "timer at zero")
	assert_eq(race.last_checkpoint, 0, "the respawn point is the start again")


func _running_race() -> RaceState:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	race.cross_start_line()
	return race


func _tick(race: RaceState, steps: int) -> void:
	for i: int in steps:
		race.tick()
