extends ReplayTest
## The chase against the bot (docs/specs/chase-bot.md) in the real physics, without a
## screen: the bot in the arena of game/levels/chase.tscn (its links, its slides, its
## trick, its rounds against another bot, its touches and dives as the cat), the links of the
## arena run by the pilot, and the mode as the start screen starts it, played on the keyboard
## and on the gamepad.
## Much faster than real time with the same fixed step of 1/60 s, many steps to a frame
## (see before_all); the rounds between bots (ChaseBotRounds) are played once for the
## four tests that read them.

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const ONE: int = Chase.PLAYER_ONE
const TWO: int = Chase.PLAYER_TWO
const EASY: ChaseBot.Level = ChaseBot.Level.EASY
const NORMAL: ChaseBot.Level = ChaseBot.Level.NORMAL
const HARD: ChaseBot.Level = ChaseBot.Level.HARD
## Rounds of each pairing of the spec, and the bounds of the cat's wins (decision 10 as
## amended; NORMAL against NORMAL in the arena of docs/specs/chase-arena.md, decision 8).
const ROUNDS: int = 6
const HARD_CAT_LEAST: int = 4
const EASY_CAT_MOST: int = 3
const EVEN_CAT_LEAST: int = 1
const EVEN_CAT_MOST: int = 5
## The longest a bot may go without getting nearer its goal, in s.
const LONGEST_WITHOUT_PROGRESS: float = 2.0
## How far a bot runs up to a link, in m, and how near its goal it has reached it.
const RUN_UP: float = 2.0
const AT_THE_GOAL: float = 1.0
## Steps a bot may take to reach a goal, and steps a run along a link lasts at most.
const GOAL_STEPS: int = 600
const LINK_STEPS: int = 240
## The heights of what a link climbs to or comes down from, how near its altitude the end
## of a link is reached, in m, and how far aside of its line, in m.
const ALTITUDE: float = 0.3
const ASIDE: float = 1.0
## How long the bot is given to come down from a platform, in steps.
const DESCENT_STEPS: int = 300
## How far the cat runs at the mouse standing still, in m; steps the cat is given to catch it.
const RUN_AT_THE_MOUSE: float = 6.0
const CATCH_STEPS: int = 300
## Where the bot waits while the player makes its gestures, and the steps the player runs
## before each of them.
const FAR_CORNER: Vector3 = Vector3(11.0, 0.0, 11.0)
const GESTURE_RUN_UP_STEPS: int = 30
## Steps a device is held, then left to settle; more steps than a countdown lasts.
const PUSH_STEPS: int = 20
const COUNTDOWN_STEPS: int = 400
## What the start screen and the level choice show.
const CHASE_VS_BOT: String = "CHASE VS BOT"
const LEVELS: Array[String] = ["EASY", "NORMAL", "HARD"]
const MAIN_SCENE_SETTING: String = "application/run/main_scene"
const FRAMES: int = 2
const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")

## How far before and after a tunnel of the arena a way under it starts and ends, in m.
const UNDER_RUN: float = 3.0

## How many times faster than real time the fixed steps run here, and how many of them
## may run in one frame: nothing but the physics runs, and the same steps play sooner.
const FAST: int = 400
const STEPS_PER_FRAME: int = 64

## The rounds between bots, once played.
var _rounds: ChaseBotRounds
var _steps_per_frame_before: int


## What a runner went through on a run: whether it arrived, the highest it went above its
## start, its mantles, and the states of its motor.
class Run:
	var arrived: bool = false
	var highest: float = -INF
	var mantles: int = 0
	var states: Dictionary[RunnerMotor.State, bool] = {}

	func went_through(state: RunnerMotor.State) -> bool:
		return states.has(state)


## What a cat did as it ran at the mouse: its gestures, and whether it caught the mouse.
class Catch:
	var gestures: Array[Tag.Gesture] = []
	var caught: bool = false


