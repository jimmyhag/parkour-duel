class_name RunnerSnapshot
extends RefCounted
## What one machine of an online chase tells the other of its own runner at every fixed step
## (docs/specs/online-chase.md, decision 3), so that the other shows it without simulating
## it: the date (the steps its machine has sent so far), where the body is, how its visible
## body is placed and turned, its velocity, the height of its capsule, how many times it was
## put somewhere (a start point: no interpolation across that), the animation it shows
## (RunnerAnimation), the gesture of the cat under way (Tag), and whether it was caught. It
## travels as a fixed layout of plain numbers (encode); what comes from the network is read
## back only as numbers, each one checked (decode): nothing else is ever made from it.

## The bytes of an encoded snapshot.
const SIZE: int = 118
## The latest date a snapshot may have: a day of fixed steps at 60 per second.
const LATEST_STEP: int = 60 * 60 * 60 * 24
## The gesture of no tag.
const NO_GESTURE: int = 255
## The farthest a position may be from the origin, in m, and the widest a speed or a time,
## past which a snapshot is not believed.
const FARTHEST: float = 10000.0
const WIDEST: float = 1000.0
## The tallest a capsule may be, in m.
const TALLEST: float = 10.0
## How far from 1 the length of the rotation may be before it is not believed.
const ROTATION_SLACK: float = 0.01
## The flags of the byte that holds them.
const CAUGHT: int = 1
const AIMING: int = 2
const TOUCHING: int = 4
const WITH_LOCOMOTION: int = 8
const PLACEMENTS: int = 256

var step: int = 0
## The body: where its feet are, its velocity, the height of its capsule, in the world.
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var capsule_height: float = 0.0
## The visible body, in the body: where it is and how it is turned.
var visual: Transform3D = Transform3D.IDENTITY
## How many times the runner was put somewhere, modulo PLACEMENTS.
var placement: int = 0
var animation: RunnerAnimation = RunnerAnimation.new()
## The gesture of the cat under way, its phase and the step of its motor it started at;
## NO_GESTURE for none.
var gesture: int = NO_GESTURE
var gesture_phase: Tag.Phase = Tag.Phase.REACHING
var gesture_start: int = 0
## The runner was caught by the cat, and reacts.
var caught: bool = false


## The snapshot as bytes: SIZE of them, little-endian.
func encode() -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(SIZE)
	bytes.encode_u32(0, step)
	_put_vector(bytes, 4, position)
	_put_vector(bytes, 16, velocity)
	var rotation: Quaternion = visual.basis.get_rotation_quaternion()
	bytes.encode_float(28, rotation.x)
	bytes.encode_float(32, rotation.y)
	bytes.encode_float(36, rotation.z)
	bytes.encode_float(40, rotation.w)
	_put_vector(bytes, 44, visual.origin)
	bytes.encode_float(56, capsule_height)
	bytes.encode_u8(60, posmod(placement, PLACEMENTS))
	var with_locomotion: bool = animation.locomotion.size() == RunnerAnimation.LOCOMOTION.size()
	var flags: int = (
		(CAUGHT if caught else 0)
		| (AIMING if animation.aiming else 0)
		| (TOUCHING if animation.touching else 0)
		| (WITH_LOCOMOTION if with_locomotion else 0)
	)
	bytes.encode_u8(61, flags)
	bytes.encode_u8(62, animation.clip)
	bytes.encode_u8(63, animation.wall_side)
	bytes.encode_u8(64, gesture)
	bytes.encode_u8(65, gesture_phase)
	bytes.encode_u32(66, gesture_start)
	bytes.encode_float(70, animation.speed)
	bytes.encode_float(74, animation.duration)
	bytes.encode_float(78, animation.blend_time)
	for index: int in RunnerAnimation.LOCOMOTION.size():
		var weight: float = animation.locomotion[index] if with_locomotion else 0.0
		bytes.encode_float(82 + 4 * index, weight)
	bytes.encode_float(102, animation.locomotion_position.x)
	bytes.encode_float(106, animation.locomotion_position.y)
	bytes.encode_float(110, animation.jump_position)
	bytes.encode_float(114, animation.lowered)
	return bytes


