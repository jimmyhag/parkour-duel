extends GutTest
## The repetition of the moves of the flow (game/core) across the errors: an error breaks
## the combo but keeps the last moves the repetition judges against; only a fall and a
## restart forget them (docs/specs/flow-combo.md, as amended on 2026-11-15 with
## docs/specs/vault.md). The tuning is the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const HARD_LANDING: RunnerEvent.Kind = RunnerEvent.Kind.HARD_LANDING
## The stop duration of the fixed tuning (1 s), in fixed steps at 60 steps per second.
const STOP_STEPS: int = 60
## The horizontal speed of a runner at the top speed of the fixed tuning, in m/s.
const RUNNING: float = 9.0

var _tuning: MovementTuning
## The fixed step of the messages written by the test.
var _step: int = 0


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()
	_step = 0


func test_an_error_does_not_make_the_moves_new_again() -> void:
	# Stopping on purpose makes no move new again.
	var errors: Array[String] = ["a hard landing", "a crash", "a sabotage", "a stop"]
	for what: String in errors:
		var erring: FlowState = _flow()
		_move(erring, RunnerEvent.Kind.VAULT)
		_move(erring, RunnerEvent.Kind.VAULT)
		assert_eq(erring.last_points, 75, "%s: a second vault in a row is worth half" % what)
		match what:
			"a hard landing":
				_move(erring, HARD_LANDING)
			"a crash":
				_move(erring, RunnerEvent.Kind.CRASH)
			"a sabotage":
				erring.sabotaged()
			_:
				_wait(erring, STOP_STEPS, true, 0.0)
		assert_false(erring.in_combo(), "%s breaks the combo" % what)
		assert_eq(erring.combos_broken, 1, "%s is an error" % what)
		_move(erring, RunnerEvent.Kind.VAULT)
		assert_eq(erring.last_points, 0, "after %s, a third vault is worth nothing" % what)

	for what: String in ["a fall", "a restart"]:
		var starting: FlowState = _flow()
		_move(starting, RunnerEvent.Kind.VAULT)
		_move(starting, RunnerEvent.Kind.VAULT)
		if what == "a fall":
			starting.respawn()
		else:
			starting.restart()
		_move(starting, RunnerEvent.Kind.VAULT)
		assert_eq(starting.last_points, 150, "after %s, the vault is new again" % what)


func _flow() -> FlowState:
	return FlowState.new(_tuning, STEPS_PER_SECOND)


## One fixed step at which the motor announced `kind`, the runner in the air at the top
## speed.
func _move(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	_step += 1
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, _step)]
	flow.step(events, RUNNING, false)


## Fixed steps at which the motor announced nothing, the runner on its feet at `speed`.
func _wait(flow: FlowState, steps: int, on_foot: bool, speed: float) -> void:
	var none: Array[RunnerEvent] = []
	for i: int in steps:
		_step += 1
		flow.step(none, speed, on_foot)
