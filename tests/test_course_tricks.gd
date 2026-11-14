extends CourseTest
## The aerial tricks on the test course (game/levels), played with the real inputs: key,
## button and stick events go through the input map of project.godot to the runner's own
## intent source, step by step, in the real physics. Faster than real time with the same
## fixed step of 1/60 s (see ReplayTest).

## Steps to run up before the jump, then the steps of the jump at which a finger acts,
## counted from the take-off: the trick pressed with the back held, the trick released
## in the middle of its first turn, the jump released past the top of the jump and
## tapped again for a twist. An event sent as a step starts is read by the runner at the
## step after: every finger acts one step later, and the gaps stay the same.
const RUN_UP_STEPS: int = 30
const TRICK_PRESS: int = 2
const TRICK_RELEASE: int = 15
const JUMP_RELEASE: int = 21
const TWIST_PRESS: int = 23
const TWIST_RELEASE: int = 25
## Steps after the take-off by which the runner has landed.
const FLIGHT_STEPS: int = 60
const BACKFLIP_FULL: String = "BACKFLIP FULL"
## The left stick, along its vertical axis: -1 pushes forward, 1 pulls back.
const STICK: JoyAxis = JOY_AXIS_LEFT_Y
const GAME_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"slide", &"trick"
]


## What the course paid for the tricks of its runner, step by step.
class TrickWatch:
	var paid: Array[AirTrick] = []
	var crashes: int = 0

	var _runner: Player

	func _init(runner: Player) -> void:
		_runner = runner
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		for event: RunnerEvent in _runner.motor.events:
			if event.kind == RunnerEvent.Kind.TRICK:
				paid.append(event.trick)
			crashes += int(event.kind == RunnerEvent.Kind.CRASH)


func after_each() -> void:
	for key: Key in [KEY_W, KEY_S, KEY_SPACE]:
		_send(_key(key, false))
	_send(_key(KEY_SHIFT, false, KEY_LOCATION_LEFT))
	for button: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER]:
		_send(_button(button, false))
	_send(_stick(0.0))
	for action: StringName in GAME_ACTIONS:
		Input.action_release(action)


func test_a_backflip_on_the_keyboard_in_the_real_physics() -> void:
	var fingers: Dictionary[int, Array] = {
		0: [_key(KEY_W, true)],
		RUN_UP_STEPS: [_key(KEY_SPACE, true), _key(KEY_W, false), _key(KEY_S, true)],
		RUN_UP_STEPS + TRICK_PRESS: [_key(KEY_SHIFT, true, KEY_LOCATION_LEFT)],
		RUN_UP_STEPS + TRICK_RELEASE: [_key(KEY_SHIFT, false, KEY_LOCATION_LEFT)],
		RUN_UP_STEPS + JUMP_RELEASE: [_key(KEY_SPACE, false)],
		RUN_UP_STEPS + TWIST_PRESS: [_key(KEY_SPACE, true)],
		RUN_UP_STEPS + TWIST_RELEASE: [_key(KEY_SPACE, false)],
	}

	await _assert_a_backflip_full_with(fingers)


func test_a_backflip_on_the_gamepad_in_the_real_physics() -> void:
	# The jump on A, the twist tapped on LB, the other button of the jump.
	var fingers: Dictionary[int, Array] = {
		0: [_stick(-1.0)],
		RUN_UP_STEPS: [_button(JOY_BUTTON_A, true), _stick(1.0)],
		RUN_UP_STEPS + TRICK_PRESS: [_button(JOY_BUTTON_X, true)],
		RUN_UP_STEPS + TRICK_RELEASE: [_button(JOY_BUTTON_X, false)],
		RUN_UP_STEPS + JUMP_RELEASE: [_button(JOY_BUTTON_A, false)],
		RUN_UP_STEPS + TWIST_PRESS: [_button(JOY_BUTTON_LEFT_SHOULDER, true)],
		RUN_UP_STEPS + TWIST_RELEASE: [_button(JOY_BUTTON_LEFT_SHOULDER, false)],
	}

	await _assert_a_backflip_full_with(fingers)


## On a fresh course, the runner at rest at its first checkpoint, led by its own inputs:
## plays `fingers` (the events sent at each step) and checks that the landing paid a
## backflip with a twist, and nothing else.
func _assert_a_backflip_full_with(fingers: Dictionary[int, Array]) -> void:
	var course: Course = _add_course()
	await _wait_steps(SETTLE_STEPS)
	var runner: Player = course.player
	assert_true(runner.intent_source is InputIntentSource, "the runner reads the real inputs")
	assert_true(runner.is_on_floor(), "a runner on the course")
	var watch: TrickWatch = TrickWatch.new(runner)
	var backflip: int = -1

	for step: int in RUN_UP_STEPS + FLIGHT_STEPS:
		await get_tree().physics_frame
		for event: InputEvent in fingers.get(step, []):
			_send(event)
		if step == RUN_UP_STEPS + TRICK_RELEASE:
			var trick: AirTrick = runner.motor.current_trick()
			assert_true(runner.motor.is_in_a_trick(), "a trick under way in the air")
			backflip = int(trick != null and trick.flip == AirTrick.Flip.BACKFLIP)
			var hud: Label = course.get_node("Hud/FlowHud").get_node("%TrickLabel") as Label
			assert_eq(hud.text, "BACKFLIP", "named on the HUD of the course")
	await _wait_steps(SETTLE_STEPS)

	assert_eq(backflip, 1, "a backflip, pulled back while running ahead")
	assert_eq(watch.crashes, 0, "no crash")
	assert_eq(watch.paid.size(), 1, "the landing paid one trick")
	if watch.paid.size() == 1:
		assert_eq(watch.paid[0].name(), BACKFLIP_FULL, "a backflip with a twist")
	assert_eq(course.flow.tricks_landed, 1, "counted by the flow")
	assert_true(runner.is_on_floor(), "the runner stands on the course")


## Gives an input event to the engine as the device would, at once.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(
	physical: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED
) -> InputEvent:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical
	event.location = location
	event.pressed = pressed
	return event


func _button(button: JoyButton, pressed: bool) -> InputEvent:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _stick(value: float) -> InputEvent:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = STICK
	event.axis_value = value
	return event
