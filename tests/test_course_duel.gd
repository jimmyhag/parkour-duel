extends DuelTest
## The duel (game/levels), in the real physics: two copies of the course side by side,
## the round that starts both runners at GO, the shots that only reach the opposing lane,
## the rematch; and what stays of the solo practice. Played without a screen, faster
## than real time with the same fixed step of 1/60 s (see ReplayTest).

## The least empty space between the two lanes, in m (spec, decision 1).
const LANE_GAP: float = 4.0
const FORWARD: Vector3 = Vector3.FORWARD
const FEW_STEPS: int = 5
## Who shoots in these tests when it is nobody of the duel.
const SOMEBODY_ELSE: int = 9
## Just before the finish line, on the last ledge, in a lane.
const BEFORE_THE_FINISH: Vector3 = Vector3(0.0, 2.8, -242.0)
const FINISH_STEPS: int = 60


func after_each() -> void:
	Input.action_release(&"jump")


func test_the_two_lanes_are_identical_and_apart() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	var mine: Lane = duel.player_lane
	var theirs: Lane = duel.opponent_lane
	var offset: Vector3 = theirs.global_position - mine.global_position
	assert_gt(offset.x, 0.0, "side by side")
	assert_almost_eq(offset.y, 0.0, NEAR, "at the same height")
	assert_almost_eq(offset.z, 0.0, NEAR, "level with each other")
	assert_eq(theirs.global_basis, mine.global_basis, "the same way, no mirror")

	assert_eq(_layout(theirs), _layout(mine), "the same blocks, targets and checkpoints")
	assert_gt(_layout(mine).size(), 40, "every block, target and checkpoint compared")

	var closest: float = INF
	for a: CollisionShape3D in _block_shapes(mine):
		for b: CollisionShape3D in _block_shapes(theirs):
			closest = minf(closest, _distance_between(_box_of(a), _box_of(b)))
	gut.p("closest blocks of the two lanes: %.3f m apart, lanes %.2f m apart" % [closest, offset.x])
	assert_gte(closest, LANE_GAP - 0.001, "at least 4 m of void between them")
	assert_lt(closest, LANE_GAP + 0.01, "and no more: the smallest such gap")


func test_the_runners_wait_for_go_and_start_together() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	var player: Player = duel.player_lane.player
	var bot: Player = duel.opponent_lane.player
	player.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, 1000)
	await _wait_steps(SETTLE_STEPS)
	var player_at: Vector3 = player.global_position
	var bot_at: Vector3 = bot.global_position
	var countdown: Label = duel.get_node("Hud/CountdownDisplay") as Label
	var shown: Array[String] = []
	var moved: bool = false
	var timed: bool = false
	while duel.round_state.phase == RoundState.Phase.COUNTDOWN:
		if shown.is_empty() or shown.back() != countdown.text:
			shown.append(countdown.text)
		moved = moved or player.global_position.distance_to(player_at) > NEAR
		moved = moved or bot.global_position.distance_to(bot_at) > NEAR
		for lane: Lane in [duel.player_lane, duel.opponent_lane] as Array[Lane]:
			timed = timed or lane.race.phase != RaceState.Phase.NOT_STARTED
		await get_tree().physics_frame

	assert_false(moved, "nobody moves before GO, pushing or not")
	assert_false(timed, "no timer runs before GO")
	assert_eq(shown, ["3", "2", "1"] as Array[String], "the countdown shown")
	var player_race: RaceState = duel.player_lane.race
	var bot_race: RaceState = duel.opponent_lane.race
	assert_eq(player_race.phase, RaceState.Phase.RUNNING, "the player's timer runs at GO")
	assert_eq(bot_race.phase, RaceState.Phase.RUNNING, "and the bot's")
	await _wait_steps(30)
	assert_eq(player_race.elapsed_steps, bot_race.elapsed_steps, "from the same step")
	assert_eq(countdown.text, "GO", "GO shown")
	assert_gt(player.global_position.distance_to(player_at), 1.0, "the player runs")
	assert_gt(bot.global_position.distance_to(bot_at), 1.0, "and the bot")


