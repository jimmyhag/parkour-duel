extends GutTest
## The body one sees, frame by frame, on a display faster than the fixed steps
## (docs/specs/animation-polish.md, decision 2): the visible body of a runner, and the
## ghost of a duel, are placed between two fixed steps; the bones of the character, when
## its files are there, move at every frame. And the clips that loop pass their seam
## without slowing down (decision 8). In real time: the display at 144 frames a second, the
## fixed step at 1/60 s of the game's time, the game's time slowed down while the frames
## are followed, so that a fixed step comes every few frames on any machine.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const GHOST_SCENE: PackedScene = preload("res://game/player/ghost.tscn")
const DISPLAY_RATE: int = 144
## The runner gets under way faster than real time, as in ReplayTest; then, while the
## frames are followed, the game's time goes this many times slower than real time: a fixed
## step every 144 / (60 * 0.25), about 10, frames; still one in two on a machine that shows
## only 30 frames a second.
const STEPS_PER_SECOND: int = 60
const SPEED_UP: float = 10.0
const SLOW_DOWN: float = 0.25
## How many steps the runner runs before the frames are followed, how many frames it takes
## the display to settle at the slowed time, and how many frames are followed.
const SETTLE_STEPS: int = 30
const SETTLE_FRAMES: int = 4
const FRAMES: int = 60
## The runner runs around: its push turns this much at each step, in radians.
const TURN: float = 0.04
## More steps than the runner runs here.
const RUN_STEPS: int = 120
## How far beside the runner the ghost goes, in m.
const ASIDE: Vector3 = Vector3(6.0, 0.0, 0.0)
## A move smaller than this, in m (in the units of the skeleton for a bone), from one frame
## to the next, is none; and a turn that moves the way the body faces less than this.
const NO_MOVE: float = 0.000001
## A made-up loop, as a file gives it: a bone swinging to and fro, one cycle in this many s,
## keyed at 30 frames a second on straight lines, its last key at its end, the same as its
## first; and how far it swings, in radians.
const LOOP_LENGTH: float = 0.8
const SWING: float = 0.6
## A loop is read this many times a second around one of its keys, this many times on
## either side; around its seam, and around this many keys spread over it.
const READS_PER_SECOND: float = 240.0
const READS: int = 3
const KEYS_READ: int = 24
## Across its seam, a loop turns its bones, against straight lines between its keys, at
## least this share of what it does across its other keys.
const SEAM_SHARE: float = 0.8

var _max_fps_before: int = 0
var _ticks_before: int = 0
var _time_scale_before: float = 1.0
var _ghost: Ghost = null
var _runner: Player = null


func before_all() -> void:
	_max_fps_before = Engine.max_fps
	_ticks_before = Engine.physics_ticks_per_second
	_time_scale_before = Engine.time_scale
	Engine.max_fps = DISPLAY_RATE


func after_all() -> void:
	Engine.max_fps = _max_fps_before
	Engine.physics_ticks_per_second = _ticks_before
	Engine.time_scale = _time_scale_before


