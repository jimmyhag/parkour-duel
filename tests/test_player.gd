extends GutTest
## The player layer: inputs turned into intents, the capsule that follows the state of
## the runner, the third-person camera, and the visible body without the Mixamo files.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const GHOST_SCENE: PackedScene = preload("res://game/player/ghost.tscn")
## Where no character is: a project without the Mixamo files.
const NO_CHARACTER: String = "res://assets/mixamo/no_character_here.fbx"
const MOVE_FORWARD: StringName = &"move_forward"
const SLIDE: StringName = &"slide"
const FORWARD: Vector3 = Vector3.FORWARD
const TOLERANCE: float = 0.001
const SETTLE_FRAMES: int = 20
const WORLD_LAYER: int = 1
const STEP: float = 1.0 / 60.0
## A few steps: enough to land on the floor under the feet, or to stand up.
const FEW_STEPS: int = 5
## How far a beam hung over a runner goes, before and after it.
const BEAM_REACH: float = 1.0


func after_each() -> void:
	Input.action_release(MOVE_FORWARD)
	Input.action_release(SLIDE)


func test_forward_goes_where_the_camera_looks() -> void:
	var player: Player = _add_player()
	player.camera_rig.turn(PI / 2.0, 0.0)
	var camera: Camera3D = player.camera_rig.get_node("Camera3D") as Camera3D
	var looking: Vector3 = -camera.global_basis.z
	looking.y = 0.0
	looking = looking.normalized()

	Input.action_press(MOVE_FORWARD)
	var intent: MoveIntent = player.intent_source.next_intent()

	assert_almost_eq(looking.x, -1.0, TOLERANCE, "a quarter turn to the left looks along -X")
	assert_almost_eq(intent.direction.x, looking.x, TOLERANCE)
	assert_almost_eq(intent.direction.z, looking.z, TOLERANCE)
	assert_eq(intent.direction.y, 0.0, "the intent stays horizontal")


func test_pressing_the_slide_is_read_in_the_intent() -> void:
	var player: Player = _add_player()
	var pressed_steps: Array[int] = []
	var held_steps: Array[int] = []
	var steps: Array[int] = [0]
	player.stepped.connect(
		func(intent: MoveIntent) -> void:
			if intent.slide_pressed:
				pressed_steps.append(steps[0])
			if intent.slide_held:
				held_steps.append(steps[0])
			steps[0] += 1
	)
	await _between_two_steps()

	Input.action_press(SLIDE)
	await _between_two_steps()
	Input.action_release(SLIDE)
	await _between_two_steps()

	assert_eq(pressed_steps.size(), 1, "pressed at one step only")
	assert_gt(held_steps.size(), 1, "held for several steps")
	if pressed_steps.size() == 1 and held_steps.size() > 1:
		assert_eq(pressed_steps[0], held_steps[0], "the press is the first step it is held")
		var held_span: int = held_steps[-1] - held_steps[0] + 1
		assert_eq(held_span, held_steps.size(), "then it stays held, without a gap")
		assert_gt(pressed_steps[0], 0, "nothing was read before the press")
		assert_lt(held_steps[-1], steps[0] - 1, "and nothing is read once it is released")


