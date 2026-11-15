extends GutTest
## What touches on screen catches (docs/specs/chase-tag-reach.md): the reaches of the game's
## tuning are those of the body, measured on the bones of the character, and the hand of a
## touch lands on the runner it reaches for only once the level observes the catch, stopping
## short of it otherwise. Where the fingertips go is checked without the files; with them,
## the bones are measured and a cat touches a mouse in the real physics, in real time, so
## that the frames between two steps show the hand as a screen would.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const TUNING: String = "res://game/core/movement_tuning.tres"
## How far a tuned reach may be from the one measured on the bones, in m.
const MEASURE_TOLERANCE: float = 0.03
## How far under or beyond the reach of a touch the mouse stands, in m: a little.
const A_LITTLE: float = 0.02
## How close to the body of the mouse the fingertips of a hand that lands on it come, and how
## far from it, at the least, those of a hand that stops before it stay, in m.
const ON_THE_BODY: float = 0.03
const BEFORE_THE_BODY: float = 0.01
## The steps a touch is played for: past its reach and the blend of the arm.
const TOUCH_STEPS: int = 20
## The steps a runner stands before it touches: long enough to have landed from its start.
const STANDING_STEPS: int = 45
const SPEED_UP: int = 10
const PRECISION: float = 0.0001
## How many times the search for the farthest a mouse is in reach halves its interval.
const HALVINGS: int = 40


func test_the_reaches_are_those_of_the_body() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	assert_gt(tuning.tag_touch_reach, 0.0, "a touch reaches beyond the body")
	assert_gt(tuning.tag_dive_reach, tuning.tag_touch_reach, "a dive reaches farther")
	var character: RunnerCharacter = RunnerCharacter.create(RunnerCharacter.MODEL, tuning)
	if character == null:
		pass_test("without the Mixamo files, the bones are not measured")
		return
	add_child_autofree(character)

	var measured: Dictionary[StringName, float] = character.measured_reaches()

	assert_eq(measured.size(), 5, "the reaches of the touch and of the dive, and where from")
	for name: StringName in measured:
		var tuned: float = tuning.get(name)
		gut.p("%s: %.3f m measured on the bones, %.3f m tuned" % [name, measured[name], tuned])
		assert_almost_eq(tuned, measured[name], MEASURE_TOLERANCE, String(name))


func test_the_hand_rests_only_on_a_catch() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var radius: float = tuning.capsule_radius
	var reach: TagReach = TagReach.touch(tuning)
	var cat: PackedVector3Array = _axis(Vector3.ZERO, tuning.capsule_height, tuning)
	# Where the fingertips go, a mouse standing or sliding ahead along -Z, a little within the
	# reach of the game, then a little beyond.
	for height: float in [tuning.capsule_height, tuning.slide_capsule_height]:
		var limit: float = _farthest_in_reach(reach, cat, height, tuning)
		for apart: float in [limit - A_LITTLE, limit + A_LITTLE]:
			var context: String = "%.1f m high, %.2f m ahead: " % [height, apart]
			var mouse: PackedVector3Array = _axis(Vector3.FORWARD * apart, height, tuning)
			var in_reach: bool = reach.reaches(cat, mouse, radius, Vector3.FORWARD)
			assert_eq(in_reach, apart < limit, context + "the game's reach")
			var from: Vector3 = TouchHand.shoulder_towards(Vector3.ZERO, mouse, tuning)
			var caught: Vector3 = TouchHand.fingertips_target(from, reach.arm, mouse, radius, true)
			var missed: Vector3 = TouchHand.fingertips_target(from, reach.arm, mouse, radius, false)
			assert_lte(from.distance_to(caught), reach.arm + PRECISION, context + "never beyond")
			assert_gt(_off(missed, mouse, radius), 0.0, context + "missed: short of the body")
			if in_reach:
				assert_almost_eq(_off(caught, mouse, radius), 0.0, PRECISION, context + "on it")
			else:
				assert_gt(_off(caught, mouse, radius), 0.0, context + "out of reach: short of it")
	# With the files, in the real physics: once caught, once just out of reach.
	var touch_reach: float = tuning.tag_touch_reach
	var landed: float = await _nearest_fingertips(touch_reach - A_LITTLE)
	if is_nan(landed):
		pass_test("without the Mixamo files, where the fingertips go alone")
		return
	var stopped: float = await _nearest_fingertips(touch_reach + A_LITTLE)
	gut.p("the fingertips: %.3f m from the body caught, %.3f m missed" % [landed, stopped])
	assert_lte(absf(landed), ON_THE_BODY, "the hand lands on the mouse caught")
	assert_gt(stopped, BEFORE_THE_BODY, "and stops before the mouse missed")


