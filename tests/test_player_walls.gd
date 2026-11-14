extends ReplayTest
## The walls the player layer reports to game/core, in the real physics: a wall a level
## excludes, or one that leans too far, gives no wall run, where a plain wall does; and how
## the body one sees lies against the wall it runs along (docs/specs/animation-polish.md):
## rolled, its feet brushing the wall, at a fixed offset. The runner is put in the air
## beside the wall, fast, pushing along it. Faster than real time with the same fixed step
## of 1/60 s (see ReplayTest).

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
## A made-up run, as the character's bones would give it, in the frame of the body (across,
## positive at its right, and up from its feet, in m): MADE_UP_BONES places a frame, its
## left foot, its right foot, its head, its left hand, its right hand and its hips. Its feet
## swing apart and lift in turn; its hands swing out as far as its feet.
const MADE_UP_RUN: PackedVector2Array = [
	Vector2(-0.12, 0.05),
	Vector2(0.12, 0.30),
	Vector2(0.0, 1.65),
	Vector2(-0.30, 1.0),
	Vector2(0.25, 1.1),
	Vector2(0.0, 0.95),
	Vector2(-0.10, 0.20),
	Vector2(0.15, 0.04),
	Vector2(0.02, 1.62),
	Vector2(-0.25, 1.1),
	Vector2(0.30, 1.0),
	Vector2(0.01, 0.93),
	Vector2(-0.16, 0.0),
	Vector2(0.08, 0.15),
	Vector2(-0.02, 1.66),
	Vector2(-0.35, 0.95),
	Vector2(0.2, 1.05),
	Vector2(-0.01, 0.96),
]
const MADE_UP_BONES: int = 6
const MADE_UP_LEFT_FOOT: int = 0
const MADE_UP_RIGHT_FOOT: int = 1
const MADE_UP_HEAD: int = 2
## The shares of the roll a wall run goes through as it starts and as it ends.
const ROLL_SHARES: Array[float] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
## Of a place that should not move from one step to the next, how far it may move, in m.
const FIXED: float = 0.001


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
## far the body rolls and moves across; and at each final pose of the character, its
## bones against the face of the wall, all along the wall run for the nearest bone, and
## once the body has rolled for the others; after it, as the body rolls back, then in the
## fall alone, the nearest bone. Once the body has rolled, how far across it is moved, and
## where its hips are in it, at each step.
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
	## The poses measured as the body rolls back, the nearest any bone came to the wall then,
	## and the nearest one came to it in the fall that follows, the body upright.
	var leaving_poses: int = 0
	var nearest_leaving: float = INF
	var nearest_in_the_fall: float = INF
	## Once the body has rolled: how far across the visible body is moved, at each step, and
	## where the hips of the character are across in it, at each pose.
	var across: Array[float] = []
	var hips_across: Array[float] = []
	## The weights of the run the runner showed along the wall, at its last step there.
	var locomotion: PackedFloat32Array = []
	## The sums of the distances of the head, the hips and the nearest foot to the wall.
	var _head: float = 0.0
	var _hips: float = 0.0
	var _foot: float = 0.0
	var _scene: BesideAWall
	var _skeleton: Skeleton3D = null
	var _feet: Array[int] = []
	## The steps of the wall run while the body rolls.
	var _roll_steps: int = 0

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
		_roll_steps = ceili(tuning.wall_run_roll_time * ReplayTest.STEPS_PER_SECOND) + 1
		# The final pose, once the clips and the modifiers have moved the bones: here at every
		# fixed step, faster than real time, so that the whole stride is seen; the body it is
		# measured in is placed as it is at that step.
		var tree: AnimationTree = (
			character.find_children("*", "AnimationTree", true, false)[0] as AnimationTree
		)
		tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
		_skeleton.modifier_callback_mode_process = (
			Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
		)
		_skeleton.skeleton_updated.connect(_on_skeleton_updated)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		if _scene.runner.motor.state != WALL_RUNNING:
			return
		samples += 1
		var visual: Node3D = _scene.runner.get_node("Visual") as Node3D
		leaned = maxf(leaned, absf(visual.rotation.z))
		moved_across = maxf(moved_across, absf(visual.position.x))
		locomotion = _scene.runner.animation.locomotion
		if _scene.wall_run_steps > _roll_steps:
			across.append(visual.position.dot(_scene.normal))

	func _on_skeleton_updated() -> void:
		var nearest: float = INF
		var foot: float = INF
		for bone: int in _skeleton.get_bone_count():
			var distance: float = _to_the_wall(bone)
			nearest = minf(nearest, distance)
			if bone in _feet:
				foot = minf(foot, distance)
		var visual: Node3D = _scene.runner.get_node("Visual") as Node3D
		if _scene.runner.motor.state != WALL_RUNNING:
			if absf(visual.rotation.z) > 0.0001:
				leaving_poses += 1
				nearest_leaving = minf(nearest_leaving, nearest)
			elif _scene.did_run_along:
				nearest_in_the_fall = minf(nearest_in_the_fall, nearest)
			return
		nearest_bone = minf(nearest_bone, nearest)
		if _scene.wall_run_steps <= _roll_steps:
			return
		poses += 1
		var hips: Vector3 = (
			_skeleton.global_transform
			* _skeleton.get_bone_global_pose(_skeleton.find_bone(RunnerCharacter.HIPS)).origin
		)
		hips_across.append((visual.global_transform.affine_inverse() * hips).x)
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
		var rolled: float = deg_to_rad(tuning.wall_run_body_roll)
		assert_almost_eq(watch.leaned, rolled, 0.001, context + ": the whole body rolled")
		assert_eq(watch.head_not_farther, 0, context + ": the head farther than the feet")
		assert_gt(watch.nearest_bone, -BEHIND_THE_WALL, context + ": no bone behind the wall")
		assert_lt(watch.nearest_foot, FEW_CENTIMETRES, context + ": the feet a few cm from it")
		# Out of the wall run, the character rolls back upright, away from the wall: no bone
		# behind it as it rolls, but where the fall that follows reaches by itself.
		gut.p(
			(
				"%s: %d poses rolling back, a bone %.3f m from the wall; in the fall, %.3f m"
				% [context, watch.leaving_poses, watch.nearest_leaving, watch.nearest_in_the_fall]
			)
		)
		assert_gt(watch.leaving_poses, 0, context + ": measured as it rolls back")
		var fall: float = minf(watch.nearest_in_the_fall, 0.0)
		assert_gt(
			watch.nearest_leaving, fall - BEHIND_THE_WALL, context + ": no bone behind the wall"
		)


