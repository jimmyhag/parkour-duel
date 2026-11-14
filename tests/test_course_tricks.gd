extends CourseTest
## The aerial tricks on the test course (game/levels), played with the real inputs: key,
## button and stick events go through the input map of project.godot to the runner's own
## intent source, step by step, in the real physics. A turn asks for more height than a
## jump on the flat gives: the runner jumps off the end of the low passage, over the big
## drop, and rolls as it lands. Faster than real time with the same fixed step of 1/60 s
## (see ReplayTest).

## What the fingers do, keyed by the step: RUN as the run starts, ROLL once the runner
## falls close to the floor below, LET_GO once it is down there, the others counted from
## the take-off: the jump, then
## the trick pressed with the back held, both released in the middle of its first turn
## (pulling back all the flight long would turn the runner's speed backwards), the
## jump released past the top of the jump and tapped again for a twist. An event sent as
## a step starts is read by the runner at the step after: every finger acts one step
## later, and the gaps stay the same.
const RUN: int = -1
const ROLL: int = -2
const LET_GO: int = -3
const TAKE_OFF: int = 0
const TRICK_PRESS: int = 2
const TRICK_RELEASE: int = 15
const JUMP_RELEASE: int = 21
const TWIST_PRESS: int = 23
const TWIST_RELEASE: int = 25
## The block the runner jumps off, the one it lands on, how far before the edge it jumps,
## and how high above the floor below it presses the slide for a roll.
const TAKE_OFF_BLOCK: String = "Blocks/LowPassageFloor"
const LANDING_BLOCK: String = "Blocks/BigDropLanding"
const BEFORE_THE_EDGE: float = 0.8
const ROLL_HEIGHT: float = 1.5
## Steps after which a run that did not take off, or a flight, is over.
const MOST_STEPS: int = 240
const FLIGHT_STEPS: int = 80
## Held past the end of its first turn (39 steps after it started), the trick is
## released this many steps after the take-off; the turns are counted at the step
## before, the runner still in the air above the drop. A second course for it stands
## this far aside.
const TWO_TURNS_RELEASE: int = 50
const TWO_TURNS_CHECK: int = 47
const ASIDE: float = 60.0
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
	var rolls: int = 0

	var _runner: Player

	func _init(runner: Player) -> void:
		_runner = runner
		runner.stepped.connect(_on_runner_stepped)

	func _on_runner_stepped(_intent: MoveIntent) -> void:
		for event: RunnerEvent in _runner.motor.events:
			if event.kind == RunnerEvent.Kind.TRICK:
				paid.append(event.trick)
			crashes += int(event.kind == RunnerEvent.Kind.CRASH)
			rolls += int(event.kind == RunnerEvent.Kind.ROLL)


func after_each() -> void:
	for key: Key in [KEY_W, KEY_S, KEY_SPACE]:
		_send(_key(key, false))
	for key: Key in [KEY_SHIFT, KEY_CTRL]:
		_send(_key(key, false, KEY_LOCATION_LEFT))
	for button: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER]:
		_send(_button(button, false))
	_send(_stick(0.0))
	for action: StringName in GAME_ACTIONS:
		Input.action_release(action)


func test_a_backflip_on_the_keyboard_in_the_real_physics() -> void:
	var fingers: Dictionary[int, Array] = {
		RUN: [_key(KEY_W, true)],
		TAKE_OFF: [_key(KEY_SPACE, true), _key(KEY_W, false), _key(KEY_S, true)],
		TRICK_PRESS: [_key(KEY_SHIFT, true, KEY_LOCATION_LEFT)],
		TRICK_RELEASE: [_key(KEY_SHIFT, false, KEY_LOCATION_LEFT), _key(KEY_S, false)],
		JUMP_RELEASE: [_key(KEY_SPACE, false)],
		TWIST_PRESS: [_key(KEY_SPACE, true)],
		TWIST_RELEASE: [_key(KEY_SPACE, false)],
		ROLL: [_key(KEY_CTRL, true, KEY_LOCATION_LEFT)],
		LET_GO: [_key(KEY_CTRL, false, KEY_LOCATION_LEFT)],
	}

	await _assert_a_backflip_full_with(fingers)
	await _assert_two_turns_with(fingers)


func test_a_backflip_on_the_gamepad_in_the_real_physics() -> void:
	# The jump on A, the twist tapped on LB, the other button of the jump.
	var fingers: Dictionary[int, Array] = {
		RUN: [_stick(-1.0)],
		TAKE_OFF: [_button(JOY_BUTTON_A, true), _stick(1.0)],
		TRICK_PRESS: [_button(JOY_BUTTON_X, true)],
		TRICK_RELEASE: [_button(JOY_BUTTON_X, false), _stick(0.0)],
		JUMP_RELEASE: [_button(JOY_BUTTON_A, false)],
		TWIST_PRESS: [_button(JOY_BUTTON_LEFT_SHOULDER, true)],
		TWIST_RELEASE: [_button(JOY_BUTTON_LEFT_SHOULDER, false)],
		ROLL: [_button(JOY_BUTTON_B, true)],
		LET_GO: [_button(JOY_BUTTON_B, false)],
	}

	await _assert_a_backflip_full_with(fingers)
	await _assert_two_turns_with(fingers)


