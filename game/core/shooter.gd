class_name Shooter
extends RefCounted
## The weapon of one runner: whether it aims, what it aims at (the facts the player layer
## observed under the reticle, AimFacts), what its reticle shows, and its shots. A shot
## goes only once the aim has been held without a break for the least aim of the tuning,
## counted on the ground only (it waits in the air, without starting over) and from
## zero again after each shot,
## at a ready target within range that the runner can pay for: it is then a dated message
## (SabotageMessage) given to the board of the targets, and its cost is spent from the
## flow. Otherwise nothing happens and nothing is spent.

## What the reticle shows: nothing to shoot; a target it would hit; a target it could
## hit but cannot pay for.
enum Verdict { NONE, SHOOTABLE, TOO_EXPENSIVE }

## The runner it belongs to: who shoots.
var id: int
var aiming: bool = false
## What the runner aims at; nothing while it does not aim.
var aim: AimFacts = AimFacts.new()
var verdict: Verdict = Verdict.NONE
## The shots fired in the session, and the message of the last one.
var shots: int = 0
var last_message: SabotageMessage
var tuning: MovementTuning

var _steps_per_second: int
## Steps the aim has been held on the ground without a break, this one included: 0 while
## not aiming; it does not grow in the air.
var _steps_aiming: int = 0


func _init(runner_id: int, movement_tuning: MovementTuning, steps_per_second: int) -> void:
	id = runner_id
	tuning = movement_tuning
	_steps_per_second = steps_per_second


## One fixed step of the runner, at its step `step`: its intent, the facts under its
## reticle, the targets it may shoot (its own lane's in solo, the opposing lane's in a
## duel), its flow, and whether it is on the ground (on its feet, sliding or rolling).
## Returns the message of the shot it fired, or null.
func follow(
	intent: MoveIntent,
	facts: AimFacts,
	step: int,
	board: TargetBoard,
	flow: FlowState,
	on_the_ground: bool
) -> SabotageMessage:
	aiming = intent.aim_held
	aim = facts if aiming else AimFacts.new()
	if not aiming:
		_steps_aiming = 0
	elif on_the_ground:
		_steps_aiming += 1
	var message: SabotageMessage = null
	var aimed_enough: bool = _steps_aiming >= roundi(tuning.aim_min_time * _steps_per_second)
	if intent.shoot_pressed and aimed_enough and _judge(board, flow.ammo) == Verdict.SHOOTABLE:
		var target: SabotageTarget = board.target(aim.target)
		message = SabotageMessage.new(id, aim.target, step)
		if board.receive(message) and flow.spend(target.cost()):
			shots += 1
			last_message = message
			# Every shot pays its own least aim.
			_steps_aiming = 0
		else:
			message = null
	verdict = _judge(board, flow.ammo)
	return message


## The aim counted towards the next shot, in s: on the ground, since the aim was taken
## or since the last shot.
func aim_time() -> float:
	return float(_steps_aiming) / _steps_per_second


## The target the reticle is on, if a shot now would hit it; NO_TARGET otherwise.
func shootable_target() -> int:
	return aim.target if verdict == Verdict.SHOOTABLE else SabotageTarget.NO_TARGET


## What the reticle shows, aiming at what it aims at with `ammo` in reserve: a ready
## target of the lane of the board, within range, is shootable, or too expensive; anything
## else (a target of another lane among them) is nothing.
func _judge(board: TargetBoard, ammo: int) -> Verdict:
	if not aiming or aim.lane != board.lane:
		return Verdict.NONE
	var target: SabotageTarget = board.target(aim.target)
	if target == null or not target.is_ready() or aim.distance > tuning.shot_range:
		return Verdict.NONE
	return Verdict.SHOOTABLE if ammo >= target.cost() else Verdict.TOO_EXPENSIVE
