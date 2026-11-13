class_name PilotIntentSource
extends IntentSource
## The test pilot: a source of intents that, at every fixed step, looks at its runner
## and at the physical world around it, then decides. It runs in a given direction,
## jumps when the floor stops just ahead, when a step it can clear stands just ahead, or
## when a ledge it can climb stands right in front of it, and holds the jump up to its
## top unless holding it would carry it past the floor it can land on. It holds the
## slide when a low obstacle stands just ahead, in one go until there is room to stand
## up again, and presses it just before the floor when it falls from high enough to need
## a roll. Along a wall, it jumps off when another wall stands across, and lets the jump
## carry it to that wall. It never jumps in the air or on a floor that goes on but off a
## wall, and never asks for the slide without one of its two reasons.
## It knows no course: only what it probes, the state of the runner and the tuning,
## from which its look-ahead distances are worked out.

var _runner: Player
var _direction: Vector3
var _slides: bool
## The highest altitude of the runner since it last stood on a floor, and the altitude
## of that floor.
var _highest: float = 0.0
var _floor_altitude: float = 0.0
var _slide_was_held: bool = false
var _roll_asked: bool = false
## The runner jumped off a wall and has not reached anything since.
var _flying_off_a_wall: bool = false


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
	var motor: RunnerMotor = _runner.motor
	var altitude: float = _runner.global_position.y
	var on_floor: bool = _runner.is_on_floor()
	_highest = altitude if on_floor else maxf(_highest, altitude)
	if on_floor:
		_floor_altitude = altitude
	_roll_asked = _roll_asked and not on_floor
	var in_the_air: bool = motor.state == RunnerMotor.State.RISING
	in_the_air = in_the_air or motor.state == RunnerMotor.State.FALLING
	_flying_off_a_wall = (_flying_off_a_wall or motor.jumped_off_a_wall) and in_the_air
	if _flying_off_a_wall:
		# Off a wall, the jump carries the runner: it pushes the way it flies.
		var flight: Vector3 = Vector3(_runner.velocity.x, 0.0, _runner.velocity.z)
		intent.direction = flight.normalized()
	if _slides and (_ceiling_is_low() or (on_floor and _low_obstacle_stands_ahead())):
		# Under a low ceiling the slide stays held, floor or not: a crack is no way out.
		intent.slide_held = true
		intent.slide_pressed = not _slide_was_held
	elif on_floor:
		intent.jump_pressed = _floor_stops_ahead() or _step_stands_ahead()
		intent.jump_pressed = intent.jump_pressed or _ledge_stands_ahead()
	elif motor.state == RunnerMotor.State.WALL_RUNNING:
		intent.jump_pressed = _another_wall_stands_across()
	elif _slides and not _roll_asked and _high_landing_is_near():
		intent.slide_pressed = true
		intent.slide_held = true
		_roll_asked = true
	_slide_was_held = intent.slide_held
	var rising: bool = motor.state == RunnerMotor.State.RISING
	intent.jump_held = intent.jump_pressed or (rising and not _holding_overshoots())
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
	return _clears_what_stops_it(_reach(), _runner.tuning.jump_height)


## A ledge stands right in front when something would stop the runner's body before the
## end of this step, and the same body, lifted by the highest ledge a mantle climbs,
## would pass over it with room to stand on it. Jumping now puts the runner in the air
## against its face, where the mantle takes it up.
func _ledge_stands_ahead() -> bool:
	var stride: float = _speed_ahead() * _runner.get_physics_process_delta_time()
	return _clears_what_stops_it(stride, _runner.tuning.mantle_max_height)


## Something would stop the runner's body within `reach`, and the same body, lifted by
## `lift`, would pass over it with room to stand on it.
func _clears_what_stops_it(reach: float, lift: float) -> bool:
	var tuning: MovementTuning = _runner.tuning
	var free: float = _free_share(tuning.capsule_height, _direction * reach)
	if free >= 1.0:
		return false
	var up_there: Transform3D = _runner.global_transform.translated(Vector3.UP * lift)
	var room: float = free * reach + 2.0 * tuning.capsule_radius
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


