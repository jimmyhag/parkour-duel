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
## place: the motor alone moves the runner. Every change shows through a blend, frame by
## frame, even one cut short by another (Crossfade, docs/specs/animation-polish.md), and
## the keys of the clips are followed on curves, not on straight lines from one to the
## next. Along a wall it runs, and the runner rolls its visible body against the wall as its
## run allows (WallRunPose). In a vault and a mantle, its hands are put on the real top
## (HandPlant) by inverse kinematics (TwoBoneIK3D) while the clip plants them; in a vault,
## its body follows the real height of the obstacle (docs/specs/vault.md). Presentation
## only: nothing the runner observes depends on it.

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
	RunnerAnimation.Clip.LEDGE_PULL_UP: "res://assets/mixamo/ledge_pull_up.fbx",
	RunnerAnimation.Clip.VAULT_ONE_HAND: "res://assets/mixamo/vault_one_hand.fbx",
	RunnerAnimation.Clip.VAULT_TWO_HANDS: "res://assets/mixamo/vault_two_hands.fbx",
	RunnerAnimation.Clip.TUCK: "res://assets/mixamo/backflip.fbx",
}
const PISTOL_IDLE: String = "res://assets/mixamo/pistol_idle.fbx"
## The part of each clip that is played, from its start to its end, in s (an end of 0: to
## the end of the file): the part of Falling To Roll that rolls, of Ledge Pull Up that
## hoists, of the vaults from the take-off to the landing, of Landing from the contact with
## the ground. A state that lasts less than its part at the fastest pace the tuning allows
## plays its first part only.
const CUTS: Dictionary[RunnerAnimation.Clip, Vector2] = {
	RunnerAnimation.Clip.JUMP: Vector2(0.05, 0.42),
	RunnerAnimation.Clip.LANDING: Vector2(0.35, 0.8),
	RunnerAnimation.Clip.HARD_LANDING: Vector2(0.0, 0.5),
	RunnerAnimation.Clip.FALLING_TO_ROLL: Vector2(0.3, 1.1),
	RunnerAnimation.Clip.RUNNING_SLIDE: Vector2(0.1, 0.8),
	RunnerAnimation.Clip.LEDGE_PULL_UP: Vector2(1.7, 2.33),
	RunnerAnimation.Clip.VAULT_ONE_HAND: Vector2(0.3, 0.93),
	RunnerAnimation.Clip.VAULT_TWO_HANDS: Vector2(0.2, 0.9),
}
## The hands, and of each one the upper arm and the forearm it hangs from, with the axis of
## the forearm that points out of the bend of the elbow (measured on the clips: +X for the
## left one, -X for the right one).
const LEFT_HAND: String = "mixamorig7_LeftHand"
const RIGHT_HAND: String = "mixamorig7_RightHand"
const UPPER_ARMS: Dictionary[String, String] = {
	LEFT_HAND: "mixamorig7_LeftArm",
	RIGHT_HAND: "mixamorig7_RightArm",
}
const FOREARMS: Dictionary[String, String] = {
	LEFT_HAND: "mixamorig7_LeftForeArm",
	RIGHT_HAND: "mixamorig7_RightForeArm",
}
const ELBOWS_OUT: Dictionary[String, SkeletonModifier3D.SecondaryDirection] = {
	LEFT_HAND: SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_X,
	RIGHT_HAND: SkeletonModifier3D.SECONDARY_DIRECTION_MINUS_X,
}
## The part of the clips of a vault and of a mantle where they plant hands on the top, in s
## of their files, and those that plant both hands there (the others, the left one).
const PLANTS: Dictionary[RunnerAnimation.Clip, Vector2] = {
	RunnerAnimation.Clip.VAULT_ONE_HAND: Vector2(0.43, 0.7),
	RunnerAnimation.Clip.VAULT_TWO_HANDS: Vector2(0.57, 0.7),
	RunnerAnimation.Clip.LEDGE_PULL_UP: Vector2(1.7, 2.33),
}
const BOTH_HANDS: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.VAULT_TWO_HANDS,
	RunnerAnimation.Clip.LEDGE_PULL_UP,
]
## How long a hand takes to go onto the top before the clip plants it, and to leave it, in
## s of the clip; how far above the top the wrist of a hand lying on it is, in m; and how
## far out of the bend of the arm the point the elbow points to is, in m.
const PLANT_RAMP: float = 0.15
const WRIST_HEIGHT: float = 0.03
const POLE_DISTANCE: float = 0.3
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
## The clips of the run along a wall, whose bones tell how the rolled body lies against it.
const WALL_RUN_CLIPS: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.RUNNING,
	RunnerAnimation.Clip.SPRINT,
]
## The clips whose rise of the hips is a move the motor already makes: their hips stay at
## the height of a standing body. The others keep the height of their hips (a slide, a
## roll, a crouch), not their way forward.
const RAISED: Array[RunnerAnimation.Clip] = [
	RunnerAnimation.Clip.JUMP,
	RunnerAnimation.Clip.LEDGE_PULL_UP,
]
## The animation of a Mixamo file, the root bone of its skeleton, the first bone of the
## upper body, the bone whose bend shows the tuck, the head and feet, and the toe that
## tells, with the left foot, when a stride starts, in the tracks of the files.
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
const RIG: Array[String] = [
	HIPS,
	SPINE,
	KNEE,
	HEAD,
	LEFT_FOOT,
	RIGHT_FOOT,
	LEFT_TOE,
	LEFT_HAND,
	RIGHT_HAND,
]
## The turn that makes the model, which faces +Z, face -Z as the runner does.
const FACING: Basis = Basis(Vector3.UP, PI)
## The rate at which the clips are sampled, as in the files.
const FRAMES_PER_SECOND: float = 30.0
const LIBRARY: StringName = &"runner"
const AIM: String = "pistol_idle"
## The nodes of the animation tree, and their parameters: the locomotion (Idle blended with
## the clips that stride, at a phase and a number of strides a second), each other clip
## (started again, at its pace), the blend of them all (one node per state after the
## first, how much it shows over those before it), and the aim.
const LOCOMOTION_NODE: StringName = &"locomotion"
const MOVING_NODE: StringName = &"moving"
const RESUME_NODE: StringName = &"resume"
const STRIDE_NODE: StringName = &"stride"
const AIM_NODE: StringName = &"aim"
const PACE: String = "parameters/%s_pace/scale"
const START: String = "parameters/%s_start/seek_request"
const MIX: String = "parameters/%s_mix/blend_amount"
const LOCOMOTION_AMOUNT: StringName = &"parameters/locomotion/blend_amount"
const MOVING_POSITION: StringName = &"parameters/moving/blend_position"
const RESUME_REQUEST: StringName = &"parameters/resume/seek_request"
const STRIDE_SCALE: StringName = &"parameters/stride/scale"
const STRIDE_POSITION: String = "parameters/moving/%s/current_position"
const AIM_AMOUNT: StringName = &"parameters/aim/blend_amount"
const CLIP_POSITION: String = "parameters/%s/current_position"
## The colour a tint adds over the character, as a share of it.
const TINT_SHARE: float = 0.5

