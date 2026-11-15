extends ReplayTest
## The arena of the chase (docs/specs/chase-arena.md) in the real physics, without a
## screen: its floor and its enclosure, its loops run round and cut short by the pilot, its
## half-turn symmetry, the measures and the colour of each kind of obstacle, its low walls
## vaulted both ways at the new tempo and its tunnels passed by a slide. Much faster than
## real time with the same fixed step of 1/60 s, many steps to a frame (see before_all).
## The balance of the cat and the mouse is in test_course_chase_bot.gd, with the rounds
## between bots it reads.

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const GRID_SHADER: String = "res://game/world/grid.gdshader"
const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## How many times faster than real time the fixed steps run here, and how many of them
## may run in one frame: nothing but the physics runs, and the same steps play sooner.
const FAST: int = 400
const STEPS_PER_FRAME: int = 64
## The precision of a size read from the physics, in m.
const PRECISION: float = 0.001
## The free floor, in m, and the grid of the measures of the obstacles.
const ARENA_SIZE: float = 32.0
const GRID: float = 0.5
## The measures of each kind of obstacle, in m.
const LOW_WALL_HEIGHT: float = 1.0
const LOW_WALL_THICKNESS: float = 0.3
const BLOCK_HEIGHT: float = 1.8
const WALL_HEIGHT: float = 3.5
const WALL_SHORTEST: float = 6.0
const TUNNEL_ROOM: float = 1.2
const TUNNEL_SHORTEST: float = 2.0
const TUNNEL_LONGEST: float = 3.0
## The kinds of obstacle: the groups of the arena.
const KINDS: Array[String] = [
	"Ground", "Enclosure", "LowWalls", "Blocks", "Walls", "Tunnels", "Platforms"
]
## The loops: how many at least, how long a lap is, in m; how near a corner the pilot has
## reached it, in m; the least speed of a lap run without stopping, as a share of the top
## speed; how near its lap a flee point stands, in m.
const LOOPS_LEAST: int = 3
const LAP_SHORTEST: float = 12.0
const LAP_LONGEST: float = 30.0
const CORNER_REACH: float = 1.0
const LAP_SLOWEST: float = 0.5
const ON_THE_LAP: float = 0.3
const FLEE_POINTS_LEAST: int = 2
## Steps a lap, a shortcut, a run at a low wall or at a tunnel lasts at most.
const LAP_STEPS: int = 900
const SHORTCUT_STEPS: int = 600
const RUN_STEPS: int = 240
## How far from the end of a shortcut, along it and aside, the pilot is there, in m; and
## how near its altitude.
const AT_THE_END: float = 1.0
const ALTITUDE: float = 0.3
## How far before a tunnel or a low wall the pilot starts, in m: room enough to reach its
## top speed, at tier 3 of the flow for a low wall, before it is within reach.
const RUN_UP: float = 3.0
const VAULT_RUN_UP: float = 4.0
## The share of its top speed a runner has at least as it vaults.
const AT_TOP_SPEED: float = 0.99
## How far a runner must be past an obstacle to be on the other side, in m.
const PAST: float = 1.0
## The run-up free in front of each start point, in m.
const START_RUN_UP: float = 3.0
## How far apart two colours are at least, in RGB.
const DISTINCT: float = 0.3

var _steps_per_frame_before: int


## What a runner went through on a run: whether it arrived, and the states of its motor.
class Run:
	var arrived: bool = false
	var states: Dictionary[RunnerMotor.State, bool] = {}


## A runner led by the pilot round a lap: from its first corner to the next, and on.
class LapPilot:
	extends IntentSource

	## The corners of the lap, and how many the runner has passed.
	var corners: Array[Vector3] = []
	var passed: int = 0
	var _runner: Player
	var _pilot: PilotIntentSource

	func _init(runner: Player, lap: Array[Vector3]) -> void:
		_runner = runner
		corners = lap
		_pilot = PilotIntentSource.new(runner, lap[1] - lap[0])

	func next_intent() -> MoveIntent:
		var feet: Vector3 = _runner.global_position
		var corner: Vector3 = _corner()
		if Vector2(corner.x - feet.x, corner.z - feet.z).length() < CORNER_REACH:
			passed += 1
			corner = _corner()
		_pilot.run_towards(corner - feet)
		return _pilot.next_intent()

	func _corner() -> Vector3:
		return corners[(passed + 1) % corners.size()]


