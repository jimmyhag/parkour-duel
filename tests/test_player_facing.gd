extends ReplayTest
## Where the visible body of the runner looks, in the real physics: where the runner
## pushes on the floor and in the air, never where the scenery lets it go; where it moves
## in a slide; along the wall in a wall run; nowhere new during a mantle; and upright out
## of a wall run. The visor is measured at every step, on blocks built for each case.
## Faster than real time with the same fixed step of 1/60 s (see ReplayTest).

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## The tuning the runner of that scene obeys.
const TUNING: String = "res://game/core/movement_tuning.tres"
const FORWARD: Vector3 = Vector3.FORWARD
const MANTLING: RunnerMotor.State = RunnerMotor.State.MANTLING
const SLIDING: RunnerMotor.State = RunnerMotor.State.SLIDING
const WALL_RUNNING: RunnerMotor.State = RunnerMotor.State.WALL_RUNNING
## Angles are compared within this many degrees, once a turn is over.
const ANGLE_TOLERANCE: float = 2.0
## A push meant straight ahead, as a real camera holds it: a few degrees off on either
## side, or not at all.
const CAMERA_OFFSETS: Array[float] = [-3.0, -1.0, 0.0, 1.0, 3.0]
## Where the face of the block ahead stands along -Z, and how far before it the runner
## starts.
const FACE: float = 10.0
const START_GAP: float = 0.5
## The width of the blocks, and how far apart the courses stand side by side.
const WIDTH: float = 12.0
const ASIDE: float = 20.0
## A wall no jump and no mantle gets over.
const TALL: float = 10.0
## Steps of an approach on the floor, then of a jump.
const APPROACH_STEPS: int = 40
const JUMP_STEPS: int = 60


## What the test sees of the runner at the end of one step.
class Moment:
	## Where the visor looks, where the runner pushes and where its body moves, all
	## horizontal and of unit length (zero for no push or no motion).
	var look: Vector3
	var push: Vector3
	var motion: Vector3
	## The axis of the visible body that stands up when the body is upright, and the one
	## its visor looks along, in the world.
	var up: Vector3
	var front: Vector3
	var state: RunnerMotor.State
	var on_floor: bool
	var on_wall: bool


## The intents of a written sequence, except that once the runner mantles, it pushes
## `elsewhere`. The state read is the one of the step before: the step that starts the
## mantle still follows the sequence.
class PushElsewhereInTheMantle:
	extends IntentSource

	var _runner: Player
	var _sequence: IntentSource
	var _elsewhere: Vector3

	func _init(runner: Player, sequence: IntentSource, elsewhere: Vector3) -> void:
		_runner = runner
		_sequence = sequence
		_elsewhere = elsewhere

	func next_intent() -> MoveIntent:
		var intent: MoveIntent = _sequence.next_intent()
		if _runner.motor.state == MANTLING:
			intent.direction = _elsewhere
		return intent


