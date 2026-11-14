extends GutTest
## The start screen (game/ui): its four choices, the duel against the ghost greyed with
## its reason until a solo run is finished, and its navigation.

const SCREEN_SCENE: PackedScene = preload("res://game/ui/start_screen.tscn")
const LABELS: Array[String] = ["SOLO PRACTICE", "DUEL VS GHOST", "DUEL VS BOT", "TRICK PARK"]
const REASON: String = "FINISH A SOLO RUN FIRST"

var _chosen: Array[StartScreen.Choice] = []


func after_each() -> void:
	for action: StringName in [&"menu_up", &"menu_down", &"jump"]:
		Input.action_release(action)


func test_the_ghost_duel_needs_a_solo_run() -> void:
	var screen: StartScreen = _add_screen(false)

	assert_eq(_texts(screen), LABELS, "the four choices")
	assert_true(_is_greyed(screen, StartScreen.Choice.DUEL_VS_GHOST), "the ghost greyed")
	var reason: Label = screen.get_node("%Reason") as Label
	assert_true(reason.is_visible_in_tree(), "with its reason")
	assert_eq(reason.text, REASON)
	assert_false(_is_greyed(screen, StartScreen.Choice.SOLO_PRACTICE), "solo practice is not")
	assert_false(_is_greyed(screen, StartScreen.Choice.DUEL_VS_BOT), "nor the bot")
	assert_false(_is_greyed(screen, StartScreen.Choice.TRICK_PARK), "nor the trick park")

	screen.open(true)

	assert_false(_is_greyed(screen, StartScreen.Choice.DUEL_VS_GHOST), "after a solo run: open")
	assert_false(reason.is_visible_in_tree(), "no reason any more")


func test_the_start_screen_chooses_with_up_down_and_jump() -> void:
	var screen: StartScreen = _add_screen(true)
	assert_eq(screen.selected(), StartScreen.Choice.SOLO_PRACTICE, "the first choice first")
	assert_true(_is_highlighted(screen, StartScreen.Choice.SOLO_PRACTICE), "shown selected")

	await _tap(&"menu_down")
	assert_eq(screen.selected(), StartScreen.Choice.DUEL_VS_GHOST, "down")
	assert_true(_is_highlighted(screen, StartScreen.Choice.DUEL_VS_GHOST), "shown selected")
	assert_false(_is_highlighted(screen, StartScreen.Choice.SOLO_PRACTICE), "the other not")
	await _tap(&"menu_down")
	await _tap(&"menu_down")
	await _tap(&"menu_down")
	assert_eq(screen.selected(), StartScreen.Choice.TRICK_PARK, "it stops at the last one")
	await _tap(&"menu_up")
	await _tap(&"menu_up")
	assert_eq(screen.selected(), StartScreen.Choice.DUEL_VS_GHOST, "up")
	assert_eq(_chosen.size(), 0, "nothing chosen yet")

	await _tap(&"jump")

	assert_eq(_chosen, [StartScreen.Choice.DUEL_VS_GHOST] as Array[StartScreen.Choice], "jump")

	var without_ghost: StartScreen = _add_screen(false)
	await _tap(&"menu_down")
	assert_eq(without_ghost.selected(), StartScreen.Choice.DUEL_VS_BOT, "a greyed one skipped")


func _add_screen(ghost_available: bool) -> StartScreen:
	var screen: StartScreen = SCREEN_SCENE.instantiate() as StartScreen
	add_child_autofree(screen)
	screen.mode_chosen.connect(_on_mode_chosen)
	screen.open(ghost_available)
	return screen


func _on_mode_chosen(choice: StartScreen.Choice) -> void:
	_chosen.append(choice)


func _texts(screen: StartScreen) -> Array[String]:
	var texts: Array[String] = []
	for choice: StartScreen.Choice in StartScreen.Choice.values():
		texts.append(screen.choice_label(choice).text)
	return texts


func _is_greyed(screen: StartScreen, choice: StartScreen.Choice) -> bool:
	return screen.choice_item(choice).modulate == ChoiceMenu.DISABLED_COLOR


func _is_highlighted(screen: StartScreen, choice: StartScreen.Choice) -> bool:
	return screen.choice_item(choice).modulate == ChoiceMenu.SELECTED_COLOR


## Presses an action of the input map for one frame, as a finger would, once the screen
## has been on screen for a frame: it ignores the frame it opens.
func _tap(action: StringName) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame
