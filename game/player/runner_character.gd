class_name RunnerCharacter
extends Node3D
## The Mixamo character, animated: the visible body of a runner when the Mixamo files are
## in assets/mixamo/ (`just mixamo`, docs/specs/character-animations.md), in place of the
## capsule; without them, there is none. It stands as tall as the standing capsule, its
## feet on the ground, facing -Z, and plays the animation chosen from the motor
## (RunnerAnimation): a blend from one clip to the next, the clip fitted to the move it
## shows, the upper body held in the aim of Pistol Idle over what the legs do. On its feet,
## the locomotion blends Idle, Walking, Running and Sprint as the animation weighs them,
## the last three at the same phase of their stride (Stride), as fast as the feet keep up
## with the ground, and resumed at the stride nearest the pose shown. The clips play in
## place: the motor alone moves the runner. Wall Run is laid against the wall from its
## bones (WallRunPose): mirrored along a wall on the other side than its own, and moved
## across so that its feet almost touch the wall, as much as its clip is blended in.
## Presentation only: nothing the runner observes depends on it.

## The character, the only file whose mesh the game uses.
const MODEL: String = "res://assets/mixamo/ch08_nonpbr.fbx"
## The file of each clip; the tuck pose is taken out of Backflip.
const CLIP_FILES: Dictionary[RunnerAnimation.Clip, String] = {
	RunnerAnimation.Clip.IDLE: "res://assets/mixamo/idle.fbx",
	RunnerAnimation.Clip.WALKING: "res://assets/mixamo/walking.fbx",
	RunnerAnimation.Clip.RUNNING: "res://assets/mixamo/running.fbx",
	RunnerAnimation.Clip.SPRINT: "res://assets/mixamo/sprint.fbx",
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
	RunnerAnimation.Clip.WALKING,
	RunnerAnimation.Clip.RUNNING,
	RunnerAnimation.Clip.SPRINT,
	RunnerAnimation.Clip.FALLING_IDLE,
]
## The clips of the locomotion that stride, from the slowest; and at how many evenly spaced
## phases of their stride they are measured.
const STRIDES: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.WALKING,
	RunnerAnimation.Clip.RUNNING,
	RunnerAnimation.Clip.SPRINT,
]
const STRIDE_SAMPLES: int = 60
## The clips whose rise of the hips is a move the motor already makes: their hips stay at
## the height of a standing body. The others keep the height of their hips (a slide, a
## roll, a crouch), not their way forward.
const RAISED: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.JUMP,
	RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB,
	RunnerAnimation.Clip.WALL_RUN,
]
## The animation of a Mixamo file, the root bone of its skeleton, the first bone of the
## upper body, the bone whose bend shows the tuck, the head and feet that tell the side of
## the wall of Wall Run, and the toe that tells, with the left foot, when a stride starts,
## in the tracks of the files.
const TAKE: StringName = &"mixamo_com"
const SKELETON: String = "Skeleton3D"
const HIPS: String = "mixamorig7_Hips"
const SPINE: String = "mixamorig7_Spine"
const KNEE: String = "mixamorig7_LeftLeg"
const HEAD: String = "mixamorig7_Head"
const LEFT_FOOT: String = "mixamorig7_LeftFoot"
const RIGHT_FOOT: String = "mixamorig7_RightFoot"
const LEFT_TOE: String = "mixamorig7_LeftToeBase"
## The bones the character must have for the clips to move it.
const RIG: Array[String] = [HIPS, SPINE, KNEE, HEAD, LEFT_FOOT, RIGHT_FOOT, LEFT_TOE]
## The turn that makes the model, which faces +Z, face -Z as the runner does.
const FACING: Basis = Basis(Vector3.UP, PI)
## The rate at which the clips are sampled, as in the files.
const FRAMES_PER_SECOND: float = 30.0
const LIBRARY: StringName = &"runner"
const AIM: String = "pistol_idle"
## The nodes of the animation tree, and their parameters: the state shown (the locomotion
## or another clip, each at its pace, and the blend from the state before), the locomotion
## (Idle blended with the clips that stride, at a phase and a number of strides a second),
## and the aim.
const STATE_NODE: StringName = &"state"
const LOCOMOTION_NODE: StringName = &"locomotion"
const MOVING_NODE: StringName = &"moving"
const RESUME_NODE: StringName = &"resume"
const STRIDE_NODE: StringName = &"stride"
const AIM_NODE: StringName = &"aim"
const TRANSITION_REQUEST: StringName = &"parameters/state/transition_request"
const CURRENT_STATE: StringName = &"parameters/state/current_state"
const PREVIOUS_INDEX: StringName = &"parameters/state/prev_index"
const BLEND_LEFT: StringName = &"parameters/state/prev_xfading"
const PACE: String = "parameters/%s_pace/scale"
const LOCOMOTION_AMOUNT: StringName = &"parameters/locomotion/blend_amount"
const MOVING_POSITION: StringName = &"parameters/moving/blend_position"
const RESUME_REQUEST: StringName = &"parameters/resume/seek_request"
const STRIDE_SCALE: StringName = &"parameters/stride/scale"
const STRIDE_POSITION: String = "parameters/moving/%s/current_position"
const AIM_AMOUNT: StringName = &"parameters/aim/blend_amount"
## The colour a tint adds over the character, as a share of it.
const TINT_SHARE: float = 0.5

