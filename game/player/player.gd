class_name Player
extends CharacterBody3D
## The runner's body. At every fixed step it asks its intent source for an intent,
## gives it to the motor of game/core with the facts it observes (RunnerFacts), and
## applies what the motor decides: the velocity it wants, a capsule as low as its state
## says, a visible body that faces the push, leans along the wall it runs along, turns
## with the trick under way and shows the animation of the motor's state (the Mixamo
## character, RunnerCharacter, when its files are there; the capsule and its visor
## otherwise). The visible body is placed at each fixed step; between two of them, the
## physics interpolation of the project shows it in between. While it aims, it observes
## what is under the reticle
## (AimFacts), or on the line from its head that its intent gives (the bot's aim), and
## puts the camera over its shoulder. Held (a countdown), it follows no intent. It decides
## nothing about the movement or the shot itself.

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
## What the line of the reticle meets: the blocks of the world and the targets
## (project.godot, layer names 1 and 3), not the runners.
const AIM_MASK: int = 0b101
## How far past a face, or under a top, the probes of an obstacle ahead look, in m: inside
## the obstacle, not on its surface.
const PROBE_INSET: float = 0.05

## The tuning resource; its capsule and camera values replace the ones of the scene.
@export var tuning: MovementTuning

var motor: RunnerMotor
## Replaceable: the inputs by default, a sequence written in advance in the tests.
var intent_source: IntentSource
## What the runner observed under the reticle at its last step: nothing unless it aimed.
var aim_facts: AimFacts = AimFacts.new()
## The runner waits: at every step it wants nothing, whatever its intent source.
var held: bool = false
## The character its visible body takes, if its files are there; a path where there is
## none keeps the capsule. To set before the runner enters the tree.
var character_model: String = RunnerCharacter.MODEL
## The animation of the state of the runner at its last step: what its body shows.
var animation: RunnerAnimation = RunnerAnimation.new()

## Where the visible body looks, as a rotation around the vertical axis, and how far it
## leans to its left, in radians.
var _yaw: float = 0.0
var _lean: float = 0.0
## How far the wall beside the runner was from the side of its capsule at its last step,
## in m: INF without a wall; and at the last step of its last wall run, with the weights
## of the run it showed then.
var _wall_distance: float = INF
var _wall_run_distance: float = 0.0
var _wall_run_locomotion: PackedFloat32Array = []
## The Mixamo character in the visible body; null with the capsule.
var _character: RunnerCharacter = null

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
	_character = RunnerCharacter.create(character_model, tuning)
	if _character != null:
		_visual.add_child(_character)
		_body.visible = false
		_visor.visible = false


func _physics_process(delta: float) -> void:
	var intent: MoveIntent = MoveIntent.new() if held else intent_source.next_intent()
	var facts: RunnerFacts = _observe(intent)
	velocity = motor.step(intent, facts, delta)
	_plant_the_hands(facts)
	_fit_capsule()
	move_and_slide()
	camera_rig.aiming = intent.aim_held
	aim_facts = _observe_the_aim(intent)
	_turn(intent, delta)
	animation = RunnerAnimation.of(motor, delta, animation)
	_lean_along_the_wall(delta)
	_pose()
	if _character != null:
		_character.play(animation)
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