## The clips of every character, made once from the files, and the character's scene,
## kept: loading it again for every runner would take a second each time.
static var _library: AnimationLibrary = null
static var _scenes: Dictionary[String, PackedScene] = {}
## Of each clip that strides, measured as it is made: when its left foot touches the
## ground, in s, the length of its cycle, in s, and its pose at each phase of its stride
## from then (how far the left foot is ahead of the right one, and how much higher).
static var _touchdowns: Dictionary[RunnerAnimation.Clip, float] = {}
static var _cycle_lengths: Dictionary[RunnerAnimation.Clip, float] = {}
static var _cycles: Dictionary[RunnerAnimation.Clip, PackedVector2Array] = {}
## Where the bones of each clip of the run along a wall go (WALL_RUN_CLIPS), measured as
## the clips are made, in the frame of the model facing -Z, across and up, before it is put
## to its size.
static var _run_places: Array[PackedVector2Array] = []
## Of each clip that plants hands (PLANTS), measured as it is made: the height of its
## planted wrists as it plants them, in the space of the skeleton, before it is put to its
## size: the height of the top it shows.
static var _plant_heights: Dictionary[RunnerAnimation.Clip, float] = {}

var _model: Node3D
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _hold: AimHold
## The top the hands go on in the vault or the mantle shown, or the last one (null before
## the first); the clip that plants them, where it is in its file, in s, and whether it has
## yet to start again (its seek not played yet, it shows where it was before); where each
## hand planted goes, once the clip has planted it, the last time of the clip it was within
## the reach of its arm, and whether its arm let go of it since, out of reach; the height of
## the top each clip shows, at this size, in m; and of each hand, its inverse kinematics and
## the nodes it reaches for and points its elbow to.
var _plant: HandPlant = null
var _plant_clip: RunnerAnimation.Clip = RunnerAnimation.Clip.VAULT_ONE_HAND
var _clip_time: float = 0.0
var _clip_restarting: bool = false
var _planted: Dictionary[String, Vector3] = {}
var _held: Dictionary[String, float] = {}
var _let_go: Dictionary[String, bool] = {}
## The hands whose target was put at the frame before.
var _aimed: Dictionary[String, bool] = {}
var _tops: Dictionary[RunnerAnimation.Clip, float] = {}
var _arms: Dictionary[String, TwoBoneIK3D] = {}
var _reached: Dictionary[String, Node3D] = {}
var _elbow_poles: Dictionary[String, Node3D] = {}
## The tuning whose speeds of the strides it follows.
var _tuning: MovementTuning
## Its size, and how its run lies against a wall at that size.
var _scale: float = 1.0
var _wall_run: WallRunPose
## The states of the tree in the order of the blend (the locomotion first), and how much
## each one shows.
var _states: Array[StringName] = []
var _fade: Crossfade = Crossfade.new()
## The state of the tree asked for last.
var _shown_state: StringName = &""
## The blend of the locomotion at the last two fixed steps: how much the clips that stride
## show over Idle, and where on their axis; shown in between at every frame.
var _walk_before: Vector2 = Vector2.ZERO
var _walk_now: Vector2 = Vector2.ZERO
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


