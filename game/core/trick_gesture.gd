class_name TrickGesture
extends RefCounted
## The drawing of a trick: the motions of the pad, fixed step after fixed step, read as a
## recipe (TrickRecipe). The player layer brings the mouse and the right stick to the one
## scale of the pad, whose axes are those of the screen: x to the right, y down; for the
## stick it tells how far it is pushed, and when it lets go of the pad (back in its dead
## zone).
##
## The drawing is cut into elements: a pause, the stick letting go, a sharp change of
## direction, or the stick dipping far under its strongest push ends one. A hand that
## pauses a moment and goes on the same way goes on with the same element: a hesitation.
## An element is cut too where it turns round a short bend between two straight stretches
## that go opposite ways: the hand going back and forth, round or sharp. An element may
## start straight, curve, and end straight. Read in order, the elements make the recipe:
## - the first stroke chooses the flip (up a front flip, down a backflip, left or right a
##   side flip that way); the same stroke again adds a turn; going the other way is not
##   read (the hand going back). On the stick, a flick past the least push of a stroke is
##   a stroke, however short;
## - a curve of a twist's arc after a front flip or a backflip adds a twist (two from a
##   bigger arc, one more for each further arc of the tuning), whether it starts straight
##   or not; a stroke that curls into a curve before any flip (a J) is the flip, then its
##   twists, even when the curve is a whole circle: after a flip, an arc is never a spin;
## - a curve that ends with a straight stroke against the flip is the hand going back, not
##   a twist;
## - a whole circle before any flip is a spin, and each further circle a turn more;
## - a curve before any flip that turns little enough is a stroke (a flick of the wrist);
## - anything else is not read. A hand that hardly moves draws nothing: the trick of the
##   context.
## A reading is validated once it has not changed for the settling time of the tuning,
## the hand hardly moving meanwhile: the last one validated is the trick that starts.
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
	## Its straight start and its straight end: their motion and their length; and the
	## motions of its straight start.
	var lead: Vector2 = Vector2.ZERO
	var lead_length: float = 0.0
	var lead_steps: int = 0
	var tail: Vector2 = Vector2.ZERO
	var tail_length: float = 0.0
	## The strongest push of the stick that drew it, from 0 to 1 (0 on the mouse).
	var peak: float = 0.0


var tuning: MovementTuning

## The elements over, measured.
var _elements: Array[Element] = []
## The motions of the element under way, one per moving step, and the push of the stick
## behind each one.
var _motions: Array[Vector2] = []
var _pushes: Array[float] = []
## The motions of the last element over, its pushes, and how many elements it made: what
## goes on if the hand only hesitated. It ended with a pause of the hand (`_paused`).
var _last_motions: Array[Vector2] = []
var _last_pushes: Array[float] = []
var _last_elements: int = 0
var _paused: bool = false
## The trace: where the pad went, from the origin, one point per moving step.
var _trace: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
## Moving steps' length since the drawing started, the strongest push of the stick, and
## still steps in a row.
var _length: float = 0.0
var _strongest_push: float = 0.0
var _still_steps: int = 0
## What the drawing reads, and the marks of what counted, as of the last step.
var _recipe: TrickRecipe = TrickRecipe.of_the_context()
var _marks: Array[Mark] = []
## The reading, as words, the steps it has not changed for, and how far the hand moved
## at each of the last steps; the reading is validated (`_settled`), and the last one
## validated.
var _reading: String = ""
var _steady_steps: int = 0
var _recent_motions: Array[float] = []
var _settled: bool = false
var _validated: TrickRecipe = TrickRecipe.of_the_context()


func _init(movement_tuning: MovementTuning) -> void:
	tuning = movement_tuning
	reset()


## An empty drawing: the trick of the context, validated.
func reset() -> void:
	_elements.clear()
	_motions = []
	_pushes = []
	_last_motions = []
	_last_pushes = []
	_last_elements = 0
	_paused = false
	_trace = PackedVector2Array([Vector2.ZERO])
	_length = 0.0
	_strongest_push = 0.0
	_still_steps = 0
	_recipe = TrickRecipe.of_the_context()
	_marks = []
	_reading = _words(_recipe)
	_steady_steps = 0
	_recent_motions.clear()
	_settled = false
	_validated = _recipe


