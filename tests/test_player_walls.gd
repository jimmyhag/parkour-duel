extends ReplayTest
## The walls the player layer reports to game/core, in the real physics: a wall a level
## excludes, or one that leans too far, gives no wall run, where a plain wall does. The
## runner is put in the air beside the wall, fast, pushing along it. Faster than real
## time with the same fixed step of 1/60 s (see ReplayTest).

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## The tuning the runner of that scene obeys.
const TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
## Long enough for a wall run to start, short enough for the runner to stay beside the
## middle of the wall.
const STEPS: int = 8
## The size of the walls: thickness, height, length.
const WALL_SIZE: Vector3 = Vector3(1.0, 10.0, 30.0)
## Where the runner is put, in the air.
const START: Vector3 = Vector3(0.0, 2.0, 0.0)
## Courses side by side, this far apart.
const ASIDE: float = 10.0
## A wall almost out of the reach of a wall run: this share of it.
const ALMOST_OUT_OF_REACH: float = 0.9
## Long enough for a whole wall run.
const WALL_RUN_STEPS: int = 90
## A bone this far behind the face of the wall is not behind it yet: the skeleton is
## measured between two fixed steps, its body placed at the last one.
const BEHIND_THE_WALL: float = 0.01
## The feet almost touch the wall: they come closer to it than this.
const FEW_CENTIMETRES: float = 0.1
## A clip made up for the rule of the pose: at each frame, the position across of its
## bones (positive at the runner's right): its left foot, its right foot, its head and a
## hand. Its feet go to the left, its head leans to the right; at its first frame, a hand
## is nearer the left than the feet.
const MADE_UP_CLIP: Array[Array] = [
	[-0.1, 0.1, 0.05, -0.3],
	[-0.4, -0.2, 0.15, -0.1],
	[-0.6, -0.3, 0.25, 0.2],
]
const MADE_UP_LEFT_FOOT: int = 0
const MADE_UP_RIGHT_FOOT: int = 1
const MADE_UP_HEAD: int = 2
## How far the made-up clip reaches to its left, at its farthest.
const MADE_UP_REACH: float = 0.6
## A made-up pose the runner comes from and goes into, a fall, its bones as in the made-up
## clip: its feet apart, its head upright, a hand out at its left, clear of a wall that
## touches the capsule.
const MADE_UP_FALL: PackedFloat32Array = [-0.15, 0.15, 0.0, -0.3]
## The shares of Wall Run a blend goes through.
const BLEND_SHARES: Array[float] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]