## Before the arms reach for the top: lifts the body of a vault to the real height of its
## obstacle, and puts where each planted hand reaches and where its elbow points
## (RunnerCharacter._put_the_hands_on_the_top).
class HandsOnTheTop:
	extends SkeletonModifier3D

	var character: RunnerCharacter

	func _init(of: RunnerCharacter) -> void:
		character = of

	func _process_modification_with_delta(_delta: float) -> void:
		character._put_the_hands_on_the_top()


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


## Shows `animation`: a new clip blends in, in its blend time, started again if it was not
## shown any more, the locomotion at the phase of the stride nearest the pose shown; the
## clip plays at its speed, or fitted to its duration; the locomotion blends its clips as
## weighed; the aim blends in and out.
func play(animation: RunnerAnimation) -> void:
	var state: StringName = _state_of(animation.clip)
	var fresh: bool = _fade.go_to(state, animation.blend_time)
	_shown_state = state
	if fresh:
		if state == LOCOMOTION_NODE:
			_tree.set(RESUME_REQUEST, _resume_phase(animation.locomotion))
		else:
			_tree.set(START % state, 0.0)
	if state == LOCOMOTION_NODE:
		_walk(animation, fresh)
	else:
		var length: float = _library.get_animation(state).length
		var pace: float = animation.speed
		if animation.duration > 0.0:
			pace = RunnerAnimation.fitted_pace(length, animation.duration, _tuning)
		_tree.set(PACE % state, pace)
		if animation.clip in PLANTS:
			_follow_the_plant(animation.clip, fresh)
	_aim_wanted = 1.0 if animation.aiming else 0.0
	_aim_blend_time = animation.blend_time


## Puts the hands on `plant` in the vault or the mantle that starts: the top the runner
## observed.
func plant_hands(plant: HandPlant) -> void:
	_plant = plant
	_planted.clear()
	_held.clear()
	_let_go.clear()


## Where the character's body is put against the wall of a wall run, in the frame of the
## runner facing -Z (WallRunPose): rolled by `roll`, the wall `wall_distance` m from the
## side of the capsule, its run weighed as the locomotion `locomotion` (RunnerAnimation)
## weighs Running and Sprint.
func placed_against_the_wall(
	roll: float, wall_distance: float, locomotion: PackedFloat32Array
) -> Transform3D:
	var weights: PackedFloat32Array = []
	for clip: RunnerAnimation.Clip in WALL_RUN_CLIPS:
		var index: int = RunnerAnimation.LOCOMOTION.find(clip)
		weights.append(locomotion[index] if index < locomotion.size() else 0.0)
	return _wall_run.placed(roll, wall_distance, weights, _tuning)


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


