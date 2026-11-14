extends CourseTest
## Shooting and sabotage on the test course (game/levels), in the real physics: the four
## types of targets placed on it, what each one does to a runner once sabotaged, the
## reticle on the real camera, and the course, which stays clearable by the test pilot
## (who never aims nor shoots) with every target ready and after each sabotage. Played
## without a screen, faster than real time with the same fixed step of 1/60 s (see
## ReplayTest).

const KINDS: Array[SabotageTarget.Kind] = [
	SabotageTarget.Kind.PLATFORM,
	SabotageTarget.Kind.BRIDGE,
	SabotageTarget.Kind.OBSTACLE,
	SabotageTarget.Kind.BARRIER,
]
const SABOTAGED: SabotageTarget.State = SabotageTarget.State.SABOTAGED
## Who shoots in these tests: nobody of the course.
const SHOOTER: int = 9
const FORWARD: Vector3 = Vector3.FORWARD
## A few steps more, for a scene to follow its target.
const FEW_STEPS: int = 5
## Steps a runner pushing ahead from its checkpoint is given to reach what stands ahead.
const RUN_STEPS: int = 90
## Frames for the camera to go over the shoulder.
const AIM_STEPS: int = 30


func test_every_type_of_target_is_on_the_course() -> void:
	var course: Course = _add_course()
	var blocks: Array[TargetBlock] = _blocks(course)
	var kinds: Array[SabotageTarget.Kind] = []
	var ids: Array[int] = []
	for block: TargetBlock in blocks:
		kinds.append(block.kind)
		assert_ne(block.target_id, SabotageTarget.NO_TARGET, "%s has an identity" % block.name)
		assert_false(ids.has(block.target_id), "%s has its own identity" % block.name)
		ids.append(block.target_id)
		assert_same(course.targets.target(block.target_id), block.target, "the course knows it")
	for kind: SabotageTarget.Kind in KINDS:
		var kind_name: String = SabotageTarget.Kind.keys()[kind]
		assert_true(kinds.has(kind), "at least one %s on the course" % kind_name)
	assert_eq(course.targets.targets.size(), blocks.size(), "every target, and no other")


func test_a_sabotaged_platform_no_longer_holds() -> void:
	var attempt: SectionRun = _section_run(LONG_JUMPS)
	var platform: TargetBlock = _block_of(attempt.course, SabotageTarget.Kind.PLATFORM)
	await _sabotage(attempt.course, platform)
	assert_true(platform.target.displaced, "a sabotaged platform")
	var top: float = _bounds_of(platform.get_node("Body")).end.y
	var lowest: Array[float] = [INF]
	var under: Array[bool] = [false]
	var runner: Player = attempt.course.player
	var body: AABB = _bounds_of(platform.get_node("Body"))
	runner.stepped.connect(
		func(_intent: MoveIntent) -> void:
			var at: Vector3 = runner.global_position
			var over: bool = at.z < body.end.z and at.z > body.position.z
			under[0] = under[0] or (over and at.y < top - 1.0)
			lowest[0] = minf(lowest[0], at.y)
	)

	await _play([attempt.run])

	assert_eq(attempt.run.outcome, PilotedRun.Outcome.FELL, "the runner fell")
	assert_true(under[0], "through the place of the platform")
	assert_eq(platform.target.state, SABOTAGED, "while it was sabotaged")


func test_a_runner_on_a_platform_as_its_effect_starts_is_hit() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	var platform: TargetBlock = _block_of(course, SabotageTarget.Kind.PLATFORM)
	var body: AABB = _bounds_of(platform.get_node("Body"))
	var on_it: Vector3 = Vector3(body.get_center().x, body.end.y, body.get_center().z)
	course.player.teleport(Transform3D(Basis.IDENTITY, on_it))
	await _wait_steps(SETTLE_STEPS)
	assert_true(course.player.is_on_floor(), "a runner standing on the platform")
	var flow: FlowState = course.flow
	flow.gauge = 1.5 * course.player.tuning.flow_tier_value
	flow.step([RunnerEvent.new(RunnerEvent.Kind.WALL_RUN, 0)] as Array[RunnerEvent], 9.0, false)
	assert_true(flow.in_combo(), "in a combo")
	var gauge: float = flow.gauge

	await _sabotage(course, platform)
	await _wait_steps(SETTLE_STEPS)

	assert_eq(flow.sabotages, 1, "the runner is hit, once")
	assert_false(flow.in_combo(), "its combo is broken")
	# A tier lost; out of a combo since, the gauge also dropped for at most the steps waited.
	var after_the_hit: float = gauge - course.player.tuning.flow_tier_value
	assert_lte(flow.gauge, after_the_hit, "a tier lost")
	assert_gt(flow.gauge, after_the_hit - course.player.tuning.flow_decay, "and no more")
	var label: Label = course.get_node("Hud/FlowHud").get_node("%TrickLabel") as Label
	assert_eq(label.text, "SABOTAGED", "shown on the HUD of the course")
	assert_lt(course.player.global_position.y, body.position.y, "and it falls through")