func before_all() -> void:
	super.before_all()
	_steps_per_frame_before = Engine.max_physics_steps_per_frame
	Engine.physics_ticks_per_second = STEPS_PER_SECOND * FAST
	Engine.time_scale = FAST
	Engine.max_physics_steps_per_frame = STEPS_PER_FRAME


func after_all() -> void:
	Engine.max_physics_steps_per_frame = _steps_per_frame_before
	super.after_all()


func test_the_arena_is_big_and_enclosed() -> void:
	var chase: Chase = _add_still_chase()
	var tuning: MovementTuning = chase.players[Chase.PLAYER_ONE].tuning
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var inside: AABB = _inside_of(_boxes_of_kind(arena, "Enclosure"))
	assert_almost_eq(inside.size.x, ARENA_SIZE, PRECISION, "32 m wide")
	assert_almost_eq(inside.size.z, ARENA_SIZE, PRECISION, "32 m deep")
	var ground: AABB = _box_of(arena.get_node("Ground") as StaticBody3D)
	assert_almost_eq(ground.end.y, 0.0, PRECISION, "a flat floor")
	var floor_box: AABB = AABB(Vector3(inside.position.x, 0.0, inside.position.z), inside.size)
	floor_box.size.y = 0.0
	assert_true(ground.grow(PRECISION).encloses(floor_box), "under the whole of it")
	for wall: Node in arena.get_node("Enclosure").get_children():
		assert_true(wall.is_in_group(Player.NO_WALL_RUN_GROUP), wall.name + ": no wall run on it")
	# Closed all round, above the highest top a runner may stand on.
	var highest_top: float = 0.0
	for body: StaticBody3D in _bodies(arena):
		if _kind_of(arena, body) != "Enclosure":
			highest_top = maxf(highest_top, _box_of(body).end.y)
	var space: PhysicsDirectSpaceState3D = chase.get_world_3d().direct_space_state
	var centre: Vector3 = (arena.get_node("Centre") as Node3D).global_position
	var over: Vector3 = centre + Vector3.UP * (highest_top + 0.5)
	var reach: float = inside.size.length()
	for turn: int in 36:
		var way: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, TAU * turn / 36.0)
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			over, over + way * reach
		)
		var hit: Dictionary = space.intersect_ray(ray)
		var wall: Object = hit.get("collider")
		var enclosure: bool = wall is Node and (wall as Node).get_parent().name == "Enclosure"
		assert_true(enclosure, "closed all round")
	for box: AABB in _boxes_of_kind(arena, "Enclosure"):
		var out_of_reach: float = highest_top + tuning.jump_height + tuning.mantle_max_height
		assert_gt(box.end.y, out_of_reach, "the enclosure is out of reach")


