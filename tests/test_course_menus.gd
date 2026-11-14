extends ReplayTest
## The game as it starts (game/levels/main.tscn, the main scene): the start screen, the
## mode it starts, and the way back to it; navigated with the real events of the keyboard
## and of the gamepad. Faster than real time with the same fixed step of 1/60 s (see
## ReplayTest).

const MAIN_SCENE_SETTING: String = "application/run/main_scene"
## Frames for an event to be seen by the screens, which read the inputs once per frame.
const FRAMES: int = 2


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_the_start_screen_is_navigated_on_keyboard_and_gamepad() -> void:
	var main: Main = await _add_main()
	var start: StartScreen = main.get_node("StartScreen") as StartScreen
	assert_true(start.visible, "the game opens on the start screen")
	assert_null(main.mode, "no mode yet")
	assert_eq(start.selected(), StartScreen.Choice.SOLO_PRACTICE, "the first choice selected")

	# The keyboard: down (the ghost is greyed: skipped), then jump.
	await _press(_key(KEY_DOWN))
	assert_eq(start.selected(), StartScreen.Choice.DUEL_VS_BOT, "down: the duel against the bot")
	await _press(_key(KEY_SPACE))
	assert_true(main.mode is Duel, "the duel starts")
	if main.mode is Duel:
		assert_eq((main.mode as Duel).opponent, Duel.Opponent.BOT, "against the bot")
	assert_false(start.visible, "the start screen is gone")

	# Back to the start screen, then the gamepad: the cross down, the stick up, A.
	await _press(_key(KEY_ESCAPE))
	assert_true(start.visible, "back on the start screen")
	assert_null(main.mode, "the duel is over")
	await _press(_button(JOY_BUTTON_DPAD_DOWN))
	assert_eq(start.selected(), StartScreen.Choice.DUEL_VS_BOT, "the cross down: the bot")
	await _press(_stick(-1.0), _stick(0.0))
	assert_eq(start.selected(), StartScreen.Choice.SOLO_PRACTICE, "the stick up: solo practice")
	await _press(_button(JOY_BUTTON_A))
	assert_true(main.mode is Course, "the solo practice starts")


func test_a_finished_solo_run_opens_the_duel_against_the_ghost() -> void:
	var main: Main = await _add_main()
	var start: StartScreen = main.get_node("StartScreen") as StartScreen
	await _press(_key(KEY_SPACE))
	var course: Course = main.mode as Course
	assert_not_null(course, "the solo practice")
	if course == null:
		return
	# A run finished at once: the runner put just before the finish line, the race on.
	course.race.cross_start_line()
	course.player.intent_source = ScriptedIntentSource.new().hold(Vector3.FORWARD, false, 60)
	course.player.teleport(Transform3D(Basis.IDENTITY, Vector3(0.0, 2.8, -242.0)))
	for step: int in 60:
		await get_tree().physics_frame
	assert_eq(course.race.phase, RaceState.Phase.FINISHED, "a solo run finished")

	await _press(_button(JOY_BUTTON_START))
	assert_true(start.visible, "the start button: back to the start screen")
	assert_true(main.session.has_solo_run(), "the session remembers the run")
	await _press(_key(KEY_DOWN))
	assert_eq(start.selected(), StartScreen.Choice.DUEL_VS_GHOST, "the ghost can be chosen")
	await _press(_key(KEY_SPACE))
	assert_true(main.mode is Duel, "a duel")
	if main.mode is Duel:
		assert_eq((main.mode as Duel).opponent, Duel.Opponent.GHOST, "against the ghost")


