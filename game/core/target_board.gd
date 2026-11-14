class_name TargetBoard
extends RefCounted
## The targets of one lane of the course (SabotageTarget), by their identity in it: where
## the messages of sabotage arrive, and what tells which runners their effects hit. Two
## lanes are copies of the same course: their targets have the same identities, and the
## lane tells them apart.

var targets: Dictionary[int, SabotageTarget] = {}
## The lane of these targets, by the runner that runs it.
var lane: int = 0


func add(target: SabotageTarget) -> void:
	targets[target.id] = target


## The target of this identity; null if the course has none.
func target(id: int) -> SabotageTarget:
	return targets.get(id)


## A message of sabotage, given to the target it names: whether that target took it.
func receive(message: SabotageMessage) -> bool:
	var named: SabotageTarget = target(message.target)
	return named != null and named.receive(message)


## Whether the effect of a target hit `runner` at the step just played.
func hit(runner: int) -> bool:
	for each: SabotageTarget in targets.values():
		if each.hits.has(runner):
			return true
	return false


## Every target ready and in its place, as at the start of a run.
func reset() -> void:
	for each: SabotageTarget in targets.values():
		each.reset()


## Makes every target obey this tuning from now on.
func set_tuning(movement_tuning: MovementTuning) -> void:
	for each: SabotageTarget in targets.values():
		each.tuning = movement_tuning
