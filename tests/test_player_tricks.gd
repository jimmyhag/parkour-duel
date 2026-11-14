extends ReplayTest
## The drawing of a trick in the player layer, with the real inputs: while the trick
## button is held, the mouse and the right stick draw instead of turning the camera, and
## what they draw reaches the motor in the intent; released on the ground, the button
## jumps into the trick drawn. Key, mouse, button and stick events go through the input
## map of project.godot, as a device would send them. Faster than real time with the same
## fixed step of 1/60 s (see ReplayTest).

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
## Steps of a roll of the right stick, of a flight, and how high above the floor the
## landing is posed.
const ROLL_STEPS: int = 24
const FLIGHT_STEPS: int = 60
const SETTLE_STEPS: int = 30
## Steps of a hand at rest that validate a reading (0.1 s), and a little more.
const VALIDATE_STEPS: int = 8
const POSE_HEIGHT: float = 0.6
## How close to the height of the tuning a full jump tops, and how high above the floor
## a runner is dropped to land hard.
const JUMP_HEIGHT_TOLERANCE: float = 0.1
const DROP_HEIGHT: float = 7.0

var _intents: Array[MoveIntent] = []


func after_each() -> void:
	_send(_key(KEY_F, false))
	_send(_key(KEY_W, false))
	_send(_key(KEY_SPACE, false))
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, false))
	_send(_stick(JOY_AXIS_RIGHT_X, 0.0))
	_send(_stick(JOY_AXIS_RIGHT_Y, 0.0))
	for button: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B]:
		_send(_button(button, false))
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
	# Headless, the mouse cannot be captured: what a captured mouse does is asked of the
	# camera directly.
	rig.move_with_the_mouse(_mouse(Vector2(40.0, 0.0)) as InputEventMouseMotion, true)
	assert_almost_eq(rig.rotation, before, Vector3.ONE * TOLERANCE, "not even captured")
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
	_send(_stick(JOY_AXIS_RIGHT_X, 0.0))
	await _wait_steps(1)
	var turned: float = rig.rotation.y
	rig.move_with_the_mouse(_mouse(Vector2(40.0, 0.0)) as InputEventMouseMotion, true)
	assert_ne(rig.rotation.y, turned, "and so does the mouse")


func test_a_circle_alone_is_a_spin() -> void:
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)

	# On the gamepad: LB held, the right stick rolled once round its rim, then let go.
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, true))
	await _wait_steps(1)
	for deflection: Vector2 in GestureHand.roll(Vector2.RIGHT, 360.0, ROLL_STEPS):
		_send(_stick(JOY_AXIS_RIGHT_X, deflection.x))
		_send(_stick(JOY_AXIS_RIGHT_Y, deflection.y))
		await _wait_steps(1)
	_send(_stick(JOY_AXIS_RIGHT_X, 0.0))
	_send(_stick(JOY_AXIS_RIGHT_Y, 0.0))
	await _wait_steps(VALIDATE_STEPS)

	var drawn: TrickRecipe = _intents[-1].trick_recipe
	assert_true(_intents[-1].trick_held, "LB held")
	assert_not_null(drawn, "the stick drew something")
	if drawn != null:
		assert_eq(drawn.name(), "360", "a spin")
	assert_true(player.drawing().is_validated(), "validated, the trick that will start")


func test_without_a_gesture_the_trick_of_the_context_starts() -> void:
	# With the real inputs of the gamepad: LB pressed and released in the air, posed with B.
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	var paid: Array[AirTrick] = []
	player.stepped.connect(
		func(_intent: MoveIntent) -> void:
			for event: RunnerEvent in player.motor.events:
				if event.trick != null:
					paid.append(event.trick)
	)
	# Long enough to stand: the release of the test before may have started a trick, and
	# its crash lasts a hard landing.
	await _wait_steps(SETTLE_STEPS)
	assert_eq(player.motor.state, RunnerMotor.State.GROUNDED, "a runner at a stop")
	paid.clear()

	# A jump on A, LB pressed and released in the air, B as the ground comes.
	_send(_button(JOY_BUTTON_A, true))
	await _wait_steps(2)
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, true))
	await _wait_steps(1)
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, false))
	await _wait_steps(2)
	var trick: AirTrick = player.motor.current_trick()
	assert_not_null(trick, "a trick starts")
	if trick != null:
		assert_true(trick.recipe.context, "the trick of the context")
		assert_eq(trick.name(), "BACKFLIP", "at a stop: a backflip")
	var posed: bool = false
	for step: int in FLIGHT_STEPS:
		await _wait_steps(1)
		if not posed and player.velocity.y < 0.0 and player.global_position.y < POSE_HEIGHT:
			_send(_button(JOY_BUTTON_B, true))
			posed = true
		if posed and player.is_on_floor():
			break
	_send(_button(JOY_BUTTON_B, false))
	_send(_button(JOY_BUTTON_A, false))
	await _wait_steps(2)

	assert_eq(paid.size(), 1, "posed with B: the landing pays it")