## On a fresh course, the runner at rest at the checkpoint of the big drop, led by its
## own inputs: plays `fingers` and checks that the landing paid a backflip with a twist,
## and nothing else.
func _assert_a_backflip_full_with(fingers: Dictionary[int, Array]) -> void:
	var course: Course = _add_course()
	_start_at(course, BIG_DROP)
	await _wait_steps(SETTLE_STEPS)
	var runner: Player = course.player
	assert_true(runner.intent_source is InputIntentSource, "the runner reads the real inputs")
	assert_true(runner.is_on_floor(), "a runner on the course")
	var edge: float = _bounds_of(course.get_node(TAKE_OFF_BLOCK)).position.z
	var below: float = _bounds_of(course.get_node(LANDING_BLOCK)).end.y
	var watch: TrickWatch = TrickWatch.new(runner)
	var backflip: int = -1
	var take_off: int = -1
	var rolled: bool = false
	var let_go: bool = false

	for step: int in MOST_STEPS:
		await get_tree().physics_frame
		if step == 0:
			_send_all(fingers[RUN])
		if take_off < 0 and runner.global_position.z <= edge + BEFORE_THE_EDGE:
			take_off = step
		if take_off < 0:
			continue
		if fingers.has(step - take_off):
			_send_all(fingers[step - take_off])
		var falling: bool = runner.velocity.y < 0.0
		if not rolled and falling and runner.global_position.y < below + ROLL_HEIGHT:
			_send_all(fingers[ROLL])
			rolled = true
		if rolled and not let_go and runner.is_on_floor():
			_send_all(fingers[LET_GO])
			let_go = true
		if step - take_off == TRICK_RELEASE:
			var trick: AirTrick = runner.motor.current_trick()
			assert_true(runner.motor.is_in_a_trick(), "a trick under way in the air")
			backflip = int(trick != null and trick.flip == AirTrick.Flip.BACKFLIP)
			var hud: Label = course.get_node("Hud/FlowHud").get_node("%TrickLabel") as Label
			assert_eq(hud.text, "BACKFLIP", "named on the HUD of the course")
		if step - take_off == FLIGHT_STEPS:
			break
	await _wait_steps(SETTLE_STEPS)

	assert_gt(take_off, 0, "the runner ran to the edge and jumped")
	assert_eq(backflip, 1, "a backflip, pulled back while running ahead")
	assert_eq(watch.crashes, 0, "no crash")
	assert_eq(watch.rolls, 1, "a roll at the foot of the drop")
	assert_eq(watch.paid.size(), 1, "the landing paid one trick")
	if watch.paid.size() == 1:
		assert_eq(watch.paid[0].name(), BACKFLIP_FULL, "a backflip with a twist")
	assert_eq(course.flow.tricks_landed, 1, "counted by the flow")
	assert_true(runner.is_on_floor(), "the runner stands on the course")
	assert_almost_eq(runner.global_position.y, below, NEAR, "on the floor below")


## On a second course, the same fingers but the trick held past the end of its first
## turn: a second turn has started while the runner is still in the air.
func _assert_two_turns_with(fingers: Dictionary[int, Array]) -> void:
	var held: Dictionary[int, Array] = fingers.duplicate()
	held[TWO_TURNS_RELEASE] = fingers[TRICK_RELEASE]
	held.erase(TRICK_RELEASE)
	var course: Course = _add_course(ASIDE)
	_start_at(course, BIG_DROP)
	await _wait_steps(SETTLE_STEPS)
	var runner: Player = course.player
	var edge: float = _bounds_of(course.get_node(TAKE_OFF_BLOCK)).position.z
	var take_off: int = -1
	var turns: int = 0
	var in_the_air: bool = false
	for step: int in MOST_STEPS:
		await get_tree().physics_frame
		if step == 0:
			_send_all(held[RUN])
		if take_off < 0 and runner.global_position.z <= edge + BEFORE_THE_EDGE:
			take_off = step
		if take_off < 0:
			continue
		if held.has(step - take_off):
			_send_all(held[step - take_off])
		if step - take_off == TWO_TURNS_CHECK:
			var trick: AirTrick = runner.motor.current_trick()
			turns = 0 if trick == null else trick.turns
			in_the_air = not runner.is_on_floor() and runner.motor.is_in_a_trick()
			break

	assert_true(in_the_air, "held: still in the trick, in the air")
	assert_eq(turns, 2, "held past the end of the first turn: a second one started")


func _send_all(events: Array) -> void:
	for event: InputEvent in events:
		_send(event)


## Gives an input event to the engine as the device would, at once.
func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## The box that holds a block, in the world.
func _bounds_of(block: Node) -> AABB:
	var collider: CollisionShape3D = block.get_node("CollisionShape3D") as CollisionShape3D
	return collider.global_transform * collider.shape.get_debug_mesh().get_aabb()


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
