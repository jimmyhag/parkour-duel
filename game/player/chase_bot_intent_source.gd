class_name ChaseBotIntentSource
extends IntentSource
## The bot of the chase (docs/specs/chase-bot.md): a runner led by the pilot
## (PilotIntentSource) along a path of the navigation of the arena, towards the goal its
## mind (ChaseBot, game/core) gives at each of its decisions. It sees the other runner only
## by its position and its velocity at the step it plays. The paths go over the navigation
## mesh of the arena, as low as a slide (the pilot slides under what is lower than a runner
## on its feet), and through the links the arena declares: the pilot vaults, mantles,
## climbs and jumps down them as it runs from their start to their end, and jumps at no
## step or ledge off a link; at the EASY level, the bot takes no link that
## climbs. The length of a path counts each of its links at the cost of travel the link
## declares (how much longer than running it takes), and, for a runner already moving,
## the turn its speed costs it to set off along the path. It pushes its stick as far as its
## level says. Going down from a block or a platform high enough for a simple trick to end
## before the ground, at the levels that do tricks, it does a front flip and presses the
## slide the time of its level before the ground: the trick is posed, and the landing
## slides on. It takes a new path to its goal at each decision, but not halfway along a
## link: a link it has started it runs to its end. When it gets no nearer its goal for the
## stuck time of the tuning, it takes a new path from where it is, or goes back to the
## start of the link it is on to take it again, and jumps if something stops it. As the cat
## (docs/specs/chase-tag.md), once the mouse has been the delay of its level within the
## reach and the cone of a touch, it touches; at the levels that dive, once the mouse has
## been that long within those of a dive but not of a touch, and would stay within them all
## through a dive, both going on as they go, it dives. It drives the motor with intents
## only, one per step, like a gamepad.

## The navigation layers of the arena: the ground, with the links any runner takes
## (vaults, jumps down), and the links that climb (mantles onto blocks, platforms).
const GROUND_LAYER: int = 1
const CLIMB_LAYER: int = 2
## How near a corner of its path, along the ground, the bot has reached it, in m; and how
## far above or below it may be.
const CORNER_REACH: float = 0.5
const CORNER_HEIGHT: float = 1.0
## How near the end of a link, along the ground, the bot has reached it, in m: where a
## jump down lands, or a vault, is not quite where the link ends.
const LINK_END_REACH: float = 1.5
## Getting nearer the goal by less than this along the path is no progress, in m.
const PROGRESS: float = 0.05
## A descent: the floor of the landing at least this far under the floor of the take-off,
## in m: a block or a platform.
const DESCENT: float = 1.0
## Fixed steps a trick must end before the ground, at the least.
const TRICK_MARGIN_STEPS: int = 2
## The longest flight the bot looks ahead along, in fixed steps.
const LONGEST_FLIGHT_STEPS: int = 180
## Under this real speed on the ground, in m/s, something stops the bot.
const STOPPED_SPEED: float = 1.0
## Nearer its target than this along the ground, in m, the bot pushes no more.
const STILL: float = 0.05
## How far apart the points of a path are where its clearance from the cat is weighed, in m.
const CLEARANCE_STEP: float = 0.5

## The bot's mind: its level, its role and its decisions.
var mind: ChaseBot
## The goal of its last decision, and the path to it it follows.
var goal: Vector3 = Vector3.ZERO
var path: PackedVector3Array = PackedVector3Array()
## Intents given so far.
var intents: int = 0
## Fixed steps since the bot last got nearer its goal, and the most of them in a row since
## it last started playing a role.
var steps_without_progress: int = 0
var most_steps_without_progress: int = 0

var _runner: Player
var _other: CharacterBody3D
var _pilot: PilotIntentSource
var _flee_points: Array[Vector3] = []
var _map: RID
## The index of the corner of the path the bot runs to, and the kinds of the corners: a
## corner of the kind LINK starts a link.
var _corner: int = 0
var _types: PackedInt32Array = PackedInt32Array()
var _steps_to_decide: int = 0
## A new path is wanted, from where the bot will be on the ground.
var _path_wanted: bool = false
## The least length left of the path since it was taken.
var _least_left: float = INF
var _query: NavigationPathQueryParameters3D = NavigationPathQueryParameters3D.new()
var _result: NavigationPathQueryResult3D = NavigationPathQueryResult3D.new()
## The altitude of the floor the bot last stood on, a trick done in this flight, the slide
## that poses it pressed, and steps the slide is still held after the landing.
var _take_off_floor: float = 0.0
var _trick_done: bool = false
var _pose_pressed: bool = false
var _pose_steps_left: int = 0
## Fixed steps in a row the mouse has been within the reach of a touch, and of a dive only.
var _steps_in_touch_reach: int = 0
var _steps_in_dive_reach: int = 0


