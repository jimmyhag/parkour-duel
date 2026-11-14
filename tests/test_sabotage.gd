extends GutTest
## Shooting and sabotage in game/core, without physics: the shot decided from what the
## player layer observed under the reticle (AimFacts), the dated message it produces, the
## ammunition it spends from the flow, the small state machine of each target driven by
## those messages only, and the runners its effect hits. The tuning is the fixed one of
## MotorBody.

const STEPS_PER_SECOND: int = 60
const PLATFORM: SabotageTarget.Kind = SabotageTarget.Kind.PLATFORM
const BRIDGE: SabotageTarget.Kind = SabotageTarget.Kind.BRIDGE
const OBSTACLE: SabotageTarget.Kind = SabotageTarget.Kind.OBSTACLE
const BARRIER: SabotageTarget.Kind = SabotageTarget.Kind.BARRIER
const KINDS: Array[SabotageTarget.Kind] = [PLATFORM, BRIDGE, OBSTACLE, BARRIER]
const READY: SabotageTarget.State = SabotageTarget.State.READY
const WARNING: SabotageTarget.State = SabotageTarget.State.WARNING
const SABOTAGED: SabotageTarget.State = SabotageTarget.State.SABOTAGED
const RECOVERING: SabotageTarget.State = SabotageTarget.State.RECOVERING
const RESTING: SabotageTarget.State = SabotageTarget.State.RESTING
## The identity of each target in its course: one of each kind, in the order of KINDS.
const IDS: Dictionary[SabotageTarget.Kind, int] = {PLATFORM: 1, BRIDGE: 2, OBSTACLE: 3, BARRIER: 4}
## The values of the fixed tuning, in fixed steps at 60 per second, and the costs:
## written out on purpose, not computed.
const WARNING_STEPS: int = 36
const COOLDOWN_STEPS: int = 180
const EFFECT_STEPS: Dictionary[SabotageTarget.Kind, int] = {
	PLATFORM: 300, BRIDGE: 360, OBSTACLE: 360, BARRIER: 240
}
const COSTS: Dictionary[SabotageTarget.Kind, int] = {
	PLATFORM: 1, BRIDGE: 2, OBSTACLE: 1, BARRIER: 1
}
const RANGE: float = 45.0
## The runner that shoots, and the runners the targets may hit: not the same ones.
const SHOOTER: int = 7
const RUNNER: int = 1
const OTHER_RUNNER: int = 2
const AT_STEP: int = 123
const IN_RANGE: float = 30.0
const NOBODY: Array[int] = []
const WALL_RUN: RunnerEvent.Kind = RunnerEvent.Kind.WALL_RUN
const HUD_SCENE: PackedScene = preload("res://game/ui/flow_hud.tscn")

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


# --- Shooting ---


func test_a_shot_at_a_ready_target_in_range_hits_it() -> void:
	for kind: SabotageTarget.Kind in KINDS:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var board: TargetBoard = _board()
		var flow: FlowState = _flow(3)
		var shooter: Shooter = Shooter.new(SHOOTER, _tuning)
		var target: SabotageTarget = board.target(IDS[kind])

		var message: SabotageMessage = shooter.follow(
			_shot(), AimFacts.new(IDS[kind], IN_RANGE), AT_STEP, board, flow
		)

		assert_not_null(message, context + "a message")
		if message != null:
			assert_eq(message.shooter, SHOOTER, context + "it says who shot")
			assert_eq(message.target, IDS[kind], context + "which target")
			assert_eq(message.step, AT_STEP, context + "and at which step")
		assert_eq(target.state, WARNING, context + "the target is hit")
		assert_eq(flow.ammo, 3 - COSTS[kind], context + "its cost is spent")
		assert_eq(shooter.shots, 1, context + "one shot")
		assert_same(shooter.last_message, message, context + "the last message of the shooter")
		for other: SabotageTarget in board.targets.values():
			if other != target:
				assert_eq(other.state, READY, context + "the other targets stay ready")

	# On the edge of the range, still in range.
	var edge_board: TargetBoard = _board()
	var edge_flow: FlowState = _flow(3)
	var at_the_edge: AimFacts = AimFacts.new(IDS[PLATFORM], RANGE)
	var shot: SabotageMessage = Shooter.new(SHOOTER, _tuning).follow(
		_shot(), at_the_edge, AT_STEP, edge_board, edge_flow
	)
	assert_not_null(shot, "a target exactly at the range is hit")


func test_no_shot_without_enough_ammunition() -> void:
	var board: TargetBoard = _board()
	var flow: FlowState = _flow(1)
	var shooter: Shooter = Shooter.new(SHOOTER, _tuning)

	var message: SabotageMessage = shooter.follow(
		_shot(), AimFacts.new(IDS[BRIDGE], IN_RANGE), AT_STEP, board, flow
	)

	assert_null(message, "no message")
	assert_eq(flow.ammo, 1, "the ammunition stays")
	assert_eq(board.target(IDS[BRIDGE]).state, READY, "the bridge stays ready")
	assert_eq(shooter.shots, 0, "no shot")


