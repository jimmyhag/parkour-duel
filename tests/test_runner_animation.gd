extends GutTest
## The animation the runner's body shows, chosen from the state of its motor (game/core),
## without the Mixamo files: the clip of each state, its playback speed, its mirror along a
## wall, the tuck pose of a trick, the aim held by the upper body, and the brief landing.
## The tuning is the fixed one of MotorBody; the runners go along -Z.

const FORWARD: Vector3 = Vector3.FORWARD
## A wall at the left of a runner going along -Z (its normal points to the runner), and
## one at its right; close to its side, and tall.
const LEFT_WALL: Vector3 = Vector3.RIGHT
const RIGHT_WALL: Vector3 = Vector3.LEFT
const A_WALL: int = 1
const CLOSE: float = 0.3
const TALL: float = 10.0
## High enough above the floor for a wall run, and for a whole trick.
const ALONG_A_WALL: float = 3.0
const HIGH: float = 40.0
const STEP: float = MotorBody.STEP
## A small fall: well under the height that asks for a roll.
const SMALL_FALL: float = 1.0
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_every_state_of_the_runner_has_its_animation() -> void:
	var expected: Dictionary[RunnerMotor.State, RunnerAnimation.Clip] = {
		RunnerMotor.State.GROUNDED: RunnerAnimation.Clip.IDLE,
		RunnerMotor.State.RISING: RunnerAnimation.Clip.JUMP,
		RunnerMotor.State.FALLING: RunnerAnimation.Clip.FALLING_IDLE,
		RunnerMotor.State.HARD_LANDING: RunnerAnimation.Clip.HARD_LANDING,
		RunnerMotor.State.ROLLING: RunnerAnimation.Clip.FALLING_TO_ROLL,
		RunnerMotor.State.SLIDING: RunnerAnimation.Clip.RUNNING_SLIDE,
		RunnerMotor.State.MANTLING: RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB,
		RunnerMotor.State.WALL_RUNNING: RunnerAnimation.Clip.WALL_RUN,
	}
	assert_eq(expected.size(), RunnerMotor.State.size(), "every state of the motor is listed")
	for state: RunnerMotor.State in expected:
		var body: MotorBody = MotorBody.new(_tuning)
		body.step(MoveIntent.new())
		body.motor.state = state
		var animation: RunnerAnimation = RunnerAnimation.of(body.motor, MotorBody.STEP)
		assert_eq(
			animation.clip, expected[state], "the clip of %s" % RunnerMotor.State.keys()[state]
		)
		assert_false(animation.mirrored, "%s: not mirrored" % RunnerMotor.State.keys()[state])
		assert_false(
			animation.aiming, "%s: the upper body follows" % RunnerMotor.State.keys()[state]
		)

	var running: MotorBody = _running_at(_tuning.top_speed)
	assert_eq(
		RunnerAnimation.of(running.motor, MotorBody.STEP).clip,
		RunnerAnimation.Clip.RUNNING,
		"on the ground, moving"
	)


func test_an_abrupt_entry_is_made_without_a_blend() -> void:
	var running: RunnerAnimation = RunnerAnimation.of(_running_at(_tuning.top_speed).motor, STEP)
	assert_eq(running.blend_time, _tuning.animation_blend_time, "running: a blend")

	# A hard landing: a fall higher than a roll forgives, without the slide pressed.
	var falling: MotorBody = MotorBody.new(_tuning, _tuning.roll_fall_height + 1.0)
	falling.velocity = FORWARD * _tuning.top_speed
	_fall_until(falling, _push(FORWARD), RunnerMotor.State.HARD_LANDING)
	var hard: RunnerAnimation = RunnerAnimation.of(falling.motor, STEP)
	assert_eq(hard.clip, RunnerAnimation.Clip.HARD_LANDING, "a hard landing")
	assert_eq(hard.blend_time, 0.0, "without a blend")

	# A crash: a trick jumped from the run, landed without the press that poses it.
	var tricking: MotorBody = _running_at(_tuning.top_speed)
	var release: MoveIntent = _push(FORWARD)
	release.trick_released = true
	release.trick_recipe = TrickRecipe.of_the_context()
	tricking.step(release)
	assert_not_null(tricking.motor.current_trick(), "a trick from the run")
	var crashed: bool = false
	var steps: int = 0
	while not crashed and steps < MANY_STEPS:
		tricking.step(_push(FORWARD))
		for event: RunnerEvent in tricking.motor.events:
			crashed = crashed or event.kind == RunnerEvent.Kind.CRASH
		steps += 1
	assert_true(crashed, "a crash")
	var crash: RunnerAnimation = RunnerAnimation.of(tricking.motor, STEP)
	assert_eq(crash.clip, RunnerAnimation.Clip.HARD_LANDING, "a crash lands hard")
	assert_eq(crash.blend_time, 0.0, "without a blend")


func test_the_run_follows_the_speed() -> void:
	var half: RunnerAnimation = RunnerAnimation.of(
		_running_at(_tuning.top_speed / 2.0).motor, MotorBody.STEP
	)
	var full: RunnerAnimation = RunnerAnimation.of(
		_running_at(_tuning.top_speed).motor, MotorBody.STEP
	)

	assert_eq(half.clip, RunnerAnimation.Clip.RUNNING, "half the top speed: Running")
	assert_eq(full.clip, RunnerAnimation.Clip.RUNNING, "the top speed: Running")
	assert_lt(half.speed, full.speed, "played slower at half the top speed")
	assert_almost_eq(half.speed, full.speed / 2.0, 0.01, "in proportion to the speed")
	var pace: float = _tuning.top_speed / _tuning.animation_run_speed
	assert_almost_eq(full.speed, pace, 0.01, "its own pace at the tuned speed")