## A bot running `runner` against `other` at `level`, over the navigation map `map`, with
## the flee points `flee_points` of the arena.
func _init(
	runner: Player,
	other: CharacterBody3D,
	level: ChaseBot.Level,
	map: RID,
	flee_points: Array[Vector3]
) -> void:
	_runner = runner
	_other = other
	_map = map
	_flee_points = flee_points
	mind = ChaseBot.new(runner.tuning, level)
	_pilot = PilotIntentSource.new(runner, -runner.global_basis.z)
	_query.map = map
	_query.metadata_flags = (
		NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_TYPES
		| NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_RIDS
	)


## From now on plays `role`, from where it stands: a decision at its first step.
func play(role: ChaseState.Role) -> void:
	mind.play(role)
	path = PackedVector3Array()
	_corner = 0
	_steps_to_decide = 0
	_least_left = INF
	steps_without_progress = 0
	most_steps_without_progress = 0
	_trick_done = false
	_pose_pressed = false
	_pose_steps_left = 0
	_steps_in_touch_reach = 0
	_steps_in_dive_reach = 0


## The navigation layers of the paths of the bot: the climbs too, at the levels that take
## them.
func navigation_layers() -> int:
	return GROUND_LAYER | (CLIMB_LAYER if mind.climbs() else 0)


## The path from `from` to `to` with the navigation layers `layers`: its corners, from a
## point of the navigation under `from`. Empty while the navigation is not ready.
func path_between(from: Vector3, to: Vector3, layers: int) -> PackedVector3Array:
	_query_path(from, to, layers)
	return _result.path


func next_intent() -> MoveIntent:
	intents += 1
	var motor: RunnerMotor = _runner.motor
	var on_the_ground: bool = motor.is_on_the_ground()
	if on_the_ground:
		_take_off_floor = _runner.global_position.y
	_steps_to_decide -= 1
	if _steps_to_decide <= 0 and NavigationServer3D.map_get_iteration_id(_map) > 0:
		_decide()
	if _path_wanted and on_the_ground and not _on_a_link():
		_take_the_path()
	_pass_the_corners()
	var stuck: bool = _follow_the_progress()
	if stuck and on_the_ground:
		if _on_a_link():
			# Back to the start of the link, to take it again from there.
			_corner -= 1
		else:
			_take_the_path()
	# Past the last corner: its goal, or where the path ends when the goal is out of its
	# reach (the player up where it may not climb), to wait there rather than push on.
	var target: Vector3 = goal
	if _corner < path.size():
		target = path[_corner]
	elif not path.is_empty():
		target = path[path.size() - 1]
	var way: Vector3 = target - _runner.global_position
	_pilot.climbs = _on_a_link()
	way.y = 0.0
	# Past its target the bot turns: what stands beyond is no obstacle of its way.
	_pilot.way_length = way.length() + _runner.tuning.capsule_radius
	_pilot.run_towards(way)
	var intent: MoveIntent = _pilot.next_intent()
	intent.direction *= mind.push()
	if way.length() < STILL:
		# At its goal: it waits there.
		intent.direction = Vector3.ZERO
	if stuck and on_the_ground and motor.real_speed() < STOPPED_SPEED:
		intent.jump_pressed = true
		intent.jump_held = true
	_trick(intent, on_the_ground)
	if mind.role == ChaseState.Role.CAT:
		_tag(intent)
	return intent


