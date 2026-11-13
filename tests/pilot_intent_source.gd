class_name PilotIntentSource
extends IntentSource
## The test pilot: a source of intents that, at every fixed step, looks at its runner
## and at the physical world around it, then decides. It runs in a given direction,
## jumps when the floor stops just ahead or when a step it can clear stands just ahead,
## and holds the jump up to its top. It holds the slide when a low obstacle stands just
## ahead, until there is room to stand up again, and presses it just before the floor
## when it falls from high enough to need a roll. It never jumps in the air or on a
## floor that goes on, and never asks for the slide without one of these two reasons.
## It knows no course: only what it probes, the state of the runner and the tuning,
## from which its look-ahead distances are worked out.

var _runner: Player
var _direction: Vector3
var _slides: bool
## The highest altitude of the runner since it last stood on a floor.
var _highest: float = 0.0
var _slide_was_held: bool = false
var _roll_asked: bool = false


## `direction` is where to run, in the world; only its horizontal part counts. A pilot
## that does not slide never asks for the slide: it neither passes under an obstacle
## nor rolls.
func _init(runner: Player, direction: Vector3, slides: bool = true) -> void:
	_runner = runner
	_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	_slides = slides


func next_intent() -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = _direction
	var altitude: float = _runner.global_position.y
	if _runner.is_on_floor():
		_highest = altitude
		_roll_asked = false
		if _slides and (_low_obstacle_stands_ahead() or _ceiling_is_low()):
			intent.slide_held = true
			intent.slide_pressed = not _slide_was_held
		else:
			intent.jump_pressed = _floor_stops_ahead() or _step_stands_ahead()
	else:
		_highest = maxf(_highest, altitude)
		if _slides and not _roll_asked and _high_landing_is_near():
			intent.slide_pressed = true
			intent.slide_held = true
			_roll_asked = true
	_slide_was_held = intent.slide_held
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
	var here: Transform3D = _runner.global_transform
	var obstacle: KinematicCollision3D = KinematicCollision3D.new()
	if not _runner.test_move(here, _direction * _reach(), obstacle):
		return false
	var up_there: Transform3D = here.translated(Vector3.UP * tuning.jump_height)
	var room: float = obstacle.get_travel().length() + 2.0 * tuning.capsule_radius
	return not _runner.test_move(up_there, _direction * room)


## A low obstacle stands ahead when a standing body would be stopped within the same
## reach, and a body as low as a slide would pass under what stops it, with room to go
## on. Sliding now is being low when the runner gets there.
func _low_obstacle_stands_ahead() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var reach: float = _reach()
	var free: float = _free_share(tuning.capsule_height, _direction * reach)
	if free >= 1.0:
		return false
	var room: float = free * reach + 2.0 * tuning.capsule_radius
	return _free_share(tuning.slide_capsule_height, _direction * room) >= 1.0


## The ceiling is low where the runner is: a body as low as a slide could not rise there
## to the standing height.
func _ceiling_is_low() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var rise: float = tuning.capsule_height - tuning.slide_capsule_height
	return _free_share(tuning.slide_capsule_height, Vector3.UP * rise) < 1.0


## The runner is falling from higher than what a landing without a roll allows, and
## will be on the floor before half of the roll window has passed: a press now is well
## inside the window.
func _high_landing_is_near() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var falling_speed: float = -_runner.velocity.y
	if falling_speed <= 0.0:
		return false
	var feet: Vector3 = _runner.global_position
	# The farthest the floor can be for the runner to reach it within the window.
	var deepest: float = tuning.max_fall_speed * tuning.roll_window
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		feet, feet + Vector3.DOWN * deepest, _runner.collision_mask, [_runner.get_rid()]
	)
	var hit: Dictionary = _runner.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return false
	var floor_below: Vector3 = hit["position"]
	if _highest - floor_below.y <= tuning.roll_fall_height:
		return false
	# The time a fall of `drop` takes from the speed the runner already has.
	var drop: float = feet.y - floor_below.y
	var gravity: float = tuning.fall_gravity
	var speed_at_the_floor: float = sqrt(falling_speed * falling_speed + 2.0 * gravity * drop)
	var seconds: float = (speed_at_the_floor - falling_speed) / gravity
	return seconds <= tuning.roll_window / 2.0


## How far ahead an obstacle counts: the distance the runner covers while a jump rises.
func _reach() -> float:
	var tuning: MovementTuning = _runner.tuning
	var take_off_speed: float = sqrt(2.0 * tuning.rise_gravity * tuning.jump_height)
	var rise_seconds: float = take_off_speed / tuning.rise_gravity
	return _speed_ahead() * rise_seconds


## The share of `motion` (0 to 1) a body shaped like the runner, `height` tall, could
## cover from where the runner stands before something stops it.
func _free_share(height: float, motion: Vector3) -> float:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = _runner.tuning.capsule_radius
	capsule.height = height
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(
		Basis.IDENTITY, _runner.global_position + Vector3.UP * height / 2.0
	)
	query.motion = motion
	query.collision_mask = _runner.collision_mask
	query.exclude = [_runner.get_rid()]
	return _runner.get_world_3d().direct_space_state.cast_motion(query)[0]


## The speed at which the runner goes its way once this step has accelerated it.
func _speed_ahead() -> float:
	var tuning: MovementTuning = _runner.tuning
	var step: float = _runner.get_physics_process_delta_time()
	var speed: float = maxf(_runner.velocity.dot(_direction), 0.0)
	return minf(speed + tuning.ground_acceleration * step, tuning.top_speed)
