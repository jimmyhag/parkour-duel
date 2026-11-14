class_name RunnerMotor
extends RefCounted
## The runner's state machine. At every fixed step the player layer gives it an intent
## and the facts it observed (RunnerFacts); it answers with the state of the runner and
## the velocity it wants, and announces the moves it starts and the tricks its landings
## pay (RunnerEvent). It plays the aerial trick (AirTrick) of each jump: the recipe drawn
## starts as the trick button is released, in the air, on the ground with a full jump
## that carries it, or along a wall (or just off it) with a full wall jump, and a landing
## poses it only with the slide pressed just before the ground. A runner that aims is
## slower on the ground, sliding and rolling included, and starts no trick. It uses
## nothing but its arguments, the tuning and the speed bonus the flow gives it: no input,
## no clock, no scene.

enum State {
	GROUNDED,
	RISING,
	FALLING,
	SLIDING,
	ROLLING,
	HARD_LANDING,
	MANTLING,
	WALL_RUNNING,
}

## How the runner got into the air it is in: what the trick of the context depends on.
enum TakeOff {
	FALL,
	JUMP,
	WALL_JUMP,
	WALL_RUN,
}

## Step counters start here: far enough for no tolerance window to be open.
const LONG_AGO: int = 1 << 30
## Under this horizontal speed (m/s), a runner is almost still: it says nothing of where
## the runner goes.
const ALMOST_STILL: float = 0.1

var tuning: MovementTuning
var state: State = State.FALLING
var velocity: Vector3 = Vector3.ZERO
## The fixed steps the motor has played: what dates its messages.
var steps: int = 0
## What the motor announces at the step it just played: the tricks paid, the moves
## started, and a hard landing or a crash.
var events: Array[RunnerEvent] = []
## The share of the top speed added by the flow (0 for none); the absolute cap holds.
var top_speed_bonus: float = 0.0
## A release of the trick button would start a trick now, after the step just played: in
## the air or along a wall, or where the jump of a trick is allowed; not while aiming, nor
## after the trick of this jump.
var trick_ready: bool = false

var _step_seconds: float = 0.0
## The runner aims at this step.
var _aiming: bool = false
## The velocity the runner really had as the step started: the one of its facts.
var _real_velocity: Vector3 = Vector3.ZERO
## There was room to stand up as the step started.
var _can_stand: bool = true
var _steps_in_the_air: int = LONG_AGO
var _steps_since_jump_request: int = LONG_AGO
var _steps_since_slide_press: int = LONG_AGO
## Steps since the runner last landed after a fall.
var _steps_since_landing: int = LONG_AGO
## The slide was pressed since the last slide started: the next one counts.
var _slide_pressed_since_the_last_slide: bool = false
var _jump_spent: bool = true
## The height of the jump under way is settled: the jump was released and cut, or it is
## the jump of a trick, which goes up to its top whatever the jump button does.
var _jump_cut: bool = false
## Where the slide is heading: what moves a runner that a low ceiling keeps down.
var _slide_heading: Vector3 = Vector3.ZERO
## The last slide ended because it was too slow, and the slide has been held ever since:
## it takes a new press to slide again.
var _slide_spent: bool = false
## The runner was low and has had no room to stand up since: it stays low, in the air
## as on the floor, whatever its state.
var _held_low: bool = false
## The highest altitude since the runner last touched the ground: where its fall starts.
var _apex: float = -INF
## Steps spent in the roll or the hard landing under way.
var _landing_steps: int = 0
## The wall of the wall run under way, or of the last one: which one it is, and the
## horizontal direction that points away from it.
var _wall_id: int = RunnerFacts.NO_WALL
var _away_from_the_wall: Vector3 = Vector3.ZERO
## The wall the runner may not run along again before it touches the ground or runs
## along another wall: the one of its last wall run.
var _refused_wall: int = RunnerFacts.NO_WALL
## Steps spent in the wall run under way.
var _wall_run_steps: int = 0
## Steps since the runner left its wall: 0 while it runs along it.
var _steps_off_the_wall: int = LONG_AGO
## The mantle under way: the altitude of the top of its ledge, the horizontal direction
## onto it, and the steps spent.
var _ledge_top: float = 0.0
var _onto_the_ledge: Vector3 = Vector3.ZERO
var _mantle_steps: int = 0
## The trick of the jump under way, finished or not: what the next landing pays, or what
## a crash loses; null when there is none. One trick per jump.
var _trick: AirTrick = null
## How the runner got into the air it is in.
var _take_off: TakeOff = TakeOff.FALL
## The horizontal direction the runner last moved in, of length 1.
var _heading: Vector3 = Vector3.FORWARD
## The trick button was held at the last step, and what its drawing read.
var _drawing: bool = false
var _drawn: TrickRecipe = null


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning


