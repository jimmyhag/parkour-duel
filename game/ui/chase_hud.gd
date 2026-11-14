class_name ChaseHud
extends Control
## The display of one player of the chase, over its view of a split screen: at the top its
## role (CAT or MOUSE, in the colour of the role) and the time left in the round, as the
## chase (ChaseState, game/core) says them at the match step given; between two rounds,
## the role and the time of the coming one. When the other player is out of sight, behind
## the camera or out of its field of view, an arrow at the edge of the view points
## towards it: the way to turn, from where the camera looks. Nothing takes the focus.

const CAT: String = "CAT"
const MOUSE: String = "MOUSE"
## How far inside the edge of the view the indicator stands, in pixels.
const INDICATOR_MARGIN: float = 48.0
## The size of the arrow, from its tip to its base, in pixels.
const INDICATOR_SIZE: float = 28.0
## The point of the other player the camera looks for: about its chest, in m above its
## feet.
const LOOKED_AT_HEIGHT: float = 1.0

## The chase, the player of this display in it, and the match step now.
var chase: ChaseState
var player: int = 0
var step: int = 0
## The camera of the view, and the body of the other player.
var camera: Camera3D
var other: Node3D
## Whether the indicator shows, where it stands in the display, in pixels, and the way it
## points (a unit vector, x to the right, y down).
var indicator_shown: bool = false
var indicator_position: Vector2 = Vector2.ZERO
var indicator_direction: Vector2 = Vector2.DOWN

@onready var _role_label: Label = %RoleLabel as Label
@onready var _time_label: Label = %TimeLabel as Label


func _process(_delta: float) -> void:
	refresh()


## Writes the role and the time on screen, and places the indicator.
func refresh() -> void:
	if chase == null:
		return
	var cat: bool = chase.role(player) == ChaseState.Role.CAT
	_role_label.text = CAT if cat else MOUSE
	_role_label.modulate = chase.tuning.chase_cat_colour if cat else chase.tuning.chase_mouse_colour
	_time_label.text = RaceHud.clock(chase.centiseconds_left(step))
	_place_the_indicator()
	queue_redraw()


func _draw() -> void:
	if not indicator_shown:
		return
	var tip: Vector2 = indicator_position + indicator_direction * INDICATOR_SIZE / 2.0
	var back: Vector2 = indicator_position - indicator_direction * INDICATOR_SIZE / 2.0
	var side: Vector2 = indicator_direction.orthogonal() * INDICATOR_SIZE / 2.0
	var colour: Color = Color.WHITE
	if chase != null:
		var other_is_cat: bool = chase.role(player) == ChaseState.Role.MOUSE
		colour = chase.tuning.chase_cat_colour if other_is_cat else chase.tuning.chase_mouse_colour
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), colour)


## The indicator shows when the other player is behind the camera or off the view; it then
## stands at the edge of the display, its margin inside, in the way to the other from the
## middle of the view, as the camera sees it.
func _place_the_indicator() -> void:
	indicator_shown = false
	if camera == null or other == null or not camera.is_inside_tree():
		return
	var target: Vector3 = other.global_position + Vector3.UP * LOOKED_AT_HEIGHT
	var view: Rect2 = Rect2(Vector2.ZERO, camera.get_viewport().get_visible_rect().size)
	if not camera.is_position_behind(target) and view.has_point(camera.unproject_position(target)):
		return
	var seen: Vector3 = camera.global_transform.affine_inverse() * target
	var direction: Vector2 = Vector2(seen.x, -seen.y)
	indicator_direction = Vector2.DOWN if direction.is_zero_approx() else direction.normalized()
	var half: Vector2 = size / 2.0 - Vector2.ONE * INDICATOR_MARGIN
	var reach: float = INF
	if not is_zero_approx(indicator_direction.x):
		reach = half.x / absf(indicator_direction.x)
	if not is_zero_approx(indicator_direction.y):
		reach = minf(reach, half.y / absf(indicator_direction.y))
	indicator_position = size / 2.0 + indicator_direction * reach
	indicator_shown = true
