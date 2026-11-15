extends GutTest
## The chase (game/core): a match of rounds between player 0 and player 1, one the cat and
## the other the mouse, fed by dated messages only (ChaseMessage): the start of a round at
## GO, the contact of the cat with the mouse, and the end of the time of a round. The
## tuning is the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const PLAYER_ONE: int = 0
const PLAYER_TWO: int = 1
## The values of the fixed tuning in fixed steps at 60 per second, written out on purpose:
## the time of a round.
const ROUND_STEPS: int = 1200
const RUNNING: ChaseState.Phase = ChaseState.Phase.RUNNING
const ROUND_OVER: ChaseState.Phase = ChaseState.Phase.ROUND_OVER
const MATCH_OVER: ChaseState.Phase = ChaseState.Phase.MATCH_OVER
const CAT: ChaseState.Role = ChaseState.Role.CAT
const MOUSE: ChaseState.Role = ChaseState.Role.MOUSE

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_cat_that_touches_the_mouse_wins_the_round() -> void:
	var chase: ChaseState = _chase()
	assert_eq(chase.phase, ChaseState.Phase.COUNTDOWN, "a match starts with a countdown")
	chase.receive(ChaseMessage.start(100))
	assert_eq(chase.phase, RUNNING, "the round is on at GO")
	assert_eq(chase.cat, PLAYER_ONE, "player 1 is the cat of the first round")
	assert_eq(chase.role(PLAYER_ONE), CAT)
	assert_eq(chase.role(PLAYER_TWO), MOUSE)

	chase.receive(ChaseMessage.contact(100 + ROUND_STEPS - 1))

	assert_eq(chase.phase, ROUND_OVER, "the contact ends the round")
	assert_eq(chase.round_winner, PLAYER_ONE, "the cat wins it")
	assert_eq(chase.round_winner_role, CAT, "as the cat")
	assert_eq(chase.score, [1, 0] as Array[int], "a round for player 1")
	assert_eq(chase.end_step, 100 + ROUND_STEPS - 1, "dated by its message")

	chase.receive(ChaseMessage.time_up(100 + ROUND_STEPS))
	assert_eq(chase.score, [1, 0] as Array[int], "the time up of an ended round counts for nothing")

	var too_late: ChaseState = _chase()
	too_late.receive(ChaseMessage.start(0))
	too_late.receive(ChaseMessage.contact(ROUND_STEPS))
	assert_eq(too_late.phase, RUNNING, "a contact once the time is up counts for nothing")
	var not_started: ChaseState = _chase()
	not_started.receive(ChaseMessage.contact(10))
	assert_eq(not_started.phase, ChaseState.Phase.COUNTDOWN, "nor one during the countdown")


func test_the_mouse_that_lasts_the_time_wins_the_round() -> void:
	var chase: ChaseState = _chase()
	chase.receive(ChaseMessage.start(180))
	assert_eq(chase.seconds_left(180), 20.0, "20 s at GO")
	assert_eq(chase.seconds_left(180 + 300), 15.0, "5 s later, 15 s")

	chase.receive(ChaseMessage.time_up(180 + ROUND_STEPS))

	assert_eq(chase.phase, ROUND_OVER, "the time up ends the round")
	assert_eq(chase.round_winner, PLAYER_TWO, "the mouse wins it")
	assert_eq(chase.round_winner_role, MOUSE, "as the mouse")
	assert_eq(chase.score, [0, 1] as Array[int], "a round for player 2")
	chase.receive(ChaseMessage.contact(180 + ROUND_STEPS))
	assert_eq(chase.score, [0, 1] as Array[int], "a contact after the end counts for nothing")


func test_the_roles_swap_every_round() -> void:
	var chase: ChaseState = _chase()
	chase.receive(ChaseMessage.start(0))
	chase.receive(ChaseMessage.contact(300))
	assert_eq(chase.role(PLAYER_ONE), MOUSE, "between two rounds: the role of the coming one")
	assert_eq(chase.role(PLAYER_TWO), CAT)

	chase.receive(ChaseMessage.start(500))

	assert_eq(chase.phase, RUNNING, "the second round is on")
	assert_eq(chase.round_number, 2)
	assert_eq(chase.cat, PLAYER_TWO, "the cat became the mouse and the mouse the cat")
	assert_eq(chase.role(PLAYER_ONE), MOUSE)
	assert_eq(chase.role(PLAYER_TWO), CAT)
	assert_eq(chase.round_winner, ChaseState.NOBODY, "nobody won it yet")
	chase.receive(ChaseMessage.time_up(500 + ROUND_STEPS))
	chase.receive(ChaseMessage.start(2000))
	assert_eq(chase.cat, PLAYER_ONE, "and back at the third")