## One runner beside one wall, the wall at its left, or at its right.
class BesideAWall:
	extends Node3D

	var runner: Player
	var wall: StaticBody3D
	## A point of the face of the wall, and its normal.
	var face: Vector3
	var normal: Vector3
	## How many steps in a row the runner has run along the wall, up to its last step.
	var wall_run_steps: int = 0
	## The runner ran along the wall at some step.
	var did_run_along: bool = false
	## It ran along the wall from its very first step, its visible body still looking at
	## the wall.
	var ran_along_at_once: bool = false
	var _steps: int = 0

	## A wall whose face, at the height of the middle of the runner's body, stands
	## `gap` metres from its side (its left, or its right if `at_the_right`), leaning by
	## `tilt` degrees, `height` tall; and, if `ground` is finite, a floor that far under
	## the runner's feet.
	func _init(
		gap: float, tilt: float, height: float, ground: float, at_the_right: bool = false
	) -> void:
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		var tuning: MovementTuning = runner.tuning
		var middle: Vector3 = START + Vector3.UP * tuning.capsule_height / 2.0
		var away: Vector3 = Vector3.LEFT if at_the_right else Vector3.RIGHT
		normal = away.rotated(Vector3.FORWARD, deg_to_rad(tilt))
		face = middle - away * (tuning.capsule_radius + gap)
		var size: Vector3 = Vector3(WALL_SIZE.x, height, WALL_SIZE.z)
		wall = _block(size, face - normal * size.x / 2.0 + FORWARD * size.z / 2.0)
		wall.basis = Basis(Vector3.FORWARD, deg_to_rad(tilt))
		if is_finite(ground):
			var floor_size: Vector3 = Vector3(ASIDE, 1.0, WALL_SIZE.z)
			var under: Vector3 = START + Vector3.DOWN * (ground + floor_size.y / 2.0)
			_block(floor_size, under + FORWARD * floor_size.z / 2.0)
		runner.stepped.connect(_on_runner_stepped)

	func _block(size: Vector3, center: Vector3) -> StaticBody3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		var block: StaticBody3D = StaticBody3D.new()
		block.add_child(collider)
		block.position = center
		add_child(block)
		return block

	## The runner pushes `push` for `steps` steps, flying at the top speed `approach`
	## degrees off the wall's axis, towards the wall.
	func launch(push: Vector3 = FORWARD, approach: float = 0.0, steps: int = STEPS) -> void:
		runner.teleport(Transform3D(Basis.IDENTITY, global_position + START))
		# The visible body looks at the wall: what the runner observes must not depend on
		# it (decision 22).
		(runner.get_node("Visual") as Node3D).rotation.y = PI / 2.0
		var flight: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(approach))
		runner.velocity = flight * runner.tuning.top_speed
		runner.intent_source = ScriptedIntentSource.new().hold(push, false, steps)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		_steps += 1
		var along: bool = runner.motor.state == WALL_RUNNING
		wall_run_steps = wall_run_steps + 1 if along else 0
		ran_along_at_once = ran_along_at_once or (along and _steps == 1)
		did_run_along = did_run_along or along


