extends ReplayTest
## The vault in the real physics (docs/specs/vault.md): the player layer reports the low
## wall ahead to game/core from probes the way the body moves, never from where the
## visible body looks, and the runner passes over the wall on its own, without stopping,
## led by the pilot (which does not jump at what a vault passes over) or only pushing;
## the hands of the character go on the real top of the wall (HandPlant). Faster than real
## time with the same fixed step of 1/60 s (see ReplayTest).

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const FORWARD: Vector3 = Vector3.FORWARD
const VAULTING: RunnerMotor.State = RunnerMotor.State.VAULTING
## The low wall of the scenario, 1 m high and 0.4 m deep, across a flat floor; where its
## face stands along -Z, and where the goal of the pilot stands past it.
const WALL_HEIGHT: float = 1.0
const WALL_DEPTH: float = 0.4
const FACE: float = 15.0
const GOAL: float = 30.0
## Wide enough for the runner, and courses side by side this far apart.
const WIDTH: float = 6.0
const ASIDE: float = 10.0
## A runner faster than this has not stopped, in m/s.
const STOPPED: float = 1.0
## Steps of a run that only pushes forward: past the wall, well before the end of the floor.
const RUN_STEPS: int = 180
## Low walls of several heights within those a vault passes over, in m; how far from the
## edges of the top a hand is put, at the least; and how close to the top the wrist of the
## character must be, the hand on it, in m.
const HEIGHTS: Array[float] = [0.7, 1.0, 1.3]
const TOLERANCE: float = 0.001
const HAND_ON_THE_TOP: float = 0.05
## How far from the wall, before and after it, the runner of the hand test is played in real
## time, in m.
const NEAR_THE_WALL: float = 3.0


## A flat floor, a low wall across it and a goal past it, and a runner at its start; what
## the test sees of the runner, step by step, while it is near the wall.
class AtALowWall:
	extends Node3D

	var runner: Player
	var goal: Area3D
	var vaulted: bool = false
	var jumped: bool = false
	## The state of the runner at the step that followed its first vault.
	var state_after_the_vault: int = -1
	## The slowest the runner went from the step it came within a few metres of the wall to
	## the step it was past it, in m/s, and the steps that followed it there.
	var slowest_near_the_wall: float = INF
	var steps_past_the_wall: int = 0
	## Where the test turns the visible body at the end of every step, if anywhere: what the
	## runner observes must not depend on it.
	var forced_look: Vector3 = Vector3.ZERO

	var _visual: Node3D

	func _init() -> void:
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		_visual = runner.get_node("Visual") as Node3D
		var length: float = GOAL + 10.0
		_block(Vector3(WIDTH, 1.0, length), Vector3(0.0, -0.5, -length / 2.0 + 2.0))
		_block(
			Vector3(WIDTH, WALL_HEIGHT, WALL_DEPTH),
			Vector3(0.0, WALL_HEIGHT / 2.0, -FACE - WALL_DEPTH / 2.0)
		)
		goal = Area3D.new()
		var zone: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(WIDTH, 3.0, 1.0)
		zone.shape = box
		goal.add_child(zone)
		goal.collision_mask = runner.collision_layer
		goal.position = Vector3(0.0, 1.5, -GOAL)
		add_child(goal)
		runner.stepped.connect(_on_runner_stepped)

	func start() -> void:
		runner.teleport(Transform3D(Basis.IDENTITY, global_position))

	func _block(size: Vector3, center: Vector3) -> void:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		var block: StaticBody3D = StaticBody3D.new()
		block.add_child(collider)
		block.position = center
		add_child(block)

	func _on_runner_stepped(intent: MoveIntent) -> void:
		if not forced_look.is_zero_approx():
			_visual.rotation.y = atan2(-forced_look.x, -forced_look.z)
		var was_vaulting: bool = vaulted and state_after_the_vault < 0
		if was_vaulting and runner.motor.state != VAULTING:
			state_after_the_vault = runner.motor.state
		vaulted = vaulted or runner.motor.state == VAULTING
		jumped = jumped or intent.jump_pressed
		var along: float = -(runner.global_position.z - global_position.z)
		var beyond: float = FACE + WALL_DEPTH + runner.tuning.capsule_radius
		if along > FACE - 3.0 and along < beyond:
			var speed: float = Vector2(runner.velocity.x, runner.velocity.z).length()
			slowest_near_the_wall = minf(slowest_near_the_wall, speed)
		elif along >= beyond and runner.is_on_floor():
			steps_past_the_wall += 1


