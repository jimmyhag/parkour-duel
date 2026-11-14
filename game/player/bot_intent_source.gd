class_name BotIntentSource
extends IntentSource
## The bot of a duel: a runner led by the pilot (PilotIntentSource) in the direction it
## is given, section after section, that does no trick. Given a point to aim at, it aims
## from its head for the aim time of the tuning, slowed on the ground like any runner that
## aims, then presses the shot: the shot goes if its weapon judges the target still ready
## and shootable. What to aim at, and when, is decided for it.

const NOT_AIMING: int = -1

var _runner: Player
var _pilot: PilotIntentSource
var _aim_point: Vector3 = Vector3.ZERO
## Steps aimed at the point so far; NOT_AIMING while it does not aim.
var _steps_aimed: int = NOT_AIMING


func _init(runner: Player, direction: Vector3) -> void:
	_runner = runner
	_pilot = PilotIntentSource.new(runner, direction)


## From now on, runs in `direction`, in the world.
func run_towards(direction: Vector3) -> void:
	_pilot.run_towards(direction)


## Starts aiming at `point`, in the world.
func aim_at(point: Vector3) -> void:
	_aim_point = point
	_steps_aimed = 0


func is_aiming() -> bool:
	return _steps_aimed != NOT_AIMING


func next_intent() -> MoveIntent:
	var intent: MoveIntent = _pilot.next_intent()
	if not is_aiming():
		return intent
	_steps_aimed += 1
	var eyes: Vector3 = _runner.global_position + Vector3.UP * _runner.tuning.camera_look_height
	intent.aim_held = true
	intent.aim_direction = (_aim_point - eyes).normalized()
	var step: float = _runner.get_physics_process_delta_time()
	if _steps_aimed >= roundi(_runner.tuning.bot_aim_time / step):
		intent.shoot_pressed = true
		_steps_aimed = NOT_AIMING
	return intent
