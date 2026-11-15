class_name Chase
extends Node3D
## The chase: two players on one machine, in an arena of obstacles, in a split screen.
## Player 1, on the left, plays on the keyboard and the mouse only; player 2, on the right,
## on the gamepad (device 0) only (InputDevice). One is the cat, the other the mouse; the
## match (ChaseState, game/core) only learns what happens from dated messages: the start
## of a round at GO, the contact of the two bodies, which this level observes from their
## capsules, and the time up of the clock of the round (RoundClock). Before every round
## the players stand at their start points, the distance of the tuning apart on either
## side of the centre of the arena, face to face, held through the countdown; they wear
## the colour of their role. A fall out of the arena brings a player back to its start
## point, the time going on. The flow of each player counts its moves and gives its speed
## bonus to its motor; there is no weapon, no aim and no target (ChaseIntentSource). Between
## two rounds a screen shows the winner of the round and the score over the countdown;
## at the end of the match, the result, with the rematch and the way back to the menu.
## Against the bot (docs/specs/chase-bot.md), player 2 is a bot of the level chosen
## (ChaseBotIntentSource, game/player) and player 1 plays alone, in full screen, on the
## keyboard and the mouse or on the gamepad. A bot follows the navigation of the arena,
## baked from its blocks as the first bot comes, as low as a slide; it takes the links the
## arena declares and flees to its flee points; it is told its role before every round.
## Expected children: Arena (a NavigationRegion3D, with Centre, its marker, Links and
## FleePoints), Screens/Views/PlayerOne and Screens/Views/PlayerTwo (PlayerView),
## Screens/CountdownDisplay, Screens/RoundScreen and Screens/ResultScreen.

## A player chose MENU on the result screen: back to the start screen.
signal menu_requested

const PLAYER_ONE: int = 0
const PLAYER_TWO: int = 1
const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## The device of each player.
const DEVICES: Array[InputDevice.Kind] = [
	InputDevice.Kind.KEYBOARD_AND_MOUSE,
	InputDevice.Kind.GAMEPAD,
]
const NAMES: Array[String] = ["PlayerOne", "PlayerTwo"]
## What the screens call the two players against the bot.
const NAMES_AGAINST_THE_BOT: Array[String] = ["YOU", "BOT"]

## The altitude under which a player has fallen out of the arena.
@export var fall_limit: float = 0.0
## Player 2 is a bot, of the level `bot_level`; to set before the chase enters the tree.
@export var against_the_bot: bool = false
@export var bot_level: ChaseBot.Level = ChaseBot.Level.NORMAL

## The two players' runners.
var players: Array[Player] = []
var chase: ChaseState
## The countdown and the time of the round under way, or of the coming one.
var clock: RoundClock
## Fixed steps since the match began: the date of its messages.
var match_steps: int = 0
## Fixed steps per second of game time, whatever the speed of the engine's clock.
var steps_per_second: int
## Where each player starts a round, facing the other.
var spawns: Array[Transform3D] = []
## The bot of each player a bot runs, by player.
var bots: Dictionary[int, ChaseBotIntentSource] = {}

## The end of the match has been shown.
var _over: bool = false
var _views: Array[PlayerView] = []
## What each player's inputs say, before the chase takes out what it does not have.
var _inputs: Array[InputIntentSource] = []

@onready var _arena: NavigationRegion3D = $Arena as NavigationRegion3D
@onready var _centre: Node3D = $Arena/Centre as Node3D
@onready var _countdown: CountdownDisplay = $Screens/CountdownDisplay as CountdownDisplay
@onready var _round_screen: ChaseRoundScreen = $Screens/RoundScreen as ChaseRoundScreen
@onready var _result: ResultScreen = $Screens/ResultScreen as ResultScreen


