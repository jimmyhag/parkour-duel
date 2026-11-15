extends ReplayTest
## The chase (game/levels/chase.tscn) in the real physics, without a screen: its arena,
## the catch of a touch of the cat (not of the contact of the bodies), its dive stopped by a
## wall, the start of a round face to face, the device of each
## player, the fall out of the arena, and its low walls vaulted both ways by the pilot.
## Faster than real time with the same fixed step of 1/60 s (see ReplayTest).

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const ONE: int = Chase.PLAYER_ONE
const TWO: int = Chase.PLAYER_TWO
## More steps than a countdown lasts.
const COUNTDOWN_STEPS: int = 400
## How much the arena may differ from 24 m by 24 m, in m (docs/specs/chase-tag.md,
## decision 10, after the 32 m of docs/specs/chase-arena.md, decision 1, and the 20 m of
## docs/specs/chase-mode.md).
const ARENA_SIZE: float = 24.0
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
const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## How far from the wall a runner coming from the side of the enclosure starts, at most,
## in m: room enough to reach its top speed before the wall is within reach.
const RUN_UP: float = 2.8
## Steps a run at a low wall lasts at most: well past it.
const RUN_STEPS: int = 90
## How far from a wall a cat runs up to it, and dives, in m; steps it is given to.
const DIVE_RUN_UP: float = 6.0
const DIVE_FROM_THE_WALL: float = 1.0
const DIVE_STEPS: int = 240
## How far from the body of the mouse the cat dives at it, in m: within the reach of a dive.
const DIVE_GAP: float = 0.5
## How much lower than standing the camera of a cat on the ground looks from, at least, in m.
const LOWERED: float = 0.2
## How far within the reach of a touch a catch is played, in m.
const IN_REACH_MARGIN: float = 0.1
## The share of its top speed a runner has at least as it vaults at it.
const AT_TOP_SPEED: float = 0.99


## Runs along +X, and dives once its runner is at `at` along X.
class DiveAt:
	extends IntentSource

	var dived: bool = false
	var _runner: Player
	var _at: float

	func _init(runner: Player, at: float) -> void:
		_runner = runner
		_at = at

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = Vector3.RIGHT
		if not dived and _runner.global_position.x >= _at:
			intent.dive_pressed = true
			dived = true
		return intent


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_the_arena_has_all_its_obstacles() -> void:
	var chase: Chase = _add_chase()
	var tuning: MovementTuning = chase.players[ONE].tuning
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var ground_top: float = _box_of(arena.get_node("Ground") as StaticBody3D).end.y

	# Enclosed by walls not to be run along, about 24 m by 24 m.
	var enclosure: Array[AABB] = _boxes(arena, "Enclosure", "the enclosure")
	var inside: AABB = _inside_of(enclosure)
	assert_almost_eq(inside.size.x, ARENA_SIZE, ARENA_TOLERANCE, "about 24 m wide")
	assert_almost_eq(inside.size.z, ARENA_SIZE, ARENA_TOLERANCE, "about 24 m deep")
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
	# The low passages are the tunnels, under their roofs.
	var roofs: Array[AABB] = []
	for tunnel: Node in arena.get_node("Tunnels").get_children():
		roofs.append(_box_of(tunnel.get_node("Roof") as StaticBody3D))
	assert_gte(roofs.size(), 2, "the arena has low passages to slide under")
	for box: AABB in roofs:
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


func test_each_low_wall_is_vaulted_both_ways_at_top_speed() -> void:
	# docs/specs/chase-mode.md, choices accepted after the vault: a low wall of the arena is
	# vaulted at top speed going out, from the side of the centre, and coming back, from the
	# side of the enclosure, which stands farther than any vault would land.
	var chase: Chase = _add_chase()
	await _assert_each_low_wall_is_vaulted_both_ways(chase, 0.0, "")