func test_the_visible_body_does_not_move_in_steps() -> void:
	var world: Node3D = Node3D.new()
	add_child_autofree(world)
	world.add_child(_floor())
	_runner = PLAYER_SCENE.instantiate() as Player
	world.add_child(_runner)
	_runner.teleport(Transform3D.IDENTITY)
	var source: ScriptedIntentSource = ScriptedIntentSource.new()
	for step: int in RUN_STEPS:
		source.hold(Vector3.FORWARD.rotated(Vector3.UP, step * TURN), false, 1)
	_runner.intent_source = source
	# The ghost replays, beside it, where its visible body is at each step, as a duel does.
	_ghost = GHOST_SCENE.instantiate() as Ghost
	world.add_child(_ghost)
	get_tree().physics_frame.connect(_follow_with_the_ghost)
	var visual: Node3D = _runner.get_node("Visual") as Node3D
	var skeleton: Skeleton3D = _skeleton_of(visual)

	_set_the_game_time(SPEED_UP)
	while _runner.motor.steps < SETTLE_STEPS:
		await get_tree().process_frame
	_set_the_game_time(SLOW_DOWN)
	for frame: int in SETTLE_FRAMES:
		await get_tree().process_frame
	var shown: Array[Transform3D] = []
	var ghosted: Array[Vector3] = []
	var bones: Array[PackedVector3Array] = []
	var steps: Array[int] = []
	for frame: int in FRAMES:
		await get_tree().process_frame
		shown.append(visual.get_global_transform_interpolated())
		ghosted.append(_ghost.get_global_transform_interpolated().origin)
		steps.append(_runner.motor.steps)
		if skeleton != null:
			bones.append(_bone_places(skeleton))
	get_tree().physics_frame.disconnect(_follow_with_the_ghost)
	_set_the_game_time(1.0)

	var without_a_step: int = 0
	for frame: int in range(1, FRAMES):
		var context: String = "frame %d" % frame
		without_a_step += int(steps[frame] == steps[frame - 1])
		var moved: float = shown[frame].origin.distance_to(shown[frame - 1].origin)
		var turned: float = shown[frame].basis.z.distance_to(shown[frame - 1].basis.z)
		assert_gt(moved, NO_MOVE, context + ": the visible body moved")
		assert_gt(turned, NO_MOVE, context + ": and turned")
		assert_gt(ghosted[frame].distance_to(ghosted[frame - 1]), NO_MOVE, context + ": the ghost")
		if skeleton != null:
			var most: float = 0.0
			for bone: int in bones[frame].size():
				most = maxf(most, bones[frame][bone].distance_to(bones[frame - 1][bone]))
			assert_gt(most, NO_MOVE, context + ": the bones moved in the skeleton")
	gut.p("%d frames of %d without a fixed step" % [without_a_step, FRAMES - 1])
	assert_gt(without_a_step, FRAMES / 2, "the display goes faster than the fixed steps")
	assert_lt(without_a_step, FRAMES - 2, "fixed steps come while the frames are followed")
	if skeleton == null:
		pass_test("without the Mixamo files, the capsule and the ghost")


## At each fixed step, the ghost is put where the runner's visible body is, aside.
func _follow_with_the_ghost() -> void:
	var where: Transform3D = _runner.visual_transform()
	where.origin += ASIDE
	_ghost.show_at(where, _runner.animation)


## The game's time goes `rate` times as fast as real time, every fixed step still 1/60 s of
## it.
func _set_the_game_time(rate: float) -> void:
	Engine.physics_ticks_per_second = roundi(STEPS_PER_SECOND * rate)
	Engine.time_scale = rate


## Where each bone of `skeleton` is, in the space of the skeleton: what the clips move of
## it, the visible body and the runner left out.
func _bone_places(skeleton: Skeleton3D) -> PackedVector3Array:
	var places: PackedVector3Array = []
	for bone: int in skeleton.get_bone_count():
		places.append(skeleton.get_bone_global_pose(bone).origin)
	return places


func _skeleton_of(visual: Node3D) -> Skeleton3D:
	var found: Array[Node] = visual.find_children("*", "Skeleton3D", true, false)
	return null if found.is_empty() else found[0] as Skeleton3D


func _floor() -> StaticBody3D:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = box
	var block: StaticBody3D = StaticBody3D.new()
	block.add_child(collider)
	block.position = Vector3.DOWN * 0.5
	return block


