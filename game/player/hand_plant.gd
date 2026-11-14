class_name HandPlant
extends RefCounted
## The top the character puts its hands on in a vault or a mantle (docs/specs/vault.md),
## made from what the runner observed as the move started: the altitude of the ground the
## move left and of the top, the point of the near edge of the top on the way of the move,
## that way (horizontal, of length 1), and how deep the top is that way (INF: a ledge, as
## deep as it goes). Presentation only: where the hands go, never where the runner goes.

## How far past the near edge of the top, and before its far edge, a hand is put, in m.
const INSET: float = 0.05

var ground: float = 0.0
var top: float = 0.0
var edge: Vector3 = Vector3.ZERO
var heading: Vector3 = Vector3.FORWARD
var depth: float = INF


func _init(
	ground_altitude: float, top_altitude: float, near_edge: Vector3, way: Vector3, deep: float
) -> void:
	ground = ground_altitude
	top = top_altitude
	edge = near_edge
	heading = Vector3(way.x, 0.0, way.z).normalized()
	depth = deep


## Where a hand that the clip shows at `hand`, in the world, is put on the top: at the
## altitude of the top, where the hand is across the way of the move, and along it over the
## top, at least INSET past its near edge and as much before its far edge.
func target(hand: Vector3) -> Vector3:
	var offset: Vector3 = hand - edge
	var along: float = offset.dot(heading)
	var across: Vector3 = offset - heading * along
	across.y = 0.0
	var point: Vector3 = edge + heading * clampf(along, INSET, maxf(depth - INSET, INSET))
	point += across
	point.y = top
	return point