func test_the_arena_has_its_loops_and_their_shortcuts() -> void:
	var chase: Chase = _add_still_chase()
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var loops: Array[Node] = arena.get_node("Loops").get_children()
	assert_gte(loops.size(), LOOPS_LEAST, "at least three loops")
	var flee_points: Array[Vector3] = []
	for point: Node in arena.get_node("FleePoints").get_children():
		flee_points.append((point as Node3D).global_position)
	for loop: Node in loops:
		var lap: Array[Vector3] = _corners_of(loop)
		var length: float = _perimeter(lap)
		var name: String = loop.name
		assert_between(length, LAP_SHORTEST, LAP_LONGEST, name + ": a lap of 12 to 30 m")
		var obstacle: StaticBody3D = _obstacle_inside(arena, lap)
		assert_not_null(obstacle, name + ": round an obstacle")
		if obstacle == null:
			continue
		var middle: Vector3 = _box_of(obstacle).get_center()
		_assert_flee_points_on_either_side(flee_points, lap, middle, name)

		# Round the lap, running.
		var runner: Player = _add_runner(chase, lap[0], lap[1] - lap[0])
		var pilot: LapPilot = LapPilot.new(runner, lap)
		runner.intent_source = pilot
		var slowest: float = INF
		var moves: Dictionary[RunnerMotor.State, bool] = {}
		for step: int in LAP_STEPS:
			await get_tree().physics_frame
			if pilot.passed > lap.size():
				break
			if pilot.passed >= 1:
				slowest = minf(slowest, Vector2(runner.velocity.x, runner.velocity.z).length())
				moves[runner.motor.state] = true
		runner.queue_free()
		assert_gt(pilot.passed, lap.size(), name + ": the pilot goes all round")
		var top_speed: float = runner.tuning.top_speed
		assert_gte(slowest, top_speed * LAP_SLOWEST, name + ": without stopping")
		assert_eq(moves.keys(), [RunnerMotor.State.GROUNDED], name + ": running all along")

		# Then cut short through the obstacle.
		var shortcut: Node = loop.get_node("Shortcut")
		var from: Vector3 = (shortcut.get_node("From") as Node3D).global_position
		var to: Vector3 = (shortcut.get_node("To") as Node3D).global_position
		var round_the_lap: float = _along_the_lap(lap, from, to)
		assert_lt(from.distance_to(to), round_the_lap, name + ": shorter than round the lap")
		var run: Run = await _run_straight(chase, from, to)
		assert_true(run.arrived, name + ": the shortcut is run through")
		var move: bool = run.states.has(RunnerMotor.State.VAULTING)
		move = move or run.states.has(RunnerMotor.State.SLIDING)
		move = move or run.states.has(RunnerMotor.State.MANTLING)
		assert_true(move, name + ": by a vault, a slide or a mantle")


func test_the_arena_is_the_same_on_both_sides() -> void:
	var chase: Chase = _add_still_chase()
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var centre: Vector3 = (arena.get_node("Centre") as Node3D).global_position
	var bodies: Array[StaticBody3D] = _bodies(arena)
	for body: StaticBody3D in bodies:
		var kind: String = _kind_of(arena, body)
		var turned: AABB = _turned(_box_of(body), centre)
		var found: bool = false
		for other: StaticBody3D in bodies:
			if _kind_of(arena, other) != kind:
				continue
			var box: AABB = _box_of(other)
			var same: bool = box.position.is_equal_approx(turned.position)
			if same and box.size.is_equal_approx(turned.size):
				found = true
		assert_true(found, "%s: an obstacle of its kind on the other side" % body.name)
	# The start points: each on the other one, facing the same way turned.
	for player: int in ChaseState.PLAYERS:
		var start: Transform3D = chase.spawns[player]
		var other: Transform3D = chase.spawns[1 - player]
		var origin: Vector3 = start.origin - centre
		var turned_origin: Vector3 = centre + Vector3(-origin.x, origin.y, -origin.z)
		assert_almost_eq(turned_origin.distance_to(other.origin), 0.0, PRECISION, "on the other")
		var facing: Vector3 = -start.basis.z.rotated(Vector3.UP, PI)
		assert_almost_eq(facing.dot(-other.basis.z), 1.0, PRECISION, "facing as the other")
		# Free in front of it for a run-up.
		var space: PhysicsDirectSpaceState3D = chase.get_world_3d().direct_space_state
		var tuning: MovementTuning = chase.players[player].tuning
		var ahead: float = START_RUN_UP + tuning.capsule_radius
		for height: float in [0.3, tuning.capsule_height / 2.0, tuning.capsule_height - 0.1]:
			var from: Vector3 = start.origin + Vector3.UP * height
			var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				from, from - start.basis.z * ahead
			)
			assert_true(space.intersect_ray(ray).is_empty(), "3 m free in front of a start")


