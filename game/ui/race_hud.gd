class_name RaceHud
extends Control
## The timer of a run, at the top of the screen: TIME while it runs, FINISHED with the
## final time, and BEST with the best time of the session; under them, once the run is
## finished, STYLE with its style score and BEST STYLE with the best of the session. In a
## duel, beside the timer, the gap with the opponent at their last common checkpoint
## (+1.24: behind it, -0.80: ahead of it), and neither the best time nor the style.

const TIME: String = "TIME %s"
const FINISHED: String = "FINISHED %s"
const BEST: String = "BEST %s"
const STYLE: String = "STYLE %d"
const BEST_STYLE: String = "BEST STYLE %d"
const GAP: String = "%+.2f"
const NO_BEST_TIME: String = "--:--.--"
const CLOCK: String = "%d:%02d.%02d"
const CENTISECONDS_PER_SECOND: int = 100
const SECONDS_PER_MINUTE: int = 60

## The run to display, and the flow of its runner.
var race: RaceState
var flow: FlowState
## In a duel: the round, and the runner of this display in it.
var round_state: RoundState
var runner: int = 0

@onready var _time_label: Label = %TimeLabel as Label
@onready var _gap_label: Label = %GapLabel as Label
@onready var _best_label: Label = %BestLabel as Label
@onready var _style_label: Label = %StyleLabel as Label
@onready var _best_style_label: Label = %BestStyleLabel as Label


func _process(_delta: float) -> void:
	refresh()


## A time in hundredths of a second as minutes:seconds.hundredths.
static func clock(centiseconds: int) -> String:
	var hundredths: int = centiseconds % CENTISECONDS_PER_SECOND
	@warning_ignore("integer_division")
	var seconds: int = centiseconds / CENTISECONDS_PER_SECOND
	@warning_ignore("integer_division")
	var minutes: int = seconds / SECONDS_PER_MINUTE
	return CLOCK % [minutes, seconds % SECONDS_PER_MINUTE, hundredths]


## Writes the current state of the run on screen.
func refresh() -> void:
	if race == null:
		return
	var time: String = clock(race.centiseconds(race.elapsed_steps))
	var finished: bool = race.phase == RaceState.Phase.FINISHED
	_time_label.text = (FINISHED if finished else TIME) % time
	var in_a_duel: bool = round_state != null
	_best_label.visible = not in_a_duel
	var has_best_time: bool = race.best_steps != RaceState.NO_TIME
	var best_time: String = clock(race.centiseconds(race.best_steps))
	_best_label.text = BEST % (best_time if has_best_time else NO_BEST_TIME)
	_gap_label.visible = in_a_duel and round_state.has_gap(runner)
	if _gap_label.visible:
		_gap_label.text = (
			GAP % (round_state.gap_centiseconds(runner) / float(CENTISECONDS_PER_SECOND))
		)
	var shows_the_style: bool = finished and flow != null and not in_a_duel
	_style_label.visible = shows_the_style
	_best_style_label.visible = shows_the_style
	if shows_the_style:
		_style_label.text = STYLE % flow.style_score
		_best_style_label.text = BEST_STYLE % flow.best_style_score
