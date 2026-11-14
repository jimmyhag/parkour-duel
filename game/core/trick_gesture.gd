class_name TrickGesture
extends RefCounted
## The drawing of a trick: the motions of the pad, fixed step after fixed step, read as a
## recipe (TrickRecipe). The player layer brings the mouse and the right stick to the one
## scale of the pad, whose axes are those of the screen: x to the right, y down, and
## tells when the stick lets go of the pad (back in its dead zone).
##
## The drawing is cut into elements: a pause, the stick letting go, or a sharp change of
## direction ends one. An element may start straight, curve, and end straight. Read in
## order, the elements make the recipe:
## - the first stroke chooses the flip (up a front flip, down a backflip, left or right a
##   side flip that way); the same stroke again adds a turn; going the other way is not
##   read (the hand going back);
## - a curve of a twist's arc after a front flip or a backflip adds a twist (two from a
##   bigger arc), whether it starts straight or not; a stroke that curls into such a curve
##   before any flip (a J) is the flip, then the twist;
## - a curve that ends with a straight stroke against the flip is the hand going back, not
##   a twist;
## - a whole circle before any flip is a spin, and each circle after it a turn more;
## - anything else is not read. A hand that hardly moves draws nothing: the trick of the
##   context.
## Every threshold is in the tuning resource (group Tricks). The drawing keeps its trace
## and marks the elements that counted, for the pad on the screen.

## What an element that counted added to the recipe, for the pad on the screen.
enum MarkKind { STROKE, TWIST, SPIN }


## One element that counted: what it added, the points of the trace it spans (indices),
## and, for a stroke, its way.
class Mark:
	var kind: MarkKind
	var from: int
	var to: int
	var way: Vector2

	func _init(mark_kind: MarkKind, first: int, last: int, mark_way: Vector2) -> void:
		kind = mark_kind
		from = first
		to = last
		way = mark_way


## One element of the drawing, measured.
class Element:
	## The point of the trace where it starts, and where it ends.
	var from: int = 0
	var to: int = 0
	var length: float = 0.0
	var net: Vector2 = Vector2.ZERO
	## How far its direction turned from its first motion to its last, in degrees
	## (positive: clockwise on the screen), and the arc it draws.
	var turned: float = 0.0
	var arc: float = 0.0
	## Its straight start and its straight end: their motion and their length.
	var lead: Vector2 = Vector2.ZERO
	var lead_length: float = 0.0
	var tail: Vector2 = Vector2.ZERO
	var tail_length: float = 0.0


var tuning: MovementTuning

## The elements over, measured.
var _elements: Array[Element] = []
## The motions of the element under way, one per moving step.
var _motions: Array[Vector2] = []
## The trace: where the pad went, from the origin, one point per moving step.
var _trace: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
## Moving steps' length since the drawing started, and still steps in a row.
var _length: float = 0.0
var _still_steps: int = 0
## What the drawing reads, and the marks of what counted, as of the last step.
var _recipe: TrickRecipe = TrickRecipe.of_the_context()
var _marks: Array[Mark] = []


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning


## An empty drawing.
func reset() -> void:
	_elements.clear()
	_motions.clear()
	_trace = PackedVector2Array([Vector2.ZERO])
	_length = 0.0
	_still_steps = 0
	_recipe = TrickRecipe.of_the_context()
	_marks = []


## The pad moved by `motion` during one fixed step of `delta` seconds; `let_go` when the
## stick came back to its dead zone at this step.
func step(motion: Vector2, delta: float, let_go: bool = false) -> void:
	if motion.length() < tuning.trick_gesture_noise:
		_still_steps += 1
		var pause: int = roundi(tuning.trick_gesture_pause / delta) if delta > 0.0 else 1
		if let_go or _still_steps >= pause:
			_end_the_element()
	else:
		_still_steps = 0
		_length += motion.length()
		if not _motions.is_empty():
			var turn: float = absf(rad_to_deg(_motions[-1].angle_to(motion)))
			if turn > tuning.trick_gesture_corner_angle:
				_end_the_element()
		_motions.append(motion)
		_trace.append(_trace[-1] + motion)
	_read()


