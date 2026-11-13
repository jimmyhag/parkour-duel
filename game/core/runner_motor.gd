class_name RunnerMotor
extends RefCounted
## The runner's state machine. At every fixed step the player layer gives it an intent
## and the facts it observed (RunnerFacts); it answers with the state of the runner and
## the velocity it wants. It uses nothing but its arguments and the tuning: no input, no
## clock, no scene.

enum State { GROUNDED, RISING, FALLING, SLIDING, ROLLING, HARD_LANDING }

## Step counters start here: far enough for no tolerance window to be open.
const LONG_AGO: int = 1 << 30

var tuning: MovementTuning
var state: State = State.FALLING
var velocity: Vector3 = Vector3.ZERO

var _step_seconds: float = 0.0
var _steps_in_the_air: int = LONG_AGO
var _steps_since_jump_request: int = LONG_AGO
var _steps_since_slide_press: int = LONG_AGO
var _jump_spent: bool = true
var _jump_cut: bool = false
## Where the slide is heading: what moves a runner that a low ceiling keeps down.
var _slide_heading: Vector3 = Vector3.ZERO
## The last slide ended because it was too slow, and the slide has been held ever since:
## it takes a new press to slide again.
var _slide_spent: bool = false
## The runner lost the floor while it was low, and has had no room to stand up since.
var _low_in_the_air: bool = false
## The highest altitude since the runner last stood on a floor: where its fall starts.
var _apex: float = -INF
## Steps spent in the roll or the hard landing under way.
var _landing_steps: int = 0


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning


## Advances the runner by one fixed step of `delta` seconds and returns the velocity it
## wants for this step.
func step(intent: MoveIntent, facts: RunnerFacts, delta: float) -> Vector3:
	velocity = facts.velocity
	_step_seconds = delta
	_remember_requests(intent)
	_observe_floor(facts)
	_choose_floor_state(intent, facts)
	if state == State.SLIDING:
		_slide(intent.direction, facts, delta)
	elif state != State.ROLLING:
		# A roll keeps the speed it landed with.
		_steer(intent.direction, delta)
	_cap_horizontal_speed()
	if _can_jump(facts):
		_start_jump(delta)
	elif state == State.SLIDING:
		velocity.y = _speed_down_the_slope(facts.floor_normal)
	elif _is_in_the_air():
		_fly(intent.jump_held, delta)
	else:
		velocity.y = 0.0
	return velocity


## Back to the state of a runner that was just put somewhere, at rest.
func reset() -> void:
	state = State.FALLING
	velocity = Vector3.ZERO
	_steps_in_the_air = LONG_AGO
	_steps_since_jump_request = LONG_AGO
	_jump_spent = true
	_jump_cut = false
	_slide_heading = Vector3.ZERO
	_slide_spent = false
	_low_in_the_air = false
	_steps_since_slide_press = LONG_AGO
	_apex = -INF
	_landing_steps = 0


## The runner is low: its capsule has the height of a slide. It is in a slide and in a
## roll, and stays so in the air if it lost the floor where it cannot stand up.
func is_low() -> bool:
	return state == State.SLIDING or state == State.ROLLING or _low_in_the_air


## Seconds during which a jump is still accepted although the floor is gone.
func coyote_time_left() -> float:
	if _jump_spent:
		return 0.0
	return maxi(_window_steps(tuning.coyote_time) - _steps_in_the_air, 0) * _step_seconds


## Seconds during which the last jump press is still remembered.
func jump_buffer_left() -> float:
	var steps_left: int = _window_steps(tuning.jump_buffer_time) - _steps_since_jump_request
	return maxi(steps_left, 0) * _step_seconds


## Seconds during which the last slide press still makes a roll of a high landing.
func roll_window_left() -> float:
	var steps_left: int = _window_steps(tuning.roll_window) - _steps_since_slide_press
	return maxi(steps_left, 0) * _step_seconds


## Seconds left of the roll or of the hard landing under way.
func landing_time_left() -> float:
	if state != State.ROLLING and state != State.HARD_LANDING:
		return 0.0
	return maxi(_landing_duration_steps() - _landing_steps, 0) * _step_seconds


func _remember_requests(intent: MoveIntent) -> void:
	if intent.jump_pressed:
		_steps_since_jump_request = 0
	else:
		_steps_since_jump_request = mini(_steps_since_jump_request + 1, LONG_AGO)
	if intent.slide_pressed:
		_steps_since_slide_press = 0
	else:
		_steps_since_slide_press = mini(_steps_since_slide_press + 1, LONG_AGO)


func _observe_floor(facts: RunnerFacts) -> void:
	# A jump that just started may still be reported on the floor: it has left it.
	var taking_off: bool = state == State.RISING and velocity.y > 0.0
	if facts.on_floor and not taking_off:
		if _low_in_the_air and not facts.can_stand:
			# Back on a floor before there is room to stand up: it goes on as a slide.
			state = State.SLIDING
		elif _is_in_the_air():
			_land(_apex - facts.altitude)
		_low_in_the_air = false
		_steps_in_the_air = 0
		_jump_spent = false
		_apex = facts.altitude
		return
	_steps_in_the_air = mini(_steps_in_the_air + 1, LONG_AGO)
	_apex = maxf(_apex, facts.altitude)
	# A low runner that loses the floor stays low for as long as it cannot stand up.
	_low_in_the_air = is_low() and not facts.can_stand
	if not _is_in_the_air():
		# Leaving the floor is falling, whatever the runner was doing on it.
		state = State.FALLING


