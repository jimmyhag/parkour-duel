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


func test_the_reaches_are_those_of_the_body() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	assert_gt(tuning.tag_touch_reach, 0.0, "a touch reaches beyond the body")
	assert_gt(tuning.tag_dive_reach, tuning.tag_touch_reach, "a dive reaches farther")
	var character: RunnerCharacter = RunnerCharacter.create(RunnerCharacter.MODEL, tuning)
	if character == null:
		pass_test("without the Mixamo files, the bones are not measured")
		return
	add_child_autofree(character)

	var touch: float = character.touch_reach()
	var dive: float = character.dive_reach()

	gut.p("measured on the bones: the touch %.3f m, the dive %.3f m" % [touch, dive])
	assert_almost_eq(tuning.tag_touch_reach, touch, MEASURE_TOLERANCE, "the reach of the arm")
	assert_almost_eq(tuning.tag_dive_reach, dive, MEASURE_TOLERANCE, "the reach of the dive")


func test_the_hand_rests_only_on_a_catch() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var radius: float = tuning.capsule_radius
	var reach: float = tuning.tag_touch_reach
	var from: Vector3 = Vector3(0.0, 1.4, 0.0)
	# Where the fingertips go, the mouse ahead along -Z, at a gap from body to body.
	for gap: float in [reach - A_LITTLE, reach + A_LITTLE]:
		var context: String = "a gap of %.2f m: " % gap
		var mouse: PackedVector3Array = _axis(Vector3.FORWARD * (2.0 * radius + gap), tuning)
		var caught: Vector3 = TouchHand.fingertips_target(from, radius, reach, mouse, radius, true)
		var missed: Vector3 = TouchHand.fingertips_target(from, radius, reach, mouse, radius, false)
		var surface: float = -(2.0 * radius + gap - radius)
		assert_lte(-caught.z, radius + reach + PRECISION, context + "never beyond the reach")
		assert_lt(-missed.z, -surface - TouchHand.SHORT_OF_THE_BODY + PRECISION, context)
		if gap <= reach:
			assert_almost_eq(caught.z, surface, PRECISION, context + "caught: on the body")
	# With the files, in the real physics: once caught, once just out of reach.
	var landed: float = await _nearest_fingertips(reach - A_LITTLE)
	if is_nan(landed):
		pass_test("without the Mixamo files, where the fingertips go alone")
		return
	var stopped: float = await _nearest_fingertips(reach + A_LITTLE)
	gut.p("the fingertips: %.3f m from the body caught, %.3f m missed" % [landed, stopped])
	assert_lte(absf(landed), ON_THE_BODY, "the hand lands on the mouse caught")
	assert_gt(stopped, BEFORE_THE_BODY, "and stops before the mouse missed")


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


## The axis of an upright capsule of the runners of `tuning`, its feet at `feet`.
func _axis(feet: Vector3, tuning: MovementTuning) -> PackedVector3Array:
	var radius: float = tuning.capsule_radius
	return PackedVector3Array(
		[feet + Vector3.UP * radius, feet + Vector3.UP * (tuning.capsule_height - radius)]
	)


func _block(parent: Node3D, size: Vector3, center: Vector3) -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = box
	var block: StaticBody3D = StaticBody3D.new()
	block.add_child(collider)
	block.position = center
	parent.add_child(block)
