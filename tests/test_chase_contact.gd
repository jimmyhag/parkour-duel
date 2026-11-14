extends GutTest
## The contact of the chase (Chase.touch, game/levels): two upright capsules touch when the
## least distance between their axes is no more than their radii together, along the
## ground and up and down.

const HEIGHT: float = 1.8
const RADIUS: float = 0.35


func test_two_capsules_one_above_the_other_touch_only_when_close() -> void:
	var low: CharacterBody3D = _add_body(Vector3.ZERO)
	var high: CharacterBody3D = _add_body(Vector3(0.0, 3.0, 0.0))

	assert_false(Chase.touch(low, high), "on the same vertical, 3 m apart: no contact")
	assert_false(Chase.touch(high, low), "whichever is asked first")

	high.position.y = HEIGHT + 0.1
	assert_false(Chase.touch(low, high), "the feet 0.1 m above the head: no contact")
	high.position.y = HEIGHT - 0.1
	assert_true(Chase.touch(low, high), "the feet 0.1 m under the head: a contact")


func test_two_capsules_side_by_side_touch_at_their_radii() -> void:
	var first: CharacterBody3D = _add_body(Vector3.ZERO)
	var second: CharacterBody3D = _add_body(Vector3(2.0 * RADIUS + 0.01, 0.0, 0.0))
	assert_false(Chase.touch(first, second), "just apart: no contact")
	second.position.x = 2.0 * RADIUS - 0.01
	assert_true(Chase.touch(first, second), "just touching: a contact")


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