func test_no_shot_into_the_void() -> void:
	var board: TargetBoard = _board()
	var flow: FlowState = _flow(3)
	var shooter: Shooter = Shooter.new(SHOOTER, _tuning)
	var unknown: int = 99

	for facts: AimFacts in [
		AimFacts.new(SabotageTarget.NO_TARGET, IN_RANGE), AimFacts.new(unknown, IN_RANGE)
	]:
		var message: SabotageMessage = shooter.follow(_shot(), facts, AT_STEP, board, flow)
		assert_null(message, "no message, aiming at %d" % facts.target)

	assert_eq(flow.ammo, 3, "nothing spent")
	_assert_all_ready(board)
	assert_eq(shooter.shots, 0, "no shot")


func test_no_shot_out_of_range() -> void:
	var board: TargetBoard = _board()
	var flow: FlowState = _flow(3)
	var shooter: Shooter = Shooter.new(SHOOTER, _tuning)
	var too_far: AimFacts = AimFacts.new(IDS[PLATFORM], RANGE + 0.01)

	var message: SabotageMessage = shooter.follow(_shot(), too_far, AT_STEP, board, flow)

	assert_null(message, "no message")
	assert_eq(flow.ammo, 3, "nothing spent")
	_assert_all_ready(board)


func test_no_shot_without_aiming() -> void:
	var board: TargetBoard = _board()
	var flow: FlowState = _flow(3)
	var shooter: Shooter = Shooter.new(SHOOTER, _tuning)
	var not_aiming: MoveIntent = MoveIntent.new()
	not_aiming.shoot_pressed = true
	var facts: AimFacts = AimFacts.new(IDS[PLATFORM], IN_RANGE)

	var message: SabotageMessage = shooter.follow(not_aiming, facts, AT_STEP, board, flow)

	assert_null(message, "no message")
	assert_false(shooter.aiming, "the shooter does not aim")
	assert_eq(shooter.verdict, Shooter.Verdict.NONE, "and its reticle shows nothing")
	assert_eq(flow.ammo, 3, "nothing spent")
	_assert_all_ready(board)


# --- The state machine of a target ---


func test_a_hit_target_goes_through_the_warning_then_the_effect() -> void:
	for kind: SabotageTarget.Kind in KINDS:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var target: SabotageTarget = _target(kind)
		assert_eq(target.state, READY, context + "a ready target")

		assert_true(target.receive(_message(target)), context + "the message is taken")

		assert_eq(target.state, WARNING, context + "in warning")
		for step: int in WARNING_STEPS - 1:
			target.step(NOBODY)
			assert_eq(target.state, WARNING, context + "step %d: still in warning" % step)
			assert_false(target.displaced, context + "still in its place")
		target.step(NOBODY)
		assert_eq(target.state, SABOTAGED, context + "after the warning: sabotaged")
		assert_true(target.displaced, context + "its effect is on")
		assert_almost_eq(target.time_left(), EFFECT_STEPS[kind] / 60.0, 0.001, context + "time")
		for step: int in EFFECT_STEPS[kind] - 1:
			target.step(NOBODY)
			assert_eq(target.state, SABOTAGED, context + "step %d of the effect" % step)
		target.step(NOBODY)
		assert_ne(target.state, SABOTAGED, context + "for the duration of its type, no more")
		assert_eq(target.warnings, 1, context + "one warning")
		assert_eq(target.effects, 1, context + "one effect")


func test_a_target_comes_back_then_rests() -> void:
	for kind: SabotageTarget.Kind in KINDS:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var target: SabotageTarget = _sabotaged(kind)
		for step: int in EFFECT_STEPS[kind] - 1:
			target.step(NOBODY)
		assert_true(target.displaced, context + "a sabotaged target")

		target.step(NOBODY)

		assert_false(target.displaced, context + "the effect over, it is back in its place")
		assert_eq(target.state, RESTING, context + "resting")
		assert_eq(target.returns, 1, context + "one return")
		for step: int in COOLDOWN_STEPS - 1:
			target.step(NOBODY)
			assert_eq(target.state, RESTING, context + "step %d: still resting" % step)
		target.step(NOBODY)
		assert_eq(target.state, READY, context + "then ready")