func test_releasing_the_button_on_the_ground_jumps_and_starts_the_trick() -> void:
	_add_box(Vector3(20.0, 1.0, 200.0), Vector3(0.0, -0.5, -80.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)
	_send(_key(KEY_W, true))
	await _wait_steps(RUN_STEPS)
	assert_true(player.is_on_floor(), "a runner on the ground")

	# On the keyboard and the mouse: a backflip drawn on the ground, the pad going down,
	# then F released, the jump never pressed.
	_send(_key(KEY_F, true))
	for step: int in STROKE_STEPS:
		_send(_mouse(MOUSE_STROKE))
		await _wait_steps(1)
	await _wait_steps(FEW_STEPS)
	var drawn: TrickRecipe = _intents[-1].trick_recipe
	assert_true(drawn != null and drawn.flip == TrickRecipe.Flip.BACKFLIP, "a backflip drawn")
	_send(_key(KEY_F, false))
	await _wait_steps(2)
	_assert_a_trick_jump(player, "F released")

	# A full jump: the runner rises to the height of a jump held up to its top.
	var apex: float = await _apex_of_the_flight(player)
	assert_almost_eq(apex, player.tuning.jump_height, JUMP_HEIGHT_TOLERANCE, "a full jump")
	_send(_key(KEY_W, false))
	await _wait_steps(SETTLE_STEPS)
	assert_eq(player.motor.state, RunnerMotor.State.GROUNDED, "back on its feet")

	# On the gamepad: LB held, the right stick flicked down and back, then LB released.
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, true))
	await _wait_steps(1)
	_send(_stick(JOY_AXIS_RIGHT_Y, 1.0))
	await _wait_steps(STROKE_STEPS)
	_send(_stick(JOY_AXIS_RIGHT_Y, 0.0))
	await _wait_steps(FEW_STEPS)
	drawn = _intents[-1].trick_recipe
	assert_true(drawn != null and drawn.flip == TrickRecipe.Flip.BACKFLIP, "a backflip drawn")
	_send(_button(JOY_BUTTON_LEFT_SHOULDER, false))
	await _wait_steps(2)
	_assert_a_trick_jump(player, "LB released")
	apex = await _apex_of_the_flight(player)
	assert_almost_eq(apex, player.tuning.jump_height, JUMP_HEIGHT_TOLERANCE, "a full jump")


func test_releasing_the_button_where_no_jump_is_allowed_starts_nothing() -> void:
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)

	# Dropped from high above the height of a roll, a backflip drawn on the way down with
	# the mouse, F still held as it lands hard.
	player.teleport(Transform3D(Basis.IDENTITY, Vector3(0.0, DROP_HEIGHT, 0.0)))
	_send(_key(KEY_F, true))
	for step: int in STROKE_STEPS:
		_send(_mouse(MOUSE_STROKE))
		await _wait_steps(1)
	var drawn: TrickRecipe = _intents[-1].trick_recipe
	assert_true(drawn != null and drawn.flip == TrickRecipe.Flip.BACKFLIP, "a backflip drawn")
	for step: int in FLIGHT_STEPS:
		if player.motor.state == RunnerMotor.State.HARD_LANDING:
			break
		await _wait_steps(1)
	assert_eq(player.motor.state, RunnerMotor.State.HARD_LANDING, "a runner in a hard landing")

	_send(_key(KEY_F, false))
	await _wait_steps(1)
	assert_ne(player.motor.state, RunnerMotor.State.RISING, "it does not jump")
	assert_null(player.motor.current_trick(), "nothing starts")
	await _wait_steps(FEW_STEPS)
	assert_true(player.is_on_floor(), "still on the ground")

	# Forgotten: once on its feet, a jump, then a press and a release in the air without
	# drawing, start the trick of the context (a backflip, at a stop), not the one drawn.
	await _wait_steps(SETTLE_STEPS)
	assert_eq(player.motor.state, RunnerMotor.State.GROUNDED, "back on its feet")
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
		assert_eq(trick.name(), "BACKFLIP", "at a stop: a backflip")