## Gives the capsule one sees the colour `colour`, or tints the character with it (the
## opponent's, in a duel).
func paint(colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	_body.material_override = material
	if _character != null:
		_character.tint(colour)


## Shows the world through this runner's camera, or not: a duel shows the player's only,
## and the bot's camera then neither turns nor follows.
func watch(watched: bool) -> void:
	var camera: Camera3D = camera_rig.camera()
	if watched:
		camera.make_current()
	else:
		camera.current = false
	camera_rig.process_mode = Node.PROCESS_MODE_INHERIT if watched else Node.PROCESS_MODE_DISABLED


## What the first block or target is on the line from the runner's eyes in `direction`:
## what a shot that way would reach (the bot sees through it whether a target is hidden).
func aim_facts_towards(direction: Vector3) -> AimFacts:
	var eyes: Vector3 = global_position + Vector3.UP * tuning.camera_look_height
	return _aim_facts_on_the_line(eyes, direction.normalized())


## The drawing of the trick the inputs make, for the pad on the screen; null when the
## runner does not follow the inputs.
func drawing() -> TrickGesture:
	var source: InputIntentSource = intent_source as InputIntentSource
	return null if source == null else source.drawing


## Where the visible body is and how it is turned, in the world, at the last step: what a
## ghost replays.
func visual_transform() -> Transform3D:
	return _visual.global_transform


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
	_wall_distance = facts.wall_distance
	_observe_the_ledge_ahead(facts, intent)
	_observe_the_obstacle_ahead(facts, intent)
	return facts


## A vault or a mantle that starts puts the hands of the character on the top the runner
## observed (HandPlant): of the obstacle ahead, from its face on the way of the vault; of the
## ledge, from its face, the capsule against it.
func _plant_the_hands(facts: RunnerFacts) -> void:
	if _character == null:
		return
	for event: RunnerEvent in motor.events:
		if event.kind == RunnerEvent.Kind.VAULT:
			var vault: Vault = motor.vault
			var into: Vector3 = -Vector3(facts.obstacle_normal.x, 0.0, facts.obstacle_normal.z)
			into = into.normalized()
			var ahead: float = tuning.capsule_radius + facts.obstacle_distance
			var edge: Vector3 = global_position + into * ahead
			edge.y = vault.top
			_character.plant_hands(HandPlant.new(vault.ground, vault.top, edge, into, vault.depth))
		elif event.kind == RunnerEvent.Kind.MANTLE:
			var onto: Vector3 = -Vector3(facts.ledge_normal.x, 0.0, facts.ledge_normal.z)
			var top: float = facts.altitude + facts.ledge_height
			var face: Vector3 = global_position + onto.normalized() * tuning.capsule_radius
			face.y = top
			_character.plant_hands(HandPlant.new(facts.altitude, top, face, onto, INF))


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


## The obstacle across the way of a runner on the floor, ahead the way its body moves (the
## way it pushes when the body hardly moves), as far as a vault reaches (see
## observe_the_obstacle_towards).
func _observe_the_obstacle_ahead(facts: RunnerFacts, intent: MoveIntent) -> void:
	if not facts.on_floor:
		return
	var moving: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if moving.length() <= ALMOST_STILL:
		moving = Vector3(intent.direction.x, 0.0, intent.direction.z) * moving.length()
	observe_the_obstacle_towards(facts, moving, tuning.vault_reach)


## The obstacle across the way of a runner going at `velocity` (horizontal) whose face is at
## most `reach` from its front, across that face, told in `facts` (RunnerFacts). Its face is
## probed along that way, at half the lowest height a vault passes over, as far as the
## slantest push into a face reaches; its top from above, as high as the highest one a vault
## passes over, down to the feet; how deep it is, across its face, back towards it from as
## deep as a vault passes over, just under its top. It has room when a standing body
## passes, the way the runner goes, over its top from its face to where the vault would
## leave the runner at the farthest (Vault.landing), and on the ground from right behind it
## to there, and when there is a floor there, at most the deepest drop a vault takes below
## the feet. An obstacle taller than a vault, or deeper, is reported so, without its room.
## Probed from the body, never from where the visible body looks; the pilot asks it too,
## farther ahead.
func observe_the_obstacle_towards(facts: RunnerFacts, moving: Vector3, reach: float) -> void:
	var heading: Vector3 = Vector3(moving.x, 0.0, moving.z).normalized()
	if heading.is_zero_approx():
		return
	var feet: Vector3 = global_position
	var low: Vector3 = feet + Vector3.UP * tuning.vault_min_height / 2.0
	var slantest: float = maxf(sin(deg_to_rad(tuning.push_split_angle)), 0.1)
	var ahead: float = (tuning.capsule_radius + reach) / slantest
	var face: Dictionary = _first_hit(low, low + heading * ahead, false)
	if face.is_empty():
		return
	var normal: Vector3 = face["normal"]
	var towards_the_runner: Vector3 = Vector3(normal.x, 0.0, normal.z).normalized()
	var face_point: Vector3 = face["position"]
	var distance: float = (low - face_point).dot(towards_the_runner) - tuning.capsule_radius
	if towards_the_runner.is_zero_approx() or distance > reach:
		return
	var inside: Vector3 = face_point - towards_the_runner * PROBE_INSET
	var highest: float = feet.y + tuning.vault_max_height + PROBE_INSET
	var top: Dictionary = _first_hit(
		Vector3(inside.x, highest, inside.z), Vector3(inside.x, feet.y, inside.z), true
	)
	facts.obstacle_normal = normal
	facts.obstacle_distance = maxf(distance, 0.0)
	facts.obstacle_height = INF
	var top_normal: Vector3 = top.get("normal", Vector3.ZERO)
	if top_normal.is_zero_approx():
		return
	var top_point: Vector3 = top["position"]
	facts.obstacle_height = top_point.y - feet.y
	var under_the_top: Vector3 = Vector3(face_point.x, top_point.y - PROBE_INSET, face_point.z)
	var into: Vector3 = -towards_the_runner
	var deepest: Vector3 = under_the_top + into * (tuning.vault_max_depth + PROBE_INSET)
	var back: Dictionary = _first_hit(deepest, under_the_top + into * PROBE_INSET, true)
	var back_normal: Vector3 = back.get("normal", Vector3.ZERO)
	if back_normal.is_zero_approx():
		return
	var back_point: Vector3 = back["position"]
	facts.obstacle_depth = (back_point - face_point).dot(into)
	facts.obstacle_clear = _has_room_to_vault(facts, moving, top_point.y)


## Whether a runner going at `moving` has room to vault the obstacle `facts` tell of, whose
## top stands at the altitude `top` (see observe_the_obstacle_towards).
func _has_room_to_vault(facts: RunnerFacts, moving: Vector3, top: float) -> bool:
	var heading: Vector3 = Vector3(moving.x, 0.0, moving.z).normalized()
	var across: Vector3 = Vector3(facts.obstacle_normal.x, 0.0, facts.obstacle_normal.z)
	var slant: float = maxf(absf(across.normalized().dot(heading)), 0.1)
	var radius: float = tuning.capsule_radius
	var feet: Vector3 = global_position
	var at_the_face: Vector3 = feet + heading * (facts.obstacle_distance + radius) / slant
	var landing: Vector3 = at_the_face + heading * Vault.landing(facts, moving, tuning)
	var clear_of_it: float = (facts.obstacle_depth + radius) / slant + PROBE_INSET
	var behind: Vector3 = at_the_face + heading * clear_of_it
	var over: Vector3 = Vector3(at_the_face.x, top, at_the_face.z)
	if not _passes_standing(over, Vector3(landing.x, top, landing.z) - over):
		return false
	if not _passes_standing(behind, landing - behind):
		return false
	var down: Dictionary = _first_hit(
		Vector3(landing.x, top, landing.z),
		Vector3(landing.x, feet.y - tuning.vault_max_drop, landing.z),
		false
	)
	return not down.is_empty()


## Whether a standing body with its feet at `feet` fits there and moves by `motion` without
## meeting anything.
func _passes_standing(feet: Vector3, motion: Vector3) -> bool:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	var middle: Vector3 = feet + Vector3.UP * (tuning.capsule_height / 2.0 + safe_margin)
	query.transform = Transform3D(Basis.IDENTITY, middle)
	query.motion = motion
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	return space.cast_motion(query)[0] >= 1.0


## What the line from `from` to `to` meets first among the blocks the body collides with;
## from inside a block, with `from_inside`, a hit without a normal. Empty if nothing.
func _first_hit(from: Vector3, to: Vector3, from_inside: bool) -> Dictionary:
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, collision_mask, [get_rid()]
	)
	ray.hit_from_inside = from_inside
	return get_world_3d().direct_space_state.intersect_ray(ray)


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


