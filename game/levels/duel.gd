class_name Duel
extends Node3D
## A local duel: two copies of the course side by side (Lane), the player's and its
## opponent's, the same way and 4 m of void between their nearest blocks. The opponent is
## the ghost of the best solo run of the session (Ghost) or the bot (a full runner led by
## BotIntentSource). Each runner's shots go to the opposing lane's targets. The round
## (RoundClock, RoundState, game/core) counts down, starts both timers at GO, and ends at
## the first finish, or at the time limit against the bot (against the ghost, at its
## finish at the latest); it only learns what happens from dated messages, and the
## runners move only while it says they may. Each runner starts a round with the starting
## ammunition of the tuning. Then the result shows, with the rematch and the way back to
## the menu. It gives the rule of game/core (BotSaboteur) what the bot sees, and feeds
## the displays and the sounds of the player (game/ui).
## Expected children: Hud/RaceHud, Hud/FlowHud, Hud/Crosshair, Hud/DebugOverlay,
## Hud/CountdownDisplay, Hud/ResultScreen, FlowSounds and SabotageSounds.

## The player chose MENU on the result screen: back to the start screen.
signal menu_requested

enum Opponent { GHOST, BOT }

## The runners of a round.
const PLAYER: int = 0
const OPPONENT: int = 1
## The least void between the nearest blocks of the two lanes, in m.
const LANE_GAP: float = 4.0
## The colour of the opponent, bot or ghost.
const OPPONENT_COLOUR: Color = Color(1.0, 0.5, 0.1)
## What the result screen calls the opponent.
const RESULT_OPPONENTS: Dictionary[Opponent, ResultScreen.Opponent] = {
	Opponent.GHOST: ResultScreen.Opponent.GHOST,
	Opponent.BOT: ResultScreen.Opponent.BOT,
}
const LANE_SCENE: PackedScene = preload("res://game/levels/lane.tscn")
const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const GHOST_SCENE: PackedScene = preload("res://game/player/ghost.tscn")

## Who the player runs against; to set before the duel enters the tree.
@export var opponent: Opponent = Opponent.BOT
## What the game remembers from one mode to the next: the ghost's run; to set before the
## duel enters the tree.
var session: Session = Session.new()

var player_lane: Lane
var opponent_lane: Lane
## The bot's intents, in a duel against the bot.
var bot_source: BotIntentSource
var clock: RoundClock
var round_state: RoundState

var _ghost: Ghost
## The run the ghost replays: the best solo run of the session, or none.
var _ghost_run: GhostRun
## The end of the round has been shown.
var _over: bool = false
## The bot's rule of sabotage, and its shots already counted, for the round.
var _saboteur: BotSaboteur
var _bot_shots_seen: int = 0
## What the round said at the last step: whether the runners may move.
var _runners_may_move: bool = false

@onready var _race_hud: RaceHud = $Hud/RaceHud as RaceHud
@onready var _flow_hud: FlowHud = $Hud/FlowHud as FlowHud
@onready var _crosshair: Crosshair = $Hud/Crosshair as Crosshair
@onready var _debug_overlay: DebugOverlay = $Hud/DebugOverlay as DebugOverlay
@onready var _countdown: CountdownDisplay = $Hud/CountdownDisplay as CountdownDisplay
@onready var _result: ResultScreen = $Hud/ResultScreen as ResultScreen
@onready var _flow_sounds: FlowSounds = $FlowSounds as FlowSounds
@onready var _sabotage_sounds: SabotageSounds = $SabotageSounds as SabotageSounds


