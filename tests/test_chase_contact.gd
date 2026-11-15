extends GutTest
## The capsules of the chase (Player.axis_of, game/player) as the reach of a gesture of the
## cat measures them (Tag.reaches, docs/specs/chase-tag.md): the least distance between
## their axes, along the ground and up and down, less their radii together: the gap between
## the two bodies. The bodies touching alone catch nothing (test_chase_tag.gd): a gesture
## must reach.

const HEIGHT: float = 1.8
const RADIUS: float = 0.35
## The reach of a gesture, and a cone that leaves out no way.
const REACH: float = 1.0
const ANY_WAY: float = 360.0


func test_two_capsules_one_above_the_other_are_in_reach_only_when_close() -> void:
	var low: CharacterBody3D = _add_body(Vector3.ZERO)
	var high: CharacterBody3D = _add_body(Vector3(0.0, 3.0, 0.0))

	assert_false(_in_reach(low, high), "on the same vertical, 3 m apart: out of reach")
	assert_false(_in_reach(high, low), "whichever is the cat")

	high.position.y = HEIGHT + REACH + 0.1
	assert_false(_in_reach(low, high), "its feet 0.1 m beyond the reach above the head")
	high.position.y = HEIGHT + REACH - 0.1
	assert_true(_in_reach(low, high), "0.1 m within it: in reach")


func test_two_capsules_side_by_side_are_in_reach_from_body_to_body() -> void:
	var cat: CharacterBody3D = _add_body(Vector3.ZERO)
	var mouse: CharacterBody3D = _add_body(Vector3(2.0 * RADIUS + REACH + 0.01, 0.0, 0.0))
	assert_false(_in_reach(cat, mouse), "just beyond the reach: out of it")
	mouse.position.x = 2.0 * RADIUS + REACH - 0.01
	assert_true(_in_reach(cat, mouse), "just within it: in reach")


## Whether `mouse` is within the reach of a gesture of `cat`.
func _in_reach(cat: CharacterBody3D, mouse: CharacterBody3D) -> bool:
	var radii: float = Player.radius_of(cat) + Player.radius_of(mouse)
	return Tag.reaches(
		Player.axis_of(cat), Player.axis_of(mouse), radii, Vector3.FORWARD, REACH, ANY_WAY
	)


## An upright capsule whose feet are at `feet`, as a runner's.
func _add_body(feet: Vector3) -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.height = HEIGHT
	capsule.radius = RADIUS
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = HEIGHT / 2.0
	body.add_child(collider)
	body.position = feet
	add_child_autofree(body)
	return body