func test_each_obstacle_has_the_measures_of_its_kind() -> void:
	var chase: Chase = _add_still_chase()
	var tuning: MovementTuning = chase.players[Chase.PLAYER_ONE].tuning
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var ground_top: float = _box_of(arena.get_node("Ground") as StaticBody3D).end.y
	for kind: String in KINDS:
		assert_false(_boxes_of_kind(arena, kind).is_empty(), "the arena has its " + kind)
	for box: AABB in _boxes_of_kind(arena, "LowWalls"):
		assert_almost_eq(box.size.y, LOW_WALL_HEIGHT, PRECISION, "a low wall of 1 m")
		var thickness: float = minf(box.size.x, box.size.z)
		assert_almost_eq(thickness, LOW_WALL_THICKNESS, PRECISION, "0.3 m thick")
	for box: AABB in _boxes_of_kind(arena, "Blocks"):
		assert_almost_eq(box.size.y, BLOCK_HEIGHT, PRECISION, "a block of 1.8 m")
	for wall: Node in arena.get_node("Walls").get_children():
		var box: AABB = _box_of(wall as StaticBody3D)
		assert_almost_eq(box.size.y, WALL_HEIGHT, PRECISION, wall.name + ": a wall of 3.5 m")
		assert_gte(maxf(box.size.x, box.size.z), WALL_SHORTEST, wall.name + ": 6 m long at least")
		assert_false(wall.is_in_group(Player.NO_WALL_RUN_GROUP), wall.name + ": to run along")
	for tunnel: Node in arena.get_node("Tunnels").get_children():
		_assert_a_tunnel(tunnel, ground_top, tuning)
	var blocks: Array[AABB] = _boxes_of_kind(arena, "Blocks")
	var from_the_floor: float = tuning.jump_height + tuning.mantle_max_height
	for box: AABB in _boxes_of_kind(arena, "Platforms"):
		assert_gt(box.size.y, from_the_floor, "above a jump and a mantle from the floor")
		assert_true(_has_a_ledge_to(box, blocks, tuning), "reached by a ledge block")
	# On the grid, each a single block, standing on the floor (a roof on its sides).
	for body: StaticBody3D in _bodies(arena):
		var shapes: Array[Node] = body.find_children("*", "CollisionShape3D", false, false)
		assert_eq(shapes.size(), 1, body.name + ": a single block")
		var box: AABB = _box_of(body)
		var mesh: MeshInstance3D = body.get_node("MeshInstance3D") as MeshInstance3D
		var seen: AABB = mesh.global_transform * mesh.get_aabb()
		assert_true(seen.is_equal_approx(box), body.name + ": seen as it is")
		var kind: String = _kind_of(arena, body)
		if kind == "Ground":
			continue
		for axis: int in [Vector3.AXIS_X, Vector3.AXIS_Z]:
			var low: float = box.position[axis]
			var high: float = box.end[axis]
			if kind == "LowWalls" and is_equal_approx(box.size[axis], LOW_WALL_THICKNESS):
				assert_true(
					_on_the_grid((low + high) / 2.0), body.name + ": its middle on the grid"
				)
			else:
				assert_true(_on_the_grid(low) and _on_the_grid(high), body.name + ": on the grid")
		if body.name != "Roof":
			assert_almost_eq(box.position.y, ground_top, PRECISION, body.name + ": on the floor")


func test_each_low_wall_is_vaulted_both_ways_at_the_new_tempo() -> void:
	var chase: Chase = _add_still_chase()
	var tuning: MovementTuning = chase.players[Chase.PLAYER_ONE].tuning
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var tier_3: float = bonuses[tuning.flow_tier_count - 1]
	var arena: Node3D = chase.get_node("Arena") as Node3D
	for wall: Node in arena.get_node("LowWalls").get_children():
		var box: AABB = _box_of(wall as StaticBody3D)
		var across: Vector3 = Vector3.FORWARD if box.size.z < box.size.x else Vector3.RIGHT
		var half: float = box.size.dot(across) / 2.0
		var middle: Vector3 = Vector3(box.get_center().x, 0.0, box.get_center().z)
		for bonus: float in [0.0, tier_3]:
			for way: Vector3 in [across, -across]:
				var start: Vector3 = middle - way * (half + VAULT_RUN_UP)
				var context: String = (
					"%s, at %.2f m/s, going %s: "
					% [wall.name, tuning.top_speed * (1.0 + bonus), way]
				)
				var seen: Array[float] = await _vault_at(chase, start, way, bonus, half)
				assert_gt(seen[0], 0.0, context + "the pilot vaults it")
				assert_eq(seen[1], 0.0, context + "without a jump")
				assert_eq(seen[2], 1.0, context + "at its top speed")
				assert_gte(seen[3], half + PAST, context + "and stands behind it")


