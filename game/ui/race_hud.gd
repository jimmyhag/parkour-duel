class_name RaceHud
extends Control
## The timer of a run, at the top of the screen: TIME while it runs, FINISHED with the
## final time, and BEST with the best time of the session; under them, once the run is
## finished, STYLE with its style score and BEST STYLE with the best of the session.

const TIME: String = "TIME %s"
const FINISHED: String = "FINISHED %s"
const BEST: String = "BEST %s"
const STYLE: String = "STYLE %d"
const BEST_STYLE: String = "BEST STYLE %d"
const NO_BEST_TIME: String = "--:--.--"
const CLOCK: String = "%d:%02d.%02d"
const CENTISECONDS_PER_SECOND: int = 100
const SECONDS_PER_MINUTE: int = 60

## The run to display, and the flow of its runner.
var race: RaceState
var flow: FlowState

@onready var _time_label: Label = %TimeLabel as Label
@onready var _best_label: Label = %BestLabel as Label
@onready var _style_label: Label = %StyleLabel as Label
@onready var _best_style_label: Label = %BestStyleLabel as Label


func _process(_delta: float) -> void:
	refresh()


## Writes the current state of the run on screen.
func refresh() -> void:
	if race == null:
		return
	var time: String = _clock(race.elapsed_steps)
	var finished: bool = race.phase == RaceState.Phase.FINISHED
	_time_label.text = (FINISHED if finished else TIME) % time
	var has_best_time: bool = race.best_steps != RaceState.NO_TIME
	_best_label.text = BEST % (_clock(race.best_steps) if has_best_time else NO_BEST_TIME)
	var shows_the_style: bool = finished and flow != null
	_style_label.visible = shows_the_style
	_best_style_label.visible = shows_the_style
	if shows_the_style:
		_style_label.text = STYLE % flow.style_score
		_best_style_label.text = BEST_STYLE % flow.best_style_score


## A time in fixed steps as minutes:seconds.hundredths.
func _clock(steps: int) -> String:
	var centiseconds: int = race.centiseconds(steps)
	var hundredths: int = centiseconds % CENTISECONDS_PER_SECOND
	@warning_ignore("integer_division")
	var seconds: int = centiseconds / CENTISECONDS_PER_SECOND
	@warning_ignore("integer_division")
	var minutes: int = seconds / SECONDS_PER_MINUTE
	return CLOCK % [minutes, seconds % SECONDS_PER_MINUTE, hundredths]
