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

	## A wall whose face, at the height of the middle of the runner's body, stands
	## `gap` metres from its side, leaning by `tilt` degrees.
	func _init(gap: float, tilt: float) -> void:
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		var tuning: MovementTuning = runner.tuning
		var middle: Vector3 = START + Vector3.UP * tuning.capsule_height / 2.0
		var normal: Vector3 = Vector3.RIGHT.rotated(Vector3.FORWARD, deg_to_rad(tilt))
		var face: Vector3 = middle + Vector3.LEFT * (tuning.capsule_radius + gap)
		var box: BoxShape3D = BoxShape3D.new()
		box.size = WALL_SIZE
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		wall = StaticBody3D.new()
		wall.add_child(collider)
		wall.basis = Basis(Vector3.FORWARD, deg_to_rad(tilt))
		wall.position = face - normal * WALL_SIZE.x / 2.0 + FORWARD * WALL_SIZE.z / 2.0
		add_child(wall)
		runner.stepped.connect(_on_runner_stepped)

	func launch() -> void:
		runner.teleport(Transform3D(Basis.IDENTITY, global_position + START))
		runner.velocity = FORWARD * runner.tuning.top_speed
		runner.intent_source = ScriptedIntentSource.new().hold(FORWARD, false, STEPS)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		did_run_along = did_run_along or runner.motor.state == WALL_RUNNING


func test_an_excluded_wall_gives_no_wall_run() -> void:
	var gap: float = _close_to_the_side()
	var plain: BesideAWall = _beside_a_wall(gap, 0.0, 0)
	var excluded: BesideAWall = _beside_a_wall(gap, 0.0, 1)
	excluded.wall.add_to_group(Player.NO_WALL_RUN_GROUP)

	await _launch([plain, excluded])

	assert_true(plain.did_run_along, "a plain wall gives a wall run")
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


## A gap between the side of the runner and the face of the wall well within the reach
## of a wall run.
func _close_to_the_side() -> float:
	return (load(TUNING) as MovementTuning).wall_run_distance / 2.0


func _beside_a_wall(gap: float, tilt: float, place: int) -> BesideAWall:
	var scene: BesideAWall = BesideAWall.new(gap, tilt)
	scene.position.x = place * ASIDE
	add_child_autofree(scene)
	return scene


func _launch(scenes: Array[BesideAWall]) -> void:
	for scene: BesideAWall in scenes:
		scene.launch()
	for i: int in STEPS:
		await get_tree().physics_frame
