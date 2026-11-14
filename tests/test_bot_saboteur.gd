extends GutTest
## The rule by which the bot chooses a target of the player's lane to sabotage
## (game/core): a ready target it can pay for, within the range of its shot, that the
## player nears and approaches (nearer than at the step before); never the same target
## twice before the player reaches a new checkpoint; the cheapest first. The tuning is
## the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const PLATFORM: int = 1
const BRIDGE: int = 2
const OBSTACLE: int = 3
const IN_RANGE: float = 30.0
const NEAR: float = 10.0
## How much nearer the player gets at each step of these tests, in m.
const STEP_CLOSER: float = 0.15

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_bot_chooses_the_cheapest_target_the_player_nears() -> void:
	var platform: SabotageTarget = _target(PLATFORM, SabotageTarget.Kind.PLATFORM)
	var bridge: SabotageTarget = _target(BRIDGE, SabotageTarget.Kind.BRIDGE)
	var saboteur: BotSaboteur = BotSaboteur.new()
	var both: Array[BotSaboteur.Candidate] = [
		BotSaboteur.Candidate.new(bridge, IN_RANGE, 5.0),
		BotSaboteur.Candidate.new(platform, IN_RANGE, 20.0),
	]
	saboteur.choose(both, 3, _tuning)
	var closer: Array[BotSaboteur.Candidate] = _closer(both)
	assert_eq(saboteur.choose(closer, 3, _tuning), PLATFORM, "the cheapest")
	closer = _closer(closer)
	assert_eq(saboteur.choose(closer, 0, _tuning), SabotageTarget.NO_TARGET, "none unpaid")

	var bridge_only: Array[BotSaboteur.Candidate] = [_closer(closer)[0]]
	assert_eq(saboteur.choose(bridge_only, 1, _tuning), SabotageTarget.NO_TARGET, "too dear")
	bridge_only = _closer(bridge_only)
	assert_eq(saboteur.choose(bridge_only, 2, _tuning), BRIDGE, "paid for")


func test_the_bot_leaves_a_target_the_player_does_not_near() -> void:
	var lead: float = _tuning.bot_sabotage_lead
	var cases: Dictionary[String, Array] = {
		"the player passed it": [IN_RANGE, -1.0],
		"the player too far before it": [IN_RANGE, lead + 0.01],
		"out of range": [_tuning.shot_range + 0.01, NEAR],
	}
	for case: String in cases:
		var saboteur: BotSaboteur = BotSaboteur.new()
		var distance: float = cases[case][0]
		var ahead: float = cases[case][1]
		saboteur.choose(_one(_candidate(distance, ahead + STEP_CLOSER)), 3, _tuning)
		var only: Array[BotSaboteur.Candidate] = [_candidate(distance, ahead)]
		assert_eq(saboteur.choose(only, 3, _tuning), SabotageTarget.NO_TARGET, case)

	var at_the_edges: BotSaboteur = BotSaboteur.new()
	at_the_edges.choose(_one(_candidate(_tuning.shot_range, lead + STEP_CLOSER)), 3, _tuning)
	var edges: Array[BotSaboteur.Candidate] = [_candidate(_tuning.shot_range, lead)]
	assert_eq(at_the_edges.choose(edges, 3, _tuning), OBSTACLE, "on the edges, chosen")

	var not_ready: BotSaboteur = BotSaboteur.new()
	var resting: BotSaboteur.Candidate = _candidate(IN_RANGE, NEAR)
	resting.target.receive(SabotageMessage.new(1, OBSTACLE, 0))
	not_ready.choose(_one(_candidate(IN_RANGE, NEAR + STEP_CLOSER)), 3, _tuning)
	var hit: Array[BotSaboteur.Candidate] = [resting]
	assert_eq(not_ready.choose(hit, 3, _tuning), SabotageTarget.NO_TARGET, "not ready")


func test_the_bot_waits_for_the_player_to_approach() -> void:
	var saboteur: BotSaboteur = BotSaboteur.new()
	var stopped: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, NEAR)]
	var first: int = saboteur.choose(stopped, 3, _tuning)
	assert_eq(first, SabotageTarget.NO_TARGET, "nothing known of the step before")
	for step: int in 10:
		var still: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, NEAR)]
		assert_eq(saboteur.choose(still, 3, _tuning), SabotageTarget.NO_TARGET, "a stopped one")
	var backing: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, NEAR + STEP_CLOSER)]
	assert_eq(saboteur.choose(backing, 3, _tuning), SabotageTarget.NO_TARGET, "one going back")
	var coming: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, NEAR)]
	assert_eq(saboteur.choose(coming, 3, _tuning), OBSTACLE, "one that approaches")


