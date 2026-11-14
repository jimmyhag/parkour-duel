class_name ScriptedIntentSource
extends IntentSource
## A sequence of intents written in advance, replayed one per fixed step: what lets a
## test play a section of a course in the real physics, without a screen or a hand.
## Once the sequence is over, the source wants nothing.

## For `aim`: the shot pressed at every step.
const ALL_STEPS: int = -2

var _intents: Array[MoveIntent] = []
var _cursor: int = 0


## Adds `steps` steps going in `direction` (in the world), with the jump held or not.
## The jump counts as pressed at the first step where it is held.
func hold(direction: Vector3, jump_held: bool, steps: int) -> ScriptedIntentSource:
	for i: int in steps:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = direction
		intent.jump_held = jump_held
		intent.jump_pressed = jump_held and not _last_step_holds_jump()
		_intents.append(intent)
	return self


## Adds `steps` steps going in `direction` (in the world) with the slide held. The slide
## counts as pressed at the first of them.
func slide(direction: Vector3, steps: int) -> ScriptedIntentSource:
	for i: int in steps:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = direction
		intent.slide_held = true
		intent.slide_pressed = i == 0
		_intents.append(intent)
	return self


## Adds `steps` steps going in `direction` (in the world) with the trick held, its
## drawing reading `recipe`, then one step where it is released.
func trick(recipe: TrickRecipe, direction: Vector3, steps: int) -> ScriptedIntentSource:
	for i: int in steps + 1:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = direction
		intent.trick_held = i < steps
		intent.trick_released = i == steps
		intent.trick_recipe = recipe
		_intents.append(intent)
	return self


## Adds `steps` steps going in `direction` (in the world) with the aim held; the shot is
## pressed at the step `shot_at` of them, if it is one, or at every step for ALL_STEPS. The
## jump held or not, pressed at the first step where it is held.
func aim(
	direction: Vector3, steps: int, shot_at: int = -1, jump_held: bool = false
) -> ScriptedIntentSource:
	for i: int in steps:
		var intent: MoveIntent = MoveIntent.new()
		intent.direction = direction
		intent.aim_held = true
		intent.shoot_pressed = i == shot_at or shot_at == ALL_STEPS
		intent.jump_held = jump_held
		intent.jump_pressed = jump_held and not _last_step_holds_jump()
		_intents.append(intent)
	return self


## Adds one step that asks to come back to the last checkpoint.
func request_respawn() -> ScriptedIntentSource:
	var intent: MoveIntent = MoveIntent.new()
	intent.respawn_requested = true
	_intents.append(intent)
	return self


## Adds one step that asks to restart the course.
func request_restart() -> ScriptedIntentSource:
	var intent: MoveIntent = MoveIntent.new()
	intent.restart_requested = true
	_intents.append(intent)
	return self


## The number of steps written so far.
func length() -> int:
	return _intents.size()


func next_intent() -> MoveIntent:
	if _cursor >= _intents.size():
		return MoveIntent.new()
	_cursor += 1
	return _intents[_cursor - 1]


func _last_step_holds_jump() -> bool:
	return not _intents.is_empty() and _intents[-1].jump_held
