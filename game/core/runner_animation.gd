class_name RunnerAnimation
extends RefCounted
## The animation the runner's body shows, chosen from the state of its motor at the step
## it just played: which clip, at what playback speed or in how long, on which side the
## wall it runs along is, whether the upper body holds the aim, and how long the blend into
## it lasts. On its feet, the clip is the locomotion: a blend of Idle, Walking, Jogging,
## Running and Sprint on its horizontal speed (docs/specs/locomotion-blend.md,
## docs/specs/motion-weight.md); along a wall, the run of that blend, Running or Sprint by
## the speed along it, the whole body rolled, its feet towards the wall
## (docs/specs/animation-polish.md). In the air, one jump whose pose follows the vertical
## speed, until a long fall. No clip plays faster than the tuning allows. Choosing it is
## logic; playing it is presentation (game/player), with or without the clips: the phase of
## the stride, and how the rolled body lies against the wall, depend on the clips, and are
## chosen there. The clips are the Mixamo ones of docs/specs/character-animations.md,
## docs/specs/vault.md and docs/specs/motion-weight.md, plus the tuck pose taken out of
## Backflip.

enum Clip {
	IDLE,
	WALKING,
	JOGGING,
	RUNNING,
	SPRINT,
	JUMP,
	RUNNING_JUMP,
	FALLING_IDLE,
	LANDING,
	LAND_TO_RUN,
	HARD_LANDING,
	FALLING_TO_ROLL,
	RUNNING_SLIDE,
	LEDGE_PULL_UP,
	VAULT_ONE_HAND,
	VAULT_TWO_HANDS,
	TUCK,
}

## The side of the runner, the way it moves, where a wall is.
enum WallSide {
	NONE,
	LEFT,
	RIGHT,
}

## The clips of the locomotion, from the slowest to the fastest.
const LOCOMOTION: Array[Clip] = [Clip.IDLE, Clip.WALKING, Clip.JOGGING, Clip.RUNNING, Clip.SPRINT]
## The clips of a jump, posed by where the runner is in it (jump_position_of): from a run, and
## standing.
const JUMPS: Array[Clip] = [Clip.RUNNING_JUMP, Clip.JUMP]
## The clips of a simple landing, chosen as it touches down and kept until it ends.
const LANDINGS: Array[Clip] = [Clip.LANDING, Clip.LAND_TO_RUN]
## Where the top of a jump is, between its take-off (0) and the approach of the ground (1).
const TOP_OF_THE_JUMP: float = 0.5
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
## Where the locomotion is in its blend space (see locomotion_position_of): how much the clips
## that stride show over Idle, and where on their axis.
var locomotion_position: Vector2 = Vector2.ZERO
## In a jump (JUMPS), where the runner is in it, from 0 to 1 (see jump_position_of).
var jump_position: float = 0.0


## The animation of the runner whose motor is `motor`, at the step it just played, its
## fixed steps lasting `step_seconds`, after `before`, the animation of the step before
## (null: none). On its feet: the locomotion, its clips weighted by its real speed and
## played so that the feet keep up with the ground; for a moment after a simple landing,
## the landing (landing_clip); along a wall, the run, as fast as the runner goes along it;
## in the air, the jump posed by the vertical speed (_fly), Falling Idle in a long fall, the
## tuck pose while a trick is under way; in a vault, the gesture its obstacle asks for
## (vault_clip); each other state its clip. The locomotion follows the speed from the
## locomotion before, no faster than the tuning allows (docs/specs/animation-polish.md,
## decision 9). A new clip blends in as the table of the tuning says for the pair; a crash
## without a blend.
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
				animation.clip = landing_clip(motor.real_speed(), tuning)
				if motor.steps_since_landing > 0 and before != null and before.clip in LANDINGS:
					animation.clip = before.clip
				animation.duration = tuning.animation_landing_time
			else:
				animation._walk(motor.real_speed(), before, step_seconds, tuning)
		RunnerMotor.State.RISING, RunnerMotor.State.FALLING:
			if still_on_its_feet(motor, before):
				animation._hold(before)
			else:
				animation._fly(motor, before, step_seconds, tuning)
		RunnerMotor.State.HARD_LANDING:
			animation.clip = Clip.HARD_LANDING
			animation.duration = tuning.hard_landing_duration
		RunnerMotor.State.ROLLING:
			animation.clip = Clip.FALLING_TO_ROLL
			animation.duration = tuning.roll_duration
		RunnerMotor.State.SLIDING:
			animation.clip = Clip.RUNNING_SLIDE
		RunnerMotor.State.MANTLING:
			animation.clip = Clip.LEDGE_PULL_UP
			animation.duration = tuning.mantle_duration
		RunnerMotor.State.VAULTING:
			animation.clip = vault_clip(motor.vault, tuning)
			animation.duration = tuning.vault_duration
		RunnerMotor.State.WALL_RUNNING:
			animation._run_along_the_wall(motor, before, step_seconds, tuning)
	if motor.is_in_a_trick():
		animation.clip = Clip.TUCK
		animation.locomotion = []
		animation.speed = 1.0
	var from: Clip = animation.clip if before == null else before.clip
	animation.blend_time = blend_time_between(from, animation.clip, tuning)
	for event: RunnerEvent in motor.events:
		if event.kind == RunnerEvent.Kind.CRASH:
			animation.blend_time = 0.0
	return animation


