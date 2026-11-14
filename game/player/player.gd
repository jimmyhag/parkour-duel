class_name Player
extends CharacterBody3D
## The runner's body. At every fixed step it asks its intent source for an intent,
## gives it to the motor of game/core with the facts it observes (RunnerFacts), and
## applies what the motor decides: the velocity it wants, a capsule as low as its state
## says, a visible body that faces the push, leans towards the wall it runs along and
## turns with the trick under way. It decides nothing about the movement itself.

## Emitted at the end of every fixed step, with the intent the runner just followed.
signal stepped(intent: MoveIntent)

const RELOAD_TUNING: StringName = &"reload_tuning"
## Where the visor sits on the capsule, as a share of its height.
const VISOR_HEIGHT_RATIO: float = 0.8
## A level puts in this group a wall it does not want to be run along. Only fixed walls
## (static bodies) are walls at all.
const NO_WALL_RUN_GROUP: StringName = &"no_wall_run"
## Below this horizontal speed (m/s), a body that looks where it moves keeps its
## orientation: what is left of a speed that small says nothing of a direction.
const ALMOST_STILL: float = 0.1

## The tuning resource; its capsule and camera values replace the ones of the scene.
@export var tuning: MovementTuning

var motor: RunnerMotor
## Replaceable: the inputs by default, a sequence written in advance in the tests.
var intent_source: IntentSource

## Where the visible body looks, as a rotation around the vertical axis, and how far it
## leans to its left, in radians.
var _yaw: float = 0.0
var _lean: float = 0.0

@onready var camera_rig: CameraRig = $CameraRig as CameraRig
@onready var _collider: CollisionShape3D = $CollisionShape3D as CollisionShape3D
@onready var _visual: Node3D = $Visual as Node3D
@onready var _body: MeshInstance3D = $Visual/Body as MeshInstance3D
@onready var _visor: MeshInstance3D = $Visual/Visor as MeshInstance3D


func _ready() -> void:
	motor = RunnerMotor.new(tuning)
	intent_source = InputIntentSource.new(camera_rig)
	camera_rig.target = self
	apply_tuning(tuning)


func _physics_process(delta: float) -> void:
	var intent: MoveIntent = intent_source.next_intent()
	velocity = motor.step(intent, _observe(intent), delta)
	_fit_capsule()
	move_and_slide()
	_turn(intent, delta)
	_lean_towards_the_wall(delta)
	_pose()
	stepped.emit(intent)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(RELOAD_TUNING):
		reload_tuning()


## Makes the runner, its capsule and its camera use this tuning from now on.
func apply_tuning(new_tuning: MovementTuning) -> void:
	tuning = new_tuning
	motor.tuning = tuning
	camera_rig.tuning = tuning
	_set_capsule_height(_wanted_capsule_height())
	(_collider.shape as CapsuleShape3D).radius = tuning.capsule_radius
	(_body.mesh as CapsuleMesh).radius = tuning.capsule_radius
	_visor.position.z = -tuning.capsule_radius


## Reads the tuning file again, so that a value changed on disk applies without
## restarting the game.
func reload_tuning() -> void:
	var path: String = tuning.resource_path
	if path.is_empty():
		return
	var fresh: MovementTuning = (
		ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as MovementTuning
	)
	if fresh != null:
		apply_tuning(fresh)


## Puts the runner at `spawn`, standing and at rest, facing its -Z axis, with the camera
## in its back.
func teleport(spawn: Transform3D) -> void:
	var yaw: float = spawn.basis.get_euler().y
	global_position = spawn.origin
	velocity = Vector3.ZERO
	motor.reset()
	_fit_capsule()
	_yaw = yaw
	_lean = 0.0
	_pose()
	camera_rig.face(yaw)
	reset_physics_interpolation()


## What the motor needs to know about the body and the world around it. Nothing of it
## depends on where the visible body looks: that is presentation only.
func _observe(intent: MoveIntent) -> RunnerFacts:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.on_floor = is_on_floor()
	facts.velocity = velocity
	facts.altitude = global_position.y
	if facts.on_floor:
		facts.floor_normal = _normal_of_the_ground_underfoot()
	facts.can_stand = not motor.is_low() or _has_headroom()
	facts.ground_clearance = _ground_clearance()
	_observe_the_wall_beside(facts, intent)
	_observe_the_ledge_ahead(facts, intent)
	return facts


