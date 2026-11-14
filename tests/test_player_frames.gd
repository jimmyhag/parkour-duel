extends GutTest
## The body one sees, frame by frame, on a display faster than the fixed steps
## (docs/specs/animation-polish.md, decision 2): the visible body of a runner, and the
## ghost of a duel, are placed between two fixed steps; the bones of the character, when
## its files are there, move at every frame. In real time: the display at 144 frames a
## second, the fixed step at 1/60 s.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const GHOST_SCENE: PackedScene = preload("res://game/player/ghost.tscn")
const DISPLAY_RATE: int = 144
const STEPS_PER_SECOND: int = 60
## How many frames are followed, once the runner is well under way.
const SETTLE_FRAMES: int = 20
const FRAMES: int = 90
## The runner runs around: its push turns this much at each step, in radians.
const TURN: float = 0.04
## More steps than the frames followed last.
const RUN_STEPS: int = 300
## How far beside the runner the ghost goes, in m.
const ASIDE: Vector3 = Vector3(6.0, 0.0, 0.0)
## A move smaller than this, in m, from one frame to the next, is none; and a turn that
## moves the way the body faces less than this.
const NO_MOVE: float = 0.000001

var _max_fps_before: int = 0
var _ticks_before: int = 0
var _ghost: Ghost = null
var _runner: Player = null


func before_all() -> void:
	_max_fps_before = Engine.max_fps
	_ticks_before = Engine.physics_ticks_per_second
	Engine.max_fps = DISPLAY_RATE
	Engine.physics_ticks_per_second = STEPS_PER_SECOND


func after_all() -> void:
	Engine.max_fps = _max_fps_before
	Engine.physics_ticks_per_second = _ticks_before


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
			assert_gt(most, NO_MOVE, context + ": the bones moved")
	gut.p("%d frames of %d without a fixed step" % [without_a_step, FRAMES - 1])
	assert_gt(without_a_step, FRAMES / 8, "the display goes faster than the fixed steps")
	if skeleton == null:
		pass_test("without the Mixamo files, the capsule and the ghost")


## At each fixed step, the ghost is put where the runner's visible body is, aside.
func _follow_with_the_ghost() -> void:
	var where: Transform3D = _runner.visual_transform()
	where.origin += ASIDE
	_ghost.show_at(where, _runner.animation)


## Where each bone of `skeleton` is, in the space of the runner's body: what moves of it
## on screen, the runner's own move left out.
func _bone_places(skeleton: Skeleton3D) -> PackedVector3Array:
	var body: Transform3D = _runner.get_global_transform_interpolated().affine_inverse()
	var place: Transform3D = body * skeleton.get_global_transform_interpolated()
	var places: PackedVector3Array = []
	for bone: int in skeleton.get_bone_count():
		places.append(place * skeleton.get_bone_global_pose(bone).origin)
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