func _ready() -> void:
	player_lane = _add_lane(PLAYER, true, Vector3.ZERO)
	var offset: float = player_lane.bounds().size.x + LANE_GAP
	opponent_lane = _add_lane(OPPONENT, opponent == Opponent.BOT, Vector3.RIGHT * offset)
	player_lane.shot_board = opponent_lane.targets
	opponent_lane.shot_board = player_lane.targets
	# Only the player's aim sets targets off: the ones of the opposing lane it could hit.
	player_lane.focus_from = null
	opponent_lane.focus_from = player_lane.shooter
	var player: Player = player_lane.player
	player.watch(true)
	if opponent == Opponent.BOT:
		var bot: Player = opponent_lane.player
		bot.paint(OPPONENT_COLOUR)
		bot.watch(false)
	else:
		_ghost = GHOST_SCENE.instantiate() as Ghost
		opponent_lane.add_child(_ghost)
	for runner: int in RoundState.RUNNERS:
		var lane: Lane = _lane(runner)
		lane.race.restartable = false
		lane.started_by_its_line = false
		lane.checkpoint_reached.connect(_on_checkpoint_reached.bind(runner))
		lane.finished.connect(_on_finished.bind(runner))
	_race_hud.race = player_lane.race
	_race_hud.flow = player_lane.flow
	_race_hud.runner = PLAYER
	_flow_hud.flow = player_lane.flow
	_flow_hud.motor = player.motor
	_crosshair.shooter = player_lane.shooter
	_flow_sounds.flow = player_lane.flow
	_sabotage_sounds.shooter = player_lane.shooter
	_sabotage_sounds.targets = player_lane.targets
	_debug_overlay.motor = player.motor
	_debug_overlay.flow = player_lane.flow
	_debug_overlay.shooter = player_lane.shooter
	_debug_overlay.targets = opponent_lane.targets
	if opponent == Opponent.BOT:
		_debug_overlay.opponent_flow = opponent_lane.flow
	_result.rematch_chosen.connect(rematch)
	_result.menu_chosen.connect(_on_menu_chosen)
	_begin_the_round()


## The round of the duel: GO after the countdown, then the race until a finish or the
## time limit; then its end is shown. The ghost and the bot follow the race, and the
## runners move only while the round says they may.
func _physics_process(_delta: float) -> void:
	if round_state.phase != RoundState.Phase.FINISHED:
		_play_the_round()
	elif not _over:
		_end_the_round()
	_follow_the_round()


func _play_the_round() -> void:
	var event: RoundClock.Event = clock.tick()
	if event == RoundClock.Event.GO:
		round_state.receive(RoundMessage.start(clock.race_steps()))
		for runner: int in RoundState.RUNNERS:
			_lane(runner).race.cross_start_line()
	if round_state.phase != RoundState.Phase.RUNNING:
		return
	_follow_the_ghost()
	_direct_the_bot()
	# Against the ghost, the round ends at its finish: no time limit.
	if event == RoundClock.Event.TIME_UP and opponent == Opponent.BOT:
		for runner: int in RoundState.RUNNERS:
			round_state.receive(
				RoundMessage.time_limit(runner, clock.race_steps(), _style_score(runner))
			)


## Both lanes, their targets, flows and timers from zero, the starting ammunition again,
## and the countdown again; the ghost replays the same run.
func rematch() -> void:
	_begin_the_round()


func _begin_the_round() -> void:
	for runner: int in RoundState.RUNNERS:
		var lane: Lane = _lane(runner)
		lane.restart_the_run()
		if lane.player != null:
			lane.flow.ammo = lane.tuning.duel_start_ammo
	var steps_per_second: int = player_lane.steps_per_second
	clock = RoundClock.new(player_lane.tuning, steps_per_second)
	round_state = RoundState.new(steps_per_second)
	_over = false
	_runners_may_move = round_state.runners_may_move()
	_hold_the_runners(not _runners_may_move)
	if opponent == Opponent.BOT:
		bot_source = BotIntentSource.new(opponent_lane.player, opponent_lane.way_forward(0))
		_saboteur = BotSaboteur.new()
		_bot_shots_seen = opponent_lane.shooter.shots
		opponent_lane.player.intent_source = bot_source
	else:
		_ghost_run = session.best_run
		_follow_the_ghost()
	_race_hud.round_state = round_state
	_countdown.clock = clock
	_result.hide_result()


func _add_lane(runner: int, with_a_runner: bool, at: Vector3) -> Lane:
	var lane: Lane = LANE_SCENE.instantiate() as Lane
	lane.name = "PlayerLane" if runner == PLAYER else "OpponentLane"
	lane.runner_id = runner
	lane.position = at
	if with_a_runner:
		var runner_body: Player = PLAYER_SCENE.instantiate() as Player
		runner_body.name = "Player"
		lane.add_child(runner_body)
	add_child(lane)
	return lane


func _lane(runner: int) -> Lane:
	return player_lane if runner == PLAYER else opponent_lane


## The runners move only while the round says they may: they are held, or let go, when
## its answer changes.
func _follow_the_round() -> void:
	var may_move: bool = round_state.runners_may_move()
	if may_move != _runners_may_move:
		_runners_may_move = may_move
		_hold_the_runners(not may_move)


func _hold_the_runners(held: bool) -> void:
	for runner: int in RoundState.RUNNERS:
		var body: Player = _lane(runner).player
		if body != null:
			body.held = held


