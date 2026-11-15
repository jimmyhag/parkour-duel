class_name ChaseRoundScreen
extends Control
## The screen between two rounds of the chase (ChaseState, game/core), over both views:
## who won the round that just ended, CAT WINS or MOUSE WINS, and the rounds each player
## has won; the countdown of the next round shows over it. Hidden during a round and once
## the match is over. Nothing takes the focus.

const CAT_WINS: String = "CAT WINS"
const MOUSE_WINS: String = "MOUSE WINS"
const SCORE: String = "PLAYER 1   %d - %d   PLAYER 2"

## The chase to show.
var chase: ChaseState

@onready var _verdict: Label = %Verdict as Label
@onready var _score: Label = %Score as Label


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	visible = chase != null and chase.phase == ChaseState.Phase.ROUND_OVER
	if not visible:
		return
	var cat_won: bool = chase.round_winner_role == ChaseState.Role.CAT
	_verdict.text = CAT_WINS if cat_won else MOUSE_WINS
	_verdict.modulate = (
		chase.tuning.chase_cat_colour if cat_won else chase.tuning.chase_mouse_colour
	)
	_score.text = SCORE % [chase.score[0], chase.score[1]]


## The texts of the verdict and of the score.
func lines() -> Array[String]:
	return [_verdict.text, _score.text]
