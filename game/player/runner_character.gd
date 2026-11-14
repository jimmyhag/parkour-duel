class_name RunnerCharacter
extends Node3D
## The Mixamo character, animated: the visible body of a runner when the Mixamo files are
## in assets/mixamo/ (`just mixamo`, docs/specs/character-animations.md), in place of the
## capsule; without them, there is none. It stands as tall as the standing capsule, its
## feet on the ground, facing -Z, and plays the animation chosen from the motor
## (RunnerAnimation): a short blend from one clip to the next, the clip fitted to the
## move it shows, mirrored along a wall at the right, and the upper body held in the aim of
## Pistol Idle over what the legs do. The clips play in place: the motor alone moves the
## runner. Presentation only: nothing the runner observes depends on it.

## The character, the only file whose mesh the game uses.
const MODEL: String = "res://assets/mixamo/ch08_nonpbr.fbx"
## The file of each clip; the tuck pose is taken out of Backflip.
const CLIP_FILES: Dictionary[RunnerAnimation.Clip, String] = {
	RunnerAnimation.Clip.IDLE: "res://assets/mixamo/idle.fbx",
	RunnerAnimation.Clip.RUNNING: "res://assets/mixamo/running.fbx",
	RunnerAnimation.Clip.JUMP: "res://assets/mixamo/jump.fbx",
	RunnerAnimation.Clip.FALLING_IDLE: "res://assets/mixamo/falling_idle.fbx",
	RunnerAnimation.Clip.LANDING: "res://assets/mixamo/landing.fbx",
	RunnerAnimation.Clip.HARD_LANDING: "res://assets/mixamo/hard_landing.fbx",
	RunnerAnimation.Clip.FALLING_TO_ROLL: "res://assets/mixamo/falling_to_roll.fbx",
	RunnerAnimation.Clip.RUNNING_SLIDE: "res://assets/mixamo/running_slide.fbx",
	RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB: "res://assets/mixamo/sprint_to_wall_climb.fbx",
	RunnerAnimation.Clip.WALL_RUN: "res://assets/mixamo/wall_run.fbx",
	RunnerAnimation.Clip.TUCK: "res://assets/mixamo/backflip.fbx",
}
const PISTOL_IDLE: String = "res://assets/mixamo/pistol_idle.fbx"
## The part of each clip that is played, from its start to its end, in s (an end of 0: to
## the end of the file): the part of Falling To Roll that rolls, of Sprint To Wall Climb
## that hoists, of Landing from the contact with the ground, of Wall Run before the body
## turns away from the wall.
const CUTS: Dictionary[RunnerAnimation.Clip, Vector2] = {
	RunnerAnimation.Clip.JUMP: Vector2(0.05, 0.42),
	RunnerAnimation.Clip.LANDING: Vector2(0.35, 0.8),
	RunnerAnimation.Clip.HARD_LANDING: Vector2(0.0, 0.5),
	RunnerAnimation.Clip.FALLING_TO_ROLL: Vector2(0.3, 1.1),
	RunnerAnimation.Clip.RUNNING_SLIDE: Vector2(0.1, 0.8),
	RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB: Vector2(0.74, 1.4),
	RunnerAnimation.Clip.WALL_RUN: Vector2(0.05, 0.6),
}
## The clips that loop; the others hold their last pose.
const LOOPED: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.IDLE,
	RunnerAnimation.Clip.RUNNING,
	RunnerAnimation.Clip.FALLING_IDLE,
]
## The clips whose rise of the hips is a move the motor already makes: their hips stay at
## the height of a standing body. The others keep the height of their hips (a slide, a
## roll, a crouch), not their way forward.
const RAISED: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.JUMP,
	RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB,
	RunnerAnimation.Clip.WALL_RUN,
]
## The animation of a Mixamo file, the root bone of its skeleton, the first bone of the
## upper body and the bone whose bend shows the tuck, in the tracks of the files.
const TAKE: StringName = &"mixamo_com"
const SKELETON: String = "Skeleton3D"
const HIPS: String = "mixamorig7_Hips"
const SPINE: String = "mixamorig7_Spine"
const KNEE: String = "mixamorig7_LeftLeg"
## The rate at which the clips are sampled, as in the files.
const FRAMES_PER_SECOND: float = 30.0
const LIBRARY: StringName = &"runner"
const AIM: String = "pistol_idle"
## The nodes of the animation tree, and their parameters.
const STATE_NODE: StringName = &"state"
const PACE_NODE: StringName = &"pace"
const AIM_NODE: StringName = &"aim"
const TRANSITION_REQUEST: StringName = &"parameters/state/transition_request"
const PACE: StringName = &"parameters/pace/scale"
const AIM_AMOUNT: StringName = &"parameters/aim/blend_amount"
## The colour a tint adds over the character, as a share of it.
const TINT_SHARE: float = 0.5

