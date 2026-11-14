class_name RunnerAnimation
extends RefCounted
## The animation the runner's body shows, chosen from the state of its motor at the step
## it just played: which clip, at what playback speed or in how long, on which side the
## wall it runs along is, whether the upper body holds the aim, and how long the blend into
## it lasts. On its feet, the clip is the locomotion: a blend of Idle, Walking, Running and
## Sprint on its horizontal speed (docs/specs/locomotion-blend.md); along a wall, the run of
## that blend, Running or Sprint by the speed along it, the whole body rolled, its feet
## towards the wall (docs/specs/animation-polish.md). No clip plays faster than the tuning
## allows. Choosing it is logic; playing it is presentation (game/player), with or without
## the clips: the phase of the stride, and how the rolled body lies against the wall,
## depend on the clips, and are chosen there. The clips are the Mixamo ones of
## docs/specs/character-animations.md, plus the tuck pose taken out of Backflip.

enum Clip {
	IDLE,
	WALKING,
	RUNNING,
	SPRINT,
	JUMP,
	FALLING_IDLE,
	LANDING,
	HARD_LANDING,
	FALLING_TO_ROLL,
	RUNNING_SLIDE,
	SPRINT_TO_WALL_CLIMB,
	TUCK,
}

## The side of the runner, the way it moves, where a wall is.
enum WallSide {
	NONE,
	LEFT,
	RIGHT,
}

## The clips of the locomotion, from the slowest to the fastest.
const LOCOMOTION: Array[Clip] = [Clip.IDLE, Clip.WALKING, Clip.RUNNING, Clip.SPRINT]
## In the table of blend times: any clip, and what parts a pair.
const ANY_CLIP: String = "*"
const PAIR: String = "%s>%s"

var clip: Clip = Clip.IDLE
## How fast the clip plays: 1 for its own pace.
var speed: float = 1.0
## How long the clip should take, in s, the move it shows lasting that long; 0 for its own
## length.
var duration: float = 0.0
## The side of the wall the runner runs along, the way it moves: NONE along no wall.
var wall_side: WallSide = WallSide.NONE
## The upper body holds the aim (Pistol Idle), whatever the legs do.
var aiming: bool = false
## How long the blend from the clip before into this one lasts, in s.
var blend_time: float = 0.0
## On its feet or along a wall (the clip IDLE or RUNNING), the weight of each clip of the
## locomotion, in the order of LOCOMOTION; empty otherwise.
var locomotion: PackedFloat32Array = []


## The animation of the runner whose motor is `motor`, at the step it just played, its
## fixed steps lasting `step_seconds`, after `before`, the animation of the step before
## (null: none). On its feet: the locomotion, its clips weighted by its real speed and
## played so that the feet keep up with the ground; Landing for a moment after a simple
## landing; along a wall, the run, as fast as the runner goes along it; in the air: Jump
## rising, Falling Idle falling, the tuck pose while a trick is under way; each other state
## its clip. A new clip blends in as the table of the tuning says for the pair; a hard
## landing (a crash too) without a blend.
static func of(
	motor: RunnerMotor, step_seconds: float, before: RunnerAnimation = null
) -> RunnerAnimation:
	var tuning: MovementTuning = motor.tuning
	var animation: RunnerAnimation = RunnerAnimation.new()
	animation.aiming = motor.is_aiming()
	match motor.state:
		RunnerMotor.State.GROUNDED:
			var landing_steps: int = roundi(tuning.animation_landing_time / step_seconds)
			if motor.steps_since_landing < landing_steps:
				animation.clip = Clip.LANDING
				animation.duration = tuning.animation_landing_time
			else:
				animation._walk(motor.real_speed(), tuning)
		RunnerMotor.State.RISING:
			animation.clip = Clip.JUMP
		RunnerMotor.State.FALLING:
			animation.clip = Clip.FALLING_IDLE
		RunnerMotor.State.HARD_LANDING:
			animation.clip = Clip.HARD_LANDING
			animation.duration = tuning.hard_landing_duration
		RunnerMotor.State.ROLLING:
			animation.clip = Clip.FALLING_TO_ROLL
			animation.duration = tuning.roll_duration
		RunnerMotor.State.SLIDING:
			animation.clip = Clip.RUNNING_SLIDE
		RunnerMotor.State.MANTLING:
			animation.clip = Clip.SPRINT_TO_WALL_CLIMB
			animation.duration = tuning.mantle_duration
		RunnerMotor.State.WALL_RUNNING:
			animation._run_along_the_wall(motor, tuning)
	if motor.is_in_a_trick():
		animation.clip = Clip.TUCK
		animation.locomotion = []
		animation.speed = 1.0
	var from: Clip = animation.clip if before == null else before.clip
	animation.blend_time = blend_time_between(from, animation.clip, tuning)
	return animation


## The weight of each clip of the locomotion (LOCOMOTION) for a runner on its feet at the
## horizontal speed `speed`: Idle alone up to the still speed, Walking alone at its own
## speed, Running alone at the top speed, Sprint alone from the top speed of the last tier
## of the flow; between two of them, those two, in proportion. They sum to 1.
static func locomotion_weights(speed: float, tuning: MovementTuning) -> PackedFloat32Array:
	var points: PackedFloat32Array = [
		tuning.animation_still_speed,
		tuning.animation_walk_speed,
		tuning.top_speed,
		tuning.top_speed * (1.0 + _last_tier_bonus(tuning)),
	]
	var weights: PackedFloat32Array = []
	weights.resize(points.size())
	if speed <= points[0]:
		weights[0] = 1.0
		return weights
	for point: int in range(1, points.size()):
		if speed < points[point]:
			var share: float = (speed - points[point - 1]) / (points[point] - points[point - 1])
			weights[point - 1] = 1.0 - clampf(share, 0.0, 1.0)
			weights[point] = clampf(share, 0.0, 1.0)
			return weights
	weights[points.size() - 1] = 1.0
	return weights


