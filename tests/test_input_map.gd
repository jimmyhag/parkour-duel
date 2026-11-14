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
	&"menu",
	&"menu_up",
	&"menu_down",
]
const KEYBOARD_ONLY_ACTIONS: Array[StringName] = [
	&"release_mouse",
	&"toggle_debug",
	&"reload_tuning",
]
## The actions of the weapon: on a mouse button, and on a gamepad button or trigger.
const MOUSE_ACTIONS: Dictionary[StringName, MouseButton] = {
	&"aim": MOUSE_BUTTON_RIGHT,
	&"shoot": MOUSE_BUTTON_LEFT,
}
const TRIGGERS: Array[JoyAxis] = [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
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


func test_aim_and_shoot_exist_on_keyboard_and_mouse_and_on_gamepad() -> void:
	for action: StringName in MOUSE_ACTIONS:
		assert_true(InputMap.has_action(action), "%s is in the input map" % action)
		var mouse_buttons: Array[MouseButton] = []
		var pad_inputs: int = 0
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventMouseButton:
				mouse_buttons.append((event as InputEventMouseButton).button_index)
			elif event is InputEventJoypadButton:
				pad_inputs += 1
			elif event is InputEventJoypadMotion:
				var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
				var trigger_pulled: bool = TRIGGERS.has(motion.axis) and motion.axis_value > 0.0
				pad_inputs += int(trigger_pulled)
		assert_eq(mouse_buttons.size(), 1, "%s has one mouse button" % action)
		assert_true(mouse_buttons.has(MOUSE_ACTIONS[action]), "%s has its mouse button" % action)
		assert_gt(pad_inputs, 0, "%s has a gamepad button or trigger" % action)


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
