extends GutTest
## The debug display (game/ui): hidden by default, toggled by its action.

const OVERLAY_SCENE: PackedScene = preload("res://game/ui/debug_overlay.tscn")
const TOGGLE_DEBUG: StringName = &"toggle_debug"
const STEP: float = 1.0 / 60.0


func test_the_debug_display_appears_and_disappears() -> void:
	var motor: RunnerMotor = _motor_falling_off_a_ledge()
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.motor = motor
	add_child_autofree(overlay)
	assert_false(overlay.visible, "hidden at first")

	_trigger(TOGGLE_DEBUG)

	assert_true(overlay.visible, "shown by its action")
	assert_string_contains(overlay.text, "STATE FALLING")
	assert_string_contains(overlay.text, "SPEED H 5.00 m/s")
	assert_string_contains(overlay.text, "SPEED V %.2f m/s" % motor.velocity.y)
	assert_string_contains(overlay.text, "COYOTE 0.08 s")
	assert_string_contains(overlay.text, "BUFFER 0.00 s")

	_trigger(TOGGLE_DEBUG)

	assert_false(overlay.visible, "hidden again by the same action")


## A runner going at 5 m/s that left the floor one step ago, without jumping.
func _motor_falling_off_a_ledge() -> RunnerMotor:
	var tuning: MovementTuning = MovementTuning.new()
	tuning.fall_gravity = 44.0
	tuning.max_fall_speed = 40.0
	tuning.coyote_time = 0.10
	tuning.jump_buffer_time = 0.12
	var motor: RunnerMotor = RunnerMotor.new(tuning)
	var running: Vector3 = Vector3(3.0, 0.0, -4.0)
	var falling: Vector3 = motor.step(MoveIntent.new(), true, running, STEP)
	motor.step(MoveIntent.new(), false, running + Vector3.UP * falling.y, STEP)
	return motor


func _trigger(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
