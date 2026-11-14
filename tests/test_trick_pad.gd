extends GutTest
## The pad of the trick on the screen (game/ui): while the trick button is held, a round
## pad at the centre of the screen draws the trace of the drawing (TrickGesture) at its
## scale, marks the elements that counted, names the recipe, and shows by the colour and
## the thickness of its border that the trick is complete; it is hidden once the button
## is released. The tuning is the fixed one of MotorBody.

const PAD_SCENE: PackedScene = preload("res://game/ui/trick_pad.tscn")
const STEP: float = 1.0 / 60.0

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_pad_shows_the_trace_and_validates_the_trick() -> void:
	var body: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, _tuning.top_speed)
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	var pad: TrickPad = _add_pad(body, gesture)
	pad.refresh()
	assert_false(pad.visible, "nothing held: no pad")

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


func _add_pad(body: MotorBody, gesture: TrickGesture) -> TrickPad:
	var pad: TrickPad = PAD_SCENE.instantiate() as TrickPad
	pad.motor = body.motor
	pad.gesture = gesture
	add_child_autofree(pad)
	return pad


## The mouse moves by each of `pixels`, a fixed step each, the trick button held; the
## runner plays its step and the pad shows it.
func _draw(body: MotorBody, gesture: TrickGesture, pad: TrickPad, pixels: Array) -> void:
	for motion: Vector2 in pixels:
		gesture.step(motion * _tuning.trick_pad_mouse_scale, STEP)
		var drawing: MoveIntent = MoveIntent.new()
		drawing.direction = Vector3.FORWARD
		drawing.trick_held = true
		drawing.trick_recipe = gesture.recipe()
		body.step(drawing)
		pad.refresh()


func _kinds(pad: TrickPad) -> Array[TrickGesture.MarkKind]:
	var kinds: Array[TrickGesture.MarkKind] = []
	for mark: TrickGesture.Mark in pad.marks_shown():
		kinds.append(mark.kind)
	return kinds
