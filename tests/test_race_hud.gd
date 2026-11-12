extends GutTest
## The timer display (game/ui): TIME, FINISHED and BEST, to the hundredth of a second.

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


func _add_hud(race: RaceState) -> RaceHud:
	var hud: RaceHud = HUD_SCENE.instantiate() as RaceHud
	hud.race = race
	add_child_autofree(hud)
	return hud


func _text(hud: RaceHud, label_path: NodePath) -> String:
	return (hud.get_node(label_path) as Label).text


func _tick(race: RaceState, steps: int) -> void:
	for i: int in steps:
		race.tick()
