class_name RaceState
extends RefCounted
## The state of one run on a course: not started, running or finished, the time
## elapsed, the last checkpoint reached and the best time of the session. Time is
## counted in fixed steps, so the timer does not depend on the frame rate. It also
## holds the rule that sends a runner back to a checkpoint. Nothing is saved to disk.

enum Phase { NOT_STARTED, RUNNING, FINISHED }
## What a course must do with its runner: nothing, or put it back at the last
## checkpoint (after a restart, that checkpoint is the start).
enum RespawnOrder { NONE, RESPAWN, RESTART }

## The best time while no run has been finished.
const NO_TIME: int = -1
## The checkpoint of the start platform.
const FIRST_CHECKPOINT: int = 0
const CENTISECONDS_PER_SECOND: int = 100

var phase: Phase = Phase.NOT_STARTED
var elapsed_steps: int = 0
var best_steps: int = NO_TIME
var last_checkpoint: int = FIRST_CHECKPOINT
## Whether its runner may restart the course: not in a duel, where the rematch replaces
## it.
var restartable: bool = true

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


## The respawn rule, evaluated at every fixed step with the runner's altitude, the
## altitude under which it has fallen off the course, and its intent. A runner that
## fell or asks for it goes back to the last checkpoint, and the timer is not touched.
## Restarting wins over respawning: the race itself is then restarted here, if it may be;
## otherwise the request does nothing.
func apply_respawn_rule(altitude: float, fall_limit: float, intent: MoveIntent) -> RespawnOrder:
	if intent.restart_requested and restartable:
		restart()
		return RespawnOrder.RESTART
	if intent.respawn_requested or altitude < fall_limit:
		return RespawnOrder.RESPAWN
	return RespawnOrder.NONE


## A number of fixed steps as hundredths of a second, rounded down.
func centiseconds(steps: int) -> int:
	@warning_ignore("integer_division")
	return steps * CENTISECONDS_PER_SECOND / _steps_per_second