## The clips of every character, made once from the files, and the character's scene,
## kept: loading it again for every runner would take a second each time.
static var _library: AnimationLibrary = null
static var _scenes: Dictionary[String, PackedScene] = {}
## How Wall Run is laid against the wall, measured as its clip is made.
static var _wall_run: WallRunPose = null
## Of each clip that strides, measured as it is made: when its left foot touches the
## ground, in s, the length of its cycle, in s, and its pose at each phase of its stride
## from then (how far the left foot is ahead of the right one, and how much higher).
static var _touchdowns: Dictionary[RunnerAnimation.Clip, float] = {}
static var _cycle_lengths: Dictionary[RunnerAnimation.Clip, float] = {}
static var _cycles: Dictionary[RunnerAnimation.Clip, PackedVector2Array] = {}

var _model: Node3D
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _transition: AnimationNodeTransition
var _hold: AimHold
## The tuning whose speeds of the strides it follows.
var _tuning: MovementTuning
## Its size, the state it shows (the locomotion or a clip; none before it first plays),
## the mirror, the input of Wall Run in the tree, and the aim.
var _scale: float = 1.0
var _state: StringName = &""
var _mirrored: bool = false
var _wall_run_input: int = -1
## The way to the wall of the last wall run, in the world, and how far towards it the
## character leans with Wall Run wholly blended in, in m (negative: away from it).
var _lean_towards: Vector3 = Vector3.ZERO
var _lean_offset: float = 0.0
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


## Moves the whole body across, at its hips, as far as the character leans on the wall of
## a wall run (wall_shift), in the update that poses it: the move follows the blend of the
## clip the bones show.
class WallLean:
	extends SkeletonModifier3D

	var _character: RunnerCharacter
	var _hips: int = -1

	func _init(character: RunnerCharacter, hips: int) -> void:
		_character = character
		_hips = hips

	func _process_modification_with_delta(_delta: float) -> void:
		var skeleton: Skeleton3D = get_skeleton()
		var shift: Vector3 = _character.wall_shift()
		if skeleton == null or shift.is_zero_approx():
			return
		var across: Vector3 = skeleton.global_basis.inverse() * shift
		skeleton.set_bone_pose_position(_hips, skeleton.get_bone_pose_position(_hips) + across)


## The character, as tall as the capsule of `tuning`, made from `model` and the clips;
## null when one of the files is not there, or when the character is not rigged as Ch08
## (see fits): the runner keeps its capsule.
static func create(model: String, tuning: MovementTuning) -> RunnerCharacter:
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
	character._tuning = tuning
	character._build(instance, tuning.capsule_height)
	return character


