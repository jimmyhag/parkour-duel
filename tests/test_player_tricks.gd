extends GutTest
## The drawing of a trick in the player layer, with the real inputs: while the trick
## button is held, the mouse and the right stick draw instead of turning the camera, and
## what they draw reaches the motor in the intent. Key, mouse, button and stick events go
## through the input map of project.godot, as a device would send them.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const WORLD_LAYER: int = 1
const TOLERANCE: float = 0.0001
## A few steps: enough for an event to be read, or for a runner to settle.
const FEW_STEPS: int = 5
## Steps of a run up to the top speed.
const RUN_STEPS: int = 25
## A stroke of the mouse, in pixels per step, and its steps.
const MOUSE_STROKE: Vector2 = Vector2(0.0, 40.0)
const STROKE_STEPS: int = 6

var _intents: Array[MoveIntent] = []


func after_each() -> void:
	_send(_key(KEY_F, false))
	_send(_key(KEY_W, false))
	_send(_key(KEY_SPACE, false))
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, false))
	_send(_stick(JOY_AXIS_RIGHT_X, 0.0))
	_intents.clear()


func test_holding_the_trick_button_freezes_the_camera() -> void:
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)
	var rig: CameraRig = player.camera_rig
	var before: Vector3 = rig.rotation
	_send(_key(KEY_F, true))
	await _wait_steps(1)

	# The mouse, then the right stick, while the button is held.
	for step: int in STROKE_STEPS:
		_send(_mouse(Vector2(40.0, 0.0)))
		await _wait_steps(1)
	assert_almost_eq(rig.rotation, before, Vector3.ONE * TOLERANCE, "the mouse does not turn it")
	var drawn: TrickRecipe = _intents[-1].trick_recipe
	assert_true(drawn != null and drawn.flip == TrickRecipe.Flip.SIDE_FLIP, "the mouse draws")
	_send(_stick(JOY_AXIS_RIGHT_X, 1.0))
	await _wait_steps(FEW_STEPS)
	await get_tree().process_frame
	assert_almost_eq(rig.rotation, before, Vector3.ONE * TOLERANCE, "nor does the stick")

	# Released, the stick still pushed: the camera turns again.
	_send(_key(KEY_F, false))
	await _wait_steps(FEW_STEPS)
	await get_tree().process_frame

	assert_ne(rig.rotation.y, before.y, "the button released, the stick turns the camera")


func test_releasing_the_button_on_the_ground_starts_nothing() -> void:
	_add_box(Vector3(20.0, 1.0, 200.0), Vector3(0.0, -0.5, -80.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)
	_send(_key(KEY_W, true))
	await _wait_steps(RUN_STEPS)
	assert_true(player.is_on_floor(), "a runner on the ground")

	# A backflip drawn with the mouse, the pad going down, on the ground.
	_send(_key(KEY_F, true))
	for step: int in STROKE_STEPS:
		_send(_mouse(MOUSE_STROKE))
		await _wait_steps(1)
	await _wait_steps(FEW_STEPS)
	var drawn: TrickRecipe = _intents[-1].trick_recipe
	assert_true(drawn != null and drawn.flip == TrickRecipe.Flip.BACKFLIP, "a backflip drawn")
	_send(_key(KEY_F, false))
	await _wait_steps(FEW_STEPS)

	assert_true(player.is_on_floor(), "still on the ground")
	assert_null(player.motor.current_trick(), "nothing starts")

	# Forgotten: a jump, then a press and a release in the air without drawing, start the
	# trick of the context (a front flip, running forward), not the backflip.
	_send(_key(KEY_SPACE, true))
	await _wait_steps(2)
	_send(_key(KEY_F, true))
	await _wait_steps(2)
	_send(_key(KEY_F, false))
	await _wait_steps(2)
	assert_false(player.is_on_floor(), "in the air")
	var trick: AirTrick = player.motor.current_trick()
	assert_not_null(trick, "a trick starts")
	if trick != null:
		assert_true(trick.recipe.context, "the trick of the context")
		assert_eq(trick.name(), "FRONT FLIP", "running forward: a front flip")


func _add_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.stepped.connect(_on_stepped)
	return player


func _on_stepped(intent: MoveIntent) -> void:
	_intents.append(intent)


func _wait_steps(steps: int) -> void:
	for i: int in steps:
		await get_tree().physics_frame


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


## Gives an input event to the engine as the device would, at once.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(physical: Key, pressed: bool) -> InputEvent:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = pressed
	return event


func _button(button: JoyButton, pressed: bool) -> InputEvent:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _stick(axis: JoyAxis, value: float) -> InputEvent:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


## The mouse moved by `pixels` on the screen.
func _mouse(pixels: Vector2) -> InputEvent:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = pixels
	event.screen_relative = pixels
	return event