func before_all() -> void:
	super.before_all()
	_steps_per_frame_before = Engine.max_physics_steps_per_frame
	Engine.physics_ticks_per_second = STEPS_PER_SECOND * FAST
	Engine.time_scale = FAST
	Engine.max_physics_steps_per_frame = STEPS_PER_FRAME


func after_all() -> void:
	Engine.max_physics_steps_per_frame = _steps_per_frame_before
	super.after_all()


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_the_bot_vaults_mantles_climbs_and_slides() -> void:
	var chase: Chase = await _add_still_chase()
	var tuning: MovementTuning = chase.players[ONE].tuning
	var links: Node = chase.get_node("Arena/Links")
	# Over each low wall, both ways.
	for link: Node in links.get_node("Vaults").get_children():
		var vault: NavigationLink3D = link as NavigationLink3D
		var start: Vector3 = vault.get_global_start_position()
		var end: Vector3 = vault.get_global_end_position()
		for way: int in 2:
			var from: Vector3 = start if way == 0 else end
			var to: Vector3 = end if way == 0 else start
			var seen: Run = await _run_the_bot(chase, from, to)
			var context: String = "%s, %s: " % [link.name, ["out", "back"][way]]
			assert_true(seen.arrived, context + "the bot gets there")
			assert_true(seen.went_through(RunnerMotor.State.VAULTING), context + "over the wall")
	# Onto each block, from each side its links climb from.
	for link: Node in links.get_node("Mantles").get_children():
		var mantle: NavigationLink3D = link as NavigationLink3D
		var from: Vector3 = mantle.get_global_start_position()
		var seen: Run = await _run_the_bot(chase, from, mantle.get_global_end_position())
		assert_true(seen.arrived, "%s: the bot gets on the block" % link.name)
		assert_true(seen.went_through(RunnerMotor.State.MANTLING), "%s: by a mantle" % link.name)
	# Onto each platform, from the floor: a mantle onto its ledge block, then another.
	for link: Node in links.get_node("Climbs").get_children():
		var climb: NavigationLink3D = link as NavigationLink3D
		var floor_before: Vector3 = _floor_before_the_ledge_of(links, climb)
		var top: Vector3 = climb.get_global_end_position()
		var seen: Run = await _run_the_bot(chase, floor_before, top)
		assert_true(seen.arrived, "%s: the bot gets on the platform" % link.name)
		assert_eq(seen.mantles, 2, "%s: onto the ledge, then onto the platform" % link.name)
	# Under each low passage (a tunnel), from one side to the other, both ways.
	for tunnel: Node in chase.get_node("Arena/Tunnels").get_children():
		var box: AABB = _box_of(tunnel.get_node("Roof") as StaticBody3D)
		# Along its sides.
		var side: AABB = _box_of(tunnel.get_child(0) as StaticBody3D)
		var axis: Vector3 = Vector3.RIGHT if side.size.x > side.size.z else Vector3.BACK
		var middle: Vector3 = Vector3(box.get_center().x, 0.0, box.get_center().z)
		var out: float = box.size.dot(axis) / 2.0 + UNDER_RUN
		for way: Vector3 in [axis, -axis]:
			var seen: Run = await _run_the_bot(chase, middle - way * out, middle + way * out, 0.0)
			var passage: String = "%s tunnel, going %s" % [tunnel.name, way]
			assert_true(seen.arrived, passage + ": the bot gets to the other side")
			assert_true(
				seen.went_through(RunnerMotor.State.SLIDING), passage + ": sliding under it"
			)
			assert_lt(seen.highest, tuning.slide_capsule_height, passage + ": low all along")