## Whether `model` has the skeleton the clips move: the bones of Ch08, whose names carry
## the prefix Mixamo gave that character. Another character, or clips downloaded on
## another one, have other names.
static func fits(model: Node3D) -> bool:
	var skeleton: Skeleton3D = model.get_node_or_null(SKELETON) as Skeleton3D
	if skeleton == null:
		return false
	for bone: String in RIG:
		if skeleton.find_bone(bone) < 0:
			return false
	return true


## Shows `animation`: a new clip blends in, in its blend time, the locomotion at the phase
## of the stride nearest the pose shown; the clip plays at its speed, or fitted to its
## duration; the locomotion blends its clips as weighed; the aim blends in and out; along a
## wall, the clip is mirrored as the wall asks, until Wall Run has blended out.
func play(animation: RunnerAnimation) -> void:
	var state: StringName = _state_of(animation.clip)
	if state != _state:
		if state == LOCOMOTION_NODE:
			_tree.set(RESUME_REQUEST, _resume_phase(animation.locomotion))
		_state = state
		_transition.xfade_time = animation.blend_time
		_tree.set(TRANSITION_REQUEST, _state)
	if state == LOCOMOTION_NODE:
		_walk(animation)
	else:
		var pace: float = animation.speed
		if animation.duration > 0.0:
			pace = _library.get_animation(state).length / animation.duration
		_tree.set(PACE % state, pace)
	_aim_wanted = 1.0 if animation.aiming else 0.0
	_aim_blend_time = animation.blend_time
	_mirror_along(animation)


## Leans the character on the wall of the wall run under way: it is moved by `towards` (the
## way to the wall) times what puts its feet a few centimetres from the wall, the wall
## being `wall_distance` m from the side of the capsule (WallRunPose), as much as Wall Run
## is blended in.
func lean_on_the_wall(towards: Vector3, wall_distance: float) -> void:
	_lean_towards = towards
	_lean_offset = _wall_run.offset(_scale, wall_distance, _tuning)


## How far the character is moved across now, in the world: its lean on the wall times the
## share the blend of Wall Run gives it (WallRunPose.shift_share).
func wall_shift() -> Vector3:
	var along: bool = _state == _state_of(RunnerAnimation.Clip.WALL_RUN)
	var away: bool = _lean_offset < 0.0
	var share: float = WallRunPose.shift_share(wall_run_weight(), away, along)
	return _lean_towards * _lean_offset * share


## How much of Wall Run the bones show (0 to 1), as its clip blends in and out in the tree.
## Without a state before (the first one shown, or a blend over), the state shown is
## wholly in.
func wall_run_weight() -> float:
	var current: StringName = _tree.get(CURRENT_STATE)
	var previous: int = _tree.get(PREVIOUS_INDEX)
	var left: float = _tree.get(BLEND_LEFT)
	var blend: float = _transition.xfade_time
	var coming: float = 1.0
	if previous >= 0 and blend > 0.0:
		coming = clampf(1.0 - left / blend, 0.0, 1.0)
	if current == _state_of(RunnerAnimation.Clip.WALL_RUN):
		return coming
	return 1.0 - coming if previous == _wall_run_input else 0.0


## Where the clip `clip` of the locomotion is in its cycle, in the tree: from 0 at the
## touchdown of its left foot to 1.
static func stride_position(clip: RunnerAnimation.Clip) -> StringName:
	return StringName(STRIDE_POSITION % _clip_name(clip))


## When the left foot of the clip `clip` of the locomotion touches the ground, in s.
static func touchdown_of(clip: RunnerAnimation.Clip) -> float:
	return _touchdowns.get(clip, 0.0)


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
	_skeleton.add_child(WallLean.new(self, hips))


## Turns the model to face -Z, at its size, mirrored or not.
func _place() -> void:
	var size: Vector3 = Vector3(-_scale if _mirrored else _scale, _scale, _scale)
	_model.basis = FACING * Basis.from_scale(size)


func _meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for node: Node in _skeleton.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