func test_the_tunnels_are_passed_by_sliding() -> void:
	var chase: Chase = _add_still_chase()
	var arena: Node3D = chase.get_node("Arena") as Node3D
	for tunnel: Node in arena.get_node("Tunnels").get_children():
		var roof: AABB = _box_of(tunnel.get_node("Roof") as StaticBody3D)
		var axis: Vector3 = _axis_of(tunnel)
		var half: float = roof.size.dot(axis) / 2.0
		var middle: Vector3 = Vector3(roof.get_center().x, 0.0, roof.get_center().z)
		for way: Vector3 in [axis, -axis]:
			var start: Vector3 = middle - way * (half + RUN_UP)
			var context: String = "%s, going %s: " % [tunnel.name, way]
			var slid: Array[float] = await _run_through(chase, start, way, true, half)
			assert_eq(slid[0], 1.0, context + "the pilot slides")
			assert_gte(slid[1], half + PAST, context + "and gets through")
			# The slide carries it all through, never slower than a slide goes.
			var slide_stop: float = chase.players[Chase.PLAYER_ONE].tuning.slide_stop_speed
			assert_gte(slid[2], slide_stop - PRECISION, context + "without stopping")
			assert_eq(slid[3], 0.0, context + "sliding all through")
			# On its feet, the pilot neither slides nor climbs onto the roof: it runs into it.
			var standing: Array[float] = await _run_through(chase, start, way, false, half)
			assert_lt(standing[1], -half, context + "a runner on its feet does not pass")


func test_each_kind_of_obstacle_has_its_colour() -> void:
	var chase: Chase = _add_still_chase()
	var tuning: MovementTuning = chase.players[Chase.PLAYER_ONE].tuning
	var arena: Node3D = chase.get_node("Arena") as Node3D
	var colours: Dictionary[String, Color] = {}
	for body: StaticBody3D in _bodies(arena):
		var kind: String = _kind_of(arena, body)
		var mesh: MeshInstance3D = body.get_node("MeshInstance3D") as MeshInstance3D
		var material: ShaderMaterial = (mesh.mesh as PrimitiveMesh).material as ShaderMaterial
		assert_not_null(material, body.name + ": a material of its own")
		if material == null:
			continue
		assert_eq(material.shader.resource_path, GRID_SHADER, body.name + ": the grid")
		var colour: Color = material.get_shader_parameter("colour")
		if not colours.has(kind):
			colours[kind] = colour
		assert_eq(colour, colours[kind], body.name + ": the colour of its kind")
	assert_eq(colours.size(), KINDS.size(), "a colour for each kind")
	var kinds: Array[String] = colours.keys()
	for index: int in kinds.size():
		var colour: Color = colours[kinds[index]]
		for other: int in range(index + 1, kinds.size()):
			var apart: float = _apart(colour, colours[kinds[other]])
			assert_gt(apart, DISTINCT, "%s and %s apart" % [kinds[index], kinds[other]])
		var from_the_cat: float = _apart(colour, tuning.chase_cat_colour)
		assert_gt(from_the_cat, DISTINCT, kinds[index] + ": not the red of the cat")
		var from_the_mouse: float = _apart(colour, tuning.chase_mouse_colour)
		assert_gt(from_the_mouse, DISTINCT, kinds[index] + ": not the blue of the mouse")


## A chase whose match does not run: its runners held at their start points.
func _add_still_chase() -> Chase:
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	add_child_autofree(chase)
	chase.set_physics_process(false)
	return chase


## A runner of its own in the arena of `chase`, at `start`, facing `way`.
func _add_runner(chase: Chase, start: Vector3, way: Vector3) -> Player:
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	chase.add_child(runner)
	var flat: Vector3 = Vector3(way.x, 0.0, way.z).normalized()
	runner.teleport(Transform3D(Basis.looking_at(flat), start))
	return runner