## What a test measures of the visible body of a runner along a wall: at each step, how
## far the body leans and moves across; and at each final pose of the character, its
## bones against the face of the wall, all along the wall run for the nearest bone, and
## once the clip of the wall run has blended in for the others; after it, as the clip
## blends out, then in the fall alone, the nearest bone.
class BonesAlongTheWall:
	## The character shown; null with the capsule.
	var character: RunnerCharacter = null
	## The steps along the wall, and the poses of the character measured once blended in.
	var samples: int = 0
	var poses: int = 0
	## The most the visible body rolled, either way, in radians, and moved across from
	## the middle of the runner, in m.
	var leaned: float = 0.0
	var moved_across: float = 0.0
	## The nearest any bone came to the face of the wall (negative: behind it); once
	## blended in, the nearest a foot came to it, and how many times the head was no
	## farther from it than the nearest foot.
	var nearest_bone: float = INF
	var nearest_foot: float = INF
	var head_not_farther: int = 0
	## The poses measured as the clip of the wall run blends out, the nearest any bone came to
	## the wall then, and the nearest one came to it in the fall that follows, the clip gone.
	var leaving_poses: int = 0
	var nearest_leaving: float = INF
	var nearest_in_the_fall: float = INF
	## The sums of the distances of the head, the hips and the nearest foot to the wall.
	var _head: float = 0.0
	var _hips: float = 0.0
	var _foot: float = 0.0
	var _scene: BesideAWall
	var _skeleton: Skeleton3D = null
	var _feet: Array[int] = []
	## The steps of the wall run during the blend into its clip.
	var _blend_steps: int = 0

	func _init(scene: BesideAWall) -> void:
		_scene = scene
		var visual: Node3D = scene.runner.get_node("Visual") as Node3D
		for child: Node in visual.get_children():
			character = child as RunnerCharacter if child is RunnerCharacter else character
		scene.runner.stepped.connect(_on_runner_stepped)
		if character == null:
			return
		var found: Array[Node] = character.find_children("*", "Skeleton3D", true, false)
		_skeleton = found[0] as Skeleton3D
		for bone: int in _skeleton.get_bone_count():
			var name: String = _skeleton.get_bone_name(bone)
			if name.contains("Foot") or name.contains("Toe"):
				_feet.append(bone)
		var tuning: MovementTuning = scene.runner.tuning
		_blend_steps = ceili(tuning.animation_blend_time * ReplayTest.STEPS_PER_SECOND) + 1
		# The final pose, once the clips and the modifiers have moved the bones, after the
		# fixed steps of the frame: the body it is measured in is placed as it is shown.
		_skeleton.skeleton_updated.connect(_on_skeleton_updated)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		if _scene.runner.motor.state != WALL_RUNNING:
			return
		samples += 1
		var visual: Node3D = _scene.runner.get_node("Visual") as Node3D
		leaned = maxf(leaned, absf(visual.rotation.z))
		moved_across = maxf(moved_across, absf(visual.position.x))

	func _on_skeleton_updated() -> void:
		var nearest: float = INF
		var foot: float = INF
		for bone: int in _skeleton.get_bone_count():
			var distance: float = _to_the_wall(bone)
			nearest = minf(nearest, distance)
			if bone in _feet:
				foot = minf(foot, distance)
		if _scene.runner.motor.state != WALL_RUNNING:
			if character.wall_run_weight() > 0.0:
				leaving_poses += 1
				nearest_leaving = minf(nearest_leaving, nearest)
			elif _scene.did_run_along:
				nearest_in_the_fall = minf(nearest_in_the_fall, nearest)
			return
		nearest_bone = minf(nearest_bone, nearest)
		if _scene.wall_run_steps <= _blend_steps:
			return
		poses += 1
		var head: float = _to_the_wall(_skeleton.find_bone(RunnerCharacter.HEAD))
		nearest_foot = minf(nearest_foot, foot)
		head_not_farther += int(head <= foot)
		_head += head
		_hips += _to_the_wall(_skeleton.find_bone(RunnerCharacter.HIPS))
		_foot += foot

	## The distances measured, for the report of the test.
	func report(context: String) -> String:
		var form: String = (
			"%s: %d poses; mean distance to the wall: head %.3f m, hips %.3f m, "
			+ "nearest foot %.3f m; at the nearest: a foot %.3f m, a bone %.3f m"
		)
		var mean: float = maxf(poses, 1)
		return (
			form
			% [
				context,
				poses,
				_head / mean,
				_hips / mean,
				_foot / mean,
				nearest_foot,
				nearest_bone,
			]
		)

	## How far the bone `bone` is from the face of the wall, on the runner's side.
	func _to_the_wall(bone: int) -> float:
		var place: Vector3 = (
			_skeleton.global_transform * _skeleton.get_bone_global_pose(bone).origin
		)
		return (place - _scene.global_transform * _scene.face).dot(_scene.normal)


func test_an_excluded_wall_gives_no_wall_run() -> void:
	var gap: float = _close_to_the_side()
	var plain: BesideAWall = _beside_a_wall(gap, 0.0, 0)
	var excluded: BesideAWall = _beside_a_wall(gap, 0.0, 1)
	excluded.wall.add_to_group(Player.NO_WALL_RUN_GROUP)

	await _launch([plain, excluded])

	assert_true(plain.did_run_along, "a plain wall gives a wall run")
	assert_true(plain.ran_along_at_once, "at once, wherever the visible body looks")
	assert_false(excluded.did_run_along, "the same wall, excluded by its level, gives none")
	assert_lt(excluded.runner.velocity.y, 0.0, "the runner falls")


