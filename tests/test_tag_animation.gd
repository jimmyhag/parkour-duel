extends GutTest
## How the catch of a chase is seen (docs/specs/chase-tag-polish.md), without a scene: the
## animation of a dive missed (the dive to the ground, lying, the getting up from the hands)
## and of a touch missed (the stumble), chosen from the motor of a runner without a scene
## (MotorBody), each clip at no more than the pace the tuning allows it; with the Mixamo files, the
## parts of the clips measured on their bones; and the camera that goes down with the body and
## back up. With the game's tuning; the runners go along -Z.

const FORWARD: Vector3 = Vector3.FORWARD
const STEP: float = MotorBody.STEP
## More steps than a dive and its time down last.
const MANY_STEPS: int = 600
## The tuning of the game.
const TUNING: String = "res://game/core/movement_tuning.tres"
## Measured on the bones of the files, as a share of the height of the hips at rest: lying
## on the ground, the hips lower than this; the hands on it, lower than this; on all fours,
## the hips higher than this. Up again, the hips higher than this share of their mean height
## in the run, sampled this many times: 0.84, as the amendment of decision 1 says (Getting
## Up stands at 0.89 to 0.90 of the run, and the blend into the run finishes it).
const LYING_SHARE: float = 0.3
const HANDS_DOWN_SHARE: float = 0.3
const ALL_FOURS_SHARE: float = 0.6
const STANDING_SHARE: float = 0.84
const RUN_SAMPLES: int = 30
## Frames shown at every fixed step, and how near the lowest height the camera comes, as a
## share of how far down it goes.
const FRAMES_PER_STEP: int = 3
const CAMERA_NEAR_SHARE: float = 0.1
## Two made-up parts of a clip, their lengths, in s, and their bones; samples read across
## the bridge, and the steepest an eased bridge goes, as a share of its even pace.
const FIRST_LENGTH: float = 0.5
const SECOND_LENGTH: float = 0.4
const TURNED_BONE: String = "Skeleton3D:turned"
const HELD_BONE: String = "Skeleton3D:held"
const BRIDGE_SAMPLES: int = 20
const EASED_SLOPE: float = 1.6


