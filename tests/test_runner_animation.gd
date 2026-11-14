extends GutTest
## The animation the runner's body shows, chosen from the state of its motor (game/core),
## without the Mixamo files: the clip of each state, its playback speed and its limit, the
## run along a wall and the roll of the body there, the tuck pose of a trick, the aim held
## by the upper body, the brief landing, and the table of blend times of the game. The
## tuning is the fixed one of MotorBody, or the game's where it says so; the runners go
## along -Z.

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
## The tuning of the game.
const TUNING: String = "res://game/core/movement_tuning.tres"
## Steps of a wall run held, then of the fall after it: longer than the roll takes, shorter
## than a wall run lasts.
const HOLD_STEPS: int = 30
## A wall run cut short: fewer steps than the roll takes.
const SHORT_STEPS: int = 4
## Ground speeds swept, from still to past the fastest a runner goes, and their step, in m/s.
const FASTEST: float = 16.0
const SPEED_STEP: float = 0.1
## The clips whose state lasts a fixed time, and the state of the motor each one shows.
const FIXED_DURATIONS: Dictionary[RunnerAnimation.Clip, RunnerMotor.State] = {
	RunnerAnimation.Clip.HARD_LANDING: RunnerMotor.State.HARD_LANDING,
	RunnerAnimation.Clip.FALLING_TO_ROLL: RunnerMotor.State.ROLLING,
	RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB: RunnerMotor.State.MANTLING,
}

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
		# Along a wall, the run (docs/specs/animation-polish.md).
		RunnerMotor.State.WALL_RUNNING: RunnerAnimation.Clip.RUNNING,
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
		assert_eq(
			animation.wall_side,
			RunnerAnimation.WallSide.NONE,
			"%s: along no wall" % RunnerMotor.State.keys()[state]
		)
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
	# Its pace keeps the feet up with the ground: the speed over the speed of the stride of
	# the clips it blends (docs/specs/locomotion-blend.md, decision 1).
	var own: float = RunnerAnimation.own_speed(half.locomotion, _tuning)
	assert_almost_eq(half.speed, _tuning.top_speed / 2.0 / own, 0.01, "in step with the ground")
	var pace: float = _tuning.top_speed / _tuning.animation_run_speed
	assert_almost_eq(full.speed, pace, 0.01, "its own pace at the tuned speed")


func test_the_wall_run_on_the_other_side_is_mirrored() -> void:
	var along_the_left: RunnerAnimation = RunnerAnimation.of(
		_wall_runner(LEFT_WALL).motor, MotorBody.STEP
	)
	var along_the_right: RunnerAnimation = RunnerAnimation.of(
		_wall_runner(RIGHT_WALL).motor, MotorBody.STEP
	)

	assert_eq(along_the_left.clip, RunnerAnimation.Clip.RUNNING, "a wall at its left: the run")
	assert_eq(along_the_right.clip, RunnerAnimation.Clip.RUNNING, "a wall at its right: the run")
	assert_eq(along_the_left.wall_side, RunnerAnimation.WallSide.LEFT, "the wall at its left")
	assert_eq(along_the_right.wall_side, RunnerAnimation.WallSide.RIGHT, "the wall at its right")
	# The body rolls its feet towards the wall: one way along a wall at its left, the
	# mirror way along a wall at its right.
	var full: float = deg_to_rad(_tuning.wall_run_body_roll)
	var left: float = _held_roll(along_the_left.wall_side)
	var right: float = _held_roll(along_the_right.wall_side)
	assert_almost_eq(left, -full, 0.0001, "a wall at its left: its head away, to its right")
	assert_almost_eq(right, full, 0.0001, "a wall at its right: its head away, to its left")


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


func test_the_wall_run_roll_rises_and_falls_smoothly() -> void:
	var full: float = deg_to_rad(_tuning.wall_run_body_roll)
	var rate: float = full / _tuning.wall_run_roll_time
	var rise_steps: int = roundi(_tuning.wall_run_roll_time / STEP)
	for normal: Vector3 in [LEFT_WALL, RIGHT_WALL]:
		var context: String = "a wall at its %s" % ("left" if normal == LEFT_WALL else "right")
		var way: float = -1.0 if normal == LEFT_WALL else 1.0
		var rolls: Array[float] = _rolls_along(normal, HOLD_STEPS)
		# It comes: from 0 to the tuned roll in the tuned time, at an even pace.
		for step: int in rise_steps:
			var expected: float = way * minf(rate * STEP * (step + 1), full)
			assert_almost_eq(rolls[step], expected, 0.0001, "%s: rising, step %d" % [context, step])
		# It holds.
		for step: int in range(rise_steps, HOLD_STEPS):
			assert_almost_eq(rolls[step], way * full, 0.0001, "%s: held, step %d" % [context, step])
		# It goes, in the same time, back to 0, and stays there.
		for step: int in HOLD_STEPS:
			var expected: float = way * maxf(full - rate * STEP * (step + 1), 0.0)
			var after: float = rolls[HOLD_STEPS + step]
			assert_almost_eq(after, expected, 0.0001, "%s: going, step %d" % [context, step])
		_assert_without_a_jump(rolls, rate * STEP, context)

	# A wall run cut short: the roll goes back from where it got to, without a jump.
	var short: Array[float] = _rolls_along(LEFT_WALL, SHORT_STEPS)
	assert_almost_eq(short[SHORT_STEPS - 1], -rate * STEP * SHORT_STEPS, 0.0001, "cut short")
	assert_almost_eq(short[-1], 0.0, 0.0001, "back upright")
	_assert_without_a_jump(short, rate * STEP, "a wall run cut short")