func test_a_wall_too_tilted_gives_no_wall_run() -> void:
	var gap: float = _close_to_the_side()
	var tolerated: float = (load(TUNING) as MovementTuning).wall_run_max_tilt
	var leaning: BesideAWall = _beside_a_wall(gap, tolerated / 2.0, 0)
	var too_tilted: BesideAWall = _beside_a_wall(gap, tolerated * 4.0 / 3.0, 1)

	await _launch([leaning, too_tilted])

	assert_true(leaning.did_run_along, "a wall leaning less than the tolerance gives a wall run")
	assert_false(too_tilted.did_run_along, "one leaning more gives none")
	assert_lt(too_tilted.runner.velocity.y, 0.0, "the runner falls")

	# What else the player measures of a wall and of the ground: a vertical wall too
	# short, or one beside a runner too close to the ground, gives none either.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var short: float = tuning.wall_run_min_wall_height * 3.0 / 4.0
	var too_short: BesideAWall = _beside_a_wall(gap, 0.0, 2, short)
	var too_low: BesideAWall = _beside_a_wall(
		gap, 0.0, 3, WALL_SIZE.y, tuning.wall_run_min_height / 2.0
	)
	await _launch([too_short, too_low])
	assert_false(too_short.did_run_along, "a wall too short gives none")
	assert_false(too_low.did_run_along, "nor a wall beside a runner too close to the ground")


func test_the_keyboard_diagonal_starts_a_wall_run() -> void:
	# Forward and the key towards the wall at the left, normalised as the keyboard gives
	# it, with the camera a few degrees off the wall's axis on either side; the runner
	# flies along the wall, or comes at it slightly.
	var diagonal: Vector3 = (FORWARD + Vector3.LEFT).normalized()
	var cameras: Array[float] = [-3.0, -1.0, 0.0, 1.0, 3.0]
	var approaches: Array[float] = [0.0, 20.0]
	var scenes: Array[BesideAWall] = []
	for approach: float in approaches:
		for camera: float in cameras:
			scenes.append(_beside_a_wall(_close_to_the_side(), 0.0, scenes.size()))
	for index: int in scenes.size():
		var camera: float = cameras[index % cameras.size()]
		var approach: float = approaches[index / cameras.size()]
		scenes[index].launch(diagonal.rotated(Vector3.UP, deg_to_rad(camera)), approach)
	for i: int in STEPS:
		await get_tree().physics_frame

	for index: int in scenes.size():
		var camera: float = cameras[index % cameras.size()]
		var approach: float = approaches[index / cameras.size()]
		var context: String = "camera %+.0f degrees, approach %.0f degrees" % [camera, approach]
		assert_true(scenes[index].did_run_along, context + ": a wall run")

	# In the core too, whatever the split of the tuning.
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	for split: float in [tuning.push_split_angle, tuning.push_split_angle * 2.0 / 3.0]:
		tuning.push_split_angle = split
		var body: MotorBody = MotorBody.new(tuning, START.y)
		body.velocity = FORWARD * tuning.top_speed
		body.set_wall(1, Vector3.RIGHT, _close_to_the_side(), WALL_SIZE.y)
		body.step(_intent(diagonal))
		assert_eq(body.motor.state, WALL_RUNNING, "split at %.0f degrees: a wall run" % split)


