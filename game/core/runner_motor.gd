class_name RunnerMotor
extends RefCounted
## The runner's state machine. At every fixed step the player layer gives it an intent
## and the facts it observed (RunnerFacts); it answers with the state of the runner and
## the velocity it wants. It uses nothing but its arguments and the tuning: no input, no
## clock, no scene.

enum State { GROUNDED, RISING, FALLING }

## Step counters start here: far enough for no tolerance window to be open.
const LONG_AGO: int = 1 << 30

var tuning: MovementTuning
var state: State = State.FALLING
var velocity: Vector3 = Vector3.ZERO

var _step_seconds: float = 0.0
var _steps_in_the_air: int = LONG_AGO
var _steps_since_jump_request: int = LONG_AGO
var _jump_spent: bool = true
var _jump_cut: bool = false


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning


## Advances the runner by one fixed step of `delta` seconds and returns the velocity it
## wants for this step.
func step(intent: MoveIntent, facts: RunnerFacts, delta: float) -> Vector3:
	velocity = facts.velocity
	_step_seconds = delta
	_observe_floor(facts.on_floor)
	_remember_jump_request(intent.jump_pressed)
	_steer(intent.direction, delta)
	if _can_jump():
		_start_jump(delta)
	elif state == State.GROUNDED:
		velocity.y = 0.0
	else:
		_fly(intent.jump_held, delta)
	return velocity


## Back to the state of a runner that was just put somewhere, at rest.
func reset() -> void:
	state = State.FALLING
	velocity = Vector3.ZERO
	_steps_in_the_air = LONG_AGO
	_steps_since_jump_request = LONG_AGO
	_jump_spent = true
	_jump_cut = false


## Seconds during which a jump is still accepted although the floor is gone.
func coyote_time_left() -> float:
	if _jump_spent:
		return 0.0
	return maxi(_window_steps(tuning.coyote_time) - _steps_in_the_air, 0) * _step_seconds


## Seconds during which the last jump press is still remembered.
func jump_buffer_left() -> float:
	var steps_left: int = _window_steps(tuning.jump_buffer_time) - _steps_since_jump_request
	return maxi(steps_left, 0) * _step_seconds


func _observe_floor(on_floor: bool) -> void:
	# A jump that just started may still be reported on the floor: it has left it.
	var taking_off: bool = state == State.RISING and velocity.y > 0.0
	if on_floor and not taking_off:
		state = State.GROUNDED
		_steps_in_the_air = 0
		_jump_spent = false
		return
	_steps_in_the_air = mini(_steps_in_the_air + 1, LONG_AGO)
	if state == State.GROUNDED:
		state = State.FALLING


func _remember_jump_request(jump_pressed: bool) -> void:
	if jump_pressed:
		_steps_since_jump_request = 0
	else:
		_steps_since_jump_request = mini(_steps_since_jump_request + 1, LONG_AGO)


func _steer(direction: Vector3, delta: float) -> void:
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	var rate: float = tuning.air_acceleration
	if state == State.GROUNDED:
		rate = tuning.ground_deceleration if wish.is_zero_approx() else tuning.ground_acceleration
	elif wish.is_zero_approx():
		# Nothing brakes in the air: the momentum of the run carries the jump.
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(wish * tuning.top_speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _can_jump() -> bool:
	if _jump_spent:
		return false
	if _steps_since_jump_request > _window_steps(tuning.jump_buffer_time):
		return false
	return _steps_in_the_air <= _window_steps(tuning.coyote_time)


func _start_jump(delta: float) -> void:
	velocity.y = _jump_speed(delta)
	state = State.RISING
	_jump_spent = true
	_jump_cut = false
	_steps_since_jump_request = LONG_AGO


func _fly(jump_held: bool, delta: float) -> void:
	if state == State.RISING and not jump_held and not _jump_cut:
		velocity.y *= tuning.jump_release_velocity_ratio
		_jump_cut = true
	var gravity: float = tuning.rise_gravity if velocity.y > 0.0 else tuning.fall_gravity
	velocity.y = maxf(velocity.y - gravity * delta, -tuning.max_fall_speed)
	if state == State.RISING and velocity.y <= 0.0:
		state = State.FALLING


## The take-off speed that makes a held jump top at the tuned height, given that the
## body moves by `velocity * delta` at every step (the first step moves at full speed).
func _jump_speed(delta: float) -> float:
	var gravity_step: float = tuning.rise_gravity * delta
	var discriminant: float = gravity_step * gravity_step
	discriminant += 8.0 * tuning.rise_gravity * tuning.jump_height
	return (sqrt(discriminant) - gravity_step) / 2.0


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _window_steps(seconds: float) -> int:
	if _step_seconds <= 0.0:
		return 0
	return roundi(seconds / _step_seconds)