func test_the_trick_park_is_chosen_on_the_start_screen() -> void:
	var main: Main = await _add_main()
	var start: StartScreen = main.get_node("StartScreen") as StartScreen

	# The keyboard: down twice (the ghost is greyed: skipped), then jump.
	await _press(_key(KEY_DOWN))
	await _press(_key(KEY_DOWN))
	assert_eq(start.selected(), StartScreen.Choice.TRICK_PARK, "the trick park, after the duels")
	await _press(_key(KEY_SPACE))
	_assert_a_bare_park(main, "on the keyboard")
	var park: TrickPark = main.mode as TrickPark
	if park != null:
		# The return to the start point: R.
		park.player.teleport(Transform3D(Basis.IDENTITY, Vector3(10.0, 0.0, -10.0)))
		await _press(_key(KEY_R))
		assert_lt(_from_the_start_point(park), 0.5, "R: back at the start point")

	# The menu, then the gamepad: the cross down twice, A; Y and Start in the park.
	await _press(_key(KEY_ESCAPE))
	assert_true(start.visible, "Escape: back on the start screen")
	assert_null(main.mode, "the park is over")
	await _press(_button(JOY_BUTTON_DPAD_DOWN))
	await _press(_button(JOY_BUTTON_DPAD_DOWN))
	await _press(_button(JOY_BUTTON_A))
	_assert_a_bare_park(main, "on the gamepad")
	park = main.mode as TrickPark
	if park != null:
		park.player.teleport(Transform3D(Basis.IDENTITY, Vector3(-10.0, 0.0, -10.0)))
		await _press(_button(JOY_BUTTON_Y))
		assert_lt(_from_the_start_point(park), 0.5, "Y: back at the start point")
	await _press(_button(JOY_BUTTON_START))
	assert_true(start.visible, "Start: back on the start screen")


func test_the_main_scene_is_the_start_screen() -> void:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	var root: Node = (load(main_scene) as PackedScene).instantiate()
	add_child_autofree(root)

	assert_true(root is Main, "the game")
	assert_true(root.get_node_or_null("StartScreen") is StartScreen, "opens on its start screen")


## The mode under way is the trick park, with its runner and its flow display, but no
## timer, no target and no opponent.
func _assert_a_bare_park(main: Main, context: String) -> void:
	assert_true(main.mode is TrickPark, context + ": the trick park starts")
	if not main.mode is TrickPark:
		return
	var runners: int = 0
	var timers: int = 0
	var targets: int = 0
	var flow_displays: int = 0
	for node: Node in main.mode.find_children("*", "", true, false):
		runners += int(node is Player)
		timers += int(node is RaceHud)
		targets += int(node is TargetBlock)
		flow_displays += int(node is FlowHud)
	assert_eq(runners, 1, context + ": one runner, no opponent")
	assert_eq(timers, 0, context + ": no timer")
	assert_eq(targets, 0, context + ": no target")
	assert_eq(flow_displays, 1, context + ": the flow is shown")


## How far the runner of the park is from its start point, along the ground, in m.
func _from_the_start_point(park: TrickPark) -> float:
	var spawn: Vector3 = (park.get_node("Spawn") as Node3D).global_position
	var feet: Vector3 = park.player.global_position
	return Vector2(feet.x - spawn.x, feet.z - spawn.z).length()


func _add_main() -> Main:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	var main: Main = (load(main_scene) as PackedScene).instantiate() as Main
	add_child_autofree(main)
	await get_tree().process_frame
	return main


## Gives the events to the engine as the devices would, each one for a few frames, once
## the screen has been on screen for a frame: it ignores the frame it opens.
func _press(pressed: InputEvent, released: InputEvent = null) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Input.parse_input_event(pressed)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame
	var release: InputEvent = released
	if release == null:
		release = pressed.duplicate() as InputEvent
		_release(release)
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame


func _release(event: InputEvent) -> void:
	if event is InputEventKey:
		(event as InputEventKey).pressed = false
	elif event is InputEventJoypadButton:
		(event as InputEventJoypadButton).pressed = false


func _key(physical: Key) -> InputEvent:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = true
	return event


func _button(button: JoyButton) -> InputEvent:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _stick(value: float) -> InputEvent:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_Y
	event.axis_value = value
	return event