func test_a_sabotaged_bridge_leaves_a_gap() -> void:
	var course: Course = _add_course()
	var bridge: TargetBlock = _block_of(course, SabotageTarget.Kind.BRIDGE)
	await _sabotage(course, bridge)
	var place: AABB = _bounds_of(bridge.get_node("Body"))
	var middle: Vector3 = place.get_center()
	var probe: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		middle + Vector3.UP, middle + Vector3.DOWN * 3.0
	)
	var found: Dictionary = course.get_world_3d().direct_space_state.intersect_ray(probe)
	assert_true(found.is_empty(), "no walkway where the bridge was")

	var steps: int = 0
	var fell_in_the_gap: bool = false
	course.player.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, RUN_STEPS)
	while steps < RUN_STEPS and not fell_in_the_gap:
		await get_tree().physics_frame
		var at: Vector3 = course.player.global_position
		var in_the_gap: bool = at.z < place.end.z and at.z > place.position.z
		fell_in_the_gap = in_the_gap and at.y < place.position.y
		steps += 1

	assert_true(fell_in_the_gap, "the runner that comes to the edge falls into the gap")
	assert_eq(bridge.target.state, SABOTAGED, "while the bridge is sabotaged")


func test_the_gap_of_a_sabotaged_bridge_cannot_be_crossed() -> void:
	var attempt: SectionRun = _section_run(RUN_UP)
	var runner: Player = attempt.course.player
	var tuning: MovementTuning = runner.tuning
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var bonus: float = bonuses[tuning.flow_tier_count - 1]
	var fastest: float = tuning.top_speed * (1.0 + bonus)
	var bridge: TargetBlock = _block_of(attempt.course, SabotageTarget.Kind.BRIDGE)
	var gap: float = _bounds_of(bridge.get_node("Body")).size.z
	var reach: float = _farthest_crossing(tuning, fastest)
	gut.p(
		"bridge gap %.2f m, farthest jump then mantle at %.2f m/s: %.2f m" % [gap, fastest, reach]
	)
	assert_gt(gap, reach, "wider than a jump then a mantle cross, at the speed of tier 3")
	await _sabotage(attempt.course, bridge)
	var top: Array[float] = [0.0]
	runner.stepped.connect(
		func(_intent: MoveIntent) -> void:
			runner.motor.top_speed_bonus = bonus
			top[0] = maxf(top[0], Vector2(runner.velocity.x, runner.velocity.z).length())
	)

	await _play([attempt.run])

	assert_almost_eq(top[0], fastest, 0.05, "the pilot came at the speed of tier 3")
	assert_gt(attempt.run.jumps, 0, "it jumped at the edge")
	assert_eq(attempt.run.steps_mantling, 0, "no mantle at the far edge")
	assert_eq(attempt.run.outcome, PilotedRun.Outcome.FELL, "it fell into the gap")
	assert_false(attempt.run.goal_reached, "the far side is not reached")


func test_a_runner_waiting_at_the_edge_does_not_block_the_return_of_the_bridge() -> void:
	var course: Course = _add_course()
	var bridge: TargetBlock = _block_of(course, SabotageTarget.Kind.BRIDGE)
	var place: AABB = _bounds_of(bridge.get_node("Body"))
	var runner: Player = course.player
	var radius: float = runner.tuning.capsule_radius
	# Standing on the block before the gap, its capsule over the edge but above the
	# bridge: the lowest point of the capsule over the bridge is that high above its top.
	var from_the_edge: float = radius / 2.0
	var above: float = radius - sqrt(radius * radius - from_the_edge * from_the_edge)
	var at_the_edge: Vector3 = Vector3(0.0, place.end.y, place.end.z + from_the_edge)
	runner.teleport(Transform3D(Basis.IDENTITY, at_the_edge))
	await _wait_steps(SETTLE_STEPS)
	assert_true(runner.is_on_floor(), "a runner standing at the edge")
	assert_gt(above, 0.0, "not touching the volume of the bridge")
	await _sabotage(course, bridge)
	assert_true(bridge.holds(runner), "in the zone of the bridge")
	var effect: int = _steps_of(runner.tuning.sabotage_duration_bridge)

	await _wait_steps(effect + FEW_STEPS)

	assert_true(runner.is_on_floor(), "the runner still waits at the edge")
	assert_false(bridge.target.displaced, "the bridge came back")
	assert_eq(bridge.target.state, SabotageTarget.State.RESTING, "and rests")