## The pad moved by `motion` during one fixed step of `delta` seconds; `let_go` when the
## stick came back to its dead zone at this step; `push`, how far the stick that moved
## it is pushed, from 0 to 1 (0 for the mouse).
func step(motion: Vector2, delta: float, let_go: bool = false, push: float = 0.0) -> void:
	if motion.length() < tuning.trick_gesture_noise:
		_still_steps += 1
		if let_go:
			_end_the_element(false)
		elif _still_steps >= _steps(tuning.trick_gesture_pause, delta):
			_end_the_element(true)
	else:
		if _motions.is_empty():
			if _goes_on(motion, delta):
				_reopen()
		else:
			var turn: float = absf(rad_to_deg(_motions[-1].angle_to(motion)))
			var dip: bool = push > 0.0 and push < _peak(_pushes) * tuning.trick_gesture_stick_dip
			if turn > tuning.trick_gesture_corner_angle or dip:
				_end_the_element(false)
		_still_steps = 0
		_length += motion.length()
		_strongest_push = maxf(_strongest_push, push)
		_motions.append(motion)
		_pushes.append(push)
		_trace.append(_trace[-1] + motion)
	_read()
	_settle(motion, delta)


## What the drawing reads so far, the element under way included: the recipe drawn, the
## trick of the context when nothing was drawn, or null when it cannot be read.
func recipe() -> TrickRecipe:
	return _recipe


## The recipe drawn read now is validated: steady, the hand at rest. It is the trick that
## starts if the button is released.
func is_validated() -> bool:
	return _settled and _recipe != null and not _recipe.context


## The last reading validated: the trick that starts if the button is released (the trick
## of the context for a drawing still empty; null for one that does not read).
func validated_recipe() -> TrickRecipe:
	return _validated


## Where the pad went, from the origin, in units of the pad.
func trace() -> PackedVector2Array:
	return _trace


## The elements that counted for the recipe, in order.
func marks() -> Array[Mark]:
	return _marks


## Ends the element under way; `paused` when the hand paused.
func _end_the_element(paused: bool) -> void:
	if _motions.is_empty():
		return
	var measured: Array[Element] = _measure(_motions, _pushes)
	_elements.append_array(measured)
	_last_elements = measured.size()
	_last_motions = _motions
	_last_pushes = _pushes
	_motions = []
	_pushes = []
	_paused = paused


## The hand moves again by `motion` after it paused for less than the pause that tells two
## strokes apart, the way it went: it only hesitated.
func _goes_on(motion: Vector2, delta: float) -> bool:
	if not _paused or _last_motions.is_empty():
		return false
	if _still_steps >= _steps(tuning.trick_gesture_repeat_pause, delta):
		return false
	var turn: float = absf(rad_to_deg(_last_motions[-1].angle_to(motion)))
	return turn <= tuning.trick_gesture_bend_angle


## The last element over goes on: it is under way again.
func _reopen() -> void:
	for index: int in _last_elements:
		_elements.pop_back()
	_motions = _last_motions
	_pushes = _last_pushes
	_last_motions = []
	_last_pushes = []
	_last_elements = 0
	_paused = false


## Reads the elements over and the one under way.
func _read() -> void:
	_marks = []
	var stick_flick: bool = _strongest_push >= tuning.trick_gesture_stick_flick
	if _length <= tuning.trick_gesture_still_length and not stick_flick:
		_recipe = TrickRecipe.of_the_context()
		return
	var elements: Array[Element] = _elements.duplicate()
	if not _motions.is_empty():
		elements.append_array(_measure(_motions, _pushes))
	_recipe = _compose(elements)


## The reading is validated once it has not changed for the settling time, the hand
## moving less than the settling length meanwhile.
func _settle(motion: Vector2, delta: float) -> void:
	var settling: int = maxi(_steps(tuning.trick_gesture_settle, delta), 1)
	var reading: String = _words(_recipe)
	if reading != _reading:
		_reading = reading
		_steady_steps = 0
	_steady_steps += 1
	_recent_motions.append(motion.length())
	while _recent_motions.size() > settling:
		_recent_motions.pop_front()
	var moved: float = 0.0
	for length: float in _recent_motions:
		moved += length
	_settled = _steady_steps >= settling and moved <= tuning.trick_gesture_settle_length
	if _settled:
		_validated = _recipe


