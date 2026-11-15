class_name ChaseRoundScreen
extends Control
## The screen between two rounds of the chase (ChaseState, game/core), over both views:
## who won the round that just ended, CAT WINS under CAUGHT! (the cat wins a round only by
## catching the mouse, docs/specs/chase-tag.md) or MOUSE WINS, and the rounds each player
## has won, with their names (PLAYER 1 and PLAYER 2, YOU and BOT against the bot, YOU and
## FRIEND online, each machine calling its own player YOU); the
## countdown of the next round shows over it. Hidden during a round, while it waits (the
## pause after a catch, docs/specs/chase-tag-polish.md), and once the match is over. Nothing
## takes the focus.

const CAT_WINS: String = "CAT WINS"
const MOUSE_WINS: String = "MOUSE WINS"
const SCORE: String = "%s   %d - %d   %s"
## Online, what each machine calls its own player and the other one.
const YOU: String = "YOU"
const FRIEND: String = "FRIEND"

## The chase to show.
var chase: ChaseState
## The names of player 1 and of player 2.
var names: Array[String] = ["PLAYER 1", "PLAYER 2"]
## The screen waits, hidden, though the round is over.
var waiting: bool = false

@onready var _caught: Label = %Caught as Label
@onready var _verdict: Label = %Verdict as Label
@onready var _score: Label = %Score as Label


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	visible = chase != null and chase.phase == ChaseState.Phase.ROUND_OVER and not waiting
	if not visible:
		return
	var cat_won: bool = chase.round_winner_role == ChaseState.Role.CAT
	_caught.visible = cat_won
	_verdict.text = CAT_WINS if cat_won else MOUSE_WINS
	_verdict.modulate = (
		chase.tuning.chase_cat_colour if cat_won else chase.tuning.chase_mouse_colour
	)
	_score.text = SCORE % [names[0], chase.score[0], chase.score[1], names[1]]


## Online: the player `player` of this machine is YOU, the other one FRIEND.
func name_online(player: int) -> void:
	var online: Array[String] = [YOU, FRIEND]
	if player != 0:
		online.reverse()
	names = online


## The texts shown: CAUGHT! when the cat won, the verdict and the score.
func lines() -> Array[String]:
	var shown: Array[String] = [_verdict.text, _score.text]
	if _caught.visible:
		shown.push_front(_caught.text)
	return shown
