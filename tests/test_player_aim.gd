extends GutTest
## Aiming in the player layer: the aim and the shot read from the mouse and the gamepad,
## the camera over the shoulder, what the runner observes under the reticle, and time,
## which aiming never slows down.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const WORLD_LAYER: int = 1
const TARGETS_LAYER: int = 3
const FEW_STEPS: int = 5
## Enough frames for the camera to go over the shoulder.
const SETTLE_FRAMES: int = 12
const TOLERANCE: float = 0.001
## A target straight ahead of a runner at the origin, its face this far, and its
## identity.
const TARGET_FACE: float = 19.5
const TARGET_ID: int = 5
const GAME_ACTIONS: Array[StringName] = [&"aim", &"shoot"]


func after_each() -> void:
	_send(_mouse(MOUSE_BUTTON_RIGHT, false))
	_send(_mouse(MOUSE_BUTTON_LEFT, false))
	_send(_trigger(JOY_AXIS_TRIGGER_LEFT, 0.0))
	_send(_trigger(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	for action: StringName in GAME_ACTIONS:
		Input.action_release(action)


func test_aiming_does_not_slow_down_time() -> void:
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0), WORLD_LAYER)
	var player: Player = _add_player()
	var time_scale: float = Engine.time_scale
	var ticks: int = Engine.physics_ticks_per_second
	await _wait_steps(FEW_STEPS)
	assert_false(player.motor.is_aiming(), "a runner in the game, not aiming")

	for press: InputEvent in [
		_mouse(MOUSE_BUTTON_RIGHT, true), _trigger(JOY_AXIS_TRIGGER_LEFT, 1.0)
	]:
		_send(press)
		await _wait_steps(FEW_STEPS)
		assert_true(player.motor.is_aiming(), "the runner aims")
		assert_eq(Engine.time_scale, time_scale, "the time scale of the engine does not change")
		assert_eq(Engine.physics_ticks_per_second, ticks, "nor the fixed steps per second")
		_send(_mouse(MOUSE_BUTTON_RIGHT, false))
		_send(_trigger(JOY_AXIS_TRIGGER_LEFT, 0.0))
		await _wait_steps(FEW_STEPS)
		assert_false(player.motor.is_aiming(), "released, it no longer aims")
	assert_eq(Engine.time_scale, time_scale, "after the aim neither")


func test_aim_and_shoot_are_read_from_the_mouse_and_the_gamepad() -> void:
	var player: Player = _add_player()
	var source: IntentSource = player.intent_source
	var presses: Dictionary[String, Array] = {
		"mouse": [_mouse(MOUSE_BUTTON_RIGHT, true), _mouse(MOUSE_BUTTON_LEFT, true)],
		"gamepad": [_trigger(JOY_AXIS_TRIGGER_LEFT, 1.0), _trigger(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
	}
	var releases: Dictionary[String, Array] = {
		"mouse": [_mouse(MOUSE_BUTTON_RIGHT, false), _mouse(MOUSE_BUTTON_LEFT, false)],
		"gamepad": [_trigger(JOY_AXIS_TRIGGER_LEFT, 0.0), _trigger(JOY_AXIS_TRIGGER_RIGHT, 0.0)],
	}
	for device: String in presses:
		var aim_press: InputEvent = presses[device][0]
		var shot_press: InputEvent = presses[device][1]
		var nothing: MoveIntent = source.next_intent()
		assert_false(nothing.aim_held, device + ": nothing held, no aim")
		_send(aim_press)
		await get_tree().process_frame
		var aiming: MoveIntent = source.next_intent()
		assert_true(aiming.aim_held, device + ": the aim is held")
		assert_false(aiming.shoot_pressed, device + ": no shot yet")
		_send(shot_press)
		var shooting: MoveIntent = source.next_intent()
		assert_true(shooting.aim_held, device + ": still aiming")
		assert_true(shooting.shoot_pressed, device + ": the shot is pressed")
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().process_frame
		assert_false(source.next_intent().shoot_pressed, device + ": once only")
		for release: InputEvent in releases[device]:
			_send(release)
		await get_tree().process_frame
		assert_false(source.next_intent().aim_held, device + ": released")


func test_aiming_puts_the_camera_over_the_shoulder() -> void:
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0), WORLD_LAYER)
	var player: Player = _add_player()
	var camera: Camera3D = player.camera_rig.get_node("Camera3D") as Camera3D
	var normal_fov: float = camera.fov
	await wait_physics_frames(SETTLE_FRAMES)
	assert_almost_eq(camera.global_position.x, 0.0, TOLERANCE, "behind the back")

	player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, 1000)
	await wait_physics_frames(SETTLE_FRAMES)

	var tuning: MovementTuning = player.tuning
	assert_almost_eq(camera.fov, tuning.aim_camera_fov, TOLERANCE, "a narrower field")
	var right: float = camera.global_position.x - player.global_position.x
	assert_almost_eq(right, tuning.aim_camera_offset, TOLERANCE, "over the right shoulder")
	assert_gt(camera.global_position.z, player.global_position.z, "still behind the runner")

	player.intent_source = IntentSource.new()
	await wait_physics_frames(SETTLE_FRAMES)
	assert_almost_eq(camera.fov, normal_fov, TOLERANCE, "back to the usual field")
	assert_almost_eq(camera.global_position.x, 0.0, TOLERANCE, "and behind the back")


func test_the_runner_observes_what_is_under_the_reticle() -> void:
	_add_box(Vector3(20.0, 1.0, 60.0), Vector3(0.0, -0.5, 0.0), WORLD_LAYER)
	var player: Player = _add_player()
	var look_height: float = player.tuning.camera_look_height
	var target: StaticBody3D = _add_box(
		Vector3(6.0, 6.0, 1.0), Vector3(0.0, look_height, -TARGET_FACE - 0.5), TARGETS_LAYER
	)
	target.set_meta(SabotageTarget.META, TARGET_ID)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_eq(player.aim_facts.target, SabotageTarget.NO_TARGET, "not aiming: nothing")

	player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, 1000)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_eq(player.aim_facts.target, TARGET_ID, "aiming at a target: its identity")
	var distance: float = player.aim_facts.distance
	var offset: float = player.tuning.aim_camera_offset
	var expected: float = Vector2(TARGET_FACE, offset).length()
	assert_almost_eq(distance, expected, 0.05, "and how far it is from the eyes")

	# A block, not a target, across the line: it hides the target.
	_add_box(Vector3(6.0, 6.0, 1.0), Vector3(0.0, look_height, -10.0), WORLD_LAYER)
	await wait_physics_frames(FEW_STEPS)
	assert_eq(player.aim_facts.target, SabotageTarget.NO_TARGET, "a block in the way: nothing")
	assert_almost_eq(player.aim_facts.distance, 9.5, 0.05, "the block is seen, and is no target")

	player.intent_source = IntentSource.new()
	await wait_physics_frames(FEW_STEPS)
	assert_eq(player.aim_facts.target, SabotageTarget.NO_TARGET, "no longer aiming: nothing")


func _add_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


func _add_box(size: Vector3, center: Vector3, layer: int) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 0
	body.set_collision_layer_value(layer, true)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	body.position = center
	add_child_autofree(body)
	return body


func _wait_steps(steps: int) -> void:
	for i: int in steps:
		await get_tree().physics_frame


## Gives an input event to the engine as the device would, at once.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _mouse(button: MouseButton, pressed: bool) -> InputEvent:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _trigger(axis: JoyAxis, value: float) -> InputEvent:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
