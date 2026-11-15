class_name StartScreen
extends Control
## The start screen: SOLO PRACTICE, DUEL VS GHOST, DUEL VS BOT, TRICK PARK, CHASE, CHASE
## VS BOT and CHASE ONLINE, the first one selected, navigated on the keyboard and on the
## gamepad (ChoiceMenu). The duel against the ghost is greyed, with its reason, while no solo
## run is finished in the session. The chase is played by two, player 2 on the gamepad:
## chosen while that gamepad (device 0) is not connected, it says so and waits, and starts as
## soon as it is, unless the selection left it. The chase against the bot needs no gamepad:
## it asks for the level of the bot, EASY, NORMAL or HARD, NORMAL selected first; the menu
## action goes back to the choice of the mode. The chase online (docs/specs/online-chase.md)
## asks HOST or JOIN: HOST shows WAITING FOR A PLAYER, the port and the addresses of the
## machine on its network, and why a player was refused; JOIN asks for the address of the
## host (AddressField), the last one joined in it, then shows CONNECTING… or why it could
## not. What hosts and joins is not here (game/levels): this screen says what was chosen
## and shows what it is told. The menu action goes back one screen, and stops hosting or
## joining. A notice (the other player left) shows over the choice of the mode until the next
## choice.

signal mode_chosen(choice: Choice)
## HOST was chosen, then an address to join, or hosting or joining stopped.
signal host_chosen
signal join_chosen(address: String)
signal online_cancelled

enum Choice {
	SOLO_PRACTICE, DUEL_VS_GHOST, DUEL_VS_BOT, TRICK_PARK, CHASE, CHASE_VS_BOT, CHASE_ONLINE
}
## The choices of the chase online.
enum Online { HOST, JOIN }

## What leaves a screen for the one before.
const BACK_ACTIONS: Array[StringName] = [&"menu"]
const BACK: StringName = &"menu"
const PORT: String = "PORT %d"
const CONNECTING: String = "CONNECTING…"
const FAILURES: Dictionary[LinkStatus.Failure, String] = {
	LinkStatus.Failure.NONE: "",
	LinkStatus.Failure.PORT_ALREADY_IN_USE: "PORT ALREADY IN USE",
	LinkStatus.Failure.COULD_NOT_CONNECT: "COULD NOT CONNECT",
	LinkStatus.Failure.DIFFERENT_GAME_VERSION: "DIFFERENT GAME VERSION",
	LinkStatus.Failure.THE_OTHER_PLAYER_LEFT: "THE OTHER PLAYER LEFT",
}

## Whether the gamepad of player 2 is connected; replaceable in the tests.
var has_the_gamepad: Callable = func() -> bool:
	return Input.get_connected_joypads().has(ChaseState.GAMEPAD_DEVICE)

## The level of the bot chosen for the chase against it.
var chosen_level: ChaseBot.Level = ChaseBot.Level.NORMAL

## The chase was chosen without the gamepad: it starts when the gamepad is there.
var _waiting_for_the_gamepad: bool = false
## The address joined, or being joined.
var _address: String = ""
var _waiting_opened_at_frame: int = -1

@onready var _menu: ChoiceMenu = %Choices as ChoiceMenu
@onready var _levels: ChoiceMenu = %Levels as ChoiceMenu
@onready var _online_panel: Control = %OnlinePanel as Control
@onready var _online: ChoiceMenu = %Online as ChoiceMenu
@onready var _waiting: Control = %Waiting as Control
@onready var _join: Control = %Join as Control
@onready var _address_field: AddressField = %AddressField as AddressField
@onready var _reason: Label = %Reason as Label
@onready var _gamepad_reason: Label = %GamepadReason as Label
@onready var _notice: Label = %Notice as Label
@onready var _online_failure: Label = %OnlineFailure as Label
@onready var _port: Label = %Port as Label
@onready var _addresses: Label = %Addresses as Label
@onready var _waiting_failure: Label = %WaitingFailure as Label
@onready var _join_message: Label = %JoinMessage as Label


func _ready() -> void:
	_menu.chosen.connect(_on_chosen)
	_levels.back_actions = BACK_ACTIONS
	_levels.chosen.connect(_on_level_chosen)
	_levels.backed.connect(_back_to_the_modes)
	_online.back_actions = BACK_ACTIONS
	_online.chosen.connect(_on_online_chosen)
	_online.backed.connect(_back_to_the_modes)
	_address_field.validated.connect(_on_address_validated)
	_address_field.backed.connect(_on_join_backed)


## While the chase waits for the gamepad: it starts once the gamepad is there, and stops
## waiting once the selection leaves it. While it hosts: the menu action stops it.
func _process(_delta: float) -> void:
	if not visible:
		return
	if _waiting.visible and Engine.get_process_frames() != _waiting_opened_at_frame:
		if Input.is_action_just_pressed(BACK):
			online_cancelled.emit()
			_back_to_online(Online.HOST)
	if not _waiting_for_the_gamepad:
		return
	if selected() != Choice.CHASE:
		_wait_for_the_gamepad(false)
	elif has_the_gamepad.call():
		_choose(Choice.CHASE)


