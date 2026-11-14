extends GutTest
## The pad of the trick on the screen (game/ui): while the trick button is held, a round
## pad at the centre of the screen draws the trace of the drawing (TrickGesture) at its
## scale, marks the elements that counted, names the recipe, and shows by the colour and
## the thickness of its border that the trick is validated, only when it can start; it is
## hidden once the button is released. The tuning is the fixed one of MotorBody.

const PAD_SCENE: PackedScene = preload("res://game/ui/trick_pad.tscn")
const STEP: float = 1.0 / 60.0
const TREMBLING_STEPS: int = 40

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_pad_shows_the_trace_and_validates_the_trick() -> void:
	var body: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, _tuning.top_speed)
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	var pad: TrickPad = _add_pad(body, gesture)
	pad.refresh()
	assert_false(pad.visible, "nothing held: no pad")
	_draw(body, gesture, pad, GestureHand.still(1))
	assert_true(pad.visible, "the button held: the pad is on screen")
	assert_eq(pad.recipe_shown(), "?", "nothing drawn yet: nothing read")

	# A stroke down, a pause, then a half circle, the button held all along.
	_draw(body, gesture, pad, GestureHand.bell(Vector2.DOWN, 150, 5))
	assert_true(pad.visible, "the button held: the pad is on screen")
	assert_eq(pad.trace_shown().size(), gesture.trace().size(), "the trace, point by point")
	assert_false(pad.is_validated(), "the hand still moving: not complete")
	var border: Color = pad.border_color()
	var width: float = pad.border_width()
	_draw(body, gesture, pad, GestureHand.still(6))
	assert_eq(_kinds(pad), [TrickGesture.MarkKind.STROKE], "the stroke marked")
	assert_eq(pad.recipe_shown(), "BACKFLIP")
	assert_true(pad.is_validated(), "the hand at rest: a backflip, complete")
	_draw(body, gesture, pad, GestureHand.arc(Vector2.RIGHT, 90.0, 60.0, 5))
	assert_false(pad.is_validated(), "mid-curve, the trick is not complete")
	assert_eq(pad.border_color(), border, "nor shown so")

	_draw(body, gesture, pad, GestureHand.arc(Vector2.DOWN, 90.0, 60.0, 5) + GestureHand.still(6))

	var kinds: Array[TrickGesture.MarkKind] = [
		TrickGesture.MarkKind.STROKE, TrickGesture.MarkKind.TWIST
	]
	assert_eq(_kinds(pad), kinds, "the stroke, then the arc marked")
	assert_eq(pad.recipe_shown(), "BACKFLIP FULL", "the recipe named")
	assert_true(pad.is_validated(), "the trick complete: validated")
	assert_ne(pad.border_color(), border, "its border changes colour")
	assert_gt(pad.border_width(), width, "and thickness")
	assert_eq(pad.trace_shown().size(), gesture.trace().size(), "the whole trace")
	# At the scale of the recognition: the stroke drawn down, as long as it is on the pad.
	var trace: PackedVector2Array = pad.trace_shown()
	var stroke: Vector2 = trace[5] - trace[0]
	var drawn: Vector2 = gesture.trace()[5] - gesture.trace()[0]
	assert_almost_eq(stroke.angle_to(drawn), 0.0, 0.001, "the same way")
	assert_almost_eq(stroke.length() / drawn.length(), pad.pixels_per_unit(), 0.001, "one scale")


func test_the_pad_disappears_on_release() -> void:
	var body: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, _tuning.top_speed)
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	var pad: TrickPad = _add_pad(body, gesture)
	_draw(body, gesture, pad, GestureHand.bell(Vector2.DOWN, 150, 5) + GestureHand.still(6))
	assert_true(pad.visible, "a runner holding the button, who drew")

	var released: MoveIntent = MoveIntent.new()
	released.direction = Vector3.FORWARD
	released.trick_released = true
	released.trick_recipe = gesture.recipe()
	body.step(released)
	pad.refresh()

	assert_false(pad.visible, "released: the pad is gone")


func test_the_pad_validates_only_what_can_start() -> void:
	# Decision 25 of docs/specs/trick-gestures.md: a runner that aims, then a runner that
	# already did the trick of its jump, draw a backflip; the drawing validates it.
	var aiming: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, _tuning.top_speed)
	var tricked: MotorBody = MotorBody.new(_tuning, 40.0)
	var trick: MoveIntent = MoveIntent.new()
	trick.trick_released = true
	trick.trick_recipe = TrickRecipe.drawn(TrickRecipe.Flip.FRONT_FLIP)
	tricked.step(trick)
	assert_not_null(tricked.motor.current_trick(), "a runner in the trick of its jump")
	var stroke: Array = GestureHand.bell(Vector2.DOWN, 150, 5) + GestureHand.still(8)
	for body: MotorBody in [aiming, tricked]:
		var who: String = "aiming" if body == aiming else "after the trick of its jump"
		var gesture: TrickGesture = TrickGesture.new(_tuning)
		var pad: TrickPad = _add_pad(body, gesture)

		_draw(body, gesture, pad, stroke, body == aiming)

		assert_true(gesture.is_validated(), who + ": the drawing validated a backflip")
		assert_eq(pad.recipe_shown(), "BACKFLIP", who + ": the pad names it")
		assert_false(pad.is_validated(), who + ": but does not validate it")
		assert_eq(pad.border_width(), TrickPad.BORDER_WIDTH, who + ": its border says so")


func test_a_trembling_hand_keeps_the_trick_validated() -> void:
	var body: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, _tuning.top_speed)
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	var pad: TrickPad = _add_pad(body, gesture)
	_draw(body, gesture, pad, GestureHand.bell(Vector2.DOWN, 150, 5) + GestureHand.still(8))
	assert_true(pad.is_validated(), "a backflip validated")

	# A hand that trembles by a pixel or two at every step.
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 11
	for step: int in TREMBLING_STEPS:
		var tremble: Vector2 = Vector2(random.randi_range(-2, 2), random.randi_range(-2, 2))
		_draw(body, gesture, pad, [tremble])
		assert_true(pad.is_validated(), "step %d: still validated" % step)

	assert_eq(pad.recipe_shown(), "BACKFLIP", "still a backflip")
	assert_eq(gesture.validated_recipe().name(), "BACKFLIP", "the trick that starts")


func _add_pad(body: MotorBody, gesture: TrickGesture) -> TrickPad:
	var pad: TrickPad = PAD_SCENE.instantiate() as TrickPad
	pad.motor = body.motor
	pad.gesture = gesture
	add_child_autofree(pad)
	return pad


## The mouse moves by each of `pixels`, a fixed step each, the trick button held (and the
## aim if `aim`); the runner plays its step and the pad shows it.
func _draw(
	body: MotorBody, gesture: TrickGesture, pad: TrickPad, pixels: Array, aim: bool = false
) -> void:
	for motion: Vector2 in pixels:
		gesture.step(motion * GestureHand.pad_units_per_pixel(_tuning), STEP)
		var drawing: MoveIntent = MoveIntent.new()
		drawing.direction = Vector3.FORWARD
		drawing.aim_held = aim
		drawing.trick_held = true
		drawing.trick_recipe = gesture.recipe()
		body.step(drawing)
		pad.refresh()


func _kinds(pad: TrickPad) -> Array[TrickGesture.MarkKind]:
	var kinds: Array[TrickGesture.MarkKind] = []
	for mark: TrickGesture.Mark in pad.marks_shown():
		kinds.append(mark.kind)
	return kinds
