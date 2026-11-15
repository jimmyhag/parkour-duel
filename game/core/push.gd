class_name Push
extends RefCounted
## How the push of the runner (the horizontal direction it wants) goes against a surface
## whose horizontal normal is given: towards it, along it or away from it, split at an
## angle measured from the surface, in degrees (the push split angle of the tuning).


## The angle of a push `direction` off a surface whose horizontal normal is `normal`, in
## radians: 0 along the surface, positive away from it, negative towards it; NAN without a
## push.
static func angle(direction: Vector3, normal: Vector3) -> float:
	var wish: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if wish.is_zero_approx():
		return NAN
	var across: float = wish.dot(normal)
	return atan2(across, (wish - normal * across).length())


## Pushing into a surface: towards it by the split angle at least, the limit included.
static func into(direction: Vector3, normal: Vector3, split: float) -> bool:
	var towards: float = -angle(direction, normal)
	if is_nan(towards):
		return false
	return _on_the_split(towards, split) or not _within_the_split(towards, split)


## Pushing away from a surface: beyond the split angle, the limit excluded.
static func away(direction: Vector3, normal: Vector3, split: float) -> bool:
	var off: float = angle(direction, normal)
	return not is_nan(off) and not _within_the_split(off, split)


## The angle is at most the split angle, or on it (a push exactly on the limit, as the
## keyboard diagonal, computed with rounding errors).
static func _within_the_split(push_angle: float, split: float) -> bool:
	return push_angle < deg_to_rad(split) or _on_the_split(push_angle, split)


static func _on_the_split(push_angle: float, split: float) -> bool:
	return is_equal_approx(push_angle, deg_to_rad(split))