## Advances the runner by one fixed step of `delta` seconds and returns the velocity it
## wants for this step.
func step(intent: MoveIntent, facts: RunnerFacts, delta: float) -> Vector3:
	steps += 1
	events.clear()
	_real_velocity = facts.velocity
	_can_stand = facts.can_stand
	velocity = facts.velocity
	_step_seconds = delta
	_aiming = intent.aim_held
	_remember_requests(intent)
	_turn_the_trick()
	_observe_floor(facts)
	if state != State.MANTLING:
		_choose_floor_state(intent, facts)
		_choose_air_state(intent, facts)
	if state == State.MANTLING:
		_mantle(facts, delta)
	else:
		_move(intent, facts, delta)
	_start_a_trick(intent)
	trick_ready = _can_start_a_trick()
	return velocity


## Back to the state of a runner that was just put somewhere, at rest, that has
## announced nothing. Its steps go on being counted.
func reset() -> void:
	state = State.FALLING
	velocity = Vector3.ZERO
	_real_velocity = Vector3.ZERO
	_can_stand = true
	_aiming = false
	events.clear()
	_steps_since_landing = LONG_AGO
	_slide_pressed_since_the_last_slide = false
	_steps_in_the_air = LONG_AGO
	_steps_since_jump_request = LONG_AGO
	_jump_spent = true
	_jump_cut = false
	_slide_heading = Vector3.ZERO
	_slide_spent = false
	_held_low = false
	_steps_since_slide_press = LONG_AGO
	_apex = -INF
	_landing_steps = 0
	_wall_id = RunnerFacts.NO_WALL
	_away_from_the_wall = Vector3.ZERO
	_refused_wall = RunnerFacts.NO_WALL
	_wall_run_steps = 0
	_steps_off_the_wall = LONG_AGO
	_ledge_top = 0.0
	_onto_the_ledge = Vector3.ZERO
	_mantle_steps = 0
	_trick = null
	_take_off = TakeOff.FALL
	_drawing = false
	_drawn = null
	trick_ready = false


## The top speed of the runner: the one of the tuning, plus the bonus of the flow.
func top_speed() -> float:
	return tuning.top_speed * (1.0 + top_speed_bonus)


## The runner aimed at the step it just played.
func is_aiming() -> bool:
	return _aiming


## The real horizontal speed of the runner as it started the step it just played: what
## the physics left it of the step before (against a wall, nothing), in m/s.
func real_speed() -> float:
	return Vector2(_real_velocity.x, _real_velocity.z).length()


## The runner is on its feet on the ground: neither in the air, nor along a wall, nor in
## a mantle, a slide or a roll.
func is_on_foot() -> bool:
	return state == State.GROUNDED or state == State.HARD_LANDING


## The runner is on the ground: on its feet, sliding or rolling; neither in the air,
## nor along a wall, nor in a mantle.
func is_on_the_ground() -> bool:
	return is_on_foot() or state == State.SLIDING or state == State.ROLLING


## The runner is low: its capsule has the height of a slide. It is in a slide and in a
## roll, and stays so, in the air as on the floor, wherever it has no room to stand up.
func is_low() -> bool:
	return state == State.SLIDING or state == State.ROLLING or _held_low


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


## Seconds left of the mantle under way.
func mantle_time_left() -> float:
	if state != State.MANTLING:
		return 0.0
	return maxi(_mantle_duration_steps() - _mantle_steps, 0) * _step_seconds


## Seconds left of the wall run under way.
func wall_run_time_left() -> float:
	if state != State.WALL_RUNNING:
		return 0.0
	return maxi(_window_steps(tuning.wall_run_duration) - _wall_run_steps, 0) * _step_seconds


## Seconds during which a jump is still a wall jump: all of it while the runner runs
## along a wall, then what is left once it has left it.
func wall_jump_time_left() -> float:
	var steps_left: int = _window_steps(tuning.wall_jump_grace_time) - _steps_off_the_wall
	return maxi(steps_left, 0) * _step_seconds


## The trick of the jump under way, finished or not, until the landing pays it; null
## when there is none.
func current_trick() -> AirTrick:
	return _trick


## A trick of the jump is under way: it is not over.
func is_in_a_trick() -> bool:
	return _trick != null and not _trick.finished


## The trick button was held at the step just played: the runner draws a trick.
func is_drawing() -> bool:
	return _drawing


## A release of the trick button would start a trick after the step just played (see
## trick_ready).
func _can_start_a_trick() -> bool:
	if _aiming or _trick != null:
		return false
	if _is_in_the_air():
		return true
	if state == State.ROLLING or state == State.MANTLING:
		return false
	return _may_jump(_can_stand)