func test_the_rematch_resets_everything() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var lanes: Array[Lane] = [duel.player_lane, duel.opponent_lane]
	for lane: Lane in lanes:
		lane.flow.ammo = 2
		lane.flow.gauge = 1500.0
		lane.flow.style_score = 777
		var block: TargetBlock = _block_of_kind(lane, SabotageTarget.Kind.PLATFORM)
		lane.targets.receive(SabotageMessage.new(SOMEBODY_ELSE, block.target_id, 0))
	var player: Player = duel.player_lane.player
	await _put(player, BEFORE_THE_FINISH)
	player.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, FINISH_STEPS)
	await _wait_steps(FINISH_STEPS)
	var result: ResultScreen = duel.get_node("Hud/ResultScreen") as ResultScreen
	assert_eq(duel.round_state.phase, RoundState.Phase.FINISHED, "a round over")
	assert_true(result.visible, "its result on screen")
	assert_gt(duel.opponent_lane.race.elapsed_steps, 0, "the timers ran")

	# The player chooses the rematch, the first choice.
	await get_tree().process_frame
	Input.action_press(&"jump")
	await get_tree().process_frame
	Input.action_release(&"jump")
	await get_tree().physics_frame

	assert_false(result.visible, "the result is gone")
	assert_eq(duel.round_state.phase, RoundState.Phase.COUNTDOWN, "the countdown again")
	assert_eq(duel.clock.countdown(), 3, "from 3")
	for lane: Lane in lanes:
		var context: String = "lane %d: " % lane.runner_id
		assert_eq(lane.race.phase, RaceState.Phase.NOT_STARTED, context + "timer not started")
		assert_eq(lane.race.elapsed_steps, 0, context + "timer at zero")
		assert_eq(lane.race.last_checkpoint, 0, context + "back to the start")
		assert_eq(lane.flow.ammo, 0, context + "no ammunition")
		assert_eq(lane.flow.gauge, 0.0, context + "an empty gauge")
		assert_eq(lane.flow.style_score, 0, context + "no style score")
		for block: TargetBlock in lane.target_blocks():
			assert_true(block.target.is_ready(), context + "%s ready" % block.name)
			assert_false(block.target.displaced, context + "%s in its place" % block.name)
		var start: Vector3 = _checkpoint_of(lane, RUN_UP).global_position
		assert_lt(lane.player.global_position.distance_to(start), NEAR, context + "at the start")


func test_an_opposing_target_can_be_shot_from_the_section_before() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	var shot_range: float = duel.player_lane.tuning.shot_range
	var eyes_height: float = duel.player_lane.tuning.camera_look_height
	for pair: Array[Lane] in (
		[[duel.player_lane, duel.opponent_lane], [duel.opponent_lane, duel.player_lane]]
		as Array[Array]
	):
		var shooter_lane: Lane = pair[0]
		var target_lane: Lane = pair[1]
		for block: TargetBlock in target_lane.target_blocks():
			var section: int = _section_of_block(target_lane, block)
			# The section before; the start for a target of the first section. Its
			# checkpoint is the farthest point of it from the target.
			var before: int = maxi(section - 1, RUN_UP)
			var eyes: Vector3 = (
				_checkpoint_of(shooter_lane, before).global_position + Vector3.UP * eyes_height
			)
			var distance: float = eyes.distance_to(block.aim_point())
			var context: String = (
				"%s of lane %d, from %s of lane %d"
				% [
					block.name,
					target_lane.runner_id,
					CHECKPOINT_NAMES[before],
					shooter_lane.runner_id
				]
			)
			gut.p("%s: %.2f m" % [context, distance])
			assert_lte(distance, shot_range, context + ": within range")


func test_the_player_of_a_duel_shoots_the_opposing_lane_only() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var player: Player = duel.player_lane.player
	var flow: FlowState = duel.player_lane.flow
	var crosshair: Crosshair = duel.get_node("Hud/Crosshair") as Crosshair
	await _put(player, _checkpoint_of(duel.player_lane, LONG_JUMPS).global_position)
	flow.ammo = 1
	var own: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.PLATFORM)
	var theirs: TargetBlock = _block_of_kind(duel.opponent_lane, SabotageTarget.Kind.PLATFORM)

	await _aim_with_the_camera_at(player, own.aim_point())
	assert_eq(duel.player_lane.shooter.aim.target, own.target_id, "the reticle on its platform")
	assert_eq(crosshair.look, Crosshair.Look.NEUTRAL, "nothing to shoot there")
	player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, FEW_STEPS, 0)
	await _wait_steps(FEW_STEPS)
	assert_eq(flow.ammo, 1, "nothing spent")
	assert_true(own.target.is_ready(), "its own platform untouched")
	assert_true(theirs.target.is_ready(), "and the opposing one too")

	await _aim_with_the_camera_at(player, theirs.aim_point())
	assert_eq(crosshair.look, Crosshair.Look.SHOOTABLE, "the opposing platform can be shot")
	assert_true(theirs.focused, "and is set off")
	player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, FEW_STEPS, 0)
	await _wait_steps(FEW_STEPS)
	var message: SabotageMessage = duel.player_lane.shooter.last_message
	assert_not_null(message, "a shot")
	if message != null:
		assert_eq(message.shooter, PLAYER, "by the player")
		assert_eq(message.target, theirs.target_id, "at the opposing platform")
	assert_eq(theirs.target.state, SabotageTarget.State.WARNING, "which warns")
	assert_true(own.target.is_ready(), "its own one still ready")
	assert_eq(flow.ammo, 0, "its cost spent")