func test_a_target_that_is_not_ready_cannot_be_hit() -> void:
	var board: TargetBoard = _board()
	var waiting: SabotageTarget = board.target(IDS[OBSTACLE])
	var sabotaged: SabotageTarget = board.target(IDS[PLATFORM])
	var resting: SabotageTarget = board.target(IDS[BARRIER])
	var recovering: SabotageTarget = board.target(IDS[BRIDGE])
	for target: SabotageTarget in board.targets.values():
		assert_true(board.receive(_message(target)), "every target hit once")
	_steps(board, [waiting], WARNING_STEPS - 10, NOBODY)
	_steps(board, [sabotaged, resting, recovering], WARNING_STEPS + 10, NOBODY)
	_steps(board, [resting], EFFECT_STEPS[BARRIER], NOBODY)
	_steps(board, [recovering], EFFECT_STEPS[BRIDGE] - 10, [RUNNER])
	assert_eq(waiting.state, WARNING, "one in warning")
	assert_eq(sabotaged.state, SABOTAGED, "one sabotaged")
	assert_eq(resting.state, RESTING, "one resting")
	assert_eq(recovering.state, RECOVERING, "one waiting to come back")
	var flow: FlowState = _flow(3)
	var shooter: Shooter = Shooter.new(SHOOTER, _tuning)

	for target: SabotageTarget in [waiting, sabotaged, resting, recovering]:
		var state: String = SabotageTarget.State.keys()[target.state]
		var before: SabotageTarget.State = target.state
		var time_before: float = target.time_left()
		assert_false(board.receive(_message(target)), state + ": the message is refused")
		var facts: AimFacts = AimFacts.new(target.id, IN_RANGE)
		var shot: SabotageMessage = shooter.follow(_shot(), facts, AT_STEP, board, flow)
		assert_null(shot, state + ": no shot")
		assert_eq(shooter.verdict, Shooter.Verdict.NONE, state + ": the reticle shows nothing")
		assert_eq(target.state, before, state + ": its state does not change")
		assert_eq(target.time_left(), time_before, state + ": nor its time")
		assert_eq(target.warnings, 1, state + ": one warning, no more")

	assert_eq(flow.ammo, 3, "no ammunition spent")


func test_a_target_does_not_come_back_onto_the_runner() -> void:
	for kind: SabotageTarget.Kind in [PLATFORM, BRIDGE]:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var target: SabotageTarget = _sabotaged(kind)
		for step: int in EFFECT_STEPS[kind] - 1:
			target.step(NOBODY)

		# The effect over, the runner where the object would come back, then away, back
		# in, and away for good.
		for step: int in 50:
			target.step([RUNNER])
			assert_true(target.displaced, context + "step %d: it waits" % step)
			assert_eq(target.state, RECOVERING, context + "step %d: to come back" % step)
		target.step([OTHER_RUNNER, RUNNER])
		assert_true(target.displaced, context + "with two runners there, it waits")
		target.step(NOBODY)

		assert_false(target.displaced, context + "the place free, it is back")
		assert_eq(target.state, RESTING, context + "and rests")
		target.step([RUNNER])
		assert_false(target.displaced, context + "a runner back on it changes nothing")
		assert_eq(target.hits, NOBODY, context + "and nobody is hit")


func test_a_target_does_not_land_on_the_runner() -> void:
	for kind: SabotageTarget.Kind in [OBSTACLE, BARRIER]:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var target: SabotageTarget = _target(kind)
		target.receive(_message(target))
		for step: int in WARNING_STEPS - 1:
			target.step(NOBODY)

		target.step([RUNNER])
		assert_eq(target.state, SABOTAGED, context + "the effect starts")
		assert_eq(target.hits, [RUNNER] as Array[int], context + "the runner there is hit")
		assert_false(target.displaced, context + "but nothing lands on it")
		for step: int in 20:
			target.step([RUNNER])
			assert_false(target.displaced, context + "step %d: it waits" % step)
		target.step(NOBODY)
		assert_true(target.displaced, context + "the place free, the effect is on")
		assert_eq(target.hits, NOBODY, context + "and hits nobody")

		# It goes back to where it came from, where no runner can be, when its effect is
		# over: counted from its start, not from its landing.
		for step: int in EFFECT_STEPS[kind] - 22:
			target.step([RUNNER])
		assert_true(target.displaced, context + "one step before its end, still on")
		target.step([RUNNER])
		assert_false(target.displaced, context + "back at the end of its effect")
		assert_eq(target.state, RESTING, context + "and rests")


# --- Being hit ---