## The pilot runs from `from` straight on to `to`: whether it got there (on the floor at
## its altitude, as far along, near the line), and the motor states it went through.
func _run_straight(chase: Chase, from: Vector3, to: Vector3) -> Run:
	var way: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	var length: float = way.length()
	way = way.normalized()
	var runner: Player = _add_runner(chase, from, way)
	await get_tree().physics_frame
	runner.intent_source = PilotIntentSource.new(runner, way)
	var run: Run = Run.new()
	for step: int in SHORTCUT_STEPS:
		await get_tree().physics_frame
		run.states[runner.motor.state] = true
		var feet: Vector3 = runner.global_position
		var along: float = (feet - from).dot(way)
		var off: Vector3 = feet - from - way * along
		var near: bool = Vector2(off.x, off.z).length() < AT_THE_END
		var down: bool = absf(feet.y - to.y) < ALTITUDE and runner.is_on_floor()
		if down and near and along >= length - AT_THE_END:
			run.arrived = true
			break
	runner.queue_free()
	return run


## A runner of its own, its top speed raised by `bonus`, led by the pilot from `start` the
## way `way`: the steps it vaulted, the jumps it made, 1 if it went at its top speed as it
## started its first vault (0 otherwise), and how far past the middle of the wall it
## started VAULT_RUN_UP before, `half` thick, it stands at the end, on the floor (-INF if
## not on the floor).
func _vault_at(
	chase: Chase, start: Vector3, way: Vector3, bonus: float, half: float
) -> Array[float]:
	var runner: Player = _add_runner(chase, start, way)
	runner.motor.top_speed_bonus = bonus
	await get_tree().physics_frame
	runner.intent_source = PilotIntentSource.new(runner, way)
	var seen: Array[float] = [0.0, 0.0, 0.0, -INF]
	var speed: float = 0.0
	for step: int in RUN_STEPS:
		await get_tree().physics_frame
		var vaulting: bool = runner.motor.state == RunnerMotor.State.VAULTING
		if vaulting and seen[0] == 0.0:
			seen[2] = float(speed >= runner.motor.top_speed() * AT_TOP_SPEED)
		seen[0] += float(vaulting)
		for event: RunnerEvent in runner.motor.events:
			seen[1] += float(event.kind == RunnerEvent.Kind.JUMP)
		speed = Vector2(runner.velocity.x, runner.velocity.z).length()
	if runner.is_on_floor() and absf(runner.global_position.y - start.y) < ALTITUDE:
		seen[3] = (runner.global_position - start).dot(way) - VAULT_RUN_UP - half
	runner.queue_free()
	return seen


## A runner of its own led by the pilot (sliding, or neither sliding nor climbing, as
## `slides` says) from `start` the way `way` at a tunnel `half` long: 1 if it slid (0
## otherwise), how far past the middle of the tunnel it got, its least speed under the
## roof (INF if it never got there), and 1 if it was ever out of a slide there (0
## otherwise).
func _run_through(
	chase: Chase, start: Vector3, way: Vector3, slides: bool, half: float
) -> Array[float]:
	var runner: Player = _add_runner(chase, start, way)
	await get_tree().physics_frame
	var pilot: PilotIntentSource = PilotIntentSource.new(runner, way, slides)
	pilot.climbs = slides
	runner.intent_source = pilot
	var seen: Array[float] = [0.0, -INF, INF, 0.0]
	for step: int in RUN_STEPS:
		await get_tree().physics_frame
		var sliding: bool = runner.motor.state == RunnerMotor.State.SLIDING
		seen[0] = maxf(seen[0], float(sliding))
		var along: float = (runner.global_position - start).dot(way) - half - RUN_UP
		seen[1] = maxf(seen[1], along)
		if absf(along) < half:
			seen[2] = minf(seen[2], Vector2(runner.velocity.x, runner.velocity.z).length())
			seen[3] = maxf(seen[3], float(not sliding))
	runner.queue_free()
	return seen