## What is under the reticle while the runner aims: the first block or target on the
## line from the camera through the centre of the screen, as far as twice the range of a
## shot beyond the camera's arm; or, when the intent gives a direction to aim at, on the
## line from the runner's eyes that way. A target is a body that holds the identity of its
## target (SabotageTarget.META) and of its lane (SabotageTarget.LANE_META); its distance
## is measured from the runner's eyes.
func _observe_the_aim(intent: MoveIntent) -> AimFacts:
	if not intent.aim_held:
		return AimFacts.new()
	if not intent.aim_direction.is_zero_approx():
		return aim_facts_towards(intent.aim_direction)
	var eye: Transform3D = camera_rig.camera().global_transform
	return _aim_facts_on_the_line(eye.origin, -eye.basis.z)


## The first block or target on the line from `from` in `towards`, as far as twice the
## range of a shot beyond the camera's arm, its distance measured from the runner's eyes.
func _aim_facts_on_the_line(from: Vector3, towards: Vector3) -> AimFacts:
	var eyes: Vector3 = global_position + Vector3.UP * tuning.camera_look_height
	var reach: float = 2.0 * tuning.shot_range + tuning.camera_distance
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + towards * reach, AIM_MASK, [get_rid()]
	)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return AimFacts.new()
	var collider: Object = hit["collider"]
	var target: int = collider.get_meta(SabotageTarget.META, SabotageTarget.NO_TARGET)
	var lane: int = collider.get_meta(SabotageTarget.LANE_META, 0)
	var point: Vector3 = hit["position"]
	return AimFacts.new(target, eyes.distance_to(point), lane)


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


