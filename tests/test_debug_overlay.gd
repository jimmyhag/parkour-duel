extends GutTest
## The debug display (game/ui): hidden by default, toggled by its action, and what it
## says of the runner and of its flow.

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


func test_the_debug_display_shows_the_new_states() -> void:
	var motor: RunnerMotor = RunnerMotor.new(MotorBody.fixed_tuning())
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.motor = motor
	add_child_autofree(overlay)
	_trigger(TOGGLE_DEBUG)
	var running: Vector3 = Vector3.FORWARD * motor.tuning.top_speed
	var high: float = motor.tuning.roll_fall_height * 2.0

	var slide: MoveIntent = MoveIntent.new()
	slide.slide_pressed = true
	slide.slide_held = true
	motor.step(slide, _facts(true, running), STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE SLIDING")
	assert_string_contains(overlay.text, "ROLL WINDOW 0.20 s")
	assert_string_contains(overlay.text, "LANDING 0.00 s")

	# A high fall, the slide pressed two steps before the floor: a roll, at its first
	# step out of thirty, ten steps of the window left.
	motor.step(slide, _facts(false, running, high), STEP)
	motor.step(MoveIntent.new(), _facts(false, running, high / 2.0), STEP)
	motor.step(MoveIntent.new(), _facts(true, running), STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE ROLLING")
	assert_string_contains(overlay.text, "ROLL WINDOW 0.17 s")
	assert_string_contains(overlay.text, "LANDING 0.48 s")

	# Another high fall, long after the press: a hard landing, at its first step out of
	# twenty-one.
	for i: int in 20:
		motor.step(MoveIntent.new(), _facts(false, running, high), STEP)
	motor.step(MoveIntent.new(), _facts(true, running), STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE HARD_LANDING")
	assert_string_contains(overlay.text, "ROLL WINDOW 0.00 s")
	assert_string_contains(overlay.text, "LANDING 0.33 s")


func test_the_debug_display_shows_the_wall_states() -> void:
	var motor: RunnerMotor = RunnerMotor.new(MotorBody.fixed_tuning())
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.motor = motor
	add_child_autofree(overlay)
	_trigger(TOGGLE_DEBUG)
	var forward: MoveIntent = MoveIntent.new()
	forward.direction = Vector3.FORWARD
	var running: Vector3 = Vector3.FORWARD * motor.tuning.top_speed
	var high: float = motor.tuning.roll_fall_height

	# In the air against a ledge within reach: a mantle, at its first step out of
	# twenty-one.
	var against_a_ledge: RunnerFacts = _facts(false, Vector3.ZERO, high)
	against_a_ledge.ledge_normal = Vector3.BACK
	against_a_ledge.ledge_height = motor.tuning.mantle_min_height * 1.5
	against_a_ledge.ledge_clear = true
	motor.step(forward, against_a_ledge, STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE MANTLING")
	assert_string_contains(overlay.text, "MANTLE 0.33 s")
	assert_string_contains(overlay.text, "WALL RUN 0.00 s")
	assert_string_contains(overlay.text, "WALL JUMP 0.00 s")
	for i: int in 20:
		motor.step(forward, _facts(i > 10, running, high), STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE GROUNDED")
	assert_string_contains(overlay.text, "MANTLE 0.00 s")

	# Then in the air along a wall: a wall run at its first step out of seventy-two, all
	# of the wall jump grace ahead; one step off the wall, five steps of it are left.
	var beside_a_wall: RunnerFacts = _facts(false, running, high)
	beside_a_wall.ground_clearance = high
	beside_a_wall.wall_id = 1
	beside_a_wall.wall_normal = Vector3.RIGHT
	beside_a_wall.wall_distance = motor.tuning.wall_run_distance / 2.0
	beside_a_wall.wall_height = motor.tuning.wall_run_min_wall_height * 2.0
	motor.step(forward, beside_a_wall, STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE WALL_RUNNING")
	assert_string_contains(overlay.text, "WALL RUN 1.18 s")
	assert_string_contains(overlay.text, "WALL JUMP 0.10 s")
	motor.step(forward, _facts(false, running, high), STEP)
	overlay.refresh()
	assert_string_contains(overlay.text, "STATE FALLING")
	assert_string_contains(overlay.text, "WALL RUN 0.00 s")
	assert_string_contains(overlay.text, "WALL JUMP 0.08 s")


func test_the_debug_display_shows_the_flow() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var flow: FlowState = FlowState.new(tuning, 60)
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	overlay.motor = RunnerMotor.new(tuning)
	overlay.flow = flow
	add_child_autofree(overlay)
	_trigger(TOGGLE_DEBUG)
	# Just under tier 2, then a slide, a jump, a roll and a jump: 2175 points, x2, the
	# jump the second time among the last moves; then half a second on the ground.
	flow.gauge = 1950.0
	var none: Array[RunnerEvent] = []
	for kind: RunnerEvent.Kind in [
		RunnerEvent.Kind.SLIDE, RunnerEvent.Kind.JUMP, RunnerEvent.Kind.ROLL, RunnerEvent.Kind.JUMP
	]:
		var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
		flow.step(events, tuning.top_speed, false)
	for i: int in 30:
		flow.step(none, tuning.top_speed, true)
	assert_true(flow.in_combo(), "a runner in a combo")

	overlay.refresh()

	assert_string_contains(overlay.text, "GAUGE 2175")
	assert_string_contains(overlay.text, "TIER 2")
	assert_string_contains(overlay.text, "CHAIN 1.50 s")
	assert_string_contains(overlay.text, "REPEAT JUMP x2")
	assert_string_contains(overlay.text, "MULTIPLIER x2")
	assert_string_contains(overlay.text, "SPEED BONUS 10 %")


## A runner going at 5 m/s that left the floor one step ago, without jumping.
func _motor_falling_off_a_ledge() -> RunnerMotor:
	var tuning: MovementTuning = MovementTuning.new()
	tuning.fall_gravity = 44.0
	tuning.max_fall_speed = 40.0
	tuning.coyote_time = 0.10
	tuning.jump_buffer_time = 0.12
	tuning.max_horizontal_speed = 22.0
	var motor: RunnerMotor = RunnerMotor.new(tuning)
	var running: Vector3 = Vector3(3.0, 0.0, -4.0)
	var falling: Vector3 = motor.step(MoveIntent.new(), _facts(true, running), STEP)
	motor.step(MoveIntent.new(), _facts(false, running + Vector3.UP * falling.y), STEP)
	return motor


func _facts(on_floor: bool, velocity: Vector3, altitude: float = 0.0) -> RunnerFacts:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.on_floor = on_floor
	facts.velocity = velocity
	facts.altitude = altitude
	return facts


func _trigger(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)