## The gestures of the cat: a touch once the mouse has been the delay of the level within
## its reach and its cone; at the levels that dive, a dive once it has been that long within
## the reach of a dive only, and would stay within it all through the dive. None while a
## gesture of the cat goes on.
func _tag(intent: MoveIntent) -> void:
	var tuning: MovementTuning = _runner.tuning
	var cat: PackedVector3Array = Player.axis_of(_runner)
	var mouse: PackedVector3Array = Player.axis_of(_other)
	var radii: float = Player.radius_of(_runner) + Player.radius_of(_other)
	var facing: Vector3 = _runner.tag_facing()
	var touch: float = tuning.tag_touch_reach
	var in_touch_reach: bool = Tag.reaches(cat, mouse, radii, facing, touch, tuning.tag_touch_cone)
	var in_dive_reach: bool = not in_touch_reach and mind.dives() and _dive_catches()
	_steps_in_touch_reach = _steps_in_touch_reach + 1 if in_touch_reach else 0
	_steps_in_dive_reach = _steps_in_dive_reach + 1 if in_dive_reach else 0
	var gesture: Tag = _runner.motor.tag
	if gesture != null and not gesture.is_over():
		return
	var delay: int = roundi(mind.tag_delay() / _runner.get_physics_process_delta_time())
	if _steps_in_touch_reach > delay:
		intent.touch_pressed = true
	elif _steps_in_dive_reach > delay:
		intent.dive_pressed = true


## Whether a dive started now would keep the mouse within its reach and its cone all
## through it: at each of its steps, the cat going the way it runs, the push of a dive
## faster, the mouse going on at its velocity. Only on its feet, fast enough to dive.
func _dive_catches() -> bool:
	var tuning: MovementTuning = _runner.tuning
	var motor: RunnerMotor = _runner.motor
	if not motor.is_on_foot() or motor.real_speed() < tuning.tag_dive_min_speed:
		return false
	var step: float = _runner.get_physics_process_delta_time()
	var run: Vector3 = Vector3(_runner.velocity.x, 0.0, _runner.velocity.z)
	var dive: Vector3 = run.normalized() * (run.length() + tuning.tag_dive_push)
	var flight: Vector3 = Vector3(_other.velocity.x, 0.0, _other.velocity.z)
	var cat: PackedVector3Array = Player.axis_of(_runner)
	var mouse: PackedVector3Array = Player.axis_of(_other)
	var radii: float = Player.radius_of(_runner) + Player.radius_of(_other)
	for index: int in roundi(tuning.tag_dive_time / step) + 1:
		var ahead: Vector3 = (flight - dive) * step * index
		var moved: PackedVector3Array = [mouse[0] + ahead, mouse[1] + ahead]
		var reach: float = tuning.tag_dive_reach
		if not Tag.reaches(cat, moved, radii, run.normalized(), reach, tuning.tag_dive_cone):
			return false
	return true


## A decision of the mind: its goal, on the navigation; a new path to it is wanted.
func _decide() -> void:
	var step: float = _runner.get_physics_process_delta_time()
	_steps_to_decide = maxi(roundi(mind.decision_time() / step), 1)
	var candidates: Array[ChaseBotCandidate] = []
	if mind.role == ChaseState.Role.MOUSE:
		candidates = _candidates()
	var aim: Vector3 = mind.decide(
		_runner.global_position,
		_runner.velocity,
		_other.global_position,
		_other.velocity,
		candidates
	)
	goal = NavigationServer3D.map_get_closest_point(_map, aim)
	_path_wanted = true


## The flee points, with the lengths of the bot's path and of the cat's to each, and how
## near the cat can come to the bot along its path.
func _candidates() -> Array[ChaseBotCandidate]:
	var candidates: Array[ChaseBotCandidate] = []
	var from: Vector3 = _runner.global_position
	var cat: Vector3 = _other.global_position
	var all_layers: int = GROUND_LAYER | CLIMB_LAYER
	for point: Vector3 in _flee_points:
		var candidate: ChaseBotCandidate = ChaseBotCandidate.new()
		candidate.point = point
		_query_path(from, point, navigation_layers())
		var own: PackedVector3Array = _result.path
		var on_the_mesh: Vector3 = NavigationServer3D.map_get_closest_point(_map, point)
		if not own.is_empty() and own[own.size() - 1].distance_to(on_the_mesh) <= CORNER_REACH:
			candidate.distance = _path_length(_runner.velocity)
			candidate.cat_clearance = _clearance(own, from, cat)
		_query_path(cat, point, all_layers)
		if not _result.path.is_empty():
			candidate.cat_distance = _path_length(_other.velocity)
		candidates.append(candidate)
	return candidates


