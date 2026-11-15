class_name TouchHand
extends RefCounted
## The hand of the touch of the cat of a chase, on the Mixamo character (RunnerCharacter):
## while the upper body reaches out, for a runner within the cone of the touch, the upper
## body turns so that the shoulder of the hand on its side faces that runner, and that hand,
## its wrist straight, stretches its fingertips towards its body by inverse kinematics; no
## farther than the reach of the touch, and onto that body only once the level observed the
## catch (docs/specs/chase-tag-reach.md, decision 4). Also the reach of the arm and of the
## dive, measured once on the bones of the clips as they are made (decisions 2 and 3).
## Presentation only: the game reads the reaches from its tuning, never from the hand.

## At how many evenly spaced instants of the dive its reach is measured.
const DIVE_SAMPLES: int = 60
## How far short of the body of the runner it reaches for the fingertips of a touch that did
## not catch it stop, in m.
const SHORT_OF_THE_BODY: float = 0.05
## An arm whose elbow is this close to the line from its shoulder to its wrist is held
## straight: its bend says nothing of where its elbow points, in m.
const STRAIGHT_ARM: float = 0.02

## Measured on the pose of the touch (Reaching Out) as it is made, in the space of the
## skeleton, before it is put to its size: how far the right shoulder is from the axis of the
## body, along the ground, plus the length of its arm stretched to the fingertips.
static var _arm_reach: float = 0.0
## Where the fingertips of both hands go in the dive as it is played, at DIVE_SAMPLES
## instants of it, in the space of the skeleton.
static var _dive_fingertips: PackedVector3Array = []

## The skeleton of the character, its tuning, and of each hand its inverse kinematics and the
## nodes it reaches for and points its elbow to (shared with the character).
var _skeleton: Skeleton3D
var _tuning: MovementTuning
var _arms: Dictionary[String, TwoBoneIK3D] = {}
var _reached: Dictionary[String, Node3D] = {}
var _elbow_poles: Dictionary[String, Node3D] = {}
## The axis and the radius of the capsule of the runner it reaches for (an empty axis: none),
## and whether the touch caught it; the hand that reaches for it, and whether its target was
## put at the frame before.
var _axis: PackedVector3Array = PackedVector3Array()
var _radius: float = 0.0
var _caught: bool = false
var _hand: String = RunnerCharacter.RIGHT_HAND
var _aimed: bool = false


func _init(
	skeleton: Skeleton3D,
	tuning: MovementTuning,
	arms: Dictionary[String, TwoBoneIK3D],
	reached: Dictionary[String, Node3D],
	elbow_poles: Dictionary[String, Node3D]
) -> void:
	_skeleton = skeleton
	_tuning = tuning
	_arms = arms
	_reached = reached
	_elbow_poles = elbow_poles


## The touch reaches for the runner whose capsule has the axis `axis`, from its lowest point
## to its highest, and the radius `radius`, and `caught` it, as the level observed; an empty
## axis: for nobody.
func reach_for(axis: PackedVector3Array, radius: float, caught: bool) -> void:
	_axis = axis
	_radius = radius
	_caught = caught


## While the upper body reaches out, as much as `share`, for a runner within the cone of the
## touch: the upper body turns so that the shoulder of the hand on its side faces the point of
## its body the fingertips go to (fingertips_target), and that hand, its wrist straight,
## stretches its fingertips there (or as far towards it as the arm goes); its elbow keeps the
## bend of the pose, or points down from an arm held straight. Measured where the body is
## shown, between two fixed steps: the skeleton `seen` there, the feet of the character at
## `body`, facing its -Z.
func reach(share: float, seen: Transform3D, body: Transform3D) -> void:
	if share <= 0.0 or _axis.is_empty():
		_aimed = false
		return
	var right: String = RunnerCharacter.RIGHT_HAND
	var height: float = (seen * _bone_pose(RunnerCharacter.UPPER_ARMS[right]).origin).y
	var from: Vector3 = Vector3(body.origin.x, height, body.origin.z)
	var target: Vector3 = fingertips_target(
		from, _tuning.capsule_radius, _tuning.tag_touch_reach, _axis, _radius, _caught
	)
	var ahead: Vector3 = -body.basis.z
	var towards: Vector3 = target - from
	var turn: float = Vector2(ahead.x, ahead.z).angle_to(Vector2(towards.x, towards.z))
	if absf(turn) > deg_to_rad(_tuning.tag_touch_cone) / 2.0:
		_aimed = false
		return
	var hand: String = right if towards.dot(body.basis.x) >= 0.0 else RunnerCharacter.LEFT_HAND
	if hand != _hand:
		_hand = hand
		_aimed = false
	_turn_the_upper_body(seen, hand, target, share)
	_straighten_the_wrist(hand, share)
	var wrist: Vector3 = seen * _bone_pose(hand).origin
	var shoulder: Vector3 = seen * _bone_pose(RunnerCharacter.UPPER_ARMS[hand]).origin
	var elbow: Vector3 = seen * _bone_pose(RunnerCharacter.FOREARMS[hand]).origin
	var out: Vector3 = elbow - (shoulder + wrist) / 2.0
	if out.length() < STRAIGHT_ARM:
		out = Vector3.DOWN
	var pole: Vector3 = elbow + out.normalized() * RunnerCharacter.POLE_DISTANCE
	# The arm reaches for where its target was put at the frame before: not before it was.
	_arms[hand].influence = share if _aimed else 0.0
	_aimed = true
	_reached[hand].global_position = _wrist_for(seen, hand, target, pole)
	_elbow_poles[hand].global_position = pole