func test_the_easy_bot_takes_neither_platforms_nor_blocks() -> void:
	var chase: Chase = await _add_still_chase()
	var easy: ChaseBotIntentSource = chase.make_bot(TWO, EASY)
	var hard: ChaseBotIntentSource = chase.make_bot(ONE, HARD)
	var ground_top: float = 0.0
	var climb: NavigationLink3D = chase.get_node("Arena/Links/Climbs/SouthEast") as NavigationLink3D
	var platform: Vector3 = climb.get_global_end_position()
	var from: Vector3 = Vector3(0.0, ground_top, 0.0)

	var path: PackedVector3Array = easy.path_between(from, platform, easy.navigation_layers())

	assert_gt(path.size(), 1, "EASY finds a path towards the platform")
	for corner: Vector3 in path:
		assert_lt(corner.y, ground_top + ALTITUDE + 0.2, "on the ground only, never on a block")
	var last: Vector3 = path[path.size() - 1]
	assert_gt(last.distance_to(platform), 1.0, "and never up to the platform")
	var hard_path: PackedVector3Array = hard.path_between(from, platform, hard.navigation_layers())
	assert_almost_eq(
		hard_path[hard_path.size() - 1].distance_to(platform), 0.0, 0.5, "HARD gets up there"
	)


func test_the_bot_does_a_trick_going_down_from_a_platform() -> void:
	var chase: Chase = await _add_still_chase()
	var links: Node = chase.get_node("Arena/Links")
	var drop: NavigationLink3D = links.get_node("Drops/PlatformNorthWest") as NavigationLink3D
	var climb: NavigationLink3D = links.get_node("Climbs/NorthWest") as NavigationLink3D
	var top: Vector3 = climb.get_global_end_position()
	var below: Vector3 = drop.get_global_end_position()
	var bot: ChaseBotIntentSource = _bot_towards(chase, HARD, top, below + Vector3(0.0, 0.0, 2.0))
	var bot_runner: Player = chase.players[TWO]
	var tricks: Array[AirTrick] = []
	var crashes: int = 0
	for step: int in DESCENT_STEPS:
		await get_tree().physics_frame
		for event: RunnerEvent in bot_runner.motor.events:
			if event.kind == RunnerEvent.Kind.TRICK:
				tricks.append(event.trick)
			crashes += int(event.kind == RunnerEvent.Kind.CRASH)
		if not tricks.is_empty() and bot_runner.is_on_floor():
			break

	assert_eq(crashes, 0, "no crash")
	assert_eq(tricks.size(), 1, "a trick, paid on the landing")
	if tricks.size() == 1:
		assert_eq(tricks[0].recipe.turns, 1, "a simple one")
		assert_eq(tricks[0].recipe.twists, 0, "without a twist")
		assert_false(tricks[0].unposed, "posed by the slide")
		assert_true(tricks[0].perfect, "PERFECT at the HARD level")
	assert_lt(bot_runner.global_position.y, ALTITUDE, "down on the ground")
	assert_not_null(bot, "the bot ran it")


func test_the_bot_never_stays_stuck() -> void:
	var played: ChaseBotRounds = await _played_rounds()
	var limit: int = roundi(LONGEST_WITHOUT_PROGRESS * STEPS_PER_SECOND)
	for level: ChaseBot.Level in [EASY, NORMAL, HARD] as Array[ChaseBot.Level]:
		var name: String = ChaseBot.Level.keys()[level]
		assert_gt(played.steps_played[level], 0, name + ": the bots played")
		assert_lte(
			played.longest_without_progress[level], limit, name + ": never 2 s without progress"
		)


func test_the_bot_drives_only_with_intents() -> void:
	var played: ChaseBotRounds = await _played_rounds()
	var chase: Chase = await _add_still_chase()
	var bot: ChaseBotIntentSource = chase.make_bot(TWO, NORMAL)
	var source: ChaseIntentSource = chase.players[TWO].intent_source as ChaseIntentSource

	assert_not_null(source, "the bot's runner reads the intents of the chase")
	assert_not_null(bot, "from the bot")
	assert_eq(played.steps_without_one_intent, 0, "one intent per step, at every step")
	assert_eq(played.steps_too_fast, 0, "never faster than a runner of its tier of the flow")