func _ready() -> void:
	steps_per_second = roundi(Engine.physics_ticks_per_second / Engine.time_scale)
	for player: int in ChaseState.PLAYERS:
		_views.append(get_node("Screens/Views/" + NAMES[player]) as PlayerView)
		players.append(_add_player(player))
	if against_the_bot:
		# One player, in full screen: the view of player 2 goes.
		var view: PlayerView = _views.pop_back()
		view.get_parent().remove_child(view)
		view.queue_free()
		make_bot(PLAYER_TWO, bot_level)
		_round_screen.names = NAMES_AGAINST_THE_BOT
	for player: int in _views.size():
		var runner: Player = players[player]
		var view: PlayerView = _views[player]
		# The runner's camera shows nothing itself: its view's camera takes its place.
		runner.camera_rig.camera().clear_current(false)
		view.followed = runner.camera_rig.camera()
		view.hud.player = player
		view.hud.other = players[1 - player]
		view.flow_hud.motor = runner.motor
		view.flow_hud.shows_ammo = false
		view.trick_pad.motor = runner.motor
		view.trick_pad.gesture = _inputs[player].drawing
	_result.rematch_chosen.connect(rematch)
	_result.menu_chosen.connect(_on_menu_chosen)
	rematch()


## A match from zero: the scores, the flows, and the countdown. Player 1 is the cat of the
## first round of the first match; each rematch gives that first round to the other.
func rematch() -> void:
	var first_cat: int = PLAYER_ONE if chase == null else 1 - chase.first_cat
	chase = ChaseState.new(players[PLAYER_ONE].tuning, steps_per_second, first_cat)
	match_steps = 0
	_over = false
	for player: int in _views.size():
		_views[player].hud.chase = chase
		_views[player].flow_hud.flow = chase.flows[player]
	_round_screen.chase = chase
	_result.hide_result()
	_begin_the_countdown()


## One fixed step of the match: the contact of the two bodies while a round is on, or the
## step of the clock (GO, the time up); then what the new phase asks for.
func _physics_process(_delta: float) -> void:
	match_steps += 1
	var before: ChaseState.Phase = chase.phase
	_play_the_step()
	if chase.phase != before:
		_follow_the_phase()
	for view: PlayerView in _views:
		view.hud.step = match_steps


## From now on a bot of `level` runs the runner of `player`, against the other one; the
## navigation of the arena is baked for the first bot.
func make_bot(player: int, level: ChaseBot.Level) -> ChaseBotIntentSource:
	if bots.is_empty():
		_bake_the_navigation()
	var runner: Player = players[player]
	var flee_points: Array[Vector3] = []
	for point: Node in _arena.get_node("FleePoints").get_children():
		flee_points.append((point as Node3D).global_position)
	var bot: ChaseBotIntentSource = ChaseBotIntentSource.new(
		runner, players[1 - player], level, _arena.get_navigation_map(), flee_points
	)
	bots[player] = bot
	runner.intent_source = ChaseIntentSource.new(bot)
	runner.watch(false)
	if chase != null:
		bot.play(chase.role(player))
	return bot


## The navigation mesh of the arena, from its blocks, for a body as low as a slide and as
## wide as a runner (to the cells of the mesh above), on a map of the same cells.
func _bake_the_navigation() -> void:
	var tuning: MovementTuning = players[PLAYER_ONE].tuning
	var mesh: NavigationMesh = _arena.navigation_mesh
	mesh.agent_height = ceilf(tuning.slide_capsule_height / mesh.cell_height) * mesh.cell_height
	mesh.agent_radius = ceilf(tuning.capsule_radius / mesh.cell_size) * mesh.cell_size
	var map: RID = _arena.get_navigation_map()
	NavigationServer3D.map_set_cell_size(map, mesh.cell_size)
	NavigationServer3D.map_set_cell_height(map, mesh.cell_height)
	_arena.bake_navigation_mesh(false)


func _play_the_step() -> void:
	if chase.phase == ChaseState.Phase.MATCH_OVER:
		return
	if chase.phase == ChaseState.Phase.RUNNING and touch(players[PLAYER_ONE], players[PLAYER_TWO]):
		chase.receive(ChaseMessage.contact(match_steps))
		# A contact once the time is up wins nothing: the clock still says it is up.
		if chase.phase != ChaseState.Phase.RUNNING:
			return
	match clock.tick():
		RoundClock.Event.GO:
			chase.receive(ChaseMessage.start(match_steps))
		RoundClock.Event.TIME_UP:
			chase.receive(ChaseMessage.time_up(match_steps))


func _follow_the_phase() -> void:
	match chase.phase:
		ChaseState.Phase.RUNNING:
			_hold_the_players(false)
		ChaseState.Phase.ROUND_OVER:
			_begin_the_countdown()
		ChaseState.Phase.MATCH_OVER:
			_end_the_match()