## At every frame shown, before the tree plays: the blend of the states and the aim move
## on, frame by frame, and the blend of the locomotion is shown between the last two fixed
## steps.
func _process(delta: float) -> void:
	var walk: Vector2 = _walk_before.lerp(_walk_now, Engine.get_physics_interpolation_fraction())
	_tree.set(LOCOMOTION_AMOUNT, walk.x)
	_tree.set(MOVING_POSITION, walk.y)
	_fade.advance(delta)
	var shown: float = _fade.weight(_states[0])
	for index: int in range(1, _states.size()):
		var state: StringName = _states[index]
		var weight: float = _fade.weight(state)
		shown += weight
		_tree.set(MIX % state, weight / shown if shown > 0.0 else 0.0)
	if _aim_blend_time <= 0.0:
		_aim = _aim_wanted
	else:
		_aim = move_toward(_aim, _aim_wanted, delta / _aim_blend_time)
	_tree.set(AIM_AMOUNT, _aim)
	_hold.weight = _aim


## The clip `clip`, which plants hands, is shown: from its start when it starts again
## (`fresh`), its hands not planted yet.
func _follow_the_plant(clip: RunnerAnimation.Clip, fresh: bool) -> void:
	if fresh or clip != _plant_clip:
		_plant_clip = clip
		_clip_restarting = true
		_planted.clear()
		_held.clear()
		_let_go.clear()


## While the clip that plants hands is asked for, fully, and as much as it shows while it
## goes: the body of a vault is lifted
## to the real height of its obstacle, and each hand the clip plants reaches for the top
## (HandPlant), from a little before the clip plants it to a little after it leaves it, then
## stays where it was planted, until the body has gone out of the reach of its arm; its elbow
## keeps the bend of the clip. Everything is measured where the body is shown: between two
## fixed steps, in between (the arms reach for their targets there).
func _put_the_hands_on_the_top() -> void:
	for hand: String in _arms:
		_arms[hand].influence = 0.0
	if _plant == null:
		return
	var plant_state: StringName = _state_of(_plant_clip)
	var shown: float = 1.0 if _shown_state == plant_state else _fade.weight(plant_state)
	if shown <= 0.0:
		_aimed.clear()
		return
	_read_the_clip_time()
	var seen: Transform3D = _skeleton.get_global_transform_interpolated()
	if _plant_clip not in RAISED:
		_lift_to_the_top(seen, shown)
	for hand: String in _planting_hands(_plant_clip):
		var wrist: Vector3 = seen * _bone_pose(hand).origin
		var shoulder: Vector3 = seen * _bone_pose(UPPER_ARMS[hand]).origin
		var elbow: Vector3 = seen * _bone_pose(FOREARMS[hand]).origin
		var reached: Vector3 = _planted.get(hand, _plant.target(wrist) + Vector3.UP * WRIST_HEIGHT)
		if _clip_time >= PLANTS[_plant_clip].x:
			_planted[hand] = reached
		var reach: float = shoulder.distance_to(elbow) + elbow.distance_to(wrist)
		if _planted.has(hand) and not _let_go.has(hand):
			if shoulder.distance_to(reached) <= reach:
				_held[hand] = _clip_time
			else:
				_let_go[hand] = true
		var released: float = INF
		if _let_go.has(hand):
			released = _held.get(hand, PLANTS[_plant_clip].x)
		var share: float = _share_planted(released) * shown
		# An arm reaches for where its target was put at the frame before: not before it was.
		_arms[hand].influence = share if _aimed.has(hand) else 0.0
		if share <= 0.0:
			_aimed.erase(hand)
			continue
		_aimed[hand] = true
		_reached[hand].global_position = reached
		var out: Vector3 = (elbow - (shoulder + wrist) / 2.0).normalized()
		_elbow_poles[hand].global_position = elbow + out * POLE_DISTANCE