## In a wall run, the character rolls its whole body, its feet towards the wall and its
## head away from it, as RunnerAnimation says, and straightens up when the wall run is
## over; the capsule one sees leans towards the wall instead, at the pace it turns.
func _lean_along_the_wall(delta: float) -> void:
	if _character != null:
		_lean = RunnerAnimation.wall_run_roll(_lean, animation.wall_side, delta, tuning)
		if motor.state == RunnerMotor.State.WALL_RUNNING:
			_wall_run_locomotion = animation.locomotion
			if is_finite(_wall_distance):
				_wall_run_distance = _wall_distance
		return
	var away: Vector3 = motor.wall_run_normal()
	var lean: float = 0.0
	if not away.is_zero_approx():
		# Rolling the body to the left (a positive angle) leans it towards a wall at its
		# left, whose normal points to its right.
		var right: Vector3 = _facing().cross(Vector3.UP)
		lean = deg_to_rad(tuning.wall_run_lean) * signf(away.dot(right))
	_lean = rotate_toward(_lean, lean, tuning.turn_speed * delta)


## Places the visible body: where it looks, how it leans (the capsule about its feet; the
## character rolled about the middle of its body and moved across against the wall of the
## wall run, WallRunPose); in a trick, read from the motor, twisted around its own axis
## and turned around the axis of the flip, through the middle of the body. A trick over
## leaves it upright, and so does a crash, at once.
func _pose() -> void:
	var leaning: Transform3D = Transform3D(Basis(Vector3.BACK, _lean), Vector3.ZERO)
	if _character != null:
		leaning = _character.placed_against_the_wall(
			_lean, _wall_run_distance, _wall_run_locomotion
		)
	var body: Transform3D = Transform3D(Basis(Vector3.UP, _yaw), Vector3.ZERO) * leaning
	var trick: AirTrick = motor.current_trick()
	if trick != null:
		body = body * Transform3D(Basis(Vector3.UP, trick.twist_angle()), Vector3.ZERO)
		var flip: Basis = Basis(trick.axis, trick.flip_angle())
		var middle: Vector3 = Vector3.UP * _capsule_height() / 2.0
		body = Transform3D(flip, middle - flip * middle) * body
	_visual.transform = body