func test_the_cat_bot_catches_with_its_gestures() -> void:
	var chase: Chase = await _add_still_chase()
	var cat: Player = chase.players[TWO]
	var mouse: Player = chase.players[ONE]
	var start: Transform3D = chase.spawns[ONE]
	var way: Vector3 = -start.basis.z
	# A mouse standing still, a few metres ahead.
	_bot_towards(chase, HARD, start.origin, start.origin + way * RUN_AT_THE_MOUSE)
	cat.motor.can_tag = true
	var seen: Catch = await _the_catch(cat, mouse)
	assert_eq(seen.gestures, [Tag.Gesture.TOUCH], "the bot touches the mouse standing still")
	assert_true(seen.caught, "and catches it")

	# A mouse fleeing, its body ahead of the cat's halfway between the reach of a touch and the
	# reach of a dive (1.3 m with the reaches of docs/specs/chase-tag.md): out of the first,
	# within the second.
	var tuning: MovementTuning = cat.tuning
	var between: float = (tuning.tag_touch_reach + tuning.tag_dive_reach) / 2.0
	var gap: float = between + 2.0 * tuning.capsule_radius
	_bot_towards(chase, HARD, start.origin, start.origin + way * gap)
	mouse.held = false
	mouse.intent_source = ScriptedIntentSource.new().hold(way, false, CATCH_STEPS)
	seen = await _the_catch(cat, mouse)
	assert_eq(seen.gestures, [Tag.Gesture.DIVE], "the bot dives on the mouse that flees")
	assert_true(seen.caught, "and catches it")


func test_the_easy_bot_never_dives() -> void:
	var played: ChaseBotRounds = await _played_rounds()
	assert_gt(played.touches[EASY], 0, "the EASY cat touched")
	assert_eq(played.dives[EASY], 0, "and never dived")


func test_the_cat_and_the_mouse_are_even_with_the_gestures() -> void:
	# docs/specs/chase-tag.md, decision 11: with the touch and the dive, the NORMAL cat wins
	# some of its rounds against the NORMAL mouse, not all of them, nor none.
	var played: ChaseBotRounds = await _played_rounds()
	assert_eq(played.rounds[0], ROUNDS, "6 rounds of NORMAL against NORMAL")
	assert_gt(played.touches[NORMAL] + played.dives[NORMAL], 0, "the cat made its gestures")
	assert_between(played.cat_wins[0], EVEN_CAT_LEAST, EVEN_CAT_MOST, "the cat wins 1 to 5")


func test_a_higher_level_wins_more() -> void:
	var played: ChaseBotRounds = await _played_rounds()
	for line: String in played.lines:
		gut.p(line)
	gut.p("cat wins %s of %s, %d ms" % [played.cat_wins, played.rounds, played.duration])
	assert_eq(played.rounds, [ROUNDS, ROUNDS, ROUNDS] as Array[int], "6 rounds a pairing")
	assert_gte(played.cat_wins[1], HARD_CAT_LEAST, "HARD cat against EASY mouse")
	assert_lte(played.cat_wins[2], EASY_CAT_MOST, "EASY cat against HARD mouse")
	assert_gt(played.cat_wins[1], played.cat_wins[2], "the higher level wins more, either role")


func test_the_cat_and_the_mouse_are_even_at_the_same_level() -> void:
	# docs/specs/chase-arena.md, decision 8: the NORMAL cat wins some of its rounds against
	# the NORMAL mouse, not all of them, nor none.
	var played: ChaseBotRounds = await _played_rounds()
	assert_eq(played.rounds[0], ROUNDS, "6 rounds of NORMAL against NORMAL")
	assert_between(played.cat_wins[0], EVEN_CAT_LEAST, EVEN_CAT_MOST, "the cat wins 1 to 5")


func test_the_polish_keeps_the_balance() -> void:
	# docs/specs/chase-tag-polish.md, decision 5: with the new times (lying down, the getting
	# up, the pause after a catch), the NORMAL cat still wins 1 to 5 of its 6 rounds against
	# the NORMAL mouse.
	var tuning: MovementTuning = load("res://game/core/movement_tuning.tres") as MovementTuning
	assert_gt(tuning.tag_down_lying, 0.0, "the new times")
	var played: ChaseBotRounds = await _played_rounds()
	assert_eq(played.rounds[0], ROUNDS, "6 rounds of NORMAL against NORMAL")
	assert_gt(played.touches[NORMAL] + played.dives[NORMAL], 0, "the cat made its gestures")
	assert_between(played.cat_wins[0], EVEN_CAT_LEAST, EVEN_CAT_MOST, "the cat wins 1 to 5")


