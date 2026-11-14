class_name BotSaboteur
extends RefCounted
## The rule by which the bot chooses a target of the player's lane to sabotage: a ready
## target it can pay for with its ammunition, within the range of its shot, that the
## player nears (at most the lead of the tuning before it, along the way, and not past
## it) and approaches (nearer than at the step before), on a clear line of fire from the
## bot's head; never a target it already sabotaged since the player last reached a new
## checkpoint; and no aim started when a jump comes before the aim would end. The
## cheapest one first;
## between two of the same cost, the one the player is nearest to. It remembers how far
## the player was from each target at the last step it was asked, and what it sabotaged.

## How much nearer the player must get between two steps to approach, in m: less is the
## noise of a body at rest.
const APPROACH: float = 0.001


## A target of the player's lane, as the bot sees it: how far it is from the bot's eyes,
## how far the player is before it along the way (negative once past it), in m, and
## whether the line from the bot's head reaches it first, before any block.
class Candidate:
	var target: SabotageTarget
	var distance: float
	var ahead: float
	var line_clear: bool

	func _init(
		candidate: SabotageTarget,
		distance_from_the_bot: float,
		player_ahead: float,
		clear_line_of_fire: bool = true
	) -> void:
		target = candidate
		distance = distance_from_the_bot
		ahead = player_ahead
		line_clear = clear_line_of_fire


## How far before each target the player was at the last step, by target.
var _last_ahead: Dictionary[int, float] = {}
## The targets sabotaged since the player last reached a new checkpoint.
var _sabotaged: Dictionary[int, bool] = {}


## The identity of the target to sabotage among `candidates` at this step, with `ammo`
## in reserve, and whether the bot's pilot sees a jump to make before an aim started now
## would end; NO_TARGET if none may be. To ask at every step: the approach of the player
## is measured from one step to the next.
func choose(
	candidates: Array[Candidate], ammo: int, tuning: MovementTuning, jump_ahead: bool = false
) -> int:
	var chosen: Candidate = null
	for candidate: Candidate in candidates:
		var id: int = candidate.target.id
		var approaching: bool = _last_ahead.has(id)
		approaching = approaching and candidate.ahead < _last_ahead[id] - APPROACH
		_last_ahead[id] = candidate.ahead
		if not approaching or _sabotaged.has(id) or not _may_sabotage(candidate, ammo, tuning):
			continue
		if chosen == null or _is_better(candidate, chosen):
			chosen = candidate
	if chosen == null or jump_ahead:
		return SabotageTarget.NO_TARGET
	return chosen.target.id


## The bot's shot at `target` went.
func sabotaged(target: int) -> void:
	_sabotaged[target] = true


## The player reached a checkpoint farther than any before: every target may be sabotaged
## again.
func player_reached_a_checkpoint() -> void:
	_sabotaged.clear()


static func _may_sabotage(candidate: Candidate, ammo: int, tuning: MovementTuning) -> bool:
	var target: SabotageTarget = candidate.target
	if not candidate.line_clear or not target.is_ready() or target.cost() > ammo:
		return false
	if candidate.distance > tuning.shot_range:
		return false
	return candidate.ahead > 0.0 and candidate.ahead <= tuning.bot_sabotage_lead


static func _is_better(candidate: Candidate, than: Candidate) -> bool:
	if candidate.target.cost() != than.target.cost():
		return candidate.target.cost() < than.target.cost()
	return candidate.ahead < than.ahead