func test_being_in_the_zone_when_the_effect_starts_breaks_the_combo() -> void:
	var board: TargetBoard = _board()
	var platform: SabotageTarget = board.target(IDS[PLATFORM])
	var flow: FlowState = _flow(0)
	var bystander: FlowState = _flow(0)
	var hud: FlowHud = HUD_SCENE.instantiate() as FlowHud
	hud.flow = flow
	add_child_autofree(hud)
	for runner_flow: FlowState in [flow, bystander]:
		runner_flow.gauge = 1.5 * _tuning.flow_tier_value
		_count(runner_flow, WALL_RUN)
		assert_true(runner_flow.in_combo(), "a runner in a combo")
	hud.refresh()
	board.receive(_message(platform))

	for step: int in WARNING_STEPS:
		platform.step([RUNNER])
		flow.follow_targets(board, RUNNER)
		bystander.follow_targets(board, OTHER_RUNNER)
		if step < WARNING_STEPS - 1:
			assert_true(flow.in_combo(), "step %d of the warning: not hit yet" % step)
	hud.refresh()

	assert_eq(platform.state, SABOTAGED, "the effect started")
	assert_eq(platform.hits, [RUNNER] as Array[int], "with the runner in its zone")
	assert_true(board.hit(RUNNER), "it is hit")
	assert_false(flow.in_combo(), "its combo is broken")
	assert_eq(flow.combos_broken, 1)
	assert_almost_eq(flow.gauge, 0.5 * _tuning.flow_tier_value + 150.0, 0.001, "a tier lost")
	assert_eq(flow.sabotages, 1, "a sabotage received")
	assert_eq(_shown(hud, "%TrickLabel"), "SABOTAGED", "SABOTAGED is shown")
	assert_eq(_shown(hud, "%MoveLabel"), "COMBO BROKEN", "and the combo broken")
	assert_false(board.hit(OTHER_RUNNER), "another runner, elsewhere, is not hit")
	assert_true(bystander.in_combo(), "its combo goes on")
	assert_eq(bystander.sabotages, 0)

	# Being in the zone during the effect is no new hit.
	platform.step([RUNNER])
	flow.follow_targets(board, RUNNER)
	assert_false(board.hit(RUNNER), "no new hit during the effect")
	assert_eq(flow.sabotages, 1, "one sabotage received, no more")


func test_leaving_the_zone_during_the_warning_avoids_being_hit() -> void:
	var board: TargetBoard = _board()
	var platform: SabotageTarget = board.target(IDS[PLATFORM])
	var flow: FlowState = _flow(0)
	_count(flow, WALL_RUN)
	var gauge: float = flow.gauge
	board.receive(_message(platform))

	# In the zone for most of the warning, out of it as the effect starts, back in it
	# right after.
	for step: int in WARNING_STEPS + 5:
		var inside: bool = step < WARNING_STEPS - 3 or step > WARNING_STEPS
		var zone: Array[int] = [RUNNER]
		platform.step(zone if inside else NOBODY)
		flow.follow_targets(board, RUNNER)
		assert_false(board.hit(RUNNER), "step %d: not hit" % step)

	assert_eq(platform.state, SABOTAGED, "the effect started")
	assert_true(flow.in_combo(), "the combo goes on")
	assert_eq(flow.gauge, gauge, "the gauge lost nothing")
	assert_eq(flow.sabotages, 0, "no sabotage received")


# --- Helpers ---


## One target of each kind, ready, on a board of their own.
func _board() -> TargetBoard:
	var board: TargetBoard = TargetBoard.new()
	for kind: SabotageTarget.Kind in KINDS:
		board.add(_target(kind))
	return board


func _target(kind: SabotageTarget.Kind) -> SabotageTarget:
	return SabotageTarget.new(IDS[kind], kind, _tuning, STEPS_PER_SECOND)


## A target of `kind` whose effect just started.
func _sabotaged(kind: SabotageTarget.Kind) -> SabotageTarget:
	var target: SabotageTarget = _target(kind)
	target.receive(_message(target))
	for step: int in WARNING_STEPS:
		target.step(NOBODY)
	assert_eq(target.state, SABOTAGED, "a target whose effect just started")
	return target


## Plays `steps` steps of the targets of `board` in `playing`, with `inside` in the zone
## of each.
func _steps(board: TargetBoard, playing: Array, steps: int, inside: Array[int]) -> void:
	for step: int in steps:
		for target: SabotageTarget in playing:
			assert_true(board.targets.values().has(target))
			target.step(inside)


func _message(target: SabotageTarget) -> SabotageMessage:
	return SabotageMessage.new(SHOOTER, target.id, AT_STEP)


func _flow(ammo: int) -> FlowState:
	var flow: FlowState = FlowState.new(_tuning, STEPS_PER_SECOND)
	flow.ammo = ammo
	return flow


## The aim held and the shot pressed.
func _shot() -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.aim_held = true
	intent.shoot_pressed = true
	return intent


## One step at which the motor announced `kind`, the runner in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, _tuning.top_speed, false)


func _assert_all_ready(board: TargetBoard) -> void:
	for target: SabotageTarget in board.targets.values():
		assert_eq(target.state, READY, "target %d stays ready" % target.id)


## The text of a label if it is on screen, nothing otherwise.
func _shown(hud: FlowHud, label_path: NodePath) -> String:
	var label: Label = hud.get_node_or_null(label_path) as Label
	if label == null or not label.visible:
		return ""
	return label.text