func test_the_pilot_vaults_a_low_wall_in_the_real_physics() -> void:
	var piloted: AtALowWall = _at_a_low_wall(0)
	var pushing: AtALowWall = _at_a_low_wall(1)
	# The visible body of the runner that only pushes looks aside the whole way: what it
	# observes does not depend on it.
	pushing.forced_look = Vector3.RIGHT
	pushing.runner.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, RUN_STEPS)

	var run: PilotedRun = PilotedRun.new(piloted.runner, piloted.goal, piloted)
	await _play([run])

	assert_eq(run.outcome, PilotedRun.Outcome.REACHED, "the pilot led the runner to the goal")
	assert_eq(run.jumps, 0, "led by the pilot: no jump was asked for")
	assert_gt(run.steps_vaulting, 0, "led by the pilot: the runner vaulted over the wall")
	gut.p("led by the pilot: %d steps vaulting, %d jumps" % [run.steps_vaulting, run.jumps])
	var grounded: int = RunnerMotor.State.GROUNDED
	for scene: AtALowWall in [piloted, pushing]:
		var context: String = "led by the pilot: " if scene == piloted else "only pushing: "
		assert_false(scene.jumped, context + "no jump")
		assert_true(scene.vaulted, context + "the runner vaulted over the wall on its own")
		assert_gt(scene.slowest_near_the_wall, STOPPED, context + "it never stopped at the wall")
		assert_eq(scene.state_after_the_vault, grounded, context + "it came out standing")
		assert_gt(scene.steps_past_the_wall, 0, context + "it went on, on the other side")


func test_the_hand_lands_on_top_of_the_obstacle() -> void:
	for height: float in HEIGHTS:
		var context: String = "a wall %.1f m high: " % height
		var edge: Vector3 = Vector3(0.0, height, -FACE)
		var plant: HandPlant = HandPlant.new(0.0, height, edge, FORWARD, WALL_DEPTH)
		# Where the clip shows the hand as it plants it: above the wall, short of its face,
		# or past its back.
		var aside: float = 0.3
		var hands: Array[Vector3] = [
			edge + FORWARD * WALL_DEPTH / 2.0 + Vector3(aside, 0.25, 0.0),
			edge - FORWARD * 0.2 + Vector3(aside, -0.1, 0.0),
			edge + FORWARD * (WALL_DEPTH + 0.3) + Vector3(aside, 0.4, 0.0),
		]
		for hand: Vector3 in hands:
			var target: Vector3 = plant.target(hand)
			assert_almost_eq(target.y, height, TOLERANCE, context + "at the height of its top")
			var along: float = (target - edge).dot(FORWARD)
			assert_gte(along, HandPlant.INSET - TOLERANCE, context + "past its face")
			assert_lte(along, WALL_DEPTH - HandPlant.INSET + TOLERANCE, context + "before its back")
			assert_almost_eq(target.x, aside, TOLERANCE, context + "where the hand is across")
		var over: Vector3 = hands[0]
		assert_almost_eq(
			plant.target(over).z, over.z, TOLERANCE, context + "over it, under the hand"
		)

	# With the files, the wrist of the character, planted, is on the real top of the wall.
	var scene: AtALowWall = _at_a_low_wall(0)
	var skeletons: Array[Node] = scene.runner.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		pass_test("without the Mixamo files, the target alone")
		return
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	# Where each wrist is shown at every frame where its hand is fully planted.
	var wrists: Array[Vector3] = []
	for node: Node in skeleton.find_children("*", "TwoBoneIK3D", false, false):
		var arm: TwoBoneIK3D = node as TwoBoneIK3D
		arm.modification_processed.connect(
			func() -> void:
				if arm.influence >= 1.0:
					var wrist: Vector3 = skeleton.get_bone_global_pose(arm.get_end_bone(0)).origin
					wrists.append(skeleton.get_global_transform_interpolated() * wrist)
		)
	scene.runner.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, RUN_STEPS)
	for i: int in RUN_STEPS:
		# Near the wall, the steps play in real time: the frames shown between two of them
		# show the hand as a screen would.
		var along: float = -(scene.runner.global_position.z - scene.global_position.z)
		var near: bool = along > FACE - NEAR_THE_WALL and along < FACE + NEAR_THE_WALL
		Engine.physics_ticks_per_second = STEPS_PER_SECOND * (1 if near else SPEED_UP)
		Engine.time_scale = 1 if near else SPEED_UP
		await get_tree().physics_frame
	Engine.physics_ticks_per_second = STEPS_PER_SECOND * SPEED_UP
	Engine.time_scale = SPEED_UP

	assert_true(scene.vaulted, "the runner vaulted")
	assert_gt(wrists.size(), 0, "the character planted a hand on the wall")
	var highest: float = -INF
	var lowest: float = INF
	for wrist: Vector3 in wrists:
		highest = maxf(highest, wrist.y - WALL_HEIGHT)
		lowest = minf(lowest, wrist.y - WALL_HEIGHT)
		var along: float = -(wrist.z - scene.global_position.z) - FACE
		assert_between(along, 0.0, WALL_DEPTH, "the wrist is over the top of the wall")
	gut.p(
		(
			"the planted wrist, above the top of the wall: from %.3f to %.3f m (%d frames)"
			% [lowest, highest, wrists.size()]
		)
	)
	assert_lte(highest, HAND_ON_THE_TOP, "the wrist is on the top, a few centimetres at most")
	assert_gte(lowest, 0.0, "never under it")


func _at_a_low_wall(place: int) -> AtALowWall:
	var scene: AtALowWall = AtALowWall.new()
	scene.position.x = place * ASIDE * 2.0
	add_child_autofree(scene)
	scene.start()
	return scene
