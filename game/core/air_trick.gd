class_name AirTrick
extends RefCounted
## One aerial trick of the runner, composed of three bricks: its flip, chosen by the push
## at the press; its turns, as long as the button is held when one ends; and its twists,
## the jump presses during a front flip or a backflip. The motor plays it in fixed steps;
## the presentation only reads its angles.

enum Flip {
	FRONT_FLIP,
	BACKFLIP,
	SIDE_FLIP,
	SPIN,
}

const FLIP_NAMES: Dictionary[Flip, String] = {
	Flip.FRONT_FLIP: "FRONT FLIP",
	Flip.BACKFLIP: "BACKFLIP",
	Flip.SIDE_FLIP: "SIDE FLIP",
}
const TURN_PREFIXES: Array[String] = ["", "", "DOUBLE ", "TRIPLE "]
const TWIST_SUFFIXES: Array[String] = ["", " FULL", " DOUBLE FULL", " TRIPLE FULL"]
const MANY_TURNS: String = "%dX "
const MANY_TWISTS: String = " %dX FULL"
const DEGREES_PER_TURN: int = 360
## Under this horizontal speed (m/s), a runner is almost still: its push is its front.
const ALMOST_STILL: float = 0.1
## The share of a quarter a push may stray past its edge and still count in it: the
## keyboard diagonal, computed with rounding errors, falls in the flip ahead or behind.
const EDGE: float = 0.0001

var flip: Flip
## The side of a side flip: 1 to the right, -1 to the left.
var side: int = 1
## The turns of the trick: the ones done, plus the one under way.
var turns: int = 1
var twists: int = 0
## Its last turn is over.
var finished: bool = false
## The fixed step of the motor at which it finished.
var finished_at: int = 0
## Its rank among the tricks of its jump, from 1.
var rank: int = 1
## It was the last trick of a perfect landing.
var perfect: bool = false
## The axis the body turns around, in the world, of length 1, and the way it turns
## around it: 1 or -1 (right-hand rule).
var axis: Vector3 = Vector3.UP
var way: float = 1.0

## Where the runner was going as the trick started, horizontal and of length 1, and its
## right.
var _front: Vector3 = Vector3.ZERO
var _right: Vector3 = Vector3.ZERO
## Fixed steps in one turn.
var _turn_steps: int = 1
## Fixed steps played since the trick started.
var _steps: int = 0
## Each twist: the step of the trick it started at, the step it ends at (the end of its
## turn), and the way it turns around the body (right-hand rule).
var _twist_starts: Array[int] = []
var _twist_ends: Array[int] = []
var _twist_ways: Array[float] = []


## A trick chosen by `push` for a runner whose horizontal velocity is `velocity`: a front
## flip in the quarter ahead of the velocity, a backflip in the quarter behind it, a side
## flip in a quarter aside, a spin without a push. A runner almost still takes its push
## for its front.
func _init(push: Vector3, velocity: Vector3, turn_steps: int, rank_in_the_jump: int) -> void:
	var wish: Vector3 = Vector3(push.x, 0.0, push.z)
	var front: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if front.length() < ALMOST_STILL:
		front = wish
	_front = front.normalized()
	_right = _front.cross(Vector3.UP)
	_turn_steps = maxi(turn_steps, 1)
	rank = rank_in_the_jump
	if wish.is_zero_approx():
		flip = Flip.SPIN
		axis = Vector3.UP
		way = -1.0
		return
	var ahead: float = wish.normalized().dot(_front)
	if ahead >= cos(PI / 4.0) - EDGE:
		flip = Flip.FRONT_FLIP
		axis = _right
		way = -1.0
	elif ahead <= -cos(PI / 4.0) + EDGE:
		flip = Flip.BACKFLIP
		axis = _right
		way = 1.0
	else:
		flip = Flip.SIDE_FLIP
		side = 1 if wish.dot(_right) > 0.0 else -1
		axis = _front
		way = side


## One more fixed step of the trick, the motor at `motor_step`. When a turn ends, the next
## one starts if the trick is still `held`; otherwise the trick is finished.
func advance(held: bool, motor_step: int) -> void:
	if finished:
		return
	_steps += 1
	if _steps < turns * _turn_steps:
		return
	if held:
		turns += 1
	else:
		finished = true
		finished_at = motor_step


## A jump pressed during the trick, the runner pushing `push`: a front flip and a
## backflip gain a twist, up to `most_per_turn` in the turn under way, to the side pushed
## (to the right without a push, or a push without a side).
func twist(push: Vector3, most_per_turn: int) -> void:
	if finished or (flip != Flip.FRONT_FLIP and flip != Flip.BACKFLIP):
		return
	var turn_end: int = turns * _turn_steps
	if _twist_ends.count(turn_end) >= most_per_turn:
		return
	var to_the_left: bool = Vector3(push.x, 0.0, push.z).dot(_right) < 0.0
	twists += 1
	_twist_starts.append(_steps)
	_twist_ends.append(turn_end)
	# Turning to the right, seen from above, is turning the negative way around up.
	_twist_ways.append(1.0 if to_the_left else -1.0)


## The name of the trick, built from its bricks: the turns as a prefix, the flip, the
## twists as a suffix; a spin is named by its degrees.
func name() -> String:
	if flip == Flip.SPIN:
		return str(turns * DEGREES_PER_TURN)
	var prefix: String = MANY_TURNS % turns
	if turns < TURN_PREFIXES.size():
		prefix = TURN_PREFIXES[turns]
	var suffix: String = MANY_TWISTS % twists
	if twists < TWIST_SUFFIXES.size():
		suffix = TWIST_SUFFIXES[twists]
	return prefix + FLIP_NAMES[flip] + suffix


## What tells two tricks apart for the repetition of the flow: their flip, their turns
## and their twists.
func identity() -> String:
	return "%s %d %d" % [Flip.keys()[flip], turns, twists]


## The points of the trick: per turn and per twist, raised for each trick done before it
## in its jump, then for a perfect landing.
func points(tuning: MovementTuning) -> int:
	var base: int = turns * tuning.trick_points_per_turn + twists * tuning.trick_points_per_twist
	var share: float = 1.0 + tuning.trick_air_chain_bonus * (rank - 1)
	if perfect:
		share *= 1.0 + tuning.trick_perfect_bonus
	return roundi(base * share)


## How far the body has turned around the axis of the flip in the turn under way, in
## radians, the way it turns; 0 once the trick is finished: the body is upright.
func flip_angle() -> float:
	if finished:
		return 0.0
	return way * TAU * float(_steps % _turn_steps) / _turn_steps


## How far the body has turned around its own axis, in radians: each twist does a whole
## turn, from where it started to the end of its turn.
func twist_angle() -> float:
	var angle: float = 0.0
	for index: int in _twist_starts.size():
		var length: int = _twist_ends[index] - _twist_starts[index]
		var done: float = clampf(float(_steps - _twist_starts[index]) / length, 0.0, 1.0)
		angle += _twist_ways[index] * TAU * done
	return fmod(angle, TAU)