## The speed of the stride of the blend of the locomotion weighted by `weights`: how fast
## its foot on the ground goes back when its clips play at their own pace, in m/s. Idle
## strides not: as much as it weighs, the stride is shorter. The speed of Walking when only
## Idle weighs.
static func own_speed(weights: PackedFloat32Array, tuning: MovementTuning) -> float:
	var speeds: PackedFloat32Array = stride_speeds(tuning)
	var speed: float = 0.0
	for clip: int in weights.size():
		speed += weights[clip] * speeds[clip]
	if speed <= 0.0:
		return tuning.animation_walk_speed
	return speed


## The speed of the stride of each clip of the locomotion (LOCOMOTION), in m/s: none for
## Idle.
static func stride_speeds(tuning: MovementTuning) -> PackedFloat32Array:
	return [
		0.0,
		tuning.animation_walk_speed,
		tuning.animation_run_speed,
		tuning.animation_sprint_speed,
	]


## How long the blend from the clip `from` into the clip `to` lasts, in s: none into a hard
## landing; the default from a clip into itself (no blend happens); otherwise the table of
## the tuning (the pair, then any clip into `to`, then `from` into any clip), or its
## default.
static func blend_time_between(from: Clip, to: Clip, tuning: MovementTuning) -> float:
	if to == Clip.HARD_LANDING:
		return 0.0
	if from == to:
		return tuning.animation_blend_time
	var table: Dictionary[String, float] = tuning.animation_blend_times
	var keys: Array[String] = [
		PAIR % [_table_name(from), _table_name(to)],
		PAIR % [ANY_CLIP, _table_name(to)],
		PAIR % [_table_name(from), ANY_CLIP],
	]
	for key: String in keys:
		if table.has(key):
			return table[key]
	return tuning.animation_blend_time


## How fast a clip `length` s long plays to last `duration` s (its own pace without a
## duration), never faster than the tuning allows: a clip too long for its move plays its
## first part only.
static func fitted_pace(length: float, duration: float, tuning: MovementTuning) -> float:
	if duration <= 0.0:
		return 1.0
	return minf(length / duration, tuning.animation_max_pace)


## The roll of the body about the way it runs, in radians (positive: its head to its left),
## `step` s after it was `roll`, the wall the runner runs along at `wall_side`: towards the
## tuned roll, its feet towards the wall and its head away from it, or back to upright
## along no wall; at a pace that goes from upright to the tuned roll in the tuned time.
static func wall_run_roll(
	roll: float, wall_side: WallSide, step: float, tuning: MovementTuning
) -> float:
	var full: float = deg_to_rad(tuning.wall_run_body_roll)
	var wanted: float = 0.0
	if wall_side == WallSide.LEFT:
		wanted = -full
	elif wall_side == WallSide.RIGHT:
		wanted = full
	if tuning.wall_run_roll_time <= 0.0:
		return wanted
	return move_toward(roll, wanted, full / tuning.wall_run_roll_time * step)


## The locomotion of a runner on its feet at the horizontal speed `ground_speed`: its
## weights, Idle when it stands, and the pace of the clips that move, the feet keeping up
## with the ground.
func _walk(ground_speed: float, tuning: MovementTuning) -> void:
	locomotion = locomotion_weights(ground_speed, tuning)
	if locomotion[0] >= 1.0:
		clip = Clip.IDLE
		return
	clip = Clip.RUNNING
	_keep_up_with(ground_speed, tuning)


## The run of a runner along a wall, as fast as it goes along it: Running up to the top
## speed, blended into Sprint above it, as on the ground; its feet keep up with the wall.
func _run_along_the_wall(motor: RunnerMotor, tuning: MovementTuning) -> void:
	wall_side = _side_of_the_wall(motor)
	var away: Vector3 = motor.wall_run_normal()
	var motion: Vector3 = Vector3(motor.velocity.x, 0.0, motor.velocity.z)
	var along: float = (motion - away * motion.dot(away)).length()
	locomotion = locomotion_weights(maxf(along, tuning.top_speed), tuning)
	clip = Clip.RUNNING
	_keep_up_with(along, tuning)


## The pace of the locomotion whose foot goes back at `ground_speed`, never faster than the
## tuning allows.
func _keep_up_with(ground_speed: float, tuning: MovementTuning) -> void:
	speed = minf(ground_speed / own_speed(locomotion, tuning), tuning.animation_max_pace)


## The name of `clip` in the table of blend times: the locomotion is "running".
static func _table_name(clip: Clip) -> String:
	var named: Clip = Clip.RUNNING if clip in LOCOMOTION else clip
	var name: String = Clip.keys()[named]
	return name.to_lower()


## The share of the top speed the last tier of the flow adds.
static func _last_tier_bonus(tuning: MovementTuning) -> float:
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var last: int = mini(tuning.flow_tier_count, bonuses.size())
	return 0.0 if last <= 0 else bonuses[last - 1]


## The side of the wall the runner runs along, the way it moves: the way away from it
## points to the other side.
static func _side_of_the_wall(motor: RunnerMotor) -> WallSide:
	var motion: Vector3 = Vector3(motor.velocity.x, 0.0, motor.velocity.z)
	var right: Vector3 = motion.cross(Vector3.UP)
	var away: float = motor.wall_run_normal().dot(right)
	if is_zero_approx(away):
		return WallSide.NONE
	return WallSide.RIGHT if away < 0.0 else WallSide.LEFT
