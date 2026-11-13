extends ReplayTest
## The walls the player layer reports to game/core, in the real physics: a wall a level
## excludes, or one that leans too far, gives no wall run, where a plain wall does. The
## runner is put in the air beside the wall, fast, pushing along it. Faster than real
## time with the same fixed step of 1/60 s (see ReplayTest).

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## The tuning the runner of that scene obeys.
const TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
## Long enough for a wall run to start, short enough for the runner to stay beside the
## middle of the wall.
const STEPS: int = 8
## The size of the walls: thickness, height, length.
const WALL_SIZE: Vector3 = Vector3(1.0, 10.0, 30.0)
## Where the runner is put, in the air.
const START: Vector3 = Vector3(0.0, 2.0, 0.0)
## Courses side by side, this far apart.
const ASIDE: float = 10.0


## One runner beside one wall, the wall at its left.
class BesideAWall:
	extends Node3D

	var runner: Player
	var wall: StaticBody3D
	## The runner ran along the wall at some step.
	var did_run_along: bool = false
	## It ran along the wall from its very first step, its visible body still looking at
	## the wall.
	var ran_along_at_once: bool = false
	var _steps: int = 0

	## A wall whose face, at the height of the middle of the runner's body, stands
	## `gap` metres from its side, leaning by `tilt` degrees, `height` tall; and, if
	## `ground` is finite, a floor that far under the runner's feet.
	func _init(gap: float, tilt: float, height: float, ground: float) -> void:
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		var tuning: MovementTuning = runner.tuning
		var middle: Vector3 = START + Vector3.UP * tuning.capsule_height / 2.0
		var normal: Vector3 = Vector3.RIGHT.rotated(Vector3.FORWARD, deg_to_rad(tilt))
		var face: Vector3 = middle + Vector3.LEFT * (tuning.capsule_radius + gap)
		var size: Vector3 = Vector3(WALL_SIZE.x, height, WALL_SIZE.z)
		wall = _block(size, face - normal * size.x / 2.0 + FORWARD * size.z / 2.0)
		wall.basis = Basis(Vector3.FORWARD, deg_to_rad(tilt))
		if is_finite(ground):
			var floor_size: Vector3 = Vector3(ASIDE, 1.0, WALL_SIZE.z)
			var under: Vector3 = START + Vector3.DOWN * (ground + floor_size.y / 2.0)
			_block(floor_size, under + FORWARD * floor_size.z / 2.0)
		runner.stepped.connect(_on_runner_stepped)

	func _block(size: Vector3, center: Vector3) -> StaticBody3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		var block: StaticBody3D = StaticBody3D.new()
		block.add_child(collider)
		block.position = center
		add_child(block)
		return block

	## The runner pushes `push`, flying at the top speed `approach` degrees off the
	## wall's axis, towards the wall.
	func launch(push: Vector3 = FORWARD, approach: float = 0.0) -> void:
		runner.teleport(Transform3D(Basis.IDENTITY, global_position + START))
		# The visible body looks at the wall: what the runner observes must not depend on
		# it (decision 22).
		(runner.get_node("Visual") as Node3D).rotation.y = PI / 2.0
		var flight: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(approach))
		runner.velocity = flight * runner.tuning.top_speed
		runner.intent_source = ScriptedIntentSource.new().hold(push, false, STEPS)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		_steps += 1
		var along: bool = runner.motor.state == WALL_RUNNING
		ran_along_at_once = ran_along_at_once or (along and _steps == 1)
		did_run_along = did_run_along or along


func test_an_excluded_wall_gives_no_wall_run() -> void:
	var gap: float = _close_to_the_side()
	var plain: BesideAWall = _beside_a_wall(gap, 0.0, 0)
	var excluded: BesideAWall = _beside_a_wall(gap, 0.0, 1)
	excluded.wall.add_to_group(Player.NO_WALL_RUN_GROUP)

	await _launch([plain, excluded])

	assert_true(plain.did_run_along, "a plain wall gives a wall run")
	assert_true(plain.ran_along_at_once, "at once, wherever the visible body looks")
	assert_false(excluded.did_run_along, "the same wall, excluded by its level, gives none")
	assert_lt(excluded.runner.velocity.y, 0.0, "the runner falls")