## The clip of the vault `vault` (null: none known): Vault Two Hands over an obstacle
## deeper than the tuning vaults with one hand, Vault One Hand otherwise.
static func vault_clip(vault: Vault, tuning: MovementTuning) -> Clip:
	if vault != null and vault.depth > tuning.vault_two_hands_depth:
		return Clip.VAULT_TWO_HANDS
	return Clip.VAULT_ONE_HAND


## Whether a runner whose motor is `motor`, shown as `before` (null: none) the step before,
## still shows what it showed on its feet or along a wall: it has just stepped off them
## without a jump, and may still jump as from them (the coyote time, or the grace of a wall
## jump). A jump taken then starts from the take-off, not from the fall it would otherwise
## show (docs/specs/motion-weight.md, decision 6).
static func still_on_its_feet(motor: RunnerMotor, before: RunnerAnimation) -> bool:
	if motor.state != RunnerMotor.State.FALLING or before == null:
		return false
	if before.clip not in LOCOMOTION and before.clip not in LANDINGS:
		return false
	return motor.coyote_time_left() > 0.0 or motor.wall_jump_time_left() > 0.0


## The clip of a simple landing at the horizontal speed `speed`: Land To Run faster than a
## walk, Landing otherwise (docs/specs/motion-weight.md, decision 7).
static func landing_clip(speed: float, tuning: MovementTuning) -> Clip:
	return Clip.LAND_TO_RUN if speed > tuning.animation_walk_speed else Clip.LANDING


## The clip of a jump taken at the horizontal speed `speed`: Running Jump faster than a
## walk, Jump otherwise.
static func jump_clip(speed: float, tuning: MovementTuning) -> Clip:
	return Clip.RUNNING_JUMP if speed > tuning.animation_walk_speed else Clip.JUMP


## Where a runner in the air at the vertical speed `vertical_speed` (m/s, up) is in a jump,
## from 0 to 1 (docs/specs/motion-weight.md, decision 6): from the take-off (0, the speed of
## a full jump upwards) to the top (TOP_OF_THE_JUMP, no vertical speed) while it rises,
## then to the approach of the ground (1, the speed a full jump lands at) while it falls.
## Gravity being steady, it moves on at a steady pace in each half.
static func jump_position_of(vertical_speed: float, tuning: MovementTuning) -> float:
	if vertical_speed > 0.0:
		var rise: float = minf(vertical_speed / _take_off_speed(tuning), 1.0)
		return TOP_OF_THE_JUMP * (1.0 - rise)
	var fall: float = minf(-vertical_speed / _landing_speed(tuning), 1.0)
	return TOP_OF_THE_JUMP + (1.0 - TOP_OF_THE_JUMP) * fall


## Where a jump is `step` s after it was at `before`, on its way to `wanted`: no faster than
## animation_jump_catch_up times the pace of a full jump in its faster half, so that a jump
## released early (its rise cut short) moves the pose on without a jump.
static func jump_position_moved(
	before: float, wanted: float, step: float, tuning: MovementTuning
) -> float:
	var rise: float = _take_off_speed(tuning) / tuning.rise_gravity
	var fall: float = _landing_speed(tuning) / tuning.fall_gravity
	var fastest: float = maxf(TOP_OF_THE_JUMP / rise, (1.0 - TOP_OF_THE_JUMP) / fall)
	return move_toward(before, wanted, tuning.animation_jump_catch_up * fastest * step)