## The way along a tunnel: along its sides.
func _axis_of(tunnel: Node) -> Vector3:
	for side: Node in tunnel.get_children():
		if side.name != "Roof":
			var box: AABB = _box_of(side as StaticBody3D)
			return Vector3.RIGHT if box.size.x > box.size.z else Vector3.BACK
	return Vector3.RIGHT


## A tunnel: two sides and a roof over them, the room under the roof a slide and not a
## runner on its feet, 2 to 3 m long, wide enough for a runner.
func _assert_a_tunnel(tunnel: Node, ground_top: float, tuning: MovementTuning) -> void:
	var name: String = tunnel.name
	assert_eq(tunnel.get_child_count(), 3, name + ": two sides and a roof")
	if not tunnel.has_node("Roof"):
		fail_test(name + ": a roof")
		return
	var roof: AABB = _box_of(tunnel.get_node("Roof") as StaticBody3D)
	var room: float = roof.position.y - ground_top
	assert_almost_eq(room, TUNNEL_ROOM, PRECISION, name + ": the roof at 1.2 m")
	assert_gt(room, tuning.slide_capsule_height, name + ": room for a slide")
	assert_lt(room, tuning.capsule_height, name + ": none for a runner on its feet")
	var axis: Vector3 = _axis_of(tunnel)
	var length: float = roof.size.dot(axis)
	assert_between(length, TUNNEL_SHORTEST, TUNNEL_LONGEST, name + ": 2 to 3 m long")
	var sides: Array[AABB] = []
	for side: Node in tunnel.get_children():
		if side.name != "Roof":
			sides.append(_box_of(side as StaticBody3D))
	for side: AABB in sides:
		assert_almost_eq(side.end.y, roof.position.y, PRECISION, name + ": its sides to its roof")
		assert_almost_eq(side.size.dot(axis), length, PRECISION, name + ": as long as its roof")
		assert_true(roof.grow(PRECISION).intersects(side), name + ": the roof on its sides")
	if sides.size() == 2:
		var across: Vector3 = Vector3.ONE - axis - Vector3.UP
		var inner: float = absf((sides[1].get_center() - sides[0].get_center()).dot(across))
		inner -= (sides[0].size.dot(across) + sides[1].size.dot(across)) / 2.0
		assert_gt(inner, 2.0 * tuning.capsule_radius, name + ": wide enough for a runner")


## At least two flee points on the lap `lap`, on either side of its obstacle at `middle`.
func _assert_flee_points_on_either_side(
	flee_points: Array[Vector3], lap: Array[Vector3], middle: Vector3, name: String
) -> void:
	var on_it: Array[Vector3] = []
	for point: Vector3 in flee_points:
		if _off_the_lap(lap, point) < ON_THE_LAP:
			on_it.append(point)
	assert_gte(on_it.size(), FLEE_POINTS_LEAST, name + ": flee points on the lap")
	var either_side: bool = false
	for point: Vector3 in on_it:
		for other: Vector3 in on_it:
			var one: Vector3 = point - middle
			var two: Vector3 = other - middle
			either_side = either_side or Vector2(one.x, one.z).dot(Vector2(two.x, two.z)) < 0.0
	assert_true(either_side, name + ": on either side of its obstacle")


## The corners of the lap of `loop`, in order.
func _corners_of(loop: Node) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for corner: Node in loop.get_node("Lap").get_children():
		corners.append((corner as Node3D).global_position)
	return corners


func _perimeter(lap: Array[Vector3]) -> float:
	var length: float = 0.0
	for index: int in lap.size():
		length += lap[index].distance_to(lap[(index + 1) % lap.size()])
	return length


## How far along the lap a point is from its first corner, at the point of the lap
## nearest to it, in m.
func _position_on_the_lap(lap: Array[Vector3], point: Vector3) -> float:
	var nearest: float = INF
	var position: float = 0.0
	var run: float = 0.0
	for index: int in lap.size():
		var a: Vector3 = lap[index]
		var b: Vector3 = lap[(index + 1) % lap.size()]
		var on_it: Vector3 = Geometry3D.get_closest_point_to_segment(point, a, b)
		if on_it.distance_to(point) < nearest:
			nearest = on_it.distance_to(point)
			position = run + a.distance_to(on_it)
		run += a.distance_to(b)
	return position


