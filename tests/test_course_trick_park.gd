extends ReplayTest
## The Trick Park (game/levels): its blocks of every height, each one climbed in the real
## physics, its walls; and a twisted backflip drawn and posed there with the real inputs:
## key, mouse, button and stick events go through the input map of project.godot to the
## runner's own intent source, step by step. Faster than real time with the same fixed
## step of 1/60 s (see ReplayTest).

const PARK_SCENE: String = "res://game/levels/trick_park.tscn"
## The heights of the blocks, in m, and the block of each one.
const HEIGHTS: Dictionary[int, String] = {
	1: "Blocks/Block1",
	2: "Blocks/Block2",
	3: "Blocks/Block3",
	5: "Blocks/Block5",
	8: "Blocks/Block8",
}
const GROUND: String = "Blocks/Ground"
const FACING_WALLS: Array[String] = ["Walls/FacingLeft", "Walls/FacingRight"]
const WALL_RUN_WALL: String = "Walls/WallRun"
const LEAST_SIDE: float = 100.0
const NEAR: float = 0.05
## How far before the blocks a climber starts, along +Z, and how long it may take.
const RUN_UP: float = 6.0
const CLIMB_STEPS: int = 600
## The twisted backflip: where the runner starts on the block of 2 m, how far before its
## edge it jumps, and how high above the ground it presses the slide to pose the trick.
const TAKE_OFF_BLOCK: String = "Blocks/Block2"
const START_ON_THE_BLOCK: float = 0.5
const BEFORE_THE_EDGE: float = 0.8
const POSE_HEIGHT: float = 1.5
const SETTLE_STEPS: int = 20
const MOST_STEPS: int = 240
## What the fingers do while the runner runs on the block, keyed by the step: the run and
## the trick button at once, a stroke down, a pause, then a half circle.
const STROKE_FROM: int = 2
const STROKE_STEPS: int = 6
const ARC_FROM: int = 14
const ARC_STEPS: int = 12
const DRAWN_BY: int = 30
## Steps after the take-off at which the trick button is released.
const RELEASE_AFTER: int = 2
## The mouse: pixels per step of the stroke, and of the chord of the half circle.
const MOUSE_STROKE: float = 40.0
const MOUSE_CHORD: float = 15.0
const BACKFLIP_FULL: String = "BACKFLIP FULL"


## A runner that pushes one way and jumps whenever it stands: what climbs steps and
## ledges, by jumps and mantles.
class Climber:
	extends IntentSource

	var _runner: Player
	var _towards: Vector3

	func _init(runner: Player, towards: Vector3) -> void:
		_runner = runner
		_towards = towards

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = _towards
		intent.jump_pressed = _runner.is_on_floor()
		intent.jump_held = true
		return intent


## The fingers of one hand on the keyboard and the mouse, or on the gamepad.
class Fingers:
	var run: Array[InputEvent] = []
	var stop: Array[InputEvent] = []
	var trick_press: InputEvent
	var trick_release: InputEvent
	var jump_press: InputEvent
	var jump_release: InputEvent
	var pose_press: InputEvent
	var pose_release: InputEvent
	## The events of the drawing, keyed by the step of the run.
	var drawing: Dictionary[int, Array] = {}


## What the park paid for the tricks of its runner, step by step.
class TrickWatch:
	var paid: Array[AirTrick] = []
	var crashes: int = 0

	var _runner: Player

	func _init(runner: Player) -> void:
		_runner = runner
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		for event: RunnerEvent in _runner.motor.events:
			if event.kind == RunnerEvent.Kind.TRICK:
				paid.append(event.trick)
			crashes += int(event.kind == RunnerEvent.Kind.CRASH)


func after_each() -> void:
	for key: Key in [KEY_W, KEY_F, KEY_SPACE]:
		_send(_key(key, false))
	_send(_key(KEY_CTRL, false, KEY_LOCATION_LEFT))
	for button: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		_send(_button(button, false))
	for axis: JoyAxis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		_send(_stick(axis, 0.0))


