class_name Tag
extends RefCounted
## One gesture of the cat of a chase to catch the mouse (docs/specs/chase-tag.md): a touch
## or a dive. A touch reaches out for its time, the runner running on no faster than a share
## of its top speed, then, if nothing ended the round, costs its recovery: a lower cap. A
## dive throws the runner forward, low, faster than it ran, for its time, nothing stopping
## it but a wall; then the runner lies down for its recovery, still, and gets up. The motor
## plays it and never knows whether it caught anything: the level observes, while the gesture
## reaches (reaches), whether the mouse is within its reach (from body to body) and its cone,
## and tells the chase so in a dated message. What it does not catch is a miss, and costs
## its recovery.

enum Gesture { TOUCH, DIVE }
## Reaching out: the window in which it catches. Then the recovery of a touch missed, the
## time down after a dive, and its end.
enum Phase { REACHING, RECOVERING, DOWN, OVER }

## Under this share of the speed of its dive, along its way, the runner has met a wall.
const STOPPED_SHARE: float = 0.5

var gesture: Gesture = Gesture.TOUCH
var phase: Phase = Phase.REACHING
## The fixed step of the motor at which it started, and the steps played in its phase, the
## one under way included.
var start_step: int = 0
var steps: int = 1
## The way a dive goes, horizontal, of length 1.
var heading: Vector3 = Vector3.ZERO

var _tuning: MovementTuning
## How many fixed steps it reaches, and how many its recovery lasts.
var _reaching_steps: int = 1
var _recovery_steps: int = 1
## The horizontal speed of a dive, and the altitude of the ground it left.
var _speed: float = 0.0
var _ground: float = 0.0


func _init(kind: Gesture, tuning: MovementTuning, step_seconds: float, at_step: int) -> void:
	gesture = kind
	_tuning = tuning
	start_step = at_step
	var reaching: float = tuning.tag_touch_time if kind == Gesture.TOUCH else tuning.tag_dive_time
	var recovery: float = tuning.tag_touch_recovery
	if kind == Gesture.DIVE:
		recovery = tuning.tag_dive_recovery
	_reaching_steps = _steps_of(reaching, step_seconds)
	_recovery_steps = _steps_of(recovery, step_seconds)


## A touch, started at the fixed step `at_step` of a motor whose steps last `step_seconds`.
static func touch(tuning: MovementTuning, step_seconds: float, at_step: int) -> Tag:
	return Tag.new(Gesture.TOUCH, tuning, step_seconds, at_step)


## A dive of a runner that observed `facts` (it runs on the ground), started at the fixed
## step `at_step`: the way it ran, the push of the tuning faster.
static func dive(
	facts: RunnerFacts, tuning: MovementTuning, step_seconds: float, at_step: int
) -> Tag:
	var made: Tag = Tag.new(Gesture.DIVE, tuning, step_seconds, at_step)
	var horizontal: Vector3 = Vector3(facts.velocity.x, 0.0, facts.velocity.z)
	made.heading = horizontal.normalized()
	made._speed = horizontal.length() + tuning.tag_dive_push
	made._ground = facts.altitude
	return made


## Whether the mouse, whose capsule has its axis from `mouse_axis[0]` (its lowest point) to
## `mouse_axis[1]` (its highest), is within `reach` of the capsule of the cat, whose axis is
## `cat_axis` (the same): the least distance between their axes, less `radii`, the radii of
## the two capsules together, is no more than `reach`; and within the cone of `cone` degrees
## (from side to side) about `facing`, along the ground. Both capsules upright.
static func reaches(
	cat_axis: PackedVector3Array,
	mouse_axis: PackedVector3Array,
	radii: float,
	facing: Vector3,
	reach: float,
	cone: float
) -> bool:
	var apart: Vector2 = Vector2(mouse_axis[0].x - cat_axis[0].x, mouse_axis[0].z - cat_axis[0].z)
	var gap: float = maxf(cat_axis[0].y - mouse_axis[1].y, mouse_axis[0].y - cat_axis[1].y)
	var distance: float = Vector2(apart.length(), maxf(gap, 0.0)).length()
	if distance - radii > reach:
		return false
	var ahead: Vector2 = Vector2(facing.x, facing.z)
	if apart.is_zero_approx() or ahead.is_zero_approx():
		return true
	return absf(ahead.angle_to(apart)) <= deg_to_rad(cone) / 2.0


