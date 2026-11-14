class_name InputDevice
extends RefCounted
## The device a runner's inputs come from. Alone, any device plays: the actions of the
## input map as they are. In a split screen, player 1 plays on the keyboard and the
## mouse only, player 2 on the first gamepad (device 0) only. The input map knows no
## player: an action is pressed by any device that has one of its events. So a device of
## its own reads actions of its own, made at run time from the actions of the project,
## the first time they are asked for: the same name with the device as a suffix, holding
## only the keys and the mouse buttons of the action, or only its gamepad buttons and axes,
## set to device 0. The project's actions are left as they are.

enum Kind { ANY, KEYBOARD_AND_MOUSE, GAMEPAD }

## The gamepad of player 2.
const GAMEPAD_DEVICE: int = 0
const SUFFIXES: Dictionary[Kind, String] = {
	Kind.KEYBOARD_AND_MOUSE: "@keyboard_and_mouse",
	Kind.GAMEPAD: "@gamepad",
}


## The action to read for `action` on the device `kind`.
static func action(base: StringName, kind: Kind) -> StringName:
	if kind == Kind.ANY:
		return base
	var own: StringName = StringName(String(base) + SUFFIXES[kind])
	if InputMap.has_action(own):
		return own
	InputMap.add_action(own, InputMap.action_get_deadzone(base))
	for event: InputEvent in InputMap.action_get_events(base):
		if not _belongs_to(event, kind):
			continue
		var copy: InputEvent = event.duplicate() as InputEvent
		if kind == Kind.GAMEPAD:
			copy.device = GAMEPAD_DEVICE
		InputMap.action_add_event(own, copy)
	return own


## Whether `event` comes from the device `kind`: a key or the mouse for the keyboard and
## the mouse, a button or an axis of the gamepad for the gamepad.
static func _belongs_to(event: InputEvent, kind: Kind) -> bool:
	match kind:
		Kind.KEYBOARD_AND_MOUSE:
			return event is InputEventKey or event is InputEventMouse
		Kind.GAMEPAD:
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return true
