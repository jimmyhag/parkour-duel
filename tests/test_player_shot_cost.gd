extends ReplayTest
## What a shot costs a runner, in the real physics: two runners side by side on a long
## floor, one that aims and shoots as soon as it can, one that does not aim; the lag of
## the shooter, compared to the lag of the least aim computed from the tuning. Faster than
## real time with the same fixed step of 1/60 s (see ReplayTest).

## How the two runners of a race move as the shooter aims.
enum Move { RUN, SLIDE, ROLL }

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const WORLD_LAYER: int = 1
const TARGETS_LAYER: int = 3
const TARGET_ID: int = 5
## Two runners side by side, this far from the middle; a target this far ahead of them.
const LANE: float = 3.0
const FAR_TARGET: float = 40.0
## Steps to reach the top speed before aiming; steps of a slide; steps after them for
## the lag to settle, the runners at top speed again.
const RUN_STEPS: int = 30
const SLIDE_STEPS: int = 45
const LAG_STEPS: int = 90
## A fall that asks for a roll: the runners start this high above the floor, and press
## the slide this close to it.
const DROP: float = 7.0
const ROLL_HEIGHT: float = 1.5
## What a fixed step may shift a distance measured in the physics, in m.
const LAG_TOLERANCE: float = 0.05
const TOLERANCE: float = 0.001


## Runs ahead; after `start` steps, aims and presses the shot at every step until its
## shot goes, then lets go of the aim. Without a shooter, it does not aim. It slides for
## a while from the same step when it slides; when it rolls, it presses the slide just
## before the floor of its fall.
class QuickShooter:
	extends IntentSource

	var _shooter: Shooter
	var _start: int
	var _move: Move
	var _runner: Player
	var _rolled: bool = false
	var _steps: int = 0

	func _init(shooter: Shooter, start: int, move: Move, runner: Player) -> void:
		_shooter = shooter
		_start = start
		_move = move
		_runner = runner

	func next_intent() -> MoveIntent:
		_steps += 1
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = Vector3.FORWARD
		var started: bool = _steps > _start
		var shooting: bool = _shooter != null and started and _shooter.shots == 0
		intent.aim_held = shooting
		intent.shoot_pressed = shooting
		var slides: bool = _move == Move.SLIDE
		intent.slide_held = slides and started and _steps <= _start + SLIDE_STEPS
		intent.slide_pressed = slides and _steps == _start + 1
		var falling: bool = _runner.velocity.y < 0.0
		if _move == Move.ROLL and not _rolled and falling:
			if _runner.global_position.y < ROLL_HEIGHT:
				_rolled = true
				intent.slide_pressed = true
				intent.slide_held = true
		return intent


## What a race of two runners showed.
class Race:
	var lag: float = 0.0
	var shots: int = 0
	var state_at_the_shot: RunnerMotor.State = RunnerMotor.State.FALLING
	var target_state: SabotageTarget.State = SabotageTarget.State.READY
	var speed: float = 0.0


func test_every_shot_costs_advance_on_the_ground() -> void:
	var race: Race = await _race(Move.RUN)

	assert_eq(race.shots, 1, "the runner shot")
	assert_eq(race.state_at_the_shot, RunnerMotor.State.GROUNDED, "running")
	assert_eq(race.target_state, SabotageTarget.State.WARNING, "and hit the target")
	var tuning: MovementTuning = _project_tuning()
	assert_almost_eq(race.speed, tuning.top_speed, TOLERANCE, "both run at top speed again")
	var least: float = _lag_of_a_minimal_aim(tuning)
	assert_gt(least, 0.5, "a minimal aim costs a real distance")
	assert_gte(
		race.lag, least - LAG_TOLERANCE, "the shooter lost at least the lag of a minimal aim"
	)


func test_aiming_while_sliding_costs_advance() -> void:
	var race: Race = await _race(Move.SLIDE)

	assert_eq(race.shots, 1, "the runner shot")
	assert_eq(race.state_at_the_shot, RunnerMotor.State.SLIDING, "while sliding")
	assert_eq(race.target_state, SabotageTarget.State.WARNING, "and hit the target")
	var tuning: MovementTuning = _project_tuning()
	assert_almost_eq(race.speed, tuning.top_speed, TOLERANCE, "both run at top speed again")
	var least: float = _lag_of_a_minimal_aim(tuning)
	assert_gte(
		race.lag, least - LAG_TOLERANCE, "the shooter lost at least the lag of a minimal aim"
	)