func test_each_link_of_the_arena_is_run_through() -> void:
	var chase: Chase = await _add_still_chase()
	var links: Node = chase.get_node("Arena/Links")
	for group: Node in links.get_children():
		for node: Node in group.get_children():
			var link: NavigationLink3D = node as NavigationLink3D
			var ways: int = 2 if link.bidirectional else 1
			for way: int in ways:
				var start: Vector3 = link.get_global_start_position()
				var end: Vector3 = link.get_global_end_position()
				if way == 1:
					var swap: Vector3 = start
					start = end
					end = swap
				var seen: Run = await _pilot_along(chase, start, end)
				var back: String = " back" if way == 1 else ""
				var context: String = "%s/%s%s: " % [group.name, link.name, back]
				assert_true(seen.arrived, context + "on the other side")
				var vaulted: bool = seen.went_through(RunnerMotor.State.VAULTING)
				var mantled: bool = seen.went_through(RunnerMotor.State.MANTLING)
				match String(group.name):
					"Vaults":
						assert_true(vaulted, context + "by a vault")
						assert_false(mantled, context + "not a mantle")
					"Mantles", "Climbs":
						assert_true(mantled, context + "by a mantle")
					"Drops":
						var fell: bool = seen.went_through(RunnerMotor.State.FALLING)
						assert_true(fell, context + "down through the air")
						assert_false(mantled or vaulted, context + "neither a mantle nor a vault")
	# The links that climb are the ones EASY does not take: on their own layer.
	for group: String in ["Mantles", "Climbs"]:
		for node: Node in links.get_node(group).get_children():
			var layers: int = (node as NavigationLink3D).navigation_layers
			assert_eq(layers, ChaseBotIntentSource.CLIMB_LAYER, node.name + ": a link that climbs")
	for group: String in ["Vaults", "Drops"]:
		for node: Node in links.get_node(group).get_children():
			var layers: int = (node as NavigationLink3D).navigation_layers
			assert_eq(layers, ChaseBotIntentSource.GROUND_LAYER, node.name + ": any runner's")


func test_the_gestures_work_on_the_keyboard_as_on_the_gamepad() -> void:
	# docs/specs/chase-tag.md, decision 2: the touch on the left click and the right trigger,
	# the dive on the right click and the left trigger.
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	chase.against_the_bot = true
	add_child_autofree(chase)
	await _wait_for_go(chase)
	var cat: Player = chase.players[ONE]
	assert_eq(chase.chase.role(ONE), ChaseState.Role.CAT, "the player is the cat")
	# The bot waits in a far corner.
	var bot: Player = chase.players[TWO]
	bot.held = true
	bot.teleport(Transform3D(Basis.IDENTITY, FAR_CORNER))
	var forward: InputEventKey = _key(KEY_W)
	Input.parse_input_event(forward)
	Input.flush_buffered_events()
	var presses: Array[InputEvent] = [
		_mouse_button(MOUSE_BUTTON_LEFT),
		_trigger(JOY_AXIS_TRIGGER_RIGHT),
		_mouse_button(MOUSE_BUTTON_RIGHT),
		_trigger(JOY_AXIS_TRIGGER_LEFT),
	]
	var releases: Array[InputEvent] = [
		_mouse_button(MOUSE_BUTTON_LEFT, false),
		_trigger(JOY_AXIS_TRIGGER_RIGHT, false),
		_mouse_button(MOUSE_BUTTON_RIGHT, false),
		_trigger(JOY_AXIS_TRIGGER_LEFT, false),
	]
	var gestures: Array[Tag.Gesture] = []
	for index: int in presses.size():
		# From the start point, running forward: fast enough to dive.
		cat.teleport(chase.spawns[ONE])
		for step: int in GESTURE_RUN_UP_STEPS:
			await get_tree().physics_frame
		await _push(presses[index])
		gestures.append(cat.motor.tag.gesture if cat.motor.tag != null else -1)
		await _push(releases[index])
	var released: InputEventKey = forward.duplicate() as InputEventKey
	released.pressed = false
	await _push(released)
	var expected: Array[Tag.Gesture] = [
		Tag.Gesture.TOUCH, Tag.Gesture.TOUCH, Tag.Gesture.DIVE, Tag.Gesture.DIVE
	]
	assert_eq(gestures, expected, "a touch, a touch, a dive, a dive")
	assert_eq(chase.chase.phase, ChaseState.Phase.RUNNING, "catching nobody")


