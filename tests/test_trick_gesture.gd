extends GutTest
## The drawing of a trick (game/core): the motions of the pad, step by step, read as a
## recipe: a quick stroke chooses the flip, the same stroke again adds a turn, a half
## circle adds a twist, a circle alone is a spin, and what cannot be read is nothing. The
## pad has the axes of the screen: x to the right, y down. The tuning is the fixed one of
## MotorBody.

const STEP: float = 1.0 / 60.0
const PROJECT_TUNING: String = "res://game/core/movement_tuning.tres"
const UP: Vector2 = Vector2.UP
const DOWN: Vector2 = Vector2.DOWN
const LEFT: Vector2 = Vector2.LEFT
const RIGHT: Vector2 = Vector2.RIGHT
const FRONT_FLIP: TrickRecipe.Flip = TrickRecipe.Flip.FRONT_FLIP
const BACKFLIP: TrickRecipe.Flip = TrickRecipe.Flip.BACKFLIP
const SIDE_FLIP: TrickRecipe.Flip = TrickRecipe.Flip.SIDE_FLIP
const SPIN: TrickRecipe.Flip = TrickRecipe.Flip.SPIN
## A quick stroke, in units of the pad, and the steps it takes.
const STROKE: float = 1.2
const STROKE_STEPS: int = 6
## A half circle: its radius, in units of the pad, and the steps it takes.
const RADIUS: float = 0.5
const HALF_CIRCLE_STEPS: int = 12
## Steps of a pause between two elements: a little more than the pause of the tuning.
const PAUSE_STEPS: int = 6

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_a_quick_stroke_chooses_the_flip() -> void:
	var directions: Array[Vector2] = [UP, DOWN, LEFT, RIGHT]
	var flips: Array[TrickRecipe.Flip] = [FRONT_FLIP, BACKFLIP, SIDE_FLIP, SIDE_FLIP]
	var sides: Array[int] = [1, 1, -1, 1]
	for index: int in directions.size():
		var context: String = "a stroke %s" % directions[index]
		var gesture: TrickGesture = TrickGesture.new(_tuning)
		assert_true(_is_blank(gesture), context + ": an empty drawing")

		_stroke(gesture, directions[index])

		_assert_recipe(gesture, flips[index], 1, 0, context)
		if flips[index] == SIDE_FLIP and gesture.recipe() != null:
			assert_eq(gesture.recipe().side, sides[index], context + ": to that side")

	# A hand is not a ruler: a stroke 30 degrees off, slightly bent, slowing down at its
	# end as a stick that comes back, is still read.
	var sloppy: TrickGesture = TrickGesture.new(_tuning)
	for step: int in STROKE_STEPS:
		var bend: float = deg_to_rad(30.0 - 4.0 * step)
		var speed: float = STROKE / STROKE_STEPS * (1.4 - 0.15 * step)
		sloppy.step(DOWN.rotated(bend) * speed, STEP)
	for step: int in PAUSE_STEPS:
		sloppy.step(Vector2.ZERO, STEP)
	_assert_recipe(sloppy, BACKFLIP, 1, 0, "a sloppy stroke down")


func test_the_same_stroke_repeated_adds_a_turn() -> void:
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	_stroke(gesture, DOWN)
	_assert_recipe(gesture, BACKFLIP, 1, 0, "a drawing that read a backflip")

	_pause(gesture)
	_stroke(gesture, DOWN)
	_assert_recipe(gesture, BACKFLIP, 2, 0, "the stroke again: a double")
	_pause(gesture)
	_stroke(gesture, DOWN)
	_assert_recipe(gesture, BACKFLIP, 3, 0, "and again: a triple")
	_pause(gesture)
	_stroke(gesture, DOWN)
	_assert_recipe(gesture, BACKFLIP, 3, 0, "and not more")
	assert_eq(gesture.recipe().name(), "TRIPLE BACKFLIP")

	# The hand that goes back up between two strokes down: going back is not read.
	# Without a pause: the sharp turn back ends each stroke.
	var back_and_forth: TrickGesture = TrickGesture.new(_tuning)
	_stroke(back_and_forth, DOWN, false)
	_stroke(back_and_forth, UP, false)
	_stroke(back_and_forth, DOWN, false)
	_assert_recipe(back_and_forth, BACKFLIP, 2, 0, "down, back up, down: a double")