## Whether the capsules of two bodies touch: the least distance between their axes is no
## more than their radii together. Each body has one capsule, upright.
static func touch(first: CollisionObject3D, second: CollisionObject3D) -> bool:
	var axis_one: PackedVector3Array = _axis_of(first)
	var axis_two: PackedVector3Array = _axis_of(second)
	var apart: Vector2 = Vector2(axis_two[0].x - axis_one[0].x, axis_two[0].z - axis_one[0].z)
	var gap: float = maxf(axis_one[0].y - axis_two[1].y, axis_two[0].y - axis_one[1].y)
	var distance: float = Vector2(apart.length(), maxf(gap, 0.0)).length()
	return distance <= _radius_of(first) + _radius_of(second)


## The lowest and the highest points of the axis of the capsule of `body`, in the world.
static func _axis_of(body: CollisionObject3D) -> PackedVector3Array:
	var owner_id: int = body.get_shape_owners()[0]
	var capsule: CapsuleShape3D = body.shape_owner_get_shape(owner_id, 0) as CapsuleShape3D
	var centre: Vector3 = (body.global_transform * body.shape_owner_get_transform(owner_id)).origin
	var half: float = capsule.height / 2.0 - capsule.radius
	return PackedVector3Array([centre + Vector3.DOWN * half, centre + Vector3.UP * half])


static func _radius_of(body: CollisionObject3D) -> float:
	var owner_id: int = body.get_shape_owners()[0]
	return (body.shape_owner_get_shape(owner_id, 0) as CapsuleShape3D).radius


func _add_player(player: int) -> Player:
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	runner.name = NAMES[player]
	add_child(runner)
	runner.camera_rig.device = DEVICES[player]
	if against_the_bot:
		runner.camera_rig.device = InputDevice.Kind.ANY
	var inputs: InputIntentSource = InputIntentSource.new(runner.camera_rig)
	_inputs.append(inputs)
	runner.intent_source = ChaseIntentSource.new(inputs)
	runner.stepped.connect(_on_player_stepped.bind(player))
	return runner


## A countdown before a round: a new clock, the players held at their start points, face
## to face, in the colours of their roles in the coming round.
func _begin_the_countdown() -> void:
	var tuning: MovementTuning = players[PLAYER_ONE].tuning
	clock = RoundClock.new(tuning, steps_per_second, tuning.chase_round_time)
	_countdown.clock = clock
	_place_the_spawns(tuning.chase_start_distance)
	for player: int in ChaseState.PLAYERS:
		var runner: Player = players[player]
		runner.teleport(spawns[player])
		var cat: bool = chase.role(player) == ChaseState.Role.CAT
		runner.paint(tuning.chase_cat_colour if cat else tuning.chase_mouse_colour)
		if bots.has(player):
			bots[player].play(chase.role(player))
	_hold_the_players(true)


## The start points: on either side of the centre of the arena, along its X axis, half the
## start distance from it, each facing the other.
func _place_the_spawns(distance: float) -> void:
	spawns.clear()
	var centre: Vector3 = _centre.global_position
	var aside: Vector3 = _centre.global_basis.x * distance / 2.0
	for way: float in [-1.0, 1.0]:
		var origin: Vector3 = centre + aside * way
		spawns.append(Transform3D(Basis.looking_at(-aside * way), origin))


func _hold_the_players(held: bool) -> void:
	for runner: Player in players:
		runner.held = held


## One fixed step of a player has passed: back to its start point if it fell out of the
## arena (the flow loses its combo and its gauge, the time goes on); then the flow counts
## the step and gives its speed bonus back to the motor.
func _on_player_stepped(_intent: MoveIntent, player: int) -> void:
	var runner: Player = players[player]
	var flow: FlowState = chase.flows[player]
	if runner.global_position.y < fall_limit:
		runner.teleport(spawns[player])
		flow.respawn()
	flow.tuning = runner.tuning
	flow.follow(runner.motor)


## The match is over: the players stop, and the result shows.
func _end_the_match() -> void:
	if _over:
		return
	_over = true
	_hold_the_players(true)
	_result.show_chase(chase, against_the_bot)


func _on_menu_chosen() -> void:
	menu_requested.emit()