## Where the clip that plants hands is in its file, as the tree shows it: at its start while
## its seek has not played yet.
func _read_the_clip_time() -> void:
	var played: float = _tree.get(CLIP_POSITION % _clip_name(_plant_clip))
	if _clip_restarting and is_zero_approx(played):
		_clip_restarting = false
	_clip_time = CUTS[_plant_clip].x + (0.0 if _clip_restarting else played)


## Lifts the hips so that the feet stand on the ground the vault left, plus, as the clip
## goes to the plant of its hands and back, the difference between the real height of the
## obstacle and the height of the top the clip shows; as much as the clip shows (`shown`).
## The character is `seen` there.
func _lift_to_the_top(seen: Transform3D, shown: float) -> void:
	var cut: Vector2 = CUTS[_plant_clip]
	var plant: Vector2 = PLANTS[_plant_clip]
	var share: float = 1.0
	if _clip_time < plant.x:
		share = smoothstep(cut.x, plant.x, _clip_time)
	elif _clip_time > plant.y:
		share = 1.0 - smoothstep(plant.y, cut.y, _clip_time)
	var top: float = _plant.top - _plant.ground - _tops[_plant_clip]
	var feet: float = get_global_transform_interpolated().origin.y
	var rise: float = (_plant.ground + share * top - feet) * shown
	var hips: int = _skeleton.find_bone(HIPS)
	var up: Vector3 = seen.basis.inverse() * Vector3.UP * rise
	_skeleton.set_bone_pose_position(hips, _skeleton.get_bone_pose_position(hips) + up)


## The hands `clip` plants on the top: both, or the left one.
static func _planting_hands(clip: RunnerAnimation.Clip) -> PackedStringArray:
	if clip in BOTH_HANDS:
		return [LEFT_HAND, RIGHT_HAND]
	return [LEFT_HAND]


## Where the bone `bone` is in the space of the skeleton, as the clips and the modifiers
## before put it.
func _bone_pose(bone: String) -> Transform3D:
	return _skeleton.get_bone_global_pose(_skeleton.find_bone(bone))


## How much a hand the clip plants is on the top, from 0 to 1: from a little before the clip
## plants it to a little after it leaves the top, or after the last time of the clip it was
## within the reach of its arm, `released`, if its arm let go of it (INF: it did not).
func _share_planted(released: float) -> float:
	var plant: Vector2 = PLANTS[_plant_clip]
	var leaves: float = minf(plant.y, released)
	if _clip_time < plant.x:
		return clampf(1.0 - (plant.x - _clip_time) / PLANT_RAMP, 0.0, 1.0)
	if _clip_time <= leaves:
		return 1.0
	return clampf(1.0 - (_clip_time - leaves) / PLANT_RAMP, 0.0, 1.0)


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
	_model.basis = FACING * Basis.from_scale(Vector3.ONE * _scale)
	_model.position.y = -bounds.position.y * _scale
	if _library == null:
		_library = _make_library(_skeleton)
	var runs: Array[PackedVector2Array] = []
	for run: PackedVector2Array in _run_places:
		var places: PackedVector2Array = []
		for place: Vector2 in run:
			places.append(Vector2(place.x, place.y - bounds.position.y) * _scale)
		runs.append(places)
	_wall_run = WallRunPose.measure(runs)
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
	for clip: RunnerAnimation.Clip in _plant_heights:
		_tops[clip] = (_plant_heights[clip] - bounds.position.y) * _scale
	_skeleton.add_child(HandsOnTheTop.new(self))
	for hand: String in UPPER_ARMS:
		_add_the_arm(hand)


## The inverse kinematics of the arm of `hand`, off until a clip plants it, and the nodes, in
## the world, it reaches for and points its elbow to.
func _add_the_arm(hand: String) -> void:
	var arm: TwoBoneIK3D = TwoBoneIK3D.new()
	arm.influence = 0.0
	_skeleton.add_child(arm)
	arm.set_setting_count(1)
	arm.set_root_bone_name(0, UPPER_ARMS[hand])
	arm.set_middle_bone_name(0, FOREARMS[hand])
	arm.set_end_bone_name(0, hand)
	arm.set_pole_direction(0, ELBOWS_OUT[hand])
	_arms[hand] = arm
	_reached[hand] = _world_point()
	arm.set_target_node(0, arm.get_path_to(_reached[hand]))
	_elbow_poles[hand] = _world_point()
	arm.set_pole_node(0, arm.get_path_to(_elbow_poles[hand]))


