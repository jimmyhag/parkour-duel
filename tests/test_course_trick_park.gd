extends ReplayTest
## The Trick Park (game/levels): its blocks of every height, each one climbed in the real
## physics, its walls, and what a riskless minute of tricks between its walls face to
## face earns; a twisted backflip, and a backflip out of a wall run, drawn and posed
## there with the real inputs: key, mouse, button and stick events go through the input
## map of project.godot to the runner's own intent source, step by step. Faster than
## real time with the same fixed step of 1/60 s (see ReplayTest).

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
## the trick button at once, a stroke down, a pause, then a half circle; drawn and at
## rest long enough to be validated (0.1 s) by the step DRAWN_BY.
const STROKE_FROM: int = 2
const STROKE_STEPS: int = 6
const ARC_FROM: int = 14
const ARC_STEPS: int = 12
const DRAWN_BY: int = 34
## Steps after the take-off at which the trick button is released.
const RELEASE_AFTER: int = 2
## The mouse: pixels per step of the stroke, and of the chord of the half circle.
const MOUSE_STROKE: float = 40.0
const MOUSE_CHORD: float = 15.0
const BACKFLIP_FULL: String = "BACKFLIP FULL"
## Between the walls face to face: one minute of fixed steps, and the most style it may
## earn (the threshold of the riskless loop on the flat, tests/test_runner_trick_risk.gd).
const MINUTE: int = 3600
const RISKLESS_STYLE_PER_MINUTE: int = 4800
## How many times faster than real time that minute plays, and the most fixed steps a
## frame may play for it.
const MINUTE_SPEED_UP: int = 100
const MINUTE_STEPS_PER_FRAME: int = 64
## The wall exit: the wall to run along, where the runner starts on the ground beside it
## (x, z), how far into its stretch it jumps, the steps of the wall run before it draws,
## and the steps it leaves the hand at rest before the release.
const WALL_RUN_LANE: Vector2 = Vector2(39.55, -21.0)
const WALL_RUN_START: float = -28.0
const JUMP_INTO_THE_WALL: float = 0.8
const DRAW_AFTER: int = 2
const REST_STEPS: int = 9


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