## A reading in words: what tells two readings apart.
func _words(read: TrickRecipe) -> String:
	if read == null:
		return ""
	if read.context:
		return "context"
	return "%s %d" % [read.name(), read.side]


## The elements of `motions`, the last ones of the trace, and of their `pushes`: one, or
## several where the hand turns round a short bend.
func _measure(motions: Array[Vector2], pushes: Array[float]) -> Array[Element]:
	var first: int = _trace.size() - 1 - motions.size()
	var elements: Array[Element] = []
	var start: int = 0
	for cut: Vector2i in _turnarounds(motions):
		elements.append(_element(motions, pushes, start, cut.x, first))
		start = cut.y
	elements.append(_element(motions, pushes, start, motions.size(), first))
	return elements


## Where the hand turns round within `motions`: for each turn, the end of the stretch
## before it and the start of the one after it (motion indices). The stretch after it is
## a stroke at least as long as the bend, and the one before it goes the opposite way;
## both span more than one motion (a fast circle is no back and forth).
func _turnarounds(motions: Array[Vector2]) -> Array[Vector2i]:
	var runs: Array[Vector2i] = _straight_runs(motions)
	var cuts: Array[Vector2i] = []
	var free_from: int = 0
	for after: int in runs.size():
		var run: Vector2i = runs[after]
		var length: float = _length_of(motions, run.x, run.y)
		if length < tuning.trick_gesture_stroke_length or run.y - run.x < 2:
			continue
		var way: Vector2 = _main_way(_sum_of(motions, run.x, run.y))
		var bend: float = 0.0
		for before: int in range(after - 1, free_from - 1, -1):
			var other: Vector2i = runs[before]
			var opposite: bool = _main_way(_sum_of(motions, other.x, other.y)) == -way
			if opposite and other.y - other.x > 1:
				cuts.append(Vector2i(other.y, run.x))
				free_from = after
				break
			bend += _length_of(motions, other.x, other.y)
			if bend > length:
				break
	return cuts


## The straight stretches of `motions`: each one keeps within the bend of the tuning of
## its first motion. Their first motion index, and the one after their last.
func _straight_runs(motions: Array[Vector2]) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start: int = 0
	for index: int in range(1, motions.size() + 1):
		var ends: bool = index == motions.size()
		if not ends:
			var turn: float = absf(rad_to_deg(motions[start].angle_to(motions[index])))
			ends = turn > tuning.trick_gesture_bend_angle
		if ends:
			runs.append(Vector2i(start, index))
			start = index
	return runs


func _sum_of(motions: Array[Vector2], from: int, to: int) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	for index: int in range(from, to):
		sum += motions[index]
	return sum


func _length_of(motions: Array[Vector2], from: int, to: int) -> float:
	var length: float = 0.0
	for index: int in range(from, to):
		length += motions[index].length()
	return length


## The element of the motions `from` to `to` (excluded) of `motions`, whose first motion
## starts at the point `first` of the trace, measured.
func _element(
	motions: Array[Vector2], pushes: Array[float], from: int, to: int, first: int
) -> Element:
	var element: Element = Element.new()
	element.from = first + from
	element.to = first + to
	var bend: float = tuning.trick_gesture_bend_angle
	var leading: bool = true
	for index: int in range(from, to):
		var motion: Vector2 = motions[index]
		if index > from:
			element.turned += rad_to_deg(motions[index - 1].angle_to(motion))
		leading = leading and absf(element.turned) <= bend
		if leading:
			element.lead += motion
			element.lead_length += motion.length()
			element.lead_steps += 1
		element.length += motion.length()
		element.net += motion
		element.peak = maxf(element.peak, pushes[index])
	var back: float = 0.0
	for index: int in range(to - 1, from - 1, -1):
		if index < to - 1:
			back += rad_to_deg(motions[index].angle_to(motions[index + 1]))
		if absf(back) > bend:
			break
		element.tail += motions[index]
		element.tail_length += motions[index].length()
	# The turn is measured between the first and the last motion: the arc drawn spans one
	# more step.
	var count: int = to - from
	element.arc = element.turned * count / (count - 1) if count > 1 else 0.0
	return element