## The tree that plays the clips: the locomotion and one state per other clip, each at its
## pace, blended from one to the next, then the aim over the upper body (the spine and all
## it carries).
func _make_blend_tree() -> AnimationNodeBlendTree:
	var blend_tree: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	_transition = AnimationNodeTransition.new()
	blend_tree.add_node(STATE_NODE, _transition)
	_add_the_locomotion(blend_tree)
	_transition.add_input(LOCOMOTION_NODE)
	# Back to the locomotion, its stride is put at a phase: not at its start.
	_transition.set_input_reset(0, false)
	blend_tree.connect_node(STATE_NODE, 0, LOCOMOTION_NODE)
	var index: int = 1
	for clip: RunnerAnimation.Clip in RunnerAnimation.Clip.values():
		if clip in RunnerAnimation.LOCOMOTION:
			continue
		var name: String = _clip_name(clip)
		blend_tree.add_node(name, _clip_node(clip))
		var pace_node: StringName = StringName(name + "_pace")
		blend_tree.add_node(pace_node, AnimationNodeTimeScale.new())
		blend_tree.connect_node(pace_node, 0, name)
		_transition.add_input(name)
		if clip == RunnerAnimation.Clip.WALL_RUN:
			_wall_run_input = index
		blend_tree.connect_node(STATE_NODE, index, pace_node)
		index += 1
	var aim_clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
	aim_clip.animation = "%s/%s" % [LIBRARY, AIM]
	blend_tree.add_node(AIM, aim_clip)
	var aim: AnimationNodeBlend2 = AnimationNodeBlend2.new()
	aim.filter_enabled = true
	for bone: int in _upper_body():
		aim.set_filter_path(NodePath("%s:%s" % [SKELETON, _skeleton.get_bone_name(bone)]), true)
	blend_tree.add_node(AIM_NODE, aim)
	blend_tree.connect_node(AIM_NODE, 0, STATE_NODE)
	blend_tree.connect_node(AIM_NODE, 1, AIM)
	blend_tree.connect_node(&"output", 0, AIM_NODE)
	return blend_tree


## The locomotion: Idle at its own pace, blended with the clips that stride, on one axis
## from Walking to Sprint; each of those plays one cycle in one second of its timeline,
## from the touchdown of its left foot, all of them on, so that they stay at the same
## phase; a seek puts them at a phase, a scale sets how many strides a second they make.
func _add_the_locomotion(blend_tree: AnimationNodeBlendTree) -> void:
	var idle: String = _clip_name(RunnerAnimation.Clip.IDLE)
	blend_tree.add_node(idle, _clip_node(RunnerAnimation.Clip.IDLE))
	var moving: AnimationNodeBlendSpace1D = AnimationNodeBlendSpace1D.new()
	moving.min_space = 0.0
	moving.max_space = STRIDES.size() - 1
	moving.sync_mode = AnimationNodeBlendSpace1D.SYNC_MODE_INDEPENDENT
	for point: int in STRIDES.size():
		var clip: RunnerAnimation.Clip = STRIDES[point]
		var node: AnimationNodeAnimation = _clip_node(clip)
		node.use_custom_timeline = true
		node.timeline_length = 1.0
		node.stretch_time_scale = true
		# The offset is on the timeline, stretched: a share of the cycle.
		node.start_offset = _touchdowns[clip] / _cycle_lengths[clip]
		node.loop_mode = Animation.LOOP_LINEAR
		moving.add_blend_point(node, point, -1, _clip_name(clip))
	blend_tree.add_node(MOVING_NODE, moving)
	blend_tree.add_node(RESUME_NODE, AnimationNodeTimeSeek.new())
	blend_tree.connect_node(RESUME_NODE, 0, MOVING_NODE)
	blend_tree.add_node(STRIDE_NODE, AnimationNodeTimeScale.new())
	blend_tree.connect_node(STRIDE_NODE, 0, RESUME_NODE)
	blend_tree.add_node(LOCOMOTION_NODE, AnimationNodeBlend2.new())
	blend_tree.connect_node(LOCOMOTION_NODE, 0, idle)
	blend_tree.connect_node(LOCOMOTION_NODE, 1, STRIDE_NODE)


static func _clip_node(clip: RunnerAnimation.Clip) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	node.animation = "%s/%s" % [LIBRARY, _clip_name(clip)]
	return node