func test_the_wall_run_offset_is_fixed() -> void:
	# Along a wall at its left, then at its right, at a distance a wall run keeps: once the
	# body has rolled, the visible body is moved across by one offset, step after step, and
	# the character's hips stay where they are in it: no sway from one key to the next.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var gap: float = tuning.wall_run_distance / 2.0
	var scenes: Array[BesideAWall] = []
	var watches: Array[BonesAlongTheWall] = []
	for at_the_right: bool in [false, true]:
		var scene: BesideAWall = BesideAWall.new(gap, 0.0, WALL_SIZE.y, INF, at_the_right)
		scene.position.x = scenes.size() * ASIDE
		add_child_autofree(scene)
		scenes.append(scene)
		watches.append(BonesAlongTheWall.new(scene))
		scene.launch(FORWARD, 0.0, WALL_RUN_STEPS)
	while scenes[0].runner.motor.steps < WALL_RUN_STEPS:
		await get_tree().process_frame

	for index: int in scenes.size():
		var watch: BonesAlongTheWall = watches[index]
		var context: String = "a wall at its %s" % ("right" if index == 1 else "left")
		assert_gt(watch.across.size(), 1, context + ": steps along the wall, the body rolled")
		_assert_fixed(watch.across, context + ": the visible body moved across")
		if watch.character == null:
			assert_almost_eq(watch.across[0], 0.0, FIXED, context + ": the capsule stays")
			continue
		# The runner faces -Z along the wall: the frame of its body is the scene's.
		var rolled: float = deg_to_rad(tuning.wall_run_body_roll) * (1.0 if index == 1 else -1.0)
		var run: PackedFloat32Array = watch.locomotion
		var placed: Transform3D = watch.character.placed_against_the_wall(rolled, gap, run)
		var offset: float = placed.origin.dot(scenes[index].normal)
		gut.p("%s: the body moved %.3f m away from the wall" % [context, watch.across[0]])
		assert_almost_eq(watch.across[0], offset, FIXED, context + ": by the offset of its pose")
		assert_gt(watch.hips_across.size(), 1, context + ": its hips measured")
		_assert_fixed(watch.hips_across, context + ": the hips in the body")


