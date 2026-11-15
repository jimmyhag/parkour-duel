extends ReplayTest
## The chase (game/levels/chase.tscn) in the real physics, without a screen: its arena,
## the contact of the two bodies, the start of a round face to face, the device of each
## player, and the fall out of the arena. Faster than real time with the same fixed step
## of 1/60 s (see ReplayTest).

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const ONE: int = Chase.PLAYER_ONE
const TWO: int = Chase.PLAYER_TWO
## More steps than a countdown lasts.
const COUNTDOWN_STEPS: int = 400
## How much the arena may differ from 20 m by 20 m, in m.
const ARENA_SIZE: float = 20.0
const ARENA_TOLERANCE: float = 2.0
## The height of a low wall the vault will take, and how thin it is at most, in m.
const LOW_WALL_LOWEST: float = 0.8
const LOW_WALL_HIGHEST: float = 1.2
const LOW_WALL_THICKEST: float = 0.5
## The height of a block to climb, in m.
const BLOCK_LOWEST: float = 1.5
const BLOCK_HIGHEST: float = 2.0
## How much higher than a jump and a mantle from the floor a platform stands, in m.
const PLATFORM_MARGIN: float = 0.3
## Steps of a climb: twice pressing against a face, then jumping and pushing on.
const PRESS_STEPS: int = 30
const JUMP_STEPS: int = 45
const CLIMB_STEPS: int = 2 * (PRESS_STEPS + JUMP_STEPS) + PRESS_STEPS
## Steps the players push forward from the countdown on: more than it lasts.
const PUSH_STEPS_FROM_THE_COUNTDOWN: int = 1000
## Steps a device is held, then left to settle.
const PUSH_STEPS: int = 20
const STILL: float = 0.05
const NEAR: float = 0.05
## The precision of a size read from the physics, in m.
const PRECISION: float = 0.001


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_the_arena_has_all_its_obstacles() -> void:
	var chase: Chase = _add_chase()
	var tuning: MovementTuning = chase.players[ONE].tuning
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var ground_top: float = _box_of(arena.get_node("Ground") as StaticBody3D).end.y

	# Enclosed by walls not to be run along, about 20 m by 20 m.
	var enclosure: Array[AABB] = _boxes(arena, "Enclosure", "the enclosure")
	var inside: AABB = _inside_of(enclosure)
	assert_almost_eq(inside.size.x, ARENA_SIZE, ARENA_TOLERANCE, "about 20 m wide")
	assert_almost_eq(inside.size.z, ARENA_SIZE, ARENA_TOLERANCE, "about 20 m deep")
	for wall: Node in arena.get_node("Enclosure").get_children():
		assert_true(wall.is_in_group(Player.NO_WALL_RUN_GROUP), wall.name + ": no wall run on it")
	# No way out: higher than a jump from the highest top, and the mantle above it.
	var highest_top: float = ground_top
	for body: StaticBody3D in _bodies(arena):
		if body.get_parent().name != "Enclosure":
			highest_top = maxf(highest_top, _box_of(body).end.y)
	var reach: float = highest_top + tuning.jump_height + tuning.mantle_max_height
	for box: AABB in enclosure:
		assert_gt(box.end.y, reach, "the enclosure is out of reach")

	for box: AABB in _boxes(arena, "LowWalls", "low walls to vault"):
		var height: float = box.end.y - ground_top
		var lowest: float = LOW_WALL_LOWEST - PRECISION
		var highest: float = LOW_WALL_HIGHEST + PRECISION
		assert_between(height, lowest, highest, "a low wall of 0.8 to 1.2 m")
		assert_lte(minf(box.size.x, box.size.z), LOW_WALL_THICKEST, "a thin one")
	var blocks: Array[AABB] = _boxes(arena, "Blocks", "blocks to climb")
	for box: AABB in blocks:
		var height: float = box.end.y - ground_top
		var lowest: float = BLOCK_LOWEST - PRECISION
		assert_between(height, lowest, BLOCK_HIGHEST + PRECISION, "a block of 1.5 to 2 m")
		assert_between(height, tuning.mantle_min_height, tuning.mantle_max_height, "to mantle")
	var walls: Node = arena.get_node("Walls")
	for box: AABB in _boxes(arena, "Walls", "walls to run along"):
		assert_gte(box.size.y, tuning.wall_run_min_wall_height, "high enough to run along")
		assert_gte(maxf(box.size.x, box.size.z), 4.0, "long enough")
	for wall: Node in walls.get_children():
		assert_false(wall.is_in_group(Player.NO_WALL_RUN_GROUP), wall.name + ": may be run along")
	for box: AABB in _boxes(arena, "LowPassages", "low passages to slide under"):
		var room: float = box.position.y - ground_top
		assert_gt(room, tuning.slide_capsule_height, "room for a slide under it")
		assert_lt(room, tuning.capsule_height, "none for a runner on its feet")
	for box: AABB in _boxes(arena, "Platforms", "a platform"):
		var height: float = box.end.y - ground_top
		var from_the_floor: float = tuning.jump_height + tuning.mantle_max_height
		assert_gt(height, from_the_floor + PLATFORM_MARGIN, "out of reach from the floor")
		assert_true(_has_a_ledge_to(box, blocks, tuning), "reached from a ledge")

	# Every wall a single block, every block inside the enclosure.
	for body: StaticBody3D in _bodies(arena):
		var shapes: int = body.find_children("*", "CollisionShape3D", false, false).size()
		assert_eq(shapes, 1, body.name + ": a single block")
		if body.get_parent().name in ["Arena", "Enclosure"]:
			continue
		var box: AABB = _box_of(body)
		assert_true(inside.grow(NEAR).encloses(box), body.name + ": inside the arena")


