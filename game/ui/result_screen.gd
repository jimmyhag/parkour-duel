class_name ResultScreen
extends Control
## The result of a round of a duel (RoundState, game/core), for runner 0, the player: YOU
## WIN, YOU LOSE or DRAW, in large; one line per runner (YOU, then GHOST or BOT) with its
## time or DNF and its style score; then REMATCH and MENU, navigated on the keyboard and
## on the gamepad (ChoiceMenu). The menu action, or the restart one (Esc or Back), also
## goes back to the start screen. Hidden during the round.

signal rematch_chosen
signal menu_chosen

enum Choice { REMATCH, MENU }
## Who the player ran against.
enum Opponent { GHOST, BOT }

const YOU_WIN: String = "YOU WIN"
const YOU_LOSE: String = "YOU LOSE"
const DRAW: String = "DRAW"
const YOU: String = "YOU"
const DNF: String = "DNF"
const OPPONENT_NAMES: Dictionary[Opponent, String] = {
	Opponent.GHOST: "GHOST",
	Opponent.BOT: "BOT",
}
const LINE: String = "%s   %s   STYLE %d"
const PLAYER: int = 0
const OPPONENT: int = 1
const BACK_ACTIONS: Array[StringName] = [&"menu", &"restart"]

@onready var _verdict: Label = %Verdict as Label
@onready var _you_line: Label = %YouLine as Label
@onready var _them_line: Label = %ThemLine as Label
@onready var _menu: ChoiceMenu = %Choices as ChoiceMenu


func _ready() -> void:
	visible = false
	_menu.back_actions = BACK_ACTIONS
	_menu.chosen.connect(_on_chosen)
	_menu.backed.connect(_on_backed)


## Shows how the round ended, with the style score of each runner, REMATCH selected.
func show_round(round_state: RoundState, opponent: Opponent, styles: Array[int]) -> void:
	match round_state.winner:
		PLAYER:
			_verdict.text = YOU_WIN
		OPPONENT:
			_verdict.text = YOU_LOSE
		_:
			_verdict.text = DRAW
	_you_line.text = _line(round_state, PLAYER, YOU, styles[PLAYER])
	_them_line.text = _line(round_state, OPPONENT, OPPONENT_NAMES[opponent], styles[OPPONENT])
	visible = true
	_menu.open()


func hide_result() -> void:
	visible = false


func selected() -> Choice:
	return _menu.selected as Choice


func choice_texts() -> Array[String]:
	var texts: Array[String] = []
	for item: Control in _menu.items():
		texts.append((item as Label).text)
	return texts


func _line(round_state: RoundState, runner: int, runner_name: String, style: int) -> String:
	var time: String = DNF
	if round_state.has_finished(runner):
		time = RaceHud.clock(round_state.centiseconds(round_state.finish_step(runner)))
	return LINE % [runner_name, time, style]


func _on_chosen(index: int) -> void:
	hide_result()
	if index == Choice.REMATCH:
		rematch_chosen.emit()
	else:
		menu_chosen.emit()


func _on_backed() -> void:
	hide_result()
	menu_chosen.emit()
