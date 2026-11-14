class_name GestureHand
extends RefCounted
## A hand on the pad of a trick, for the tests of the drawing (game/core): the motions of a
## mouse or of a right stick, step by step, brought to the scale of the pad the way the
## player layer brings them (InputIntentSource): pixels times the mouse scale; the stick
## past its dead zone, as Input.get_vector gives it, times the stick speed, the stick back
## in its dead zone letting go of the pad. Motions are in the axes of the screen: x to the
## right, y down.

const STEP: float = 1.0 / 60.0


## The mouse moves by each of `pixels`, one per fixed step.
static func mouse(gesture: TrickGesture, pixels: Array) -> void:
	for motion: Vector2 in pixels:
		gesture.step(motion * gesture.tuning.trick_pad_mouse_scale, STEP)


## The right stick is pushed to each of `deflections`, one per fixed step.
static func stick(gesture: TrickGesture, deflections: Array) -> void:
	var tuning: MovementTuning = gesture.tuning
	var before: Vector2 = Vector2.ZERO
	for raw: Vector2 in deflections:
		var pushed: Vector2 = Vector2.ZERO
		if raw.length() > tuning.stick_deadzone:
			var strength: float = inverse_lerp(tuning.stick_deadzone, 1.0, raw.length())
			pushed = raw.normalized() * clampf(strength, 0.0, 1.0)
		var let_go: bool = pushed.is_zero_approx() and not before.is_zero_approx()
		gesture.step(pushed * tuning.trick_pad_stick_speed * STEP, STEP, let_go)
		before = pushed


## What the drawing reads, in words: the name of the recipe, CONTEXT when nothing was
## drawn, NOTHING when it cannot be read.
static func read(gesture: TrickGesture) -> String:
	var recipe: TrickRecipe = gesture.recipe()
	if recipe == null:
		return "NOTHING"
	if recipe.context:
		return "CONTEXT"
	return recipe.name()


## A stroke towards `way`, `total` long, over `steps`, fast in its middle as a hand goes.
static func bell(way: Vector2, total: float, steps: int) -> Array:
	var motions: Array = []
	var sum: float = 0.0
	for index: int in steps:
		sum += sin(PI * (index + 0.5) / steps)
	for index: int in steps:
		motions.append(way * total * sin(PI * (index + 0.5) / steps) / sum)
	return motions


## An arc of `radius` that starts towards `start` and turns by `degrees` (positive:
## clockwise on the screen) over `steps`.
static func arc(start: Vector2, degrees: float, radius: float, steps: int) -> Array:
	var motions: Array = []
	var turn: float = deg_to_rad(degrees) / steps
	var chord: float = 2.0 * radius * sin(absf(turn) / 2.0)
	for index: int in steps:
		motions.append(start.rotated(turn * (index + 0.5)) * chord)
	return motions


## The stick rolled along its rim from `start`, by `degrees`, over `steps`.
static func roll(start: Vector2, degrees: float, steps: int) -> Array:
	var deflections: Array = []
	for index: int in steps:
		deflections.append(start.rotated(deg_to_rad(degrees) * (index + 1) / steps))
	return deflections


## The same motion or deflection `steps` times.
static func hold(value: Vector2, steps: int) -> Array:
	var values: Array = []
	for index: int in steps:
		values.append(value)
	return values


## Nothing for `steps`: the hand still, or the stick in its dead zone.
static func still(steps: int) -> Array:
	return hold(Vector2.ZERO, steps)