## The clips of every character, made once from the files, and the character's scene,
## kept: loading it again for every runner would take a second each time.
static var _library: AnimationLibrary = null
static var _scenes: Dictionary[String, PackedScene] = {}

var _model: Node3D
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _transition: AnimationNodeTransition
var _hold: AimHold
## Its size, and the clip, the mirror and the aim it shows.
var _scale: float = 1.0
var _clip: RunnerAnimation.Clip = RunnerAnimation.Clip.IDLE
var _mirrored: bool = false
var _aim: float = 0.0
var _aim_wanted: float = 0.0
var _aim_blend_time: float = 0.0


## Holds the upper body in the aim of Pistol Idle, turned as in that clip, whatever the
## hips of the legs do: the aim faces where the runner faces.
class AimHold:
	extends SkeletonModifier3D

	## How much of the aim the upper body holds (0 to 1).
	var weight: float = 0.0
	var _hips: int = -1
	var _spine: int = -1
	## The rotation of the hips in Pistol Idle.
	var _aim_hips: Quaternion = Quaternion.IDENTITY

	func _init(hips: int, spine: int, aim_hips: Quaternion) -> void:
		_hips = hips
		_spine = spine
		_aim_hips = aim_hips

	func _process_modification_with_delta(_delta: float) -> void:
		var skeleton: Skeleton3D = get_skeleton()
		if weight <= 0.0 or skeleton == null:
			return
		var hips: Quaternion = skeleton.get_bone_pose_rotation(_hips)
		var turn: Quaternion = Quaternion.IDENTITY.slerp(hips.inverse() * _aim_hips, weight)
		skeleton.set_bone_pose_rotation(_spine, turn * skeleton.get_bone_pose_rotation(_spine))


## The character, `height` tall, made from `model` and the clips; null when one of the
## files is not there, or when the character is not rigged as Ch08 (see fits): the runner
## keeps its capsule.
static func create(model: String, height: float) -> RunnerCharacter:
	if not ResourceLoader.exists(model) or not ResourceLoader.exists(PISTOL_IDLE):
		return null
	for clip: RunnerAnimation.Clip in CLIP_FILES:
		if not ResourceLoader.exists(CLIP_FILES[clip]):
			return null
	if not _scenes.has(model):
		var loaded: PackedScene = load(model) as PackedScene
		if loaded == null:
			return null
		_scenes[model] = loaded
	var instance: Node3D = _scenes[model].instantiate() as Node3D
	if not fits(instance):
		instance.free()
		return null
	var character: RunnerCharacter = RunnerCharacter.new()
	character._build(instance, height)
	return character


## Whether `model` has the skeleton the clips move: the bones of Ch08, whose names carry
## the prefix Mixamo gave that character. Another character, or clips downloaded on
## another one, have other names.
static func fits(model: Node3D) -> bool:
	var skeleton: Skeleton3D = model.get_node_or_null(SKELETON) as Skeleton3D
	if skeleton == null:
		return false
	for bone: String in [HIPS, SPINE, KNEE]:
		if skeleton.find_bone(bone) < 0:
			return false
	return true


## Shows `animation`: a new clip blends in, in its blend time; the clip plays at its speed,
## or fitted to its duration; the mirror follows at once; the aim blends in and out.
func play(animation: RunnerAnimation) -> void:
	var length: float = _library.get_animation(_clip_name(animation.clip)).length
	var pace: float = animation.speed
	if animation.duration > 0.0:
		pace = length / animation.duration
	if animation.clip != _clip:
		_clip = animation.clip
		_transition.xfade_time = animation.blend_time
		_tree.set(TRANSITION_REQUEST, _clip_name(_clip))
	_tree.set(PACE, pace)
	_aim_wanted = 1.0 if animation.aiming else 0.0
	_aim_blend_time = animation.blend_time
	if animation.mirrored != _mirrored:
		_mirrored = animation.mirrored
		_place()
		_model.reset_physics_interpolation()