## The ghost is where its run was as many steps after its start as the race is after GO,
## once the runners have played this step; its checkpoints and its finish are messages of
## the round like the player's.
func _follow_the_ghost() -> void:
	if _ghost == null:
		return
	if _ghost_run == null or _ghost_run.frames.is_empty():
		_ghost.visible = false
		return
	_ghost.visible = true
	var frame: int = 0
	if round_state.phase == RoundState.Phase.RUNNING:
		frame = clock.race_steps() + 1
	_ghost.show_at(opponent_lane.global_transform * _ghost_run.frame(frame))
	if frame == 0:
		return
	var style: int = _ghost_run.style_score
	for index: int in _ghost_run.checkpoint_frames:
		if _ghost_run.checkpoint_frames[index] == frame:
			round_state.receive(RoundMessage.checkpoint_reached(OPPONENT, index, frame, style))
	if frame == _ghost_run.finish_frame:
		round_state.receive(RoundMessage.finish(OPPONENT, frame, style))


## The bot runs towards the next checkpoint (the finish line in the last section); the
## rule of game/core (BotSaboteur) chooses a target of the player's lane for it to
## sabotage, from what the bot sees (the distances, its line of fire, a jump ahead), and
## it aims at it unless it already aims.
func _direct_the_bot() -> void:
	if bot_source == null:
		return
	var bot: Player = opponent_lane.player
	var to_the_goal: Vector3 = opponent_lane.goal_after(opponent_lane.race.last_checkpoint)
	bot_source.run_towards(to_the_goal - bot.global_position)
	var shooter: Shooter = opponent_lane.shooter
	if shooter.shots != _bot_shots_seen:
		_bot_shots_seen = shooter.shots
		_saboteur.sabotaged(shooter.last_message.target)
	var tuning: MovementTuning = bot.tuning
	var eyes: Vector3 = bot.global_position + Vector3.UP * tuning.camera_look_height
	var player: Player = player_lane.player
	var forward: Vector3 = player_lane.way_forward(player_lane.race.last_checkpoint)
	var candidates: Array[BotSaboteur.Candidate] = []
	var blocks: Dictionary[int, TargetBlock] = {}
	for block: TargetBlock in player_lane.target_blocks():
		var point: Vector3 = block.aim_point()
		var to_it: Vector3 = point - player.global_position
		to_it.y = 0.0
		var line: AimFacts = bot.aim_facts_towards(point - eyes)
		var clear: bool = line.target == block.target_id and line.lane == PLAYER
		candidates.append(
			BotSaboteur.Candidate.new(
				block.target, eyes.distance_to(point), to_it.dot(forward), clear
			)
		)
		blocks[block.target_id] = block
	# Asked at every step, aiming or not: the approach of the player is step to step.
	var jump_ahead: bool = bot_source.sees_a_jump_before_an_aim_ends()
	var ammo: int = opponent_lane.flow.ammo
	var chosen: int = _saboteur.choose(candidates, ammo, tuning, jump_ahead)
	if chosen != SabotageTarget.NO_TARGET and not bot_source.is_aiming():
		bot_source.aim_at(blocks[chosen].aim_point())


func _style_score(runner: int) -> int:
	if runner == OPPONENT and opponent == Opponent.GHOST:
		return 0 if _ghost_run == null else _ghost_run.style_score
	return _lane(runner).flow.style_score


func _on_checkpoint_reached(index: int, runner: int) -> void:
	if runner == PLAYER and _saboteur != null:
		_saboteur.player_reached_a_checkpoint()
	var lane: Lane = _lane(runner)
	round_state.receive(
		RoundMessage.checkpoint_reached(
			runner, index, lane.race.elapsed_steps, _style_score(runner)
		)
	)


func _on_finished(runner: int) -> void:
	var lane: Lane = _lane(runner)
	round_state.receive(RoundMessage.finish(runner, lane.race.elapsed_steps, _style_score(runner)))


## The round is over: both runners stop, their flows freeze, and the result shows.
func _end_the_round() -> void:
	_over = true
	var styles: Array[int] = []
	for runner: int in RoundState.RUNNERS:
		var lane: Lane = _lane(runner)
		lane.flow.finish()
		styles.append(_style_score(runner))
	_result.show_round(round_state, RESULT_OPPONENTS[opponent], styles)


func _on_menu_chosen() -> void:
	menu_requested.emit()
