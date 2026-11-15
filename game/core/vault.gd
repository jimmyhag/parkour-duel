class_name Vault
extends RefCounted
## One vault of the runner over an obstacle, from the ground before it to the ground behind
## it (docs/specs/vault.md). Planned from what the runner observed as it started, it gives
## the velocity of each of its fixed steps: the way the runner went, at the speed it keeps
## out of the vault, or faster if that is what it takes to be clear of the obstacle in
## time, never faster than it came (what it cannot clear so, it does not vault). Its
## obstacle is measured across its face, whatever way the runner comes at it. The feet
## rise to the top of the obstacle by the time the front of the runner reaches its face,
## stay there while its axis is over the obstacle, then come down to the ground it left by
## the end, pressed onto it with the weight of one step, so that they stand there. How far
## the runner went is read from its real velocity: a body held back catches up. The motor
## plays it; the presentation reads its obstacle.

## The horizontal direction of the vault, of length 1.
var heading: Vector3 = Vector3.FORWARD
## The altitude of the ground the runner left and of the top of the obstacle, in m, and how
## deep the obstacle is, across its face, in m.
var ground: float = 0.0
var top: float = 0.0
var depth: float = 0.0
## The fixed steps the vault has played.
var steps: int = 0

## The speed the runner came with and the one it keeps out of the vault, in m/s, how many
## fixed steps it lasts, and the fall gravity of the tuning, in m/s².
var _entry: float = 0.0
var _speed: float = 0.0
var _duration: int = 1
var _gravity: float = 0.0
## Along the way of the vault, from where the runner's axis was as it started: how far the
## runner may go before its front reaches the face of the obstacle, how far its axis must go
## to be past the back of the obstacle, and how far to be clear of it; how far it went.
var _to_the_face: float = 0.0
var _past_the_back: float = 0.0
var _clear: float = 0.0
var _progress: float = 0.0


## The vault of a runner that observed `facts` (it moves, an obstacle ahead), with the
## tuning `tuning`, lasting `duration_steps` fixed steps (at least one).
func _init(facts: RunnerFacts, tuning: MovementTuning, duration_steps: int) -> void:
	var horizontal: Vector3 = Vector3(facts.velocity.x, 0.0, facts.velocity.z)
	heading = horizontal.normalized()
	_entry = horizontal.length()
	_speed = _entry * tuning.vault_speed_kept
	_duration = maxi(duration_steps, 1)
	_gravity = tuning.fall_gravity
	ground = facts.altitude
	top = facts.altitude + facts.obstacle_height
	depth = facts.obstacle_depth
	var slant: float = _slant(facts.obstacle_normal, heading)
	var radius: float = tuning.capsule_radius
	_to_the_face = facts.obstacle_distance / slant
	_past_the_back = (facts.obstacle_distance + radius + facts.obstacle_depth) / slant
	_clear = crossing(facts, heading, tuning)


## Whether a runner that observed `facts` (its velocity among them) may vault the obstacle
## ahead now: it is within reach, and a vault passes over it (passes_over).
static func fits(facts: RunnerFacts, tuning: MovementTuning) -> bool:
	if facts.obstacle_distance > tuning.vault_reach:
		return false
	return passes_over(facts, facts.velocity, tuning)


## Whether a runner coming at `velocity` vaults the obstacle `facts` tell of, once within
## reach: fast enough, its top within the heights a vault passes over, not too deep, with
## room over it and behind it, and clear of it in the time of a vault without going faster
## than it came.
static func passes_over(facts: RunnerFacts, velocity: Vector3, tuning: MovementTuning) -> bool:
	if facts.obstacle_normal.is_zero_approx() or not facts.obstacle_clear:
		return false
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed: float = horizontal.length()
	if speed < tuning.vault_min_speed or facts.obstacle_depth > tuning.vault_max_depth:
		return false
	var height: float = facts.obstacle_height
	if height < tuning.vault_min_height or height > tuning.vault_max_height:
		return false
	return crossing(facts, horizontal.normalized(), tuning) <= speed * tuning.vault_duration


## How far the axis of a runner going `heading` (horizontal, of length 1) must go to be
## clear of the obstacle `facts` tell of, from where it is, or from where it comes within
## reach if it is farther (where a vault starts at the latest), in m.
static func crossing(facts: RunnerFacts, heading: Vector3, tuning: MovementTuning) -> float:
	var distance: float = minf(facts.obstacle_distance, tuning.vault_reach)
	var across: float = distance + 2.0 * tuning.capsule_radius
	return (across + facts.obstacle_depth) / _slant(facts.obstacle_normal, heading)


## How far past the face of the obstacle `facts` tell of, the way it goes, the axis of a
## runner coming at `velocity` is at the end of its vault, at the farthest (the vault started
## against the face), in m.
static func landing(facts: RunnerFacts, velocity: Vector3, tuning: MovementTuning) -> float:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var slant: float = _slant(facts.obstacle_normal, horizontal.normalized())
	var radius: float = tuning.capsule_radius
	var run: float = horizontal.length() * tuning.vault_speed_kept * tuning.vault_duration
	return maxf(run - radius / slant, (radius + facts.obstacle_depth) / slant)


## How square to the face of normal `normal` the way `heading` goes: the cosine of the
## angle between them, horizontal, never under a tenth.
static func _slant(normal: Vector3, heading: Vector3) -> float:
	var across: Vector3 = Vector3(normal.x, 0.0, normal.z).normalized()
	return maxf(absf(across.dot(heading)), 0.1)


## Plays one more fixed step of `delta` s, the runner having observed `facts`, and returns
## the velocity of that step.
func step(facts: RunnerFacts, delta: float) -> Vector3:
	if steps > 0:
		var moved: Vector3 = Vector3(facts.velocity.x, 0.0, facts.velocity.z)
		_progress += moved.dot(heading) * delta
	steps += 1
	var steps_left: int = maxi(_duration - steps + 1, 1)
	var needed: float = (_clear - _progress) / (steps_left * delta)
	var speed: float = minf(maxf(_speed, needed), _entry)
	var velocity: Vector3 = heading * speed
	if _progress < _past_the_back:
		var steps_to_the_face: int = maxi(ceili((_to_the_face - _progress) / (speed * delta)), 1)
		velocity.y = (top - facts.altitude) / (mini(steps_to_the_face, steps_left) * delta)
	else:
		velocity.y = (ground - facts.altitude) / (steps_left * delta) - _gravity * delta
	return velocity


## The vault has lasted its time.
func is_over() -> bool:
	return steps >= _duration


## The velocity the runner comes out of the vault with: the speed it keeps, the way it went.
func exit_velocity() -> Vector3:
	return heading * _speed
