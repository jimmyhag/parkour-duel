class_name StartScreen
extends Control
## The start screen: SOLO PRACTICE, DUEL VS GHOST, DUEL VS BOT and TRICK PARK, the first one
## selected,
## navigated on the keyboard and on the gamepad (ChoiceMenu). The duel against the ghost
## is greyed, with its reason, while no solo run is finished in the session.

signal mode_chosen(choice: Choice)

enum Choice { SOLO_PRACTICE, DUEL_VS_GHOST, DUEL_VS_BOT, TRICK_PARK }

@onready var _menu: ChoiceMenu = %Choices as ChoiceMenu
@onready var _reason: Label = %Reason as Label


func _ready() -> void:
	_menu.chosen.connect(_on_chosen)


## On screen, the first choice selected; the duel against the ghost open or not.
func open(ghost_available: bool) -> void:
	visible = true
	_menu.set_enabled(Choice.DUEL_VS_GHOST, ghost_available)
	_reason.visible = not ghost_available
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
	mode_chosen.emit(index as Choice)
