class_name Tag
extends RefCounted
## One gesture of the cat of a chase to catch the mouse (docs/specs/chase-tag.md): a touch
## or a dive. A touch reaches out for its time, the runner running on no faster than a share
## of its top speed, then, if nothing ended the round, costs its recovery: a lower cap. A
## dive throws the runner forward, low, faster than it ran, for its time, nothing stopping
## it but a wall (it falls once it has left the ground it dived from); then the runner lies
## down for its recovery, still, and gets up. The motor plays it and never knows whether it
## caught anything: the level observes, while the gesture reaches (reaches_during), whether
## the mouse came within its reach (from body to body) and its cone during the step, and tells
## the chase so in a dated message. What it does not catch is a miss, and costs its recovery.
## The reaches are those of the body, measured on its bones (docs/specs/chase-tag-reach.md).

enum Gesture { TOUCH, DIVE }
## Reaching out: the window in which it catches. Then the recovery of a touch missed, the
## time down after a dive, and its end.
enum Phase { REACHING, RECOVERING, DOWN, OVER }

## How far under the ground it left the floor under a dive must be for the dive to have
## left it (off the edge of a block or a platform), in m: the rounding of a contact.
const OFF_THE_GROUND: float = 0.05
## The rounding of an angle, in radians: a mouse on a side of the cone is within it.
const ANGLE_ROUNDING: float = 0.0001
## How many times the search for the instant two capsules are the nearest in a step narrows
## it, each time by the golden ratio: to a millionth of the step and less.
const NEAREST_SEARCH: int = 32
const GOLDEN: float = 0.6180339887

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
	if _distance(cat_axis, mouse_axis) - radii > reach:
		return false
	return _in_the_cone(_apart(cat_axis, mouse_axis), facing, cone)


## Whether the mouse is within `reach` of the cat and within its cone (reaches) at one instant
## at least of a step in which the axis of the capsule of the cat went from `cat_axes[0]` to
## `cat_axes[1]`, and the axis of the mouse from `mouse_axes[0]` to `mouse_axes[1]`, each
## at an even pace (docs/specs/chase-tag-reach.md, decision 6): at the instant their capsules
## are the nearest, or, if the mouse is out of the cone then, at an instant it comes in or
## goes out of it, or at an end of the step. Two runners that cross within the step do not
## miss each other.
static func reaches_during(
	cat_axes: Array[PackedVector3Array],
	mouse_axes: Array[PackedVector3Array],
	radii: float,
	facing: Vector3,
	reach: float,
	cone: float
) -> bool:
	var instants: PackedFloat32Array = [0.0, 1.0, _nearest_instant(cat_axes, mouse_axes)]
	instants.append_array(_cone_crossings(cat_axes, mouse_axes, facing, cone))
	for instant: float in instants:
		var cat_axis: PackedVector3Array = _axis_at(cat_axes, instant)
		var mouse_axis: PackedVector3Array = _axis_at(mouse_axes, instant)
		if reaches(cat_axis, mouse_axis, radii, facing, reach, cone):
			return true
	return false


## Whether the cat whose motor is `motor` catches the mouse during the step it just played: a
## gesture of its reaches, and the mouse is within its reach and its cone at one instant of
## the step (reaches_during). The capsules as for reaches_during, from where they were as the
## step started to where they are; `facing` is where the cat faces.
static func catches(
	motor: RunnerMotor,
	cat_axes: Array[PackedVector3Array],
	mouse_axes: Array[PackedVector3Array],
	radii: float,
	facing: Vector3
) -> bool:
	var gesture_of: Tag = motor.tag
	if gesture_of == null or gesture_of.phase != Phase.REACHING:
		return false
	return reaches_during(
		cat_axes, mouse_axes, radii, facing, gesture_of.reach(), gesture_of.cone()
	)


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


