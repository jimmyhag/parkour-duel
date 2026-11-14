extends GutTest
## The targets of the scenery (game/world): four scenes, one per type, that only show
## what the state machine of their target (game/core) says: their object in or out of
## its place, solid or not, highlighted when ready, brighter under the reticle, flashing
## during the warning.

const SCENES: Dictionary[SabotageTarget.Kind, PackedScene] = {
	SabotageTarget.Kind.PLATFORM: preload("res://game/world/falling_platform.tscn"),
	SabotageTarget.Kind.BRIDGE: preload("res://game/world/falling_bridge.tscn"),
	SabotageTarget.Kind.OBSTACLE: preload("res://game/world/falling_obstacle.tscn"),
	SabotageTarget.Kind.BARRIER: preload("res://game/world/rising_barrier.tscn"),
}
const STEPS_PER_SECOND: int = 60
const WARNING_STEPS: int = 36
const WORLD_LAYER: int = 1
const TARGETS_LAYER: int = 3
const NOBODY: Array[int] = []

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_a_ready_target_is_highlighted_and_a_resting_target_is_not() -> void:
	for kind: SabotageTarget.Kind in SCENES:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var ready_one: TargetBlock = _add_block(kind, 1)
		var resting_one: TargetBlock = _add_block(kind, 2)
		_sabotage(resting_one.target)
		while resting_one.target.state != SabotageTarget.State.RESTING:
			resting_one.target.step(NOBODY, true)
		for block: TargetBlock in [ready_one, resting_one]:
			block.follow()
			block.refresh()

		assert_true(_glows(ready_one), context + "the ready one is highlighted")
		assert_false(_glows(resting_one), context + "the resting one is not")
		var colour: Color = _material(ready_one).albedo_color
		assert_ne(colour, _material(resting_one).albedo_color, context + "nor of the same colour")

		# Under the reticle, a ready target is brighter still.
		var energy: float = _material(ready_one).emission_energy_multiplier
		ready_one.focused = true
		ready_one.refresh()
		assert_gt(_material(ready_one).emission_energy_multiplier, energy, context + "focused")


func test_a_target_block_shows_what_its_target_says() -> void:
	for kind: SabotageTarget.Kind in SCENES:
		var context: String = SabotageTarget.Kind.keys()[kind] + ": "
		var block: TargetBlock = _add_block(kind, 1)
		var body: StaticBody3D = block.get_node("Body") as StaticBody3D
		var home: Vector3 = body.global_position
		var leaves: bool = block.target.leaves_its_place()
		var named: int = body.get_meta(SabotageTarget.META, SabotageTarget.NO_TARGET)
		assert_eq(named, 1, context + "its body names its target")
		assert_true(body.get_collision_layer_value(TARGETS_LAYER), context + "it can be shot")
		var solid_at_rest: bool = kind != SabotageTarget.Kind.BARRIER
		var solid: bool = body.get_collision_layer_value(WORLD_LAYER)
		assert_eq(solid, solid_at_rest, context + "solid at rest, but a barrier in the ground")

		# The warning: it flashes, still in its place.
		_sabotage(block.target)
		block.follow()
		var flashes: Array[bool] = []
		for frame: int in 12:
			block.refresh(frame * 0.05)
			flashes.append(_glows(block))
		assert_true(flashes.has(true) and flashes.has(false), context + "it flashes")
		assert_eq(body.global_position, home, context + "in its place during the warning")

		# The effect.
		for step: int in WARNING_STEPS:
			block.target.step(NOBODY, true)
		block.follow()
		block.refresh()
		assert_true(block.target.displaced, context + "sabotaged")
		assert_false(_glows(block), context + "no longer highlighted")
		if leaves:
			assert_false(body.visible, context + "gone")
			assert_false(body.get_collision_layer_value(WORLD_LAYER), context + "it holds nothing")
			assert_false(
				body.get_collision_layer_value(TARGETS_LAYER), context + "nor stops a shot"
			)
		else:
			assert_true(body.visible, context + "there")
			assert_true(body.get_collision_layer_value(WORLD_LAYER), context + "solid on the way")
			assert_eq(body.global_position, home + block.travel, context + "moved onto the way")

		# Back in its place.
		while block.target.displaced:
			block.target.step(NOBODY, true)
		block.follow()
		assert_true(body.visible, context + "back")
		assert_eq(body.global_position, home, context + "in its place")
		var solid_again: bool = body.get_collision_layer_value(WORLD_LAYER)
		assert_eq(solid_again, solid_at_rest, context + "as solid as at rest")


func _add_block(kind: SabotageTarget.Kind, id: int) -> TargetBlock:
	var block: TargetBlock = SCENES[kind].instantiate() as TargetBlock
	block.target_id = id
	block.position.x = id * 20.0
	add_child_autofree(block)
	assert_eq(block.kind, kind, "the scene of a %s" % SabotageTarget.Kind.keys()[kind])
	block.target = SabotageTarget.new(id, block.kind, _tuning, STEPS_PER_SECOND)
	block.follow()
	return block


func _sabotage(target: SabotageTarget) -> void:
	assert_true(target.receive(SabotageMessage.new(7, target.id, 0)), "a target hit")


func _material(block: TargetBlock) -> StandardMaterial3D:
	var mesh: MeshInstance3D = block.get_node("Body/MeshInstance3D") as MeshInstance3D
	return mesh.material_override as StandardMaterial3D


## The block glows: highlighted.
func _glows(block: TargetBlock) -> bool:
	return _material(block).emission_enabled