func test_aiming_while_rolling_costs_advance() -> void:
	# Both fall from high enough for a roll, at top speed, and roll; one aims from the top
	# of its fall: its least aim is counted in the roll only.
	var race: Race = await _race(Move.ROLL)

	assert_eq(race.shots, 1, "the runner shot")
	assert_eq(race.state_at_the_shot, RunnerMotor.State.ROLLING, "while rolling")
	assert_eq(race.target_state, SabotageTarget.State.WARNING, "and hit the target")
	var tuning: MovementTuning = _project_tuning()
	assert_almost_eq(race.speed, tuning.top_speed, TOLERANCE, "both run at top speed again")
	var least: float = _lag_of_a_minimal_aim(tuning)
	assert_gte(
		race.lag, least - LAG_TOLERANCE, "the shooter lost at least the lag of a minimal aim"
	)


## Two runners side by side, sliding at the same moment, or falling from high enough to
## roll, as `move` says: one aims and shoots as soon as it can, the other does not aim.
## Returns what the race showed.
func _race(move: Move) -> Race:
	_add_box(Vector3(20.0, 1.0, 100.0), Vector3(0.0, -0.5, -40.0), WORLD_LAYER)
	var plain: Player = _add_player()
	var shooting: Player = _add_player()
	plain.position.x = -LANE
	shooting.position.x = LANE
	var tuning: MovementTuning = shooting.tuning
	# A target far ahead of both, within range.
	var wall: StaticBody3D = _add_box(
		Vector3(20.0, 6.0, 1.0), Vector3(0.0, 3.0, -FAR_TARGET - 0.5), TARGETS_LAYER
	)
	wall.set_meta(SabotageTarget.META, TARGET_ID)
	var board: TargetBoard = TargetBoard.new()
	var target: SabotageTarget = SabotageTarget.new(
		TARGET_ID, SabotageTarget.Kind.PLATFORM, tuning, STEPS_PER_SECOND
	)
	board.add(target)
	var flow: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	flow.ammo = 3
	var shooter: Shooter = Shooter.new(1, tuning, STEPS_PER_SECOND)
	var race: Race = Race.new()
	shooting.stepped.connect(
		func(intent: MoveIntent) -> void:
			var motor: RunnerMotor = shooting.motor
			var ground: bool = motor.is_on_the_ground()
			shooter.follow(intent, shooting.aim_facts, motor.steps, board, flow, ground)
			if shooter.shots > race.shots:
				race.shots = shooter.shots
				race.state_at_the_shot = motor.state
	)
	var start: int = RUN_STEPS
	if move == Move.ROLL:
		start = 0
		for runner: Player in [plain, shooting]:
			runner.position.y = DROP
			runner.velocity = Vector3.FORWARD * tuning.top_speed
	plain.intent_source = QuickShooter.new(null, start, move, plain)
	shooting.intent_source = QuickShooter.new(shooter, start, move, shooting)

	for step: int in RUN_STEPS + SLIDE_STEPS + LAG_STEPS:
		await get_tree().physics_frame

	race.lag = shooting.global_position.z - plain.global_position.z
	race.target_state = target.state
	race.speed = Vector2(shooting.velocity.x, shooting.velocity.z).length()
	return race


## The distance a runner at its top speed loses to an aim held on the ground for the
## least aim, then let go, computed from the tuning: it brakes down to the speed of an
## aim, runs at it until the least aim is over, then speeds up again.
func _lag_of_a_minimal_aim(tuning: MovementTuning) -> float:
	var lost_speed: float = tuning.top_speed * (1.0 - tuning.aim_speed_ratio)
	var braking: float = lost_speed / tuning.ground_deceleration
	var speeding_up: float = lost_speed / tuning.ground_acceleration
	var held: float = maxf(tuning.aim_min_time - braking, 0.0)
	return lost_speed * (braking / 2.0 + held + speeding_up / 2.0)


func _project_tuning() -> MovementTuning:
	return load("res://game/core/movement_tuning.tres") as MovementTuning


func _add_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


func _add_box(size: Vector3, center: Vector3, layer: int) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 0
	body.set_collision_layer_value(layer, true)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	body.position = center
	add_child_autofree(body)
	return body
