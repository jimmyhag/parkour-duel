class_name StartScreen
extends Control
## The start screen: SOLO PRACTICE, DUEL VS GHOST, DUEL VS BOT, TRICK PARK and CHASE, the
## first one selected, navigated on the keyboard and on the gamepad (ChoiceMenu). The duel
## against the ghost is greyed, with its reason, while no solo run is finished in the
## session. The chase is played by two, player 2 on the gamepad: chosen while that gamepad
## (device 0) is not connected, it says so and waits, and starts as soon as it is.

signal mode_chosen(choice: Choice)

enum Choice { SOLO_PRACTICE, DUEL_VS_GHOST, DUEL_VS_BOT, TRICK_PARK, CHASE }

## The gamepad of player 2 in the chase.
const GAMEPAD_DEVICE: int = 0

## Whether the gamepad of player 2 is connected; replaceable in the tests.
var has_the_gamepad: Callable = func() -> bool:
	return Input.get_connected_joypads().has(GAMEPAD_DEVICE)

## The chase was chosen without the gamepad: it starts when the gamepad is there.
var _waiting_for_the_gamepad: bool = false

@onready var _menu: ChoiceMenu = %Choices as ChoiceMenu
@onready var _reason: Label = %Reason as Label
@onready var _gamepad_reason: Label = %GamepadReason as Label


func _ready() -> void:
	_menu.chosen.connect(_on_chosen)


func _process(_delta: float) -> void:
	if _waiting_for_the_gamepad and visible and has_the_gamepad.call():
		_choose(Choice.CHASE)


## On screen, the first choice selected; the duel against the ghost open or not.
func open(ghost_available: bool) -> void:
	visible = true
	_menu.set_enabled(Choice.DUEL_VS_GHOST, ghost_available)
	_reason.visible = not ghost_available
	_wait_for_the_gamepad(false)
	_menu.open()


func close() -> void:
	visible = false


func selected() -> Choice:
	return _menu.selected as Choice


## The node of a choice: what is lit or greyed.
func choice_item(choice: Choice) -> Control:
	return _menu.items()[choice]


## The label that names a choice.
func choice_label(choice: Choice) -> Label:
	var item: Control = choice_item(choice)
	if item is Label:
		return item as Label
	return item.get_node("Label") as Label


func _on_chosen(index: int) -> void:
	var choice: Choice = index as Choice
	if choice == Choice.CHASE and not has_the_gamepad.call():
		_wait_for_the_gamepad(true)
		return
	_choose(choice)


func _choose(choice: Choice) -> void:
	_wait_for_the_gamepad(false)
	mode_chosen.emit(choice)


func _wait_for_the_gamepad(waiting: bool) -> void:
	_waiting_for_the_gamepad = waiting
	_gamepad_reason.visible = waiting