func test_the_chase_arena_keeps_its_rules_at_the_realistic_tempo() -> void:
	# docs/specs/realistic-tempo.md, decision 9: the tuning of the project, each low wall
	# vaulted both ways at the top speed, then at the top speed of tier 3 of the flow; each
	# platform above a jump followed by a mantle from the floor, reached by its ledge block.
	var chase: Chase = _add_chase()
	var tuning: MovementTuning = chase.players[ONE].tuning
	assert_almost_eq(tuning.top_speed, 6.5, PRECISION, "the run of the spec")
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var tier_3: float = bonuses[tuning.flow_tier_count - 1]
	await _assert_each_low_wall_is_vaulted_both_ways(chase, 0.0, "at the top speed, ")
	await _assert_each_low_wall_is_vaulted_both_ways(chase, tier_3, "at tier 3, ")

	var arena: Node3D = chase.get_node("Arena") as Node3D
	var ground_top: float = _box_of(arena.get_node("Ground") as StaticBody3D).end.y
	var blocks: Array[AABB] = _boxes(arena, "Blocks", "blocks to climb")
	var from_the_floor: float = tuning.jump_height + tuning.mantle_max_height
	for box: AABB in _boxes(arena, "Platforms", "a platform"):
		var height: float = box.end.y - ground_top
		assert_gt(height, from_the_floor + PLATFORM_MARGIN, "above a jump and a mantle")
		assert_true(_has_a_ledge_to(box, blocks, tuning), "reached by its ledge block")


func test_the_catch_of_a_touch_is_observed_not_the_contact() -> void:
	# docs/specs/chase-tag.md, decision 1: the bodies running into each other catch nothing;
	# a touch of the cat in reach does, dated.
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	var tuning: MovementTuning = cat.tuning
	var touching: float = 2.0 * tuning.capsule_radius
	cat.intent_source = ScriptedIntentSource.new().hold(Vector3.RIGHT, false, 200)
	mouse.intent_source = ScriptedIntentSource.new().hold(Vector3.LEFT, false, 200)
	var closest: float = INF
	for step: int in 200:
		closest = minf(closest, _apart(cat, mouse))
		await get_tree().physics_frame
	assert_lt(closest, touching, "the bodies ran into each other")
	assert_eq(chase.chase.phase, ChaseState.Phase.RUNNING, "and the round goes on")

	# The cat touches the mouse in front of it, within the reach of a touch.
	mouse.teleport(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)))
	cat.teleport(Transform3D(Basis.IDENTITY, Vector3.BACK * _in_reach(tuning)))
	cat.intent_source = ScriptedIntentSource.new().gesture(Vector3.ZERO)
	mouse.intent_source = ScriptedIntentSource.new()
	var touched_at: int = chase.match_steps
	for step: int in 10:
		await get_tree().physics_frame
		if chase.chase.phase != ChaseState.Phase.RUNNING:
			break
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round is over")
	assert_eq(chase.chase.round_winner_role, ChaseState.Role.CAT, "won by the cat")
	# The touch is played at the next step, and seen reaching at the one after.
	assert_eq(chase.chase.end_step, touched_at + 2, "a catch message, dated")
	# The screen between two rounds waits for the pause after a catch
	# (docs/specs/chase-tag-polish.md, decision 3), then follows the match at every frame shown.
	while chase.catch_pause > 0:
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: ChaseRoundScreen = chase.get_node("Screens/RoundScreen") as ChaseRoundScreen
	assert_true(screen.visible, "the screen between two rounds shows")
	assert_eq(
		screen.lines(),
		["CAUGHT!", "CAT WINS", "PLAYER 1   1 - 0   PLAYER 2"],
		"caught: the winner, the score"
	)