func test_a_wall_too_tilted_gives_no_wall_run() -> void:
	var gap: float = _close_to_the_side()
	var tolerated: float = (load(TUNING) as MovementTuning).wall_run_max_tilt
	var leaning: BesideAWall = _beside_a_wall(gap, tolerated / 2.0, 0)
	var too_tilted: BesideAWall = _beside_a_wall(gap, tolerated * 4.0 / 3.0, 1)

	await _launch([leaning, too_tilted])

	assert_true(leaning.did_run_along, "a wall leaning less than the tolerance gives a wall run")
	assert_false(too_tilted.did_run_along, "one leaning more gives none")
	assert_lt(too_tilted.runner.velocity.y, 0.0, "the runner falls")

	# What else the player measures of a wall and of the ground: a vertical wall too
	# short, or one beside a runner too close to the ground, gives none either.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var short: float = tuning.wall_run_min_wall_height * 3.0 / 4.0
	var too_short: BesideAWall = _beside_a_wall(gap, 0.0, 2, short)
	var too_low: BesideAWall = _beside_a_wall(
		gap, 0.0, 3, WALL_SIZE.y, tuning.wall_run_min_height / 2.0
	)
	await _launch([too_short, too_low])
	assert_false(too_short.did_run_along, "a wall too short gives none")
	assert_false(too_low.did_run_along, "nor a wall beside a runner too close to the ground")


func test_the_keyboard_diagonal_starts_a_wall_run() -> void:
	# Forward and the key towards the wall at the left, normalised as the keyboard gives
	# it, with the camera a few degrees off the wall's axis on either side; the runner
	# flies along the wall, or comes at it slightly.
	var diagonal: Vector3 = (FORWARD + Vector3.LEFT).normalized()
	var cameras: Array[float] = [-3.0, -1.0, 0.0, 1.0, 3.0]
	var approaches: Array[float] = [0.0, 20.0]
	var scenes: Array[BesideAWall] = []
	for approach: float in approaches:
		for camera: float in cameras:
			scenes.append(_beside_a_wall(_close_to_the_side(), 0.0, scenes.size()))
	for index: int in scenes.size():
		var camera: float = cameras[index % cameras.size()]
		var approach: float = approaches[index / cameras.size()]
		scenes[index].launch(diagonal.rotated(Vector3.UP, deg_to_rad(camera)), approach)
	for i: int in STEPS:
		await get_tree().physics_frame

	for index: int in scenes.size():
		var camera: float = cameras[index % cameras.size()]
		var approach: float = approaches[index / cameras.size()]
		var context: String = "camera %+.0f degrees, approach %.0f degrees" % [camera, approach]
		assert_true(scenes[index].did_run_along, context + ": a wall run")

	# In the core too, whatever the split of the tuning.
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	for split: float in [tuning.push_split_angle, tuning.push_split_angle * 2.0 / 3.0]:
		tuning.push_split_angle = split
		var body: MotorBody = MotorBody.new(tuning, START.y)
		body.velocity = FORWARD * tuning.top_speed
		body.set_wall(1, Vector3.RIGHT, _close_to_the_side(), WALL_SIZE.y)
		body.step(_intent(diagonal))
		assert_eq(body.motor.state, WALL_RUNNING, "split at %.0f degrees: a wall run" % split)


func _intent(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent


## A gap between the side of the runner and the face of the wall well within the reach
## of a wall run.
func _close_to_the_side() -> float:
	return (load(TUNING) as MovementTuning).wall_run_distance / 2.0


func _beside_a_wall(
	gap: float, tilt: float, place: int, height: float = WALL_SIZE.y, ground: float = INF
) -> BesideAWall:
	var scene: BesideAWall = BesideAWall.new(gap, tilt, height, ground)
	scene.position.x = place * ASIDE
	add_child_autofree(scene)
	return scene


func _launch(scenes: Array[BesideAWall]) -> void:
	for scene: BesideAWall in scenes:
		scene.launch()
	for i: int in STEPS:
		await get_tree().physics_frame