func test_a_missed_dive_is_seen_whole() -> void:
	# docs/specs/chase-tag-polish.md, decision 1 as amended: with the game's tuning, the dive
	# to the contact of the ground, lying down for at least the tuned time, then the getting
	# up from the push of the hands; the dive at no more than 1.25 times its pace, the getting
	# up at no more than 2, and 1.6 s down at most.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var most: float = 1.25
	assert_almost_eq(tuning.animation_max_pace, most, 0.0001, "the cap of the project: 1.25")
	var getting_up_most: float = tuning.tag_getup_max_pace
	assert_lte(getting_up_most, 2.0 + 0.0001, "the getting up: 2 times its pace at most")
	assert_gt(tuning.tag_down_lying, 0.0, "a time lying down")
	assert_lte(tuning.tag_dive_recovery, 1.6 + 0.0001, "1.6 s down at most")
	var cat: MotorBody = _running_at(tuning.top_speed, tuning)
	cat.motor.can_tag = true
	var dive: MoveIntent = _push(FORWARD)
	dive.dive_pressed = true
	cat.step(dive)
	assert_eq(cat.motor.state, RunnerMotor.State.DIVING, "a dive")
	var shown: Array[RunnerAnimation] = []
	var animation: RunnerAnimation = null
	for step: int in MANY_STEPS:
		animation = RunnerAnimation.of(cat.motor, STEP, animation)
		if (
			cat.motor.state != RunnerMotor.State.DIVING
			and cat.motor.state != RunnerMotor.State.DOWN
		):
			break
		shown.append(animation)
		cat.step(_push(FORWARD))
	var diving: int = 0
	var lying: int = 0
	var getting_up: int = 0
	for seen: RunnerAnimation in shown:
		if seen.clip == RunnerAnimation.Clip.DIVE:
			assert_eq(lying + getting_up, 0, "the dive first")
			diving += 1
			var pace: float = _played_pace(seen)
			assert_almost_eq(seen.duration, tuning.tag_dive_time, 0.0001, "the dive in its time")
			assert_between(pace, 1.0, most + 0.0001, "the dive: %.2f times its pace" % pace)
			continue
		assert_eq(seen.clip, RunnerAnimation.Clip.GETTING_UP, "then down, the getting up")
		if seen.duration <= 0.0:
			assert_eq(getting_up, 0, "lying, before the getting up")
			assert_eq(seen.speed, 0.0, "lying: held at its first pose")
			lying += 1
			continue
		getting_up += 1
		var played: float = _played_pace(seen)
		var context: String = "the getting up: %.2f times its pace" % played
		assert_between(played, 1.0, getting_up_most + 0.0001, context)
	assert_eq(diving, roundi(tuning.tag_dive_time / STEP), "the dive lasts its time")
	assert_gte(lying * STEP, tuning.tag_down_lying - 0.0001, "lying down the tuned time at least")
	var down: int = roundi(tuning.tag_dive_recovery / STEP)
	assert_eq(lying + getting_up, down, "then it gets up for the rest of its time down")
	assert_almost_eq(
		getting_up * STEP, tuning.tag_dive_recovery - tuning.tag_down_lying, 0.0001, "in its time"
	)
	assert_has(RunnerAnimation.LOCOMOTION, animation.clip, "then the run")
	# Measured on the bones of the files, when they are there: the dive ends with its hands on
	# the ground; the getting up starts lying, the hands under the shoulders, plays the push
	# of the hands whole, to all fours, is cut only between close poses, and ends up again.
	var character: RunnerCharacter = RunnerCharacter.create(RunnerCharacter.MODEL, tuning)
	if character == null:
		pass_test("without the Mixamo files, the parts of the clips are not measured")
		return
	add_child_autofree(character)
	var skeleton: Skeleton3D = (
		character.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	)
	var tree: AnimationTree = (
		character.find_children("*", "AnimationTree", true, false)[0] as AnimationTree
	)
	var library: AnimationLibrary = tree.get_animation_library(RunnerCharacter.LIBRARY)
	var hips: int = skeleton.find_bone(RunnerCharacter.HIPS)
	var head: int = skeleton.find_bone(RunnerCharacter.HEAD)
	var hands: Array[int] = [
		skeleton.find_bone(RunnerCharacter.LEFT_HAND),
		skeleton.find_bone(RunnerCharacter.RIGHT_HAND)
	]
	var standing: float = skeleton.get_bone_rest(hips).origin.y
	var landed: PackedVector3Array = MixamoClip.bone_places(
		library.get_animation("dive"),
		RunnerCharacter.played_length(RunnerAnimation.Clip.DIVE),
		skeleton
	)
	for hand: int in hands:
		gut.p("the dive ends with a hand %.2f high" % landed[hand].y)
		assert_lt(landed[hand].y, standing * HANDS_DOWN_SHARE, "the dive ends on its hands")
	var made_up: Animation = library.get_animation("getting_up")
	var first: PackedVector3Array = MixamoClip.bone_places(made_up, 0.0, skeleton)
	gut.p("the getting up starts with the hips %.2f high" % first[hips].y)
	assert_lt(first[hips].y, standing * LYING_SHARE, "it starts lying on the ground")
	for hand: int in hands:
		assert_lt(first[hand].y, standing * HANDS_DOWN_SHARE, "its hands on the ground")
		assert_lt(
			absf(first[hand].z - first[hips].z),
			absf(first[head].z - first[hips].z),
			"under its shoulders, nearer the hips than the head is"
		)
	var cut: Vector2 = RunnerCharacter.CUTS[RunnerAnimation.Clip.GETTING_UP]
	var left: PackedVector3Array = MixamoClip.bone_places(made_up, cut.y - cut.x, skeleton)
	var taken: PackedVector3Array = MixamoClip.bone_places(
		made_up, cut.y - cut.x + RunnerCharacter.BRIDGE, skeleton
	)
	gut.p("the push of the hands ends with the hips %.2f high" % left[hips].y)
	assert_gt(left[hips].y, standing * ALL_FOURS_SHARE, "the push played whole, to all fours")
	for bone: int in [hips, hands[0], hands[1]]:
		var apart: float = left[bone].distance_to(taken[bone])
		gut.p("cut out: %s %.3f m apart" % [skeleton.get_bone_name(bone), apart])
		assert_lt(apart, RunnerCharacter.MOST_APART, "cut out only between close poses")
	var running: Animation = library.get_animation("running")
	var run_hips: float = 0.0
	for sample: int in RUN_SAMPLES:
		var at: float = running.length * sample / RUN_SAMPLES
		run_hips += MixamoClip.bone_places(running, at, skeleton)[hips].y / RUN_SAMPLES
	var last: PackedVector3Array = MixamoClip.bone_places(
		made_up, RunnerCharacter.played_length(RunnerAnimation.Clip.GETTING_UP), skeleton
	)
	var share: float = last[hips].y / run_hips
	gut.p("it ends with the hips %.2f high, %.0f %% of the run" % [last[hips].y, share * 100.0])
	assert_gt(share, STANDING_SHARE, "and ends up again")


