class_name DuelTest
extends CourseTest
## Base of the test scripts that play a duel (game/levels/duel.tscn) without a screen:
## how a duel is added, how its countdown is waited out, and what the tests of the duel
## need to read its lanes. Faster than real time with the same fixed step of 1/60 s (see
## ReplayTest).

const DUEL_SCENE: String = "res://game/levels/duel.tscn"
const PLAYER: int = Duel.PLAYER
const OPPONENT: int = Duel.OPPONENT
## More steps than a countdown lasts.
const COUNTDOWN_STEPS: int = 400
## Frames for the camera to go over the shoulder.
const AIM_STEPS: int = 30


## A duel against `opponent`, with the session `session`, `aside` metres beside the place
## where the scene puts it.
func _add_duel(
	opponent: Duel.Opponent, session: Session = Session.new(), aside: float = 0.0
) -> Duel:
	var duel: Duel = (load(DUEL_SCENE) as PackedScene).instantiate() as Duel
	duel.opponent = opponent
	duel.session = session
	duel.position.x = aside
	add_child_autofree(duel)
	return duel


## Waits for GO: the race of the round is on.
func _wait_for_go(duel: Duel) -> void:
	for step: int in COUNTDOWN_STEPS:
		if duel.round_state.phase == RoundState.Phase.RUNNING:
			return
		await get_tree().physics_frame
	assert_eq(duel.round_state.phase, RoundState.Phase.RUNNING, "GO came")


## The checkpoint of a section of a lane.
func _checkpoint_of(lane: Lane, section: int) -> Checkpoint:
	return lane.get_node("Checkpoints/" + CHECKPOINT_NAMES[section]) as Checkpoint


## The section a block stands in: the last checkpoint before it along its lane, which goes
## along -Z.
func _section_of_block(lane: Lane, block: Node3D) -> int:
	var section: int = RUN_UP
	for index: int in CHECKPOINT_NAMES.size():
		if _checkpoint_of(lane, index).global_position.z > block.global_position.z:
			section = index
	return section


func _block_of_kind(lane: Lane, kind: SabotageTarget.Kind) -> TargetBlock:
	for block: TargetBlock in lane.target_blocks():
		if block.kind == kind:
			return block
	return null


## Puts `runner` at `at`, facing -Z, and lets it settle.
func _put(runner: Player, at: Vector3) -> void:
	runner.teleport(Transform3D(Basis.IDENTITY, at))
	await _wait_steps(SETTLE_STEPS)


## The runner `runner` aims, its camera turned so that the centre of the screen is on
## `point`, until the camera is over the shoulder; then it keeps aiming.
func _aim_with_the_camera_at(runner: Player, point: Vector3) -> void:
	var rig: CameraRig = runner.camera_rig
	runner.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, 1000)
	for attempt: int in 3:
		await _wait_steps(AIM_STEPS)
		var towards: Vector3 = (point - rig.global_position).normalized()
		rig.rotation.y = atan2(-towards.x, -towards.z)
		rig.rotation.x = asin(towards.y)
	await _wait_steps(AIM_STEPS)


## The horizontal speed of a runner, in m/s.
func _speed_of(runner: Player) -> float:
	return Vector2(runner.velocity.x, runner.velocity.z).length()


## The box that holds a collision shape, in the world.
func _box_of(collider: CollisionShape3D) -> AABB:
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