## How far the arm of a touch reaches beyond the capsule of the runner, in m, measured on the
## bones, the character at the size `size` (docs/specs/chase-tag-reach.md, decision 2): the
## right shoulder turned towards the runner touched, the arm stretched, to the fingertips of
## the pose of Reaching Out.
func touch_reach(size: float) -> float:
	return _arm_reach * size - _tuning.capsule_radius


## How far the fingertips of the dive go beyond the capsule of the runner, at the most, in m,
## measured on the bones of the dive as it is played, the model placed by `model` in the frame
## of the runner (docs/specs/chase-tag-reach.md, decision 3).
func dive_reach(model: Transform3D) -> float:
	var radius: float = _tuning.capsule_radius
	var lowest: Vector3 = Vector3.UP * radius
	var highest: Vector3 = Vector3.UP * (_tuning.capsule_height - radius)
	var farthest: float = 0.0
	for fingertip: Vector3 in _dive_fingertips:
		var place: Vector3 = model * fingertip
		var axis: Vector3 = Geometry3D.get_closest_point_to_segment(place, lowest, highest)
		farthest = maxf(farthest, place.distance_to(axis) - radius)
	return farthest


## Where the fingertips of a touch go, from `from`, on the axis of the capsule of the cat (of
## radius `radius`) at the height of its shoulders: towards the point of the body touched
## nearest it (touch_point: its capsule of axis `axis` and radius `other_radius`); onto it if
## the level observed that the touch caught it (`caught`), SHORT_OF_THE_BODY short of it
## otherwise; and never farther from the axis of the cat than its capsule and the reach
## `reach` of the touch (docs/specs/chase-tag-reach.md, decision 4).
static func fingertips_target(
	from: Vector3,
	radius: float,
	reach: float,
	axis: PackedVector3Array,
	other_radius: float,
	caught: bool
) -> Vector3:
	var way: Vector3 = touch_point(from, axis, other_radius) - from
	var along: float = way.length()
	if not caught:
		along -= SHORT_OF_THE_BODY
	return from + way.normalized() * clampf(along, 0.0, radius + reach)


## The point of the surface of an upright capsule, of axis `axis` (its lowest point, then its
## highest) and radius `radius`, nearest to `from`.
static func touch_point(from: Vector3, axis: PackedVector3Array, radius: float) -> Vector3:
	var on_the_axis: Vector3 = Geometry3D.get_closest_point_to_segment(from, axis[0], axis[1])
	var out: Vector3 = from - on_the_axis
	if out.is_zero_approx():
		return on_the_axis
	return on_the_axis + out.normalized() * minf(radius, out.length())


## Measures, on the pose of the touch `pose`, how far its right shoulder is from the axis of
## the body along the ground plus the length of its arm stretched to the fingertips, in the
## space of `skeleton`.
static func measure_the_arm(pose: Animation, skeleton: Skeleton3D) -> void:
	var right: String = RunnerCharacter.RIGHT_HAND
	var places: PackedVector3Array = MixamoClip.bone_places(pose, 0.0, skeleton)
	var shoulder: Vector3 = places[skeleton.find_bone(RunnerCharacter.UPPER_ARMS[right])]
	var elbow: Vector3 = places[skeleton.find_bone(RunnerCharacter.FOREARMS[right])]
	var wrist: Vector3 = places[skeleton.find_bone(right)]
	var fingertips: Vector3 = places[skeleton.find_bone(RunnerCharacter.FINGERTIPS[right])]
	var arm: float = (
		shoulder.distance_to(elbow) + elbow.distance_to(wrist) + wrist.distance_to(fingertips)
	)
	_arm_reach = Vector2(shoulder.x, shoulder.z).length() + arm


## Measures where the fingertips of both hands go in the dive `made` as it is played, at
## DIVE_SAMPLES evenly spaced instants of it, in the space of `skeleton`.
static func measure_the_dive(made: Animation, skeleton: Skeleton3D) -> void:
	_dive_fingertips = []
	for sample: int in DIVE_SAMPLES + 1:
		var places: PackedVector3Array = MixamoClip.bone_places(
			made, made.length * sample / DIVE_SAMPLES, skeleton
		)
		for hand: String in RunnerCharacter.FINGERTIPS:
			_dive_fingertips.append(places[skeleton.find_bone(RunnerCharacter.FINGERTIPS[hand])])


