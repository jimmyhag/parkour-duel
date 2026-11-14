extends GutTest
## The input map of project.godot: the only place where keys and buttons are bound.

## The actions of the game itself. The debug actions and the mouse release are keyboard
## only, by decision of the movement-base spec.
const GAME_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_back",
	&"move_left",
	&"move_right",
	&"jump",
	&"slide",
	&"trick",
	&"respawn",
	&"restart",
]
const KEYBOARD_ONLY_ACTIONS: Array[StringName] = [
	&"release_mouse",
	&"toggle_debug",
	&"reload_tuning",
]
const BUILT_IN_PREFIX: String = "ui_"


func test_every_game_action_has_a_keyboard_mouse_input_and_a_gamepad_input() -> void:
	for action: StringName in GAME_ACTIONS:
		assert_true(InputMap.has_action(action), "%s is in the input map" % action)
		var keys: int = 0
		var pad_inputs: int = 0
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys += 1
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				pad_inputs += 1
		assert_gt(keys, 0, "%s has a keyboard key" % action)
		assert_gt(pad_inputs, 0, "%s has a gamepad button or axis" % action)


func test_keyboard_keys_are_physical_keys() -> void:
	var keys: int = 0
	for action: StringName in _project_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			var key: InputEventKey = event as InputEventKey
			if key == null:
				continue
			keys += 1
			assert_ne(key.physical_keycode, KEY_NONE, "%s is bound by key position" % action)
			assert_eq(key.keycode, KEY_NONE, "%s is not bound by the letter produced" % action)
			assert_eq(key.key_label, KEY_NONE, "%s is not bound by the key label" % action)

	var expected: int = GAME_ACTIONS.size() + KEYBOARD_ONLY_ACTIONS.size()
	assert_gte(keys, expected, "every action of the project was examined")


## The actions project.godot declares, without the ones built into the engine.
func _project_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with(BUILT_IN_PREFIX):
			actions.append(action)
	return actions
