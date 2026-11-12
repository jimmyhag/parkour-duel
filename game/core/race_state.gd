class_name RaceState
extends RefCounted
## The state of one run on a course: not started, running or finished, the time
## elapsed, the last checkpoint reached and the best time of the session. Time is
## counted in fixed steps, so the timer does not depend on the frame rate. Nothing is
## saved to disk.

enum Phase { NOT_STARTED, RUNNING, FINISHED }

## The best time while no run has been finished.
const NO_TIME: int = -1
## The checkpoint of the start platform.
const FIRST_CHECKPOINT: int = 0
const CENTISECONDS_PER_SECOND: int = 100

var phase: Phase = Phase.NOT_STARTED
var elapsed_steps: int = 0
var best_steps: int = NO_TIME
var last_checkpoint: int = FIRST_CHECKPOINT

var _steps_per_second: int


func _init(steps_per_second: int) -> void:
	_steps_per_second = steps_per_second


## One fixed step of the simulation has passed.
func tick() -> void:
	if phase == Phase.RUNNING:
		elapsed_steps += 1


func cross_start_line() -> void:
	if phase == Phase.NOT_STARTED:
		phase = Phase.RUNNING


func cross_finish_line() -> void:
	if phase != Phase.RUNNING:
		return
	phase = Phase.FINISHED
	if best_steps == NO_TIME or elapsed_steps < best_steps:
		best_steps = elapsed_steps


## Checkpoints are numbered along the course: one already passed never moves the
## respawn point back.
func reach_checkpoint(index: int) -> void:
	last_checkpoint = maxi(last_checkpoint, index)


## Back before the start line, timer at zero. The best time of the session stays.
func restart() -> void:
	phase = Phase.NOT_STARTED
	elapsed_steps = 0
	last_checkpoint = FIRST_CHECKPOINT


## A number of fixed steps as hundredths of a second, rounded down.
func centiseconds(steps: int) -> int:
	@warning_ignore("integer_division")
	return steps * CENTISECONDS_PER_SECOND / _steps_per_second