## The runner touches the floor after a fall of `fall_height`, measured from the highest
## point it reached in the air. Above the height that asks for a roll, the slide must
## have been pressed within the window before this step: a button held since earlier is
## not a press. Otherwise the landing is hard and costs speed.
func _land(fall_height: float) -> void:
	_landing_steps = 0
	if fall_height <= tuning.roll_fall_height:
		state = State.GROUNDED
	elif _steps_since_slide_press <= _window_steps(tuning.roll_window):
		state = State.ROLLING
	else:
		state = State.HARD_LANDING
		velocity.x *= tuning.hard_landing_speed_ratio
		velocity.z *= tuning.hard_landing_speed_ratio


func _is_in_the_air() -> bool:
	return state == State.RISING or state == State.FALLING


## On the floor: a roll and a hard landing last their time, then the runner stands or
## slides. A slide starts while the slide is held with enough speed, and ends when it is
## released or too slow; one that ended too slow does not start again until the slide is
## released. Under a low ceiling the runner stays low whatever it asks.
func _choose_floor_state(intent: MoveIntent, facts: RunnerFacts) -> void:
	if not intent.slide_held:
		_slide_spent = false
	if state == State.ROLLING or state == State.HARD_LANDING:
		_landing_steps += 1
		if _landing_steps > _landing_duration_steps():
			# A roll that ends without room to stand up goes on as a slide.
			var stands: bool = facts.can_stand or state == State.HARD_LANDING
			state = State.GROUNDED if stands else State.SLIDING
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if state == State.GROUNDED:
		if intent.slide_held and not _slide_spent and speed >= tuning.slide_min_speed:
			state = State.SLIDING
	elif state == State.SLIDING and facts.can_stand:
		if not intent.slide_held or speed < tuning.slide_stop_speed:
			state = State.GROUNDED
			_slide_spent = intent.slide_held


## A slide takes no acceleration from the runner: it slows down at its own pace, the
## slope pulls it with the fall gravity, and its direction only follows the wanted one
## slowly. Without room to stand up, it never goes slower than its least speed.
func _slide(direction: Vector3, facts: RunnerFacts, delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed: float = horizontal.length()
	if not horizontal.is_zero_approx():
		_slide_heading = horizontal / speed
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if not wish.is_zero_approx() and not _slide_heading.is_zero_approx():
		var turn: float = tuning.slide_turn_speed * delta
		var angle: float = _slide_heading.signed_angle_to(wish, Vector3.UP)
		_slide_heading = _slide_heading.rotated(Vector3.UP, clampf(angle, -turn, turn))
	horizontal = _slide_heading * maxf(speed - tuning.slide_deceleration * delta, 0.0)
	var normal: Vector3 = facts.floor_normal
	var downhill: Vector3 = Vector3(normal.x, 0.0, normal.z) * normal.y
	horizontal += downhill * tuning.fall_gravity * delta
	if not facts.can_stand and horizontal.length() < tuning.slide_stop_speed:
		horizontal = _slide_heading * tuning.slide_stop_speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## The vertical speed that keeps a slide on a floor that goes down under it.
func _speed_down_the_slope(normal: Vector3) -> float:
	if normal.y <= 0.0:
		return 0.0
	return minf(-(normal.x * velocity.x + normal.z * velocity.z) / normal.y, 0.0)


func _steer(direction: Vector3, delta: float) -> void:
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	var rate: float = tuning.air_acceleration
	var top_speed: float = tuning.top_speed
	# What the floor takes, per step, from a speed above the top speed; the air takes
	# nothing.
	var momentum_loss: float = 0.0
	if state == State.HARD_LANDING:
		top_speed *= tuning.hard_landing_speed_ratio
	if not _is_in_the_air():
		rate = tuning.ground_deceleration if wish.is_zero_approx() else tuning.ground_acceleration
		momentum_loss = tuning.momentum_deceleration * delta
	elif wish.is_zero_approx():
		# Nothing brakes in the air: the momentum of the run carries the jump.
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = wish * top_speed
	var speed: float = horizontal.length()
	if state == State.HARD_LANDING:
		horizontal = horizontal.limit_length(top_speed)
	elif speed > top_speed and not wish.is_zero_approx():
		# Momentum: the runner goes where it wants at the speed it has, which only comes
		# back down towards the top speed at the pace of the loss.
		var kept: float = maxf(speed - momentum_loss, top_speed)
		target = wish.normalized() * maxf(target.length(), kept)
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Nothing takes the horizontal speed above its absolute cap.
func _cap_horizontal_speed() -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.limit_length(tuning.max_horizontal_speed)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _can_jump(facts: RunnerFacts) -> bool:
	if _jump_spent:
		return false
	if state == State.HARD_LANDING:
		return false
	if is_low() and not facts.can_stand:
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


## How long the roll or the hard landing under way lasts, in fixed steps.
func _landing_duration_steps() -> int:
	if state == State.ROLLING:
		return _window_steps(tuning.roll_duration)
	return _window_steps(tuning.hard_landing_duration)


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _window_steps(seconds: float) -> int:
	if _step_seconds <= 0.0:
		return 0
	return roundi(seconds / _step_seconds)