func test_the_touched_mouse_reacts() -> void:
	# docs/specs/chase-tag-polish.md, decision 3: the round is over at the very step of the
	# catch; the mouse stumbles after a touch and falls flat after a dive; CAUGHT! waits for
	# the tuned pause, so that its reaction is seen.
	var chase: Chase = _add_chase()
	var screen: ChaseRoundScreen = chase.get_node("Screens/RoundScreen") as ChaseRoundScreen
	var tuning: MovementTuning = chase.players[ONE].tuning
	var pause: int = roundi(tuning.chase_catch_pause * STEPS_PER_SECOND)
	assert_gt(pause, 0, "a pause")
	await _wait_for_go(chase)
	var mouse: Player = chase.players[chase.chase.mouse()]
	await _catch(chase, Vector3(-6.0, 0.0, 6.0))
	var cat: Player = chase.players[chase.chase.cat]
	var heights: Array[float] = []
	var shown: Array[RunnerAnimation.Clip] = await _the_reaction(chase, cat, mouse, screen, heights)
	assert_eq(shown[0], RunnerAnimation.Clip.STUMBLE, "a touch: the mouse stumbles at once")

	# The next round: the cat runs at the mouse standing near a wall, and dives.
	await _wait_for_go(chase)
	cat = chase.players[chase.chase.cat]
	mouse = chase.players[chase.chase.mouse()]
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var face: float = _inside_of(_boxes(arena, "Enclosure", "the enclosure")).end.x
	var radius: float = tuning.capsule_radius
	var mouse_at: float = face - radius - DIVE_FROM_THE_WALL
	mouse.teleport(Transform3D(Basis.looking_at(Vector3.RIGHT), Vector3(mouse_at, 0.0, 0.0)))
	mouse.intent_source = ScriptedIntentSource.new()
	cat.teleport(
		Transform3D(Basis.looking_at(Vector3.RIGHT), Vector3(face - DIVE_RUN_UP, 0.0, 0.0))
	)
	cat.intent_source = DiveAt.new(cat, mouse_at - 2.0 * radius - DIVE_GAP)
	for step: int in DIVE_STEPS:
		await get_tree().physics_frame
		if chase.chase.phase != ChaseState.Phase.RUNNING:
			break
	assert_eq(cat.motor.tag.gesture, Tag.Gesture.DIVE, "the cat dived")
	heights.clear()
	shown = await _the_reaction(chase, cat, mouse, screen, heights)
	for clip: RunnerAnimation.Clip in shown:
		assert_eq(clip, RunnerAnimation.Clip.FALL_FLAT, "a dive: the mouse falls flat, and lies")
	var lowest: float = heights.min()
	assert_lt(lowest, tuning.camera_look_height - LOWERED, "the camera of the cat goes down")


func test_the_two_players_start_face_to_face() -> void:
	var chase: Chase = _add_chase()
	# Both push forward through the countdown: they are held at their start points.
	_push_forward(chase)
	await _wait_for_the_end_of_the_countdown(chase)
	_assert_face_to_face(chase, "the first round")
	await _wait_for_go(chase)
	# The cat catches the mouse at once, away from the start: then the next round.
	await _catch(chase, Vector3(-6.0, 0.0, 6.0))
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the first round is over")
	_push_forward(chase)
	await _wait_for_the_end_of_the_countdown(chase)
	_assert_face_to_face(chase, "the second round")
	await _wait_for_go(chase)
	assert_eq(chase.chase.cat, TWO, "with the roles swapped")


func test_a_catch_on_the_step_the_time_ends_lets_the_mouse_win() -> void:
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var time_up: int = chase.chase.start_step + chase.chase.round_steps()
	while chase.match_steps < time_up - 2:
		await get_tree().physics_frame
	# The cat touches the mouse in reach: its touch is observed at the step the time ends.
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	var at: Vector3 = Vector3(-6.0, 0.0, 6.0)
	mouse.teleport(Transform3D(Basis.IDENTITY, at))
	cat.teleport(Transform3D(Basis.IDENTITY, at + Vector3.BACK * _in_reach(cat.tuning)))
	cat.intent_source = ScriptedIntentSource.new().gesture(Vector3.ZERO)
	var caught_at_the_time_up: bool = false
	for step: int in 3:
		await get_tree().physics_frame
		# The step the chase is about to play: the catch it sees then.
		if chase.match_steps + 1 == time_up:
			caught_at_the_time_up = Chase.catches(cat, mouse)

	assert_true(caught_at_the_time_up, "the touch catches the mouse at the step the time ends")
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
	await _catch(chase, Vector3(-6.0, 0.0, 6.0))
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round is over")

	await _wait_for_go(chase)

	for player: int in ChaseState.PLAYERS:
		assert_eq(chase.chase.flows[player].gauge, 0.0, "an empty gauge at GO")
		assert_eq(chase.players[player].motor.top_speed_bonus, 0.0, "and no speed bonus")


