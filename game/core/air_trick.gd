class_name AirTrick
extends RefCounted
## One aerial trick of the runner, done from its recipe (TrickRecipe): its flip, its
## turns and its twists. It lasts a turn per turn and a twist per twist; the body flips
## and twists evenly from its start to its end. The motor plays it in fixed steps; the
## presentation only reads its angles.

var recipe: TrickRecipe
## Its last step is over.
var finished: bool = false
## The fixed step of the motor at which it finished.
var finished_at: int = 0
## It was posed in a perfect landing.
var perfect: bool = false
## The axis the body flips around, in the world, of length 1, and the way it turns
## around it: 1 or -1 (right-hand rule).
var axis: Vector3 = Vector3.UP
var way: float = 1.0

## Fixed steps the trick lasts, and fixed steps played since it started.
var _duration: int = 1
var _steps: int = 0


## The trick of `trick_recipe` for a runner whose front is `front` (horizontal, of length
## 1), a turn lasting `turn_steps` fixed steps and a twist `twist_steps`.
func _init(trick_recipe: TrickRecipe, front: Vector3, turn_steps: int, twist_steps: int) -> void:
	recipe = trick_recipe
	_duration = maxi(recipe.turns * turn_steps + recipe.twists * twist_steps, 1)
	var right: Vector3 = front.cross(Vector3.UP)
	match recipe.flip:
		TrickRecipe.Flip.FRONT_FLIP:
			axis = right
			way = -1.0
		TrickRecipe.Flip.BACKFLIP:
			axis = right
			way = 1.0
		TrickRecipe.Flip.SIDE_FLIP:
			axis = front
			way = recipe.side
		TrickRecipe.Flip.SPIN:
			axis = Vector3.UP
			way = -1.0


## One more fixed step of the trick, the motor at `motor_step`.
func advance(motor_step: int) -> void:
	if finished:
		return
	_steps += 1
	if _steps >= _duration:
		finished = true
		finished_at = motor_step


## The name of its recipe.
func name() -> String:
	return recipe.name()


## What tells two tricks apart for the repetition of the flow: their recipe.
func identity() -> String:
	return recipe.identity()


## The points of the trick: the ones of its recipe, raised for a perfect landing.
func points(tuning: MovementTuning) -> int:
	var share: float = 1.0 + tuning.trick_perfect_bonus if perfect else 1.0
	return roundi(recipe.points(tuning) * share)


## How far the body has flipped around the axis of the flip in the turn under way, in
## radians, the way it turns; 0 once the trick is finished: the body is upright.
func flip_angle() -> float:
	if finished:
		return 0.0
	return way * fmod(TAU * recipe.turns * _steps / _duration, TAU)


## How far the body has twisted around its own axis in the twist under way, in radians;
## 0 once the trick is finished.
func twist_angle() -> float:
	if finished:
		return 0.0
	return recipe.twist_way * fmod(TAU * recipe.twists * _steps / _duration, TAU)