func test_a_loop_passes_its_seam_without_slowing_down() -> void:
	# A made-up loop prepared for the tree, then, with the files, every looped clip of the
	# character: read around its seam, its bones turn as much as around its other keys,
	# measured against straight lines between its keys (no key repeated at its end that
	# would stall them there).
	var loops: Dictionary[String, Animation] = {}
	loops["a made-up loop"] = MixamoClip.in_place(
		_made_up_loop(), Vector2.ZERO, false, Vector3.ZERO, true
	)
	var character: RunnerCharacter = RunnerCharacter.create(
		RunnerCharacter.MODEL, MotorBody.fixed_tuning()
	)
	if character != null:
		var tree: AnimationTree = (
			character.find_children("*", "AnimationTree", true, false)[0] as AnimationTree
		)
		var library: AnimationLibrary = tree.get_animation_library(RunnerCharacter.LIBRARY)
		for clip: RunnerAnimation.Clip in RunnerCharacter.LOOPED:
			var named: String = RunnerAnimation.Clip.keys()[clip]
			loops[named] = library.get_animation(named.to_lower())
		character.free()
	for named: String in loops:
		var loop: Animation = loops[named]
		assert_eq(loop.loop_mode, Animation.LOOP_LINEAR, named + ": it loops")
		var straight: Animation = _on_straight_lines(loop)
		var keys: int = roundi(loop.length * RunnerCharacter.FRAMES_PER_SECOND)
		var shares: Array[float] = []
		for place: int in KEYS_READ:
			var at: float = (
				roundi(float(place * keys) / KEYS_READ) / RunnerCharacter.FRAMES_PER_SECOND
			)
			var along_the_lines: float = _turn_around(straight, at)
			assert_gt(along_the_lines, 0.0, "%s: its bones turn at %.3f s" % [named, at])
			shares.append(_turn_around(loop, at) / maxf(along_the_lines, NO_MOVE))
		var seam: float = shares.pop_front()
		shares.sort()
		var usual: float = shares[shares.size() / 2]
		gut.p(
			(
				"%s: across its seam, %.2f of the straight lines; elsewhere, %.2f"
				% [named, seam, usual]
			)
		)
		assert_gt(seam, usual * SEAM_SHARE, named + ": its bones do not slow down at the seam")
	if character == null:
		pass_test("without the Mixamo files, the made-up loop")


## A loop as a file gives it: one bone swinging to and fro, keyed at 30 frames a second on
## straight lines, from its start to its end, its last key the same as its first.
func _made_up_loop() -> Animation:
	var loop: Animation = Animation.new()
	loop.length = LOOP_LENGTH
	var track: int = loop.add_track(Animation.TYPE_ROTATION_3D)
	loop.track_set_path(track, NodePath("Skeleton3D:made_up_bone"))
	loop.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	var keys: int = roundi(LOOP_LENGTH * RunnerCharacter.FRAMES_PER_SECOND)
	for key: int in keys + 1:
		var time: float = LOOP_LENGTH * key / keys
		var swing: float = SWING * sin(TAU * key / keys)
		loop.rotation_track_insert_key(track, time, Quaternion(Vector3.RIGHT, swing))
	return loop


## How much `loop` turns its bones around its instant `at` (in s), every rotation of it
## summed, read READS times on either side, in radians.
func _turn_around(loop: Animation, at: float) -> float:
	var turned: float = 0.0
	for track: int in loop.get_track_count():
		if loop.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var before: Quaternion = loop.rotation_track_interpolate(track, _read(loop, at, -READS))
		for read: int in range(1 - READS, READS + 1):
			var turn: Quaternion = loop.rotation_track_interpolate(track, _read(loop, at, read))
			turned += before.angle_to(turn)
			before = turn
	return turned


## The instant of the `read`th reading of `loop` from its instant `at` (negative: before).
func _read(loop: Animation, at: float, read: int) -> float:
	return fposmod(at + read / READS_PER_SECOND, loop.length)


## A copy of `loop` whose keys are followed on straight lines.
func _on_straight_lines(loop: Animation) -> Animation:
	var copy: Animation = loop.duplicate() as Animation
	for track: int in copy.get_track_count():
		copy.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	return copy