func test_the_dive_stops_against_a_wall() -> void:
	# docs/specs/chase-tag.md, decision 3: nothing stops a dive but a wall, against which it
	# stops.
	var chase: Chase = _add_chase()
	await _wait_for_go(chase)
	var cat: Player = chase.players[chase.chase.cat]
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var face: float = _inside_of(_boxes(arena, "Enclosure", "the enclosure")).end.x
	var radius: float = cat.tuning.capsule_radius
	cat.teleport(
		Transform3D(Basis.looking_at(Vector3.RIGHT), Vector3(face - DIVE_RUN_UP, 0.0, 0.0))
	)
	var source: DiveAt = DiveAt.new(cat, face - radius - DIVE_FROM_THE_WALL)
	cat.intent_source = source
	var farthest: float = -INF
	var states: Dictionary[RunnerMotor.State, bool] = {}
	for step: int in DIVE_STEPS:
		await get_tree().physics_frame
		farthest = maxf(farthest, cat.global_position.x)
		states[cat.motor.state] = true
		if source.dived and cat.motor.state == RunnerMotor.State.DOWN:
			break

	assert_true(source.dived, "the cat dives 1 m from the wall")
	assert_true(states.has(RunnerMotor.State.DIVING), "it dives")
	assert_lte(farthest, face - radius + NEAR, "it stops against the wall, not through it")
	assert_eq(cat.motor.state, RunnerMotor.State.DOWN, "and ends on the ground")


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


## The cat of the round under way touches the mouse put at `at`, within the reach of a touch
## ahead of the cat (along -Z, where it looks), and the round is over.
func _catch(chase: Chase, at: Vector3) -> void:
	var cat: Player = chase.players[chase.chase.cat]
	var mouse: Player = chase.players[chase.chase.mouse()]
	mouse.teleport(Transform3D(Basis.IDENTITY, at))
	cat.teleport(Transform3D(Basis.IDENTITY, at + Vector3.BACK * _in_reach(cat.tuning)))
	cat.intent_source = ScriptedIntentSource.new().gesture(Vector3.ZERO)
	mouse.intent_source = ScriptedIntentSource.new()
	for step: int in 10:
		await get_tree().physics_frame
		if chase.chase.phase != ChaseState.Phase.RUNNING:
			return


## The round of `chase` has just been won by a catch of its mouse `mouse` by its cat `cat`: at
## each step of the pause after it, the clip the body of the mouse shows, the screen between
## two rounds hidden (and in `heights`, how high above its feet the camera of the cat is);
## then that screen shows CAUGHT!.
func _the_reaction(
	chase: Chase, cat: Player, mouse: Player, screen: ChaseRoundScreen, heights: Array[float]
) -> Array[RunnerAnimation.Clip]:
	var pause: int = roundi(cat.tuning.chase_catch_pause * STEPS_PER_SECOND)
	assert_eq(chase.chase.phase, ChaseState.Phase.ROUND_OVER, "the round is over")
	assert_eq(chase.chase.round_winner_role, ChaseState.Role.CAT, "won by the cat")
	var caught_at: int = chase.chase.end_step
	assert_eq(chase.match_steps, caught_at, "at the very step of the catch")
	var shown: Array[RunnerAnimation.Clip] = []
	while chase.match_steps < caught_at + pause:
		shown.append(mouse.animation.clip)
		heights.append(cat.camera_rig.global_position.y - cat.global_position.y)
		screen.refresh()
		var step: int = chase.match_steps - caught_at
		assert_false(screen.visible, "step %d of the pause: not yet" % step)
		await get_tree().physics_frame
	screen.refresh()
	assert_true(screen.visible, "the screen between two rounds after the pause")
	assert_eq(screen.lines()[0], "CAUGHT!", "CAUGHT!")
	assert_eq(chase.chase.end_step, caught_at, "the round still over at the step of the catch")
	return shown