func test_the_warning_leaves_time_to_get_off_a_platform() -> void:
	var attempt: SectionRun = _section_run(LONG_JUMPS)
	var course: Course = attempt.course
	var runner: Player = course.player
	var platform: TargetBlock = _block_of(course, SabotageTarget.Kind.PLATFORM)
	var body: AABB = _bounds_of(platform.get_node("Body"))
	var landing: Array[Vector3] = []
	var speed_on_landing: Array[float] = []
	runner.stepped.connect(
		func(_intent: MoveIntent) -> void:
			var at: Vector3 = runner.global_position
			var on_it: bool = at.z < body.end.z and at.z > body.position.z
			if landing.is_empty() and on_it and runner.is_on_floor():
				landing.append(at)
				speed_on_landing.append(Vector2(runner.velocity.x, runner.velocity.z).length())
				var message: SabotageMessage = SabotageMessage.new(SHOOTER, platform.target_id, 0)
				assert_true(course.targets.receive(message), "the platform warns as it lands")
	)

	await _play([attempt.run])
	var waited: int = 0
	while platform.target.effects == 0 and waited < 200:
		await get_tree().physics_frame
		waited += 1

	assert_eq(landing.size(), 1, "the runner landed on the platform")
	if landing.size() == 1:
		var into_it: float = body.end.z - landing[0].z
		gut.p("landed %.2f m into the platform, at %.2f m/s" % [into_it, speed_on_landing[0]])
		assert_lt(into_it, 2.0, "at its start")
		assert_gt(speed_on_landing[0], 0.95 * runner.tuning.top_speed, "at top speed")
	assert_eq(platform.target.effects, 1, "the effect started")
	assert_eq(course.flow.sabotages, 0, "the runner was gone: not hit")
	_assert_cleared(attempt)


func test_a_fallen_obstacle_can_be_cleared() -> void:
	var attempt: SectionRun = _section_run(BIG_DROP)
	var obstacle: TargetBlock = _block_of(attempt.course, SabotageTarget.Kind.OBSTACLE)
	await _sabotage(attempt.course, obstacle)
	assert_true(obstacle.target.displaced, "an obstacle fallen on the way")
	var fallen: AABB = _bounds_of(obstacle.get_node("Body"))
	var floor_top: float = _bounds_of(attempt.course.get_node("Blocks/BigDropLanding")).end.y
	assert_almost_eq(fallen.position.y, floor_top, NEAR, "on the floor of the way")

	await _play([attempt.run])

	_assert_cleared(attempt)
	assert_eq(obstacle.target.state, SABOTAGED, "the obstacle was still there")
	assert_true(
		attempt.course.player.global_position.z < fallen.position.z, "the runner is past it"
	)


func test_a_raised_barrier_is_cleared_by_jumping_and_climbing() -> void:
	var raised: SectionRun = _section_run(LOW_PASSAGE)
	var spacing: float = 2.0 * PilotedRun.bounds_of_the_blocks(raised.course).size.x
	var free: SectionRun = _section_run(LOW_PASSAGE, null, spacing)
	var barrier: TargetBlock = _block_of(raised.course, SabotageTarget.Kind.BARRIER)
	await _sabotage(raised.course, barrier)
	var runner: Player = raised.course.player
	var tuning: MovementTuning = runner.tuning
	var wall: AABB = _bounds_of(barrier.get_node("Body"))
	var path: float = runner.global_position.y
	assert_true(barrier.target.displaced, "a barrier raised on the way")
	assert_almost_eq(wall.position.y, path, NEAR, "out of the ground of the way")
	var height: float = wall.end.y - path
	assert_gt(height, tuning.mantle_max_height, "too high to climb without a jump")
	var from_the_top_of_a_jump: float = height - tuning.jump_height
	assert_gte(from_the_top_of_a_jump, tuning.mantle_min_height, "a mantle from a jump's top")
	assert_lte(from_the_top_of_a_jump, tuning.mantle_max_height, "within its reach")
	var up_as_it_climbed: Array[bool] = []
	runner.stepped.connect(
		func(_intent: MoveIntent) -> void:
			if runner.motor.state == RunnerMotor.State.MANTLING:
				up_as_it_climbed.append(barrier.target.displaced)
	)

	await _play([raised.run, free.run])

	_assert_cleared(raised)
	_assert_cleared(free)
	assert_gt(raised.run.steps_mantling, 0, "the runner climbed onto the barrier")
	assert_false(up_as_it_climbed.has(false), "while it was up")
	assert_gt(raised.run.jumps, free.run.jumps, "after a jump at it")
	var slower: int = raised.run.steps_to_the_goal
	assert_gt(slower, free.run.steps_to_the_goal, "slower than without the barrier")