## The least distance between the upright axes `cat_axis` and `mouse_axis` (each from its
## lowest point to its highest): along the ground, and up or down when one is above the other.
static func _distance(cat_axis: PackedVector3Array, mouse_axis: PackedVector3Array) -> float:
	var gap: float = maxf(cat_axis[0].y - mouse_axis[1].y, mouse_axis[0].y - cat_axis[1].y)
	return Vector2(_apart(cat_axis, mouse_axis).length(), maxf(gap, 0.0)).length()


## How far the axis `mouse_axis` is from the axis `cat_axis`, along the ground.
static func _apart(cat_axis: PackedVector3Array, mouse_axis: PackedVector3Array) -> Vector2:
	return Vector2(mouse_axis[0].x - cat_axis[0].x, mouse_axis[0].z - cat_axis[0].z)


## Whether `apart`, along the ground, is within the cone of `cone` degrees (from side to side)
## about `facing`, to the rounding of an angle; on the axis itself, or facing nowhere, it is.
static func _in_the_cone(apart: Vector2, facing: Vector3, cone: float) -> bool:
	var ahead: Vector2 = Vector2(facing.x, facing.z)
	if apart.is_zero_approx() or ahead.is_zero_approx():
		return true
	return absf(ahead.angle_to(apart)) <= deg_to_rad(cone) / 2.0 + ANGLE_ROUNDING


## Where an axis that goes from `axes[0]` to `axes[1]` at an even pace is at `instant`, from
## 0 (the start of the step) to 1 (its end).
static func _axis_at(axes: Array[PackedVector3Array], instant: float) -> PackedVector3Array:
	return PackedVector3Array(
		[axes[0][0].lerp(axes[1][0], instant), axes[0][1].lerp(axes[1][1], instant)]
	)


## The instant of the step, from 0 to 1, at which the axes going from `cat_axes[0]` to
## `cat_axes[1]` and from `mouse_axes[0]` to `mouse_axes[1]` are the nearest: their distance
## along the step goes down then up (it is convex), so a golden-section search finds it.
static func _nearest_instant(
	cat_axes: Array[PackedVector3Array], mouse_axes: Array[PackedVector3Array]
) -> float:
	var low: float = 0.0
	var high: float = 1.0
	for search: int in NEAREST_SEARCH:
		var first: float = high - GOLDEN * (high - low)
		var second: float = low + GOLDEN * (high - low)
		var at_first: float = _distance(_axis_at(cat_axes, first), _axis_at(mouse_axes, first))
		var at_second: float = _distance(_axis_at(cat_axes, second), _axis_at(mouse_axes, second))
		if at_first <= at_second:
			high = second
		else:
			low = first
	return (low + high) / 2.0


## The instants of the step, from 0 to 1, at which the mouse crosses a side of the cone of
## `cone` degrees about `facing` (the line of each of its sides), the axes going from
## `cat_axes[0]` to `cat_axes[1]` and from `mouse_axes[0]` to `mouse_axes[1]`.
static func _cone_crossings(
	cat_axes: Array[PackedVector3Array],
	mouse_axes: Array[PackedVector3Array],
	facing: Vector3,
	cone: float
) -> PackedFloat32Array:
	var crossings: PackedFloat32Array = []
	var ahead: Vector2 = Vector2(facing.x, facing.z)
	if ahead.is_zero_approx():
		return crossings
	var start: Vector2 = _apart(cat_axes[0], mouse_axes[0])
	var change: Vector2 = _apart(cat_axes[1], mouse_axes[1]) - start
	for side: float in [-1.0, 1.0]:
		var edge: Vector2 = ahead.rotated(side * deg_to_rad(cone) / 2.0)
		var across: Vector2 = edge.orthogonal()
		var rate: float = across.dot(change)
		if is_zero_approx(rate):
			continue
		var instant: float = -across.dot(start) / rate
		if instant > 0.0 and instant < 1.0:
			crossings.append(instant)
	return crossings
