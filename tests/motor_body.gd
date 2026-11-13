class_name MotorBody
extends RefCounted
## A runner without a scene, for the tests of the ground moves of game/core. It plays
## the part of the player layer over a floor that is a plane through the origin: it
## feeds the motor with the facts it observes and moves by the velocity the motor
## returns. Nothing snaps it to its floor: on a slope it only stays on it if the motor
## asks for a velocity that follows the slope.

const STEP: float = 1.0 / 60.0
## How close to the floor counts as standing on it.
const CONTACT: float = 0.0001

var motor: RunnerMotor
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var on_floor: bool = true
## The floor: whether there is one, and its normal (a slope when it is not straight up).
var has_floor: bool = true
var floor_normal: Vector3 = Vector3.UP
## There is room above the runner to stand up.
var can_stand: bool = true


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
	var facts: RunnerFacts = RunnerFacts.new()
	facts.on_floor = on_floor
	facts.velocity = velocity
	facts.altitude = position.y
	if on_floor:
		facts.floor_normal = floor_normal
	facts.can_stand = can_stand
	velocity = motor.step(intent, facts, STEP)
	position += velocity * STEP
	var floor_altitude: float = _floor_altitude()
	on_floor = has_floor and position.y <= floor_altitude + CONTACT and velocity.y <= 0.0
	if on_floor:
		position.y = floor_altitude
		# What a collision does: nothing is left of the velocity that goes into the floor.
		if velocity.dot(floor_normal) < 0.0:
			velocity = velocity.slide(floor_normal)


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## The altitude of the floor under the body.
func _floor_altitude() -> float:
	var across: float = floor_normal.x * position.x + floor_normal.z * position.z
	return -across / floor_normal.y