## A runner that goes to and fro between the walls face to face, without a risk: along
## the left wall into the corridor, a jump, a wall run, a wall jump, the next of its
## recipes released at once, the wall run in front pays it, and so on; out of the
## corridor, it presses the slide as the ground comes, turns round and goes again. With
## `trick_exits`, the release of the trick button is its wall jump.
class WallBot:
	extends IntentSource

	## The corridor between the faces of the walls: across (x), along (z), in m.
	const LEFT_FACE: float = -42.0
	const RIGHT_FACE: float = -38.0
	const NEAR_END: float = -30.0
	const FAR_END: float = -50.0
	## The lane along the left wall, how far past an end the runner turns round, and how
	## far before an end it jumps in.
	const LANE: float = -41.4
	const TURN_ROUND: float = 3.0
	const JUMP_IN: float = 1.5
	const WALL_RUN_STEPS: int = 4

	var recipes: Array[TrickRecipe] = []
	var released: int = 0

	var _trick_exits: bool = false
	var _runner: Player
	var _way: float = -1.0
	var _wall_run_steps: int = 0
	var _since_wall_jump: int = -1
	var _pressed: bool = false

	func _init(runner: Player, tricks: Array[TrickRecipe], trick_exits: bool = false) -> void:
		_runner = runner
		recipes = tricks
		_trick_exits = trick_exits

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = MoveIntent.new()
		var state: RunnerMotor.State = _runner.motor.state
		var feet: Vector3 = _runner.global_position
		var along: Vector3 = Vector3(0.0, 0.0, _way)
		if state == RunnerMotor.State.WALL_RUNNING:
			_wall_run_steps += 1
			intent.direction = along
			if _wall_run_steps >= WALL_RUN_STEPS and _trick_exits:
				_release(intent)
				_since_wall_jump = 0
			elif _wall_run_steps >= WALL_RUN_STEPS:
				intent.jump_pressed = true
				intent.jump_held = true
				_since_wall_jump = 0
		elif state == RunnerMotor.State.RISING or state == RunnerMotor.State.FALLING:
			_wall_run_steps = 0
			intent.jump_held = state == RunnerMotor.State.RISING
			var towards: float = -1.0
			if _since_wall_jump >= 0:
				_since_wall_jump += 1
				towards = signf(_runner.velocity.x)
			intent.direction = (along + Vector3.RIGHT * towards * 0.8).normalized()
			if _since_wall_jump == 1 and not _trick_exits:
				_release(intent)
		else:
			_on_the_ground(intent, feet)
		var ground_soon: bool = feet.y + 2.0 * _runner.velocity.y / 60.0 <= 0.0
		var falling: bool = _runner.velocity.y < 0.0 and not _runner.is_on_floor()
		intent.slide_pressed = falling and ground_soon and not _pressed
		_pressed = falling and (_pressed or intent.slide_pressed)
		return intent

	## The trick button released, its drawing reading the next of the recipes.
	func _release(intent: MoveIntent) -> void:
		intent.trick_released = true
		intent.trick_recipe = recipes[released % recipes.size()]
		released += 1

	## On the ground: turns round past an end, keeps to the lane along the left wall, and
	## jumps in fast enough for a wall run.
	func _on_the_ground(intent: MoveIntent, feet: Vector3) -> void:
		_since_wall_jump = -1
		_wall_run_steps = 0
		if _way < 0.0 and feet.z < FAR_END - TURN_ROUND:
			_way = 1.0
		elif _way > 0.0 and feet.z > NEAR_END + TURN_ROUND:
			_way = -1.0
		var lane: float = clampf(LANE - feet.x, -1.0, 1.0) * 0.5
		intent.direction = Vector3(lane, 0.0, _way).normalized()
		var entrance: float = NEAR_END if _way < 0.0 else FAR_END
		var before: float = (feet.z - entrance) * -_way
		var speed: float = Vector2(_runner.velocity.x, _runner.velocity.z).length()
		var fast: bool = speed > _runner.tuning.wall_run_start_speed + 0.5
		intent.jump_pressed = before > -JUMP_IN and before < 0.5 and fast
		intent.jump_held = intent.jump_pressed


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


func test_no_wall_of_the_trick_park_is_made_of_several_blocks() -> void:
	var park: TrickPark = _add_park()
	var paths: Array[String] = _blocks_and_walls(park)
	var touching: int = 0
	for first: int in paths.size():
		for second: int in range(first + 1, paths.size()):
			var one: AABB = _bounds_of(park.get_node(paths[first]))
			var other: AABB = _bounds_of(park.get_node(paths[second]))
			if not one.grow(NEAR).intersects(other.grow(NEAR)):
				continue
			touching += 1
			var pair: String = "%s and %s" % [paths[first], paths[second]]
			# Their upright faces turned the same way: X and Z, at either end.
			for axis: int in [Vector3.AXIS_X, Vector3.AXIS_Z]:
				var starts: float = absf(one.position[axis] - other.position[axis])
				var ends: float = absf(one.end[axis] - other.end[axis])
				assert_gt(starts, NEAR, "%s: no face in one plane (axis %d)" % [pair, axis])
				assert_gt(ends, NEAR, "%s: no face in one plane (axis %d)" % [pair, axis])
	assert_gt(touching, 3, "blocks that touch were compared")


