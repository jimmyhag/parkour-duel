extends GutTest
## The result screen of a round (game/ui): the verdict, one line per runner with its time
## or DNF and its style score, and the two choices, REMATCH and MENU.

const SCREEN_SCENE: PackedScene = preload("res://game/ui/result_screen.tscn")
const STEPS_PER_SECOND: int = 60
const PLAYER: int = 0
const OPPONENT: int = 1
## 30.5 s of fixed steps.
const PLAYER_STEPS: int = 1830

var _rematches: int = 0
var _menus: int = 0


func after_each() -> void:
	for action: StringName in [&"menu_down", &"jump", &"menu"]:
		Input.action_release(action)


func test_the_result_screen_shows_the_round() -> void:
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	round_state.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 2500))
	var screen: ResultScreen = _add_screen()
	assert_false(screen.visible, "hidden during the round")

	screen.show_round(round_state, "BOT", [2500, 700] as Array[int])

	assert_true(screen.visible, "shown at the end of the round")
	assert_eq(_text(screen, "%Verdict"), "YOU WIN")
	var you: String = _text(screen, "%YouLine")
	assert_string_contains(you, "YOU")
	assert_string_contains(you, "0:30.50")
	assert_string_contains(you, "STYLE 2500")
	var them: String = _text(screen, "%ThemLine")
	assert_string_contains(them, "BOT")
	assert_string_contains(them, "DNF")
	assert_string_contains(them, "STYLE 700")
	assert_eq(screen.choice_texts(), ["REMATCH", "MENU"] as Array[String], "two choices")
	assert_eq(screen.selected(), ResultScreen.Choice.REMATCH, "the first one selected")


func test_the_verdict_of_a_lost_round_and_of_a_draw() -> void:
	var screen: ResultScreen = _add_screen()
	var lost: RoundState = RoundState.new(STEPS_PER_SECOND)
	lost.receive(RoundMessage.start(0))
	lost.receive(RoundMessage.finish(OPPONENT, PLAYER_STEPS, 0))
	screen.show_round(lost, "GHOST", [0, 0] as Array[int])
	assert_eq(_text(screen, "%Verdict"), "YOU LOSE")
	assert_string_contains(_text(screen, "%YouLine"), "DNF")
	assert_string_contains(_text(screen, "%ThemLine"), "GHOST")

	var drawn: RoundState = RoundState.new(STEPS_PER_SECOND)
	drawn.receive(RoundMessage.start(0))
	drawn.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 10))
	drawn.receive(RoundMessage.finish(OPPONENT, PLAYER_STEPS, 10))
	screen.show_round(drawn, "BOT", [10, 10] as Array[int])
	assert_eq(_text(screen, "%Verdict"), "DRAW")


func test_the_result_screen_chooses_the_rematch_or_the_menu() -> void:
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	round_state.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 0))
	var screen: ResultScreen = _add_screen()
	screen.show_round(round_state, "BOT", [0, 0] as Array[int])

	await _tap(&"jump")
	assert_eq(_rematches, 1, "jump on REMATCH: the rematch")

	screen.show_round(round_state, "BOT", [0, 0] as Array[int])
	await _tap(&"menu_down")
	assert_eq(screen.selected(), ResultScreen.Choice.MENU, "down: MENU")
	await _tap(&"jump")
	assert_eq(_menus, 1, "jump on MENU: the start screen")

	screen.show_round(round_state, "BOT", [0, 0] as Array[int])
	await _tap(&"menu")
	assert_eq(_menus, 2, "Esc or Back: the start screen too")
	assert_eq(_rematches, 1, "and no rematch")


func _add_screen() -> ResultScreen:
	var screen: ResultScreen = SCREEN_SCENE.instantiate() as ResultScreen
	add_child_autofree(screen)
	screen.rematch_chosen.connect(func() -> void: _rematches += 1)
	screen.menu_chosen.connect(func() -> void: _menus += 1)
	return screen


func _text(screen: ResultScreen, path: NodePath) -> String:
	return (screen.get_node(path) as Label).text


## Presses an action of the input map for one frame, as a finger would, once the screen
## has been on screen for a frame: it ignores the frame it opens.
func _tap(action: StringName) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame
