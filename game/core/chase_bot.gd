class_name ChaseBot
extends RefCounted
## The mind of the bot of the chase (docs/specs/chase-bot.md): at each decision it is
## given its position and its velocity, those of the other runner, and, as the mouse, the
## flee points of the arena with the lengths of the paths to them (ChaseBotCandidate,
## worked out by the player layer); it gives back its goal. The cat aims at where the
## other will be the lead of its level later, along the ground. The mouse runs to the
## flee point where it arrives with the most margin over the cat: the cat's path to it
## less its own, leaving out the points it cannot reach, those its path takes too close to
## the cat, and those nearer to it than a flight (unless no other is left); of points
## whose margins differ by less than the tie of margins (every point straight away from
## the cat has about the same), the farthest, to run away the longest. It keeps its point
## until the cat comes within the danger radius of the tuning, then runs to another one
## (not the one it ran to before), or until it is there. Its level sets how often it
## decides, how far it anticipates, which links it takes, how far it pushes, and its
## tricks. It sees no scene: only what it is given, and the tuning.

enum Level { EASY, NORMAL, HARD }

## The mouse has no flee point.
const NO_POINT: int = -1
## How near its flee point, along its path, the mouse is there, in m.
const REACHED: float = 2.0
## Margins that differ by less than this are the same, in m.
const MARGIN_TIE: float = 1.0
## A flee point nearer than this along the path is no flight, in m.
const FLIGHT: float = 4.0

var tuning: MovementTuning
var level: Level = Level.NORMAL
var role: ChaseState.Role = ChaseState.Role.CAT
## The flee point the mouse runs to, among the candidates of its decisions; NO_POINT for
## the cat, and for a mouse that has not chosen yet.
var flee_point: int = NO_POINT

## The cat was within the danger radius at the last decision.
var _cat_was_near: bool = false
## The flee point the mouse ran to before the one it runs to: it does not go back to it.
var _previous_point: int = NO_POINT


func _init(bot_tuning: MovementTuning, bot_level: Level) -> void:
	tuning = bot_tuning
	level = bot_level


## From now on plays `new_role`, with no flee point yet.
func play(new_role: ChaseState.Role) -> void:
	role = new_role
	flee_point = NO_POINT
	_cat_was_near = false
	_previous_point = NO_POINT


## The goal of the bot at `position` going at `_velocity` (which its paths already count),
## the other runner at `other_position` going at `other_velocity`, the flee points
## `candidates` (for the mouse; always the same points, in the same order).
func decide(
	position: Vector3,
	_velocity: Vector3,
	other_position: Vector3,
	other_velocity: Vector3,
	candidates: Array[ChaseBotCandidate]
) -> Vector3:
	if role == ChaseState.Role.CAT:
		var along: Vector3 = Vector3(other_velocity.x, 0.0, other_velocity.z)
		return other_position + along * lead()
	var apart: Vector3 = other_position - position
	var cat_distance: float = Vector2(apart.x, apart.z).length()
	var cat_is_near: bool = cat_distance < tuning.chase_bot_danger_radius
	if flee_point == NO_POINT or flee_point >= candidates.size():
		_change_point(cat_distance, candidates)
	elif cat_is_near and not _cat_was_near:
		_change_point(cat_distance, candidates)
	elif candidates[flee_point].distance <= REACHED:
		_change_point(cat_distance, candidates)
	_cat_was_near = cat_is_near
	if flee_point == NO_POINT:
		# Nowhere to go: away from the cat.
		var away: Vector3 = position - other_position
		return position + Vector3(away.x, 0.0, away.z).normalized() * tuning.chase_bot_danger_radius
	return candidates[flee_point].point


## The time between two decisions, in s.
func decision_time() -> float:
	return tuning.chase_bot_decision_time[level]


## How far ahead the cat aims, in s.
func lead() -> float:
	return tuning.chase_bot_lead[level]


## Whether the bot takes the links that climb: blocks to mantle and platforms.
func climbs() -> bool:
	return tuning.chase_bot_climbs[level]


## How far the bot pushes its stick (0 to 1).
func push() -> float:
	return tuning.chase_bot_push[level]


## Whether the bot does a simple trick as it goes down from a block or a platform.
func tricks() -> bool:
	return tuning.chase_bot_tricks[level]


## How long before touching the ground the bot presses the slide that poses its trick, in
## s.
func landing_press() -> float:
	return tuning.chase_bot_landing_press[level]


## The mouse runs to another point than the one it runs to, and than the one it ran to
## before, if there is one; to another than the one it runs to otherwise.
func _change_point(cat_distance: float, candidates: Array[ChaseBotCandidate]) -> void:
	var left: Array[int] = [flee_point, _previous_point]
	var chosen: int = _safest(cat_distance, candidates, left)
	if chosen == NO_POINT:
		chosen = _safest(cat_distance, candidates, [flee_point])
	if chosen != NO_POINT and chosen != flee_point:
		_previous_point = flee_point
		flee_point = chosen


## The point of the most margin over the cat among those the bot can reach, but those it
## leaves (`left`): first among those a flight away whose path keeps away from the cat
## (by the danger radius, or by the distance the cat is at now if that is less: a path
## that only goes away from a cat already near is safe); then among those nearer too;
## among them all if no path keeps away.
func _safest(cat_distance: float, candidates: Array[ChaseBotCandidate], left: Array[int]) -> int:
	var radius: float = tuning.chase_bot_danger_radius
	var clearance: float = minf(radius, cat_distance)
	var best: int = _most_margin(candidates, clearance, FLIGHT, left)
	if best == NO_POINT:
		best = _most_margin(candidates, clearance, REACHED, left)
	if best == NO_POINT:
		best = _most_margin(candidates, -INF, REACHED, left)
	return best


## The reachable point farther than `nearest` along the path, not `left`, of the most
## margin whose path passes at least `clearance` from the cat, the farthest of those tied
## for it; NO_POINT if there is none.
func _most_margin(
	candidates: Array[ChaseBotCandidate], clearance: float, nearest: float, left: Array[int]
) -> int:
	var open: Array[int] = []
	var best_margin: float = -INF
	for index: int in candidates.size():
		var candidate: ChaseBotCandidate = candidates[index]
		if index in left or is_inf(candidate.distance) or candidate.distance <= nearest:
			continue
		if candidate.cat_clearance < clearance:
			continue
		open.append(index)
		best_margin = maxf(best_margin, candidate.cat_distance - candidate.distance)
	var best: int = NO_POINT
	for index: int in open:
		var candidate: ChaseBotCandidate = candidates[index]
		if candidate.cat_distance - candidate.distance < best_margin - MARGIN_TIE:
			continue
		if best == NO_POINT or candidate.distance > candidates[best].distance:
			best = index
	return best