func test_in_a_wall_run_the_character_runs() -> void:
	var tier_three: float = _tuning.top_speed * (1.0 + _tuning.flow_tier_speed_bonus[2])
	var slow: float = (_tuning.wall_run_start_speed + _tuning.top_speed) / 2.0
	var between: float = (_tuning.top_speed + tier_three) / 2.0
	var fast: float = tier_three + 1.0
	var cases: Array[Array] = [
		[slow, [0.0, 0.0, 1.0, 0.0], "slow along the wall: Running"],
		[between, [0.0, 0.0, 0.5, 0.5], "faster: Running and Sprint"],
		[fast, [0.0, 0.0, 0.0, 1.0], "fast along the wall: Sprint"],
	]
	for case: Array in cases:
		var speed: float = case[0]
		var listed: Array = case[1]
		var weights: Array[float] = []
		weights.assign(listed)
		var context: String = case[2]
		var body: MotorBody = _wall_runner(LEFT_WALL, speed)
		for step: int in HOLD_STEPS:
			var animation: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
			assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, context + ": along it")
			assert_eq(animation.clip, RunnerAnimation.Clip.RUNNING, context + ": the run")
			assert_eq(animation.wall_side, RunnerAnimation.WallSide.LEFT, context + ": its side")
			for index: int in weights.size():
				assert_almost_eq(animation.locomotion[index], weights[index], 0.01, context)
			# Its feet keep up with the wall as they would with the ground.
			var stride: float = RunnerAnimation.own_speed(animation.locomotion, _tuning)
			var pace: float = minf(speed / stride, _tuning.animation_max_pace)
			assert_almost_eq(animation.speed, pace, 0.01, context + ": its pace")
			body.step(_push(FORWARD))
	# Never the clip Wall Run: the game has it no more.
	assert_false("WALL_RUN" in RunnerAnimation.Clip.keys(), "no clip Wall Run")
	for file: String in RunnerCharacter.CLIP_FILES.values():
		assert_false(file.contains("wall_run"), "%s: not the file of Wall Run" % file)


func test_no_clip_is_played_too_fast() -> void:
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	for tuning: MovementTuning in [_tuning, game_tuning]:
		var most: float = tuning.animation_max_pace
		var named: String = "the game's tuning" if tuning == game_tuning else "the fixed tuning"
		assert_almost_eq(most, 1.5, 0.0001, named + ": at most 1.5 times its own pace")
		# Each state of a fixed duration: its clip fitted to it, or its first part only.
		var states: Dictionary[RunnerAnimation.Clip, float] = _fixed_durations(tuning)
		for clip: RunnerAnimation.Clip in states:
			var duration: float = states[clip]
			var cut: Vector2 = RunnerCharacter.CUTS[clip]
			var length: float = cut.y - cut.x
			var pace: float = RunnerAnimation.fitted_pace(length, duration, tuning)
			var context: String = "%s, %s" % [named, RunnerAnimation.Clip.keys()[clip]]
			assert_gt(duration, 0.0, context + ": a fixed duration")
			assert_lte(pace, most + 0.0001, context + ": not too fast")
			assert_almost_eq(pace, minf(length / duration, most), 0.0001, context + ": fitted")
		# Every speed on the ground, and along a wall.
		var speed: float = 0.0
		while speed <= FASTEST:
			var running: RunnerAnimation = RunnerAnimation.of(
				_running_at(speed, tuning).motor, STEP
			)
			var context: String = "%s, %.1f m/s" % [named, speed]
			assert_lte(running.speed, most + 0.0001, context + " on the ground: not too fast")
			if speed >= tuning.wall_run_start_speed:
				var along: RunnerAnimation = RunnerAnimation.of(
					_wall_runner(LEFT_WALL, speed, tuning).motor, STEP
				)
				assert_lte(along.speed, most + 0.0001, context + " along a wall: not too fast")
			speed += SPEED_STEP