func test_a_missed_touch_stumbles() -> void:
	# docs/specs/chase-tag-polish.md, decision 2: after the arm stretched, the whole body
	# stumbles for the time a touch missed costs, at no more than 1.25 times its pace, then
	# runs again, blended.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var most: float = 1.25
	var cat: MotorBody = _running_at(tuning.top_speed, tuning)
	cat.motor.can_tag = true
	var touch: MoveIntent = _push(FORWARD)
	touch.touch_pressed = true
	cat.step(touch)
	var animation: RunnerAnimation = RunnerAnimation.of(cat.motor, STEP)
	assert_true(animation.touching, "the arm stretched")
	var phases: Array[String] = []
	for step: int in MANY_STEPS:
		cat.step(_push(FORWARD))
		var before: RunnerAnimation = animation
		animation = RunnerAnimation.of(cat.motor, STEP, before)
		var phase: String = "reaching"
		if animation.clip == RunnerAnimation.Clip.STUMBLE:
			phase = "stumbling"
			assert_eq(cat.motor.tag.phase, Tag.Phase.RECOVERING, "while its touch costs")
			assert_false(animation.touching, "the arm no longer stretched")
			assert_almost_eq(animation.duration, tuning.tag_touch_recovery, 0.0001, "its time")
			var pace: float = _played_pace(animation)
			assert_between(pace, 1.0, most + 0.0001, "%.2f times its pace" % pace)
			if before.clip != RunnerAnimation.Clip.STUMBLE:
				assert_gt(animation.blend_time, 0.0, "blended in after the arm: no jump")
		elif not animation.touching:
			phase = "running"
			assert_has(RunnerAnimation.LOCOMOTION, animation.clip, "the run")
			if before.clip == RunnerAnimation.Clip.STUMBLE:
				assert_gt(animation.blend_time, 0.0, "blended back into the run")
		if phases.is_empty() or phases[-1] != phase:
			phases.append(phase)
		if phase == "running" and cat.motor.tag.is_over():
			break
	assert_eq(phases, ["reaching", "stumbling", "running"] as Array[String], "in that order")


func test_the_camera_follows_the_cat_on_the_ground() -> void:
	# docs/specs/chase-tag-polish.md, decision 4: from the dive to the end of the getting up,
	# the camera goes down with the body and back up, smoothed: frames shown more often than
	# fixed steps, and never a jump from one to the next.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var standing: float = tuning.camera_look_height
	var lying: float = tuning.tag_camera_down_height
	assert_lt(lying, standing, "lower on the ground")
	assert_gt(tuning.tag_camera_follow, 0.0, "smoothed")
	var cat: MotorBody = _running_at(tuning.top_speed, tuning)
	cat.motor.can_tag = true
	var dive: MoveIntent = _push(FORWARD)
	dive.dive_pressed = true
	cat.step(dive)
	var animation: RunnerAnimation = null
	var height: float = standing
	var heights: Array[float] = []
	var lowest_state: RunnerMotor.State = RunnerMotor.State.GROUNDED
	var lowest: float = INF
	var frame: float = STEP / FRAMES_PER_STEP
	for step: int in MANY_STEPS:
		animation = RunnerAnimation.of(cat.motor, STEP, animation)
		var wanted: float = CameraRig.look_height(animation.lowered, tuning)
		for shown: int in FRAMES_PER_STEP:
			height = CameraRig.followed_height(height, wanted, frame, tuning.tag_camera_follow)
			heights.append(height)
		if height < lowest:
			lowest = height
			lowest_state = cat.motor.state
		cat.step(_push(FORWARD))
	var span: float = standing - lying
	assert_lt(lowest, lying + span * CAMERA_NEAR_SHARE, "down with the body")
	assert_eq(lowest_state, RunnerMotor.State.DOWN, "lowest on the ground")
	assert_almost_eq(heights[-1], standing, 0.001, "back up once it runs again")
	var most: float = span * frame / tuning.tag_camera_follow + 0.0001
	for index: int in range(1, heights.size()):
		var moved: float = absf(heights[index] - heights[index - 1])
		assert_lte(moved, most, "frame %d: without a jump" % index)


