class_name ChoiceMenu
extends VBoxContainer
## A list of choices, one per child, navigated on the keyboard and on the gamepad: up and
## down (the arrows, W and S, the left stick, the cross) change the choice, jump (Space,
## A) takes it, and the back actions, if it has any, leave it. The selected choice is lit,
## a disabled one is greyed and skipped. It reads the inputs only while it is on screen,
## and not at the frame it opens: the press that opened it does not choose in it.

signal chosen(index: int)
signal backed

const UP: StringName = &"menu_up"
const DOWN: StringName = &"menu_down"
const CHOOSE: StringName = &"jump"
const SELECTED_COLOR: Color = Color(1.0, 0.85, 0.3)
const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0, 0.85)
const DISABLED_COLOR: Color = Color(1.0, 1.0, 1.0, 0.3)

## The actions that leave the list; none unless its screen gives some.
var back_actions: Array[StringName] = []
var selected: int = 0

var _disabled: Dictionary[int, bool] = {}
var _opened_at_frame: int = -1


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or Engine.get_process_frames() == _opened_at_frame:
		return
	if Input.is_action_just_pressed(UP):
		_move(-1)
	elif Input.is_action_just_pressed(DOWN):
		_move(1)
	elif Input.is_action_just_pressed(CHOOSE):
		if is_enabled(selected):
			chosen.emit(selected)
	else:
		for action: StringName in back_actions:
			if Input.is_action_just_pressed(action):
				backed.emit()
				return


## The choices, in their order.
func items() -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in get_children():
		var item: Control = child as Control
		if item != null:
			found.append(item)
	return found


func is_enabled(index: int) -> bool:
	return not _disabled.get(index, false)


func set_enabled(index: int, enabled: bool) -> void:
	_disabled[index] = not enabled
	refresh()


## Ready to be used: the first choice it may take selected.
func open() -> void:
	_opened_at_frame = Engine.get_process_frames()
	selected = 0
	while selected < items().size() - 1 and not is_enabled(selected):
		selected += 1
	refresh()


## Lights the selected choice, greys the disabled ones.
func refresh() -> void:
	var all: Array[Control] = items()
	for index: int in all.size():
		var colour: Color = NORMAL_COLOR
		if not is_enabled(index):
			colour = DISABLED_COLOR
		elif index == selected:
			colour = SELECTED_COLOR
		all[index].modulate = colour


## The next choice it may take that way, if there is one.
func _move(way: int) -> void:
	var index: int = selected + way
	while index >= 0 and index < items().size():
		if is_enabled(index):
			selected = index
			refresh()
			return
		index += way