## What the drawing reads so far, the element under way included: the recipe drawn, the
## trick of the context when nothing was drawn, or null when it cannot be read.
func recipe() -> TrickRecipe:
	return _recipe


## The drawing reads a recipe drawn, and no element is under way: the trick is complete,
## it is the one that will start.
func is_complete() -> bool:
	return _recipe != null and not _recipe.context and _motions.is_empty()


## Where the pad went, from the origin, in units of the pad.
func trace() -> PackedVector2Array:
	return _trace


## The elements that counted for the recipe, in order.
func marks() -> Array[Mark]:
	return _marks


func _end_the_element() -> void:
	if _motions.is_empty():
		return
	_elements.append(_measure(_motions))
	_motions.clear()


## Reads the elements over and the one under way.
func _read() -> void:
	_marks = []
	if _length <= tuning.trick_gesture_still_length:
		_recipe = TrickRecipe.of_the_context()
		return
	var elements: Array[Element] = _elements.duplicate()
	if not _motions.is_empty():
		elements.append(_measure(_motions))
	_recipe = _compose(elements)


## The element of `motions`, the last ones of the trace, measured.
func _measure(motions: Array[Vector2]) -> Element:
	var element: Element = Element.new()
	element.to = _trace.size() - 1
	element.from = element.to - motions.size()
	var bend: float = tuning.trick_gesture_bend_angle
	var leading: bool = true
	for index: int in motions.size():
		var motion: Vector2 = motions[index]
		if index > 0:
			element.turned += rad_to_deg(motions[index - 1].angle_to(motion))
		leading = leading and absf(element.turned) <= bend
		if leading:
			element.lead += motion
			element.lead_length += motion.length()
		element.length += motion.length()
		element.net += motion
	var back: float = 0.0
	for index: int in range(motions.size() - 1, -1, -1):
		if index < motions.size() - 1:
			back += rad_to_deg(motions[index].angle_to(motions[index + 1]))
		if absf(back) > bend:
			break
		element.tail += motions[index]
		element.tail_length += motions[index].length()
	# The turn is measured between the first and the last motion: the arc drawn spans one
	# more step.
	var count: int = motions.size()
	element.arc = element.turned * count / (count - 1) if count > 1 else 0.0
	return element


## The recipe the elements make, or null if they make none; the marks of what counted.
func _compose(elements: Array[Element]) -> TrickRecipe:
	var recipe: TrickRecipe = null
	var flip_way: Vector2 = Vector2.ZERO
	var half_circles: int = 0
	var stroke: float = tuning.trick_gesture_stroke_length
	for element: Element in elements:
		var curved: bool = absf(element.arc) >= tuning.trick_gesture_half_circle_angle
		curved = curved and element.length >= stroke
		if curved and recipe == null and _is_a_circle(element.arc):
			recipe = TrickRecipe.drawn(TrickRecipe.Flip.SPIN, 0)
			recipe.turns = mini(_circles(element.arc), tuning.trick_max_turns)
			_mark(MarkKind.SPIN, element, Vector2.ZERO)
		elif curved and recipe == null:
			# A J: a stroke that curls into a curve.
			var share: float = tuning.trick_gesture_stroke_share * element.length
			if element.lead_length < stroke or element.lead_length < share:
				continue
			flip_way = _main_way(element.lead)
			recipe = _flip_of(flip_way)
			_mark(MarkKind.STROKE, element, flip_way)
			if _takes_twists(recipe) and not _goes_back(element, flip_way):
				half_circles += _twist(recipe, element, half_circles)
		elif curved and recipe.flip == TrickRecipe.Flip.SPIN:
			if _is_a_circle(element.arc):
				recipe.turns = mini(recipe.turns + _circles(element.arc), tuning.trick_max_turns)
				_mark(MarkKind.SPIN, element, Vector2.ZERO)
		elif curved:
			if _takes_twists(recipe) and not _goes_back(element, flip_way):
				half_circles += _twist(recipe, element, half_circles)
		else:
			var way: Vector2 = _stroke_way(element)
			if way.is_zero_approx():
				continue
			if recipe == null:
				flip_way = way
				recipe = _flip_of(way)
				_mark(MarkKind.STROKE, element, way)
			elif recipe.flip != TrickRecipe.Flip.SPIN and way == flip_way:
				recipe.turns = mini(recipe.turns + 1, tuning.trick_max_turns)
				_mark(MarkKind.STROKE, element, way)
	if recipe != null:
		recipe.twists = mini(half_circles, tuning.trick_max_twists_per_turn * recipe.turns)
	return recipe