## Blends the locomotion as `animation` weighs it: Idle against the clips that stride, those
## on their axis, as many strides a second as keep the feet up with the ground.
func _walk(animation: RunnerAnimation) -> void:
	var weights: PackedFloat32Array = _locomotion_weights(animation)
	var moving: float = 1.0 - weights[0]
	var position: float = 0.0
	for point: int in STRIDES.size():
		position += point * weights[point + 1]
	_tree.set(LOCOMOTION_AMOUNT, moving)
	_tree.set(MOVING_POSITION, position / moving if moving > 0.0 else 0.0)
	var lengths: PackedFloat32Array = [0.0]
	for clip: RunnerAnimation.Clip in STRIDES:
		lengths.append(_cycle_lengths[clip])
	var speeds: PackedFloat32Array = RunnerAnimation.stride_speeds(_tuning)
	_tree.set(STRIDE_SCALE, Stride.cycles_per_second(animation.speed, weights, speeds, lengths))


## The phase at which the locomotion resumes, weighed by `weights`: the phase of its stride
## whose pose is nearest the one shown, the left foot ahead of the right one or behind it,
## higher or lower.
func _resume_phase(weights: PackedFloat32Array) -> float:
	var shown: Vector2 = _stride_pose(
		_skeleton.get_bone_global_pose(_skeleton.find_bone(LEFT_FOOT)).origin,
		_skeleton.get_bone_global_pose(_skeleton.find_bone(RIGHT_FOOT)).origin
	)
	var cycle: PackedVector2Array = []
	cycle.resize(STRIDE_SAMPLES)
	var moving: float = 0.0
	for point: int in STRIDES.size():
		var weight: float = weights[point + 1] if weights.size() > point + 1 else 0.0
		moving += weight
		var poses: PackedVector2Array = _cycles[STRIDES[point]]
		for sample: int in STRIDE_SAMPLES:
			cycle[sample] += poses[sample] * weight
	if moving <= 0.0:
		return Stride.nearest_phase(shown, _cycles[STRIDES[0]])
	for sample: int in STRIDE_SAMPLES:
		cycle[sample] /= moving
	return Stride.nearest_phase(shown, cycle)


## The weights of the locomotion of `animation`; Idle alone when it has none.
func _locomotion_weights(animation: RunnerAnimation) -> PackedFloat32Array:
	if animation.locomotion.size() == RunnerAnimation.LOCOMOTION.size():
		return animation.locomotion
	return RunnerAnimation.locomotion_weights(0.0, _tuning)


## Mirrors the clip as the wall of the wall run asks while it runs along it, and until
## Wall Run has blended out.
func _mirror_along(animation: RunnerAnimation) -> void:
	var mirrored: bool = _mirrored
	if animation.wall_side != RunnerAnimation.WallSide.NONE:
		mirrored = _wall_run.mirrors(animation.wall_side)
	elif wall_run_weight() <= 0.0:
		mirrored = false
	if mirrored != _mirrored:
		_mirrored = mirrored
		_place()
		_model.reset_physics_interpolation()


## The state of the tree that shows `clip`: the locomotion, or the clip.
static func _state_of(clip: RunnerAnimation.Clip) -> StringName:
	if clip in RunnerAnimation.LOCOMOTION:
		return LOCOMOTION_NODE
	return StringName(_clip_name(clip))


## How far the left foot at `left` is ahead of the right one at `right`, and how much
## higher: the pose of a stride, in the space of the skeleton (+Z ahead).
static func _stride_pose(left: Vector3, right: Vector3) -> Vector2:
	return Vector2(left.z - right.z, left.y - right.y)


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


## Every clip, cut, in place, looped or not; the tuck pose; and the aim. Wall Run is laid
## against its wall, measured from its bones.
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
		if clip == RunnerAnimation.Clip.WALL_RUN:
			_wall_run = _lay_against_the_wall(made, skeleton)
		if clip in STRIDES:
			_measure_the_stride(clip, made, skeleton)
		if clip in LOOPED:
			made.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(_clip_name(clip), made)
	var aim: Animation = _in_place(_take(PISTOL_IDLE), Vector2.ZERO, false, hips_rest)
	aim.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(AIM, aim)
	return library