## A node of the character placed in the world, as it is told, at every frame.
func _world_point() -> Node3D:
	var point: Node3D = Node3D.new()
	point.top_level = true
	point.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(point)
	return point


func _meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for node: Node in _skeleton.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


## The tree that plays the clips: the locomotion and one state per other clip, each one
## started again when it comes from nothing and at its pace, blended one over the other as
## much as each one shows; then the aim over the upper body (the spine and all it carries).
func _make_blend_tree() -> AnimationNodeBlendTree:
	var blend_tree: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	_add_the_locomotion(blend_tree)
	_states = [LOCOMOTION_NODE]
	var blended: StringName = LOCOMOTION_NODE
	for clip: RunnerAnimation.Clip in RunnerAnimation.Clip.values():
		if clip in RunnerAnimation.LOCOMOTION:
			continue
		var name: String = _clip_name(clip)
		blend_tree.add_node(name, _clip_node(clip))
		var start: StringName = StringName(name + "_start")
		blend_tree.add_node(start, AnimationNodeTimeSeek.new())
		blend_tree.connect_node(start, 0, name)
		var pace: StringName = StringName(name + "_pace")
		blend_tree.add_node(pace, AnimationNodeTimeScale.new())
		blend_tree.connect_node(pace, 0, start)
		var mix: StringName = StringName(name + "_mix")
		blend_tree.add_node(mix, AnimationNodeBlend2.new())
		blend_tree.connect_node(mix, 0, blended)
		blend_tree.connect_node(mix, 1, pace)
		blended = mix
		_states.append(StringName(name))
	var aim_clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
	aim_clip.animation = "%s/%s" % [LIBRARY, AIM]
	blend_tree.add_node(AIM, aim_clip)
	var aim: AnimationNodeBlend2 = AnimationNodeBlend2.new()
	aim.filter_enabled = true
	for bone: int in _upper_body():
		aim.set_filter_path(NodePath("%s:%s" % [SKELETON, _skeleton.get_bone_name(bone)]), true)
	blend_tree.add_node(AIM_NODE, aim)
	blend_tree.connect_node(AIM_NODE, 0, blended)
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
## on their axis (where they were when they no longer show), as many strides a second as
## keep the feet up with the ground; from there, without a blend from before, when it
## comes back from nothing (`fresh`).
func _walk(animation: RunnerAnimation, fresh: bool) -> void:
	var weights: PackedFloat32Array = _locomotion_weights(animation)
	var moving: float = 1.0 - weights[0]
	var position: float = 0.0
	for point: int in STRIDES.size():
		position += point * weights[point + 1]
	var blend: Vector2 = Vector2(moving, position / moving if moving > 0.0 else _walk_now.y)
	_walk_before = blend if fresh else _walk_now
	_walk_now = blend
	_tree.set(LOCOMOTION_AMOUNT, blend.x)
	_tree.set(MOVING_POSITION, blend.y)
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


## Every clip, cut, in place, looped or not; the tuck pose; and the aim. The stride of the
## clips that stride, and where the bones of the run go, measured from their bones.
static func _make_library(skeleton: Skeleton3D) -> AnimationLibrary:
	var hips_rest: Vector3 = skeleton.get_bone_rest(skeleton.find_bone(HIPS)).origin
	var library: AnimationLibrary = AnimationLibrary.new()
	_run_places = []
	for clip: RunnerAnimation.Clip in WALL_RUN_CLIPS:
		assert(clip in CLIP_FILES, "every clip of the run along a wall is made")
	for clip: RunnerAnimation.Clip in CLIP_FILES:
		var source: Animation = _take(CLIP_FILES[clip])
		var made: Animation
		if clip == RunnerAnimation.Clip.TUCK:
			made = _pose_at(source, _tightest_tuck(source), hips_rest)
		else:
			var cut: Vector2 = CUTS.get(clip, Vector2.ZERO)
			made = in_place(source, cut, clip in RAISED, hips_rest, clip in LOOPED)
		if clip in STRIDES:
			_measure_the_stride(clip, made, skeleton)
		if clip in WALL_RUN_CLIPS:
			_run_places.append(_places_across(made, skeleton))
		if clip in PLANTS:
			_plant_heights[clip] = _planted_height(clip, made, skeleton)
		library.add_animation(_clip_name(clip), made)
	var aim: Animation = in_place(_take(PISTOL_IDLE), Vector2.ZERO, false, hips_rest, true)
	library.add_animation(AIM, aim)
	return library