func test_a_half_circle_adds_a_twist() -> void:
	var gesture: TrickGesture = TrickGesture.new(_tuning)
	_stroke(gesture, DOWN)
	_assert_recipe(gesture, BACKFLIP, 1, 0, "a drawing that read a backflip")

	_pause(gesture)
	_arc(gesture, RIGHT, 180.0)
	_assert_recipe(gesture, BACKFLIP, 1, 1, "a half circle: one twist")
	_pause(gesture)
	_arc(gesture, LEFT, -180.0)
	_assert_recipe(gesture, BACKFLIP, 1, 2, "a second one: two twists")
	_pause(gesture)
	_arc(gesture, RIGHT, 180.0)
	_assert_recipe(gesture, BACKFLIP, 1, 2, "not more for one turn")
	assert_eq(gesture.recipe().name(), "BACKFLIP DOUBLE FULL")

	# The half circle drawn on from the stroke, without a pause, as a J; and a sloppy one,
	# three quarters of a half circle.
	var flowing: TrickGesture = TrickGesture.new(_tuning)
	_stroke(flowing, DOWN, false)
	_arc(flowing, DOWN, 180.0)
	_assert_recipe(flowing, BACKFLIP, 1, 1, "a stroke that curls into a half circle")
	var sloppy: TrickGesture = TrickGesture.new(_tuning)
	_stroke(sloppy, UP)
	_arc(sloppy, LEFT, -135.0)
	_assert_recipe(sloppy, FRONT_FLIP, 1, 1, "a front flip and a sloppy half circle")


func test_no_twist_on_a_side_flip_or_a_spin() -> void:
	var side_flip: TrickGesture = TrickGesture.new(_tuning)
	_stroke(side_flip, LEFT)
	_assert_recipe(side_flip, SIDE_FLIP, 1, 0, "a drawing that read a side flip")
	var spin: TrickGesture = TrickGesture.new(_tuning)
	_arc(spin, RIGHT, 360.0, 2 * HALF_CIRCLE_STEPS)
	_assert_recipe(spin, SPIN, 1, 0, "a drawing that read a spin")

	for gesture: TrickGesture in [side_flip, spin]:
		_pause(gesture)
		_arc(gesture, UP, 180.0)

	_assert_recipe(side_flip, SIDE_FLIP, 1, 0, "the side flip has no twist")
	_assert_recipe(spin, SPIN, 1, 0, "nor the spin")


func test_a_circle_alone_is_a_spin() -> void:
	# Both ways, from anywhere, and a little short of a whole turn.
	var starts: Array[Vector2] = [RIGHT, DOWN, LEFT]
	var angles: Array[float] = [360.0, -360.0, 300.0]
	for index: int in starts.size():
		var context: String = "a circle of %d degrees from %s" % [angles[index], starts[index]]
		var gesture: TrickGesture = TrickGesture.new(_tuning)

		_arc(gesture, starts[index], angles[index], 2 * HALF_CIRCLE_STEPS)

		_assert_recipe(gesture, SPIN, 1, 0, context)
		if gesture.recipe() != null:
			assert_eq(gesture.recipe().name(), "360", context + ": named by its degrees")

	# A second circle makes a 720, a third a 1080, and not more; a half circle adds nothing.
	var spin: TrickGesture = TrickGesture.new(_tuning)
	_arc(spin, RIGHT, 360.0, 2 * HALF_CIRCLE_STEPS)
	var names: Array[String] = []
	for circle: int in 3:
		_arc(spin, RIGHT, 360.0, 2 * HALF_CIRCLE_STEPS)
		names.append("" if spin.recipe() == null else spin.recipe().name())
	_arc(spin, RIGHT, 180.0)
	names.append("" if spin.recipe() == null else spin.recipe().name())
	assert_eq(names, ["720", "1080", "1080", "1080"] as Array[String], "more circles")
	_assert_recipe(spin, SPIN, 3, 0, "three circles at most")