func test_the_contact_of_the_two_bodies_is_observed() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	var tuning: MovementTuning = cat.tuning
	var touching: float = 2.0 * tuning.capsule_radius
	cat.intent_source = ScriptedIntentSource.new().hold(Vector3.RIGHT, false, 200)
	mouse.intent_source = ScriptedIntentSource.new().hold(Vector3.LEFT, false, 200)
	# The distance between the axes of the two capsules after each step, by its step.
	var distances: Dictionary[int, float] = {}
	for step: int in 200:
		if chase.chase.phase != ChaseState.Phase.RUNNING:
			break
		distances[chase.match_steps] = _apart(cat, mouse)
		await get_tree().physics_frame

	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round is over")
	assert_eq(chase.chase.round_winner_role, ChaseState.Role.CAT, "won by the cat")
	var dated: int = chase.chase.end_step
	assert_true(distances.has(dated - 1), "a contact message, dated")
	if distances.has(dated - 1) and distances.has(dated - 2):
		assert_lte(distances[dated - 1], touching + NEAR, "the capsules touched")
		assert_gt(distances[dated - 2], touching, "and not one step before")
	# The screens follow the match at every frame shown.
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: ChaseRoundScreen = chase.get_node("Screens/RoundScreen") as ChaseRoundScreen
	assert_true(screen.visible, "the screen between two rounds shows")
	assert_eq(screen.lines(), ["CAT WINS", "PLAYER 1   1 - 0   PLAYER 2"], "the winner, the score")


func test_the_two_players_start_face_to_face() -> void:
	var chase: Chase = _add_chase()
	# Both push forward through the countdown: they are held at their start points.
	_push_forward(chase)
	await _wait_for_the_end_of_the_countdown(chase)
	_assert_face_to_face(chase, "the first round")
	await _wait_for_go(chase)
	# The cat catches the mouse at once, away from the start: then the next round.
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	cat.teleport(Transform3D(Basis.IDENTITY, Vector3(-6.0, 0.0, 5.0)))
	mouse.teleport(Transform3D(Basis.IDENTITY, Vector3(-6.3, 0.0, 5.0)))
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the first round is over")
	_push_forward(chase)
	await _wait_for_the_end_of_the_countdown(chase)
	_assert_face_to_face(chase, "the second round")
	await _wait_for_go(chase)
	assert_eq(chase.chase.cat, TWO, "with the roles swapped")