func test_the_feet_brush_the_wall_and_the_head_moves_away() -> void:
	# A made-up run, its body rolled along a wall at its left, then at its right, against
	# it, or as far as a wall run allows: its feet a few centimetres from the wall, its
	# head farther, and no point of it behind the wall.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var runs: Array[PackedVector2Array] = [MADE_UP_RUN]
	var pose: WallRunPose = WallRunPose.measure(runs)
	var weights: PackedFloat32Array = [1.0]
	var full: float = deg_to_rad(tuning.wall_run_body_roll)
	for way: float in [-1.0, 1.0]:
		for gap: float in [0.0, tuning.wall_run_distance / 2.0, tuning.wall_run_distance]:
			var side: String = "left" if way < 0.0 else "right"
			var context: String = "a wall at its %s, %.2f m away" % [side, gap]
			var nearest: float = INF
			var nearest_foot: float = INF
			var placed: Transform3D = pose.placed(way * full, gap, weights, tuning)
			for frame: PackedVector2Array in _made_up_frames():
				var to_the_wall: Array[float] = _to_the_wall(placed, frame, way, gap, tuning)
				for distance: float in to_the_wall:
					nearest = minf(nearest, distance)
				var foot: float = minf(
					to_the_wall[MADE_UP_LEFT_FOOT], to_the_wall[MADE_UP_RIGHT_FOOT]
				)
				nearest_foot = minf(nearest_foot, foot)
				assert_gt(to_the_wall[MADE_UP_HEAD], foot + 0.3, context + ": the head farther")
			assert_almost_eq(nearest, WallRunPose.WALL_GAP, 0.001, context + ": the nearest point")
			assert_almost_eq(nearest_foot, nearest, 0.001, context + ": a foot, nearest")
			assert_lt(nearest_foot, FEW_CENTIMETRES, context + ": the feet a few cm from it")
			# As the roll comes and goes, the body moves across with it: no point behind the
			# wall but where the upright body already reaches.
			var upright: float = INF
			for frame: PackedVector2Array in _made_up_frames():
				for distance: float in _to_the_wall(Transform3D(), frame, way, gap, tuning):
					upright = minf(upright, distance)
			for share: float in ROLL_SHARES:
				var rolling: Transform3D = pose.placed(way * full * share, gap, weights, tuning)
				var least: float = INF
				for frame: PackedVector2Array in _made_up_frames():
					for distance: float in _to_the_wall(rolling, frame, way, gap, tuning):
						least = minf(least, distance)
				var rolled: String = "%s, %d%% rolled" % [context, share * 100]
				assert_gt(least, minf(upright, 0.0) - 0.001, rolled + ": none behind the wall")


## The frames of the made-up run, each one its places.
func _made_up_frames() -> Array[PackedVector2Array]:
	var frames: Array[PackedVector2Array] = []
	for first: int in range(0, MADE_UP_RUN.size(), MADE_UP_BONES):
		frames.append(MADE_UP_RUN.slice(first, first + MADE_UP_BONES))
	return frames


## How far each place of `frame` is from the face of a wall at the runner's side `way` (-1
## its left, 1 its right), `gap` m from the side of its capsule, the body placed by
## `placed` (negative: behind the wall).
func _to_the_wall(
	placed: Transform3D,
	frame: PackedVector2Array,
	way: float,
	gap: float,
	tuning: MovementTuning,
) -> Array[float]:
	var distances: Array[float] = []
	for place: Vector2 in frame:
		var shown: Vector3 = placed * Vector3(place.x, place.y, 0.0)
		distances.append(tuning.capsule_radius + gap - way * shown.x)
	return distances


## The values of `values` are all the same, give or take FIXED.
func _assert_fixed(values: Array[float], context: String) -> void:
	var least: float = INF
	var most: float = -INF
	for value: float in values:
		least = minf(least, value)
		most = maxf(most, value)
	assert_lt(most - least, FIXED, "%s: %.4f to %.4f, fixed" % [context, least, most])


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