## Whether a runner falling at the vertical speed `vertical_speed` (m/s, up), in fixed steps
## of `step` s, falls longer than the descent of a jump: faster than a full jump lands, by
## more than the speed one step of its fall adds.
static func is_a_long_fall(vertical_speed: float, step: float, tuning: MovementTuning) -> bool:
	return -vertical_speed > _landing_speed(tuning) + tuning.fall_gravity * step


## The weight of each clip of the locomotion (LOCOMOTION) for a runner on its feet at the
## horizontal speed `speed`: Idle alone up to the still speed, Walking alone at its own
## speed, Jogging alone at its own speed, Running alone at its own speed times the pace the
## tuning gives it alone, Sprint alone from the top speed (docs/specs/locomotion-blend.md,
## decision 1 as amended; docs/specs/motion-weight.md, decision 4); between two of them,
## those two, in proportion. They sum to 1.
static func locomotion_weights(speed: float, tuning: MovementTuning) -> PackedFloat32Array:
	return locomotion_weights_at(locomotion_position_of(speed, tuning))


## Where a runner on its feet at the horizontal speed `speed` is in the blend space of the
## locomotion: how much the clips that stride show over Idle (x, from 0 at the still speed
## to 1 at the speed of Walking), and where on their axis (y, from 0 at the speed of Walking
## through 1 at the speed of Jogging and 2 where Running plays alone to 3 at the top speed,
## Sprint alone).
static func locomotion_position_of(speed: float, tuning: MovementTuning) -> Vector2:
	var points: PackedFloat32Array = [
		tuning.animation_walk_speed,
		tuning.animation_jog_speed,
		_running_alone(tuning),
		tuning.top_speed,
	]
	var still: float = tuning.animation_still_speed
	var moving: float = clampf((speed - still) / (points[0] - still), 0.0, 1.0)
	var along: float = float(points.size() - 1)
	for point: int in range(1, points.size()):
		if speed < points[point]:
			var share: float = (speed - points[point - 1]) / (points[point] - points[point - 1])
			along = point - 1 + clampf(share, 0.0, 1.0)
			break
	return Vector2(moving, along)


## The weight of each clip of the locomotion (LOCOMOTION) at `position` in its blend space
## (see locomotion_position_of): Idle as much as the clips that stride do not show, those
## shared between the two nearest on their axis. They sum to 1.
static func locomotion_weights_at(position: Vector2) -> PackedFloat32Array:
	var weights: PackedFloat32Array = []
	weights.resize(LOCOMOTION.size())
	weights[0] = 1.0 - position.x
	var last: int = LOCOMOTION.size() - 2
	var along: float = clampf(position.y, 0.0, last)
	var below: int = mini(floori(along), last - 1)
	var share: float = along - below
	weights[below + 1] += position.x * (1.0 - share)
	weights[below + 2] += position.x * share
	return weights


## Where the locomotion is in its blend space `step` s after it was at `before`, on its way
## to `wanted`: no faster than from standing to moving (x, 0 to 1), or from Walking to Sprint
## (y, 0 to 3), in the tuned start and stop time; at once without one.
static func locomotion_moved(
	before: Vector2, wanted: Vector2, step: float, tuning: MovementTuning
) -> Vector2:
	var time: float = tuning.animation_start_stop_time
	if time <= 0.0:
		return wanted
	var along: float = LOCOMOTION.size() - 2
	return Vector2(
		move_toward(before.x, wanted.x, step / time),
		move_toward(before.y, wanted.y, along * step / time)
	)


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
		tuning.animation_jog_speed,
		tuning.animation_run_speed,
		tuning.animation_sprint_speed,
	]


## How long the blend from the clip `from` into the clip `to` lasts, in s: the default from
## a clip into itself (no blend happens); otherwise the table of the tuning (the pair, then
## any clip into `to`, then `from` into any clip), or its default. A crash comes without a
## blend whatever the table says (see of).
static func blend_time_between(from: Clip, to: Clip, tuning: MovementTuning) -> float:
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


