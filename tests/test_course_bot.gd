extends DuelTest
## The bot of a duel (game/levels, game/player), in the real physics: a full runner on the
## opposing lane, led by the pilot section after section, that aims and shoots the
## targets of the player's lane when the player nears one, paying the aim like a player.
## Played without a screen, faster than real time with the same fixed step of 1/60 s (see
## ReplayTest).

const FEW_STEPS: int = 5
## Where the player waits in its lane, on the block before the platform of the long
## jumps: 17.7 m before the middle of the platform.
const BEFORE_THE_PLATFORM: Vector3 = Vector3(0.0, 0.0, -40.0)
## Steps given to the bot to shoot, or to show that it does not.
const WATCH_STEPS: int = 120


func test_the_bot_clears_the_whole_course() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	var bot: Player = duel.opponent_lane.player
	var limit: int = roundi(duel.player_lane.tuning.round_time_limit * STEPS_PER_SECOND)
	var falls: Array[int] = [0]
	duel.opponent_lane.player.stepped.connect(
		func(_intent: MoveIntent) -> void:
			falls[0] += int(bot.global_position.y < duel.opponent_lane.fall_limit + 1.0)
	)
	await _wait_for_go(duel)
	# Nobody disturbs it: the player waits at the start, and never shoots.
	var steps: int = 0
	while duel.round_state.phase == RoundState.Phase.RUNNING and steps < limit + FEW_STEPS:
		await get_tree().physics_frame
		steps += 1

	var bot_race: RaceState = duel.opponent_lane.race
	(
		gut
		. p(
			(
				"the bot: %s in %.2f s, checkpoint %d, %d steps under the course, %d shots"
				% [
					RaceState.Phase.keys()[bot_race.phase],
					bot_race.elapsed_steps / 60.0,
					bot_race.last_checkpoint,
					falls[0],
					duel.opponent_lane.shooter.shots,
				]
			)
		)
	)
	assert_eq(bot_race.phase, RaceState.Phase.FINISHED, "the bot crossed the finish line")
	assert_lt(bot_race.elapsed_steps, limit, "before the time limit")
	assert_eq(duel.round_state.winner, OPPONENT, "and won the round")


func test_the_bot_sabotages_when_the_player_nears_a_target() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var bot: Player = duel.opponent_lane.player
	var player: Player = duel.player_lane.player
	var platform: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.PLATFORM)
	player.intent_source = IntentSource.new()
	await _put(player, BEFORE_THE_PLATFORM)
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	var eyes: Vector3 = bot.global_position + Vector3.UP * bot.tuning.camera_look_height
	var lead: float = (platform.aim_point() - player.global_position).dot(Vector3.FORWARD)
	assert_lte(lead, bot.tuning.bot_sabotage_lead, "the player nears the platform")
	assert_lte(eyes.distance_to(platform.aim_point()), bot.tuning.shot_range, "within range")
	duel.opponent_lane.flow.ammo = 1
	var aimed_from: Array[int] = [-1]
	bot.stepped.connect(
		func(intent: MoveIntent) -> void:
			if intent.aim_held and aimed_from[0] < 0:
				aimed_from[0] = bot.motor.steps
	)

	await _wait_steps(WATCH_STEPS)

	var message: SabotageMessage = duel.opponent_lane.shooter.last_message
	assert_not_null(message, "a message of sabotage from the bot")
	if message != null:
		assert_eq(message.shooter, OPPONENT, "it says the bot shot")
		assert_eq(message.target, platform.target_id, "at the platform")
		var aimed: int = message.step - aimed_from[0] + 1
		var aim_steps: int = roundi(bot.tuning.bot_aim_time * STEPS_PER_SECOND)
		assert_eq(aimed, aim_steps, "after aiming for the aim time of the bot")
	assert_ne(platform.target.state, SabotageTarget.State.READY, "the platform is hit")
	assert_eq(duel.opponent_lane.flow.ammo, 0, "its cost spent")


func test_the_bot_pays_for_the_aim() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var bot: Player = duel.opponent_lane.player
	var landing: Node3D = duel.opponent_lane.get_node("Blocks/BigDropLanding") as Node3D
	var top: float = _box_of(landing.get_node("CollisionShape3D") as CollisionShape3D).end.y
	await _put(bot, Vector3(landing.global_position.x, top, landing.global_position.z + 13.0))
	await _wait_steps(STEPS_PER_SECOND)
	var top_speed: float = bot.motor.top_speed()
	assert_almost_eq(_speed_of(bot), top_speed, 0.05, "the bot runs at its top speed")
	var obstacle: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.OBSTACLE)

	duel.bot_source.aim_at(obstacle.aim_point())
	var on_the_ground: Array[bool] = []
	var speeds: Array[float] = []
	for step: int in roundi(bot.tuning.bot_aim_time * STEPS_PER_SECOND) - 1:
		await get_tree().physics_frame
		on_the_ground.append(bot.motor.is_on_the_ground())
		speeds.append(_speed_of(bot))

	assert_false(on_the_ground.has(false), "running on the ground all along")
	assert_true(bot.motor.is_aiming(), "and aiming")
	var aimed_top_speed: float = top_speed * bot.tuning.aim_speed_ratio
	var last: float = speeds[speeds.size() - 1]
	var most: float = speeds.slice(15).max()
	assert_almost_eq(last, aimed_top_speed, 0.05, "the top speed of the aim")
	assert_lte(most, aimed_top_speed + 0.05, "and no more")


func test_the_bot_does_not_shoot_without_ammunition() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var bot: Player = duel.opponent_lane.player
	var player: Player = duel.player_lane.player
	var platform: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.PLATFORM)
	player.intent_source = IntentSource.new()
	await _put(player, BEFORE_THE_PLATFORM)
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	duel.opponent_lane.flow.ammo = 0
	var aimed: Array[bool] = [false]
	bot.stepped.connect(func(intent: MoveIntent) -> void: aimed[0] = aimed[0] or intent.aim_held)

	await _wait_steps(WATCH_STEPS)

	assert_eq(duel.opponent_lane.flow.ammo, 0, "still no ammunition")
	assert_eq(duel.opponent_lane.shooter.shots, 0, "no shot")
	assert_null(duel.opponent_lane.shooter.last_message, "no message of sabotage")
	assert_true(platform.target.is_ready(), "the platform stays ready")
	assert_false(aimed[0], "the bot did not even aim")