## The snapshot `bytes` hold, or null when they are not one: the wrong size, a number that
## is not finite or out of its range, a clip, a side or a gesture that does not exist.
static func decode(bytes: PackedByteArray) -> RunnerSnapshot:
	if bytes.size() != SIZE:
		return null
	for offset: int in range(4, 60, 4) + range(70, SIZE, 4):
		var number: float = bytes.decode_float(offset)
		if not is_finite(number) or absf(number) > FARTHEST:
			return null
	var made: RunnerSnapshot = RunnerSnapshot.new()
	made.step = bytes.decode_u32(0)
	made.position = _vector_at(bytes, 4)
	made.velocity = _vector_at(bytes, 16)
	var rotation: Quaternion = Quaternion(
		bytes.decode_float(28),
		bytes.decode_float(32),
		bytes.decode_float(36),
		bytes.decode_float(40)
	)
	if absf(rotation.length() - 1.0) > ROTATION_SLACK:
		return null
	made.visual = Transform3D(Basis(rotation.normalized()), _vector_at(bytes, 44))
	made.capsule_height = bytes.decode_float(56)
	if made.capsule_height <= 0.0 or made.capsule_height > TALLEST:
		return null
	made.placement = bytes.decode_u8(60)
	var flags: int = bytes.decode_u8(61)
	var clip: int = bytes.decode_u8(62)
	var side: int = bytes.decode_u8(63)
	var gesture_kind: int = bytes.decode_u8(64)
	var phase: int = bytes.decode_u8(65)
	if clip >= RunnerAnimation.Clip.size() or side >= RunnerAnimation.WallSide.size():
		return null
	if gesture_kind != NO_GESTURE and gesture_kind >= Tag.Gesture.size():
		return null
	if phase >= Tag.Phase.size():
		return null
	made.caught = (flags & CAUGHT) != 0
	made.gesture = gesture_kind
	made.gesture_phase = phase as Tag.Phase
	made.gesture_start = bytes.decode_u32(66)
	var shown: RunnerAnimation = made.animation
	shown.clip = clip as RunnerAnimation.Clip
	shown.wall_side = side as RunnerAnimation.WallSide
	shown.aiming = (flags & AIMING) != 0
	shown.touching = (flags & TOUCHING) != 0
	shown.speed = bytes.decode_float(70)
	shown.duration = bytes.decode_float(74)
	shown.blend_time = bytes.decode_float(78)
	for number: float in [shown.speed, shown.duration, shown.blend_time]:
		if number < 0.0 or number > WIDEST:
			return null
	if (flags & WITH_LOCOMOTION) != 0:
		for index: int in RunnerAnimation.LOCOMOTION.size():
			var weight: float = bytes.decode_float(82 + 4 * index)
			if weight < 0.0 or weight > 1.0:
				return null
			shown.locomotion.append(weight)
	shown.locomotion_position = Vector2(bytes.decode_float(102), bytes.decode_float(106))
	shown.jump_position = bytes.decode_float(110)
	shown.lowered = bytes.decode_float(114)
	return made


## The runner between `from` (weight 0) and `to` (weight 1), both of it: the body and its
## visible body in between, the rest (its animation, its gesture) of the nearer one. Put
## somewhere between the two, it is not in between: it is at `from` until it is at `to`.
static func between(from: RunnerSnapshot, to: RunnerSnapshot, weight: float) -> RunnerSnapshot:
	if from.placement != to.placement:
		return to if weight >= 1.0 else from
	var nearer: RunnerSnapshot = from if weight < 0.5 else to
	var made: RunnerSnapshot = RunnerSnapshot.new()
	made.step = nearer.step
	made.position = from.position.lerp(to.position, weight)
	made.velocity = from.velocity.lerp(to.velocity, weight)
	made.capsule_height = nearer.capsule_height
	var rotation: Quaternion = from.visual.basis.get_rotation_quaternion().slerp(
		to.visual.basis.get_rotation_quaternion(), weight
	)
	made.visual = Transform3D(Basis(rotation), from.visual.origin.lerp(to.visual.origin, weight))
	made.placement = nearer.placement
	made.animation = nearer.animation
	made.gesture = nearer.gesture
	made.gesture_phase = nearer.gesture_phase
	made.gesture_start = nearer.gesture_start
	made.caught = nearer.caught
	return made


static func _put_vector(bytes: PackedByteArray, offset: int, vector: Vector3) -> void:
	bytes.encode_float(offset, vector.x)
	bytes.encode_float(offset + 4, vector.y)
	bytes.encode_float(offset + 8, vector.z)


static func _vector_at(bytes: PackedByteArray, offset: int) -> Vector3:
	return Vector3(
		bytes.decode_float(offset), bytes.decode_float(offset + 4), bytes.decode_float(offset + 8)
	)
