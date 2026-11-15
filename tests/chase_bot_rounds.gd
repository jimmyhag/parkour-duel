class_name ChaseBotRounds
extends RefCounted
## Rounds of the chase (game/levels/chase.tscn) between two bots, in the real physics,
## through the match as it is played: before each round the cat and the mouse are made
## bots of the levels of a pairing, their start points moved aside by -1, 0 or 1 m, the
## countdown cut short; then the round is played to its end. The sides change with every
## round, as the roles swap. As they run, what the tests check is noted: who wins, how long
## each bot goes without getting nearer its goal, whether its motor gets one intent per
## step from it, and whether it ever goes faster than a runner of its tier of the flow.
## The rounds run at the pace of the engine the test sets, in fixed steps of 1/60 s.

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const EASY: ChaseBot.Level = ChaseBot.Level.EASY
const NORMAL: ChaseBot.Level = ChaseBot.Level.NORMAL
const HARD: ChaseBot.Level = ChaseBot.Level.HARD
## The pairings of the spec: the level of the cat and the level of the mouse of each.
const CAT_LEVELS: Array[ChaseBot.Level] = [NORMAL, HARD, EASY]
const MOUSE_LEVELS: Array[ChaseBot.Level] = [NORMAL, EASY, HARD]
## How far a start point is moved aside, in m.
const ASIDE: Array[float] = [-1.0, 0.0, 1.0]
## More steps than any countdown or round lasts.
const LONGEST_WAIT: int = 2000
## The fixed steps of the game.
const STEPS_PER_SECOND: int = 60
## What the speed of a runner may be above the limit of its tier, in m/s: rounding.
const SPEED_TOLERANCE: float = 0.01

## The rounds the cat won, by pairing (its index in CAT_LEVELS), and the rounds played.
var cat_wins: Array[int] = [0, 0, 0]
var rounds: Array[int] = [0, 0, 0]
## The most fixed steps in a row a bot of each level went without getting nearer its
## goal, and the steps of the rounds each level played.
var longest_without_progress: Array[int] = [0, 0, 0]
var steps_played: Array[int] = [0, 0, 0]
## Steps at which a bot did not give its motor exactly one intent, and at which a bot went
## faster than a runner of its tier of the flow; its fastest speed above its top speed.
var steps_without_one_intent: int = 0
var steps_too_fast: int = 0
var fastest_over_the_top_speed: float = 0.0
## One line per round: the pairing, the winner, the time.
var lines: Array[String] = []
## Wall-clock time of the rounds, in ms.
var duration: int = 0

var _tree: SceneTree


func _init(tree: SceneTree) -> void:
	_tree = tree


## Plays `count` rounds of each pairing, in a chase added under `parent` and freed after.
func run(parent: Node, count: int) -> void:
	var started: int = Time.get_ticks_msec()
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	parent.add_child(chase)
	for pairing: int in CAT_LEVELS.size():
		for index: int in count:
			await _play_a_round(chase, pairing, index)
	chase.queue_free()
	await _tree.process_frame
	duration = Time.get_ticks_msec() - started


func _play_a_round(chase: Chase, pairing: int, index: int) -> void:
	if chase.chase.phase == ChaseState.Phase.MATCH_OVER:
		chase.rematch()
	await _wait_for_the_countdown(chase)
	var cat: int = 0 if chase.chase.role(0) == ChaseState.Role.CAT else 1
	var mouse: int = 1 - cat
	var levels: Array[ChaseBot.Level] = [CAT_LEVELS[pairing], MOUSE_LEVELS[pairing]]
	var cat_bot: ChaseBotIntentSource = chase.make_bot(cat, levels[0])
	var mouse_bot: ChaseBotIntentSource = chase.make_bot(mouse, levels[1])
	var aside: Vector3 = (chase.get_node("Arena/Centre") as Node3D).global_basis.z
	var cat_start: Transform3D = chase.spawns[cat]
	cat_start.origin += aside * ASIDE[index % ASIDE.size()]
	var mouse_start: Transform3D = chase.spawns[mouse]
	@warning_ignore("integer_division")
	mouse_start.origin += aside * ASIDE[(index / ASIDE.size() + index) % ASIDE.size()]
	chase.players[cat].teleport(cat_start)
	chase.players[mouse].teleport(mouse_start)
	# The countdown cut short: GO at the next steps.
	var number: int = roundi(chase.players[0].tuning.round_countdown_number_time * STEPS_PER_SECOND)
	chase.clock.steps = RoundClock.NUMBERS * number - 2
	for step: int in LONGEST_WAIT:
		if chase.chase.phase == ChaseState.Phase.RUNNING:
			break
		await _tree.physics_frame
	var bots: Array[ChaseBotIntentSource] = [cat_bot, mouse_bot]
	var runners: Array[Player] = [chase.players[cat], chase.players[mouse]]
	var highest_bonus: Array[float] = [0.0, 0.0]
	var intents: Array[int] = [cat_bot.intents, mouse_bot.intents]
	var steps: int = 0
	while chase.chase.phase == ChaseState.Phase.RUNNING and steps < LONGEST_WAIT:
		await _tree.physics_frame
		steps += 1
		# At the step the round ends, the runners are held: they ask for no intent.
		var running: bool = chase.chase.phase == ChaseState.Phase.RUNNING
		for side: int in 2:
			var runner: Player = runners[side]
			if running and bots[side].intents - intents[side] != 1:
				steps_without_one_intent += 1
			intents[side] = bots[side].intents
			highest_bonus[side] = maxf(highest_bonus[side], runner.motor.top_speed_bonus)
			_check_the_speed(runner, highest_bonus[side])
	for side: int in 2:
		var level: ChaseBot.Level = levels[side]
		longest_without_progress[level] = maxi(
			longest_without_progress[level], bots[side].most_steps_without_progress
		)
		steps_played[level] += steps
	rounds[pairing] += 1
	var cat_won: bool = chase.chase.round_winner_role == ChaseState.Role.CAT
	cat_wins[pairing] += int(cat_won)
	lines.append(
		(
			"%s cat vs %s mouse, round %d: %s at %.2f s"
			% [
				ChaseBot.Level.keys()[levels[0]],
				ChaseBot.Level.keys()[levels[1]],
				index + 1,
				"the cat" if cat_won else "the mouse",
				steps / float(STEPS_PER_SECOND)
			]
		)
	)


## A runner may go no faster than the top speed of the highest tier of the flow it reached
## in the round, plus the most a move gains above it (a perfect slide or landing).
func _check_the_speed(runner: Player, bonus: float) -> void:
	var tuning: MovementTuning = runner.tuning
	var gain: float = maxf(tuning.perfect_slide_speed_gain, tuning.trick_perfect_speed_gain)
	var limit: float = tuning.top_speed * (1.0 + bonus) + gain
	var speed: float = Vector2(runner.velocity.x, runner.velocity.z).length()
	fastest_over_the_top_speed = maxf(fastest_over_the_top_speed, speed - tuning.top_speed)
	if speed > limit + SPEED_TOLERANCE:
		steps_too_fast += 1


## Waits for the countdown before a round: the first of a match, or the one after a round.
func _wait_for_the_countdown(chase: Chase) -> void:
	for step: int in LONGEST_WAIT:
		var phase: ChaseState.Phase = chase.chase.phase
		if phase == ChaseState.Phase.COUNTDOWN or phase == ChaseState.Phase.ROUND_OVER:
			return
		await _tree.physics_frame
