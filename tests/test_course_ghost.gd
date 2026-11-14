extends DuelTest
## The ghost of a duel (game/levels, game/player), in the real physics: it replays the
## best solo run of the session, step by step, on the opposing lane, and touches nothing.
## Played without a screen, faster than real time with the same fixed step of 1/60 s (see
## ReplayTest).

const FEW_STEPS: int = 5
const STEPS_AFTER_ITS_FINISH: int = 10
## Who shoots in these tests: nobody of the duel.
const SOMEBODY_ELSE: int = 9
const LANE_SCENE: String = "res://game/levels/lane.tscn"


func test_the_ghost_replays_the_best_solo_run() -> void:
	# A solo run of the last section, finished: where the runner's visible body was at
	# each step from the one before it first acted, in its course.
	var course: Course = _add_course()
	_start_at(course, FINAL)
	var where: Array[Transform3D] = []
	var runner: Player = course.player
	runner.stepped.connect(
		func(intent: MoveIntent) -> void:
			if course.race.phase == RaceState.Phase.FINISHED:
				return
			if where.is_empty() or intent.direction.is_zero_approx() and where.size() == 1:
				where.clear()
			where.append(course.global_transform.affine_inverse() * runner.visual_transform())
	)
	var finish: Area3D = course.get_node("FinishLine") as Area3D
	var solo: PilotedRun = await _pilot_to(runner, finish, course)
	assert_true(solo.goal_reached, "a solo run finished")
	var session: Session = course.session
	assert_true(session.has_solo_run(), "the session has it")
	var best: GhostRun = session.best_run
	course.queue_free()
	await get_tree().physics_frame

	var duel: Duel = _add_duel(Duel.Opponent.GHOST, session)
	var ghost: Node3D = duel.opponent_lane.get_node("Ghost") as Node3D
	assert_not_null(ghost, "a ghost, on the opposing lane")
	var lane: Transform3D = duel.opponent_lane.global_transform
	assert_gt(lane.origin.x, 1.0, "the opposing lane, beside the player's")
	# Each step after GO, the ghost against where the runner was as many steps into its run.
	var steps_shown: Array[int] = []
	var off: Array[String] = []
	var player: Player = duel.player_lane.player
	player.stepped.connect(
		func(_intent: MoveIntent) -> void:
			var step: int = duel.player_lane.race.elapsed_steps
			if duel.player_lane.race.phase != RaceState.Phase.RUNNING or step >= where.size():
				return
			var expected: Transform3D = lane * where[step]
			steps_shown.append(step)
			var shown: Transform3D = ghost.global_transform
			var apart: float = shown.origin.distance_to(expected.origin)
			var turned: bool = shown.basis.is_equal_approx(expected.basis)
			if apart > 0.001 or not turned:
				off.append("step %d: %.3f m away" % [step, apart])
	)
	await _wait_for_go(duel)
	await _wait_steps(where.size() + STEPS_AFTER_ITS_FINISH)

	assert_eq(steps_shown.size(), where.size() - 1, "every step of the run was compared")
	assert_eq(off, [] as Array[String], "the ghost was where the runner was, at each step")
	assert_eq(best.finish_frame, where.size() - 1, "the run ends where it finished")
	assert_eq(duel.round_state.phase, RoundState.Phase.FINISHED, "its finish ends the round")
	assert_eq(duel.round_state.winner, OPPONENT, "the ghost won: the player did not move")
	assert_eq(duel.round_state.finish_step(OPPONENT), best.finish_frame, "in its time")


func test_the_ghost_touches_nothing() -> void:
	# A run standing on the platform of the lane, from the start to long after.
	var on_it: Vector3 = _top_of_the_platform_in_its_lane()
	var frames: Array[Transform3D] = []
	for step: int in 2000:
		frames.append(Transform3D(Basis.IDENTITY, on_it))
	var duel: Duel = _add_duel(Duel.Opponent.GHOST, _session_with_a_run(frames))
	var opposing: Lane = duel.opponent_lane
	var platform: TargetBlock = _block_of_kind(opposing, SabotageTarget.Kind.PLATFORM)
	var ghost: Node3D = opposing.get_node("Ghost") as Node3D
	assert_eq(
		ghost.find_children("*", "CollisionObject3D", true, false).size(), 0, "no physics body"
	)
	await _wait_for_go(duel)
	await _wait_steps(FEW_STEPS)
	assert_lt(ghost.global_position.distance_to(platform.aim_point()), 0.1, "on the platform")
	# The player, in the ghost's place: nothing pushes it.
	var player: Player = duel.player_lane.player
	await _put(player, ghost.global_position + Vector3.UP * 0.01)
	var player_at: Vector3 = player.global_position
	await _wait_steps(SETTLE_STEPS)
	assert_lt(player.global_position.distance_to(player_at), NEAR, "the player stays put")

	opposing.targets.receive(SabotageMessage.new(SOMEBODY_ELSE, platform.target_id, 0))
	var warning: int = roundi(opposing.tuning.sabotage_warning * STEPS_PER_SECOND)
	var hit: bool = false
	var lowest: float = player_at.y
	for step: int in warning + 2 * FEW_STEPS:
		await get_tree().physics_frame
		hit = hit or not platform.target.hits.is_empty()
		lowest = minf(lowest, player.global_position.y)

	assert_eq(platform.target.effects, 1, "the platform's effect started under the ghost")
	assert_false(hit, "nobody hit")
	assert_eq(duel.player_lane.flow.sabotages, 0, "the player is not hit either")
	assert_lt(ghost.global_position.distance_to(platform.aim_point()), 0.1, "the ghost goes on")
	for step: int in SETTLE_STEPS:
		await get_tree().physics_frame
		lowest = minf(lowest, player.global_position.y)
	assert_lt(lowest, player_at.y - 1.0, "the player fell: nothing held it")


## Where a runner stands on the platform of a lane, in the lane.
func _top_of_the_platform_in_its_lane() -> Vector3:
	var lane: Node = (load(LANE_SCENE) as PackedScene).instantiate()
	var on_it: Vector3 = Vector3.ZERO
	for block: Node in lane.get_node("Targets").get_children():
		var target: TargetBlock = block as TargetBlock
		if target.kind == SabotageTarget.Kind.PLATFORM:
			var collider: CollisionShape3D = (
				target.get_node("Body/CollisionShape3D") as CollisionShape3D
			)
			var size: Vector3 = (collider.shape as BoxShape3D).size
			on_it = target.position + Vector3.UP * size.y / 2.0
	lane.free()
	return on_it


## A session whose best run is made of `frames`, finished long after them.
func _session_with_a_run(frames: Array[Transform3D]) -> Session:
	var run: GhostRun = GhostRun.new()
	for frame: Transform3D in frames:
		run.record(frame, true)
	if frames.is_empty():
		run.record(Transform3D.IDENTITY, true)
	run.finish(10000, 0)
	var session: Session = Session.new()
	session.offer(run)
	return session