func test_a_contact_on_the_step_the_time_ends_lets_the_mouse_win() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	var time_up: int = chase.chase.start_step + chase.chase.round_steps()
	while chase.match_steps < time_up - 1:
		await get_tree().physics_frame
	# The capsules overlap from the very step the time ends, and stay so.
	cat.teleport(Transform3D(Basis.IDENTITY, mouse.global_position + Vector3(0.3, 0.0, 0.0)))
	for step: int in 3:
		await get_tree().physics_frame

	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round ends with the time")
	assert_eq(chase.chase.round_winner_role, ChaseState.Role.MOUSE, "won by the mouse")
	assert_eq(chase.chase.end_step, time_up, "at the step the time ends")


func test_the_gauge_of_a_round_is_empty_at_the_next_go() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var one: Player = chase.players[ONE]
	var flow: FlowState = chase.chase.flows[ONE]
	one.intent_source = ScriptedIntentSource.new().hold(Vector3.RIGHT, false, 20).hold(
		Vector3.RIGHT, true, 30
	)
	for step: int in 60:
		await get_tree().physics_frame
	assert_gt(flow.gauge, 0.0, "the moves of the round fill the gauge")
	assert_gt(flow.moves_counted, 0, "they are counted")
	# The cat catches the mouse: the next round.
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	cat.teleport(Transform3D(Basis.IDENTITY, mouse.global_position + Vector3(0.3, 0.0, 0.0)))
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round is over")

	await _wait_for_go(chase)

	for player: int in ChaseState.PLAYERS:
		assert_eq(chase.chase.flows[player].gauge, 0.0, "an empty gauge at GO")
		assert_eq(chase.players[player].motor.top_speed_bonus, 0.0, "and no speed bonus")


func test_a_rematch_starts_with_the_other_player_as_the_cat() -> void:
	var chase: Chase = _add_chase()
	assert_eq(chase.chase.cat, ONE, "player 1 is the cat of the first round")

	chase.rematch()
	assert_eq(chase.chase.cat, TWO, "player 2 in the rematch")
	assert_eq(chase.chase.role(TWO), ChaseState.Role.CAT, "and wears it before GO")
	chase.rematch()
	assert_eq(chase.chase.cat, ONE, "then player 1 again")


func test_a_platform_is_not_reached_from_the_floor_but_from_its_ledge() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var one: Player = chase.players[ONE]
	var two: Player = chase.players[TWO]
	var platform: AABB = _box_of(chase.get_node("Arena/Platforms/SouthEast") as StaticBody3D)
	var ledge: AABB = _box_of(chase.get_node("Arena/Blocks/LedgeSouthEast") as StaticBody3D)
	# Player 1 presses against the face of the platform from the floor, then jumps and
	# pushes on: the highest a jump and a mantle take it. Player 2 does the same at the
	# ledge, then from the ledge at the platform.
	var face: Vector3 = Vector3(platform.get_center().x, 0.0, platform.position.z - 1.0)
	one.teleport(Transform3D(Basis.IDENTITY, face))
	var before_the_ledge: Vector3 = Vector3(ledge.position.x - 1.0, 0.0, ledge.get_center().z)
	two.teleport(Transform3D(Basis.IDENTITY, before_the_ledge))
	one.intent_source = _climb(Vector3.BACK)
	two.intent_source = _climb(Vector3.RIGHT)
	var highest: Array[float] = [0.0, 0.0]
	for step: int in CLIMB_STEPS:
		await get_tree().physics_frame
		highest[ONE] = maxf(highest[ONE], one.global_position.y)
		highest[TWO] = maxf(highest[TWO], two.global_position.y)

	assert_lt(highest[ONE], platform.end.y - NEAR, "from the floor, never on the platform")
	assert_gte(highest[TWO], platform.end.y - NEAR, "from its ledge, on the platform")