func test_the_trick_park_offers_every_height() -> void:
	var park: TrickPark = _add_park()
	var tuning: MovementTuning = park.player.tuning
	var ground: AABB = _bounds_of(park.get_node(GROUND))
	assert_gte(ground.size.x, LEAST_SIDE, "an esplanade at least 100 m wide")
	assert_gte(ground.size.z, LEAST_SIDE, "and 100 m long")
	assert_almost_eq(ground.end.y, 0.0, NEAR, "its top at 0")
	for path: String in _blocks_and_walls(park):
		var block: Node = park.get_node(path)
		assert_true(block is StaticBody3D, path + ": a fixed block")
		var shapes: int = block.find_children("*", "CollisionShape3D", false, false).size()
		assert_eq(shapes, 1, path + ": a single block")

	# Every height, standing on the ground, each one climbed by a runner that pushes
	# towards it and jumps.
	var climbs: Dictionary[int, Player] = {}
	for height: int in HEIGHTS:
		var block: AABB = _bounds_of(park.get_node(HEIGHTS[height]))
		assert_almost_eq(block.end.y, float(height), NEAR, "a block of %d m" % height)
		assert_almost_eq(block.position.y, 0.0, NEAR, "%d m: on the ground" % height)
		var climber: Player = _add_climber(park, Vector3(block.get_center().x, 0.0, RUN_UP))
		climbs[height] = climber
	var tops: Dictionary[int, float] = {}
	for step: int in CLIMB_STEPS:
		await get_tree().physics_frame
		for height: int in climbs:
			var climber: Player = climbs[height]
			var highest: float = tops[height] if tops.has(height) else 0.0
			if climber.is_on_floor():
				tops[height] = maxf(highest, climber.global_position.y)
	for height: int in HEIGHTS:
		var highest: float = tops[height] if tops.has(height) else 0.0
		assert_almost_eq(highest, float(height), NEAR, "%d m: climbed" % height)

	# A pair of walls face to face, for wall jumps; a wall to run along, above the ground.
	var left: AABB = _bounds_of(park.get_node(FACING_WALLS[0]))
	var right: AABB = _bounds_of(park.get_node(FACING_WALLS[1]))
	var gap: float = right.position.x - left.end.x
	assert_between(gap, 2.0, 6.0, "two walls face to face, a few metres apart")
	assert_almost_eq(left.position.z, right.position.z, NEAR, "along the same stretch")
	assert_almost_eq(left.end.z, right.end.z, NEAR)
	var wall_run: AABB = _bounds_of(park.get_node(WALL_RUN_WALL))
	var high_enough: float = tuning.wall_run_min_height + tuning.wall_run_min_wall_height
	for wall: AABB in [left, right, wall_run]:
		assert_almost_eq(wall.position.y, 0.0, NEAR, "a wall on the ground")
		assert_gte(wall.size.y, high_enough, "tall enough to run along")
	assert_gte(wall_run.size.z, 20.0, "a long wall to run along")
	for path: String in [WALL_RUN_WALL] + FACING_WALLS:
		var wall: Node = park.get_node(path)
		assert_false(wall.is_in_group(Player.NO_WALL_RUN_GROUP), path + ": may be run along")


func test_a_twisted_backflip_on_keyboard_and_mouse() -> void:
	var fingers: Fingers = Fingers.new()
	fingers.run = [_key(KEY_W, true)]
	fingers.stop = [_key(KEY_W, false)]
	fingers.trick_press = _key(KEY_F, true)
	fingers.trick_release = _key(KEY_F, false)
	fingers.jump_press = _key(KEY_SPACE, true)
	fingers.jump_release = _key(KEY_SPACE, false)
	fingers.pose_press = _key(KEY_CTRL, true, KEY_LOCATION_LEFT)
	fingers.pose_release = _key(KEY_CTRL, false, KEY_LOCATION_LEFT)
	for step: int in STROKE_STEPS:
		fingers.drawing[STROKE_FROM + step] = [_mouse(Vector2(0.0, MOUSE_STROKE))]
	for step: int in ARC_STEPS:
		var way: Vector2 = Vector2.RIGHT.rotated(PI * (step + 0.5) / ARC_STEPS)
		fingers.drawing[ARC_FROM + step] = [_mouse(way * MOUSE_CHORD)]

	await _assert_a_twisted_backflip_with(fingers)


func test_a_twisted_backflip_on_the_gamepad() -> void:
	var fingers: Fingers = Fingers.new()
	fingers.run = [_stick(JOY_AXIS_LEFT_Y, -1.0)]
	fingers.stop = [_stick(JOY_AXIS_LEFT_Y, 0.0)]
	fingers.trick_press = _button(JOY_BUTTON_LEFT_SHOULDER, true)
	fingers.trick_release = _button(JOY_BUTTON_LEFT_SHOULDER, false)
	fingers.jump_press = _button(JOY_BUTTON_A, true)
	fingers.jump_release = _button(JOY_BUTTON_A, false)
	fingers.pose_press = _button(JOY_BUTTON_RIGHT_SHOULDER, true)
	fingers.pose_release = _button(JOY_BUTTON_RIGHT_SHOULDER, false)
	# The right stick flicked down and back, then turned half round its rim.
	fingers.drawing[STROKE_FROM] = [_stick(JOY_AXIS_RIGHT_Y, 1.0)]
	fingers.drawing[STROKE_FROM + STROKE_STEPS] = [_stick(JOY_AXIS_RIGHT_Y, 0.0)]
	for step: int in ARC_STEPS:
		var way: Vector2 = Vector2.RIGHT.rotated(PI * (step + 0.5) / ARC_STEPS)
		fingers.drawing[ARC_FROM + step] = [
			_stick(JOY_AXIS_RIGHT_X, way.x), _stick(JOY_AXIS_RIGHT_Y, way.y)
		]
	fingers.drawing[ARC_FROM + ARC_STEPS] = [
		_stick(JOY_AXIS_RIGHT_X, 0.0), _stick(JOY_AXIS_RIGHT_Y, 0.0)
	]

	await _assert_a_twisted_backflip_with(fingers)