## The recipe the elements make, or null if they make none; the marks of what counted.
func _compose(elements: Array[Element]) -> TrickRecipe:
	var recipe: TrickRecipe = null
	var flip_way: Vector2 = Vector2.ZERO
	var half_circles: int = 0
	for element: Element in elements:
		var curved: bool = absf(element.arc) >= tuning.trick_gesture_half_circle_angle
		curved = curved and element.length >= tuning.trick_gesture_stroke_length
		if curved and recipe == null and _is_a_j(element):
			flip_way = _main_way(element.lead)
			recipe = _flip_of(flip_way)
			_mark(MarkKind.STROKE, element, flip_way)
			if _takes_twists(recipe) and not _goes_back(element, flip_way):
				half_circles += _twist(recipe, element, half_circles)
		elif curved and recipe == null and _is_a_circle(element.arc):
			recipe = TrickRecipe.drawn(TrickRecipe.Flip.SPIN, 0)
			recipe.turns = mini(_spin_turns(element.arc), tuning.trick_max_turns)
			_mark(MarkKind.SPIN, element, Vector2.ZERO)
		elif curved and recipe != null and recipe.flip == TrickRecipe.Flip.SPIN:
			if _is_a_circle(element.arc):
				var turns: int = recipe.turns + _spin_turns(element.arc)
				recipe.turns = mini(turns, tuning.trick_max_turns)
				_mark(MarkKind.SPIN, element, Vector2.ZERO)
		elif curved and recipe != null:
			if _takes_twists(recipe) and not _goes_back(element, flip_way):
				half_circles += _twist(recipe, element, half_circles)
		elif not curved or absf(element.turned) <= tuning.trick_gesture_stroke_turn:
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


## A stroke that curls into a curve: its straight start is a stroke over more than one
## motion (a fast circle starts with a long chord), and a share of the element.
func _is_a_j(element: Element) -> bool:
	var share: float = tuning.trick_gesture_stroke_share * element.length
	var lead: float = element.lead_length
	var stroke: bool = lead >= tuning.trick_gesture_stroke_length and element.lead_steps > 1
	return stroke and lead >= share


## The way of a stroke: the whole element if it is long enough, or a flick of the stick
## pushed far enough, and goes mostly one way; or its straight start if it ends in a hook;
## ZERO if it is no stroke.
func _stroke_way(element: Element) -> Vector2:
	var stroke: float = tuning.trick_gesture_stroke_length
	var long: bool = element.net.length() >= stroke
	long = long or element.peak >= tuning.trick_gesture_stick_flick
	if long and absf(element.turned) <= tuning.trick_gesture_stroke_turn:
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


## The twists a curve after a front flip or a backflip adds: one, two from a bigger arc,
## one more for each further arc of the tuning. The first one gives the way they turn.
func _twist(recipe: TrickRecipe, element: Element, twists_so_far: int) -> int:
	if twists_so_far == 0:
		recipe.twist_way = -1.0 if element.arc > 0.0 else 1.0
	_mark(MarkKind.TWIST, element, Vector2.ZERO)
	var arc: float = absf(element.arc)
	if arc < tuning.trick_gesture_two_twists_angle:
		return 1
	var further: float = maxf(tuning.trick_gesture_more_twists_angle, 1.0)
	return 2 + floori((arc - tuning.trick_gesture_two_twists_angle) / further)


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


## The turns of a spin an arc of a circle makes: one from the arc of a circle, one more
## for each further turn of the tuning beyond it.
func _spin_turns(arc: float) -> int:
	var further: float = maxf(tuning.trick_gesture_spin_turn_angle, 1.0)
	return 1 + maxi(floori((absf(arc) - tuning.trick_gesture_circle_angle) / further), 0)


func _takes_twists(recipe: TrickRecipe) -> bool:
	return recipe.flip == TrickRecipe.Flip.FRONT_FLIP or recipe.flip == TrickRecipe.Flip.BACKFLIP


## The strongest of `pushes`.
func _peak(pushes: Array[float]) -> float:
	var peak: float = 0.0
	for push: float in pushes:
		peak = maxf(peak, push)
	return peak


## A duration of the tuning, in fixed steps of `delta` seconds (rounded to the nearest).
func _steps(seconds: float, delta: float) -> int:
	return roundi(seconds / delta) if delta > 0.0 else 1