func test_a_stick_flick_that_comes_back_fast_is_read() -> void:
	# With the tuning of the project, the one the hand plays with.
	var tuning: MovementTuning = load(PROJECT_TUNING) as MovementTuning
	var flicks: Dictionary[String, Array] = {
		"pushed down and let go in 0.1 s":
		[Vector2.DOWN * 0.5] + GestureHand.hold(Vector2.DOWN, 4) + [Vector2.DOWN * 0.5],
		"pushed at 60 % for 0.1 s": GestureHand.hold(Vector2.DOWN * 0.6, 6),
	}
	for what: String in flicks:
		var gesture: TrickGesture = TrickGesture.new(tuning)

		GestureHand.stick(gesture, flicks[what] + GestureHand.still(6))

		assert_eq(GestureHand.read(gesture), "BACKFLIP", what)

	# Back in its dead zone, the flick is over at once: two flicks one step apart.
	var double: TrickGesture = TrickGesture.new(tuning)
	var flick: Array = GestureHand.hold(Vector2.DOWN, 6)
	GestureHand.stick(double, flick + GestureHand.still(1) + flick + GestureHand.still(6))
	assert_eq(GestureHand.read(double), "DOUBLE BACKFLIP", "two flicks a step apart")


func test_an_arc_after_the_flip_is_a_twist() -> void:
	var tuning: MovementTuning = load(PROJECT_TUNING) as MovementTuning
	var arc: float = tuning.trick_gesture_half_circle_angle
	assert_eq(arc, 100.0, "the least arc of a twist")
	# On the mouse: a stroke down, a pause, an arc of 100 degrees without a straight part.
	var mouse: TrickGesture = TrickGesture.new(tuning)
	var down: Array = GestureHand.bell(Vector2.DOWN, 150, 5)
	var pause: Array = GestureHand.still(6)
	GestureHand.mouse(mouse, down + pause + GestureHand.arc(Vector2.RIGHT, arc, 80.0, 8) + pause)
	assert_eq(GestureHand.read(mouse), "BACKFLIP FULL", "on the mouse")
	# On the stick: a flick down, then the stick rolled by 100 degrees.
	var stick: TrickGesture = TrickGesture.new(tuning)
	var flick: Array = GestureHand.hold(Vector2.DOWN, 6) + GestureHand.still(6)
	GestureHand.stick(stick, flick + GestureHand.roll(Vector2.RIGHT, arc, 10) + pause)
	assert_eq(GestureHand.read(stick), "BACKFLIP FULL", "on the stick")
	# And with a straight start: a J.
	var j: TrickGesture = TrickGesture.new(tuning)
	GestureHand.mouse(j, down + GestureHand.arc(Vector2.DOWN, arc + 10.0, 80.0, 8) + pause)
	assert_eq(GestureHand.read(j), "BACKFLIP FULL", "curling out of the stroke")


func test_a_rounded_return_of_the_hand_is_not_a_twist() -> void:
	var tuning: MovementTuning = load(PROJECT_TUNING) as MovementTuning
	var down: Array = GestureHand.bell(Vector2.DOWN, 150, 5)
	var returns: Dictionary[String, Array] = {
		"a tight U-turn":
		GestureHand.arc(Vector2.DOWN, -180.0, 20.0, 4) + GestureHand.bell(Vector2.UP, 130, 5),
		"drifting aside":
		[Vector2(8, 10), Vector2(10, 2), Vector2(6, -8)] + GestureHand.bell(Vector2.UP, 140, 5),
		"rounder":
		(
			[Vector2(5, 15), Vector2(12, 4), Vector2(8, -10), Vector2(2, -25)]
			+ GestureHand.bell(Vector2.UP, 120, 4)
		),
	}
	for what: String in returns:
		var gesture: TrickGesture = TrickGesture.new(tuning)

		GestureHand.mouse(gesture, down + returns[what] + GestureHand.still(6))

		assert_eq(GestureHand.read(gesture), "BACKFLIP", what)