func test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away() -> void:
	# The rule, on the measures of clips given as they would be read from their bones:
	# with or without the Mixamo files.
	_assert_the_pose_rule_on_made_up_clips()

	# The character itself, along a wall at its left, then at its right, against it or as
	# far as a wall run allows: its bones measured against the wall. Without the files
	# (CI), the capsule shows the wall run as before.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var far: float = tuning.wall_run_distance * ALMOST_OUT_OF_REACH
	var gaps: Array[float] = [0.0, tuning.wall_run_distance / 2.0, far]
	var scenes: Array[BesideAWall] = []
	for at_the_right: bool in [false, true]:
		for gap: float in gaps:
			var scene: BesideAWall = BesideAWall.new(gap, 0.0, WALL_SIZE.y, INF, at_the_right)
			scene.position.x = scenes.size() * ASIDE
			add_child_autofree(scene)
			scenes.append(scene)
	var watches: Array[BonesAlongTheWall] = []
	for scene: BesideAWall in scenes:
		watches.append(BonesAlongTheWall.new(scene))
		scene.launch(FORWARD, 0.0, WALL_RUN_STEPS)
	while scenes[0].runner.motor.steps < WALL_RUN_STEPS:
		await get_tree().process_frame

	for index: int in scenes.size():
		var watch: BonesAlongTheWall = watches[index]
		var side: String = "right" if index >= gaps.size() else "left"
		var context: String = "a wall at its %s, %.2f m away" % [side, gaps[index % gaps.size()]]
		assert_gt(watch.samples, 0, context + ": it ran along the wall")
		if watch.character == null:
			_assert_the_capsule_leans(watch, tuning, context)
			continue
		gut.p(watch.report(context))
		assert_gt(watch.poses, 0, context + ": its poses measured")
		assert_almost_eq(watch.leaned, 0.0, 0.001, context + ": no lean, the clip leans")
		assert_eq(watch.head_not_farther, 0, context + ": the head farther than the feet")
		assert_gt(watch.nearest_bone, -BEHIND_THE_WALL, context + ": no bone behind the wall")
		assert_lt(watch.nearest_foot, FEW_CENTIMETRES, context + ": the feet a few cm from it")
		# Out of the wall run, the character slides back from the wall with its clip: no bone
		# behind it as the clip blends out, but where the fall that follows reaches by itself.
		gut.p(
			(
				"%s: %d poses blending out, a bone %.3f m from the wall; in the fall, %.3f m"
				% [context, watch.leaving_poses, watch.nearest_leaving, watch.nearest_in_the_fall]
			)
		)
		assert_gt(watch.leaving_poses, 0, context + ": its clip measured as it blends out")
		var fall: float = minf(watch.nearest_in_the_fall, 0.0)
		assert_gt(
			watch.nearest_leaving, fall - BEHIND_THE_WALL, context + ": no bone behind the wall"
		)


## The rule of the pose, on two made-up clips: one whose feet go to the runner's left as
## its head leans to its right, and its mirror. Their wall is found on the side of their
## feet. Along a wall at the left or at the right, at any distance a wall run allows, the
## clip shown, mirrored or not, moved across at each frame and put beside the wall, has
## its nearest bone a few centimetres from the wall, none behind it, and its head farther
## from it than its feet.
func _assert_the_pose_rule_on_made_up_clips() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var clips: Dictionary[RunnerAnimation.WallSide, Array] = {
		RunnerAnimation.WallSide.LEFT: [],
		RunnerAnimation.WallSide.RIGHT: [],
	}
	for frame: Array in MADE_UP_CLIP:
		clips[RunnerAnimation.WallSide.LEFT].append(PackedFloat32Array(frame))
		var mirrored: PackedFloat32Array = []
		for across: float in frame:
			mirrored.append(-across)
		clips[RunnerAnimation.WallSide.RIGHT].append(mirrored)
	var feet: PackedInt32Array = [MADE_UP_LEFT_FOOT, MADE_UP_RIGHT_FOOT]
	for side: RunnerAnimation.WallSide in clips:
		var frames: Array[PackedFloat32Array] = []
		frames.assign(clips[side])
		var clip: WallRunPose = WallRunPose.measure(frames, feet, MADE_UP_HEAD)
		assert_eq(clip.side, side, "the wall of a clip is on the side of its feet")
		assert_almost_eq(clip.reach, MADE_UP_REACH, 0.001, "as far as its bones go that way")
		assert_eq(clip.shifts.size(), frames.size(), "a shift at each frame")
		var clip_way: float = -1.0 if side == RunnerAnimation.WallSide.LEFT else 1.0
		for wall_side: RunnerAnimation.WallSide in clips:
			var wall_way: float = -1.0 if wall_side == RunnerAnimation.WallSide.LEFT else 1.0
			var mirror: float = -1.0 if clip.mirrors(wall_side) else 1.0
			for gap: float in [0.0, tuning.wall_run_distance / 2.0, tuning.wall_run_distance]:
				var offset: float = clip.offset(1.0, gap, tuning)
				var context: String = "clip %d, wall %d, %.2f m away" % [side, wall_side, gap]
				for index: int in frames.size():
					var to_the_wall: PackedFloat32Array = []
					for across: float in frames[index]:
						var shown: float = (across + clip_way * clip.shifts[index]) * mirror
						shown += wall_way * offset
						to_the_wall.append(tuning.capsule_radius + gap - wall_way * shown)
					var nearest: float = INF
					for distance: float in to_the_wall:
						nearest = minf(nearest, distance)
					var foot: float = minf(
						to_the_wall[MADE_UP_LEFT_FOOT], to_the_wall[MADE_UP_RIGHT_FOOT]
					)
					var gap_left: float = WallRunPose.WALL_GAP
					assert_almost_eq(nearest, gap_left, 0.001, context + ": the nearest bone")
					assert_gt(to_the_wall[MADE_UP_HEAD], foot, context + ": the head farther")
				_assert_the_blend_stays_clear(clip, wall_side, gap, tuning, frames)


