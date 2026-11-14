class_name TrickGesture
extends RefCounted
## The drawing of a trick: the motions of the pad, fixed step after fixed step, read as a
## recipe (TrickRecipe). The player layer brings the mouse and the right stick to the one
## scale of the pad, whose axes are those of the screen: x to the right, y down.
##
## The drawing is cut into elements: a pause, or a sharp change of direction, ends one.
## An element is a stroke (it goes mostly one way), a curve (its direction turns: half
## circles), or nothing (too short, or a curve short of half a circle). A stroke that
## curls into a curve without a pause is a stroke, then a curve; a small hook at its end
## is not read. The elements make the recipe: the first stroke chooses the
## flip (up a front flip, down a backflip, left or right a side flip that way); the same
## stroke again adds a turn; a curve after a front flip or a backflip adds a twist per half
## circle; a whole circle before any stroke is a spin; anything else is not read. A hand
## that hardly moves draws nothing: the trick of the context.

## One element of the drawing, as read.
enum Shape { NOTHING, STROKE, CURVE }

## Under this motion in one step, in units of the pad, the pad stands still.
const NOISE: float = 0.004
## A change of direction sharper than this from one moving step to the next ends an
## element, in degrees: going back, as a hand does between two strokes.
const CORNER: float = 90.0
## How far the straight start of an element may turn from its first direction, in
## degrees, and how far a stroke may turn from its start to its end.
const BEND: float = 40.0
const STROKE_TURN: float = 60.0
## The least share of the length of an element its straight start must have to be a
## stroke of its own, before the curve it curls into.
const STROKE_SHARE: float = 0.4

var tuning: MovementTuning

## The elements over, read: their shapes, the way of each stroke and the signed angle of
## each curve, in degrees (positive: clockwise on the screen).
var _shapes: Array[Shape] = []
var _ways: Array[Vector2] = []
var _angles: Array[float] = []
## The motions of the element under way, one per moving step.
var _motions: Array[Vector2] = []
## Moving steps' length since the drawing started, and still steps in a row.
var _length: float = 0.0
var _still_steps: int = 0


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning


## An empty drawing.
func reset() -> void:
	_shapes.clear()
	_ways.clear()
	_angles.clear()
	_motions.clear()
	_length = 0.0
	_still_steps = 0


## The pad moved by `motion` during one fixed step of `delta` seconds.
func step(motion: Vector2, delta: float) -> void:
	if motion.length() < NOISE:
		_still_steps += 1
		if delta > 0.0 and _still_steps >= roundi(tuning.trick_gesture_pause / delta):
			_end_the_element()
		return
	_still_steps = 0
	_length += motion.length()
	if not _motions.is_empty():
		var turn: float = absf(rad_to_deg(_motions[-1].angle_to(motion)))
		if turn > CORNER:
			_end_the_element()
	_motions.append(motion)


## What the drawing reads so far, the element under way included: the recipe drawn, the
## trick of the context when nothing was drawn, or null when it cannot be read.
func recipe() -> TrickRecipe:
	if _length <= tuning.trick_gesture_still_length:
		return TrickRecipe.of_the_context()
	var shapes: Array[Shape] = _shapes.duplicate()
	var ways: Array[Vector2] = _ways.duplicate()
	var angles: Array[float] = _angles.duplicate()
	_read(_motions, shapes, ways, angles)
	return _compose(shapes, ways, angles)


func _end_the_element() -> void:
	if _motions.is_empty():
		return
	_read(_motions, _shapes, _ways, _angles)
	_motions.clear()