## Measures how `clip`, in place, is laid against its wall, from where its bones are at each
## key of its hips, across, the way the runner faces; and moves its hips across at each
## key as the measure says, so that its bone nearest the wall stays on one plane.
static func _lay_against_the_wall(clip: Animation, skeleton: Skeleton3D) -> WallRunPose:
	var hips: int = clip.find_track(
		NodePath("%s:%s" % [SKELETON, HIPS]), Animation.TYPE_POSITION_3D
	)
	var frames: Array[PackedFloat32Array] = []
	for key: int in clip.track_get_key_count(hips):
		var across: PackedFloat32Array = []
		for place: Vector3 in bone_places(clip, clip.track_get_key_time(hips, key), skeleton):
			across.append((FACING * place).x)
		frames.append(across)
	var feet: PackedInt32Array = [skeleton.find_bone(LEFT_FOOT), skeleton.find_bone(RIGHT_FOOT)]
	var pose: WallRunPose = WallRunPose.measure(frames, feet, skeleton.find_bone(HEAD))
	var towards: Vector3 = FACING.inverse() * Vector3.RIGHT * WallRunPose.way(pose.side)
	for key: int in pose.shifts.size():
		var place: Vector3 = clip.track_get_key_value(hips, key)
		clip.track_set_key_value(hips, key, place + towards * pose.shifts[key])
	return pose


## Measures the stride of `clip`, in place: when its left foot touches the ground (its
## ankle or its toe at its lowest), and its pose at each phase of its stride from then.
static func _measure_the_stride(
	clip: RunnerAnimation.Clip, made: Animation, skeleton: Skeleton3D
) -> void:
	var left: int = skeleton.find_bone(LEFT_FOOT)
	var toe: int = skeleton.find_bone(LEFT_TOE)
	var right: int = skeleton.find_bone(RIGHT_FOOT)
	var ankles: PackedFloat32Array = []
	var toes: PackedFloat32Array = []
	var poses: PackedVector2Array = []
	for sample: int in STRIDE_SAMPLES:
		var places: PackedVector3Array = bone_places(
			made, made.length * sample / STRIDE_SAMPLES, skeleton
		)
		ankles.append(places[left].y)
		toes.append(places[toe].y)
		poses.append(_stride_pose(places[left], places[right]))
	var feet: Array[PackedFloat32Array] = [ankles, toes]
	var touchdown: float = Stride.touchdown(feet)
	_touchdowns[clip] = touchdown * made.length
	_cycle_lengths[clip] = made.length
	var first: int = roundi(touchdown * STRIDE_SAMPLES)
	var cycle: PackedVector2Array = []
	for sample: int in STRIDE_SAMPLES:
		cycle.append(poses[(first + sample) % STRIDE_SAMPLES])
	_cycles[clip] = cycle


## Where every bone of `skeleton` is, in its space, at `time` of `clip`: a bone that the
## clip does not move stays as at rest.
static func bone_places(clip: Animation, time: float, skeleton: Skeleton3D) -> PackedVector3Array:
	var poses: Array[Transform3D] = []
	for bone: int in skeleton.get_bone_count():
		poses.append(skeleton.get_bone_rest(bone))
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone < 0:
			continue
		if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			poses[bone].basis = Basis(clip.rotation_track_interpolate(track, time))
		elif clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			poses[bone].origin = clip.position_track_interpolate(track, time)
	var places: PackedVector3Array = []
	places.resize(skeleton.get_bone_count())
	var bones: Array[int] = []
	bones.append_array(skeleton.get_parentless_bones())
	var index: int = 0
	while index < bones.size():
		var bone: int = bones[index]
		var parent: int = skeleton.get_bone_parent(bone)
		if parent >= 0:
			poses[bone] = poses[parent] * poses[bone]
		places[bone] = poses[bone].origin
		bones.append_array(skeleton.get_bone_children(bone))
		index += 1
	return places


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
