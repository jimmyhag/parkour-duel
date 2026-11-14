extends ReplayTest
## The ledges the player layer reports to game/core, in the real physics: a ledge is
## found from the face the body touches and the way the runner pushes, never from where
## the visible body looks (decision 22); a mantle ends standing on the ledge; a ledge
## whose top is covered gives no mantle. The runner starts near the foot of the face and
## is led by written intents. Faster than real time with the same fixed step of 1/60 s
## (see ReplayTest).

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const MANTLING: RunnerMotor.State = RunnerMotor.State.MANTLING
const NEAR: float = 0.05
## Where the face of the ledge stands along -Z, and how far before it the runner starts.
const FACE: float = 10.0
const START_GAP: float = 0.5
## Steps of the approach on the floor, then of the jump.
const APPROACH_STEPS: int = 40
const JUMP_STEPS: int = 60
## Courses side by side, this far apart.
const ASIDE: float = 10.0


## A floor, a ledge across it whose top stands `height` above the floor, a slab over
## that top if it is `covered`, and a runner near the foot of the face.
class AtALedge:
	extends Node3D

	var runner: Player
	var top: float
	## What the test sees of the runner, step by step.
	var did_mantle: bool = false
	var fell_after_the_mantle: bool = false
	## The runner at the step that followed its mantle: its state, whether it stood on a
	## floor, its altitude and its horizontal speed.
	var state_after_the_mantle: int = -1
	var on_floor_after_the_mantle: bool = false
	var altitude_after_the_mantle: float = 0.0
	var speed_after_the_mantle: float = 0.0
	## The widest angle, on the floor, between where the visible body looked and the way
	## into the face.
	var widest_look_aside: float = 0.0
	## Where the test turns the visible body at the end of every step before the mantle,
	## if anywhere: what the runner observes must not depend on it (decision 22).
	var forced_look: Vector3 = Vector3.ZERO

	var _was_mantling: bool = false
	var _visual: Node3D

	func _init(height: float, covered: bool) -> void:
		top = height
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		_visual = runner.get_node("Visual") as Node3D
		var depth: float = 1.0
		_block(Vector3(ASIDE, depth, FACE), Vector3(0.0, -depth / 2.0, -FACE / 2.0))
		var ledge: Vector3 = Vector3(ASIDE, height + depth, FACE)
		_block(ledge, Vector3(0.0, (height - depth) / 2.0, -FACE * 1.5))
		if covered:
			# A slab whose underside leaves less room than a standing body, and whose
			# own top is out of reach of any jump and mantle.
			var room: float = runner.tuning.capsule_height / 2.0
			var thickness: float = runner.tuning.capsule_height * 2.0
			var slab: Vector3 = Vector3(ASIDE, thickness, FACE)
			_block(slab, Vector3(0.0, height + room + thickness / 2.0, -FACE * 1.5))
		runner.stepped.connect(_on_runner_stepped)

	func launch(intents: ScriptedIntentSource) -> void:
		var start: Vector3 = FORWARD * (FACE - runner.tuning.capsule_radius - START_GAP)
		runner.teleport(Transform3D(Basis.IDENTITY, global_position + start))
		runner.intent_source = intents

	func _block(size: Vector3, center: Vector3) -> void:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		var block: StaticBody3D = StaticBody3D.new()
		block.add_child(collider)
		block.position = center
		add_child(block)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		var state: int = runner.motor.state
		if not forced_look.is_zero_approx() and not did_mantle:
			_visual.rotation.y = atan2(-forced_look.x, -forced_look.z)
		if runner.is_on_floor() and not did_mantle:
			var look: Vector3 = -_visual.global_basis.z
			look.y = 0.0
			widest_look_aside = maxf(widest_look_aside, look.angle_to(FORWARD))
		if _was_mantling and state != MANTLING and state_after_the_mantle < 0:
			state_after_the_mantle = state
			on_floor_after_the_mantle = runner.is_on_floor()
			altitude_after_the_mantle = runner.global_position.y
			speed_after_the_mantle = Vector2(runner.velocity.x, runner.velocity.z).length()
		if did_mantle and not _was_mantling:
			fell_after_the_mantle = fell_after_the_mantle or state == RunnerMotor.State.FALLING
		did_mantle = did_mantle or state == MANTLING
		_was_mantling = state == MANTLING


func test_a_ledge_approached_at_an_angle_gives_a_mantle() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	# The split is measured from the surface, as the motor does: a push counts as towards
	# the face up to (90 - split) degrees off its normal. Aim halfway inside that, slow
	# enough along the face for no wall run.
	var towards_limit: float = 90.0 - tuning.push_split_angle
	var aslant: float = deg_to_rad(towards_limit) / 2.0
	var direction: Vector3 = FORWARD.rotated(Vector3.UP, -aslant)
	var scene: AtALedge = _at_a_ledge(_ledge_height(tuning), false, 0)
	# The visible body faces the push (docs/specs/runner-facing.md): the test turns it
	# along the face, the way the push slides, as the physics turned it before.
	scene.forced_look = Vector3.RIGHT

	await _play_at(scene, direction)

	var aside: float = rad_to_deg(scene.widest_look_aside)
	assert_gt(aside, towards_limit, "the visible body turned along the face, past the limit")
	assert_true(scene.did_mantle, "and yet the runner mantled")


func test_the_mantle_ends_standing_on_the_ledge() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var scene: AtALedge = _at_a_ledge(_ledge_height(tuning), false, 0)

	await _play_at(scene, FORWARD)

	assert_true(scene.did_mantle, "the runner mantled")
	var grounded: int = RunnerMotor.State.GROUNDED
	assert_eq(scene.state_after_the_mantle, grounded, "the step after: standing")
	assert_true(scene.on_floor_after_the_mantle, "on a floor")
	assert_almost_eq(scene.altitude_after_the_mantle, scene.top, NEAR, "on top of the ledge")
	var exit_speed: float = tuning.mantle_exit_speed
	assert_almost_eq(scene.speed_after_the_mantle, exit_speed, NEAR, "at the exit speed")
	assert_false(scene.fell_after_the_mantle, "without a fall")


func test_a_covered_ledge_gives_no_mantle() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var free: AtALedge = _at_a_ledge(_ledge_height(tuning), false, 0)
	var covered: AtALedge = _at_a_ledge(_ledge_height(tuning), true, 1)

	await _play_at_once([free, covered], FORWARD)

	assert_true(free.did_mantle, "the same ledge, free, is climbed")
	assert_false(covered.did_mantle, "covered, it is not")


## Above any jump, within a mantle.
func _ledge_height(tuning: MovementTuning) -> float:
	return (tuning.jump_height + tuning.mantle_max_height) / 2.0


func _at_a_ledge(height: float, covered: bool, place: int) -> AtALedge:
	var scene: AtALedge = AtALedge.new(height, covered)
	scene.position.x = place * ASIDE * 2.0
	add_child_autofree(scene)
	return scene


func _play_at(scene: AtALedge, direction: Vector3) -> void:
	await _play_at_once([scene], direction)


## The runners push `direction` on the floor, then jump while still pushing it.
func _play_at_once(scenes: Array[AtALedge], direction: Vector3) -> void:
	for scene: AtALedge in scenes:
		var intents: ScriptedIntentSource = ScriptedIntentSource.new()
		scene.launch(
			intents.hold(direction, false, APPROACH_STEPS).hold(direction, true, JUMP_STEPS)
		)
	for i: int in APPROACH_STEPS + JUMP_STEPS:
		await get_tree().physics_frame