func test_the_mode_is_chosen_on_the_start_screen() -> void:
	var main: Main = await _add_main()
	var start: StartScreen = main.get_node("StartScreen") as StartScreen
	start.has_the_gamepad = func() -> bool: return false
	assert_eq(start.choice_label(StartScreen.Choice.CHASE_VS_BOT).text, CHASE_VS_BOT, "a choice")

	# The keyboard: down to the last choice (the ghost is greyed: skipped), then jump.
	for press: int in 4:
		await _press(_key(KEY_DOWN))
	assert_eq(start.selected(), StartScreen.Choice.CHASE_VS_BOT, "after CHASE")
	await _press(_key(KEY_SPACE))
	assert_null(main.mode, "the level first")
	assert_eq(start.level_texts(), LEVELS, "EASY, NORMAL, HARD")
	assert_eq(start.selected_level(), NORMAL, "NORMAL selected first")
	await _press(_key(KEY_SPACE))

	assert_true(main.mode is Chase, "the chase starts, without a gamepad")
	assert_false(start.visible, "the start screen is gone")
	var chase: Chase = main.mode as Chase
	if chase == null:
		return
	var views: Array[Node] = chase.find_children("*", "PlayerView", true, false)
	assert_eq(views.size(), 1, "one view")
	if views.size() == 1:
		var view: PlayerView = views[0] as PlayerView
		await get_tree().process_frame
		var window: Vector2 = main.get_viewport().get_visible_rect().size
		assert_almost_eq(view.size.x, window.x, 1.0, "in full screen")
		assert_same(view.followed, chase.players[ONE].camera_rig.camera(), "the player's")
	assert_true(chase.bots.has(TWO), "player 2 is a bot")
	assert_false(chase.bots.has(ONE), "player 1 is not")
	if chase.bots.has(TWO):
		assert_eq(chase.bots[TWO].mind.level, NORMAL, "a NORMAL one")
	assert_eq(chase.chase.role(ONE), ChaseState.Role.CAT, "the player is the cat")
	await _press(_key(KEY_ESCAPE))
	assert_true(start.visible, "Escape: back on the start screen")


func test_the_player_plays_on_the_keyboard_as_on_the_gamepad() -> void:
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	chase.against_the_bot = true
	add_child_autofree(chase)
	await _wait_for_go(chase)
	var one: Player = chase.players[ONE]
	var two: Player = chase.players[TWO]
	# The bot waits where it is: what moves is the player.
	two.held = true
	var from: Vector3 = one.global_position
	var towards: Vector3 = two.global_position

	var forward: InputEventKey = InputEventKey.new()
	forward.physical_keycode = KEY_W
	forward.pressed = true
	await _push(forward)
	var released: InputEventKey = forward.duplicate() as InputEventKey
	released.pressed = false
	await _push(released)
	assert_gt(_ahead(one, from, towards), 1.0, "the keyboard: forward")

	from = one.global_position
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.device = ChaseState.GAMEPAD_DEVICE
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -1.0
	await _push(stick)
	var let_go: InputEventJoypadMotion = stick.duplicate() as InputEventJoypadMotion
	let_go.axis_value = 0.0
	await _push(let_go)
	assert_gt(_ahead(one, from, towards), 1.0, "the gamepad: forward too")


