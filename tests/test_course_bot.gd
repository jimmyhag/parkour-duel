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
## How hard the player pushes the stick to walk towards a target, slowly (0 to 1).
const WALK: float = 0.2
## Where the bot runs at the void after the platform of the long jumps, in its lane: a
## few metres before the edge of the block before it.
const BEFORE_THE_VOID: Vector3 = Vector3(0.0, 0.0, -46.5)


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


func test_the_bot_finishes_the_course_without_falling() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	var bot: Player = duel.opponent_lane.player
	var lowest: Array[float] = [INF]
	var respawns: Array[int] = [0]
	var last_at: Array[Vector3] = [Vector3.ZERO]
	bot.stepped.connect(
		func(_intent: MoveIntent) -> void:
			lowest[0] = minf(lowest[0], bot.global_position.y)
			# A return to a checkpoint is a jump of the body, farther than any step runs.
			respawns[0] += int(bot.global_position.distance_to(last_at[0]) > 2.0)
			last_at[0] = bot.global_position
	)
	await _wait_for_go(duel)
	respawns[0] = 0
	var limit: int = roundi(duel.player_lane.tuning.round_time_limit * STEPS_PER_SECOND)
	var steps: int = 0
	while duel.round_state.phase == RoundState.Phase.RUNNING and steps < limit + FEW_STEPS:
		await get_tree().physics_frame
		steps += 1

	var bot_race: RaceState = duel.opponent_lane.race
	gut.p("the bot: %.2f s, lowest at %.2f m" % [bot_race.elapsed_steps / 60.0, lowest[0]])
	assert_eq(bot_race.phase, RaceState.Phase.FINISHED, "the bot crossed the finish line")
	assert_eq(respawns[0], 0, "without one return to a checkpoint")
	var under: float = PilotedRun.bounds_of_the_blocks(duel.opponent_lane).position.y
	assert_gt(lowest[0], under, "never under the blocks of its lane")


func test_the_bot_does_not_sabotage_a_stopped_player_twice() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	# A short sabotage, for the platform to be ready again while the bot is near.
	var tuning: MovementTuning = duel.player_lane.tuning.duplicate() as MovementTuning
	tuning.sabotage_warning = 0.2
	tuning.sabotage_duration_platform = 0.5
	tuning.sabotage_cooldown = 0.3
	var bot: Player = duel.opponent_lane.player
	var player: Player = duel.player_lane.player
	player.apply_tuning(tuning)
	bot.apply_tuning(tuning)
	await _wait_for_go(duel)
	var platform: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.PLATFORM)
	var shooter: Shooter = duel.opponent_lane.shooter
	player.intent_source = IntentSource.new()
	await _put(player, BEFORE_THE_PLATFORM)
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	duel.opponent_lane.flow.ammo = 3
	await _wait_steps(SETTLE_STEPS)
	assert_eq(shooter.shots, 0, "a stopped player: no sabotage")

	# The player walks towards the platform for a moment, then stops. The bot waits at the
	# start of its long jumps, where an aim ends before the void, and sets off with it.
	bot.held = true
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	player.intent_source = ScriptedIntentSource.new().hold(Vector3.FORWARD * WALK, false, 10)
	bot.held = false
	await _wait_steps(WATCH_STEPS)
	assert_eq(shooter.shots, 1, "it approached: one sabotage")
	if shooter.last_message != null:
		assert_eq(shooter.last_message.target, platform.target_id, "of the platform")
	var waited: int = 0
	while not platform.target.is_ready() and waited < WATCH_STEPS:
		await get_tree().physics_frame
		waited += 1
	assert_true(platform.target.is_ready(), "the platform ready again")
	await _wait_steps(SETTLE_STEPS)
	assert_eq(shooter.shots, 1, "the stopped player: not a second time")

	# It walks on, without reaching a new checkpoint: still not the same target.
	bot.held = true
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	player.intent_source = _walking_on()
	bot.held = false
	await _wait_steps(WATCH_STEPS)
	assert_eq(duel.player_lane.race.last_checkpoint, LONG_JUMPS, "no new checkpoint")
	assert_eq(shooter.shots, 1, "nor while it approaches again")
	assert_eq(duel.opponent_lane.flow.ammo, 3 - platform.target.cost(), "one shot paid")