## How near the cat at `cat` can come to a runner that runs the path `corners` from
## `from`, the two as fast: the least, along the path, of the cat's distance to a point of
## it less the runner's distance to that point along the path, on the ground. As the run
## starts, it is how far the cat is.
static func _clearance(corners: PackedVector3Array, from: Vector3, cat: Vector3) -> float:
	var flat_cat: Vector2 = Vector2(cat.x, cat.z)
	var previous: Vector2 = Vector2(from.x, from.z)
	var closest: float = previous.distance_to(flat_cat)
	var run: float = 0.0
	for index: int in range(1, corners.size()):
		var corner: Vector2 = Vector2(corners[index].x, corners[index].z)
		var length: float = previous.distance_to(corner)
		var samples: int = maxi(ceili(length / CLEARANCE_STEP), 1)
		for sample: int in range(1, samples + 1):
			var along: float = length * sample / samples
			var point: Vector2 = previous.lerp(corner, along / length) if length > 0.0 else corner
			closest = minf(closest, point.distance_to(flat_cat) - (run + along))
		run += length
		previous = corner
	return closest


## The path to the goal from where the bot is, from its first corner after the start.
func _take_the_path() -> void:
	_path_wanted = false
	var corners: PackedVector3Array = path_between(
		_runner.global_position, goal, navigation_layers()
	)
	if corners.is_empty():
		return
	path = corners
	_types = _result.path_types
	_corner = 1
	_least_left = _length_left()


## The length of the path of the last query, each of its links counted at its cost of
## travel, for a runner going at `velocity`: the speed it has against the way the path
## sets off costs it the distance it would have run while it brakes it, then gains it
## again.
func _path_length(velocity: Vector3) -> float:
	var corners: PackedVector3Array = _result.path
	var types: PackedInt32Array = _result.path_types
	var rids: Array[RID] = _result.path_rids
	var length: float = 0.0
	if corners.size() > 1:
		var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
		var way: Vector3 = corners[1] - corners[0]
		way = Vector3(way.x, 0.0, way.z).normalized()
		var lost: float = flat.length() - flat.dot(way)
		length += lost * flat.length() / _runner.tuning.ground_acceleration
	# The links of the map, now: a path may name a link that has gone since (its arena
	# freed), or a region where a link starts; only a link has a cost of travel.
	var links: Array[RID] = NavigationServer3D.map_get_links(_query.map)
	for index: int in range(1, corners.size()):
		var cost: float = 1.0
		if index - 1 < types.size() and index - 1 < rids.size():
			var rid: RID = rids[index - 1]
			var on_a_link: bool = (
				types[index - 1] == NavigationPathQueryResult3D.PATH_SEGMENT_TYPE_LINK
			)
			if on_a_link and links.has(rid):
				cost = NavigationServer3D.link_get_travel_cost(rid)
		length += corners[index - 1].distance_to(corners[index]) * cost
	return length


func _query_path(from: Vector3, to: Vector3, layers: int) -> void:
	_query.start_position = from
	_query.target_position = to
	_query.navigation_layers = layers
	NavigationServer3D.query_path(_query, _result)


## The bot runs to the end of a link: the corner before it starts a link.
func _on_a_link() -> bool:
	return _starts_a_link(_corner - 1) and _corner < path.size()


func _starts_a_link(corner: int) -> bool:
	if corner < 0 or corner >= _types.size():
		return false
	return _types[corner] == NavigationPathQueryResult3D.PATH_SEGMENT_TYPE_LINK


## The corners the bot has reached are behind it; so are those it went past, but the
## start of a link, which it must reach to take the link from there.
func _pass_the_corners() -> void:
	var feet: Vector3 = _runner.global_position
	while _corner < path.size():
		var corner: Vector3 = path[_corner]
		var off: Vector3 = feet - corner
		var reach: float = LINK_END_REACH if _on_a_link() else CORNER_REACH
		var reached: bool = Vector2(off.x, off.z).length() <= reach
		reached = reached and absf(off.y) <= CORNER_HEIGHT
		var starts_a_link: bool = _starts_a_link(_corner)
		if not reached and not starts_a_link and _corner + 1 < path.size():
			var next: Vector3 = path[_corner + 1]
			var ahead: Vector3 = Vector3(next.x - corner.x, 0.0, next.z - corner.z)
			reached = absf(off.y) <= CORNER_HEIGHT and Vector3(off.x, 0.0, off.z).dot(ahead) > 0.0
		if not reached:
			return
		_corner += 1


## The length of the path left: to the corner the bot runs to, then from corner to
## corner.
func _length_left() -> float:
	if _corner >= path.size():
		return 0.0
	var left: float = _runner.global_position.distance_to(path[_corner])
	for index: int in range(_corner + 1, path.size()):
		left += path[index - 1].distance_to(path[index])
	return left