## On screen, the first choice selected; the duel against the ghost open or not; the notice
## `notice` over it (none: no notice).
func open(ghost_available: bool, notice: LinkStatus.Failure = LinkStatus.Failure.NONE) -> void:
	visible = true
	_menu.set_enabled(Choice.DUEL_VS_GHOST, ghost_available)
	_reason.visible = not ghost_available
	_wait_for_the_gamepad(false)
	_back_to_the_modes()
	_notice.text = FAILURES[notice]
	_notice.visible = notice != LinkStatus.Failure.NONE


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


## The texts on screen, in the order of the tree: what a player reads.
func shown_texts() -> Array[String]:
	var texts: Array[String] = []
	for label: Node in find_children("*", "Label", true, false):
		var shown: Label = label as Label
		if shown.is_visible_in_tree() and not shown.text.is_empty():
			texts.append(shown.text)
	return texts


## Hosting: WAITING FOR A PLAYER, the port `port` and the addresses `addresses`.
func show_waiting(port: int, addresses: PackedStringArray) -> void:
	_show(_waiting)
	_waiting_opened_at_frame = Engine.get_process_frames()
	_port.text = PORT % port
	_addresses.text = "\n".join(addresses)
	_waiting_failure.text = ""


## Hosting, the last player that came was refused for `failure`.
func show_refusal(failure: LinkStatus.Failure) -> void:
	_waiting_failure.text = FAILURES[failure]


## Hosting could not start, for `failure`: back to HOST and JOIN, with the reason.
func show_host_failure(failure: LinkStatus.Failure) -> void:
	_back_to_online(Online.HOST)
	_online_failure.text = FAILURES[failure]


## Joining: CONNECTING…, under the address.
func show_connecting() -> void:
	if not _join.visible:
		_open_the_join(_address)
	_join_message.text = CONNECTING


## Joining failed, for `failure`: the address again, with the reason.
func show_join_failure(failure: LinkStatus.Failure) -> void:
	_open_the_join(_address)
	_join_message.text = FAILURES[failure]


func _on_chosen(index: int) -> void:
	var choice: Choice = index as Choice
	_notice.visible = false
	if choice == Choice.CHASE and not has_the_gamepad.call():
		_wait_for_the_gamepad(true)
		return
	if choice == Choice.CHASE_VS_BOT:
		_choose_the_level()
		return
	if choice == Choice.CHASE_ONLINE:
		_back_to_online(Online.HOST)
		return
	_choose(choice)


## The choice of the level instead of the choice of the mode, NORMAL selected.
func _choose_the_level() -> void:
	_wait_for_the_gamepad(false)
	_show(_levels)
	_levels.open()
	_levels.selected = ChaseBot.Level.NORMAL
	_levels.refresh()


## The choice of the mode again, the chase against the bot or online selected if it was
## left for its own screen.
func _back_to_the_modes() -> void:
	var from: Choice = Choice.SOLO_PRACTICE
	if _levels.visible:
		from = Choice.CHASE_VS_BOT
	elif _online_panel.visible:
		from = Choice.CHASE_ONLINE
	_show(_menu)
	_menu.open()
	if from != Choice.SOLO_PRACTICE:
		_menu.selected = from
		_menu.refresh()


## HOST and JOIN, `choice` selected, without a reason.
func _back_to_online(choice: Online) -> void:
	_wait_for_the_gamepad(false)
	_show(_online_panel)
	_online.open()
	_online.selected = choice
	_online.refresh()
	_online_failure.text = ""


func _on_online_chosen(index: int) -> void:
	if index == Online.HOST:
		host_chosen.emit()
	else:
		_open_the_join(_address)


## The address to join, `shown` in it.
func _open_the_join(shown: String) -> void:
	_show(_join)
	_address_field.open(shown)
	_join_message.text = ""


## Joining an address can only be asked once: the field waits for the answer.
func _on_address_validated(address: String) -> void:
	if _join_message.text == CONNECTING:
		return
	_address = address
	join_chosen.emit(address)


func _on_join_backed() -> void:
	if _join_message.text == CONNECTING:
		online_cancelled.emit()
	_back_to_online(Online.JOIN)


## The address last joined, shown when JOIN opens.
func remember(address: String) -> void:
	_address = address


func _on_level_chosen(index: int) -> void:
	chosen_level = index as ChaseBot.Level
	_choose(Choice.CHASE_VS_BOT)


func _choose(choice: Choice) -> void:
	_wait_for_the_gamepad(false)
	mode_chosen.emit(choice)


func _wait_for_the_gamepad(waiting: bool) -> void:
	_waiting_for_the_gamepad = waiting
	_gamepad_reason.visible = waiting


## Only `panel` of the screens of choices is on screen.
func _show(panel: Control) -> void:
	for each: Control in [_menu, _levels, _online_panel, _waiting, _join]:
		each.visible = each == panel
