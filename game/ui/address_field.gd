class_name AddressField
extends Label
## The address of the host of an online chase, typed (docs/specs/online-chase.md, decision
## 9): on the keyboard, the digits, the dot and the colon go in at the cursor, Backspace and
## Delete take out, the arrows move the cursor; on the gamepad (or with the arrows, W and S),
## up and down change the character under the cursor among 0-9 . : (past the last one, or
## before the first, it goes, and the next one in its place is under the cursor), left and
## right move the cursor, a step past the end being a new place. Jump (Space, A) validates,
## the menu action (Escape, Start) goes back. The character under the cursor is shown between
## brackets. It reads the inputs only while it is on screen, and not at the frame it opens.

signal validated(address: String)
signal backed

const CHARACTERS: String = "0123456789.:"
## The longest address: 255.255.255.255:65535.
const LONGEST: int = 21
const UP: StringName = &"menu_up"
const DOWN: StringName = &"menu_down"
const LEFT: StringName = &"menu_left"
const RIGHT: StringName = &"menu_right"
const VALIDATE: StringName = &"jump"
const BACK: StringName = &"menu"
const SHOWN: String = "%s[%s]%s"
const NO_CHARACTER: String = " "

var address: String = ""
## Where the cursor is: on the character of this index, or past the end.
var cursor: int = 0

var _opened_at_frame: int = -1


func _process(_delta: float) -> void:
	if not _reads():
		return
	if Input.is_action_just_pressed(UP):
		change(1)
	elif Input.is_action_just_pressed(DOWN):
		change(-1)
	elif Input.is_action_just_pressed(LEFT):
		move(-1)
	elif Input.is_action_just_pressed(RIGHT):
		move(1)
	elif Input.is_action_just_pressed(VALIDATE):
		validated.emit(address)
	elif Input.is_action_just_pressed(BACK):
		backed.emit()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or not _reads():
		return
	var typed: String = char(key.unicode) if key.unicode > 0 else ""
	if typed != "" and CHARACTERS.contains(typed):
		type(typed)
	elif key.physical_keycode == KEY_BACKSPACE and cursor > 0:
		cursor -= 1
		address = address.erase(cursor)
	elif key.physical_keycode == KEY_DELETE:
		address = address.erase(cursor)
	elif key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		validated.emit(address)
	else:
		return
	refresh()
	get_viewport().set_input_as_handled()


## On screen with `shown`, the cursor past its end.
func open(shown: String) -> void:
	_opened_at_frame = Engine.get_process_frames()
	address = shown
	cursor = address.length()
	refresh()


## Puts `typed` in at the cursor, which moves past it.
func type(typed: String) -> void:
	if address.length() >= LONGEST:
		return
	address = address.insert(cursor, typed)
	cursor += 1
	refresh()


## The character under the cursor `way` further among CHARACTERS: none past either end.
func change(way: int) -> void:
	var index: int = -1
	if cursor < address.length():
		index = CHARACTERS.find(address[cursor])
		address = address.erase(cursor)
	elif address.length() >= LONGEST:
		return
	if index < 0:
		index = 0 if way > 0 else CHARACTERS.length() - 1
	else:
		index += way
	if index >= 0 and index < CHARACTERS.length():
		address = address.insert(cursor, CHARACTERS[index])
	refresh()


## The cursor `way` further, from the first character to the place past the last one.
func move(way: int) -> void:
	cursor = clampi(cursor + way, 0, address.length())
	refresh()


func refresh() -> void:
	var under: String = address[cursor] if cursor < address.length() else NO_CHARACTER
	text = SHOWN % [address.substr(0, cursor), under, address.substr(cursor + 1)]


func _reads() -> bool:
	return is_visible_in_tree() and Engine.get_process_frames() != _opened_at_frame