## How fast the clip of `animation` plays as the character plays it: the whole part kept
## of it (RunnerCharacter.played_length) in its duration.
func _played_pace(animation: RunnerAnimation) -> float:
	return RunnerCharacter.played_length(animation.clip) / animation.duration


func test_two_parts_of_a_clip_follow_each_other() -> void:
	# MixamoClip.chained, on made-up parts (the files are not in the CI): its length is both
	# parts and the bridge; across the bridge a bone goes from where the first part leaves it
	# to where the second takes it, without a jump at either end; a bone the second part does
	# not move stays where the first left it.
	var turned: Quaternion = Quaternion(Vector3.RIGHT, PI / 2.0)
	var half: Quaternion = Quaternion(Vector3.RIGHT, PI / 4.0)
	var first: Animation = _made_up_part(FIRST_LENGTH, Quaternion.IDENTITY, turned, true)
	var second: Animation = _made_up_part(SECOND_LENGTH, half, Quaternion.IDENTITY, false)
	var bridge: float = RunnerCharacter.BRIDGE

	var made: Animation = MixamoClip.chained(first, second, bridge)
	assert_almost_eq(made.length, FIRST_LENGTH + bridge + SECOND_LENGTH, 0.0001, "its length")
	var turning: int = made.find_track(NodePath(TURNED_BONE), Animation.TYPE_ROTATION_3D)
	var moving: int = made.find_track(NodePath(HELD_BONE), Animation.TYPE_POSITION_3D)
	assert_gte(turning, 0, "the bone both parts turn")
	assert_gte(moving, 0, "the bone only the first part moves")
	var left: Quaternion = made.rotation_track_interpolate(turning, FIRST_LENGTH)
	var taken: Quaternion = made.rotation_track_interpolate(turning, FIRST_LENGTH + bridge)
	assert_almost_eq(left.angle_to(turned), 0.0, 0.001, "the bridge starts where the first ends")
	assert_almost_eq(taken.angle_to(half), 0.0, 0.001, "and ends where the second starts")
	var across: float = turned.angle_to(half)
	var before: Quaternion = left
	var most: float = 0.0
	for sample: int in range(1, BRIDGE_SAMPLES + 1):
		var at: float = FIRST_LENGTH + bridge * sample / BRIDGE_SAMPLES
		var now: Quaternion = made.rotation_track_interpolate(turning, at)
		most = maxf(most, before.angle_to(now))
		assert_lte(now.angle_to(turned), across + 0.001, "between the two poses")
		assert_lte(now.angle_to(half), across + 0.001, "between the two poses")
		before = now
	assert_lt(most, across * EASED_SLOPE / BRIDGE_SAMPLES + 0.001, "without a jump")
	var first_moving: int = first.find_track(NodePath(HELD_BONE), Animation.TYPE_POSITION_3D)
	var held: Vector3 = first.position_track_interpolate(first_moving, FIRST_LENGTH)
	for at: float in [FIRST_LENGTH, FIRST_LENGTH + bridge / 2.0, made.length]:
		var place: Vector3 = made.position_track_interpolate(moving, at)
		assert_almost_eq(place.distance_to(held), 0.0, 0.0001, "held at %.3f s" % at)


## A body on the floor that runs at `speed` along -Z with `tuning`, as it starts its next
## step.
func _running_at(speed: float, tuning: MovementTuning) -> MotorBody:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, speed)
	body.step(_push(FORWARD * minf(speed / tuning.top_speed, 1.0)))
	return body


func _push(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## A part of a made-up clip, `length` s long, keyed at every frame: TURNED_BONE turns from
## `from` to `to`; and, if `moves`, HELD_BONE goes up by one metre.
func _made_up_part(length: float, from: Quaternion, to: Quaternion, moves: bool) -> Animation:
	var part: Animation = Animation.new()
	part.length = length
	var turning: int = part.add_track(Animation.TYPE_ROTATION_3D)
	part.track_set_path(turning, NodePath(TURNED_BONE))
	var moving: int = -1
	if moves:
		moving = part.add_track(Animation.TYPE_POSITION_3D)
		part.track_set_path(moving, NodePath(HELD_BONE))
	var frames: int = roundi(length * RunnerCharacter.FRAMES_PER_SECOND)
	for frame: int in frames + 1:
		var share: float = float(frame) / frames
		var at: float = frame / RunnerCharacter.FRAMES_PER_SECOND
		part.rotation_track_insert_key(turning, at, from.slerp(to, share))
		if moving >= 0:
			part.position_track_insert_key(moving, at, Vector3.UP * share)
	return part