## Turns the upper body of the character, `seen` there, as much as `share`, about the vertical
## through its spine, so that the shoulder of `hand` faces `target` from it, whatever the
## hips of the legs do.
func _turn_the_upper_body(seen: Transform3D, hand: String, target: Vector3, share: float) -> void:
	var spine: int = _skeleton.find_bone(RunnerCharacter.SPINE)
	var pivot: Vector3 = seen * _bone_pose(RunnerCharacter.SPINE).origin
	var shoulder: Vector3 = seen * _bone_pose(RunnerCharacter.UPPER_ARMS[hand]).origin - pivot
	var towards: Vector3 = target - pivot
	var angle: float = Vector2(shoulder.x, shoulder.z).angle_to(Vector2(towards.x, towards.z))
	# Turning along the ground by `angle` turns from +X towards +Z: about -Y.
	var up: Vector3 = (seen.basis.inverse() * Vector3.UP).normalized()
	var turn: Quaternion = Quaternion(up, -angle * share)
	var parent: int = _skeleton.get_bone_parent(spine)
	var carried: Quaternion = _skeleton.get_bone_global_pose(parent).basis.get_rotation_quaternion()
	var pose: Quaternion = _skeleton.get_bone_pose_rotation(spine)
	_skeleton.set_bone_pose_rotation(spine, carried.inverse() * turn * carried * pose)


## Turns the hand `hand` at its wrist, as much as `share`, so that its fingertips go on along
## its forearm: a wrist held straight, which the arm carries as it stretches.
func _straighten_the_wrist(hand: String, share: float) -> void:
	var bone: int = _skeleton.find_bone(hand)
	var forearm: int = _skeleton.find_bone(RunnerCharacter.FOREARMS[hand])
	var wrist: Vector3 = _bone_pose(hand).origin
	var fingers: Vector3 = _bone_pose(RunnerCharacter.FINGERTIPS[hand]).origin - wrist
	var along: Vector3 = wrist - _bone_pose(RunnerCharacter.FOREARMS[hand]).origin
	if fingers.is_zero_approx() or along.is_zero_approx():
		return
	var arc: Quaternion = Quaternion(fingers.normalized(), along.normalized())
	arc = Quaternion.IDENTITY.slerp(arc, share)
	var carried: Quaternion = (
		_skeleton.get_bone_global_pose(forearm).basis.get_rotation_quaternion()
	)
	var held: Quaternion = _skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
	_skeleton.set_bone_pose_rotation(bone, carried.inverse() * arc * held)


## Where the wrist of `hand` of the character, `seen` there, goes so that its fingertips, the
## wrist held straight, reach `target`, or as far towards it as the arm stretches: the elbow
## bent towards `pole`, the forearm and the hand in one line from it to the target.
func _wrist_for(seen: Transform3D, hand: String, target: Vector3, pole: Vector3) -> Vector3:
	var shoulder: Vector3 = seen * _bone_pose(RunnerCharacter.UPPER_ARMS[hand]).origin
	var elbow: Vector3 = seen * _bone_pose(RunnerCharacter.FOREARMS[hand]).origin
	var wrist: Vector3 = seen * _bone_pose(hand).origin
	var fingertips: Vector3 = seen * _bone_pose(RunnerCharacter.FINGERTIPS[hand]).origin
	var upper: float = shoulder.distance_to(elbow)
	var lower: float = elbow.distance_to(wrist)
	var outer: float = lower + wrist.distance_to(fingertips)
	var way: Vector3 = target - shoulder
	if way.is_zero_approx():
		return wrist
	var along: Vector3 = way.normalized()
	var span: float = clampf(way.length(), absf(upper - outer), upper + outer)
	var bend: Vector3 = pole - shoulder
	bend -= along * bend.dot(along)
	if bend.is_zero_approx():
		bend = Vector3.DOWN - along * along.y
	var cosine: float = (upper * upper + span * span - outer * outer) / (2.0 * upper * span)
	cosine = clampf(cosine, -1.0, 1.0)
	var bent: Vector3 = along * cosine + bend.normalized() * sqrt(1.0 - cosine * cosine)
	var at_the_elbow: Vector3 = shoulder + bent * upper
	var reached: Vector3 = shoulder + along * span
	return at_the_elbow + (reached - at_the_elbow).normalized() * lower


## Where the bone `bone` is in the space of the skeleton, as the clips and the modifiers
## before put it.
func _bone_pose(bone: String) -> Transform3D:
	return _skeleton.get_bone_global_pose(_skeleton.find_bone(bone))