func test_each_player_obeys_only_its_device() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var one: Player = chase.players[ONE]
	var two: Player = chase.players[TWO]
	var one_from: Vector3 = one.global_position
	var two_from: Vector3 = two.global_position

	var forward: InputEventKey = InputEventKey.new()
	forward.physical_keycode = KEY_W
	forward.pressed = true
	await _push(forward)
	var released: InputEventKey = forward.duplicate() as InputEventKey
	released.pressed = false
	await _push(released)

	assert_gt(_ahead(one, one_from, two_from), 1.0, "the keyboard: player 1 goes forward")
	assert_lt(_moved(two, two_from), STILL, "player 2 does not move")

	one_from = one.global_position
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.device = ChaseState.GAMEPAD_DEVICE
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -1.0
	await _push(stick)
	var let_go: InputEventJoypadMotion = stick.duplicate() as InputEventJoypadMotion
	let_go.axis_value = 0.0
	await _push(let_go)

	assert_gt(_ahead(two, two_from, one_from), 1.0, "the gamepad: player 2 goes forward")
	assert_lt(_moved(one, one_from), STILL, "player 1 does not move")


func test_a_fall_out_of_the_arena_brings_the_player_back_to_its_start() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var one: Player = chase.players[ONE]
	var start: Vector3 = one.global_position
	var time_left: float = chase.chase.seconds_left(chase.match_steps)
	one.teleport(Transform3D(Basis.IDENTITY, Vector3(30.0, chase.fall_limit - 1.0, 0.0)))
	for step: int in 3:
		await get_tree().physics_frame
	assert_lt(_moved(one, start), NEAR, "back at its start point")
	assert_eq(chase.chase.phase, ChaseState.Phase.RUNNING, "the round goes on")
	assert_lt(chase.chase.seconds_left(chase.match_steps), time_left, "the time too")


## Both players at their start points, the distance of the tuning apart, each facing the
## other, its camera in its back, on the ground and at rest.
func _assert_face_to_face(chase: Chase, context: String) -> void:
	var one: Player = chase.players[ONE]
	var two: Player = chase.players[TWO]
	var tuning: MovementTuning = one.tuning
	assert_almost_eq(
		_apart(one, two), tuning.chase_start_distance, NEAR, context + ": the start distance apart"
	)
	for player: int in ChaseState.PLAYERS:
		var runner: Player = chase.players[player]
		var other: Player = chase.players[1 - player]
		var towards: Vector3 = other.global_position - runner.global_position
		towards = Vector3(towards.x, 0.0, towards.z).normalized()
		var facing: Vector3 = -runner.visual_transform().basis.z
		assert_almost_eq(facing.dot(towards), 1.0, NEAR, context + ": facing the other")
		var looking: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, runner.camera_rig.view_yaw())
		assert_almost_eq(looking.dot(towards), 1.0, NEAR, context + ": its camera too")
		assert_true(runner.is_on_floor(), context + ": on the ground")
		assert_lt(runner.velocity.length(), NEAR, context + ": at rest")
		var from_its_start: float = chase.spawns[player].origin.distance_to(runner.global_position)
		assert_lt(from_its_start, NEAR, context + ": at its start point")


func _add_chase() -> Chase:
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	add_child_autofree(chase)
	return chase


func _wait_for_go(chase: Chase) -> void:
	for step: int in COUNTDOWN_STEPS:
		if chase.chase.phase == ChaseState.Phase.RUNNING:
			return
		await get_tree().physics_frame
	assert_eq(chase.chase.phase, ChaseState.Phase.RUNNING, "GO came")


## Pushes `way`, against a face, then jumps and pushes on; twice; then pushes on.
func _climb(way: Vector3) -> ScriptedIntentSource:
	var source: ScriptedIntentSource = ScriptedIntentSource.new()
	for attempt: int in 2:
		source.hold(way, false, PRESS_STEPS).hold(way, true, JUMP_STEPS)
	return source.hold(way, false, PRESS_STEPS)


