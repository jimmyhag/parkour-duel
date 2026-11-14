class_name CountdownDisplay
extends Label
## The countdown of a round, in large in the middle of the screen: 3, 2, 1, then GO, as
## the clock of the round (RoundClock, game/core) counts them; nothing otherwise. Nothing
## takes the focus.

const GO: String = "GO"

## The clock to show.
var clock: RoundClock


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	var number: int = RoundClock.NO_COUNTDOWN if clock == null else clock.countdown()
	visible = number != RoundClock.NO_COUNTDOWN
	if visible:
		text = GO if number == RoundClock.GO else str(number)
