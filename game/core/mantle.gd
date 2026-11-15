class_name Mantle
extends RefCounted
## One mantle of the runner onto a ledge, from its face to its top. Planned from what the
## runner observed as it started, it gives the velocity of each of its fixed steps: the
## runner rises along the face of its ledge up to its top, while it pushes onto it at the
## exit speed; the last stretch carries it one body width forward, over the top, pressing
## it onto the top with the weight of one step, so that it stands there. The motor plays it.

## The fixed steps the mantle has played.
var steps: int = 0

## The altitude of the top of its ledge, the horizontal direction onto it, and how many
## fixed steps it lasts (at least one).
var _top: float = 0.0
var _onto: Vector3 = Vector3.ZERO
var _duration: int = 1
var _tuning: MovementTuning


## The mantle of a runner that observed `facts` (a ledge in front), with the tuning `tuning`,
## lasting `duration_steps` fixed steps (at least one).
func _init(facts: RunnerFacts, tuning: MovementTuning, duration_steps: int) -> void:
	_tuning = tuning
	_duration = maxi(duration_steps, 1)
	_top = facts.altitude + facts.ledge_height
	_onto = -Vector3(facts.ledge_normal.x, 0.0, facts.ledge_normal.z).normalized()


## Whether a runner that observed `facts` may mantle the ledge in front of it: its top
## within the heights a mantle climbs and free to stand on (whether it pushes towards it is
## the motor's to judge).
static func fits(facts: RunnerFacts, tuning: MovementTuning) -> bool:
	if facts.ledge_normal.is_zero_approx() or not facts.ledge_clear:
		return false
	var height: float = facts.ledge_height
	return height >= tuning.mantle_min_height and height <= tuning.mantle_max_height


## Plays one more fixed step of `delta` s, the runner having observed `facts`, and returns
## the velocity of that step.
func step(facts: RunnerFacts, delta: float) -> Vector3:
	steps += 1
	var crossing_steps: int = 0
	if _tuning.mantle_exit_speed > 0.0:
		var crossing: float = 2.0 * _tuning.capsule_radius / _tuning.mantle_exit_speed
		crossing_steps = roundi(crossing / delta)
	var rising_steps: int = maxi(_duration - crossing_steps, 1)
	var velocity: Vector3 = _onto * _tuning.mantle_exit_speed
	if steps <= rising_steps:
		var steps_left: int = rising_steps - steps + 1
		velocity.y = (_top - facts.altitude) / (steps_left * delta)
	else:
		velocity.y = -_tuning.fall_gravity * delta
	return velocity


## The mantle has lasted its time.
func is_over() -> bool:
	return steps >= _duration


## The fixed steps left of the mantle.
func steps_left() -> int:
	return maxi(_duration - steps, 0)
