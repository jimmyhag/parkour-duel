class_name PilotIntentSource
extends IntentSource
## The test pilot: a source of intents that, at every fixed step, looks at its runner
## and at the physical world around it, then decides. It runs in a given direction,
## jumps when the floor stops just ahead or when a step it can clear stands just ahead,
## and holds the jump up to its top. It never jumps in the air or on a floor that goes
## on. It knows no course: only what it probes, the state of the runner and the tuning,
## from which its look-ahead distances are worked out.

var _runner: Player
var _direction: Vector3


## `direction` is where to run, in the world; only its horizontal part counts.
func _init(runner: Player, direction: Vector3) -> void:
	_runner = runner
	_direction = Vector3(direction.x, 0.0, direction.z).normalized()


func next_intent() -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = _direction
	if _runner.is_on_floor():
		intent.jump_pressed = _floor_stops_ahead() or _step_stands_ahead()
	intent.jump_held = intent.jump_pressed or _runner.motor.state == RunnerMotor.State.RISING
	return intent


## The floor stops where the runner will stand after this step: under that point there
## is no ground down to a jump height below its feet, the deepest drop it could jump
## back from. Jumping now is jumping from the last step on the floor.
func _floor_stops_ahead() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var stride: float = _speed_ahead() * _runner.get_physics_process_delta_time()
	var feet: Vector3 = _runner.global_position + _direction * stride
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		feet + Vector3.UP * tuning.capsule_height / 2.0,
		feet + Vector3.DOWN * tuning.jump_height,
		_runner.collision_mask,
		[_runner.get_rid()]
	)
	ray.hit_from_inside = true
	return _runner.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


## A step stands ahead when something would stop the runner's body before the distance
## it covers while a jump rises, and the same body, lifted by a jump height, would pass
## over it with room to stand on it. Jumping now tops the jump as the runner gets there.
func _step_stands_ahead() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var take_off_speed: float = sqrt(2.0 * tuning.rise_gravity * tuning.jump_height)
	var rise_seconds: float = take_off_speed / tuning.rise_gravity
	var here: Transform3D = _runner.global_transform
	var obstacle: KinematicCollision3D = KinematicCollision3D.new()
	if not _runner.test_move(here, _direction * _speed_ahead() * rise_seconds, obstacle):
		return false
	var up_there: Transform3D = here.translated(Vector3.UP * tuning.jump_height)
	var room: float = obstacle.get_travel().length() + 2.0 * tuning.capsule_radius
	return not _runner.test_move(up_there, _direction * room)


## The speed at which the runner goes its way once this step has accelerated it.
func _speed_ahead() -> float:
	var tuning: MovementTuning = _runner.tuning
	var step: float = _runner.get_physics_process_delta_time()
	var speed: float = maxf(_runner.velocity.dot(_direction), 0.0)
	return minf(speed + tuning.ground_acceleration * step, tuning.top_speed)