func test_solo_practice_stays_as_in_step_3() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	await _wait_steps(SETTLE_STEPS)
	course.flow.ammo = 1
	var platform: TargetBlock = _block_of_kind(course, SabotageTarget.Kind.PLATFORM)

	await _aim_with_the_camera_at(course.player, platform.aim_point())
	course.player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, FEW_STEPS, 0)
	await _wait_steps(FEW_STEPS)

	var message: SabotageMessage = course.shooter.last_message
	assert_not_null(message, "a shot at a target of its own course")
	if message != null:
		assert_eq(message.shooter, Course.RUNNER, "by its runner")
		assert_eq(message.target, platform.target_id, "at the platform")
	assert_eq(course.flow.ammo, 0, "its cost spent")
	assert_eq(platform.target.state, SabotageTarget.State.WARNING, "the platform warns")
	await _wait_steps(_steps_of_seconds(course.tuning.sabotage_warning) + FEW_STEPS)
	assert_eq(platform.target.state, SabotageTarget.State.SABOTAGED, "then is sabotaged")
	assert_true(platform.target.displaced, "gone from its place")


func test_a_platform_does_not_act_under_a_runner_in_the_air() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	var runner: Player = course.player
	var platform: TargetBlock = _block_of_kind(course, SabotageTarget.Kind.PLATFORM)
	var on_it: Vector3 = platform.aim_point()
	await _put(runner, Vector3(on_it.x, on_it.y + TargetBlock.AIM_BELOW_THE_TOP, on_it.z))
	assert_true(runner.is_on_floor(), "a runner standing on the platform")
	var warning: int = _steps_of_seconds(runner.tuning.sabotage_warning)
	var effect: int = _steps_of_seconds(runner.tuning.sabotage_duration_platform)
	course.targets.receive(SabotageMessage.new(SOMEBODY_ELSE, platform.target_id, 0))
	# It jumps on the spot so as to be in the air above the platform as the warning ends.
	await _wait_steps(warning - 20)
	runner.intent_source = ScriptedIntentSource.new().hold(Vector3.ZERO, true, 20)
	var waited_in_the_air: int = 0
	var waited_on_the_floor: int = 0
	var started: bool = false
	var started_on_the_floor: bool = false
	for step: int in 120:
		await get_tree().physics_frame
		var target: SabotageTarget = platform.target
		if target.state == SabotageTarget.State.WARNING and target.time_left() == 0.0:
			waited_in_the_air += int(not runner.is_on_floor())
			waited_on_the_floor += int(runner.is_on_floor())
		if target.state == SabotageTarget.State.SABOTAGED:
			started = true
			started_on_the_floor = runner.is_on_floor()
			break

	assert_gt(waited_in_the_air, 0, "the warning over, the effect waits while it is in the air")
	assert_eq(waited_on_the_floor, 0, "and not a step longer")
	assert_true(started, "then it starts")
	assert_true(started_on_the_floor, "once the runner is no longer in the air above it")
	assert_eq(course.flow.sabotages, 1, "a runner standing on it is hit as before")
	assert_almost_eq(
		platform.target.time_left(), effect / 60.0, 0.001, "its full time from its real start"
	)


## What a lane is made of, relative to the lane, to the millimetre: its blocks (with their
## shapes), its targets and its checkpoints.
func _layout(lane: Lane) -> Array[String]:
	var layout: Array[String] = []
	var to_lane: Transform3D = lane.global_transform.affine_inverse()
	for collider: CollisionShape3D in _block_shapes(lane):
		var box: AABB = to_lane * _box_of(collider)
		var shape: String = "%s %s" % [_mm(box.position), _mm(box.size)]
		layout.append("block %s %s" % [lane.get_path_to(collider), shape])
	for block: TargetBlock in lane.target_blocks():
		var at: String = _mm(to_lane * block.global_position)
		layout.append("target %s %d %d %s" % [block.name, block.target_id, block.kind, at])
	for index: int in CHECKPOINT_NAMES.size():
		var checkpoint: Checkpoint = _checkpoint_of(lane, index)
		var at: String = _mm(to_lane * checkpoint.global_position)
		layout.append("checkpoint %d %s" % [checkpoint.index, at])
	return layout


func _mm(at: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [at.x, at.y, at.z]


## The collision shapes of the blocks of a lane, its targets' included.
func _block_shapes(lane: Lane) -> Array[CollisionShape3D]:
	var shapes: Array[CollisionShape3D] = []
	for body: Node in lane.find_children("*", "StaticBody3D", true, false):
		for child: Node in body.get_children():
			if child is CollisionShape3D:
				shapes.append(child as CollisionShape3D)
	return shapes


## The shortest distance between two boxes.
func _distance_between(a: AABB, b: AABB) -> float:
	var gap: Vector3 = Vector3(
		maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), 0.0),
		maxf(maxf(b.position.y - a.end.y, a.position.y - b.end.y), 0.0),
		maxf(maxf(b.position.z - a.end.z, a.position.z - b.end.z), 0.0)
	)
	return gap.length()


func _steps_of_seconds(seconds: float) -> int:
	return roundi(seconds * STEPS_PER_SECOND)