func test_the_course_can_be_cleared_with_every_target_ready() -> void:
	var attempts: Array[SectionRun] = []
	var runs: Array[PilotedRun] = []
	var spacing: float = 0.0
	for section: int in CHECKPOINT_NAMES.size():
		var attempt: SectionRun = _section_run(section, null, attempts.size() * spacing)
		if attempts.is_empty():
			spacing = 2.0 * PilotedRun.bounds_of_the_blocks(attempt.course).size.x
		attempts.append(attempt)
		runs.append(attempt.run)

	await _play(runs)

	for attempt: SectionRun in attempts:
		_assert_cleared(attempt)
		for block: TargetBlock in _blocks(attempt.course):
			var context: String = "%s, %s: " % [CHECKPOINT_NAMES[attempt.section], block.name]
			assert_true(block.target.is_ready(), context + "ready all along")
			assert_false(block.target.displaced, context + "in its place")


func test_the_course_stays_clearable_after_each_sabotage() -> void:
	var probe: Course = _add_course()
	var spacing: float = 2.0 * PilotedRun.bounds_of_the_blocks(probe).size.x
	var attempts: Array[SectionRun] = []
	var sabotaged: Array[TargetBlock] = []
	for block: TargetBlock in _blocks(probe):
		var section: int = _section_of(probe, block)
		var attempt: SectionRun = _section_run(section, null, (attempts.size() + 1) * spacing)
		var target: TargetBlock = _block_of_id(attempt.course, block.target_id)
		var message: SabotageMessage = SabotageMessage.new(SHOOTER, target.target_id, 0)
		assert_true(attempt.course.targets.receive(message), "%s sabotaged" % block.name)
		attempts.append(attempt)
		sabotaged.append(target)

	# Every one sabotaged while its runner waits at the checkpoint of its section, far
	# from it, until it is back.
	var waited: int = 0
	while waited < 1000 and sabotaged.any(_is_not_back):
		await get_tree().physics_frame
		waited += 1
	for target: TargetBlock in sabotaged:
		assert_gt(target.target.effects, 0, "%s: its effect happened" % target.name)
		assert_false(target.target.displaced, "%s: back in its place" % target.name)
	var runs: Array[PilotedRun] = []
	for attempt: SectionRun in attempts:
		runs.append(attempt.run)

	await _play(runs)

	for attempt: SectionRun in attempts:
		_assert_cleared(attempt)


func test_the_reticle_shows_a_shootable_target() -> void:
	var course: Course = _add_course()
	_start_at(course, LONG_JUMPS)
	await _wait_steps(SETTLE_STEPS)
	course.flow.ammo = 1
	var platform: TargetBlock = _block_of(course, SabotageTarget.Kind.PLATFORM)
	var top: Vector3 = _bounds_of(platform.get_node("Body")).get_center() + Vector3.UP * 0.5
	var crosshair: Crosshair = course.get_node("Hud/Crosshair") as Crosshair
	assert_false(crosshair.visible, "no reticle before aiming")

	await _aim_at(course, top)

	assert_true(crosshair.visible, "a reticle while aiming")
	assert_eq(crosshair.look, Crosshair.Look.SHOOTABLE, "it shows a target it would hit")
	assert_true(platform.focused, "the target is set off")
	var material: StandardMaterial3D = _material(platform)
	assert_eq(material.emission_energy_multiplier, TargetBlock.FOCUS_ENERGY, "brighter")

	# The shot, through the course: the message, the ammunition spent, the warning.
	course.player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, FEW_STEPS, 0)
	await _wait_steps(FEW_STEPS)
	var message: SabotageMessage = course.shooter.last_message
	assert_not_null(message, "a shot")
	if message != null:
		assert_eq(message.target, platform.target_id, "at the platform")
		assert_eq(message.shooter, Course.RUNNER, "by the runner of the course")
	assert_eq(course.flow.ammo, 0, "its cost spent")
	assert_eq(platform.target.state, SabotageTarget.State.WARNING, "the platform warns")
	assert_false(platform.focused, "no longer shootable")
	assert_eq(crosshair.look, Crosshair.Look.NEUTRAL, "nor is the reticle on a target")


