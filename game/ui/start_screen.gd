class_name StartScreen
extends Control
## The start screen: SOLO PRACTICE, DUEL VS GHOST, DUEL VS BOT, TRICK PARK, CHASE and CHASE
## VS BOT, the first one selected, navigated on the keyboard and on the gamepad
## (ChoiceMenu). The duel against the ghost is greyed, with its reason, while no solo run
## is finished in the session. The chase is played by two, player 2 on the gamepad: chosen
## while that gamepad (device 0) is not connected, it says so and waits, and starts as soon
## as it is, unless the selection left it. The chase against the bot needs no gamepad: it
## asks for the level of the bot, EASY, NORMAL or HARD, NORMAL selected first; the menu
## action goes back to the choice of the mode.

signal mode_chosen(choice: Choice)

enum Choice { SOLO_PRACTICE, DUEL_VS_GHOST, DUEL_VS_BOT, TRICK_PARK, CHASE, CHASE_VS_BOT }

## What leaves the choice of the level for the choice of the mode.
const BACK_ACTIONS: Array[StringName] = [&"menu"]

## Whether the gamepad of player 2 is connected; replaceable in the tests.
var has_the_gamepad: Callable = func() -> bool:
	return Input.get_connected_joypads().has(ChaseState.GAMEPAD_DEVICE)

## The level of the bot chosen for the chase against it.
var chosen_level: ChaseBot.Level = ChaseBot.Level.NORMAL

## The chase was chosen without the gamepad: it starts when the gamepad is there.
var _waiting_for_the_gamepad: bool = false

@onready var _menu: ChoiceMenu = %Choices as ChoiceMenu
@onready var _levels: ChoiceMenu = %Levels as ChoiceMenu
@onready var _reason: Label = %Reason as Label
@onready var _gamepad_reason: Label = %GamepadReason as Label


func _ready() -> void:
	_menu.chosen.connect(_on_chosen)
	_levels.back_actions = BACK_ACTIONS
	_levels.chosen.connect(_on_level_chosen)
	_levels.backed.connect(_back_to_the_modes)


## While the chase waits for the gamepad: it starts once the gamepad is there, and stops
## waiting once the selection leaves it.
func _process(_delta: float) -> void:
	if not _waiting_for_the_gamepad or not visible:
		return
	if selected() != Choice.CHASE:
		_wait_for_the_gamepad(false)
	elif has_the_gamepad.call():
		_choose(Choice.CHASE)


## On screen, the first choice selected; the duel against the ghost open or not.
func open(ghost_available: bool) -> void:
	visible = true
	_menu.set_enabled(Choice.DUEL_VS_GHOST, ghost_available)
	_reason.visible = not ghost_available
	_wait_for_the_gamepad(false)
	_back_to_the_modes()


func close() -> void:
	visible = false


func selected() -> Choice:
	return _menu.selected as Choice


## The node of a choice: what is lit or greyed.
func choice_item(choice: Choice) -> Control:
	return _menu.items()[choice]


## The level selected in the choice of the level.
func selected_level() -> ChaseBot.Level:
	return _levels.selected as ChaseBot.Level


## The texts of the choice of the level, in their order; empty while it is not on screen.
func level_texts() -> Array[String]:
	var texts: Array[String] = []
	if not _levels.visible:
		return texts
	for item: Control in _levels.items():
		texts.append((item as Label).text)
	return texts


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
	if choice == Choice.CHASE_VS_BOT:
		_choose_the_level()
		return
	_choose(choice)


## The choice of the level instead of the choice of the mode, NORMAL selected.
func _choose_the_level() -> void:
	_wait_for_the_gamepad(false)
	_menu.visible = false
	_levels.visible = true
	_levels.open()
	_levels.selected = ChaseBot.Level.NORMAL
	_levels.refresh()


## The choice of the mode again, CHASE VS BOT selected if it was left for the level.
func _back_to_the_modes() -> void:
	var from_the_levels: bool = _levels.visible
	_levels.visible = false
	_menu.visible = true
	_menu.open()
	if from_the_levels:
		_menu.selected = Choice.CHASE_VS_BOT
		_menu.refresh()


func _on_level_chosen(index: int) -> void:
	chosen_level = index as ChaseBot.Level
	_choose(Choice.CHASE_VS_BOT)


func _choose(choice: Choice) -> void:
	_wait_for_the_gamepad(false)
	mode_chosen.emit(choice)


func _wait_for_the_gamepad(waiting: bool) -> void:
	_waiting_for_the_gamepad = waiting
	_gamepad_reason.visible = waiting