func _off_the_lap(lap: Array[Vector3], point: Vector3) -> float:
	var nearest: float = INF
	for index: int in lap.size():
		var a: Vector3 = lap[index]
		var b: Vector3 = lap[(index + 1) % lap.size()]
		nearest = minf(
			nearest, Geometry3D.get_closest_point_to_segment(point, a, b).distance_to(point)
		)
	return nearest


## The shorter way round the lap from `from` to `to`, in m.
func _along_the_lap(lap: Array[Vector3], from: Vector3, to: Vector3) -> float:
	var one_way: float = absf(_position_on_the_lap(lap, to) - _position_on_the_lap(lap, from))
	return minf(one_way, _perimeter(lap) - one_way)


## An obstacle whose middle lies inside the lap, if there is one.
func _obstacle_inside(arena: Node3D, lap: Array[Vector3]) -> StaticBody3D:
	var polygon: PackedVector2Array = PackedVector2Array()
	for corner: Vector3 in lap:
		polygon.append(Vector2(corner.x, corner.z))
	for body: StaticBody3D in _bodies(arena):
		if _kind_of(arena, body) in ["Ground", "Enclosure"]:
			continue
		var middle: Vector3 = _box_of(body).get_center()
		if Geometry2D.is_point_in_polygon(Vector2(middle.x, middle.z), polygon):
			return body
	return null


## The box `box` turned by half a turn round the vertical through `centre`.
func _turned(box: AABB, centre: Vector3) -> AABB:
	var low: Vector3 = Vector3(
		2.0 * centre.x - box.end.x, box.position.y, 2.0 * centre.z - box.end.z
	)
	return AABB(low, box.size)


func _on_the_grid(value: float) -> bool:
	return is_equal_approx(value / GRID, roundf(value / GRID))


func _apart(one: Color, two: Color) -> float:
	return Vector3(one.r - two.r, one.g - two.g, one.b - two.b).length()


## The kind of a body of the arena: the group it is in, or its own name for the ground.
func _kind_of(arena: Node3D, body: Node) -> String:
	return String(arena.get_path_to(body).get_name(0))


## The static bodies of the arena, at every depth.
func _bodies(arena: Node) -> Array[StaticBody3D]:
	var found: Array[StaticBody3D] = []
	for node: Node in arena.find_children("*", "StaticBody3D", true, false):
		found.append(node as StaticBody3D)
	return found


func _boxes_of_kind(arena: Node3D, kind: String) -> Array[AABB]:
	var boxes: Array[AABB] = []
	for body: StaticBody3D in _bodies(arena):
		if _kind_of(arena, body) == kind:
			boxes.append(_box_of(body))
	return boxes


func _box_of(body: StaticBody3D) -> AABB:
	var collider: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()


## The space between the walls of the enclosure, on the ground.
func _inside_of(walls: Array[AABB]) -> AABB:
	var low: Vector3 = Vector3(-INF, 0.0, -INF)
	var high: Vector3 = Vector3(INF, 0.0, INF)
	for box: AABB in walls:
		var middle: Vector3 = box.get_center()
		if box.size.x < box.size.z:
			if middle.x < 0.0:
				low.x = maxf(low.x, box.end.x)
			else:
				high.x = minf(high.x, box.position.x)
		elif middle.z < 0.0:
			low.z = maxf(low.z, box.end.z)
		else:
			high.z = minf(high.z, box.position.z)
	return AABB(low, Vector3(high.x - low.x, 100.0, high.z - low.z))


## Whether a block to mantle stands against the platform, its top within a jump and a
## mantle of the platform's.
func _has_a_ledge_to(platform: AABB, blocks: Array[AABB], tuning: MovementTuning) -> bool:
	for block: AABB in blocks:
		var climb: float = platform.end.y - block.end.y
		var against: bool = platform.grow(PRECISION).intersects(block)
		var reach: float = tuning.jump_height + tuning.mantle_max_height
		if against and climb >= tuning.mantle_min_height and climb <= reach:
			return true
	return false