## What the drawing read at the step just played, while the button was held: the recipe
## drawn, the trick of the context if nothing was drawn, or null if it cannot be read.
func drawn_recipe() -> TrickRecipe:
	return _drawn


## The horizontal direction away from the wall the runner runs along; ZERO when it runs
## along none.
func wall_run_normal() -> Vector3:
	if state != State.WALL_RUNNING:
		return Vector3.ZERO
	return _away_from_the_wall


## A press of the jump or of the slide is remembered, except during a mantle, which
## ignores them. During a trick, a press of the jump does nothing: it is never
## remembered. The drawing of the trick is noted.
func _remember_requests(intent: MoveIntent) -> void:
	var heeded: bool = state != State.MANTLING
	_drawing = intent.trick_held
	_drawn = intent.trick_recipe if intent.trick_held else null
	if intent.jump_pressed and heeded and not is_in_a_trick():
		_steps_since_jump_request = 0
	else:
		_steps_since_jump_request = mini(_steps_since_jump_request + 1, LONG_AGO)
	if intent.slide_pressed and heeded:
		_steps_since_slide_press = 0
		_slide_pressed_since_the_last_slide = true
	else:
		_steps_since_slide_press = mini(_steps_since_slide_press + 1, LONG_AGO)


func _observe_floor(facts: RunnerFacts) -> void:
	var was_low: bool = is_low()
	_steps_since_landing = mini(_steps_since_landing + 1, LONG_AGO)
	if state == State.MANTLING:
		# A mantle is a contact with the ground: what follows it starts from there.
		_touch_the_ground(facts)
		return
	# A jump that just started may still be reported on the floor: it has left it.
	var taking_off: bool = state == State.RISING and velocity.y > 0.0
	if facts.on_floor and not taking_off:
		if _is_in_the_air():
			_land(_apex - facts.altitude, was_low and not facts.can_stand)
		_held_low = was_low and not facts.can_stand
		_touch_the_ground(facts)
		_jump_spent = false
		return
	_steps_in_the_air = mini(_steps_in_the_air + 1, LONG_AGO)
	_steps_off_the_wall = mini(_steps_off_the_wall + 1, LONG_AGO)
	_apex = maxf(_apex, facts.altitude)
	# A low runner that loses the floor stays low for as long as it cannot stand up.
	_held_low = was_low and not facts.can_stand
	if not _is_in_the_air():
		# Leaving the floor is falling, whatever the runner was doing on it.
		state = State.FALLING
		_take_off = TakeOff.FALL


## The ground under the feet: the fall starts again from here, any wall may be run along
## again, and no wall is left to jump off.
func _touch_the_ground(facts: RunnerFacts) -> void:
	_steps_in_the_air = 0
	_apex = facts.altitude
	_refused_wall = RunnerFacts.NO_WALL
	_steps_off_the_wall = LONG_AGO


## The runner touches the floor after a fall of `fall_height`, measured from the highest
## point it reached since it last touched the ground. Above the height that asks for a
## roll, the slide must have been pressed within the window before this step: a button
## held since earlier is not a press. Otherwise the landing is hard and costs speed. A
## runner kept `low` by a ceiling lands the same way, and slides where it would stand.
## A runner that was only put somewhere (its fall has no height) has not landed. The
## trick of the jump must be over and posed: the slide pressed within the landing window
## before this step, perfect within the perfect window; otherwise the landing is a crash.
## A trick posed is paid first, and the press that posed it is a roll too, within the
## whole landing window: a trick posed never ends in a hard landing.
func _land(fall_height: float, low: bool) -> void:
	_landing_steps = 0
	if is_finite(fall_height):
		_steps_since_landing = 0
	var posed: bool = false
	if _trick != null:
		posed = _steps_since_slide_press <= _window_steps(tuning.trick_landing_window)
		if is_in_a_trick() or not posed:
			_crash()
			return
		_pay_the_trick(_steps_since_slide_press <= _window_steps(tuning.trick_perfect_window), true)
	if fall_height <= tuning.roll_fall_height:
		state = State.SLIDING if low else State.GROUNDED
	elif posed or _steps_since_slide_press <= _window_steps(tuning.roll_window):
		state = State.ROLLING
		_announce(RunnerEvent.Kind.ROLL)
	else:
		state = State.HARD_LANDING
		velocity.x *= tuning.hard_landing_speed_ratio
		velocity.z *= tuning.hard_landing_speed_ratio
		_announce(RunnerEvent.Kind.HARD_LANDING)


## The runner is off the floor: rising, falling, or running along a wall.
func _is_in_the_air() -> bool:
	return state == State.RISING or state == State.FALLING or state == State.WALL_RUNNING


