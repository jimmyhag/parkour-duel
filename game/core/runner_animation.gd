class_name RunnerAnimation
extends RefCounted
## The animation the runner's body shows, chosen from the state of its motor at the step
## it just played: which clip, at what playback speed or in how long, mirrored or not,
## whether the upper body holds the aim, and how long the blend into it lasts. Choosing it
## is logic; playing it is presentation (game/player), with or without the clips. The
## clips are the Mixamo ones of docs/specs/character-animations.md, plus the tuck pose
## taken out of Backflip.

enum Clip {
	IDLE,
	RUNNING,
	JUMP,
	FALLING_IDLE,
	LANDING,
	HARD_LANDING,
	FALLING_TO_ROLL,
	RUNNING_SLIDE,
	SPRINT_TO_WALL_CLIMB,
	WALL_RUN,
	TUCK,
}

var clip: Clip = Clip.IDLE
## How fast the clip plays: 1 for its own pace.
var speed: float = 1.0
## How long the clip should take, in s, the move it shows lasting that long; 0 for its own
## length.
var duration: float = 0.0
## The clip plays mirrored, left for right. Wall Run has its wall at the runner's left:
## it is mirrored along a wall at its right.
var mirrored: bool = false
## The upper body holds the aim (Pistol Idle), whatever the legs do.
var aiming: bool = false
## How long the blend from the clip before into this one lasts, in s.
var blend_time: float = 0.0


## The animation of the runner whose motor is `motor`, at the step it just played, its
## fixed steps lasting `step_seconds`. On its feet: Idle when still, Running in proportion
## to its real speed, Landing for a moment after a simple landing; in the air: Jump
## rising, Falling Idle falling, the tuck pose while a trick is under way; each other
## state its clip, a hard landing (a crash too) without a blend.
static func of(motor: RunnerMotor, step_seconds: float) -> RunnerAnimation:
	var tuning: MovementTuning = motor.tuning
	var animation: RunnerAnimation = RunnerAnimation.new()
	animation.aiming = motor.is_aiming()
	animation.blend_time = tuning.animation_blend_time
	match motor.state:
		RunnerMotor.State.GROUNDED:
			var landing_steps: int = roundi(tuning.animation_landing_time / step_seconds)
			if motor.steps_since_landing < landing_steps:
				animation.clip = Clip.LANDING
				animation.duration = tuning.animation_landing_time
			elif motor.real_speed() >= tuning.animation_still_speed:
				animation.clip = Clip.RUNNING
				animation.speed = motor.real_speed() / tuning.animation_run_speed
		RunnerMotor.State.RISING:
			animation.clip = Clip.JUMP
		RunnerMotor.State.FALLING:
			animation.clip = Clip.FALLING_IDLE
		RunnerMotor.State.HARD_LANDING:
			animation.clip = Clip.HARD_LANDING
			animation.duration = tuning.hard_landing_duration
			animation.blend_time = 0.0
		RunnerMotor.State.ROLLING:
			animation.clip = Clip.FALLING_TO_ROLL
			animation.duration = tuning.roll_duration
		RunnerMotor.State.SLIDING:
			animation.clip = Clip.RUNNING_SLIDE
		RunnerMotor.State.MANTLING:
			animation.clip = Clip.SPRINT_TO_WALL_CLIMB
			animation.duration = tuning.mantle_duration
		RunnerMotor.State.WALL_RUNNING:
			animation.clip = Clip.WALL_RUN
			animation.duration = tuning.wall_run_duration
			animation.mirrored = _wall_at_the_right(motor)
	if motor.is_in_a_trick():
		animation.clip = Clip.TUCK
	return animation


## Whether the wall the runner runs along is at its right, the way it moves: the way
## away from it points to its left.
static func _wall_at_the_right(motor: RunnerMotor) -> bool:
	var motion: Vector3 = Vector3(motor.velocity.x, 0.0, motor.velocity.z)
	var right: Vector3 = motion.cross(Vector3.UP)
	return motor.wall_run_normal().dot(right) < 0.0
