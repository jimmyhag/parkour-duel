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
	RunnerAnimation.Clip.LEDGE_PULL_UP: RunnerMotor.State.MANTLING,
	RunnerAnimation.Clip.VAULT_ONE_HAND: RunnerMotor.State.VAULTING,
	RunnerAnimation.Clip.VAULT_TWO_HANDS: RunnerMotor.State.VAULTING,
	RunnerAnimation.Clip.DIVE: RunnerMotor.State.DIVING,
	RunnerAnimation.Clip.GETTING_UP: RunnerMotor.State.DOWN,
}
## A low wall, a thin one and one deeper than the fixed tuning vaults with one hand; where
## it stands before the runner as it starts, out of reach; the speed of the run at it.
const WALL_HEIGHT: float = 1.0
const THIN: float = 0.4
const DEEP: float = 1.2
const WALL_DISTANCE: float = 2.0
const RUN_SPEED: float = 6.0

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_every_state_of_the_runner_has_its_animation() -> void:
	var expected: Dictionary[RunnerMotor.State, RunnerAnimation.Clip] = {
		RunnerMotor.State.GROUNDED: RunnerAnimation.Clip.IDLE,
		# In the air, standing: the jump of a standing body, posed by its vertical speed
		# (docs/specs/motion-weight.md, decision 6).
		RunnerMotor.State.RISING: RunnerAnimation.Clip.JUMP,
		RunnerMotor.State.FALLING: RunnerAnimation.Clip.JUMP,
		RunnerMotor.State.HARD_LANDING: RunnerAnimation.Clip.HARD_LANDING,
		RunnerMotor.State.ROLLING: RunnerAnimation.Clip.FALLING_TO_ROLL,
		RunnerMotor.State.SLIDING: RunnerAnimation.Clip.RUNNING_SLIDE,
		RunnerMotor.State.MANTLING: RunnerAnimation.Clip.LEDGE_PULL_UP,
		# Over a thin obstacle, or with none known: one hand.
		RunnerMotor.State.VAULTING: RunnerAnimation.Clip.VAULT_ONE_HAND,
		# Along a wall, the run (docs/specs/animation-polish.md).
		RunnerMotor.State.WALL_RUNNING: RunnerAnimation.Clip.RUNNING,
		# The dive of the cat, and its getting up after one missed (docs/specs/chase-tag.md).
		RunnerMotor.State.DIVING: RunnerAnimation.Clip.DIVE,
		RunnerMotor.State.DOWN: RunnerAnimation.Clip.GETTING_UP,
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


func test_the_gesture_follows_the_depth_of_the_obstacle() -> void:
	var clips: Array[RunnerAnimation.Clip] = []
	for depth: float in [THIN, DEEP]:
		var body: MotorBody = MotorBody.running(_tuning, FORWARD, RUN_SPEED)
		body.put_block_ahead(WALL_DISTANCE, WALL_HEIGHT, depth)
		var steps: int = 0
		while body.motor.state != RunnerMotor.State.VAULTING and steps < MANY_STEPS:
			body.step(_push(FORWARD * RUN_SPEED / _tuning.top_speed))
			steps += 1
		var context: String = "%.1f m deep: " % depth
		assert_eq(body.motor.state, RunnerMotor.State.VAULTING, context + "a vault")
		var animation: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
		clips.append(animation.clip)
		assert_eq(animation.duration, _tuning.vault_duration, context + "as long as the vault")

	assert_lt(THIN, _tuning.vault_two_hands_depth, "the thin wall is under the threshold")
	assert_gt(DEEP, _tuning.vault_two_hands_depth, "the deep one over it")
	var expected: Array[RunnerAnimation.Clip] = [
		RunnerAnimation.Clip.VAULT_ONE_HAND, RunnerAnimation.Clip.VAULT_TWO_HANDS
	]
	assert_eq(clips, expected, "Vault One Hand, then Vault Two Hands")


func test_an_abrupt_entry_is_made_without_a_blend() -> void:
	var running: RunnerAnimation = RunnerAnimation.of(_running_at(_tuning.top_speed).motor, STEP)
	assert_eq(running.blend_time, _tuning.animation_blend_time, "running: a blend")

	# A hard landing: a fall higher than a roll forgives, without the slide pressed.
	var falling: MotorBody = MotorBody.new(_tuning, _tuning.roll_fall_height + 1.0)
	falling.velocity = FORWARD * _tuning.top_speed
	_fall_until(falling, _push(FORWARD), RunnerMotor.State.HARD_LANDING)
	var hard: RunnerAnimation = RunnerAnimation.of(falling.motor, STEP)
	assert_eq(hard.clip, RunnerAnimation.Clip.HARD_LANDING, "a hard landing")
	# A hard landing now blends as its table says (docs/specs/motion-weight.md, decision 8):
	# only a crash comes at once.
	assert_eq(hard.blend_time, _tuning.animation_blend_time, "with the blend of its table")

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
	var at_top: float = _tuning.top_speed / RunnerAnimation.own_speed(full.locomotion, _tuning)
	var pace: float = minf(at_top, _tuning.animation_max_pace)
	assert_almost_eq(full.speed, pace, 0.01, "in step with the ground at the top speed")


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
	# Into the jump of a run, posed by its vertical speed (docs/specs/motion-weight.md).
	assert_eq(animation.clip, RunnerAnimation.Clip.RUNNING_JUMP, "the trick over, the body unfolds")
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


func test_each_gesture_has_its_animation() -> void:
	# docs/specs/chase-tag.md, decision 7: the touch on the upper body, over the run; the
	# dive; the getting up of a dive missed; then the run again.
	var cat: MotorBody = _running_at(_tuning.top_speed)
	cat.motor.can_tag = true
	var touch: MoveIntent = _push(FORWARD)
	touch.touch_pressed = true
	cat.step(touch)
	var touching: RunnerAnimation = RunnerAnimation.of(cat.motor, STEP)
	assert_true(touching.touching, "the touch: the arm stretched on the upper body")
	assert_eq(touching.clip, RunnerAnimation.Clip.RUNNING, "over the run")
	var shown: Array[RunnerAnimation.Clip] = []
	var reached: bool = true
	for step: int in MANY_STEPS:
		var intent: MoveIntent = _push(FORWARD)
		# The dive once the touch is over.
		intent.dive_pressed = cat.motor.tag.gesture == Tag.Gesture.TOUCH and cat.motor.tag.is_over()
		cat.step(intent)
		var animation: RunnerAnimation = RunnerAnimation.of(cat.motor, STEP)
		if cat.motor.tag.gesture == Tag.Gesture.TOUCH:
			reached = reached and animation.touching == (cat.motor.tag.phase == Tag.Phase.REACHING)
		elif shown.is_empty() or shown[-1] != animation.clip:
			shown.append(animation.clip)
		if shown.size() >= 3 and cat.motor.tag.is_over():
			break
	assert_true(reached, "the arm stretched while the touch reaches, and only then")
	var dive_and_up: Array[RunnerAnimation.Clip] = [
		RunnerAnimation.Clip.DIVE, RunnerAnimation.Clip.GETTING_UP
	]
	assert_eq(shown.slice(0, 2), dive_and_up, "the dive, then the getting up")
	assert_eq(shown.size(), 3, "then")
	if shown.size() == 3:
		assert_has(RunnerAnimation.LOCOMOTION, shown[2], "the locomotion again")


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

	# On the move, the landing that runs on (docs/specs/motion-weight.md, decision 7).
	assert_eq(clips[0], RunnerAnimation.Clip.LAND_TO_RUN, "Land To Run as it touches the ground")
	assert_eq(
		clips[landing_steps - 1],
		RunnerAnimation.Clip.LAND_TO_RUN,
		"for the first steps on the ground"
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
	# Running alone where it is alone on the ground and below, Sprint from the top speed.
	var running_alone: float = _tuning.animation_run_speed * _tuning.animation_run_alone_pace
	assert_lt(_tuning.wall_run_start_speed, running_alone, "a slow wall run is slower")
	var slow: float = _tuning.wall_run_start_speed
	var between: float = (running_alone + _tuning.top_speed) / 2.0
	var fast: float = _tuning.top_speed + 1.0
	var cases: Array[Array] = [
		[slow, [0.0, 0.0, 0.0, 1.0, 0.0], "slow along the wall: Running"],
		[between, [0.0, 0.0, 0.0, 0.5, 0.5], "faster: Running and Sprint"],
		[fast, [0.0, 0.0, 0.0, 0.0, 1.0], "fast along the wall: Sprint"],
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
		# 1.25 times its own pace (docs/specs/motion-weight.md, decision 2); the game's tuning
		# may be tuned: it is held to its own limit.
		if tuning == _tuning:
			assert_almost_eq(most, 1.25, 0.0001, named + ": at most 1.25 times its own pace")
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


func test_no_clip_is_played_at_more_than_1_25_times_its_speed() -> void:
	# docs/specs/motion-weight.md, decision 2: the project's tuning, each state of a fixed
	# duration, and every speed on the ground up to tier 3 of the flow.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var most: float = 1.25
	assert_almost_eq(tuning.animation_max_pace, most, 0.0001, "the cap of the project: 1.25")
	var states: Dictionary[RunnerAnimation.Clip, float] = _fixed_durations(tuning)
	for clip: RunnerAnimation.Clip in states:
		var cut: Vector2 = RunnerCharacter.CUTS[clip]
		var pace: float = RunnerAnimation.fitted_pace(cut.y - cut.x, states[clip], tuning)
		var context: String = RunnerAnimation.Clip.keys()[clip]
		assert_lte(pace, most + 0.0001, context + ": at most 1.25 times its own pace")
	var bonuses: Array[float] = tuning.flow_tier_speed_bonus
	var fastest: float = tuning.top_speed * (1.0 + bonuses[tuning.flow_tier_count - 1])
	var speed: float = 0.0
	while speed <= fastest + SPEED_STEP:
		var running: RunnerAnimation = RunnerAnimation.of(_running_at(speed, tuning).motor, STEP)
		var context: String = "%.1f m/s on the ground" % speed
		assert_lte(running.speed, most + 0.0001, context + ": at most 1.25 times its own pace")
		speed += SPEED_STEP


func test_each_gesture_lasts_the_time_of_its_clip() -> void:
	# docs/specs/motion-weight.md, decision 3: the mantle, the vaults, the roll and the
	# landings of the project last as long as the part of their clip kept, played from 1.0 to
	# the cap of the tuning.
	var tuning: MovementTuning = load(TUNING) as MovementTuning
	var states: Dictionary[RunnerAnimation.Clip, float] = _fixed_durations(tuning)
	var gestures: Array[RunnerAnimation.Clip] = [
		RunnerAnimation.Clip.LEDGE_PULL_UP,
		RunnerAnimation.Clip.VAULT_ONE_HAND,
		RunnerAnimation.Clip.VAULT_TWO_HANDS,
		RunnerAnimation.Clip.FALLING_TO_ROLL,
		RunnerAnimation.Clip.HARD_LANDING,
		RunnerAnimation.Clip.LANDING,
		RunnerAnimation.Clip.LAND_TO_RUN,
	]
	for clip: RunnerAnimation.Clip in gestures:
		var context: String = RunnerAnimation.Clip.keys()[clip]
		assert_has(states, clip, context + ": a state of a fixed duration")
		var cut: Vector2 = RunnerCharacter.CUTS[clip]
		var pace: float = (cut.y - cut.x) / states[clip]
		gut.p(
			(
				"%s: %.2f s of clip in %.2f s, played at %.2f"
				% [context, cut.y - cut.x, states[clip], pace]
			)
		)
		assert_between(
			pace, 1.0, tuning.animation_max_pace + 0.0001, context + ": its clip fits it"
		)
		var fitted: float = RunnerAnimation.fitted_pace(cut.y - cut.x, states[clip], tuning)
		assert_almost_eq(fitted, pace, 0.0001, context + ": played whole")


func test_the_air_pose_follows_the_vertical_speed() -> void:
	# A full jump from the run: its position in the jump at every step in the air.
	var body: MotorBody = _running_at(_tuning.top_speed)
	var shown: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
	var jump: MoveIntent = _push(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	var held: MoveIntent = _push(FORWARD)
	held.jump_held = true
	body.step(jump)
	var positions: Array[float] = []
	var speeds: Array[float] = []
	var steps: int = 0
	while not body.motor.is_on_the_ground() and steps < MANY_STEPS:
		shown = RunnerAnimation.of(body.motor, STEP, shown)
		assert_eq(
			shown.clip, RunnerAnimation.Clip.RUNNING_JUMP, "step %d: the running jump" % steps
		)
		positions.append(shown.jump_position)
		speeds.append(body.motor.velocity.y)
		body.step(held)
		steps += 1
	assert_gt(positions.size(), 10, "a jump")
	# The pace of a full jump in each half: steady, gravity being steady.
	var take_off: float = sqrt(2.0 * _tuning.rise_gravity * _tuning.jump_height)
	var landing: float = sqrt(2.0 * _tuning.fall_gravity * _tuning.jump_height)
	var top: float = RunnerAnimation.TOP_OF_THE_JUMP
	var rising: float = top * _tuning.rise_gravity * STEP / take_off
	var falling: float = (1.0 - top) * _tuning.fall_gravity * STEP / landing
	assert_lt(positions[0], 2.0 * rising, "from the take-off")
	for step: int in positions.size():
		var context: String = "step %d, %.2f m/s up" % [step, speeds[step]]
		if speeds[step] > 0.0:
			assert_lte(positions[step], top, context + ": rising, up to the top")
		else:
			assert_gte(positions[step], top, context + ": falling, from the top")
		if step > 0:
			var change: float = positions[step] - positions[step - 1]
			assert_gte(change, 0.0, context + ": always on")
			assert_lte(change, maxf(rising, falling) + 0.0001, context + ": without a jump")
	assert_gt(positions[-1], 1.0 - 2.0 * falling, "to the approach of the ground")
	# A jump released at its second step: its pose catches up, no faster than the tuning.
	var catch_up: float = _tuning.animation_jump_catch_up * maxf(rising, falling) + 0.0001
	var short: Array[float] = _jump_positions(_running_at(_tuning.top_speed), 2)
	assert_gt(short.size(), 4, "a short jump")
	for step: int in range(1, short.size()):
		var moved: float = short[step] - short[step - 1]
		assert_gte(moved, 0.0, "short jump, step %d: always on" % step)
		assert_lte(moved, catch_up, "short jump, step %d: without a jump" % step)
	# Off a ledge without a jump, then a jump in the coyote time: from the take-off.
	var off: MotorBody = _running_at(_tuning.top_speed)
	var before_the_jump: RunnerAnimation = RunnerAnimation.of(off.motor, STEP)
	off.has_floor = false
	for step: int in 4:
		off.step(_push(FORWARD))
		before_the_jump = RunnerAnimation.of(off.motor, STEP, before_the_jump)
	assert_eq(off.motor.state, RunnerMotor.State.FALLING, "off the ledge, falling")
	assert_gt(off.motor.coyote_time_left(), 0.0, "in the coyote time")
	assert_has(RunnerAnimation.LOCOMOTION, before_the_jump.clip, "still the run")
	off.has_floor = true  # the floor again, to land on
	var coyote: Array[float] = _jump_positions(off, MANY_STEPS, before_the_jump)
	assert_gt(coyote.size(), 4, "a coyote jump")
	assert_lt(coyote[0], 2.0 * rising, "coyote jump: from the take-off")
	for step: int in range(1, coyote.size()):
		var moved: float = coyote[step] - coyote[step - 1]
		assert_gte(moved, 0.0, "coyote jump, step %d: always on" % step)
		assert_lte(moved, catch_up, "coyote jump, step %d: without a jump" % step)
	# Standing, the jump of a standing body.
	var still: MotorBody = MotorBody.new(_tuning)
	still.step(MoveIntent.new())
	var up: MoveIntent = MoveIntent.new()
	up.jump_pressed = true
	up.jump_held = true
	still.step(up)
	var standing: RunnerAnimation = RunnerAnimation.of(still.motor, STEP)
	assert_eq(standing.clip, RunnerAnimation.Clip.JUMP, "standing: the jump of a standing body")


func test_a_long_fall_joins_the_falling_loop() -> void:
	# Off a high ledge, without a jump: the descent of a jump, then the falling loop.
	var body: MotorBody = MotorBody.new(_tuning, HIGH)
	var shown: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
	var landing: float = sqrt(2.0 * _tuning.fall_gravity * _tuning.jump_height)
	var descent: float = landing / _tuning.fall_gravity
	var clips: Array[RunnerAnimation.Clip] = []
	var blends: Array[float] = []
	var speeds: Array[float] = []
	for step: int in roundi(3.0 * descent / STEP):
		body.step(MoveIntent.new())
		shown = RunnerAnimation.of(body.motor, STEP, shown)
		clips.append(shown.clip)
		speeds.append(body.motor.velocity.y)
		blends.append(shown.blend_time)
	var steps_of_a_descent: int = floori(descent / STEP)
	assert_eq(clips[0], RunnerAnimation.Clip.JUMP, "the descent of a jump at first")
	assert_eq(clips[steps_of_a_descent - 1], RunnerAnimation.Clip.JUMP, "as long as a jump falls")
	assert_eq(clips[-1], RunnerAnimation.Clip.FALLING_IDLE, "then the falling loop")
	var joined: int = clips.find(RunnerAnimation.Clip.FALLING_IDLE)
	assert_gte(joined, steps_of_a_descent, "once it falls longer than a jump")
	# Not before it falls faster than a full jump lands by one step of gravity.
	var long_fall: float = landing + _tuning.fall_gravity * STEP
	assert_true(-speeds[joined] > long_fall, "the loop once a step faster than a jump lands")
	assert_true(-speeds[joined - 1] <= long_fall, "and not a step before")
	for step: int in range(joined, clips.size()):
		assert_eq(clips[step], RunnerAnimation.Clip.FALLING_IDLE, "step %d: for good" % step)
	assert_gt(blends[joined], 0.0, "into which it blends")
	assert_true(RunnerAnimation.is_a_long_fall(body.motor.velocity.y, STEP, _tuning), "a long fall")


func test_a_landing_on_the_move_runs_on() -> void:
	var moving: MotorBody = MotorBody.new(_tuning, SMALL_FALL)
	moving.velocity = FORWARD * _tuning.top_speed
	_fall_to_the_ground(moving, _push(FORWARD))
	assert_eq(moving.motor.state, RunnerMotor.State.GROUNDED, "a simple landing")
	var running_on: RunnerAnimation = RunnerAnimation.of(moving.motor, STEP)
	assert_eq(running_on.clip, RunnerAnimation.Clip.LAND_TO_RUN, "on the move: Land To Run")
	assert_eq(running_on.duration, _tuning.animation_landing_time, "for the time of a landing")
	var still: RunnerAnimation = _landed_still()
	assert_eq(still.clip, RunnerAnimation.Clip.LANDING, "standing still: Landing")
	# Landed on the move, the stick released: the gesture chosen at the contact stays.
	var braking: MotorBody = MotorBody.new(_tuning, SMALL_FALL)
	braking.velocity = FORWARD * 3.0
	_fall_to_the_ground(braking, _push(FORWARD))
	var shown: RunnerAnimation = RunnerAnimation.of(braking.motor, STEP)
	assert_eq(shown.clip, RunnerAnimation.Clip.LAND_TO_RUN, "braking: Land To Run at the contact")
	var landing_steps: int = roundi(_tuning.animation_landing_time / STEP)
	for step: int in range(1, landing_steps):
		braking.step(MoveIntent.new())
		shown = RunnerAnimation.of(braking.motor, STEP, shown)
		assert_eq(
			shown.clip, RunnerAnimation.Clip.LAND_TO_RUN, "braking, step %d: one gesture" % step
		)


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
		if clip == RunnerAnimation.Clip.VAULT_TWO_HANDS:
			body.motor.vault = _deep_vault(tuning)
		var animation: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
		assert_eq(animation.clip, clip, "the clip of %s" % RunnerAnimation.Clip.keys()[clip])
		durations[clip] = animation.duration
	var landing: RunnerAnimation = _landed_still(tuning)
	assert_eq(landing.clip, RunnerAnimation.Clip.LANDING, "a landing")
	durations[RunnerAnimation.Clip.LANDING] = landing.duration
	var moving: MotorBody = MotorBody.new(tuning, SMALL_FALL)
	moving.velocity = FORWARD * tuning.top_speed
	_fall_to_the_ground(moving, _push(FORWARD))
	var running_on: RunnerAnimation = RunnerAnimation.of(moving.motor, STEP)
	assert_eq(running_on.clip, RunnerAnimation.Clip.LAND_TO_RUN, "a landing on the move")
	durations[RunnerAnimation.Clip.LAND_TO_RUN] = running_on.duration
	return durations


## A vault over an obstacle deeper than one hand vaults, with `tuning`.
func _deep_vault(tuning: MovementTuning) -> Vault:
	var facts: RunnerFacts = RunnerFacts.new()
	facts.velocity = FORWARD * RUN_SPEED
	facts.obstacle_normal = Vector3.BACK
	facts.obstacle_distance = tuning.vault_reach
	facts.obstacle_height = WALL_HEIGHT
	facts.obstacle_depth = tuning.vault_two_hands_depth * 1.5
	return Vault.new(facts, tuning, roundi(tuning.vault_duration / STEP))


## The animation of a body that has just landed from a small fall, without moving; with
## `tuning`, the fixed one by default.
func _landed_still(tuning: MovementTuning = null) -> RunnerAnimation:
	var body: MotorBody = MotorBody.new(_tuning if tuning == null else tuning, SMALL_FALL)
	_fall_to_the_ground(body, MoveIntent.new())
	return RunnerAnimation.of(body.motor, MotorBody.STEP)


## The positions in the jump of `body`, which jumps now running forward, its jump held
## for `held` steps, shown after `before` (null: none), at each step until it lands.
func _jump_positions(body: MotorBody, held: int, before: RunnerAnimation = null) -> Array[float]:
	var shown: RunnerAnimation = before
	var positions: Array[float] = []
	var intent: MoveIntent = _push(FORWARD)
	intent.jump_pressed = true
	intent.jump_held = true
	body.step(intent)
	var steps: int = 0
	while not body.motor.is_on_the_ground() and steps < MANY_STEPS:
		shown = RunnerAnimation.of(body.motor, STEP, shown)
		assert_has(RunnerAnimation.JUMPS, shown.clip, "step %d: a jump" % steps)
		positions.append(shown.jump_position)
		intent = _push(FORWARD)
		intent.jump_held = steps + 1 < held
		body.step(intent)
		steps += 1
	return positions


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