## One runner on blocks of its own, watched at every step.
class Track:
	extends Node3D

	var runner: Player
	var moments: Array[Moment] = []
	var _visual: Node3D

	func _init() -> void:
		runner = PLAYER_SCENE.instantiate() as Player
		add_child(runner)
		_visual = runner.get_node("Visual") as Node3D
		runner.stepped.connect(_on_runner_stepped)

	## A floor from behind the start to `length` metres along -Z, its top at height 0.
	func add_floor(length: float) -> void:
		var back: float = 5.0
		var size: Vector3 = Vector3(WIDTH, 1.0, length + back)
		add_block(size, Vector3(0.0, -0.5, back - size.z / 2.0))

	## A block on the floor whose face stands at FACE along -Z, `height` tall and `depth`
	## deep.
	func add_block_ahead(height: float, depth: float) -> void:
		add_block(Vector3(WIDTH, height, depth), Vector3(0.0, height / 2.0, -FACE - depth / 2.0))

	func add_block(size: Vector3, center: Vector3) -> StaticBody3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = box
		var block: StaticBody3D = StaticBody3D.new()
		block.add_child(collider)
		block.position = center
		add_child(block)
		return block

	## Puts the runner at `at` (on this track), looking along -Z, moving at `velocity`,
	## led by `intents`.
	func start(
		at: Vector3, intents: ScriptedIntentSource, velocity: Vector3 = Vector3.ZERO
	) -> void:
		runner.teleport(Transform3D(Basis.IDENTITY, global_position + at))
		runner.velocity = velocity
		runner.intent_source = intents

	## Where the runner starts near the foot of the face ahead.
	func near_the_face() -> Vector3:
		return FORWARD * (FACE - runner.tuning.capsule_radius - START_GAP)

	## The moments the runner spent in `state`.
	func moments_in(state: RunnerMotor.State) -> Array[Moment]:
		return moments.filter(func(moment: Moment) -> bool: return moment.state == state)

	func _on_runner_stepped(intent: MoveIntent) -> void:
		var moment: Moment = Moment.new()
		moment.look = _horizontal(-_visual.global_basis.z)
		moment.push = _horizontal(intent.direction)
		moment.motion = _horizontal(runner.velocity)
		moment.up = _visual.global_basis.y.normalized()
		moment.front = -_visual.global_basis.z.normalized()
		moment.state = runner.motor.state
		moment.on_floor = runner.is_on_floor()
		moment.on_wall = runner.is_on_wall()
		moments.append(moment)

	func _horizontal(vector: Vector3) -> Vector3:
		return Vector3(vector.x, 0.0, vector.z).normalized()


# --- Against a face (real physics) ---


func test_jumping_against_a_wall_pushing_straight_keeps_the_runner_facing_the_wall() -> void:
	var tracks: Array[Track] = []
	for offset: float in CAMERA_OFFSETS:
		var track: Track = _track(tracks.size())
		track.add_floor(FACE * 2.0)
		track.add_block_ahead(TALL, FACE)
		var push: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(offset))
		var intents: ScriptedIntentSource = ScriptedIntentSource.new()
		intents.hold(push, false, APPROACH_STEPS).hold(push, true, JUMP_STEPS)
		track.start(track.near_the_face(), intents)
		tracks.append(track)

	await _steps(APPROACH_STEPS + JUMP_STEPS)

	for index: int in tracks.size():
		var offset: float = CAMERA_OFFSETS[index]
		var context: String = "camera %+.0f degrees" % offset
		var moments: Array[Moment] = tracks[index].moments
		var in_the_air: Array[Moment] = moments.filter(
			func(moment: Moment) -> bool: return moment.on_wall and not moment.on_floor
		)
		assert_gt(in_the_air.size(), 0, context + ": the runner jumped against the wall")
		assert_eq(tracks[index].moments_in(MANTLING).size(), 0, context + ": with no mantle")
		var widest: float = _widest_angle(moments, FORWARD, true)
		assert_lt(widest, absf(offset) + ANGLE_TOLERANCE, context + ": it looked at the wall")


func test_running_against_a_wall_pushing_aslant_keeps_the_runner_facing_its_push() -> void:
	var track: Track = _track(0)
	track.add_floor(FACE * 2.0)
	track.add_block_ahead(TALL, FACE)
	var aslant: float = 30.0
	var push: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(-aslant))
	var steps: int = 60
	track.start(track.near_the_face(), ScriptedIntentSource.new().hold(push, false, steps))

	await _steps(steps)

	var against: Array[Moment] = track.moments.filter(
		func(moment: Moment) -> bool: return moment.on_wall and moment.on_floor
	)
	assert_gt(against.size(), _turn_steps(aslant), "the runner ran against the wall")
	var sliding: Vector3 = track.runner.velocity
	assert_gt(sliding.x, 1.0, "the physics made it slide along the wall")
	assert_almost_eq(sliding.z, 0.0, 0.01, "and only along it")
	var after_the_turn: Array[Moment] = track.moments.slice(_turn_steps(aslant))
	var widest: float = _widest_angle(after_the_turn, push, true)
	assert_lt(widest, ANGLE_TOLERANCE, "it looked at its push, not along the wall")