## Reads the element of `motions` into `shapes`, `ways` and `angles`: a stroke, a curve,
## a stroke then a curve, or nothing.
func _read(
	motions: Array[Vector2], shapes: Array[Shape], ways: Array[Vector2], angles: Array[float]
) -> void:
	if motions.is_empty():
		return
	var length: float = 0.0
	var net: Vector2 = Vector2.ZERO
	var turned: float = 0.0
	# The straight start: as long as the direction stays within the bend of the first one.
	var straight: Vector2 = Vector2.ZERO
	var straight_length: float = 0.0
	var straight_turned: float = 0.0
	var still_straight: bool = true
	for index: int in motions.size():
		var motion: Vector2 = motions[index]
		if index > 0:
			turned += rad_to_deg(motions[index - 1].angle_to(motion))
		still_straight = still_straight and absf(turned) <= BEND
		if still_straight:
			straight += motion
			straight_length += motion.length()
			straight_turned = turned
		length += motion.length()
		net += motion
	var stroke: float = tuning.trick_gesture_stroke_length
	var half: float = tuning.trick_gesture_half_circle_angle
	if straight_length >= stroke and straight_length >= STROKE_SHARE * length:
		# A stroke, and the curve it may curl into; a hook at its end is not read.
		_add(shapes, ways, angles, Shape.STROKE, straight, 0.0)
		var curl: float = turned - straight_turned
		if absf(curl) >= half and length - straight_length >= stroke:
			_add(shapes, ways, angles, Shape.CURVE, Vector2.ZERO, curl)
	elif absf(turned) >= half and length >= stroke:
		_add(shapes, ways, angles, Shape.CURVE, Vector2.ZERO, turned)
	elif net.length() >= stroke and absf(turned) <= STROKE_TURN:
		_add(shapes, ways, angles, Shape.STROKE, net, 0.0)
	else:
		# Too short, or a curve that is not yet half a circle.
		_add(shapes, ways, angles, Shape.NOTHING, Vector2.ZERO, 0.0)


func _add(
	shapes: Array[Shape],
	ways: Array[Vector2],
	angles: Array[float],
	shape: Shape,
	way: Vector2,
	angle: float
) -> void:
	shapes.append(shape)
	ways.append(_main_way(way))
	angles.append(angle)


## The way of a stroke among the four: the axis it goes most along; up or down when it
## goes as much along both.
func _main_way(motion: Vector2) -> Vector2:
	if motion.is_zero_approx():
		return Vector2.ZERO
	if absf(motion.x) > absf(motion.y):
		return Vector2(signf(motion.x), 0.0)
	return Vector2(0.0, signf(motion.y))


## The recipe the elements make, or null if they make none.
func _compose(shapes: Array[Shape], ways: Array[Vector2], angles: Array[float]) -> TrickRecipe:
	var recipe: TrickRecipe = null
	var flip_way: Vector2 = Vector2.ZERO
	var half_circles: int = 0
	for index: int in shapes.size():
		var shape: Shape = shapes[index]
		if recipe == null and shape == Shape.STROKE:
			recipe = _flip_of(ways[index])
			flip_way = ways[index]
		elif recipe == null and shape == Shape.CURVE and _is_a_circle(angles[index]):
			recipe = TrickRecipe.drawn(TrickRecipe.Flip.SPIN)
		elif recipe == null:
			continue
		elif shape == Shape.STROKE and ways[index] == flip_way:
			recipe.turns = mini(recipe.turns + 1, tuning.trick_max_turns)
		elif shape == Shape.CURVE and _takes_twists(recipe):
			if half_circles == 0:
				recipe.twist_way = -1.0 if angles[index] > 0.0 else 1.0
			half_circles += maxi(roundi(absf(angles[index]) / 180.0), 1)
	if recipe != null:
		recipe.twists = mini(half_circles, tuning.trick_max_twists_per_turn * recipe.turns)
	return recipe


func _flip_of(way: Vector2) -> TrickRecipe:
	if way == Vector2.UP:
		return TrickRecipe.drawn(TrickRecipe.Flip.FRONT_FLIP)
	if way == Vector2.DOWN:
		return TrickRecipe.drawn(TrickRecipe.Flip.BACKFLIP)
	return TrickRecipe.drawn(TrickRecipe.Flip.SIDE_FLIP, 1, 0, roundi(way.x))


func _is_a_circle(angle: float) -> bool:
	return absf(angle) >= tuning.trick_gesture_circle_angle


func _takes_twists(recipe: TrickRecipe) -> bool:
	return recipe.flip == TrickRecipe.Flip.FRONT_FLIP or recipe.flip == TrickRecipe.Flip.BACKFLIP