func test_the_tricks_between_two_walls_earn_little_without_risk() -> void:
	# Decision 23 of docs/specs/trick-gestures.md: a trick paid by a wall run is worth half
	# of it; and a trick is judged against the last tricks (decision 22). The runner jumps
	# off each wall with the jump button and releases its trick at once, then with the
	# trick button, which jumps off the wall into the trick (decision 28).
	for trick_exits: bool in [false, true]:
		var how: String = "the trick button" if trick_exits else "the jump button"
		var park: TrickPark = _add_park()
		var runner: Player = park.player
		var start: Vector3 = Vector3(WallBot.LANE, 0.0, WallBot.NEAR_END + 8.0)
		runner.teleport(Transform3D(Basis.IDENTITY, start))
		var singles: Array[TrickRecipe] = [
			TrickRecipe.drawn(TrickRecipe.Flip.FRONT_FLIP),
			TrickRecipe.drawn(TrickRecipe.Flip.BACKFLIP),
			TrickRecipe.drawn(TrickRecipe.Flip.SIDE_FLIP),
			TrickRecipe.drawn(TrickRecipe.Flip.SPIN),
		]
		var bot: WallBot = WallBot.new(runner, singles, trick_exits)
		runner.intent_source = bot
		var watch: TrickWatch = TrickWatch.new(runner)
		var wall_runs: int = 0
		var paid_by_a_wall_run: int = 0
		var started: int = Time.get_ticks_msec()
		# A minute of fixed steps, each one still of 1/60 s, many to a frame: nothing but
		# the physics runs here, and the same steps play sooner.
		var steps_per_frame: int = Engine.max_physics_steps_per_frame
		Engine.physics_ticks_per_second = STEPS_PER_SECOND * MINUTE_SPEED_UP
		Engine.time_scale = MINUTE_SPEED_UP
		Engine.max_physics_steps_per_frame = MINUTE_STEPS_PER_FRAME

		for step: int in MINUTE:
			await get_tree().physics_frame
			for event: RunnerEvent in runner.motor.events:
				wall_runs += int(event.kind == RunnerEvent.Kind.WALL_RUN)
				paid_by_a_wall_run += int(event.trick != null and event.trick.unposed)
		Engine.physics_ticks_per_second = STEPS_PER_SECOND * SPEED_UP
		Engine.time_scale = SPEED_UP
		Engine.max_physics_steps_per_frame = steps_per_frame

		gut.p(
			(
				(
					"between the walls, off them by %s: style %d, ammunition %d, tricks released"
					+ " %d, paid %d (%d by a wall run), wall runs %d, crashes %d, %d ms"
				)
				% [
					how,
					park.flow.style_score,
					park.flow.ammo,
					bot.released,
					watch.paid.size(),
					paid_by_a_wall_run,
					wall_runs,
					watch.crashes,
					Time.get_ticks_msec() - started
				]
			)
		)
		assert_gt(paid_by_a_wall_run, 20, how + ": the wall runs pay its tricks again and again")
		assert_eq(watch.crashes, 0, how + ": without a crash")
		assert_lt(park.flow.style_score, RISKLESS_STYLE_PER_MINUTE, how + ": under the threshold")
		park.queue_free()
		await get_tree().physics_frame


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


func test_a_wall_exit_with_the_real_inputs() -> void:
	# Decision 28 of docs/specs/trick-gestures.md, along the wall of the park to run along:
	# on the keyboard and the mouse, then on the gamepad.
	var keyboard: Fingers = Fingers.new()
	keyboard.run = [_key(KEY_W, true)]
	keyboard.stop = [_key(KEY_W, false)]
	keyboard.trick_press = _key(KEY_F, true)
	keyboard.trick_release = _key(KEY_F, false)
	keyboard.jump_press = _key(KEY_SPACE, true)
	keyboard.jump_release = _key(KEY_SPACE, false)
	keyboard.pose_press = _key(KEY_CTRL, true, KEY_LOCATION_LEFT)
	keyboard.pose_release = _key(KEY_CTRL, false, KEY_LOCATION_LEFT)
	for step: int in STROKE_STEPS:
		keyboard.drawing[step] = [_mouse(Vector2(0.0, MOUSE_STROKE))]
	var gamepad: Fingers = Fingers.new()
	gamepad.run = [_stick(JOY_AXIS_LEFT_Y, -1.0)]
	gamepad.stop = [_stick(JOY_AXIS_LEFT_Y, 0.0)]
	gamepad.trick_press = _button(JOY_BUTTON_LEFT_SHOULDER, true)
	gamepad.trick_release = _button(JOY_BUTTON_LEFT_SHOULDER, false)
	gamepad.jump_press = _button(JOY_BUTTON_A, true)
	gamepad.jump_release = _button(JOY_BUTTON_A, false)
	gamepad.pose_press = _button(JOY_BUTTON_RIGHT_SHOULDER, true)
	gamepad.pose_release = _button(JOY_BUTTON_RIGHT_SHOULDER, false)
	gamepad.drawing[0] = [_stick(JOY_AXIS_RIGHT_Y, 1.0)]
	gamepad.drawing[STROKE_STEPS] = [_stick(JOY_AXIS_RIGHT_Y, 0.0)]

	for fingers: Fingers in [keyboard, gamepad]:
		var device: String = "keyboard and mouse" if fingers == keyboard else "gamepad"
		await _assert_a_wall_exit_with(fingers, device)
		after_each()