## How far down the ground is under the feet, probed as deep as a wall run asks the
## runner to be above it; INF when there is none within that depth.
func _ground_clearance() -> float:
	var feet: Vector3 = global_position
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		feet + Vector3.UP * tuning.capsule_radius,
		feet + Vector3.DOWN * tuning.wall_run_min_height,
		collision_mask,
		[get_rid()]
	)
	var ground: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty():
		return INF
	var point: Vector3 = ground["position"]
	return maxf(feet.y - point.y, 0.0)


## The nearest wall at the runner's left or right, probed straight aside from the middle
## of its body, as far as a wall run reaches: aside from the way the body moves, or from
## the way the runner pushes when the body hardly moves. A wall is a fixed body (a
## static body) that its level did not exclude; its identity is the identity of the
## body.
func _observe_the_wall_beside(facts: RunnerFacts, intent: MoveIntent) -> void:
	var heading: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if heading.is_zero_approx():
		heading = Vector3(intent.direction.x, 0.0, intent.direction.z)
	if heading.is_zero_approx():
		return
	var right: Vector3 = heading.normalized().cross(Vector3.UP)
	var middle: Vector3 = global_position + Vector3.UP * _capsule_height() / 2.0
	var reach: float = tuning.capsule_radius + tuning.wall_run_distance
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for side: Vector3 in [right, -right]:
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			middle, middle + side * reach, collision_mask, [get_rid()]
		)
		var hit: Dictionary = space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var collider: Object = hit["collider"]
		var wall: StaticBody3D = collider as StaticBody3D
		if wall == null or wall.is_in_group(NO_WALL_RUN_GROUP):
			continue
		var normal: Vector3 = hit["normal"]
		var point: Vector3 = hit["position"]
		var distance: float = maxf((middle - point).dot(normal) - tuning.capsule_radius, 0.0)
		if distance >= facts.wall_distance:
			continue
		facts.wall_id = wall.get_instance_id()
		facts.wall_normal = normal
		facts.wall_distance = distance
		var shape_index: int = hit["shape"]
		facts.wall_height = _height_of(wall, shape_index)


## How tall the shape `shape_index` of `body` is, from its lowest point to its highest.
func _height_of(body: CollisionObject3D, shape_index: int) -> float:
	var owner_id: int = body.shape_find_owner(shape_index)
	var collider: CollisionShape3D = body.shape_owner_get_owner(owner_id) as CollisionShape3D
	if collider == null or collider.shape == null:
		return 0.0
	var box: AABB = collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
	return box.size.y


## The ledge the runner pushes against, if any: of the faces the body touched at the
## last step, the one the push goes most into (the motor judges whether it is enough),
## and the top of the block behind that face, probed from above as high as the highest
## ledge a mantle climbs plus a standing body, down to the feet. Its top is free when a
## standing body fits on it.
func _observe_the_ledge_ahead(facts: RunnerFacts, intent: MoveIntent) -> void:
	var push: Vector3 = Vector3(intent.direction.x, 0.0, intent.direction.z)
	var front: KinematicCollision3D = null
	var most_into: float = 0.0
	for index: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(index)
		var normal: Vector3 = collision.get_normal()
		var into: float = -push.dot(Vector3(normal.x, 0.0, normal.z).normalized())
		if into > most_into:
			most_into = into
			front = collision
	if front == null:
		return
	var normal: Vector3 = front.get_normal()
	var onto: Vector3 = -Vector3(normal.x, 0.0, normal.z).normalized()
	var over: Vector3 = front.get_position() + onto * tuning.capsule_radius
	var feet: Vector3 = global_position
	var highest: float = feet.y + tuning.mantle_max_height + tuning.capsule_height
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(over.x, highest, over.z),
		Vector3(over.x, feet.y, over.z),
		collision_mask,
		[get_rid()]
	)
	ray.hit_from_inside = true
	var top: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if top.is_empty():
		return
	var top_point: Vector3 = top["position"]
	var top_normal: Vector3 = top["normal"]
	facts.ledge_normal = normal
	facts.ledge_height = top_point.y - feet.y
	# A ray that starts inside the block found no top: the block is taller than that.
	facts.ledge_clear = not top_normal.is_zero_approx() and _fits_standing_at(top_point)


## Whether a standing body would fit with its feet at `feet`.
func _fits_standing_at(feet: Vector3) -> bool:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	var middle: Vector3 = feet + Vector3.UP * (tuning.capsule_height / 2.0 + safe_margin)
	query.transform = Transform3D(Basis.IDENTITY, middle)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## Where the runner faces, on the ground: the direction its visible body looks at.
func _facing() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, _yaw)


func _capsule_height() -> float:
	return (_collider.shape as CapsuleShape3D).height


## The normal of the ground right under the runner's feet, probed straight down as deep
## as the steepest floor can be under a capsule that rests on it; straight up when there
## is no ground there. The contact the body reports is not used: over the edge of a
## block it is tilted like a slope, and the edge of a block is not a slope.
func _normal_of_the_ground_underfoot() -> Vector3:
	var reach: Vector3 = Vector3.UP * tuning.capsule_radius
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + reach, global_position - reach, collision_mask, [get_rid()]
	)
	var ground: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty():
		return Vector3.UP
	var normal: Vector3 = ground["normal"]
	return normal


## Whether the capsule, low as it is, could rise to its standing height where it is.
func _has_headroom() -> bool:
	var rise: float = tuning.capsule_height - tuning.slide_capsule_height
	return not test_move(global_transform, Vector3.UP * rise)


## The height the state of the runner asks for: low in a slide and in a roll.
func _wanted_capsule_height() -> float:
	return tuning.slide_capsule_height if motor.is_low() else tuning.capsule_height


## Gives the capsule the height its state asks for, if it does not have it yet.
func _fit_capsule() -> void:
	var height: float = _wanted_capsule_height()
	if not is_equal_approx((_collider.shape as CapsuleShape3D).height, height):
		_set_capsule_height(height)


## Changes the height of the capsule, the one that collides and the one that is seen,
## without moving its feet.
func _set_capsule_height(height: float) -> void:
	(_collider.shape as CapsuleShape3D).height = height
	_collider.position.y = height / 2.0
	(_body.mesh as CapsuleMesh).height = height
	_body.position.y = height / 2.0
	_visor.position.y = height * VISOR_HEIGHT_RATIO


## The visible body turns, at its pace, towards where it should look this step; with
## nowhere to look, or during a trick, it keeps its orientation.
func _turn(intent: MoveIntent, delta: float) -> void:
	var heading: Vector3 = _heading(intent)
	if heading.is_zero_approx() or motor.is_in_a_trick():
		return
	var facing: float = atan2(-heading.x, -heading.z)
	_yaw = rotate_toward(_yaw, facing, tuning.turn_speed * delta)


## Where the visible body should look, horizontal; ZERO to keep its orientation. Towards
## where the runner pushes, not where the scenery lets it go; in a slide or a roll,
## towards where it moves; in a wall run, along the wall the way it runs, whatever the
## push; during a mantle, nowhere new.
func _heading(intent: MoveIntent) -> Vector3:
	var motion: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	match motor.state:
		RunnerMotor.State.MANTLING:
			return Vector3.ZERO
		RunnerMotor.State.SLIDING, RunnerMotor.State.ROLLING:
			return motion if motion.length() > ALMOST_STILL else Vector3.ZERO
		RunnerMotor.State.WALL_RUNNING:
			var away: Vector3 = motor.wall_run_normal()
			var along: Vector3 = motion - away * motion.dot(away)
			return along if along.length() > ALMOST_STILL else Vector3.ZERO
	return Vector3(intent.direction.x, 0.0, intent.direction.z)


## In a wall run, the capsule one sees leans towards the wall, at the pace it turns; it
## straightens up when the wall run is over.
func _lean_towards_the_wall(delta: float) -> void:
	var away: Vector3 = motor.wall_run_normal()
	var lean: float = 0.0
	if not away.is_zero_approx():
		# Rolling the body to the left (a positive angle) leans it towards a wall at its
		# left, whose normal points to its right.
		var right: Vector3 = _facing().cross(Vector3.UP)
		lean = deg_to_rad(tuning.wall_run_lean) * signf(away.dot(right))
	_lean = rotate_toward(_lean, lean, tuning.turn_speed * delta)


## Places the visible body: where it looks and how it leans; in a trick, read from the
## motor, twisted around its own axis and turned around the axis of the flip, through
## the middle of the body. A trick over leaves it upright, and so does a crash, at once.
func _pose() -> void:
	var pose: Basis = Basis.from_euler(Vector3(0.0, _yaw, _lean))
	var origin: Vector3 = Vector3.ZERO
	var trick: AirTrick = motor.current_trick()
	if trick != null:
		pose = pose * Basis(Vector3.UP, trick.twist_angle())
		var flip: Basis = Basis(trick.axis, trick.flip_angle())
		var middle: Vector3 = Vector3.UP * _capsule_height() / 2.0
		pose = flip * pose
		origin = middle - flip * middle
	_visual.transform = Transform3D(pose, origin)