## Along a wall, another wall stands across, on the side the wall pushes the runner to,
## within the distance a jump off the wall carries it away before it falls back to the
## height it jumped from.
func _another_wall_stands_across() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var away: Vector3 = _runner.motor.wall_run_normal()
	var rise_seconds: float = tuning.wall_jump_up_speed / tuning.rise_gravity
	var top: float = tuning.wall_jump_up_speed * rise_seconds / 2.0
	var fall_seconds: float = sqrt(2.0 * top / tuning.fall_gravity)
	var across: float = tuning.wall_jump_away_speed * (rise_seconds + fall_seconds)
	var middle: Vector3 = _runner.global_position + Vector3.UP * tuning.capsule_height / 2.0
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		middle,
		middle + away * (tuning.capsule_radius + across),
		_runner.collision_mask,
		[_runner.get_rid()]
	)
	return not _runner.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


## Holding the jump up to its top would carry the runner past every floor, where letting
## it go now would land it on one.
func _holding_overshoots() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var rising_speed: float = _runner.velocity.y
	if rising_speed <= 0.0:
		return false
	if _lands_on_a_floor(rising_speed):
		return false
	return _lands_on_a_floor(rising_speed * tuning.jump_release_velocity_ratio)


## Whether the feet of the runner, rising from now at `rising_speed` with the gravities
## of the tuning and keeping their horizontal speed, meet a floor before they are a jump
## height below the floor they jumped from: followed step by step, the first thing they
## meet must be a floor the body can stand on.
func _lands_on_a_floor(rising_speed: float) -> bool:
	var tuning: MovementTuning = _runner.tuning
	var step: float = _runner.get_physics_process_delta_time()
	var lowest: float = _floor_altitude - tuning.jump_height
	var horizontal: Vector3 = Vector3(_runner.velocity.x, 0.0, _runner.velocity.z)
	var feet: Vector3 = _runner.global_position
	var speed: float = rising_speed
	var space: PhysicsDirectSpaceState3D = _runner.get_world_3d().direct_space_state
	while feet.y > lowest:
		var gravity: float = tuning.rise_gravity if speed > 0.0 else tuning.fall_gravity
		speed = maxf(speed - gravity * step, -tuning.max_fall_speed)
		var next: Vector3 = feet + (horizontal + Vector3.UP * speed) * step
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			feet, next, _runner.collision_mask, [_runner.get_rid()]
		)
		var hit: Dictionary = space.intersect_ray(ray)
		if not hit.is_empty():
			var normal: Vector3 = hit["normal"]
			return normal.angle_to(Vector3.UP) <= _runner.floor_max_angle
		feet = next
	return false


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
## cover from where the runner stands before something stops it. The body is probed
## standing on the ground under the runner's feet (see _probe_feet).
func _free_share(height: float, motion: Vector3) -> float:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = _runner.tuning.capsule_radius
	capsule.height = height
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, _probe_feet() + Vector3.UP * height / 2.0)
	query.motion = motion
	query.collision_mask = _runner.collision_mask
	query.exclude = [_runner.get_rid()]
	return _runner.get_world_3d().direct_space_state.cast_motion(query)[0]


## Where the feet of a probe body stand: on the ground under the runner's feet, or on
## the feet themselves if they are higher (on a slope, or with no ground there), and in
## both cases the engine's safe margin above, where it keeps the runner's own body. Never
## lower: at the joint of two floor blocks the runner's body sinks for a step by more
## than that margin, and a probe set from it would start inside the floor and stop on
## the edge of the next block.
func _probe_feet() -> Vector3:
	var feet: Vector3 = _runner.global_position
	var reach: Vector3 = Vector3.UP * _runner.tuning.capsule_radius
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		feet + reach, feet - reach, _runner.collision_mask, [_runner.get_rid()]
	)
	var ground: Dictionary = _runner.get_world_3d().direct_space_state.intersect_ray(ray)
	if not ground.is_empty():
		var ground_point: Vector3 = ground["position"]
		feet.y = maxf(feet.y, ground_point.y)
	return feet + Vector3.UP * _runner.safe_margin


## The speed at which the runner goes its way once this step has accelerated it.
func _speed_ahead() -> float:
	var tuning: MovementTuning = _runner.tuning
	var step: float = _runner.get_physics_process_delta_time()
	var speed: float = maxf(_runner.velocity.dot(_direction), 0.0)
	return minf(speed + tuning.ground_acceleration * step, tuning.top_speed)