func test_an_unreadable_gesture_starts_nothing() -> void:
	# Too little for a stroke, though more than a hand that holds still.
	var short: TrickGesture = TrickGesture.new(_tuning)
	var too_short: float = _tuning.trick_gesture_stroke_length + _tuning.trick_gesture_still_length
	_stroke(short, DOWN, true, too_short / 2.0)
	assert_null(short.recipe(), "too short for a stroke: nothing is read")
	assert_false(_is_blank(short), "and it is not an empty drawing either")

	# At random: a scribble that goes everywhere and nowhere.
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7
	for attempt: int in 5:
		var scribble: TrickGesture = TrickGesture.new(_tuning)
		for step: int in 60:
			var motion: Vector2 = Vector2.RIGHT.rotated(random.randf() * TAU)
			scribble.step(motion * random.randf_range(0.04, 0.12), STEP)
		assert_null(scribble.recipe(), "scribble %d: nothing is read" % attempt)

	# A half circle alone is no flip.
	var half: TrickGesture = TrickGesture.new(_tuning)
	_arc(half, RIGHT, 180.0)
	assert_null(half.recipe(), "a half circle alone: nothing is read")

	# A hand that holds still, or nearly, draws nothing: the trick of the context.
	var still: TrickGesture = TrickGesture.new(_tuning)
	for step: int in 30:
		still.step(Vector2(0.004, -0.003), STEP)
	assert_true(_is_blank(still), "a hand that hardly moves draws nothing")


## The recipe read is `flip`, with `turns` and `twists`.
func _assert_recipe(
	gesture: TrickGesture, flip: TrickRecipe.Flip, turns: int, twists: int, context: String
) -> void:
	var recipe: TrickRecipe = gesture.recipe()
	assert_not_null(recipe, context + ": a recipe is read")
	if recipe == null:
		return
	assert_false(recipe.context, context + ": a drawn one")
	var read: String = (
		"%s %d %d" % [TrickRecipe.Flip.keys()[recipe.flip], recipe.turns, recipe.twists]
	)
	var expected: String = "%s %d %d" % [TrickRecipe.Flip.keys()[flip], turns, twists]
	assert_eq(read, expected, context)


## Nothing drawn: the recipe is the trick of the context.
func _is_blank(gesture: TrickGesture) -> bool:
	var recipe: TrickRecipe = gesture.recipe()
	return recipe != null and recipe.context


## A quick stroke towards `direction`, `length` long, then a pause if `pause`.
func _stroke(
	gesture: TrickGesture, direction: Vector2, pause: bool = true, length: float = STROKE
) -> void:
	for step: int in STROKE_STEPS:
		gesture.step(direction * length / STROKE_STEPS, STEP)
	if pause:
		_pause(gesture)


## An arc that starts towards `start` and turns by `degrees` (positive: clockwise on the
## screen), then a pause.
func _arc(
	gesture: TrickGesture, start: Vector2, degrees: float, steps: int = HALF_CIRCLE_STEPS
) -> void:
	var turn: float = deg_to_rad(degrees) / steps
	var chord: float = 2.0 * RADIUS * sin(absf(turn) / 2.0)
	for step: int in steps:
		gesture.step(start.rotated(turn * (step + 0.5)) * chord, STEP)
	_pause(gesture)


func _pause(gesture: TrickGesture) -> void:
	for step: int in PAUSE_STEPS:
		gesture.step(Vector2.ZERO, STEP)
