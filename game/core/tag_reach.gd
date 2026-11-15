class_name TagReach
extends RefCounted
## How far a gesture of the cat of a chase reaches (Tag, docs/specs/chase-tag-reach.md): the
## body that does it measured once on its bones, so that what catches is what touches on
## screen. It reaches out from a circle about the axis of the capsule of the cat, at a height
## above its feet (its shoulder turned towards the mouse, for a touch; its fingertips out in
## front, for a dive), and `arm` farther; the mouse is within it when its body (its capsule)
## comes that near the circle, within the cone of the gesture, along the ground, about where
## the cat faces. Both capsules upright.

## The rounding of an angle, in radians: a mouse on a side of the cone is within it.
const ANGLE_ROUNDING: float = 0.0001
## How many times the search for the instant the mouse is the nearest in a step narrows it,
## each time by the golden ratio: to a millionth of the step and less.
const NEAREST_SEARCH: int = 32
const GOLDEN: float = 0.6180339887

## How high above the lowest point of the axis of the cat the circle is, how far from the
## axis, and how far beyond it the gesture reaches, in m; and how wide its cone is, from side
## to side, in degrees.
var above_the_axis: float = 0.0
var offset: float = 0.0
var arm: float = 0.0
var cone: float = 0.0


## A reach from the circle `height` m above the feet of a cat whose capsule has the radius
## `radius`, `offset` m from its axis, `arm` m farther, within `cone` degrees.
func _init(
	height: float, radius: float, reach_offset: float, reach_arm: float, wide: float
) -> void:
	above_the_axis = height - radius
	offset = reach_offset
	arm = reach_arm
	cone = wide


## The reach of a touch of the runners of `tuning`: from the shoulder, turned towards the
## mouse, the arm stretched to the fingertips; tag_touch_reach beyond the capsule along the
## ground.
static func touch(tuning: MovementTuning) -> TagReach:
	var shoulder: float = tuning.tag_touch_shoulder_offset
	var stretched: float = tuning.capsule_radius + tuning.tag_touch_reach - shoulder
	return TagReach.new(
		tuning.tag_touch_shoulder_height,
		tuning.capsule_radius,
		shoulder,
		stretched,
		tuning.tag_touch_cone
	)


## The reach of a dive of the runners of `tuning`: its fingertips, at their height when they
## are the farthest out, tag_dive_reach beyond the capsule.
static func dive(tuning: MovementTuning) -> TagReach:
	return TagReach.new(
		tuning.tag_dive_fingertips_height,
		tuning.capsule_radius,
		tuning.capsule_radius + tuning.tag_dive_reach,
		0.0,
		tuning.tag_dive_cone
	)


## How far the body of the mouse, whose capsule has its axis from `mouse_axis[0]` (its lowest
## point) to `mouse_axis[1]` (its highest) and the radius `mouse_radius`, is beyond the reach
## of the cat whose axis is `cat_axis` (the same), in m: 0 or less within it.
func gap(
	cat_axis: PackedVector3Array, mouse_axis: PackedVector3Array, mouse_radius: float
) -> float:
	var level: float = cat_axis[0].y + above_the_axis
	var up: float = maxf(maxf(mouse_axis[0].y - level, level - mouse_axis[1].y), 0.0)
	var across: float = maxf(_apart(cat_axis, mouse_axis).length() - offset, 0.0)
	return Vector2(across, up).length() - mouse_radius - arm


## Whether the mouse (as for gap) is within the reach and within the cone about `facing`.
func reaches(
	cat_axis: PackedVector3Array,
	mouse_axis: PackedVector3Array,
	mouse_radius: float,
	facing: Vector3
) -> bool:
	if gap(cat_axis, mouse_axis, mouse_radius) > 0.0:
		return false
	return _in_the_cone(_apart(cat_axis, mouse_axis), facing)


## Whether the mouse is within the reach and the cone (reaches) at one instant at least of a
## step in which the axis of the capsule of the cat went from `cat_axes[0]` to `cat_axes[1]`,
## and the axis of the mouse from `mouse_axes[0]` to `mouse_axes[1]`, each at an even pace
## (docs/specs/chase-tag-reach.md, decision 6): at the instant it is the nearest, or, if it is
## out of the cone then, at an instant it comes in or goes out of it, or at an end of the
## step. Two runners that cross within the step do not miss each other.
func reaches_during(
	cat_axes: Array[PackedVector3Array],
	mouse_axes: Array[PackedVector3Array],
	mouse_radius: float,
	facing: Vector3
) -> bool:
	var instants: PackedFloat32Array = [
		0.0, 1.0, _nearest_instant(cat_axes, mouse_axes, mouse_radius)
	]
	instants.append_array(_cone_crossings(cat_axes, mouse_axes, facing))
	for instant: float in instants:
		var cat_axis: PackedVector3Array = _axis_at(cat_axes, instant)
		var mouse_axis: PackedVector3Array = _axis_at(mouse_axes, instant)
		if reaches(cat_axis, mouse_axis, mouse_radius, facing):
			return true
	return false


## How far the axis `mouse_axis` is from the axis `cat_axis`, along the ground.
static func _apart(cat_axis: PackedVector3Array, mouse_axis: PackedVector3Array) -> Vector2:
	return Vector2(mouse_axis[0].x - cat_axis[0].x, mouse_axis[0].z - cat_axis[0].z)


## Whether `apart`, along the ground, is within the cone about `facing`, to the rounding of an
## angle; on the axis itself, or facing nowhere, it is.
func _in_the_cone(apart: Vector2, facing: Vector3) -> bool:
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


## The instant of the step, from 0 to 1, at which the mouse is the nearest the reach, the axes
## going from `cat_axes[0]` to `cat_axes[1]` and from `mouse_axes[0]` to `mouse_axes[1]`:
## how far it is goes down then up along the step (it is convex), so a golden-section search
## finds it.
func _nearest_instant(
	cat_axes: Array[PackedVector3Array], mouse_axes: Array[PackedVector3Array], radius: float
) -> float:
	var low: float = 0.0
	var high: float = 1.0
	for search: int in NEAREST_SEARCH:
		var first: float = high - GOLDEN * (high - low)
		var second: float = low + GOLDEN * (high - low)
		var at_first: float = gap(_axis_at(cat_axes, first), _axis_at(mouse_axes, first), radius)
		var at_second: float = gap(_axis_at(cat_axes, second), _axis_at(mouse_axes, second), radius)
		if at_first <= at_second:
			high = second
		else:
			low = first
	return (low + high) / 2.0


## The instants of the step, from 0 to 1, at which the mouse crosses a side of the cone about
## `facing` (the line of each of its sides), the axes going from `cat_axes[0]` to
## `cat_axes[1]` and from `mouse_axes[0]` to `mouse_axes[1]`.
func _cone_crossings(
	cat_axes: Array[PackedVector3Array], mouse_axes: Array[PackedVector3Array], facing: Vector3
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