func test_a_sideways_velocity_does_not_turn_a_runner_that_does_not_push() -> void:
	var track: Track = _track(0)
	track.add_floor(FACE * 2.0)
	var settle: int = 10
	var steps: int = 30
	track.start(Vector3.ZERO, ScriptedIntentSource.new())
	await _steps(settle)
	assert_true(track.runner.is_on_floor(), "the runner stands on the floor")
	track.runner.velocity = Vector3.RIGHT * track.runner.tuning.top_speed / 2.0

	await _steps(steps)

	assert_gt(track.runner.global_position.x, 0.1, "a sideways velocity moved it")
	var widest: float = _widest_angle(track.moments, FORWARD, false)
	assert_lt(widest, ANGLE_TOLERANCE, "it kept looking ahead")


# --- Turning towards the push ---


func test_the_runner_turns_towards_where_it_pushes_at_the_tuned_pace() -> void:
	var turn_speed: float = (load(TUNING) as MovementTuning).turn_speed
	var track: Track = _track(0)
	track.add_floor(FACE * 4.0)
	var run_up: int = 30
	var turn: int = 20
	var intents: ScriptedIntentSource = ScriptedIntentSource.new()
	track.start(Vector3.ZERO, intents.hold(FORWARD, false, run_up).hold(Vector3.RIGHT, false, turn))

	await _steps(run_up + turn)

	var running: Moment = track.moments[run_up - 1]
	assert_lt(rad_to_deg(running.look.angle_to(FORWARD)), ANGLE_TOLERANCE, "running ahead")
	var step: float = 1.0 / STEPS_PER_SECOND
	for k: int in range(1, turn + 1):
		var turned: float = minf(turn_speed * step * k, PI / 2.0)
		var look: Vector3 = track.moments[run_up - 1 + k].look
		var off: float = rad_to_deg(absf(look.angle_to(Vector3.RIGHT) - (PI / 2.0 - turned)))
		assert_lt(off, ANGLE_TOLERANCE, "step %d of the turn: turned at the tuned pace" % k)
	var last: Moment = track.moments[-1]
	assert_lt(rad_to_deg(last.look.angle_to(Vector3.RIGHT)), ANGLE_TOLERANCE, "then looks right")


func test_in_the_air_the_runner_looks_where_it_pushes_not_where_it_flies() -> void:
	var track: Track = _track(0)
	var steps: int = 20
	var flight: Vector3 = FORWARD * track.runner.tuning.top_speed
	var high: Vector3 = Vector3.UP * TALL
	track.start(high, ScriptedIntentSource.new().hold(Vector3.RIGHT, false, steps), flight)

	await _steps(steps)

	var after_the_turn: Array[Moment] = track.moments.slice(_turn_steps(90.0), steps)
	assert_gt(after_the_turn.size(), 0, "the turn is over within the flight")
	for moment: Moment in after_the_turn:
		var aside: float = rad_to_deg(moment.motion.angle_to(Vector3.RIGHT))
		assert_gt(aside, 30.0, "the runner flies aside from its push")
		assert_false(moment.on_floor, "in the air")
	var widest: float = _widest_angle(after_the_turn, Vector3.RIGHT, false)
	assert_lt(widest, ANGLE_TOLERANCE, "it looked where it pushed")


# --- States that keep their own look ---


func test_in_a_slide_the_runner_looks_where_it_slides() -> void:
	var track: Track = _track(0)
	track.add_floor(FACE * 4.0)
	var run_up: int = 40
	var slide: int = 30
	var intents: ScriptedIntentSource = ScriptedIntentSource.new()
	track.start(Vector3.ZERO, intents.hold(FORWARD, false, run_up).slide(Vector3.RIGHT, slide))

	await _steps(run_up + slide)

	var sliding: Array[Moment] = track.moments_in(SLIDING)
	assert_eq(sliding.size(), slide, "the runner slid all along")
	var last: Moment = sliding[-1]
	var aside: float = rad_to_deg(last.motion.angle_to(last.push))
	assert_gt(aside, 30.0, "pushing aside from where it slid")
	for moment: Moment in sliding:
		var off: float = rad_to_deg(moment.look.angle_to(moment.motion))
		assert_lt(off, ANGLE_TOLERANCE, "it looked where it slid")


