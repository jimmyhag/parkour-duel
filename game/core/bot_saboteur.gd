class_name BotSaboteur
extends RefCounted
## The rule by which the bot chooses a target of the player's lane to sabotage: a ready
## target it can pay for with its ammunition, within the range of its shot, that the
## player nears (at most the lead of the tuning before it, along the way, and not past
## it). The cheapest one first; between two of the same cost, the one the player is
## nearest to.


## A target of the player's lane, as the bot sees it: how far it is from the bot's eyes,
## and how far the player is before it along the way (negative once past it), in m.
class Candidate:
	var target: SabotageTarget
	var distance: float
	var ahead: float

	func _init(
		candidate: SabotageTarget, distance_from_the_bot: float, player_ahead: float
	) -> void:
		target = candidate
		distance = distance_from_the_bot
		ahead = player_ahead


## The identity of the target to sabotage among `candidates`, with `ammo` in reserve;
## NO_TARGET if none may be.
static func choose(candidates: Array[Candidate], ammo: int, tuning: MovementTuning) -> int:
	var chosen: Candidate = null
	for candidate: Candidate in candidates:
		if not _may_sabotage(candidate, ammo, tuning):
			continue
		if chosen == null or _is_better(candidate, chosen):
			chosen = candidate
	return SabotageTarget.NO_TARGET if chosen == null else chosen.target.id


static func _may_sabotage(candidate: Candidate, ammo: int, tuning: MovementTuning) -> bool:
	var target: SabotageTarget = candidate.target
	if not target.is_ready() or target.cost() > ammo:
		return false
	if candidate.distance > tuning.shot_range:
		return false
	return candidate.ahead > 0.0 and candidate.ahead <= tuning.bot_sabotage_lead


static func _is_better(candidate: Candidate, than: Candidate) -> bool:
	if candidate.target.cost() != than.target.cost():
		return candidate.target.cost() < than.target.cost()
	return candidate.ahead < than.ahead