func test_the_bot_does_not_sabotage_a_target_twice_before_a_new_checkpoint() -> void:
	var saboteur: BotSaboteur = BotSaboteur.new()
	var ahead: float = NEAR
	saboteur.choose(_one(_candidate(IN_RANGE, ahead)), 3, _tuning)
	ahead -= STEP_CLOSER
	assert_eq(saboteur.choose(_one(_candidate(IN_RANGE, ahead)), 3, _tuning), OBSTACLE, "once")

	saboteur.sabotaged(OBSTACLE)

	for step: int in 20:
		ahead -= STEP_CLOSER
		var again: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, ahead)]
		assert_eq(saboteur.choose(again, 3, _tuning), SabotageTarget.NO_TARGET, "not twice")
	saboteur.player_reached_a_checkpoint()
	ahead -= STEP_CLOSER
	var after: Array[BotSaboteur.Candidate] = [_candidate(IN_RANGE, ahead)]
	assert_eq(saboteur.choose(after, 3, _tuning), OBSTACLE, "after a new checkpoint, again")


func test_the_bot_leaves_a_target_hidden_from_it() -> void:
	var saboteur: BotSaboteur = BotSaboteur.new()
	var obstacle: SabotageTarget = _target(OBSTACLE, SabotageTarget.Kind.OBSTACLE)
	saboteur.choose(_one(BotSaboteur.Candidate.new(obstacle, IN_RANGE, NEAR, false)), 3, _tuning)
	var hidden: BotSaboteur.Candidate = BotSaboteur.Candidate.new(
		obstacle, IN_RANGE, NEAR - STEP_CLOSER, false
	)
	var chosen: int = saboteur.choose(_one(hidden), 3, _tuning)
	assert_eq(chosen, SabotageTarget.NO_TARGET, "a block between its head and the target")
	var seen: BotSaboteur.Candidate = BotSaboteur.Candidate.new(
		obstacle, IN_RANGE, NEAR - 2.0 * STEP_CLOSER, true
	)
	assert_eq(saboteur.choose(_one(seen), 3, _tuning), OBSTACLE, "a clear line of fire")


func test_the_bot_starts_no_aim_with_a_jump_ahead() -> void:
	var saboteur: BotSaboteur = BotSaboteur.new()
	var ahead: float = NEAR
	saboteur.choose(_one(_candidate(IN_RANGE, ahead)), 3, _tuning)
	for step: int in 5:
		ahead -= STEP_CLOSER
		var jump: int = saboteur.choose(_one(_candidate(IN_RANGE, ahead)), 3, _tuning, true)
		assert_eq(jump, SabotageTarget.NO_TARGET, "a jump before the aim would end")
	ahead -= STEP_CLOSER
	var after: int = saboteur.choose(_one(_candidate(IN_RANGE, ahead)), 3, _tuning, false)
	assert_eq(after, OBSTACLE, "the jump made, the player still approaching: chosen")


func _target(id: int, kind: SabotageTarget.Kind) -> SabotageTarget:
	return SabotageTarget.new(id, kind, _tuning, STEPS_PER_SECOND)


func _candidate(distance: float, ahead: float) -> BotSaboteur.Candidate:
	var obstacle: SabotageTarget = _target(OBSTACLE, SabotageTarget.Kind.OBSTACLE)
	return BotSaboteur.Candidate.new(obstacle, distance, ahead)


## The same candidates, the player a step closer to each.
func _closer(candidates: Array[BotSaboteur.Candidate]) -> Array[BotSaboteur.Candidate]:
	var closer: Array[BotSaboteur.Candidate] = []
	for candidate: BotSaboteur.Candidate in candidates:
		closer.append(
			BotSaboteur.Candidate.new(
				candidate.target, candidate.distance, candidate.ahead - STEP_CLOSER
			)
		)
	return closer


func _one(candidate: BotSaboteur.Candidate) -> Array[BotSaboteur.Candidate]:
	var one: Array[BotSaboteur.Candidate] = [candidate]
	return one