## Counts the steps the bot gets no nearer its goal along its path; once they last the
## stuck time of the tuning (and again each time they last it more), a new path is wanted
## and the step is a stuck one. At its goal, the bot is not stuck.
func _follow_the_progress() -> bool:
	var left: float = _length_left()
	if left < _least_left - PROGRESS or left <= CORNER_REACH:
		_least_left = minf(left, _least_left)
		steps_without_progress = 0
		return false
	steps_without_progress += 1
	most_steps_without_progress = maxi(most_steps_without_progress, steps_without_progress)
	var step: float = _runner.get_physics_process_delta_time()
	var stuck_steps: int = maxi(roundi(_runner.tuning.chase_bot_stuck_time / step), 1)
	if steps_without_progress % stuck_steps != 0:
		return false
	_path_wanted = true
	return true


## The trick of a descent, at the levels that do them: in the air, off a floor high enough
## over the one ahead for a simple trick to end before it, the trick button released with
## a front flip, the jump held up to its top; then the slide pressed, instead of the
## pilot's, the time of the level before the ground, and held into the landing.
func _trick(intent: MoveIntent, on_the_ground: bool) -> void:
	if on_the_ground:
		if _pose_steps_left > 0:
			_pose_steps_left -= 1
			intent.slide_held = true
		_trick_done = false
		_pose_pressed = false
		return
	if not mind.tricks():
		return
	var motor: RunnerMotor = _runner.motor
	var in_the_air: bool = (
		motor.state == RunnerMotor.State.RISING or motor.state == RunnerMotor.State.FALLING
	)
	if not in_the_air:
		return
	var landing: Vector2 = _flight_to_the_floor()
	var steps_to_land: int = int(landing.x)
	if not _trick_done:
		if not motor.trick_ready or steps_to_land < 0:
			return
		if _take_off_floor - landing.y < DESCENT:
			return
		var turn_steps: int = roundi(
			_runner.tuning.trick_turn_duration / _runner.get_physics_process_delta_time()
		)
		if steps_to_land < turn_steps + TRICK_MARGIN_STEPS:
			return
		intent.trick_released = true
		intent.trick_recipe = TrickRecipe.drawn(TrickRecipe.Flip.FRONT_FLIP)
		_trick_done = true
	# The trick goes on: the jump held to its top, the slide pressed by the bot only.
	intent.jump_held = intent.jump_held or motor.state == RunnerMotor.State.RISING
	intent.slide_pressed = false
	intent.slide_held = _pose_pressed
	var press_steps: int = roundi(mind.landing_press() / _runner.get_physics_process_delta_time())
	if not _pose_pressed and steps_to_land >= 0 and steps_to_land <= press_steps:
		intent.slide_pressed = true
		intent.slide_held = true
		_pose_pressed = true
		_pose_steps_left = 2


## The flight of the bot from now on, with the gravities of the tuning, keeping its
## horizontal speed: how many fixed steps until its feet meet a floor (x), and the
## altitude of that floor (y); x is -1 if they meet none within the longest flight.
func _flight_to_the_floor() -> Vector2:
	var tuning: MovementTuning = _runner.tuning
	var step: float = _runner.get_physics_process_delta_time()
	var horizontal: Vector3 = Vector3(_runner.velocity.x, 0.0, _runner.velocity.z)
	var feet: Vector3 = _runner.global_position
	var speed: float = _runner.velocity.y
	var space: PhysicsDirectSpaceState3D = _runner.get_world_3d().direct_space_state
	for steps: int in range(1, LONGEST_FLIGHT_STEPS + 1):
		var gravity: float = tuning.rise_gravity if speed > 0.0 else tuning.fall_gravity
		speed = maxf(speed - gravity * step, -tuning.max_fall_speed)
		var next: Vector3 = feet + (horizontal + Vector3.UP * speed) * step
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			feet, next, _runner.collision_mask, [_runner.get_rid()]
		)
		var hit: Dictionary = space.intersect_ray(ray)
		if not hit.is_empty():
			var normal: Vector3 = hit["normal"]
			if normal.angle_to(Vector3.UP) <= _runner.floor_max_angle:
				var floor_point: Vector3 = hit["position"]
				return Vector2(steps, floor_point.y)
			return Vector2(-1.0, 0.0)
		feet = next
	return Vector2(-1.0, 0.0)