## How far `point` is from the body of the capsule of axis `axis` and radius `radius`.
func _off(point: Vector3, axis: PackedVector3Array, radius: float) -> float:
	var on: Vector3 = Geometry3D.get_closest_point_to_segment(point, axis[0], axis[1])
	return point.distance_to(on) - radius


## How far ahead of the cat of axis `cat`, along -Z, a mouse `height` m high can stand for its
## body to be within the reach `reach` (TagReach.gap), found by halving.
func _farthest_in_reach(
	reach: TagReach, cat: PackedVector3Array, height: float, tuning: MovementTuning
) -> float:
	var near: float = 0.0
	var far: float = 4.0
	for halving: int in HALVINGS:
		var middle: float = (near + far) / 2.0
		var mouse: PackedVector3Array = _axis(Vector3.FORWARD * middle, height, tuning)
		if reach.gap(cat, mouse, tuning.capsule_radius) <= 0.0:
			near = middle
		else:
			far = middle
	return near


## The nearest the fingertips of a cat come to the body of a mouse standing `gap` m ahead of
## it, from body to body, as the cat touches, the catch observed as the level does
## (Chase.catches): in m from the surface of its capsule, measured at every frame the arm
## reaches fully; NAN without the files.
func _nearest_fingertips(gap: float) -> float:
	var scene: Node3D = Node3D.new()
	add_child_autofree(scene)
	_block(scene, Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var cat: Player = PLAYER_SCENE.instantiate() as Player
	var mouse: Player = PLAYER_SCENE.instantiate() as Player
	scene.add_child(cat)
	scene.add_child(mouse)
	var skeletons: Array[Node] = cat.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return NAN
	var tuning: MovementTuning = cat.tuning
	cat.teleport(Transform3D.IDENTITY)
	var ahead: Vector3 = Vector3.FORWARD * (2.0 * tuning.capsule_radius + gap)
	mouse.teleport(Transform3D(Basis.IDENTITY, ahead))
	mouse.held = true
	cat.motor.can_tag = true
	cat.tag_target = mouse
	# It stands long enough to have landed from its start, then touches.
	var intents: ScriptedIntentSource = ScriptedIntentSource.new()
	cat.intent_source = intents.hold(Vector3.ZERO, false, STANDING_STEPS).gesture(Vector3.ZERO)
	# Faster than real time while it stands: the same steps of 1/60 s, sooner.
	var ticks: int = Engine.physics_ticks_per_second
	var pace: float = Engine.time_scale
	Engine.physics_ticks_per_second = ticks * SPEED_UP
	Engine.time_scale = pace * SPEED_UP
	for step: int in STANDING_STEPS:
		await get_tree().physics_frame
	Engine.physics_ticks_per_second = ticks
	Engine.time_scale = pace
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	var nearest: Array[float] = [INF]
	for node: Node in skeleton.find_children("*", "TwoBoneIK3D", false, false):
		var arm: TwoBoneIK3D = node as TwoBoneIK3D
		var fingertip: int = skeleton.find_bone(
			RunnerCharacter.FINGERTIPS[skeleton.get_bone_name(arm.get_end_bone(0))]
		)
		arm.modification_processed.connect(
			func() -> void:
				if arm.influence >= 1.0:
					var seen: Transform3D = skeleton.get_global_transform_interpolated()
					var tip: Vector3 = seen * skeleton.get_bone_global_pose(fingertip).origin
					var axis: PackedVector3Array = Player.axis_of(mouse)
					var on: Vector3 = Geometry3D.get_closest_point_to_segment(tip, axis[0], axis[1])
					var off: float = tip.distance_to(on) - Player.radius_of(mouse)
					nearest[0] = minf(nearest[0], off)
		)
	for step: int in TOUCH_STEPS:
		await get_tree().physics_frame
		if Chase.catches(cat, mouse):
			cat.catch_the_target()
	return nearest[0]


## The axis of an upright capsule `height` m high of the runners of `tuning`, its feet at
## `feet`.
func _axis(feet: Vector3, height: float, tuning: MovementTuning) -> PackedVector3Array:
	var radius: float = tuning.capsule_radius
	return PackedVector3Array([feet + Vector3.UP * radius, feet + Vector3.UP * (height - radius)])


func _block(parent: Node3D, size: Vector3, center: Vector3) -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = box
	var block: StaticBody3D = StaticBody3D.new()
	block.add_child(collider)
	block.position = center
	parent.add_child(block)