## How far apart the axes of two runners are, their bodies a margin within the reach of a
## touch.
func _in_reach(tuning: MovementTuning) -> float:
	return 2.0 * tuning.capsule_radius + tuning.tag_touch_reach - IN_REACH_MARGIN


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


## Each low wall of the arena of `chase`, vaulted by the pilot at the top speed raised by
## `bonus` (the share a tier of the flow gives), going out, from the side of the centre,
## and coming back, from the side of the enclosure, which stands farther than any vault
## would land. `how` starts the messages.
func _assert_each_low_wall_is_vaulted_both_ways(chase: Chase, bonus: float, how: String) -> void:
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var inside: AABB = _inside_of(_boxes(arena, "Enclosure", "the enclosure"))
	var centre: Vector3 = (arena.get_node("Centre") as Node3D).global_position
	for wall: Node in arena.get_node("LowWalls").get_children():
		var box: AABB = _box_of(wall as StaticBody3D)
		var middle: Vector3 = box.get_center()
		var across: Vector3 = Vector3(signf(middle.x - centre.x), 0.0, 0.0)
		if box.size.z < box.size.x:
			across = Vector3(0.0, 0.0, signf(middle.z - centre.z))
		var half: float = box.size.dot(across.abs()) / 2.0
		var line: Vector3 = Vector3(middle.x, centre.y, middle.z)
		var out_start: Vector3 = line - across * (line - centre).dot(across)
		var room_outside: float = absf((inside.get_center() - line).dot(across))
		room_outside += inside.size.dot(across.abs()) / 2.0 - half
		var in_start: Vector3 = line + across * (half + minf(RUN_UP, room_outside - 0.4))
		var starts: Array[Vector3] = [out_start, in_start]
		var ways: Array[Vector3] = [across, -across]
		for run: int in starts.size():
			var context: String = "%s%s, %s: " % [how, wall.name, ["going out", "coming in"][run]]
			var seen: Array[int] = await _pilot_at(chase, starts[run], ways[run], bonus)
			assert_gt(seen[0], 0, context + "the pilot vaults it")
			assert_eq(seen[1], 0, context + "without a jump")
			assert_eq(seen[2], 1, context + "at its top speed")


## A runner of its own, its top speed raised by `bonus`, led by the pilot from `start` the
## way `way` in the arena of `chase`: the steps it vaulted, the jumps it made, and 1 if it
## went at its top speed as it started its first vault (0 otherwise).
func _pilot_at(chase: Chase, start: Vector3, way: Vector3, bonus: float = 0.0) -> Array[int]:
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	chase.add_child(runner)
	runner.teleport(Transform3D(Basis.looking_at(way), start))
	runner.motor.top_speed_bonus = bonus
	await get_tree().physics_frame
	runner.intent_source = PilotIntentSource.new(runner, way)
	var seen: Array[int] = [0, 0, 0]
	var speed: float = 0.0
	for step: int in RUN_STEPS:
		await get_tree().physics_frame
		var vaulting: bool = runner.motor.state == RunnerMotor.State.VAULTING
		if vaulting and seen[0] == 0:
			seen[2] = int(speed >= runner.motor.top_speed() * AT_TOP_SPEED)
		seen[0] += int(vaulting)
		for event: RunnerEvent in runner.motor.events:
			seen[1] += int(event.kind == RunnerEvent.Kind.JUMP)
		speed = Vector2(runner.velocity.x, runner.velocity.z).length()
	runner.queue_free()
	return seen


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
