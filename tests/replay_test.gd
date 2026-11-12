class_name ReplayTest
extends GutTest
## Base of the test scripts that replay a run without a screen, in the real physics.
## Their tests run faster than real time with the same fixed step of 1/60 s (see
## before_all), and their runs can be led by the test pilot (see _pilot_to and _play).

## The fixed steps of the game, and how many times faster than real time they run here.
const STEPS_PER_SECOND: int = 60
const SPEED_UP: int = 10

var _ticks_per_second_before: int
var _time_scale_before: float


## Ten times more fixed steps per second, on a clock ten times faster: every step still
## simulates 1/60 s, so the runs are the same, only sooner.
func before_all() -> void:
	_ticks_per_second_before = Engine.physics_ticks_per_second
	_time_scale_before = Engine.time_scale
	Engine.physics_ticks_per_second = STEPS_PER_SECOND * SPEED_UP
	Engine.time_scale = SPEED_UP


func after_all() -> void:
	Engine.physics_ticks_per_second = _ticks_per_second_before
	Engine.time_scale = _time_scale_before


## Lets the test pilot lead `runner` from where it is towards `goal`, over the blocks
## of `course`, and returns the run once it is over.
func _pilot_to(runner: Player, goal: Area3D, course: Node) -> PilotedRun:
	var run: PilotedRun = PilotedRun.new(runner, goal, course)
	await _play([run])
	return run


## Plays piloted runs to their end, all at the same time: each one needs its own
## course, away from the others.
func _play(runs: Array[PilotedRun]) -> void:
	var running: int = runs.size()
	while running > 0:
		await get_tree().physics_frame
		running = 0
		for run: PilotedRun in runs:
			run.observe_step()
			running += int(not run.is_over)
	var step: float = get_physics_process_delta_time()
	assert_almost_eq(step, 1.0 / STEPS_PER_SECOND, 0.000001, "a fixed step lasts 1/60 s")
