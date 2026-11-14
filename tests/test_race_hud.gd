extends GutTest
## The timer display (game/ui): TIME, FINISHED and BEST, to the hundredth of a second,
## and at the finish the style score of the run and the best one of the session.

const HUD_SCENE: PackedScene = preload("res://game/ui/race_hud.tscn")
const STEPS_PER_SECOND: int = 60
## 75.5 seconds of fixed steps.
const RUN_STEPS: int = 4530


func test_the_time_is_displayed_to_the_hundredth() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	var hud: RaceHud = _add_hud(race)
	hud.refresh()
	assert_eq(_text(hud, "%TimeLabel"), "TIME 0:00.00", "before the start line")
	assert_eq(_text(hud, "%BestLabel"), "BEST --:--.--", "no best time yet")

	race.cross_start_line()
	_tick(race, RUN_STEPS)
	hud.refresh()

	assert_eq(_text(hud, "%TimeLabel"), "TIME 1:15.50")

	race.tick()
	hud.refresh()
	assert_eq(_text(hud, "%TimeLabel"), "TIME 1:15.51", "one more step, one more hundredth")


func test_the_finish_displays_the_final_time_and_the_best_time() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	var hud: RaceHud = _add_hud(race)
	race.cross_start_line()
	_tick(race, RUN_STEPS)

	race.cross_finish_line()
	_tick(race, STEPS_PER_SECOND)
	hud.refresh()

	assert_eq(_text(hud, "%TimeLabel"), "FINISHED 1:15.50", "the final time is frozen")
	assert_eq(_text(hud, "%BestLabel"), "BEST 1:15.50")

	race.restart()
	hud.refresh()
	assert_eq(_text(hud, "%TimeLabel"), "TIME 0:00.00", "a new run starts from zero")
	assert_eq(_text(hud, "%BestLabel"), "BEST 1:15.50", "the best time stays on screen")


func test_the_finish_shows_the_style_score() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	var flow: FlowState = FlowState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	var hud: RaceHud = _add_hud(race, flow)
	_finish_a_run(race, flow, [RunnerEvent.Kind.WALL_RUN, RunnerEvent.Kind.WALL_JUMP])
	race.restart()
	flow.restart()
	race.cross_start_line()
	hud.refresh()
	assert_false(_label(hud, "%StyleLabel").visible, "no style score while a run is on")
	assert_false(_label(hud, "%BestStyleLabel").visible)

	_finish_a_run(race, flow, [RunnerEvent.Kind.ROLL])
	hud.refresh()

	assert_true(_label(hud, "%StyleLabel").visible, "a finished run shows its style score")
	assert_eq(_text(hud, "%StyleLabel"), "STYLE 100")
	assert_true(_label(hud, "%BestStyleLabel").visible, "and the best of the session")
	assert_eq(_text(hud, "%BestStyleLabel"), "BEST STYLE 300")


func test_the_hud_shows_the_gap_to_the_opponent() -> void:
	var race: RaceState = RaceState.new(STEPS_PER_SECOND)
	var hud: RaceHud = _add_hud(race)
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	hud.round_state = round_state
	race.cross_start_line()
	hud.refresh()
	assert_false(_label(hud, "%GapLabel").visible, "no common checkpoint yet: no gap")
	assert_false(_label(hud, "%BestLabel").visible, "no best time in a duel")

	# The opponent at 1.01 s on the timer, the player at 2.25 s.
	round_state.receive(RoundMessage.checkpoint_reached(1, 1, 61, 0))
	round_state.receive(RoundMessage.checkpoint_reached(0, 1, 135, 0))
	hud.refresh()

	assert_true(_label(hud, "%GapLabel").visible, "a gap at the checkpoint both passed")
	assert_eq(_text(hud, "%GapLabel"), "+1.24", "the player 1.24 s after the opponent")

	round_state.receive(RoundMessage.checkpoint_reached(0, 2, 200, 0))
	round_state.receive(RoundMessage.checkpoint_reached(1, 2, 248, 0))
	hud.refresh()
	assert_eq(_text(hud, "%GapLabel"), "-0.80", "0.80 s before it at the next one")


func _add_hud(race: RaceState, flow: FlowState = null) -> RaceHud:
	var hud: RaceHud = HUD_SCENE.instantiate() as RaceHud
	hud.race = race
	hud.flow = flow
	add_child_autofree(hud)
	return hud


## Runs from the start line to the finish line, the runner starting `moves` on the way.
func _finish_a_run(race: RaceState, flow: FlowState, moves: Array[RunnerEvent.Kind]) -> void:
	race.cross_start_line()
	for kind: RunnerEvent.Kind in moves:
		var events: Array[RunnerEvent] = [RunnerEvent.new(kind, race.elapsed_steps)]
		flow.step(events, 9.0, false)
		race.tick()
	race.cross_finish_line()
	flow.finish()


func _label(hud: RaceHud, label_path: NodePath) -> Label:
	return hud.get_node(label_path) as Label


func _text(hud: RaceHud, label_path: NodePath) -> String:
	return _label(hud, label_path).text


func _tick(race: RaceState, steps: int) -> void:
	for i: int in steps:
		race.tick()