## Adds `colour` over the character, as a share of it: the bot's.
func tint(colour: Color) -> void:
	var overlay: StandardMaterial3D = StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.albedo_color = Color(colour, TINT_SHARE)
	for mesh: MeshInstance3D in _meshes():
		mesh.material_overlay = overlay


## Draws the whole character with `material`: the ghost's.
func wear(material: Material) -> void:
	for mesh: MeshInstance3D in _meshes():
		mesh.material_override = material


func _process(delta: float) -> void:
	if _aim_blend_time <= 0.0:
		_aim = _aim_wanted
	else:
		_aim = move_toward(_aim, _aim_wanted, delta / _aim_blend_time)
	_tree.set(AIM_AMOUNT, _aim)
	_hold.weight = _aim


func _build(model: Node3D, height: float) -> void:
	_model = model
	add_child(_model)
	_skeleton = _model.get_node(SKELETON) as Skeleton3D
	var bounds: AABB = AABB()
	var first: bool = true
	for mesh: MeshInstance3D in _meshes():
		var box: AABB = mesh.transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	_scale = height / bounds.size.y
	_place()
	_model.position.y = -bounds.position.y * _scale
	if _library == null:
		_library = _make_library(_skeleton)
	_tree = AnimationTree.new()
	_model.add_child(_tree)
	_tree.root_node = NodePath("..")
	_tree.add_animation_library(LIBRARY, _library)
	_tree.tree_root = _make_blend_tree()
	_tree.active = true
	var hips: int = _skeleton.find_bone(HIPS)
	var aim_hips: Quaternion = _aim_hips_rotation()
	_hold = AimHold.new(hips, _skeleton.find_bone(SPINE), aim_hips)
	_skeleton.add_child(_hold)


## Turns the model to face -Z, at its size, mirrored or not.
func _place() -> void:
	var size: Vector3 = Vector3(-_scale if _mirrored else _scale, _scale, _scale)
	_model.basis = Basis(Vector3.UP, PI) * Basis.from_scale(size)


func _meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for node: Node in _skeleton.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


## The tree that plays the clips: one state per clip, blended from one to the next, at a
## pace, then the aim over the upper body (the spine and all it carries).
func _make_blend_tree() -> AnimationNodeBlendTree:
	var blend_tree: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	_transition = AnimationNodeTransition.new()
	blend_tree.add_node(STATE_NODE, _transition)
	var index: int = 0
	for clip: RunnerAnimation.Clip in RunnerAnimation.Clip.values():
		var name: String = _clip_name(clip)
		var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
		node.animation = "%s/%s" % [LIBRARY, name]
		blend_tree.add_node(name, node)
		_transition.add_input(name)
		blend_tree.connect_node(STATE_NODE, index, name)
		index += 1
	var pace: AnimationNodeTimeScale = AnimationNodeTimeScale.new()
	blend_tree.add_node(PACE_NODE, pace)
	blend_tree.connect_node(PACE_NODE, 0, STATE_NODE)
	var aim_clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
	aim_clip.animation = "%s/%s" % [LIBRARY, AIM]
	blend_tree.add_node(AIM, aim_clip)
	var aim: AnimationNodeBlend2 = AnimationNodeBlend2.new()
	aim.filter_enabled = true
	for bone: int in _upper_body():
		aim.set_filter_path(NodePath("%s:%s" % [SKELETON, _skeleton.get_bone_name(bone)]), true)
	blend_tree.add_node(AIM_NODE, aim)
	blend_tree.connect_node(AIM_NODE, 0, PACE_NODE)
	blend_tree.connect_node(AIM_NODE, 1, AIM)
	blend_tree.connect_node(&"output", 0, AIM_NODE)
	return blend_tree


## The spine and every bone it carries.
func _upper_body() -> Array[int]:
	var bones: Array[int] = [_skeleton.find_bone(SPINE)]
	var index: int = 0
	while index < bones.size():
		bones.append_array(_skeleton.get_bone_children(bones[index]))
		index += 1
	return bones


## The rotation of the hips in Pistol Idle, as it starts.
func _aim_hips_rotation() -> Quaternion:
	var aim: Animation = _library.get_animation(AIM)
	var track: int = aim.find_track(
		NodePath("%s:%s" % [SKELETON, HIPS]), Animation.TYPE_ROTATION_3D
	)
	if track < 0:
		return Quaternion.IDENTITY
	return aim.rotation_track_interpolate(track, 0.0)


static func _clip_name(clip: RunnerAnimation.Clip) -> String:
	var name: String = RunnerAnimation.Clip.keys()[clip]
	return name.to_lower()