## The gestures the motor of `cat` makes until it catches `mouse`, or for as long as it is
## given, and whether it caught it (Chase.catches) during one of them.
func _the_catch(cat: Player, mouse: Player) -> Catch:
	var seen: Catch = Catch.new()
	var last: Tag = null
	for step: int in CATCH_STEPS:
		await get_tree().physics_frame
		var gesture: Tag = cat.motor.tag
		if gesture != null and gesture != last:
			last = gesture
			seen.gestures.append(gesture.gesture)
		if Chase.catches(cat, mouse):
			seen.caught = true
			break
	cat.held = true
	mouse.held = true
	return seen


## A press of the mouse button `button`, or its release.
func _mouse_button(button: MouseButton, pressed: bool = true) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


## The trigger `axis` of the gamepad of player 2 pulled, or let go.
func _trigger(axis: JoyAxis, pulled: bool = true) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = ChaseState.GAMEPAD_DEVICE
	event.axis = axis
	event.axis_value = 1.0 if pulled else 0.0
	return event


## The rounds between bots of the spec, played once for the tests that read them.
func _played_rounds() -> ChaseBotRounds:
	if _rounds == null:
		_rounds = ChaseBotRounds.new(get_tree())
		await _rounds.run(self, ROUNDS)
	return _rounds


## A chase whose match does not run (no clock, no catch): its runners only, held, and
## its navigation baked and ready.
func _add_still_chase() -> Chase:
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	add_child_autofree(chase)
	chase.set_physics_process(false)
	chase.make_bot(TWO, NORMAL)
	var map: RID = (chase.get_node("Arena") as NavigationRegion3D).get_navigation_map()
	var bot: ChaseBotIntentSource = chase.bots[TWO]
	for step: int in COUNTDOWN_STEPS:
		await get_tree().physics_frame
		if not bot.path_between(Vector3(-7.0, 0.0, 0.0), Vector3(7.0, 0.0, 0.0), 1).is_empty():
			break
	assert_gt(NavigationServer3D.map_get_iteration_id(map), 0, "the navigation is ready")
	return chase


## Player 2 made a cat bot of `level` at `from`, running to player 1, held at `to`.
func _bot_towards(
	chase: Chase, level: ChaseBot.Level, from: Vector3, to: Vector3
) -> ChaseBotIntentSource:
	var bot: ChaseBotIntentSource = chase.make_bot(TWO, level)
	bot.play(ChaseState.Role.CAT)
	var runner: Player = chase.players[TWO]
	var other: Player = chase.players[ONE]
	other.teleport(Transform3D(Basis.IDENTITY, to))
	other.held = true
	var way: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	runner.teleport(Transform3D(Basis.looking_at(way.normalized()), from))
	runner.held = false
	return bot


func _box_of(body: StaticBody3D) -> AABB:
	var collider: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()


## A HARD bot run from `from` (moved back by `run_up`, if it is on the ground) to a goal at
## `to`: whether it got there, the highest it went, the motor states it went through, and
## its mantles.
func _run_the_bot(chase: Chase, from: Vector3, to: Vector3, run_up: float = RUN_UP) -> Run:
	var way: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	var start: Vector3 = from - way * run_up if from.y < ALTITUDE else from
	_bot_towards(chase, HARD, start, to)
	var runner: Player = chase.players[TWO]
	var seen: Run = Run.new()
	for step: int in GOAL_STEPS:
		await get_tree().physics_frame
		seen.states[runner.motor.state] = true
		for event: RunnerEvent in runner.motor.events:
			seen.mantles += int(event.kind == RunnerEvent.Kind.MANTLE)
		seen.highest = maxf(seen.highest, runner.global_position.y - start.y)
		var off: Vector3 = runner.global_position - to
		if Vector2(off.x, off.z).length() < AT_THE_GOAL and absf(off.y) < ALTITUDE:
			seen.arrived = true
			break
	runner.held = true
	return seen