func test_in_a_wall_run_the_runner_looks_along_the_wall() -> void:
	# The wall at the left, along -Z; the runner flies along it, or comes at it slightly,
	# pushing ahead and towards the wall, as the keyboard diagonal does.
	var approaches: Array[float] = [0.0, 20.0]
	var diagonal: Vector3 = (FORWARD + Vector3.LEFT).normalized()
	var steps: int = 40
	var tracks: Array[Track] = []
	for approach: float in approaches:
		var track: Track = _track(tracks.size())
		var tuning: MovementTuning = track.runner.tuning
		var start: Vector3 = Vector3.UP * 2.0
		var middle: Vector3 = start + Vector3.UP * tuning.capsule_height / 2.0
		var face: float = -(tuning.capsule_radius + tuning.wall_run_distance / 2.0)
		var length: float = 30.0
		track.add_block(
			Vector3(1.0, TALL, length), Vector3(face - 0.5, middle.y, middle.z - length / 2.0)
		)
		var flight: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(approach))
		var intents: ScriptedIntentSource = ScriptedIntentSource.new().hold(diagonal, false, steps)
		track.start(start, intents, flight * tuning.top_speed)
		tracks.append(track)

	await _steps(steps)

	for index: int in tracks.size():
		var context: String = "approach %.0f degrees" % approaches[index]
		var wall_running: Array[Moment] = tracks[index].moments_in(WALL_RUNNING)
		assert_gt(wall_running.size(), _turn_steps(45.0), context + ": a wall run")
		var settled: Array[Moment] = wall_running.slice(_turn_steps(45.0))
		var widest: float = _widest_angle(settled, FORWARD, false)
		assert_lt(widest, ANGLE_TOLERANCE, context + ": it looked along the wall, ahead")


func test_jumping_at_a_ledge_pushing_straight_keeps_the_runner_facing_it_to_the_top() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	# A ledge within a mantle from the floor, and one the jump must rise to first: the
	# runner meets its face too low, the face takes its speed, and only then it climbs.
	var heights: Array[float] = [_ledge_height(tuning), _high_ledge_height(tuning)]
	var tracks: Array[Track] = []
	for height: float in heights:
		for offset: float in CAMERA_OFFSETS:
			var track: Track = _track(tracks.size())
			track.add_floor(FACE * 2.0)
			track.add_block_ahead(height, FACE)
			var push: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(offset))
			var intents: ScriptedIntentSource = ScriptedIntentSource.new()
			intents.hold(push, false, APPROACH_STEPS).hold(push, true, JUMP_STEPS)
			track.start(track.near_the_face(), intents)
			tracks.append(track)

	await _steps(APPROACH_STEPS + JUMP_STEPS)

	for index: int in tracks.size():
		var offset: float = CAMERA_OFFSETS[index % CAMERA_OFFSETS.size()]
		var height: float = heights[index / CAMERA_OFFSETS.size()]
		var context: String = "ledge %.1f m, camera %+.0f degrees" % [height, offset]
		var track: Track = tracks[index]
		var mantling: Array[Moment] = track.moments_in(MANTLING)
		assert_gt(mantling.size(), 0, context + ": the runner mantled")
		if mantling.is_empty():
			continue
		var last: int = track.moments.rfind(mantling[-1])
		var climb: Array[Moment] = track.moments.slice(APPROACH_STEPS, last + 1)
		var widest: float = _widest_angle(climb, FORWARD, false)
		var limit: float = absf(offset) + ANGLE_TOLERANCE
		assert_lt(widest, limit, context + ": from the jump to the top, it looked at the ledge")