func test_the_bot_does_not_aim_before_a_jump() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var bot: Player = duel.opponent_lane.player
	var player: Player = duel.player_lane.player
	player.intent_source = IntentSource.new()
	await _put(player, BEFORE_THE_PLATFORM)
	var lane: Transform3D = duel.opponent_lane.global_transform
	bot.held = true
	# In the section of the long jumps, as if it had run there.
	duel.opponent_lane.race.reach_checkpoint(LONG_JUMPS)
	bot.teleport(Transform3D(Basis.IDENTITY, lane * BEFORE_THE_VOID))
	await _wait_steps(FEW_STEPS)
	duel.opponent_lane.flow.ammo = 3
	var edge: float = (lane * Vector3(0.0, 0.0, -49.5)).z
	var aimed_before_the_jump: Array[bool] = [false]
	var jumped: Array[bool] = [false]
	bot.stepped.connect(
		func(intent: MoveIntent) -> void:
			jumped[0] = jumped[0] or bot.global_position.z < edge
			aimed_before_the_jump[0] = (
				aimed_before_the_jump[0] or (intent.aim_held and not jumped[0])
			)
	)
	# The opportunity is open: the player walks towards its platform, within the bot's
	# range; the void is closer to the bot than the end of an aim.
	player.intent_source = _walking_on()
	bot.held = false
	await _wait_steps(WATCH_STEPS)

	assert_true(jumped[0], "the bot jumped over the void")
	assert_false(aimed_before_the_jump[0], "it did not start aiming before the jump")


func test_the_bot_sabotages_when_the_player_nears_a_target() -> void:
	var duel: Duel = _add_duel(Duel.Opponent.BOT)
	await _wait_for_go(duel)
	var bot: Player = duel.opponent_lane.player
	var player: Player = duel.player_lane.player
	var platform: TargetBlock = _block_of_kind(duel.player_lane, SabotageTarget.Kind.PLATFORM)
	player.intent_source = IntentSource.new()
	await _put(player, BEFORE_THE_PLATFORM)
	# The bot waits at the start of its long jumps, where an aim ends before the void.
	bot.held = true
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	var eyes: Vector3 = bot.global_position + Vector3.UP * bot.tuning.camera_look_height
	var lead: float = (platform.aim_point() - player.global_position).dot(Vector3.FORWARD)
	assert_lte(lead, bot.tuning.bot_sabotage_lead, "the player nears the platform")
	assert_lte(eyes.distance_to(platform.aim_point()), bot.tuning.shot_range, "within range")
	duel.opponent_lane.flow.ammo = 1
	player.intent_source = _walking_on()
	bot.held = false
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


## The player walking slowly on, the way of the course.
func _walking_on() -> ScriptedIntentSource:
	return ScriptedIntentSource.new().hold(Vector3.FORWARD * WALK, false, 2 * WATCH_STEPS)


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
	bot.held = true
	await _put(bot, _checkpoint_of(duel.opponent_lane, LONG_JUMPS).global_position)
	duel.opponent_lane.flow.ammo = 0
	player.intent_source = _walking_on()
	bot.held = false
	var aimed: Array[bool] = [false]
	bot.stepped.connect(func(intent: MoveIntent) -> void: aimed[0] = aimed[0] or intent.aim_held)

	await _wait_steps(WATCH_STEPS)

	assert_eq(duel.opponent_lane.flow.ammo, 0, "still no ammunition")
	assert_eq(duel.opponent_lane.shooter.shots, 0, "no shot")
	assert_null(duel.opponent_lane.shooter.last_message, "no message of sabotage")
	assert_true(platform.target.is_ready(), "the platform stays ready")
	assert_false(aimed[0], "the bot did not even aim")