## In a fresh park, the runner at rest on the block of 2 m, led by its own inputs: it runs
## to the far edge drawing a backflip with a twist, jumps off, releases the trick button
## in the air, poses the trick as it nears the ground; the landing pays a backflip with a
## twist, and nothing else.
func _assert_a_twisted_backflip_with(fingers: Fingers) -> void:
	var park: TrickPark = _add_park()
	var block: AABB = _bounds_of(park.get_node(TAKE_OFF_BLOCK))
	var runner: Player = park.player
	var start: Vector3 = Vector3(
		block.get_center().x, block.end.y, block.end.z - START_ON_THE_BLOCK
	)
	runner.teleport(Transform3D(Basis.IDENTITY, start))
	await _wait_steps(SETTLE_STEPS)
	assert_true(runner.intent_source is InputIntentSource, "the runner reads the real inputs")
	assert_true(runner.is_on_floor(), "a runner on the block")
	var hud: FlowHud = park.get_node("Hud/FlowHud") as FlowHud
	var label: Label = hud.get_node("%TrickLabel") as Label
	var watch: TrickWatch = TrickWatch.new(runner)
	var take_off: int = -1
	var shown: String = ""
	var jump_released: bool = false
	var posed: bool = false
	var landed: bool = false

	_send_all(fingers.run)
	_send(fingers.trick_press)
	for step: int in MOST_STEPS:
		await get_tree().physics_frame
		if fingers.drawing.has(step):
			_send_all(fingers.drawing[step])
		if step == DRAWN_BY:
			hud.refresh()
			shown = label.text if label.visible else ""
		if take_off < 0 and runner.global_position.z <= block.position.z + BEFORE_THE_EDGE:
			take_off = step
			_send(fingers.jump_press)
		if take_off < 0:
			continue
		if step == take_off + RELEASE_AFTER:
			_send(fingers.trick_release)
		var falling: bool = runner.velocity.y < 0.0
		if falling and not jump_released:
			_send(fingers.jump_release)
			jump_released = true
		if falling and not posed and runner.global_position.y < POSE_HEIGHT:
			_send(fingers.pose_press)
			posed = true
		if posed and runner.is_on_floor() and not landed:
			_send(fingers.pose_release)
			_send_all(fingers.stop)
			landed = true
		if landed and step > take_off + SETTLE_STEPS * 3:
			break

	assert_eq(shown, BACKFLIP_FULL, "the drawing read on the HUD as the runner runs")
	assert_gt(take_off, DRAWN_BY, "drawn before the edge, then the jump")
	assert_true(landed, "the runner landed on the ground below")
	assert_eq(watch.crashes, 0, "no crash")
	assert_eq(watch.paid.size(), 1, "the landing paid one trick")
	if watch.paid.size() == 1:
		assert_eq(watch.paid[0].name(), BACKFLIP_FULL, "a backflip with a twist")
	assert_eq(park.flow.tricks_landed, 1, "counted by the flow")


func _add_park() -> TrickPark:
	var park: TrickPark = (load(PARK_SCENE) as PackedScene).instantiate() as TrickPark
	add_child_autofree(park)
	return park


## A runner beside the park's own, at `feet`, that climbs along -Z.
func _add_climber(park: TrickPark, feet: Vector3) -> Player:
	var scene: PackedScene = load("res://game/player/player.tscn") as PackedScene
	var climber: Player = scene.instantiate() as Player
	park.add_child(climber)
	climber.teleport(Transform3D(Basis.IDENTITY, feet))
	climber.intent_source = Climber.new(climber, Vector3.FORWARD)
	climber.watch(false)
	return climber


## The paths of the blocks and the walls of the park.
func _blocks_and_walls(park: TrickPark) -> Array[String]:
	var paths: Array[String] = []
	for group: String in ["Blocks", "Walls"]:
		for child: Node in park.get_node(group).get_children():
			paths.append(group + "/" + child.name)
	return paths


func _wait_steps(steps: int) -> void:
	for step: int in steps:
		await get_tree().physics_frame


func _send_all(events: Array) -> void:
	for event: InputEvent in events:
		_send(event)


## Gives an input event to the engine as the device would, at once.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## The box that holds a block, in the world.
func _bounds_of(block: Node) -> AABB:
	var collider: CollisionShape3D = block.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()


func _key(
	physical: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED
) -> InputEvent:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical
	event.location = location
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