## In a fresh park, the runner on the ground beside the wall to run along, led by its own
## inputs: it runs along it, jumps into a wall run, draws a backflip there and releases
## the trick button; the release jumps off the wall into the backflip, and the slide
## pressed as the ground comes poses it.
func _assert_a_wall_exit_with(fingers: Fingers, device: String) -> void:
	var park: TrickPark = _add_park()
	var runner: Player = park.player
	var start: Vector3 = Vector3(WALL_RUN_LANE.x, 0.0, WALL_RUN_LANE.y)
	runner.teleport(Transform3D(Basis.IDENTITY, start))
	await _wait_steps(SETTLE_STEPS)
	var watch: TrickWatch = TrickWatch.new(runner)
	var wall_run_from: int = -1
	var released_at: int = -1
	var jumped: bool = false
	var wall_jumped: bool = false
	var rose: bool = false
	var posed: bool = false
	var landed: bool = false

	_send_all(fingers.run)
	for step: int in MOST_STEPS:
		await get_tree().physics_frame
		var state: RunnerMotor.State = runner.motor.state
		if released_at >= 0 and step <= released_at + 2 and runner.motor.is_in_a_trick():
			rose = state == RunnerMotor.State.RISING
		if not jumped and runner.global_position.z <= WALL_RUN_START - JUMP_INTO_THE_WALL:
			_send(fingers.jump_press)
			jumped = true
		if wall_run_from < 0 and state == RunnerMotor.State.WALL_RUNNING:
			wall_run_from = step
			_send(fingers.jump_release)
		if wall_run_from < 0 or released_at >= 0 and landed:
			continue
		var drawing: int = step - wall_run_from - DRAW_AFTER
		if drawing == -1:
			_send(fingers.trick_press)
		if fingers.drawing.has(drawing):
			_send_all(fingers.drawing[drawing])
		if released_at < 0 and drawing == STROKE_STEPS + REST_STEPS:
			assert_eq(state, RunnerMotor.State.WALL_RUNNING, device + ": still along the wall")
			_send(fingers.trick_release)
			released_at = step
		for event: RunnerEvent in runner.motor.events:
			wall_jumped = wall_jumped or event.kind == RunnerEvent.Kind.WALL_JUMP
		var falling: bool = runner.velocity.y < 0.0 and released_at >= 0
		if falling and not posed and runner.global_position.y < POSE_HEIGHT:
			_send(fingers.pose_press)
			posed = true
		if posed and runner.is_on_floor() and not landed:
			_send(fingers.pose_release)
			_send_all(fingers.stop)
			landed = true

	assert_gt(wall_run_from, -1, device + ": a wall run")
	assert_gt(released_at, -1, device + ": the trick button released along the wall")
	assert_true(rose, device + ": the release jumps off the wall into the trick")
	assert_false(wall_jumped, device + ": the jump button never jumped off the wall")
	assert_true(landed, device + ": the runner landed")
	assert_eq(watch.crashes, 0, device + ": no crash")
	assert_eq(watch.paid.size(), 1, device + ": the landing paid one trick")
	if watch.paid.size() == 1:
		assert_eq(watch.paid[0].name(), "BACKFLIP", device + ": the backflip drawn")
		assert_false(watch.paid[0].unposed, device + ": posed")
	park.queue_free()
	await _wait_steps(1)


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
	var pad: TrickPad = park.get_node("Hud/TrickPad") as TrickPad
	var pad_shown: String = ""
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
			pad.refresh()
			if pad.visible and pad.is_validated():
				pad_shown = pad.recipe_shown()
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
	assert_eq(pad_shown, BACKFLIP_FULL, "and validated on the pad")
	pad.refresh()
	assert_false(pad.visible, "the button released: no pad")
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
