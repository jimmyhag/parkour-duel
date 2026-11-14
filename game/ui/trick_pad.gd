class_name TrickPad
extends Control
## The pad of the trick, at the centre of the screen while the trick button is held: a
## round translucent disc, about a fifth of the height of the screen, where the trace of
## the drawing (TrickGesture) is drawn as it goes, at the scale of the recognition (one
## scale for the whole trace, small enough for it to fit); the elements that counted are
## marked (an arrow for a stroke, a thick arc for a twist, another colour for a spin) and
## the recipe read is named under the disc (? while nothing reads). When the trick is
## validated, the one that starts if the button is released, and the runner can start a
## trick now, the border of the disc changes colour and thickens.
## Hidden once the button is released. It reads core only; nothing takes the focus.

const UNREAD: String = "?"
## The disc: its radius as a share of the height of the screen, its colour, and how many
## units of the pad its radius shows at least.
const RADIUS_SHARE: float = 0.1
const DISC_COLOR: Color = Color(0.08, 0.09, 0.12, 0.55)
const UNITS_SHOWN: float = 2.0
const BORDER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const BORDER_WIDTH: float = 2.0
const VALID_BORDER_COLOR: Color = Color(0.4, 1.0, 0.5, 1.0)
const VALID_BORDER_WIDTH: float = 7.0
const TRACE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const TRACE_WIDTH: float = 3.0
const MARK_COLORS: Dictionary[TrickGesture.MarkKind, Color] = {
	TrickGesture.MarkKind.STROKE: Color(1.0, 0.85, 0.3),
	TrickGesture.MarkKind.TWIST: Color(0.55, 0.9, 1.0),
	TrickGesture.MarkKind.SPIN: Color(1.0, 0.5, 0.9),
}
const MARK_WIDTH: float = 6.0
const ARROW_SIZE: float = 14.0
const POINTS_PER_CIRCLE: int = 64
## Between the disc and the name under it, in pixels.
const LABEL_GAP: float = 8.0

## The runner whose button is watched, and its drawing.
var motor: RunnerMotor
var gesture: TrickGesture

@onready var _recipe_label: Label = %RecipeLabel as Label


func _process(_delta: float) -> void:
	refresh()


## Shows the drawing as it is, or hides the pad when the button is not held.
func refresh() -> void:
	visible = motor != null and gesture != null and motor.is_drawing()
	if not visible:
		return
	_recipe_label.text = recipe_shown()
	_recipe_label.size.x = 2.0 * _radius()
	_recipe_label.position = _centre() + Vector2(-_radius(), _radius() + LABEL_GAP)
	queue_redraw()


## The trick read is validated, and the runner can start it now: the one that starts if
## the button is released.
func is_validated() -> bool:
	if gesture == null or motor == null:
		return false
	return gesture.is_validated() and motor.trick_ready


func border_color() -> Color:
	return VALID_BORDER_COLOR if is_validated() else BORDER_COLOR


func border_width() -> float:
	return VALID_BORDER_WIDTH if is_validated() else BORDER_WIDTH


## The name under the disc: the recipe read, or ? while nothing reads.
func recipe_shown() -> String:
	var recipe: TrickRecipe = null if gesture == null else gesture.recipe()
	return UNREAD if recipe == null or recipe.context else recipe.name()


## The trace as it is drawn on the screen, in pixels, from the centre of the disc.
func trace_shown() -> PackedVector2Array:
	var shown: PackedVector2Array = PackedVector2Array()
	var scale: float = pixels_per_unit()
	for point: Vector2 in gesture.trace():
		shown.append(_centre() + point * scale)
	return shown


## The elements marked on the trace.
func marks_shown() -> Array[TrickGesture.Mark]:
	return gesture.marks()


## Pixels per unit of the pad: the radius shows UNITS_SHOWN units, or the farthest point
## of the trace if it went farther.
func pixels_per_unit() -> float:
	var farthest: float = UNITS_SHOWN
	for point: Vector2 in gesture.trace():
		farthest = maxf(farthest, point.length())
	return _radius() / farthest


func _draw() -> void:
	if gesture == null:
		return
	var centre: Vector2 = _centre()
	draw_circle(centre, _radius(), DISC_COLOR)
	var trace: PackedVector2Array = trace_shown()
	if trace.size() > 1:
		draw_polyline(trace, TRACE_COLOR, TRACE_WIDTH, true)
	for mark: TrickGesture.Mark in marks_shown():
		_draw_mark(mark, trace)
	draw_arc(centre, _radius(), 0.0, TAU, POINTS_PER_CIRCLE, border_color(), border_width(), true)


func _draw_mark(mark: TrickGesture.Mark, trace: PackedVector2Array) -> void:
	var colour: Color = MARK_COLORS[mark.kind]
	var span: PackedVector2Array = trace.slice(mark.from, mark.to + 1)
	if span.size() < 2:
		return
	if mark.kind != TrickGesture.MarkKind.STROKE:
		draw_polyline(span, colour, MARK_WIDTH, true)
		return
	# An arrow from the start of the stroke to its end, the way it was read.
	var tip: Vector2 = span[-1]
	draw_line(span[0], tip, colour, MARK_WIDTH, true)
	var back: Vector2 = -mark.way * ARROW_SIZE
	draw_line(tip, tip + back.rotated(PI / 6.0), colour, MARK_WIDTH, true)
	draw_line(tip, tip + back.rotated(-PI / 6.0), colour, MARK_WIDTH, true)


func _centre() -> Vector2:
	return size / 2.0


func _radius() -> float:
	return maxf(get_viewport_rect().size.y * RADIUS_SHARE, 1.0)
