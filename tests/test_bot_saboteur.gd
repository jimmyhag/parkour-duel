extends GutTest
## The rule by which the bot chooses a target of the player's lane to sabotage
## (game/core): a ready target it can pay for, within the range of its shot, that the
## player nears; the cheapest first. The tuning is the fixed one of MotorBody.

const STEPS_PER_SECOND: int = 60
const PLATFORM: int = 1
const BRIDGE: int = 2
const OBSTACLE: int = 3
const IN_RANGE: float = 30.0
const NEAR: float = 10.0

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_bot_chooses_the_cheapest_target_the_player_nears() -> void:
	var platform: SabotageTarget = _target(PLATFORM, SabotageTarget.Kind.PLATFORM)
	var bridge: SabotageTarget = _target(BRIDGE, SabotageTarget.Kind.BRIDGE)
	var both: Array[BotSaboteur.Candidate] = [
		BotSaboteur.Candidate.new(bridge, IN_RANGE, 5.0),
		BotSaboteur.Candidate.new(platform, IN_RANGE, 20.0),
	]
	assert_eq(BotSaboteur.choose(both, 3, _tuning), PLATFORM, "the cheapest")
	assert_eq(BotSaboteur.choose(both, 0, _tuning), SabotageTarget.NO_TARGET, "none unpaid")

	var bridge_only: Array[BotSaboteur.Candidate] = [both[0]]
	assert_eq(BotSaboteur.choose(bridge_only, 1, _tuning), SabotageTarget.NO_TARGET, "too dear")
	assert_eq(BotSaboteur.choose(bridge_only, 2, _tuning), BRIDGE, "paid for")


func test_the_bot_leaves_a_target_the_player_does_not_near() -> void:
	var lead: float = _tuning.bot_sabotage_lead
	var cases: Dictionary[String, BotSaboteur.Candidate] = {
		"the player passed it": _candidate(IN_RANGE, -1.0),
		"the player too far before it": _candidate(IN_RANGE, lead + 0.01),
		"out of range": _candidate(_tuning.shot_range + 0.01, NEAR),
	}
	for case: String in cases:
		var only: Array[BotSaboteur.Candidate] = [cases[case]]
		assert_eq(BotSaboteur.choose(only, 3, _tuning), SabotageTarget.NO_TARGET, case)

	var at_the_edges: Array[BotSaboteur.Candidate] = [_candidate(_tuning.shot_range, lead)]
	assert_eq(BotSaboteur.choose(at_the_edges, 3, _tuning), OBSTACLE, "on the edges, chosen")

	var resting: BotSaboteur.Candidate = _candidate(IN_RANGE, NEAR)
	resting.target.receive(SabotageMessage.new(1, OBSTACLE, 0))
	var not_ready: Array[BotSaboteur.Candidate] = [resting]
	assert_eq(BotSaboteur.choose(not_ready, 3, _tuning), SabotageTarget.NO_TARGET, "not ready")


func _target(id: int, kind: SabotageTarget.Kind) -> SabotageTarget:
	return SabotageTarget.new(id, kind, _tuning, STEPS_PER_SECOND)


func _candidate(distance: float, ahead: float) -> BotSaboteur.Candidate:
	var obstacle: SabotageTarget = _target(OBSTACLE, SabotageTarget.Kind.OBSTACLE)
	return BotSaboteur.Candidate.new(obstacle, distance, ahead)