## Whether the cat whose motor is `motor` catches the mouse at the step it just played: a
## gesture of its reaches, and the mouse is within its reach and its cone (reaches). The
## capsules as for reaches; `facing` is where the cat faces.
static func catches(
	motor: RunnerMotor,
	cat_axis: PackedVector3Array,
	mouse_axis: PackedVector3Array,
	radii: float,
	facing: Vector3
) -> bool:
	var gesture_of: Tag = motor.tag
	if gesture_of == null or gesture_of.phase != Phase.REACHING:
		return false
	return reaches(cat_axis, mouse_axis, radii, facing, gesture_of.reach(), gesture_of.cone())


## How far the gesture reaches, from the capsule of the cat to the capsule of the mouse, in
## m.
func reach() -> float:
	return _tuning.tag_touch_reach if gesture == Gesture.TOUCH else _tuning.tag_dive_reach


## How wide its cone is, from side to side, in degrees.
func cone() -> float:
	return _tuning.tag_touch_cone if gesture == Gesture.TOUCH else _tuning.tag_dive_cone


## One more fixed step of the gesture, the runner having observed `facts`: its phase ends
## once it has lasted its time, a dive as soon as it meets a wall.
func advance(facts: RunnerFacts) -> void:
	steps += 1
	match phase:
		Phase.REACHING:
			var stopped: bool = false
			if gesture == Gesture.DIVE:
				var along: float = Vector3(facts.velocity.x, 0.0, facts.velocity.z).dot(heading)
				stopped = along < _speed * STOPPED_SHARE
			if steps > _reaching_steps or stopped:
				phase = Phase.RECOVERING if gesture == Gesture.TOUCH else Phase.DOWN
				steps = 1
		Phase.RECOVERING, Phase.DOWN:
			if steps > _recovery_steps:
				phase = Phase.OVER


## The gesture is over: its recovery too.
func is_over() -> bool:
	return phase == Phase.OVER


## The highest horizontal speed it leaves the runner, in m/s, its top speed being
## `top_speed`: a share of it while a touch reaches and while it recovers; no cap otherwise.
func speed_cap(top_speed: float) -> float:
	if gesture != Gesture.TOUCH:
		return INF
	match phase:
		Phase.REACHING:
			return top_speed * _tuning.tag_touch_speed_ratio
		Phase.RECOVERING:
			return top_speed * _tuning.tag_touch_recovery_speed_ratio
	return INF


## The velocity of the dive at this step, the runner having observed `facts`, the step
## lasting `delta` s: its way at its speed, up and down an arc no higher than the tuning
## says, back on the ground it left at its end; then, down, still, falling if there is no
## floor under it.
func step(facts: RunnerFacts, delta: float) -> Vector3:
	if phase == Phase.REACHING:
		var share: float = float(steps) / _reaching_steps
		var height: float = 4.0 * _tuning.tag_dive_height * share * (1.0 - share)
		var velocity: Vector3 = heading * _speed
		velocity.y = (_ground + height - facts.altitude) / delta
		return velocity
	var falling: float = 0.0 if facts.on_floor else facts.velocity.y
	return Vector3(0.0, maxf(falling - _tuning.fall_gravity * delta, -_tuning.max_fall_speed), 0.0)


## A duration of `seconds`, in fixed steps of `step_seconds`: at least one.
static func _steps_of(seconds: float, step_seconds: float) -> int:
	if step_seconds <= 0.0:
		return 1
	return maxi(roundi(seconds / step_seconds), 1)