func test_in_a_mantle_the_runner_does_not_turn() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	# Aslant, halfway inside what still counts as towards the face (the split is measured
	# from the surface, as the motor does), slow enough along the face for no wall run.
	var aslant: float = (90.0 - tuning.push_split_angle) / 2.0
	var push: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(-aslant))
	var track: Track = _track(0)
	track.add_floor(FACE * 2.0)
	track.add_block_ahead(_ledge_height(tuning), FACE)
	var intents: ScriptedIntentSource = ScriptedIntentSource.new()
	intents.hold(push, false, APPROACH_STEPS).hold(push, true, JUMP_STEPS)
	# Once the mantle has started, the runner pushes elsewhere: neither where it climbs
	# nor where it looked.
	var elsewhere: Vector3 = Vector3.LEFT
	var turning: PushElsewhereInTheMantle = PushElsewhereInTheMantle.new(
		track.runner, intents, elsewhere
	)
	track.start(track.near_the_face(), intents)
	track.runner.intent_source = turning

	await _steps(APPROACH_STEPS + JUMP_STEPS)

	var mantling: Array[Moment] = track.moments_in(MANTLING)
	assert_gt(mantling.size(), 1, "the runner mantled")
	if mantling.size() < 2:
		return
	var first: int = track.moments.find(mantling[0])
	var at_the_start: Vector3 = track.moments[first - 1].look
	var started: float = rad_to_deg(at_the_start.angle_to(push))
	assert_lt(started, ANGLE_TOLERANCE, "the mantle started looking at the push")
	var pushed_elsewhere: Array[Moment] = mantling.slice(1).filter(
		func(moment: Moment) -> bool: return moment.push.is_equal_approx(elsewhere)
	)
	assert_eq(pushed_elsewhere.size(), mantling.size() - 1, "then pushed elsewhere")
	var widest: float = _widest_angle(mantling, at_the_start, false)
	assert_lt(widest, ANGLE_TOLERANCE, "it kept that look all along the mantle")


# --- Upright ---


func test_out_of_a_wall_run_the_runner_stays_upright() -> void:
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	# Against a wall too tall, and onto a ledge too shallow to stay on: the runner climbs
	# it, slides over its top and falls on the floor beyond.
	var wall: Track = _track(0)
	wall.add_floor(FACE * 2.0)
	wall.add_block_ahead(TALL, FACE)
	var push: Vector3 = FORWARD.rotated(Vector3.UP, deg_to_rad(CAMERA_OFFSETS[-1]))
	var against: ScriptedIntentSource = ScriptedIntentSource.new()
	wall.start(wall.near_the_face(), against.hold(push, false, 20).hold(push, true, JUMP_STEPS))
	var ledge: Track = _track(1)
	ledge.add_floor(FACE * 4.0)
	ledge.add_block_ahead(_ledge_height(tuning), 4.0)
	var over: ScriptedIntentSource = ScriptedIntentSource.new()
	over.hold(FORWARD, false, 20).hold(FORWARD, true, 30).hold(FORWARD, false, 15)
	over.slide(FORWARD, 45).hold(FORWARD, false, 20)
	ledge.start(ledge.near_the_face(), over)
	var steps: int = maxi(against.length(), over.length())

	await _steps(steps)

	var jumped: Array[Moment] = wall.moments.filter(
		func(moment: Moment) -> bool: return moment.on_wall and not moment.on_floor
	)
	assert_gt(jumped.size(), 0, "a runner jumped against the wall")
	var mantling: Array[Moment] = ledge.moments_in(MANTLING)
	assert_gt(mantling.size(), 0, "a runner climbed the ledge")
	var climbed: int = ledge.moments.find(mantling[-1]) if not mantling.is_empty() else 0
	var after: Array[Moment] = ledge.moments.slice(climbed)
	var slid: bool = after.any(func(moment: Moment) -> bool: return moment.state == SLIDING)
	var fell: bool = after.any(
		func(moment: Moment) -> bool: return moment.state == RunnerMotor.State.FALLING
	)
	assert_true(slid, "slid on top of it")
	assert_true(fell, "and fell from it")
	assert_lt(ledge.runner.global_position.y, 0.1, "down to the floor beyond")
	for track: Track in [wall, ledge]:
		assert_eq(track.moments_in(WALL_RUNNING).size(), 0, "with no wall run")
		var tilted: float = 0.0
		for moment: Moment in track.moments:
			tilted = maxf(tilted, rad_to_deg(moment.up.angle_to(Vector3.UP)))
		assert_lt(tilted, 0.01, "upright at every step, with no roll and no pitch")


