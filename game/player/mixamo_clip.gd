class_name MixamoClip
extends RefCounted
## The clips of the Mixamo files as the character (RunnerCharacter) plays them: read from a
## file, cut and kept in place, or held at one pose; and where the bones of a clip go.


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
static func take(path: String) -> Animation:
	var scene: PackedScene = load(path) as PackedScene
	var root: Node = scene.instantiate()
	var player: AnimationPlayer = root.get_node("AnimationPlayer") as AnimationPlayer
	var take: Animation = player.get_animation(RunnerCharacter.TAKE)
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
	var hips: NodePath = NodePath("%s:%s" % [RunnerCharacter.SKELETON, RunnerCharacter.HIPS])
	for track: int in source.get_track_count():
		var type: Animation.TrackType = source.track_get_type(track)
		var path: NodePath = source.track_get_path(track)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D:
			continue
		var copy: int = made.add_track(type)
		made.track_set_path(copy, path)
		made.track_set_interpolation_type(copy, Animation.INTERPOLATION_CUBIC)
		var frames: int = ceili(made.length * RunnerCharacter.FRAMES_PER_SECOND - 0.001)
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
				var at: float = start + frame / RunnerCharacter.FRAMES_PER_SECOND
				middle += source.position_track_interpolate(track, at).z - forward * (at - start)
			middle /= keys
		for frame: int in keys:
			var time: float = minf(start + frame / RunnerCharacter.FRAMES_PER_SECOND, end)
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
static func tightest_tuck(source: Animation) -> float:
	var knee: int = source.find_track(
		NodePath("%s:%s" % [RunnerCharacter.SKELETON, RunnerCharacter.KNEE]),
		Animation.TYPE_ROTATION_3D
	)
	var tightest: float = 0.0
	var most: float = -1.0
	var frames: int = floori(source.length * RunnerCharacter.FRAMES_PER_SECOND)
	for frame: int in frames + 1:
		var time: float = frame / RunnerCharacter.FRAMES_PER_SECOND
		var bend: float = source.rotation_track_interpolate(knee, time).get_angle()
		if bend > most:
			most = bend
			tightest = time
	return tightest


## The pose of `source` at `time`, held: every bone as it is then, but the hips upright
## and over the feet, so that the turn of the flip is left to the body that carries it.
static func pose_at(source: Animation, time: float, rest: Vector3) -> Animation:
	var made: Animation = Animation.new()
	made.length = 1.0 / RunnerCharacter.FRAMES_PER_SECOND
	var hips: NodePath = NodePath("%s:%s" % [RunnerCharacter.SKELETON, RunnerCharacter.HIPS])
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
