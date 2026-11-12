extends GutTest
## The player layer: inputs turned into intents, and the third-person camera.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const MOVE_FORWARD: StringName = &"move_forward"
const TOLERANCE: float = 0.001
const SETTLE_FRAMES: int = 20
const WORLD_LAYER: int = 1


func after_each() -> void:
	Input.action_release(MOVE_FORWARD)


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

	# What the camera shows starts at its near plane, a few centimetres in front of it:
	# that plane is what must stay on the runner's side of the wall. (With Jolt the
	# camera's own origin ends about a millimetre inside the wall's surface.)
	var near_plane: float = camera.global_position.z - camera.near
	assert_lt(near_plane, wall_face, "the camera does not see through the wall")
	assert_gt(camera.global_position.z, player.global_position.z, "and stays behind the runner")


func _add_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


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