func test_the_table_of_blend_times_names_real_clips() -> void:
	# Every key of the game's table is "from>to", each side a clip as the table names it
	# (the locomotion as "running") or any clip: a key naming no clip would never be read.
	var names: Array[String] = [RunnerAnimation.ANY_CLIP]
	for clip: String in RunnerAnimation.Clip.keys():
		var named: RunnerAnimation.Clip = RunnerAnimation.Clip[clip]
		if named not in RunnerAnimation.LOCOMOTION or named == RunnerAnimation.Clip.RUNNING:
			names.append(clip.to_lower())
	var table: Dictionary[String, float] = (load(TUNING) as MovementTuning).animation_blend_times
	assert_gt(table.size(), 0, "the game has a table")
	for key: String in table:
		var pair: PackedStringArray = key.split(">")
		assert_eq(pair.size(), 2, "%s: a pair" % key)
		for side: String in pair:
			assert_has(names, side, "%s: %s is a clip of the table" % [key, side])
		assert_gt(table[key], 0.0, "%s: a blend time" % key)


## A body on the floor that runs at `speed` along -Z, as it starts its next step; with
## `tuning`, the fixed one by default.
func _running_at(speed: float, tuning: MovementTuning = null) -> MotorBody:
	var used: MovementTuning = _tuning if tuning == null else tuning
	var body: MotorBody = MotorBody.running(used, FORWARD, speed)
	body.step(_push(FORWARD * minf(speed / used.top_speed, 1.0)))
	return body


## A body that has just started to run along a wall whose normal is `normal`, at `speed`
## (the top speed by default), with `tuning` (the fixed one by default).
func _wall_runner(normal: Vector3, speed: float = -1.0, tuning: MovementTuning = null) -> MotorBody:
	var used: MovementTuning = _tuning if tuning == null else tuning
	var body: MotorBody = MotorBody.new(used, ALONG_A_WALL)
	body.velocity = FORWARD * (used.top_speed if speed < 0.0 else speed)
	body.set_wall(A_WALL, normal, CLOSE, TALL)
	body.step(_push(FORWARD))
	assert_eq(body.motor.state, RunnerMotor.State.WALL_RUNNING, "a wall runner")
	return body


## The roll of the body of a runner that enters a wall run along a wall whose normal is
## `normal`, holds it `steps` steps, then leaves it (the wall gone) for HOLD_STEPS steps:
## the roll after each step.
func _rolls_along(normal: Vector3, steps: int) -> Array[float]:
	var body: MotorBody = MotorBody.new(_tuning, HIGH)
	body.velocity = FORWARD * _tuning.top_speed
	body.set_wall(A_WALL, normal, CLOSE, TALL)
	var rolls: Array[float] = []
	var roll: float = 0.0
	for step: int in steps + HOLD_STEPS:
		if step == steps:
			body.remove_wall()
		body.step(_push(FORWARD))
		var along: bool = body.motor.state == RunnerMotor.State.WALL_RUNNING
		assert_eq(along, step < steps, "step %d: along the wall while it is there" % step)
		var animation: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
		roll = RunnerAnimation.wall_run_roll(roll, animation.wall_side, STEP, _tuning)
		rolls.append(roll)
	return rolls


## The roll of a body that has run along a wall at `side` for longer than the roll takes.
func _held_roll(side: RunnerAnimation.WallSide) -> float:
	var roll: float = 0.0
	for step: int in HOLD_STEPS:
		roll = RunnerAnimation.wall_run_roll(roll, side, STEP, _tuning)
	return roll


## From one roll to the next, never more than `most` (and a little).
func _assert_without_a_jump(rolls: Array[float], most: float, context: String) -> void:
	var before: float = 0.0
	for roll: float in rolls:
		assert_lte(absf(roll - before), most + 0.0001, context + ": without a jump")
		before = roll


## The duration of each state of a fixed duration with `tuning`, as its animation says.
func _fixed_durations(tuning: MovementTuning) -> Dictionary[RunnerAnimation.Clip, float]:
	var durations: Dictionary[RunnerAnimation.Clip, float] = {}
	for clip: RunnerAnimation.Clip in FIXED_DURATIONS:
		var body: MotorBody = MotorBody.new(tuning)
		body.step(MoveIntent.new())
		body.motor.state = FIXED_DURATIONS[clip]
		var animation: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
		assert_eq(animation.clip, clip, "the clip of %s" % RunnerAnimation.Clip.keys()[clip])
		durations[clip] = animation.duration
	var landing: RunnerAnimation = _landed_still(tuning)
	assert_eq(landing.clip, RunnerAnimation.Clip.LANDING, "a landing")
	durations[RunnerAnimation.Clip.LANDING] = landing.duration
	return durations


## The animation of a body that has just landed from a small fall, without moving; with
## `tuning`, the fixed one by default.
func _landed_still(tuning: MovementTuning = null) -> RunnerAnimation:
	var body: MotorBody = MotorBody.new(_tuning if tuning == null else tuning, SMALL_FALL)
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
