extends GutTest
## The state of a run (game/core): timer in fixed steps, checkpoints, best time.

const STEPS_PER_SECOND: int = 60


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


func test_a_respawn_does_not_touch_the_timer() -> void:
	var race: RaceState = _running_race()
	race.reach_checkpoint(1)
	_tick(race, 30)

	var respawn_point: int = race.last_checkpoint
	_tick(race, 30)

	assert_eq(respawn_point, 1)
	assert_eq(race.phase, RaceState.Phase.RUNNING)
	assert_eq(race.elapsed_steps, 60, "the timer counted without a break")


func _running_race() -> RaceState:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	race.cross_start_line()
	return race


func _tick(race: RaceState, steps: int) -> void:
	for i: int in steps:
		race.tick()
