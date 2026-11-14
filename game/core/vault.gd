class_name Vault
extends RefCounted
## One vault of the runner over an obstacle, from the ground before it to the ground behind
## it (docs/specs/vault.md). Planned from what the runner observed as it started, it gives
## the velocity of each of its fixed steps: the way the runner went, at the speed it keeps
## out of the vault, or faster if that is what it takes to be clear of the obstacle in
## time. The feet rise to the top of the obstacle by the time the front of the runner
## reaches its face, stay there while its axis is over the obstacle, then come down to the
## ground it left by the end, pressed onto it with the weight of one step, so that they
## stand there. How far the runner went is read from its real velocity: a
## body held back catches up. The motor plays it; the presentation reads its obstacle.

## The horizontal direction of the vault, of length 1.
var heading: Vector3 = Vector3.FORWARD
## The altitude of the ground the runner left and of the top of the obstacle, in m, and how
## deep the obstacle is, the way the vault goes, in m.
var ground: float = 0.0
var top: float = 0.0
var depth: float = 0.0
## The fixed steps the vault has played.
var steps: int = 0

## The speed the runner keeps out of the vault, in m/s, how many fixed steps it lasts, and
## the fall gravity of the tuning, in m/s².
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
	_speed = horizontal.length() * tuning.vault_speed_kept
	_duration = maxi(duration_steps, 1)
	_gravity = tuning.fall_gravity
	ground = facts.altitude
	top = facts.altitude + facts.obstacle_height
	depth = facts.obstacle_depth
	_to_the_face = facts.obstacle_distance
	_past_the_back = facts.obstacle_distance + tuning.capsule_radius + facts.obstacle_depth
	_clear = _past_the_back + tuning.capsule_radius


## Whether a runner that observed `facts`, at the horizontal speed `speed`, may vault the
## obstacle ahead now: it is within reach, and a vault passes over it (passes_over).
static func fits(facts: RunnerFacts, speed: float, tuning: MovementTuning) -> bool:
	return facts.obstacle_distance <= tuning.vault_reach and passes_over(facts, speed, tuning)


## Whether a runner at the horizontal speed `speed` vaults the obstacle `facts` tell of, once
## within reach: fast enough, its top within the heights a vault passes over, not too deep,
## with room over it and behind it.
static func passes_over(facts: RunnerFacts, speed: float, tuning: MovementTuning) -> bool:
	if facts.obstacle_normal.is_zero_approx() or not facts.obstacle_clear:
		return false
	if speed < tuning.vault_min_speed or facts.obstacle_depth > tuning.vault_max_depth:
		return false
	var height: float = facts.obstacle_height
	return height >= tuning.vault_min_height and height <= tuning.vault_max_height


## Plays one more fixed step of `delta` s, the runner having observed `facts`, and returns
## the velocity of that step.
func step(facts: RunnerFacts, delta: float) -> Vector3:
	if steps > 0:
		var moved: Vector3 = Vector3(facts.velocity.x, 0.0, facts.velocity.z)
		_progress += moved.dot(heading) * delta
	steps += 1
	var steps_left: int = maxi(_duration - steps + 1, 1)
	var speed: float = maxf(_speed, (_clear - _progress) / (steps_left * delta))
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