## Both players push forward from now on, through the countdown and after it.
func _push_forward(chase: Chase) -> void:
	for runner: Player in chase.players:
		var forward: Vector3 = -runner.visual_transform().basis.z
		runner.intent_source = ScriptedIntentSource.new().hold(
			forward, false, PUSH_STEPS_FROM_THE_COUNTDOWN
		)


## Waits until the last step of the countdown is played: the next one is GO.
func _wait_for_the_end_of_the_countdown(chase: Chase) -> void:
	var tuning: MovementTuning = chase.players[ONE].tuning
	var number: int = roundi(tuning.round_countdown_number_time * STEPS_PER_SECOND)
	var go_step: int = RoundClock.NUMBERS * number
	for step: int in COUNTDOWN_STEPS:
		if chase.clock.steps == go_step - 1:
			return
		await get_tree().physics_frame
	assert_eq(chase.clock.steps, go_step - 1, "the countdown came to its end")


## Gives the event to the engine as its device would, then lets the players run for a while.
func _push(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for step: int in PUSH_STEPS:
		await get_tree().physics_frame


## How far the axes of two capsules are apart, along the ground.
func _apart(first: Player, second: Player) -> float:
	var between: Vector3 = second.global_position - first.global_position
	return Vector2(between.x, between.z).length()


func _moved(runner: Player, from: Vector3) -> float:
	return runner.global_position.distance_to(from)


## How far `runner` went from `from` towards `towards`, along the ground.
func _ahead(runner: Player, from: Vector3, towards: Vector3) -> float:
	var way: Vector3 = Vector3(towards.x - from.x, 0.0, towards.z - from.z).normalized()
	return (runner.global_position - from).dot(way)


## The static bodies of the arena, at every depth.
func _bodies(arena: Node) -> Array[StaticBody3D]:
	var found: Array[StaticBody3D] = []
	for node: Node in arena.find_children("*", "StaticBody3D", true, false):
		found.append(node as StaticBody3D)
	return found


## The boxes of the blocks of a group of the arena, which must hold at least two (one for
## the platforms).
func _boxes(arena: Node, group: String, what: String) -> Array[AABB]:
	var boxes: Array[AABB] = []
	for child: Node in arena.get_node(group).get_children():
		boxes.append(_box_of(child as StaticBody3D))
	var least: int = 1 if group == "Platforms" else 2
	assert_gte(boxes.size(), least, "the arena has %s" % what)
	return boxes


func _box_of(body: StaticBody3D) -> AABB:
	var collider: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()


## The space between the walls of the enclosure, on the ground.
func _inside_of(walls: Array[AABB]) -> AABB:
	var low: Vector3 = Vector3(-INF, 0.0, -INF)
	var high: Vector3 = Vector3(INF, 0.0, INF)
	for box: AABB in walls:
		var middle: Vector3 = box.get_center()
		if box.size.x < box.size.z:
			if middle.x < 0.0:
				low.x = maxf(low.x, box.end.x)
			else:
				high.x = minf(high.x, box.position.x)
		elif middle.z < 0.0:
			low.z = maxf(low.z, box.end.z)
		else:
			high.z = minf(high.z, box.position.z)
	return AABB(low, Vector3(high.x - low.x, 100.0, high.z - low.z))


## Whether a block to mantle stands against the platform, its top within a jump and a
## mantle of the platform's.
func _has_a_ledge_to(platform: AABB, blocks: Array[AABB], tuning: MovementTuning) -> bool:
	for block: AABB in blocks:
		var climb: float = platform.end.y - block.end.y
		var against: bool = platform.grow(NEAR).intersects(block)
		var reach: float = tuning.jump_height + tuning.mantle_max_height
		if against and climb >= tuning.mantle_min_height and climb <= reach:
			return true
	return false