## On the floor: a roll and a hard landing last their time, then the runner stands, or
## slides if there is no room to stand up. A slide starts while the slide is held with
## enough speed, and ends when it is released or too slow; one that ended too slow does
## not start again until the slide is released. Under a low ceiling the runner stays low
## whatever it asks.
func _choose_floor_state(intent: MoveIntent, facts: RunnerFacts) -> void:
	if not intent.slide_held:
		_slide_spent = false
	if state == State.ROLLING or state == State.HARD_LANDING:
		_landing_steps += 1
		if _landing_steps > _landing_duration_steps():
			state = State.GROUNDED if facts.can_stand else State.SLIDING
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if state == State.GROUNDED:
		if intent.slide_held and not _slide_spent and speed >= tuning.slide_min_speed:
			state = State.SLIDING
			_start_slide()
	elif state == State.SLIDING and facts.can_stand:
		if not intent.slide_held or speed < tuning.slide_stop_speed:
			state = State.GROUNDED
			_slide_spent = intent.slide_held


## A slide asked for starts. It is perfect when it starts within the window around a
## landing, the slide pressed at most that long before touching the floor or after: its
## horizontal speed gains the tuned speed the way it slides, but never beyond the top
## speed of the moment plus that gain, so that perfect slides in a row do not add up; a
## runner already faster keeps its speed. The absolute cap holds too (see _move). Only a
## slide pressed since the last one counts: a slide held down through several is
## announced once, and is never perfect again.
func _start_slide() -> void:
	if not _slide_pressed_since_the_last_slide:
		return
	_slide_pressed_since_the_last_slide = false
	var window: int = _window_steps(tuning.perfect_slide_window)
	if _steps_since_landing > window or _steps_since_slide_press > window:
		_announce(RunnerEvent.Kind.SLIDE)
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed: float = horizontal.length()
	var gained: float = minf(
		speed + tuning.perfect_slide_speed_gain, top_speed() + tuning.perfect_slide_speed_gain
	)
	if gained > speed:
		horizontal = horizontal.normalized() * gained
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	_announce(RunnerEvent.Kind.PERFECT_SLIDE)


## In the air: a wall run goes on while its wall does, and a runner that stands (not
## low), does not run along a wall and is not in a trick starts a mantle or a wall run
## when the facts and its intent allow it. The ledge in front comes before the wall
## beside.
func _choose_air_state(intent: MoveIntent, facts: RunnerFacts) -> void:
	if state == State.WALL_RUNNING:
		_wall_run_steps += 1
		if _stays_on_the_wall(intent, facts):
			_steps_off_the_wall = 0
			return
		# It leaves the wall: the time it may still jump off it starts now.
		state = State.FALLING
		_take_off = TakeOff.WALL_RUN
		return
	if not _is_in_the_air() or is_low() or is_in_a_trick():
		return
	if _can_mantle(intent, facts):
		_start_mantle(facts)
	elif _can_run_along(intent, facts):
		_start_wall_run(facts)


## A ledge in front, its top within the heights a mantle climbs and free to stand on,
## and the runner pushes towards it.
func _can_mantle(intent: MoveIntent, facts: RunnerFacts) -> bool:
	if facts.ledge_normal.is_zero_approx() or not facts.ledge_clear:
		return false
	if facts.ledge_height < tuning.mantle_min_height:
		return false
	if facts.ledge_height > tuning.mantle_max_height:
		return false
	return _pushes_into(intent.direction, _horizontal_unit(facts.ledge_normal))


func _start_mantle(facts: RunnerFacts) -> void:
	state = State.MANTLING
	_mantle_steps = 0
	_ledge_top = facts.altitude + facts.ledge_height
	_onto_the_ledge = -_horizontal_unit(facts.ledge_normal)
	_jump_spent = true
	_pay_the_trick(false, false)
	_announce(RunnerEvent.Kind.MANTLE)


## The runner rises along the face of its ledge up to its top, while it pushes onto it
## at the exit speed; the last stretch of the mantle carries it one body width forward,
## over the top, pressing it onto the top with the weight of one step, so that it stands
## there. When the mantle is over the runner stands on the ledge, or falls if it did not
## get there.
func _mantle(facts: RunnerFacts, delta: float) -> void:
	_mantle_steps += 1
	var steps: int = _mantle_duration_steps()
	var crossing_steps: int = 0
	if tuning.mantle_exit_speed > 0.0:
		var crossing: float = 2.0 * tuning.capsule_radius / tuning.mantle_exit_speed
		crossing_steps = roundi(crossing / delta)
	var rising_steps: int = maxi(steps - crossing_steps, 1)
	velocity = _onto_the_ledge * tuning.mantle_exit_speed
	if _mantle_steps <= rising_steps:
		var steps_left: int = rising_steps - _mantle_steps + 1
		velocity.y = (_ledge_top - facts.altitude) / (steps_left * delta)
	else:
		velocity.y = -tuning.fall_gravity * delta
	_cap_horizontal_speed()
	if _mantle_steps >= steps:
		state = State.GROUNDED if facts.on_floor else State.FALLING
		_take_off = TakeOff.FALL


## A wall beside the runner that can be run along, not refused, high enough above the
## ground, at a speed along it enough to start (what goes towards the wall does not
## count: too steep an approach gives no wall run, and leaves the wall free), and the
## runner pushes, anywhere but away from the wall. The speed along the wall is what
## tells a wall run from a mantle on a face pushed into.
func _can_run_along(intent: MoveIntent, facts: RunnerFacts) -> bool:
	if facts.wall_id == RunnerFacts.NO_WALL or facts.wall_id == _refused_wall:
		return false
	if not _is_runnable(facts):
		return false
	if facts.ground_clearance < tuning.wall_run_min_height:
		return false
	var away: Vector3 = _horizontal_unit(facts.wall_normal)
	if _along(velocity, away).length() < tuning.wall_run_start_speed:
		return false
	# Any push but one away from the wall: along it, towards it or straight into it.
	var wish: Vector3 = Vector3(intent.direction.x, 0.0, intent.direction.z)
	return not wish.is_zero_approx() and not _pushes_away(intent.direction, away)


## The wall is close enough, near enough to vertical and tall enough.
func _is_runnable(facts: RunnerFacts) -> bool:
	if facts.wall_normal.is_zero_approx():
		return false
	if facts.wall_distance > tuning.wall_run_distance:
		return false
	if facts.wall_height < tuning.wall_run_min_wall_height:
		return false
	var tilt: float = absf(facts.wall_normal.normalized().y)
	return tilt <= sin(deg_to_rad(tuning.wall_run_max_tilt))


func _start_wall_run(facts: RunnerFacts) -> void:
	state = State.WALL_RUNNING
	_wall_run_steps = 1
	_wall_id = facts.wall_id
	_refused_wall = facts.wall_id
	_away_from_the_wall = _horizontal_unit(facts.wall_normal)
	_steps_off_the_wall = 0
	_pay_the_trick(false, false)
	_announce(RunnerEvent.Kind.WALL_RUN)


## A wall run lasts its time, along the same wall, fast enough, unless the runner pushes
## away from the wall.
func _stays_on_the_wall(intent: MoveIntent, facts: RunnerFacts) -> bool:
	if _wall_run_steps > _window_steps(tuning.wall_run_duration):
		return false
	if facts.wall_id != _wall_id or not _is_runnable(facts):
		return false
	_away_from_the_wall = _horizontal_unit(facts.wall_normal)
	if _along(velocity, _away_from_the_wall).length() < tuning.wall_run_stop_speed:
		return false
	return not _pushes_away(intent.direction, _away_from_the_wall)


## The velocity of this step, from the state chosen.
func _move(intent: MoveIntent, facts: RunnerFacts, delta: float) -> void:
	if state == State.SLIDING:
		_slide(intent.direction, facts, delta)
	elif state == State.WALL_RUNNING:
		# Along the wall the speed is kept as it is, as in the air.
		var along: Vector3 = _along(velocity, _away_from_the_wall)
		velocity.x = along.x
		velocity.z = along.z
	elif state == State.ROLLING:
		# A roll keeps the speed it landed with, unless the runner aims.
		_brake_for_the_aim(delta)
	else:
		_steer(intent.direction, delta)
	_keep_a_low_runner_moving()
	_cap_horizontal_speed()
	if _can_wall_jump():
		_wall_jump(false)
	elif _can_trick_wall_jump(intent):
		_wall_jump(true)
	elif _can_trick_jump(intent, facts):
		_start_jump(delta, true)
	elif _can_jump(facts):
		_start_jump(delta, false)
	elif state == State.SLIDING:
		velocity.y = _speed_down_the_slope(facts.floor_normal)
	elif state == State.WALL_RUNNING:
		_fall_along_the_wall(delta)
	elif _is_in_the_air():
		_fly(intent.jump_held, delta)
	else:
		velocity.y = 0.0


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
	var slowed: float = maxf(speed - tuning.slide_deceleration * delta, 0.0)
	horizontal = _slide_heading * minf(slowed, _speed_braked_for_the_aim(speed, delta))
	var normal: Vector3 = facts.floor_normal
	var downhill: Vector3 = Vector3(normal.x, 0.0, normal.z) * normal.y
	horizontal += downhill * tuning.fall_gravity * delta
	if not facts.can_stand and horizontal.length() < tuning.slide_stop_speed:
		horizontal = _slide_heading * tuning.slide_stop_speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## While the runner aims on the ground, its horizontal speed comes down to the speed of
## an aim as fast as the ground brakes: what a slide and a roll keep otherwise.
func _brake_for_the_aim(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed: float = horizontal.length()
	if is_zero_approx(speed):
		return
	horizontal *= _speed_braked_for_the_aim(speed, delta) / speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## The speed `speed` becomes in one step of aiming on the ground: brought down towards
## the speed of an aim at the rate the ground brakes, never under it; unchanged when the
## runner does not aim or is not faster than that.
func _speed_braked_for_the_aim(speed: float, delta: float) -> float:
	var aim_speed: float = top_speed() * tuning.aim_speed_ratio
	if not _aiming or speed <= aim_speed:
		return speed
	return maxf(speed - tuning.ground_deceleration * delta, aim_speed)


## A runner kept low by a ceiling, out of a slide (in the air over a crack, in a roll or
## a hard landing), never goes slower than the least speed of a slide, the way it went:
## it never stays stuck.
func _keep_a_low_runner_moving() -> void:
	if not _held_low or state == State.SLIDING:
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if not horizontal.is_zero_approx():
		_slide_heading = horizontal.normalized()
	if horizontal.length() < tuning.slide_stop_speed:
		velocity.x = _slide_heading.x * tuning.slide_stop_speed
		velocity.z = _slide_heading.z * tuning.slide_stop_speed


## The vertical speed that keeps a slide on a floor that goes down under it.
func _speed_down_the_slope(normal: Vector3) -> float:
	if normal.y <= 0.0:
		return 0.0
	return minf(-(normal.x * velocity.x + normal.z * velocity.z) / normal.y, 0.0)


func _steer(direction: Vector3, delta: float) -> void:
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	var rate: float = tuning.air_acceleration
	var top: float = top_speed()
	# What the floor takes, per step, from a speed above the top speed; the air takes
	# nothing.
	var momentum_loss: float = 0.0
	if state == State.HARD_LANDING:
		top *= tuning.hard_landing_speed_ratio
	var aims_on_the_ground: bool = _aiming and not _is_in_the_air()
	if aims_on_the_ground:
		top *= tuning.aim_speed_ratio
	if not _is_in_the_air():
		rate = tuning.ground_deceleration if wish.is_zero_approx() else tuning.ground_acceleration
		momentum_loss = tuning.momentum_deceleration * delta
	elif wish.is_zero_approx():
		# Nothing brakes in the air: the momentum of the run carries the jump.
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = wish * top
	var speed: float = horizontal.length()
	if state == State.HARD_LANDING:
		horizontal = horizontal.limit_length(top)
	elif aims_on_the_ground and speed > top:
		# Aiming is braking: the runner comes down to the speed of an aim as fast as it
		# stops, and keeps no momentum above it.
		rate = maxf(rate, tuning.ground_deceleration)
	elif speed > top and not wish.is_zero_approx():
		# Momentum: the runner goes where it wants at the speed it has, which only comes
		# back down towards the top speed at the pace of the loss.
		var kept: float = maxf(speed - momentum_loss, top)
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


## A jump asked for (now, or within the jump buffer) while the runner runs along a wall,
## or shortly after it left it, is a jump off that wall.
func _can_wall_jump() -> bool:
	if _steps_since_jump_request > _window_steps(tuning.jump_buffer_time):
		return false
	if state == State.WALL_RUNNING:
		return true
	return (
		state == State.FALLING and _steps_off_the_wall <= _window_steps(tuning.wall_jump_grace_time)
	)


## The trick button released with a drawing that reads, where a wall jump is allowed (along
## the wall, or shortly after leaving it), the runner not aiming, before any trick of
## this jump: the wall jump of a trick.
func _can_trick_wall_jump(intent: MoveIntent) -> bool:
	if not intent.trick_released or intent.trick_recipe == null:
		return false
	if intent.aim_held or _trick != null:
		return false
	if state == State.WALL_RUNNING:
		return true
	return (
		state == State.FALLING and _steps_off_the_wall <= _window_steps(tuning.wall_jump_grace_time)
	)


## Away from the wall and upwards, keeping the speed along the wall; the cap holds from
## this very step. The wall jump of a trick (`trick`) goes up to its top as if the jump
## were held, and is not announced: the trick it carries is the move, and its trick of the
## context is the one of a runner that leaves its wall.
func _wall_jump(trick: bool) -> void:
	var along: Vector3 = _along(velocity, _away_from_the_wall)
	var away: Vector3 = _away_from_the_wall * tuning.wall_jump_away_speed
	velocity = Vector3(along.x + away.x, tuning.wall_jump_up_speed, along.z + away.z)
	_cap_horizontal_speed()
	state = State.RISING
	_jump_spent = true
	_jump_cut = trick
	_steps_since_jump_request = LONG_AGO
	_steps_off_the_wall = LONG_AGO
	if trick:
		_take_off = TakeOff.WALL_RUN
		return
	_take_off = TakeOff.WALL_JUMP
	_announce(RunnerEvent.Kind.WALL_JUMP)


## A jump asked for (now, or within the jump buffer) where a jump is allowed.
func _can_jump(facts: RunnerFacts) -> bool:
	if _steps_since_jump_request > _window_steps(tuning.jump_buffer_time):
		return false
	return _may_jump(facts.can_stand)


## A jump is allowed: on the ground or within the coyote time, the jump of this contact
## not spent yet, not in a hard landing, and with room to stand up (`can_stand`) for a low
## runner.
func _may_jump(can_stand: bool) -> bool:
	if _jump_spent:
		return false
	if state == State.HARD_LANDING:
		return false
	if is_low() and not can_stand:
		return false
	return _steps_in_the_air <= _window_steps(tuning.coyote_time)


## The trick button released with a drawing that reads, where a jump is allowed and the
## runner neither rolls nor aims, before any trick of this jump: the jump of a trick.
func _can_trick_jump(intent: MoveIntent, facts: RunnerFacts) -> bool:
	if not intent.trick_released or intent.trick_recipe == null:
		return false
	if intent.aim_held or _trick != null or state == State.ROLLING:
		return false
	return _may_jump(facts.can_stand)


## The runner jumps. The jump of a trick (`trick`) goes up to its top as if the jump were
## held, and is not announced: the trick it carries is the move.
func _start_jump(delta: float, trick: bool) -> void:
	velocity.y = _jump_speed(delta)
	state = State.RISING
	_jump_spent = true
	_jump_cut = trick
	_steps_since_jump_request = LONG_AGO
	_take_off = TakeOff.JUMP
	if not trick:
		_announce(RunnerEvent.Kind.JUMP)


func _fly(jump_held: bool, delta: float) -> void:
	if state == State.RISING and not jump_held and not _jump_cut:
		velocity.y *= tuning.jump_release_velocity_ratio
		_jump_cut = true
	var gravity: float = tuning.rise_gravity if velocity.y > 0.0 else tuning.fall_gravity
	velocity.y = maxf(velocity.y - gravity * delta, -tuning.max_fall_speed)
	if state == State.RISING and velocity.y <= 0.0:
		state = State.FALLING


## Along a wall the fall is slowed down: the wall run's own gravity on the way down. A
## runner still rising goes on with the gravity of its jump: no wall run climbs.
func _fall_along_the_wall(delta: float) -> void:
	var gravity: float = tuning.rise_gravity if velocity.y > 0.0 else tuning.wall_run_gravity
	velocity.y = maxf(velocity.y - gravity * delta, -tuning.max_fall_speed)


## The take-off speed that makes a held jump top at the tuned height, given that the
## body moves by `velocity * delta` at every step (the first step moves at full speed).
func _jump_speed(delta: float) -> float:
	var gravity_step: float = tuning.rise_gravity * delta
	var discriminant: float = gravity_step * gravity_step
	discriminant += 8.0 * tuning.rise_gravity * tuning.jump_height
	return (sqrt(discriminant) - gravity_step) / 2.0


## The horizontal part of `vector` that runs along a wall whose horizontal normal is
## `normal`.
func _along(vector: Vector3, normal: Vector3) -> Vector3:
	var horizontal: Vector3 = Vector3(vector.x, 0.0, vector.z)
	return horizontal - normal * horizontal.dot(normal)


## The angle of a push off a surface whose horizontal normal is `normal`, in radians:
## 0 along the surface, positive away from it, negative towards it; NAN without a push.
func _push_angle(direction: Vector3, normal: Vector3) -> float:
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if wish.is_zero_approx():
		return NAN
	var across: float = wish.dot(normal)
	return atan2(across, (wish - normal * across).length())


## Pushing into a surface: towards it by the split angle at least, the limit included.
func _pushes_into(direction: Vector3, normal: Vector3) -> bool:
	var angle: float = -_push_angle(direction, normal)
	if is_nan(angle):
		return false
	return _on_the_split(angle) or not _within_the_split(angle)


## Pushing away from a surface: beyond the split angle, the limit excluded.
func _pushes_away(direction: Vector3, normal: Vector3) -> bool:
	var angle: float = _push_angle(direction, normal)
	return not is_nan(angle) and not _within_the_split(angle)


## The angle is at most the split angle of the tuning, or on it (a push exactly on the
## limit, as the keyboard diagonal, computed with rounding errors).
func _within_the_split(angle: float) -> bool:
	return angle < deg_to_rad(tuning.push_split_angle) or _on_the_split(angle)


func _on_the_split(angle: float) -> bool:
	return is_equal_approx(angle, deg_to_rad(tuning.push_split_angle))


## The horizontal direction of `vector`, of length 1; ZERO if it has none.
func _horizontal_unit(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z).normalized()


## The trick under way goes on by one step: the body turned during the step before.
func _turn_the_trick() -> void:
	if is_in_a_trick():
		_trick.advance(steps)


## The trick of the jump is paid: announced, dated by this step. A perfect landing makes
## it worth more, and the horizontal speed gains the tuned speed the way it goes, but
## never beyond the top speed of the moment plus that gain, so that perfect landings in a
## row do not add up; a runner already faster keeps its speed. The absolute cap holds too.
## Paid without the landing that poses it (`posed` false: a wall run or a mantle), it is
## worth less.
func _pay_the_trick(perfect: bool, posed: bool) -> void:
	if _trick == null:
		return
	_trick.unposed = not posed
	if perfect:
		_trick.perfect = true
		var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
		var speed: float = horizontal.length()
		var gain: float = tuning.trick_perfect_speed_gain
		var gained: float = minf(speed + gain, top_speed() + gain)
		if gained > speed:
			horizontal = horizontal.normalized() * minf(gained, tuning.max_horizontal_speed)
			velocity.x = horizontal.x
			velocity.z = horizontal.z
	events.append(RunnerEvent.new(RunnerEvent.Kind.TRICK, steps, _trick))
	_trick = null


## The ground touched with the trick not over, or not posed: a hard landing whatever the
## fall, and the trick is lost.
func _crash() -> void:
	_trick = null
	state = State.HARD_LANDING
	velocity.x *= tuning.hard_landing_speed_ratio
	velocity.z *= tuning.hard_landing_speed_ratio
	_announce(RunnerEvent.Kind.CRASH)


## The trick button released in the air, rising or falling (not along a wall), starts
## the trick its drawing reads, unless the runner aims or already did a trick in this
## jump; a drawing that cannot be read starts nothing, and an empty one starts the trick
## of the context. Released where a jump or a wall jump is allowed, the jump of the trick
## (see _move) has just made the runner rise: the trick starts at the same step. Released anywhere
## else on the ground, nothing starts. Its front is where the runner went as the step
## started: the push of this step does not bend it.
func _start_a_trick(intent: MoveIntent) -> void:
	var horizontal: Vector3 = Vector3(_real_velocity.x, 0.0, _real_velocity.z)
	if horizontal.length() > ALMOST_STILL:
		_heading = horizontal.normalized()
	if not intent.trick_released or intent.aim_held or _trick != null:
		return
	if state != State.RISING and state != State.FALLING:
		return
	var recipe: TrickRecipe = intent.trick_recipe
	if recipe == null:
		return
	if recipe.context:
		recipe = _trick_of_the_context(horizontal.length())
	var turn_steps: int = _window_steps(tuning.trick_turn_duration)
	var twist_steps: int = _window_steps(tuning.trick_twist_duration)
	_trick = AirTrick.new(recipe, _heading, turn_steps, twist_steps)


## The trick of the context, for a runner at the horizontal speed `speed`: a side flip
## away from the wall it just left along (by the wall jump of a trick too), a backflip
## just after a wall jump or almost at a stop (slower than the speed of a stop of the
## flow), a front flip otherwise.
func _trick_of_the_context(speed: float) -> TrickRecipe:
	if _take_off == TakeOff.WALL_RUN:
		var right: Vector3 = _heading.cross(Vector3.UP)
		var side: int = 1 if _away_from_the_wall.dot(right) >= 0.0 else -1
		return TrickRecipe.of_the_context(TrickRecipe.Flip.SIDE_FLIP, side)
	if _take_off == TakeOff.WALL_JUMP or speed < tuning.flow_stop_speed:
		return TrickRecipe.of_the_context(TrickRecipe.Flip.BACKFLIP)
	return TrickRecipe.of_the_context(TrickRecipe.Flip.FRONT_FLIP)


## Tells, dated by this step, that `kind` happened.
func _announce(kind: RunnerEvent.Kind) -> void:
	events.append(RunnerEvent.new(kind, steps))


## How long the roll or the hard landing under way lasts, in fixed steps.
func _landing_duration_steps() -> int:
	if state == State.ROLLING:
		return _window_steps(tuning.roll_duration)
	return _window_steps(tuning.hard_landing_duration)


## How long a mantle lasts, in fixed steps: at least one.
func _mantle_duration_steps() -> int:
	return maxi(_window_steps(tuning.mantle_duration), 1)


## A duration of the tuning, in fixed steps (rounded to the nearest step).
func _window_steps(seconds: float) -> int:
	if _step_seconds <= 0.0:
		return 0
	return roundi(seconds / _step_seconds)