## The height of the wrists `clip` plants, made into `made`, as it plants them, in the
## space of `skeleton`: the height of the top it shows.
static func _planted_height(
	clip: RunnerAnimation.Clip, made: Animation, skeleton: Skeleton3D
) -> float:
	var places: PackedVector3Array = bone_places(made, PLANTS[clip].x - CUTS[clip].x, skeleton)
	var height: float = 0.0
	for hand: String in _planting_hands(clip):
		height += places[skeleton.find_bone(hand)].y
	return height / _planting_hands(clip).size()


## Where every bone of `skeleton` goes in `clip`, at evenly spaced instants of it, across
## and up, in the frame of the model facing -Z, as the files size it.
static func _places_across(clip: Animation, skeleton: Skeleton3D) -> PackedVector2Array:
	var places: PackedVector2Array = []
	for sample: int in STRIDE_SAMPLES:
		var time: float = clip.length * sample / STRIDE_SAMPLES
		for place: Vector3 in bone_places(clip, time, skeleton):
			var shown: Vector3 = FACING * place
			places.append(Vector2(shown.x, shown.y))
	return places


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


## The part `cut` of `source` (from its start to its end, in s; an end of 0: to the end of
## the file), sampled again, its hips kept over the feet at `rest`: their way forward and
## aside removed (a clip `looped` keeps their sway forward and back), and their rise too
## when `raised`. Its keys are followed on curves: a bone keeps its speed through a key
## instead of turning sharply at it. A clip `looped` plays again from its start once at its
## end.
static func in_place(
	source: Animation, cut: Vector2, raised: bool, rest: Vector3, looped: bool
) -> Animation:
	var start: float = cut.x
	var end: float = source.length if cut.y <= 0.0 else minf(cut.y, source.length)
	var made: Animation = Animation.new()
	made.length = end - start
	if looped:
		made.loop_mode = Animation.LOOP_LINEAR
	var hips: NodePath = NodePath("%s:%s" % [SKELETON, HIPS])
	for track: int in source.get_track_count():
		var type: Animation.TrackType = source.track_get_type(track)
		var path: NodePath = source.track_get_path(track)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D:
			continue
		var copy: int = made.add_track(type)
		made.track_set_path(copy, path)
		made.track_set_interpolation_type(copy, Animation.INTERPOLATION_CUBIC)
		var frames: int = ceili(made.length * FRAMES_PER_SECOND - 0.001)
		# A loop has no key at its end: its first key follows its last one, and a key there,
		# the same pose again, would stall its bones on the curve as it loops.
		var keys: int = frames if looped else frames + 1
		# A loop keeps the sway of its hips forward and back about their place at rest, its
		# way forward over a whole cycle removed: its planted foot goes back as steadily as the
		# file has it still, the left one as the right one.
		var forward: float = 0.0
		var middle: float = 0.0
		if path == hips and type == Animation.TYPE_POSITION_3D and looped:
			var first: float = source.position_track_interpolate(track, start).z
			forward = (source.position_track_interpolate(track, end).z - first) / made.length
			for frame: int in keys:
				var at: float = start + frame / FRAMES_PER_SECOND
				middle += source.position_track_interpolate(track, at).z - forward * (at - start)
			middle /= keys
		for frame: int in keys:
			var time: float = minf(start + frame / FRAMES_PER_SECOND, end)
			if type == Animation.TYPE_ROTATION_3D:
				var turn: Quaternion = source.rotation_track_interpolate(track, time)
				made.rotation_track_insert_key(copy, time - start, turn)
				continue
			var place: Vector3 = source.position_track_interpolate(track, time)
			if path == hips:
				var sway: float = 0.0
				if looped:
					sway = place.z - forward * (time - start) - middle
				place = Vector3(rest.x, rest.y if raised else place.y, rest.z + sway)
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