func test_the_wall_run_on_the_other_side_is_mirrored() -> void:
	var along_the_left: RunnerAnimation = RunnerAnimation.of(
		_wall_runner(LEFT_WALL).motor, MotorBody.STEP
	)
	var along_the_right: RunnerAnimation = RunnerAnimation.of(
		_wall_runner(RIGHT_WALL).motor, MotorBody.STEP
	)

	assert_eq(along_the_left.clip, RunnerAnimation.Clip.WALL_RUN, "a wall at its left: Wall Run")
	assert_eq(along_the_right.clip, RunnerAnimation.Clip.WALL_RUN, "a wall at its right: Wall Run")
	assert_ne(along_the_left.mirrored, along_the_right.mirrored, "mirrored for one of the two")


func test_a_trick_takes_the_tuck_pose() -> void:
	var body: MotorBody = MotorBody.new(_tuning, HIGH)
	body.velocity = FORWARD * _tuning.top_speed + Vector3.UP * 10.0
	var release: MoveIntent = MoveIntent.new()
	release.trick_released = true
	release.trick_recipe = TrickRecipe.of_the_context()
	body.step(release)
	assert_true(body.motor.is_in_a_trick(), "a trick under way")

	var animation: RunnerAnimation = RunnerAnimation.of(body.motor, MotorBody.STEP)
	assert_eq(animation.clip, RunnerAnimation.Clip.TUCK, "the tuck pose")

	while body.motor.is_in_a_trick():
		body.step(MoveIntent.new())
	animation = RunnerAnimation.of(body.motor, MotorBody.STEP)
	assert_eq(animation.clip, RunnerAnimation.Clip.FALLING_IDLE, "the trick over, the body unfolds")
	assert_eq(animation.blend_time, _tuning.animation_blend_time, "with a blend")


func test_aiming_takes_the_upper_body() -> void:
	var body: MotorBody = _running_at(_tuning.top_speed)
	var aim: MoveIntent = _push(FORWARD)
	aim.aim_held = true
	body.step(aim)

	var animation: RunnerAnimation = RunnerAnimation.of(body.motor, MotorBody.STEP)
	assert_eq(animation.clip, RunnerAnimation.Clip.RUNNING, "the legs run")
	assert_true(animation.aiming, "the upper body holds the aim")

	body.step(_push(FORWARD))
	assert_false(
		RunnerAnimation.of(body.motor, MotorBody.STEP).aiming, "the aim released, the body runs"
	)


func test_a_simple_landing_plays_landing_briefly() -> void:
	var body: MotorBody = MotorBody.new(_tuning, SMALL_FALL)
	body.velocity = FORWARD * _tuning.top_speed
	_fall_to_the_ground(body, _push(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.GROUNDED, "a simple landing")

	var landing_steps: int = roundi(_tuning.animation_landing_time / MotorBody.STEP)
	var clips: Array[RunnerAnimation.Clip] = [RunnerAnimation.of(body.motor, MotorBody.STEP).clip]
	for step: int in landing_steps + 1:
		body.step(_push(FORWARD))
		clips.append(RunnerAnimation.of(body.motor, MotorBody.STEP).clip)

	assert_eq(clips[0], RunnerAnimation.Clip.LANDING, "Landing as it touches the ground")
	assert_eq(
		clips[landing_steps - 1], RunnerAnimation.Clip.LANDING, "for the first steps on the ground"
	)
	assert_eq(clips[-1], RunnerAnimation.Clip.RUNNING, "then the run")
	var landing: RunnerAnimation = _landed_still()
	assert_eq(landing.clip, RunnerAnimation.Clip.LANDING, "Landing, standing still too")
	assert_eq(landing.duration, _tuning.animation_landing_time, "played in that time")


## A body on the floor that runs at `speed` along -Z, as it starts its next step.
func _running_at(speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, speed)
	body.step(_push(FORWARD * speed / _tuning.top_speed))
	return body


## A body that has just started to run along a wall whose normal is `normal`.
func _wall_runner(normal: Vector3) -> MotorBody:
	var body: MotorBody = MotorBody.new(_tuning, ALONG_A_WALL)
	body.velocity = FORWARD * _tuning.top_speed
	body.set_wall(A_WALL, normal, CLOSE, TALL)
	body.step(_push(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a wall runner")
	return body


## The animation of a body that has just landed from a small fall, without moving.
func _landed_still() -> RunnerAnimation:
	var body: MotorBody = MotorBody.new(_tuning, SMALL_FALL)
	_fall_to_the_ground(body, MoveIntent.new())
	return RunnerAnimation.of(body.motor, MotorBody.STEP)


## Steps `body` with `intent` until its motor has landed.
func _fall_to_the_ground(body: MotorBody, intent: MoveIntent) -> void:
	_fall_until(body, intent, RunnerMotor.State.GROUNDED)


## Steps `body` with `intent` until its motor is in `state`.
func _fall_until(body: MotorBody, intent: MoveIntent, state: RunnerMotor.State) -> void:
	var steps: int = 0
	while body.motor.state != state and steps < MANY_STEPS:
		body.step(intent)
		steps += 1


func _push(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent
