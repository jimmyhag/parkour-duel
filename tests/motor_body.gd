class_name MotorBody
extends RefCounted
## A runner without a scene, for the tests of the moves of game/core. It plays the part
## of the player layer over a floor that is a plane through the point `floor_height`
## above the origin: it feeds the motor with the facts it observes and moves by the
## velocity the motor returns. Nothing snaps it to its floor: on a slope it only stays
## on it if the motor asks for a velocity that follows the slope. A wall beside it is
## only a fact the test sets; a ledge across its way is a block that stops it.

const STEP: float = 1.0 / 60.0
## How close to the floor counts as standing on it, and to a face as touching it.
const CONTACT: float = 0.0001

var motor: RunnerMotor
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var on_floor: bool = true
## The floor: whether there is one, its altitude at the origin and its normal (a slope
## when it is not straight up).
var has_floor: bool = true
var floor_height: float = 0.0
var floor_normal: Vector3 = Vector3.UP
## There is room above the runner to stand up.
var can_stand: bool = true
## The wall beside the runner, as the player layer would report it.
var wall_id: int = RunnerFacts.NO_WALL
var wall_normal: Vector3 = Vector3.ZERO
var wall_distance: float = INF
var wall_height: float = 0.0
## A ledge across the way of a runner going along -Z: a block whose face stands at
## `ledge_face` along Z and whose top is at the altitude `ledge_top`. The runner sees it
## while it touches its face below its top.
var has_ledge: bool = false
var ledge_face: float = 0.0
var ledge_top: float = 0.0
var ledge_clear: bool = true


func _init(tuning: MovementTuning, altitude: float = 0.0) -> void:
	motor = RunnerMotor.new(tuning)
	position.y = altitude
	on_floor = altitude <= 0.0


## The tuning of these tests, fixed on purpose: they check the rules, not the values the
## owner tunes in movement_tuning.tres.
static func fixed_tuning() -> MovementTuning:
	var tuning: MovementTuning = MovementTuning.new()
	tuning.top_speed = 9.0
	tuning.ground_acceleration = 30.0
	tuning.ground_deceleration = 45.0
	tuning.air_acceleration = 14.0
	tuning.jump_height = 1.6
	tuning.rise_gravity = 32.0
	tuning.fall_gravity = 44.0
	tuning.jump_release_velocity_ratio = 0.45
	tuning.max_fall_speed = 40.0
	tuning.coyote_time = 0.10
	tuning.jump_buffer_time = 0.12
	tuning.slide_min_speed = 5.0
	tuning.slide_stop_speed = 2.5
	tuning.slide_deceleration = 4.0
	tuning.slide_turn_speed = 1.0
	tuning.roll_fall_height = 4.0
	tuning.roll_window = 0.20
	tuning.roll_duration = 0.5
	tuning.hard_landing_speed_ratio = 0.35
	tuning.hard_landing_duration = 0.35
	tuning.momentum_deceleration = 6.0
	tuning.max_horizontal_speed = 22.0
	tuning.push_split_angle = 45.0
	tuning.mantle_min_height = 0.9
	tuning.mantle_max_height = 2.2
	tuning.mantle_duration = 0.35
	tuning.mantle_exit_speed = 4.0
	tuning.wall_run_distance = 0.6
	tuning.wall_run_max_tilt = 15.0
	tuning.wall_run_min_wall_height = 2.0
	tuning.wall_run_min_height = 1.0
	tuning.wall_run_start_speed = 6.0
	tuning.wall_run_stop_speed = 4.0
	tuning.wall_run_duration = 1.2
	tuning.wall_run_gravity = 6.0
	tuning.wall_jump_away_speed = 7.0
	tuning.wall_jump_up_speed = 9.5
	tuning.wall_jump_grace_time = 0.10
	tuning.capsule_height = 1.8
	tuning.capsule_radius = 0.35
	tuning.flow_points_jump = 50
	tuning.flow_points_slide = 50
	tuning.flow_points_perfect_slide = 150
	tuning.flow_points_roll = 100
	tuning.flow_points_mantle = 100
	tuning.flow_points_wall_run = 150
	tuning.flow_points_wall_jump = 150
	tuning.flow_jump_min_speed_share = 0.5
	tuning.flow_repetition_window = 4
	tuning.flow_second_time_share = 0.5
	tuning.flow_later_times_share = 0.0
	tuning.flow_chain_delay = 2.0
	tuning.flow_moves_per_multiplier = 4
	tuning.flow_max_multiplier = 4
	tuning.flow_tier_value = 1000.0
	tuning.flow_tier_count = 3
	tuning.flow_decay = 100.0
	tuning.flow_tier_speed_bonus = [0.05, 0.10, 0.15]
	tuning.flow_max_ammo = 3
	tuning.flow_points_per_ammo = 1000
	tuning.perfect_slide_window = 0.15
	tuning.perfect_slide_speed_gain = 2.0
	tuning.flow_stop_speed = 1.0
	tuning.flow_stop_duration = 1.0
	tuning.trick_turn_duration = 0.35
	tuning.trick_twist_duration = 0.15
	tuning.trick_max_turns = 3
	tuning.trick_max_twists_per_turn = 2
	tuning.trick_points_flip = 200
	tuning.trick_points_side_flip = 250
	tuning.trick_points_context = 100
	tuning.trick_double_multiplier = 2.5
	tuning.trick_triple_multiplier = 4.0
	tuning.trick_points_per_twist = 150
	tuning.trick_repetition_window = 8
	tuning.trick_landing_window = 0.25
	tuning.trick_perfect_window = 0.1
	tuning.trick_perfect_bonus = 0.5
	tuning.trick_unposed_share = 0.5
	tuning.trick_perfect_speed_gain = 1.0
	tuning.camera_mouse_sensitivity = 0.0025
	tuning.trick_pad_units_per_radian = 4.0
	tuning.trick_pad_stick_speed = 18.0
	tuning.trick_gesture_stroke_length = 0.65
	tuning.trick_gesture_still_length = 0.55
	tuning.trick_gesture_half_circle_angle = 100.0
	tuning.trick_gesture_circle_angle = 270.0
	tuning.trick_gesture_pause = 0.05
	tuning.trick_gesture_two_twists_angle = 300.0
	tuning.trick_gesture_more_twists_angle = 180.0
	tuning.trick_gesture_spin_turn_angle = 360.0
	tuning.trick_gesture_repeat_pause = 0.12
	tuning.trick_gesture_stick_flick = 0.45
	tuning.trick_gesture_stick_dip = 0.5
	tuning.trick_gesture_settle = 0.1
	tuning.trick_gesture_settle_length = 0.25
	tuning.trick_gesture_noise = 0.004
	tuning.trick_gesture_corner_angle = 90.0
	tuning.trick_gesture_bend_angle = 25.0
	tuning.trick_gesture_stroke_turn = 60.0
	tuning.trick_gesture_stroke_share = 0.15
	tuning.aim_speed_ratio = 0.6
	tuning.shot_range = 45.0
	tuning.aim_min_time = 0.25
	tuning.aim_camera_fov = 50.0
	tuning.aim_camera_offset = 0.6
	tuning.aim_camera_blend_time = 0.12
	tuning.sabotage_warning = 0.6
	tuning.sabotage_cooldown = 3.0
	tuning.sabotage_cost_platform = 1
	tuning.sabotage_cost_bridge = 2
	tuning.sabotage_cost_obstacle = 1
	tuning.sabotage_cost_barrier = 1
	tuning.sabotage_duration_platform = 5.0
	tuning.sabotage_duration_bridge = 6.0
	tuning.sabotage_duration_obstacle = 6.0
	tuning.sabotage_duration_barrier = 4.0
	tuning.round_countdown_number_time = 1.0
	tuning.round_time_limit = 180.0
	tuning.bot_sabotage_lead = 25.0
	tuning.bot_aim_time = 0.8
	tuning.duel_start_ammo = 2
	return tuning


## A body on the floor that already runs at `speed` along `direction`.
static func running(tuning: MovementTuning, direction: Vector3, speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.new(tuning)
	body.velocity = direction * speed
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction * minf(speed / tuning.top_speed, 1.0)
	body.step(intent)
	return body


func step(intent: MoveIntent) -> void:
	velocity = motor.step(intent, _facts(), STEP)
	var before: Vector3 = position
	position += velocity * STEP
	_stop_at_the_ledge(before)
	var floor_altitude: float = _floor_altitude()
	on_floor = has_floor and position.y <= floor_altitude + CONTACT and velocity.y <= 0.0
	if on_floor:
		position.y = floor_altitude
		# What a collision does: nothing is left of the velocity that goes into the floor.
		var normal: Vector3 = _normal_underfoot()
		if velocity.dot(normal) < 0.0:
			velocity = velocity.slide(normal)


## Puts a wall beside the body, `distance` from its side, with this normal (pointing
## towards the body) and this height; `id` tells it apart from other walls.
func set_wall(id: int, normal: Vector3, distance: float, height: float) -> void:
	wall_id = id
	wall_normal = normal
	wall_distance = distance
	wall_height = height


func remove_wall() -> void:
	set_wall(RunnerFacts.NO_WALL, Vector3.ZERO, INF, 0.0)


## Puts a ledge across the way, its face right in front of the body, its top `height`
## above the body's feet.
func put_ledge_ahead(height: float) -> void:
	has_ledge = true
	ledge_face = position.z - motor.tuning.capsule_radius
	ledge_top = position.y + height


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _facts() -> RunnerFacts:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.on_floor = on_floor
	facts.velocity = velocity
	facts.altitude = position.y
	if on_floor:
		facts.floor_normal = _normal_underfoot()
	facts.can_stand = can_stand
	if has_floor:
		facts.ground_clearance = position.y - _floor_altitude()
	facts.wall_id = wall_id
	facts.wall_normal = wall_normal
	facts.wall_distance = wall_distance
	facts.wall_height = wall_height
	if _touches_the_ledge():
		facts.ledge_normal = Vector3.BACK
		facts.ledge_height = ledge_top - position.y
		facts.ledge_clear = ledge_clear
	return facts


## The body's side touches the face of the ledge, below its top.
func _touches_the_ledge() -> bool:
	if not has_ledge or position.y >= ledge_top - CONTACT:
		return false
	var gap: float = position.z - motor.tuning.capsule_radius - ledge_face
	return gap >= -CONTACT and gap <= CONTACT


## The face of the ledge stops a body that comes at it, from `before`, with its feet
## below its top.
func _stop_at_the_ledge(before: Vector3) -> void:
	if not has_ledge or position.y >= ledge_top - CONTACT:
		return
	var front: float = ledge_face + motor.tuning.capsule_radius
	if before.z >= front - CONTACT and position.z < front:
		position.z = front
		velocity.z = maxf(velocity.z, 0.0)


## The body stands over the top of the ledge: its axis is past the face.
func _is_over_the_ledge() -> bool:
	return has_ledge and position.z < ledge_face


func _normal_underfoot() -> Vector3:
	return Vector3.UP if _is_over_the_ledge() else floor_normal


## The altitude of the floor under the body.
func _floor_altitude() -> float:
	if _is_over_the_ledge():
		return ledge_top
	var across: float = floor_normal.x * position.x + floor_normal.z * position.z
	return floor_height - across / floor_normal.y