func test_the_capsule_lowers_while_sliding_and_rises_after() -> void:
	_add_box(Vector3(20.0, 1.0, 80.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	var bystander: Player = _add_player()
	bystander.position.x = 5.0
	var tuning: MovementTuning = player.tuning
	var standing: float = tuning.capsule_height
	var low: float = tuning.slide_capsule_height
	await _wait_steps(FEW_STEPS)
	assert_almost_eq(_capsule_height(player), standing, TOLERANCE, "standing at first")

	var run_steps: int = ceili(tuning.top_speed / (tuning.ground_acceleration * STEP))
	var moves: ScriptedIntentSource = ScriptedIntentSource.new()
	player.intent_source = moves.hold(FORWARD, false, run_steps).slide(FORWARD, FEW_STEPS)
	await _wait_steps(run_steps + FEW_STEPS - 1)

	assert_eq(player.motor.state, RunnerMotor.State.SLIDING, "it slides")
	assert_almost_eq(_capsule_height(player), low, TOLERANCE, "its collision shape is low")
	assert_almost_eq(_capsule_foot(player), 0.0, TOLERANCE, "with its foot where it was")
	assert_almost_eq(_mesh_height(player), low, TOLERANCE, "and so is the capsule one sees")
	assert_true(player.is_on_floor(), "it stays on the floor")
	assert_almost_eq(_capsule_height(bystander), standing, TOLERANCE, "another runner stands")

	# A beam too low to stand under, hung over the runner as its slide is released: it
	# rises once it is out from under it, not before.
	var clearance: float = (low + standing) / 2.0
	var over: Vector3 = player.global_position + Vector3.UP * (clearance + 0.5)
	_add_box(Vector3(2.0, 1.0, 2.0 * BEAM_REACH), over)
	await _wait_steps(FEW_STEPS)
	assert_eq(player.motor.state, RunnerMotor.State.SLIDING, "it stays low under the beam")
	assert_almost_eq(_capsule_height(player), low, TOLERANCE, "and so does its collision shape")
	var slowest: float = tuning.slide_stop_speed * STEP
	await _wait_steps(ceili((BEAM_REACH + tuning.capsule_radius) / slowest))

	assert_eq(player.motor.state, RunnerMotor.State.GROUNDED, "it stood up")
	assert_almost_eq(_capsule_height(player), standing, TOLERANCE, "its shape is tall again")
	assert_almost_eq(_capsule_foot(player), 0.0, TOLERANCE, "its foot still on the floor")
	assert_almost_eq(_mesh_height(player), standing, TOLERANCE, "and so is what one sees")
	assert_true(player.is_on_floor())


func test_the_camera_moves_closer_when_a_wall_passes_behind_the_runner() -> void:
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	var camera: Camera3D = player.camera_rig.get_node("Camera3D") as Camera3D
	await wait_physics_frames(SETTLE_FRAMES)
	var free_distance: float = camera.global_position.z - player.global_position.z
	assert_almost_eq(free_distance, player.tuning.camera_distance, 0.05, "nothing in the way")

	var wall_face: float = player.tuning.camera_distance / 2.0
	_add_box(Vector3(10.0, 10.0, 1.0), Vector3(0.0, 5.0, wall_face + 0.5))
	await wait_physics_frames(SETTLE_FRAMES)

	assert_lt(camera.global_position.z, wall_face, "it stays on the runner's side of the wall")
	var clearance: float = wall_face - camera.global_position.z
	var radius: float = player.tuning.camera_collision_radius
	assert_almost_eq(clearance, radius, 0.01, "at the radius of its sphere from the wall")
	assert_gt(camera.global_position.z, player.global_position.z, "and stays behind the runner")


func test_without_the_files_the_capsule_stays() -> void:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.character_model = NO_CHARACTER
	add_child_autofree(player)
	var ghost: Ghost = GHOST_SCENE.instantiate() as Ghost
	ghost.character_model = NO_CHARACTER
	add_child_autofree(ghost)
	await wait_physics_frames(FEW_STEPS)

	var visual: Node3D = player.get_node("Visual") as Node3D
	var body: MeshInstance3D = visual.get_node("Body") as MeshInstance3D
	var visor: MeshInstance3D = visual.get_node("Visor") as MeshInstance3D
	assert_eq(visual.get_child_count(), 2, "the visible body: the capsule and its visor")
	assert_true(body.is_visible_in_tree(), "the capsule is seen")
	assert_true(visor.is_visible_in_tree(), "its visor is seen")
	assert_almost_eq(_mesh_height(player), player.tuning.capsule_height, TOLERANCE, "standing")
	var capsule: CapsuleMesh = body.mesh as CapsuleMesh
	assert_almost_eq(capsule.radius, player.tuning.capsule_radius, TOLERANCE, "of its radius")
	assert_eq(ghost.get_child_count(), 2, "the ghost: the capsule and its visor")
	for part: String in ["Body", "Visor"]:
		var seen: MeshInstance3D = ghost.get_node(part) as MeshInstance3D
		assert_true(seen.is_visible_in_tree(), "the ghost's %s is seen" % part)


func test_a_character_of_another_rig_keeps_the_capsule() -> void:
	var rig: Array[String] = RunnerCharacter.RIG
	assert_true(RunnerCharacter.fits(_model_with_bones(rig)), "the bones of Ch08: it fits")
	var other: Array[String] = []
	for bone: String in rig:
		other.append(bone.replace("mixamorig7_", "mixamorig1_"))
	assert_false(RunnerCharacter.fits(_model_with_bones(other)), "another prefix: the capsule")
	assert_false(RunnerCharacter.fits(Node3D.new()), "no skeleton: the capsule")


## A model as an imported character is: a skeleton with these bones, under its root.
func _model_with_bones(bones: Array[String]) -> Node3D:
	var model: Node3D = Node3D.new()
	var skeleton: Skeleton3D = Skeleton3D.new()
	skeleton.name = RunnerCharacter.SKELETON
	for bone: String in bones:
		skeleton.add_bone(bone)
	model.add_child(skeleton)
	autofree(model)
	return model


func _add_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


## Waits for fixed steps to start: what follows runs before the nodes of that step.
func _wait_steps(steps: int) -> void:
	for i: int in steps:
		await get_tree().physics_frame


## Lets a few fixed steps pass, then waits to be out of them: where a key press comes
## from the player, between two steps.
func _between_two_steps() -> void:
	await _wait_steps(FEW_STEPS)
	await get_tree().process_frame


func _capsule(player: Player) -> CollisionShape3D:
	return player.get_node("CollisionShape3D") as CollisionShape3D


func _capsule_height(player: Player) -> float:
	return (_capsule(player).shape as CapsuleShape3D).height


## The altitude of the lowest point of the capsule, above the runner's feet.
func _capsule_foot(player: Player) -> float:
	return _capsule(player).position.y - _capsule_height(player) / 2.0


func _mesh_height(player: Player) -> float:
	var body: MeshInstance3D = player.get_node("Visual/Body") as MeshInstance3D
	return (body.mesh as CapsuleMesh).height


func _add_box(size: Vector3, center: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	body.position = center
	add_child_autofree(body)
