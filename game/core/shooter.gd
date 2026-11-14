class_name Shooter
extends RefCounted
## The weapon of one runner: whether it aims, what it aims at (the facts the player layer
## observed under the reticle, AimFacts), what its reticle shows, and its shots. A shot
## goes only while aiming, at a ready target within range that the runner can pay for:
## it is then a dated message (SabotageMessage) given to the board of the targets, and
## its cost is spent from the flow. Otherwise nothing happens and nothing is spent.

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


func _init(runner_id: int, movement_tuning: MovementTuning) -> void:
	id = runner_id
	tuning = movement_tuning


## One fixed step of the runner, at its step `step`: its intent, the facts under its
## reticle, the targets it may shoot and its flow. Returns the message of the shot it
## fired, or null.
func follow(
	intent: MoveIntent, facts: AimFacts, step: int, board: TargetBoard, flow: FlowState
) -> SabotageMessage:
	aiming = intent.aim_held
	aim = facts if aiming else AimFacts.new()
	var message: SabotageMessage = null
	if intent.shoot_pressed and _judge(board, flow.ammo) == Verdict.SHOOTABLE:
		var target: SabotageTarget = board.target(aim.target)
		message = SabotageMessage.new(id, aim.target, step)
		if board.receive(message) and flow.spend(target.cost()):
			shots += 1
			last_message = message
		else:
			message = null
	verdict = _judge(board, flow.ammo)
	return message


## The target the reticle is on, if a shot now would hit it; NO_TARGET otherwise.
func shootable_target() -> int:
	return aim.target if verdict == Verdict.SHOOTABLE else SabotageTarget.NO_TARGET


## What the reticle shows, aiming at what it aims at with `ammo` in reserve: a ready
## target within range is shootable, or too expensive; anything else is nothing.
func _judge(board: TargetBoard, ammo: int) -> Verdict:
	if not aiming:
		return Verdict.NONE
	var target: SabotageTarget = board.target(aim.target)
	if target == null or not target.is_ready() or aim.distance > tuning.shot_range:
		return Verdict.NONE
	return Verdict.SHOOTABLE if ammo >= target.cost() else Verdict.TOO_EXPENSIVE
