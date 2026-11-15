class_name ResultScreen
extends Control
## The result of a round of a duel (RoundState, game/core), for runner 0, the player: YOU
## WIN, YOU LOSE or DRAW, in large; one line per runner (YOU, then GHOST or BOT) with its
## time or DNF and its style score. Or the result of a chase (ChaseState): PLAYER 1 WINS or
## PLAYER 2 WINS, and the rounds each player won; against the bot, YOU WIN or BOT WINS,
## and the rounds of YOU and of the BOT; online, YOU WIN or FRIEND WINS, and the rounds of
## YOU and of the FRIEND (docs/specs/online-chase.md). Then REMATCH and MENU, navigated on the
## keyboard and on the gamepad (ChoiceMenu). The menu action, or the restart one (Esc or
## Back), also goes back to the start screen. Hidden during the round.

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
const PLAYER_WINS: String = "PLAYER %d WINS"
const PLAYER_ROUNDS: String = "PLAYER %d   %d"
const OTHER_WINS: String = "%s WINS"
## Online, what each machine calls the other player.
const FRIEND: String = "FRIEND"
const ROUNDS: String = "%s   %d"
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


## Shows how the chase ended: its winner, and the rounds each player won, REMATCH
## selected; `against_the_bot`, player 2 is the bot.
func show_chase(chase: ChaseState, against_the_bot: bool = false) -> void:
	if against_the_bot:
		show_chase_of(chase, PLAYER, OPPONENT_NAMES[Opponent.BOT])
		return
	_verdict.text = PLAYER_WINS % (chase.winner + 1)
	_you_line.text = PLAYER_ROUNDS % [1, chase.score[0]]
	_them_line.text = PLAYER_ROUNDS % [2, chase.score[1]]
	visible = true
	_menu.open()


## Shows how the chase online ended for the player `player` of this machine, against its
## FRIEND.
func show_chase_online(chase: ChaseState, player: int) -> void:
	show_chase_of(chase, player, FRIEND)


## Shows how the chase ended for the player `player`, against the other one, named
## `other_name`: YOU WIN or its name WINS, and the rounds of YOU and of it, REMATCH selected.
func show_chase_of(chase: ChaseState, player: int, other_name: String) -> void:
	_verdict.text = YOU_WIN if chase.winner == player else OTHER_WINS % other_name
	_you_line.text = ROUNDS % [YOU, chase.score[player]]
	_them_line.text = ROUNDS % [other_name, chase.score[1 - player]]
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
