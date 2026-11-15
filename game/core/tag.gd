class_name Tag
extends RefCounted
## One gesture of the cat of a chase to catch the mouse (docs/specs/chase-tag.md): a touch
## or a dive. A touch reaches out for its time, the runner running on no faster than a share
## of its top speed, then, if nothing ended the round, costs its recovery: a lower cap. A
## dive throws the runner forward, low, faster than it ran, for its time, nothing stopping
## it but a wall (it falls once it has left the ground it dived from); then the runner lies
## down for its recovery, still, and gets up. The motor plays it and never knows whether it
## caught anything: the level observes, while the gesture reaches (catches), whether the
## mouse came within its reach and its cone during the step, and tells the chase so in a dated
## message. What it does not catch is a miss, and costs its recovery. The reaches are those of
## the body, measured on its bones (TagReach, docs/specs/chase-tag-reach.md).

enum Gesture { TOUCH, DIVE }
## Reaching out: the window in which it catches. Then the recovery of a touch missed, the
## time down after a dive, and its end.
enum Phase { REACHING, RECOVERING, DOWN, OVER }

## How far under the ground it left the floor under a dive must be for the dive to have
## left it (off the edge of a block or a platform), in m: the rounding of a contact.
const OFF_THE_GROUND: float = 0.05

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
## The dive has left the ground it dived from: it falls.
var _falling: bool = false


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


## Whether the cat whose motor is `motor` catches the mouse during the step it just played: a
## gesture of its reaches, and the mouse, its capsule of radius `mouse_radius`, came within
## the reach of the gesture and its cone at one instant of the step (TagReach.reaches_during):
## the axis of the capsule of the cat from `cat_axes[0]` as the step started to `cat_axes[1]`,
## the axis of the mouse from `mouse_axes[0]` to `mouse_axes[1]`; `facing` is where the cat
## faces.
static func catches(
	motor: RunnerMotor,
	cat_axes: Array[PackedVector3Array],
	mouse_axes: Array[PackedVector3Array],
	mouse_radius: float,
	facing: Vector3
) -> bool:
	var gesture_of: Tag = motor.tag
	if gesture_of == null or gesture_of.phase != Phase.REACHING:
		return false
	return gesture_of.span().reaches_during(cat_axes, mouse_axes, mouse_radius, facing)


## How far the gesture reaches, and from where on the body (TagReach).
func span() -> TagReach:
	return TagReach.touch(_tuning) if gesture == Gesture.TOUCH else TagReach.dive(_tuning)


## One more fixed step of the gesture, the runner having observed `facts`: its phase ends
## once it has lasted its time, a dive as soon as it meets a wall.
func advance(facts: RunnerFacts) -> void:
	steps += 1
	match phase:
		Phase.REACHING:
			var stopped: bool = false
			if gesture == Gesture.DIVE:
				var along: float = Vector3(facts.velocity.x, 0.0, facts.velocity.z).dot(heading)
				stopped = along < _speed * _tuning.tag_dive_stopped_share
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
## says, back on the ground it left at its end; once the floor under it is lower than that
## ground (off an edge), it falls, still going its way, to the end of the dive. Then, down,
## still, falling if there is no floor under it.
func step(facts: RunnerFacts, delta: float) -> Vector3:
	if phase == Phase.REACHING:
		var velocity: Vector3 = heading * _speed
		var floor_under: float = facts.altitude - facts.ground_clearance
		_falling = _falling or floor_under < _ground - OFF_THE_GROUND
		if _falling:
			velocity.y = _fall(facts, delta)
			return velocity
		var share: float = float(steps) / _reaching_steps
		var height: float = 4.0 * _tuning.tag_dive_height * share * (1.0 - share)
		velocity.y = (_ground + height - facts.altitude) / delta
		return velocity
	return Vector3(0.0, _fall(facts, delta), 0.0)


## The vertical speed of a runner that falls at this step, the runner having observed
## `facts`: none kept on a floor.
func _fall(facts: RunnerFacts, delta: float) -> float:
	var falling: float = 0.0 if facts.on_floor else facts.velocity.y
	return maxf(falling - _tuning.fall_gravity * delta, -_tuning.max_fall_speed)


## A duration of `seconds`, in fixed steps of `step_seconds`: at least one.
static func _steps_of(seconds: float, step_seconds: float) -> int:
	if step_seconds <= 0.0:
		return 1
	return maxi(roundi(seconds / step_seconds), 1)