## The way of a stroke: the whole element if it goes mostly one way, or its straight start
## if it ends in a hook; ZERO if it is no stroke.
func _stroke_way(element: Element) -> Vector2:
	var stroke: float = tuning.trick_gesture_stroke_length
	if element.net.length() >= stroke and absf(element.turned) <= tuning.trick_gesture_stroke_turn:
		return _main_way(element.net)
	if element.lead_length >= stroke:
		return _main_way(element.lead)
	return Vector2.ZERO


## A curve that ends with a straight stroke against the flip, longer than the curve
## itself: the hand going back round a short turn, not a twist.
func _goes_back(element: Element, flip_way: Vector2) -> bool:
	if element.tail_length < tuning.trick_gesture_stroke_length:
		return false
	var curve: float = maxf(element.length - element.lead_length - element.tail_length, 0.0)
	return element.tail_length >= curve and _main_way(element.tail) == -flip_way


## The twists a curve after a front flip or a backflip adds: one, two from a bigger arc.
## The first one gives the way the twists turn.
func _twist(recipe: TrickRecipe, element: Element, twists_so_far: int) -> int:
	if twists_so_far == 0:
		recipe.twist_way = -1.0 if element.arc > 0.0 else 1.0
	_mark(MarkKind.TWIST, element, Vector2.ZERO)
	if absf(element.arc) < tuning.trick_gesture_two_twists_angle:
		return 1
	return 2 + floori((absf(element.arc) - tuning.trick_gesture_two_twists_angle) / 180.0)


func _mark(kind: MarkKind, element: Element, way: Vector2) -> void:
	_marks.append(Mark.new(kind, element.from, element.to, way))


## The way of a stroke among the four: the axis it goes most along; up or down when it
## goes as much along both.
func _main_way(motion: Vector2) -> Vector2:
	if motion.is_zero_approx():
		return Vector2.ZERO
	if absf(motion.x) > absf(motion.y):
		return Vector2(signf(motion.x), 0.0)
	return Vector2(0.0, signf(motion.y))


func _flip_of(way: Vector2) -> TrickRecipe:
	if way == Vector2.UP:
		return TrickRecipe.drawn(TrickRecipe.Flip.FRONT_FLIP)
	if way == Vector2.DOWN:
		return TrickRecipe.drawn(TrickRecipe.Flip.BACKFLIP)
	return TrickRecipe.drawn(TrickRecipe.Flip.SIDE_FLIP, 1, 0, roundi(way.x))


func _is_a_circle(arc: float) -> bool:
	return absf(arc) >= tuning.trick_gesture_circle_angle


## The whole circles an arc of a circle at least makes: one at least.
func _circles(arc: float) -> int:
	return maxi(roundi(absf(arc) / 360.0), 1)


func _takes_twists(recipe: TrickRecipe) -> bool:
	return recipe.flip == TrickRecipe.Flip.FRONT_FLIP or recipe.flip == TrickRecipe.Flip.BACKFLIP
