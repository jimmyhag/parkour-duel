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
## Expected children: Arena (with Centre, its marker), Screens/Views/PlayerOne and
## Screens/Views/PlayerTwo (PlayerView), Screens/CountdownDisplay, Screens/RoundScreen and
## Screens/ResultScreen.

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

## The altitude under which a player has fallen out of the arena.
@export var fall_limit: float = 0.0

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

## The end of the match has been shown.
var _over: bool = false
var _views: Array[PlayerView] = []
## What each player's inputs say, before the chase takes out what it does not have.
var _inputs: Array[InputIntentSource] = []

@onready var _centre: Node3D = $Arena/Centre as Node3D
@onready var _countdown: CountdownDisplay = $Screens/CountdownDisplay as CountdownDisplay
@onready var _round_screen: ChaseRoundScreen = $Screens/RoundScreen as ChaseRoundScreen
@onready var _result: ResultScreen = $Screens/ResultScreen as ResultScreen


func _ready() -> void:
	steps_per_second = roundi(Engine.physics_ticks_per_second / Engine.time_scale)
	for player: int in ChaseState.PLAYERS:
		_views.append(get_node("Screens/Views/" + NAMES[player]) as PlayerView)
		players.append(_add_player(player))
	for player: int in ChaseState.PLAYERS:
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


## A match from zero: the scores, the roles of the first round, the flows, and the
## countdown.
func rematch() -> void:
	chase = ChaseState.new(players[PLAYER_ONE].tuning, steps_per_second)
	match_steps = 0
	_over = false
	for player: int in ChaseState.PLAYERS:
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


func _play_the_step() -> void:
	if chase.phase == ChaseState.Phase.MATCH_OVER:
		return
	if chase.phase == ChaseState.Phase.RUNNING and touch(players[PLAYER_ONE], players[PLAYER_TWO]):
		chase.receive(ChaseMessage.contact(match_steps))
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
	_result.show_chase(chase)


func _on_menu_chosen() -> void:
	menu_requested.emit()