## The floor before the mantle link onto the ledge block a climb starts from: where a bot
## comes from to climb onto the platform from the floor.
func _floor_before_the_ledge_of(links: Node, climb: NavigationLink3D) -> Vector3:
	var top: Vector3 = climb.get_global_start_position()
	for node: Node in links.get_node("Mantles").get_children():
		var mantle: NavigationLink3D = node as NavigationLink3D
		if mantle.get_global_end_position().distance_to(top) < ALTITUDE:
			return mantle.get_global_start_position()
	return top


## A runner of its own led by the pilot from before `start` (a run-up at its top speed,
## where the arena leaves room for one) towards `end` and on: whether it arrived on the
## other side (at the altitude of `end`, as far along the link as `end`, not more than a
## metre aside), and the motor states it went through.
func _pilot_along(chase: Chase, start: Vector3, end: Vector3) -> Run:
	var way: Vector3 = Vector3(end.x - start.x, 0.0, end.z - start.z)
	var length: float = way.length()
	way = way.normalized()
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	chase.add_child(runner)
	var room: float = _room_behind(chase, start, way)
	runner.teleport(Transform3D(Basis.looking_at(way), start - way * room))
	await get_tree().physics_frame
	runner.intent_source = PilotIntentSource.new(runner, way)
	var seen: Run = Run.new()
	for step: int in LINK_STEPS:
		await get_tree().physics_frame
		seen.states[runner.motor.state] = true
		var feet: Vector3 = runner.global_position
		var along: float = (feet - start).dot(way)
		var off: Vector3 = feet - start - way * along
		var aside: float = Vector2(off.x, off.z).length()
		var up_there: bool = absf(feet.y - end.y) < ALTITUDE and runner.is_on_floor()
		if up_there and along >= length - ChaseBotIntentSource.LINK_END_REACH and aside < ASIDE:
			seen.arrived = true
			break
	runner.queue_free()
	return seen


## How far back from `start`, against `way`, a runner may start without leaving the floor
## of `start` or running into something: as much as a run-up to the top speed asks, at
## most.
func _room_behind(chase: Chase, start: Vector3, way: Vector3) -> float:
	var tuning: MovementTuning = chase.players[ONE].tuning
	var run_up: float = tuning.top_speed * tuning.top_speed / (2.0 * tuning.ground_acceleration)
	var space: PhysicsDirectSpaceState3D = chase.get_world_3d().direct_space_state
	var room: float = 0.0
	while room < run_up:
		var feet: Vector3 = start - way * (room + 0.25)
		var down: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			feet + Vector3.UP * 0.5, feet + Vector3.DOWN * 0.5
		)
		var floor_hit: Dictionary = space.intersect_ray(down)
		if floor_hit.is_empty():
			break
		var body: Vector3 = feet + Vector3.UP * tuning.capsule_height / 2.0
		var back: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			start + Vector3.UP * tuning.capsule_height / 2.0, body - way * tuning.capsule_radius
		)
		if not space.intersect_ray(back).is_empty():
			break
		room += 0.25
	return room


func _wait_for_go(chase: Chase) -> void:
	for step: int in COUNTDOWN_STEPS:
		if chase.chase.phase == ChaseState.Phase.RUNNING:
			return
		await get_tree().physics_frame
	assert_eq(chase.chase.phase, ChaseState.Phase.RUNNING, "GO came")


## Gives the event to the engine as its device would, then lets the runners run a while.
func _push(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for step: int in PUSH_STEPS:
		await get_tree().physics_frame


## How far `runner` went from `from` towards `towards`, along the ground.
func _ahead(runner: Player, from: Vector3, towards: Vector3) -> float:
	var way: Vector3 = Vector3(towards.x - from.x, 0.0, towards.z - from.z).normalized()
	return (runner.global_position - from).dot(way)


func _add_main() -> Main:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	var main: Main = (load(main_scene) as PackedScene).instantiate() as Main
	add_child_autofree(main)
	await get_tree().process_frame
	return main


## Gives a key to the engine as the keyboard would, for a few frames, once the screen has
## been on screen for a frame: it ignores the frame it opens.
func _press(pressed: InputEventKey) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Input.parse_input_event(pressed)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame
	var release: InputEventKey = pressed.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame


func _key(physical: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = true
	return event