## The animation of a runner in the air, after the animation `before` (null: none), `step`
## s ago: Falling Idle in a long fall; otherwise the jump of its take-off (jump_clip, kept
## until it lands), posed where its vertical speed puts it in the jump, on its way there
## from where it was.
func _fly(motor: RunnerMotor, before: RunnerAnimation, step: float, tuning: MovementTuning) -> void:
	if motor.state == RunnerMotor.State.FALLING and is_a_long_fall(motor.velocity.y, step, tuning):
		clip = Clip.FALLING_IDLE
		return
	var wanted: float = jump_position_of(motor.velocity.y, tuning)
	if before != null and before.clip in JUMPS:
		clip = before.clip
		jump_position = jump_position_moved(before.jump_position, wanted, step, tuning)
		return
	clip = jump_clip(motor.real_speed(), tuning)
	jump_position = wanted


## What `before` showed, as it showed it (see still_on_its_feet).
func _hold(before: RunnerAnimation) -> void:
	clip = before.clip
	speed = before.speed
	duration = before.duration
	wall_side = before.wall_side
	locomotion = before.locomotion.duplicate()
	locomotion_position = before.locomotion_position
	jump_position = before.jump_position


## The locomotion of a runner on its feet at the horizontal speed `ground_speed`, after
## the animation `before` (null: none), `step` s ago: its weights, on their way from the
## locomotion before; Idle when it stands; and the pace of the clips that move, the feet
## keeping up with the ground.
func _walk(
	ground_speed: float, before: RunnerAnimation, step: float, tuning: MovementTuning
) -> void:
	_move_the_locomotion(locomotion_position_of(ground_speed, tuning), before, step, tuning)
	if locomotion[0] >= 1.0:
		clip = Clip.IDLE
		return
	clip = Clip.RUNNING
	_keep_up_with(ground_speed, tuning)


## The run of a runner along a wall, as fast as it goes along it: Running up to where it
## plays alone on the ground, then as on the ground, blended into Sprint up to the top speed,
## on its way from the locomotion before; its feet keep up with the wall.
func _run_along_the_wall(
	motor: RunnerMotor, before: RunnerAnimation, step: float, tuning: MovementTuning
) -> void:
	wall_side = _side_of_the_wall(motor)
	var away: Vector3 = motor.wall_run_normal()
	var motion: Vector3 = Vector3(motor.velocity.x, 0.0, motor.velocity.z)
	var along: float = (motion - away * motion.dot(away)).length()
	var wanted: Vector2 = locomotion_position_of(maxf(along, _running_alone(tuning)), tuning)
	_move_the_locomotion(wanted, before, step, tuning)
	clip = Clip.RUNNING
	_keep_up_with(along, tuning)


## Puts the locomotion at `wanted` in its blend space, or on its way there from the
## locomotion of `before`, `step` s ago, when it showed one.
func _move_the_locomotion(
	wanted: Vector2, before: RunnerAnimation, step: float, tuning: MovementTuning
) -> void:
	locomotion_position = wanted
	if before != null and not before.locomotion.is_empty():
		locomotion_position = locomotion_moved(before.locomotion_position, wanted, step, tuning)
	locomotion = locomotion_weights_at(locomotion_position)


## The pace of the locomotion whose foot goes back at `ground_speed`, never faster than the
## tuning allows.
func _keep_up_with(ground_speed: float, tuning: MovementTuning) -> void:
	speed = minf(ground_speed / own_speed(locomotion, tuning), tuning.animation_max_pace)


## The name of `clip` in the table of blend times: the locomotion is "running".
static func _table_name(clip: Clip) -> String:
	var named: Clip = Clip.RUNNING if clip in LOCOMOTION else clip
	var name: String = Clip.keys()[named]
	return name.to_lower()


## The vertical speed of a full jump as it takes off, and as it lands, in m/s.
static func _take_off_speed(tuning: MovementTuning) -> float:
	return sqrt(2.0 * tuning.rise_gravity * tuning.jump_height)


static func _landing_speed(tuning: MovementTuning) -> float:
	return sqrt(2.0 * tuning.fall_gravity * tuning.jump_height)


## The speed at which Running plays alone, in m/s.
static func _running_alone(tuning: MovementTuning) -> float:
	return tuning.animation_run_speed * tuning.animation_run_alone_pace


## The side of the wall the runner runs along, the way it moves: the way away from it
## points to the other side.
static func _side_of_the_wall(motor: RunnerMotor) -> WallSide:
	var motion: Vector3 = Vector3(motor.velocity.x, 0.0, motor.velocity.z)
	var right: Vector3 = motion.cross(Vector3.UP)
	var away: float = motor.wall_run_normal().dot(right)
	if is_zero_approx(away):
		return WallSide.NONE
	return WallSide.RIGHT if away < 0.0 else WallSide.LEFT