## The made-up clip `clip` (its bones across at each frame `frames`), shown along a wall at
## `wall_side`, `gap` metres from the side of the capsule, blended in from the made-up
## fall, then out into it: at every share of the blend, the character moved across by its
## share of the offset (WallRunPose.shift_share), no bone goes behind the wall. Blends are
## of the positions of the bones, as for a short blend between two poses.
func _assert_the_blend_stays_clear(
	clip: WallRunPose,
	wall_side: RunnerAnimation.WallSide,
	gap: float,
	tuning: MovementTuning,
	frames: Array[PackedFloat32Array],
) -> void:
	var clip_way: float = WallRunPose.way(clip.side)
	var wall_way: float = WallRunPose.way(wall_side)
	var mirror: float = -1.0 if clip.mirrors(wall_side) else 1.0
	var offset: float = clip.offset(1.0, gap, tuning)
	for along: bool in [true, false]:
		var way: String = "in" if along else "out"
		for share: float in BLEND_SHARES:
			var moved: float = WallRunPose.shift_share(share, offset < 0.0, along) * offset
			for index: int in frames.size():
				var nearest: float = INF
				for bone: int in MADE_UP_FALL.size():
					var shown: float = (
						(frames[index][bone] + clip_way * clip.shifts[index]) * mirror
					)
					var blended: float = lerpf(MADE_UP_FALL[bone], shown, share)
					var across: float = blended + wall_way * moved
					nearest = minf(nearest, tuning.capsule_radius + gap - wall_way * across)
				var context: String = (
					"clip %d, wall %d, %.2f m away, %d%% blended %s"
					% [clip.side, wall_side, gap, share * 100, way]
				)
				assert_gt(nearest, -0.001, context + ": no bone behind the wall")


## The capsule, without the character: it leans towards the wall by its tuned angle and
## stays over the middle of the body.
func _assert_the_capsule_leans(
	watch: BonesAlongTheWall, tuning: MovementTuning, context: String
) -> void:
	var tuned: float = deg_to_rad(tuning.wall_run_lean)
	assert_almost_eq(watch.leaned, tuned, 0.01, context + ": the capsule leans as tuned")
	assert_almost_eq(watch.moved_across, 0.0, 0.001, context + ": over the middle of the body")


func _intent(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## A gap between the side of the runner and the face of the wall well within the reach
## of a wall run.
func _close_to_the_side() -> float:
	return (load(TUNING) as MovementTuning).wall_run_distance / 2.0


func _beside_a_wall(
	gap: float, tilt: float, place: int, height: float = WALL_SIZE.y, ground: float = INF
) -> BesideAWall:
	var scene: BesideAWall = BesideAWall.new(gap, tilt, height, ground)
	scene.position.x = place * ASIDE
	add_child_autofree(scene)
	return scene


func _launch(scenes: Array[BesideAWall]) -> void:
	for scene: BesideAWall in scenes:
		scene.launch()
	for i: int in STEPS:
		await get_tree().physics_frame