# --- Tricks ---


func test_the_visible_body_makes_the_turn_of_the_trick() -> void:
	var turn_steps: int = roundi((load(TUNING) as MovementTuning).trick_turn_duration * 60.0)
	var track: Track = _track(0)
	var flight: Vector3 = FORWARD * track.runner.tuning.top_speed
	# A backflip of one turn, released early; the push goes elsewhere during it.
	var intents: ScriptedIntentSource = ScriptedIntentSource.new()
	intents.trick(Vector3.BACK, 5).hold(Vector3.RIGHT, false, turn_steps + 5)
	track.start(Vector3.UP * TALL * 3.0, intents, flight)

	await _steps(intents.length())

	var trick: AirTrick = track.runner.motor.current_trick()
	assert_not_null(trick, "a runner that launched a backflip")
	if trick == null:
		return
	assert_eq(trick.flip, AirTrick.Flip.BACKFLIP)
	assert_true(trick.finished, "over in the air")
	var axis: Vector3 = trick.axis
	assert_almost_eq(axis, Vector3.RIGHT, Vector3.ONE * 0.001, "around the axis across the flight")
	# From the first step, where it started, to the step its turn is over.
	var turned: float = 0.0
	var upside_down: bool = false
	for k: int in range(1, turn_steps + 1):
		var before: Moment = track.moments[k - 1]
		var now: Moment = track.moments[k]
		turned += before.up.signed_angle_to(now.up, axis)
		upside_down = upside_down or now.up.dot(Vector3.UP) < -0.99
		if k < turn_steps:
			var aside: float = absf(now.front.dot(axis))
			assert_lt(aside, 0.01, "step %d: not turned towards the push" % k)
	assert_almost_eq(rad_to_deg(turned), 360.0, ANGLE_TOLERANCE, "a whole turn, head backwards")
	assert_true(upside_down, "through upside down")
	var last: Moment = track.moments[turn_steps]
	assert_lt(rad_to_deg(last.up.angle_to(Vector3.UP)), 0.01, "upright as the turn ends")
	for moment: Moment in track.moments.slice(turn_steps):
		assert_lt(rad_to_deg(moment.up.angle_to(Vector3.UP)), 0.01, "and upright after it")


## Above any jump, within a mantle.
func _ledge_height(tuning: MovementTuning) -> float:
	return (tuning.jump_height + tuning.mantle_max_height) / 2.0


## Out of a mantle from the floor, within one once the jump has risen halfway.
func _high_ledge_height(tuning: MovementTuning) -> float:
	return tuning.mantle_max_height + tuning.jump_height / 2.0


## The steps the visible body takes to turn by `degrees`, at the tuned pace.
func _turn_steps(degrees: float) -> int:
	var turn_speed: float = (load(TUNING) as MovementTuning).turn_speed
	return ceili(deg_to_rad(degrees) / (turn_speed / STEPS_PER_SECOND))


## The widest angle, in degrees, between where the visor looked and `towards` over
## `moments`; only at the steps of a contact with a wall if `on_wall_only`.
func _widest_angle(moments: Array[Moment], towards: Vector3, on_wall_only: bool) -> float:
	var widest: float = 0.0
	for moment: Moment in moments:
		if on_wall_only and not moment.on_wall:
			continue
		widest = maxf(widest, rad_to_deg(moment.look.angle_to(towards)))
	return widest


func _track(place: int) -> Track:
	var track: Track = Track.new()
	track.position.x = place * ASIDE
	add_child_autofree(track)
	return track


## Waits until at least `count` steps have gone by.
func _steps(count: int) -> void:
	for i: int in count + 1:
		await get_tree().physics_frame