func test_the_pad_follows_the_sensitivity_of_the_camera() -> void:
	# Decision 26 of docs/specs/trick-gestures.md: the same stroke, drawn with half the
	# pixels under a sensitivity twice as high, is read the same; and the same pixels under
	# it draw twice as far.
	var traces: Array[PackedVector2Array] = []
	var reads: Array[String] = []
	var sensitivities: Array[float] = [1.0, 2.0, 2.0]
	var pixels: Array[float] = [1.0, 0.5, 1.0]
	for attempt: int in sensitivities.size():
		var player: Player = _add_player(sensitivities[attempt])
		await _wait_steps(FEW_STEPS)
		_send(_key(KEY_F, true))
		await _wait_steps(1)
		for step: int in STROKE_STEPS:
			_send(_mouse(MOUSE_STROKE * pixels[attempt]))
			await _wait_steps(1)
		await _wait_steps(FEW_STEPS)
		traces.append(player.drawing().trace().duplicate())
		reads.append(GestureHand.read(player.drawing()))
		_send(_key(KEY_F, false))
		await _wait_steps(1)
		player.queue_free()
		await _wait_steps(1)

	assert_eq(reads[0], "BACKFLIP", "a stroke down")
	assert_eq(reads[1], reads[0], "half the pixels under twice the sensitivity: the same")
	assert_eq(traces[1].size(), traces[0].size(), "the same trace")
	for index: int in traces[0].size():
		assert_almost_eq(traces[1][index], traces[0][index], Vector2.ONE * TOLERANCE)
	var far: Vector2 = traces[2][-1]
	assert_almost_eq(far, 2.0 * traces[0][-1], Vector2.ONE * TOLERANCE, "the same pixels: twice")


func test_a_recipe_read_in_passing_does_not_start() -> void:
	# Decision 25 of docs/specs/trick-gestures.md.
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)
	# A backflip drawn with the mouse, the hand at rest long enough to validate it.
	_send(_key(KEY_F, true))
	for step: int in STROKE_STEPS:
		_send(_mouse(MOUSE_STROKE))
		await _wait_steps(1)
	await _wait_steps(VALIDATE_STEPS)
	assert_eq(player.drawing().validated_recipe().name(), "BACKFLIP", "a backflip validated")

	# A twist started downwards: the reading goes through a double for a moment.
	var passing: String = ""
	for motion: Vector2 in GestureHand.arc(Vector2.DOWN, 180.0, 60.0, 10):
		_send(_mouse(motion))
		await _wait_steps(1)
		passing = GestureHand.read(player.drawing())
		if passing == "DOUBLE BACKFLIP":
			break
	assert_eq(passing, "DOUBLE BACKFLIP", "read in passing")
	_send(_key(KEY_F, false))
	await _wait_steps(2)
	assert_true(_intents[-1].trick_released, "F released")
	assert_eq(GestureHand.read(player.drawing()), "DOUBLE BACKFLIP", "still read so")

	var trick: AirTrick = player.motor.current_trick()
	assert_not_null(trick, "the release starts a trick")
	if trick != null:
		assert_eq(trick.name(), "BACKFLIP", "the last one validated")


func test_an_unreadable_drawing_starts_nothing_even_in_the_air() -> void:
	# Decision 27 of docs/specs/trick-gestures.md.
	_add_box(Vector3(20.0, 1.0, 20.0), Vector3(0.0, -0.5, 0.0))
	var player: Player = _add_player()
	await _wait_steps(FEW_STEPS)
	_send(_key(KEY_SPACE, true))
	await _wait_steps(1)
	_send(_key(KEY_F, true))
	# A half circle alone: no flip; then the hand at rest, long enough to settle.
	for motion: Vector2 in GestureHand.arc(Vector2.RIGHT, 180.0, 60.0, 10):
		_send(_mouse(motion))
		await _wait_steps(1)
	await _wait_steps(VALIDATE_STEPS)
	assert_false(player.is_on_floor(), "a runner in the air")
	assert_eq(GestureHand.read(player.drawing()), "NOTHING", "a drawing that does not read")

	_send(_key(KEY_F, false))
	await _wait_steps(2)

	assert_true(_intents[-1].trick_released, "F released")
	assert_null(player.motor.current_trick(), "no trick starts")
	_send(_key(KEY_SPACE, false))


## The runner jumped at the release, and the backflip drawn started with it.
func _assert_a_trick_jump(player: Player, context: String) -> void:
	assert_eq(player.motor.state, RunnerMotor.State.RISING, context + ": it jumps")
	var trick: AirTrick = player.motor.current_trick()
	assert_not_null(trick, context + ": a trick starts at the same step")
	if trick != null:
		assert_eq(trick.name(), "BACKFLIP", context + ": the backflip drawn")
		assert_false(trick.recipe.context, context + ": not the trick of the context")


## The highest the feet of the runner go above the floor until it lands again.
func _apex_of_the_flight(player: Player) -> float:
	var apex: float = player.global_position.y
	for step: int in FLIGHT_STEPS:
		await _wait_steps(1)
		apex = maxf(apex, player.global_position.y)
		if player.is_on_floor():
			break
	return apex


## A runner of the tuning of the project, its camera at `sensitivity` times the mouse
## sensitivity of the project.
func _add_player(sensitivity: float = 1.0) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	var tuning: MovementTuning = player.tuning.duplicate() as MovementTuning
	tuning.camera_mouse_sensitivity *= sensitivity
	player.tuning = tuning
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