## Every clip, cut, in place, looped or not; the tuck pose; and the aim.
static func _make_library(skeleton: Skeleton3D) -> AnimationLibrary:
	var hips_rest: Vector3 = skeleton.get_bone_rest(skeleton.find_bone(HIPS)).origin
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: RunnerAnimation.Clip in CLIP_FILES:
		var source: Animation = _take(CLIP_FILES[clip])
		var made: Animation
		if clip == RunnerAnimation.Clip.TUCK:
			made = _pose_at(source, _tightest_tuck(source), hips_rest)
		else:
			var cut: Vector2 = CUTS.get(clip, Vector2.ZERO)
			made = _in_place(source, cut, clip in RAISED, hips_rest)
		if clip in LOOPED:
			made.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(_clip_name(clip), made)
	var aim: Animation = _in_place(_take(PISTOL_IDLE), Vector2.ZERO, false, hips_rest)
	aim.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(AIM, aim)
	return library


## The animation of a Mixamo file.
static func _take(path: String) -> Animation:
	var scene: PackedScene = load(path) as PackedScene
	var root: Node = scene.instantiate()
	var player: AnimationPlayer = root.get_node("AnimationPlayer") as AnimationPlayer
	var take: Animation = player.get_animation(TAKE)
	root.free()
	return take


## The part `cut` of `source`, sampled again, its hips kept over the feet: their way
## forward and aside removed, and their rise too when `raised`.
static func _in_place(source: Animation, cut: Vector2, raised: bool, rest: Vector3) -> Animation:
	var start: float = cut.x
	var end: float = source.length if cut.y <= 0.0 else minf(cut.y, source.length)
	var made: Animation = Animation.new()
	made.length = end - start
	var hips: NodePath = NodePath("%s:%s" % [SKELETON, HIPS])
	for track: int in source.get_track_count():
		var type: Animation.TrackType = source.track_get_type(track)
		var path: NodePath = source.track_get_path(track)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D:
			continue
		var copy: int = made.add_track(type)
		made.track_set_path(copy, path)
		var frames: int = ceili(made.length * FRAMES_PER_SECOND - 0.001)
		for frame: int in frames + 1:
			var time: float = minf(start + frame / FRAMES_PER_SECOND, end)
			if type == Animation.TYPE_ROTATION_3D:
				var turn: Quaternion = source.rotation_track_interpolate(track, time)
				made.rotation_track_insert_key(copy, time - start, turn)
				continue
			var place: Vector3 = source.position_track_interpolate(track, time)
			if path == hips:
				place = Vector3(rest.x, rest.y if raised else place.y, rest.z)
			made.position_track_insert_key(copy, time - start, place)
	return made


## When the knee of `source` bends the most: the tightest tuck of a flip.
static func _tightest_tuck(source: Animation) -> float:
	var knee: int = source.find_track(
		NodePath("%s:%s" % [SKELETON, KNEE]), Animation.TYPE_ROTATION_3D
	)
	var tightest: float = 0.0
	var most: float = -1.0
	var frames: int = floori(source.length * FRAMES_PER_SECOND)
	for frame: int in frames + 1:
		var time: float = frame / FRAMES_PER_SECOND
		var bend: float = source.rotation_track_interpolate(knee, time).get_angle()
		if bend > most:
			most = bend
			tightest = time
	return tightest


## The pose of `source` at `time`, held: every bone as it is then, but the hips upright
## and over the feet, so that the turn of the flip is left to the body that carries it.
static func _pose_at(source: Animation, time: float, rest: Vector3) -> Animation:
	var made: Animation = Animation.new()
	made.length = 1.0 / FRAMES_PER_SECOND
	var hips: NodePath = NodePath("%s:%s" % [SKELETON, HIPS])
	for track: int in source.get_track_count():
		var type: Animation.TrackType = source.track_get_type(track)
		var path: NodePath = source.track_get_path(track)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D:
			continue
		var copy: int = made.add_track(type)
		made.track_set_path(copy, path)
		if type == Animation.TYPE_POSITION_3D:
			var place: Vector3 = source.position_track_interpolate(track, time)
			made.position_track_insert_key(copy, 0.0, rest if path == hips else place)
		else:
			var turn: Quaternion = source.rotation_track_interpolate(track, time)
			made.rotation_track_insert_key(copy, 0.0, Quaternion.IDENTITY if path == hips else turn)
	return made