func test_the_first_to_three_rounds_wins() -> void:
	var chase: ChaseState = _chase()
	var step: int = 0
	# Player 1 wins the first two rounds: as the cat, then as the mouse.
	step = _play_a_round(chase, step, true)
	step = _play_a_round(chase, step, false)
	# Player 2 wins the third, as the mouse.
	step = _play_a_round(chase, step, false)
	assert_eq(chase.score, [2, 1] as Array[int], "player 1 has two rounds")
	assert_eq(chase.phase, ROUND_OVER, "the match goes on")
	assert_eq(chase.winner, ChaseState.NOBODY, "nobody won it yet")

	# The fourth: player 2 is the cat, and the mouse holds out.
	step = _play_a_round(chase, step, false)

	assert_eq(chase.score, [3, 1] as Array[int], "a third round for player 1")
	assert_eq(chase.phase, MATCH_OVER, "the match is over")
	assert_eq(chase.winner, PLAYER_ONE, "player 1 wins it")
	chase.receive(ChaseMessage.start(step + 100))
	assert_eq(chase.phase, MATCH_OVER, "no round after the end of the match")


func test_the_flow_starts_from_zero_every_round() -> void:
	var chase: ChaseState = _chase()
	chase.receive(ChaseMessage.start(0))
	for player: int in ChaseState.PLAYERS:
		var flow: FlowState = chase.flows[player]
		flow.gauge = flow.max_gauge() / 2.0
		flow.style_score = 900
	chase.receive(ChaseMessage.contact(400))
	assert_gt(chase.flows[PLAYER_ONE].gauge, 0.0, "the gauge is kept to the end of the round")

	chase.receive(ChaseMessage.start(600))

	for player: int in ChaseState.PLAYERS:
		var flow: FlowState = chase.flows[player]
		assert_eq(flow.gauge, 0.0, "the gauge of player %d is empty" % (player + 1))
		assert_eq(flow.style_score, 0, "and its score from zero")
		assert_false(flow.frozen, "it counts again")
		assert_eq(flow.speed_bonus(), 0.0, "no speed bonus left")


func test_the_intents_of_the_chase_have_no_aim_shot_return_or_restart() -> void:
	var source: ChaseIntentSource = ChaseIntentSource.new(EverythingAsked.new())

	var intent: MoveIntent = source.next_intent()

	assert_eq(intent.direction, Vector3.FORWARD, "the way it goes is kept")
	assert_true(intent.jump_held, "and the jump")
	assert_false(intent.aim_held, "no aim")
	assert_eq(intent.aim_direction, Vector3.ZERO, "nowhere to aim at")
	assert_false(intent.shoot_pressed, "no shot")
	assert_false(intent.respawn_requested, "no return to a checkpoint")
	assert_false(intent.restart_requested, "no restart")


func _chase() -> ChaseState:
	return ChaseState.new(_tuning, STEPS_PER_SECOND)


## Plays a round from `step` (one second of countdown first): the cat touches the mouse
## after 5 s if `caught`, otherwise the time runs out. Returns the step it ended at.
func _play_a_round(chase: ChaseState, step: int, caught: bool) -> int:
	var go: int = step + STEPS_PER_SECOND
	chase.receive(ChaseMessage.start(go))
	if caught:
		chase.receive(ChaseMessage.contact(go + 300))
		return go + 300
	chase.receive(ChaseMessage.time_up(go + ROUND_STEPS))
	return go + ROUND_STEPS


## A source that asks for everything at every step.
class EverythingAsked:
	extends IntentSource

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = Vector3.FORWARD
		intent.jump_held = true
		intent.aim_held = true
		intent.aim_direction = Vector3.LEFT
		intent.shoot_pressed = true
		intent.respawn_requested = true
		intent.restart_requested = true
		return intent