func test_the_reticle_shows_a_target_too_expensive() -> void:
	var course: Course = _add_course()
	await _wait_steps(SETTLE_STEPS)
	course.flow.ammo = 1
	var bridge: TargetBlock = _block_of(course, SabotageTarget.Kind.BRIDGE)
	var top: Vector3 = _bounds_of(bridge.get_node("Body")).get_center() + Vector3.UP * 0.25
	var crosshair: Crosshair = course.get_node("Hud/Crosshair") as Crosshair

	await _aim_at(course, top)

	assert_eq(course.shooter.aim.target, bridge.target_id, "the reticle on the bridge")
	assert_true(bridge.target.is_ready(), "a ready bridge")
	assert_true(crosshair.visible, "a reticle")
	assert_eq(crosshair.look, Crosshair.Look.BARRED, "barred: one ammunition, the bridge asks two")
	assert_false(bridge.focused, "the bridge is not set off")


## The target blocks of a course.
func _blocks(course: Course) -> Array[TargetBlock]:
	var blocks: Array[TargetBlock] = []
	for child: Node in course.get_node("Targets").get_children():
		var block: TargetBlock = child as TargetBlock
		assert_not_null(block, "%s is a target" % child.name)
		if block != null:
			blocks.append(block)
	return blocks


func _block_of(course: Course, kind: SabotageTarget.Kind) -> TargetBlock:
	for block: TargetBlock in _blocks(course):
		if block.kind == kind:
			return block
	return null


func _block_of_id(course: Course, id: int) -> TargetBlock:
	for block: TargetBlock in _blocks(course):
		if block.target_id == id:
			return block
	return null


## The section a block stands in: the last checkpoint before it along the course, which
## goes along -Z.
func _section_of(course: Course, block: TargetBlock) -> int:
	var section: int = RUN_UP
	for index: int in CHECKPOINT_NAMES.size():
		if _checkpoint(course, index).global_position.z > block.global_position.z:
			section = index
	return section


## A message of sabotage at `block`, from someone else, and the warning waited out.
func _sabotage(course: Course, block: TargetBlock) -> void:
	var message: SabotageMessage = SabotageMessage.new(SHOOTER, block.target_id, 0)
	assert_true(course.targets.receive(message), "%s hit" % block.name)
	await _wait_steps(_steps_of(course.player.tuning.sabotage_warning) + FEW_STEPS)
	assert_eq(block.target.state, SABOTAGED, "%s sabotaged" % block.name)


## A duration of the tuning, in fixed steps.
func _steps_of(seconds: float) -> int:
	return roundi(seconds * STEPS_PER_SECOND)


## The farthest a runner at `speed` crosses a gap between two floors at the same height,
## from the tuning: it jumps at the very end of its coyote time, flies at its speed, and
## reaches the far face with its feet as low as the highest ledge a mantle climbs; its
## capsule leaves the near edge and catches the far one a radius from its axis.
func _farthest_crossing(tuning: MovementTuning, speed: float) -> float:
	var coyote_drop: float = tuning.fall_gravity * tuning.coyote_time * tuning.coyote_time / 2.0
	var rise: float = sqrt(2.0 * tuning.jump_height / tuning.rise_gravity)
	var drop: float = tuning.jump_height - coyote_drop + tuning.mantle_max_height
	var fall: float = sqrt(2.0 * drop / tuning.fall_gravity)
	return speed * (tuning.coyote_time + rise + fall) + 2.0 * tuning.capsule_radius


func _is_not_back(block: TargetBlock) -> bool:
	return block.target.displaced or block.target.effects == 0


## The runner of `course` aims, the camera turned so that the centre of the screen is on
## `point`, until the camera is over the shoulder.
func _aim_at(course: Course, point: Vector3) -> void:
	var rig: CameraRig = course.player.camera_rig
	course.player.intent_source = ScriptedIntentSource.new().aim(Vector3.ZERO, 1000)
	for attempt: int in 3:
		await _wait_steps(AIM_STEPS)
		var towards: Vector3 = (point - rig.global_position).normalized()
		rig.rotation.y = atan2(-towards.x, -towards.z)
		rig.rotation.x = asin(towards.y)
	await _wait_steps(AIM_STEPS)


func _material(block: TargetBlock) -> StandardMaterial3D:
	var mesh: MeshInstance3D = block.get_node("Body/MeshInstance3D") as MeshInstance3D
	return mesh.material_override as StandardMaterial3D


## The box that holds a block, in the world.
func _bounds_of(block: Node) -> AABB:
	var collider: CollisionShape3D = block.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
