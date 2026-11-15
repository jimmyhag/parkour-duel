extends ReplayTest
## The locomotion of the runner's body (docs/specs/locomotion-blend.md): on its feet, a
## blend of Idle, Walking, Running and Sprint on its horizontal speed, the clips at the
## same phase of their stride, a blend time for each pair of animations, the run resumed at
## the stride nearest the pose it comes from, and a stop and a start through the walk
## (docs/specs/animation-polish.md, decision 9). The weights, the table and the phases are
## logic, tested without the Mixamo files; with them (on the owner's machine), the same
## rules are checked on the character's animation tree, faster than real time (see
## ReplayTest). The tuning of the logic is the fixed one of MotorBody; the runners go along
## -Z.

const FORWARD: Vector3 = Vector3.FORWARD
const STEP: float = MotorBody.STEP
## The tuning of the game, for the character with the files.
const TUNING: String = "res://game/core/movement_tuning.tres"
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600
## The weights of the locomotion, in the order of RunnerAnimation.LOCOMOTION.
const IDLE: int = 0
const WALKING: int = 1
const JOGGING: int = 2
const RUNNING: int = 3
const SPRINT: int = 4
## Speeds well spread over the whole range of the locomotion, in m/s.
const SPEEDS: Array[float] = [0.0, 0.3, 0.5, 0.9, 1.4, 2.0, 4.4, 7.0, 9.0, 9.4, 10.0, 10.35, 14.0]
## A made-up stride of three clips: the height of the left foot (its ankle and its toe)
## above the ground at evenly spaced instants of one cycle, and the length of that cycle, in
## s. The first touches the ground at its third sample; the second, longer, at its sixth;
## the third brushes the ground for one sample (its second) before it lands for good at its
## sixth: its touchdown is the start of its longest time on the ground.
const MADE_UP_ANKLES: Array[PackedFloat32Array] = [
	[0.30, 0.20, 0.12, 0.10, 0.10, 0.11, 0.25, 0.40],
	[0.25, 0.30, 0.31, 0.29, 0.20, 0.11, 0.10, 0.10, 0.10, 0.18],
	[0.30, 0.10, 0.25, 0.30, 0.20, 0.10, 0.10, 0.10, 0.10, 0.20],
]
const MADE_UP_TOES: Array[PackedFloat32Array] = [
	[0.20, 0.10, 0.005, 0.00, 0.00, 0.00, 0.10, 0.30],
	[0.15, 0.20, 0.20, 0.18, 0.10, 0.005, 0.00, 0.00, 0.00, 0.08],
	[0.20, 0.005, 0.15, 0.20, 0.10, 0.00, 0.00, 0.00, 0.00, 0.10],
]
const MADE_UP_TOUCHDOWNS: Array[float] = [2.0 / 8.0, 5.0 / 10.0, 5.0 / 10.0]
const MADE_UP_LENGTHS: Array[float] = [1.2, 0.7]
## A made-up cycle of the locomotion, from the left foot's touchdown: at each of its eight
## phases, how far the left foot is ahead of the right one, and how much higher, in m.
const MADE_UP_CYCLE: PackedVector2Array = [
	Vector2(0.6, -0.2),
	Vector2(0.3, -0.3),
	Vector2(-0.1, -0.2),
	Vector2(-0.5, 0.0),
	Vector2(-0.6, 0.2),
	Vector2(-0.3, 0.3),
	Vector2(0.1, 0.2),
	Vector2(0.5, 0.0),
]
## Poses a runner comes from: out of a slide, its left leg stretched far ahead, both feet on
## the ground; out of a landing, its right foot a little ahead and a little higher.
const OUT_OF_A_SLIDE: Vector2 = Vector2(0.8, 0.0)
const OUT_OF_A_LANDING: Vector2 = Vector2(-0.25, 0.25)
## The phases of the made-up cycle nearest those poses.
const AFTER_THE_SLIDE: float = 7.0 / 8.0
const AFTER_THE_LANDING: float = 5.0 / 8.0
## Long enough for a runner to stop dead and stand, or to set off and reach its top
## speed, in fixed steps.
const STOP_STEPS: int = 40
## Long enough for a runner to reach the speed of tier 2 of the flow, in fixed steps.
const FLOW_STEPS: int = 150
## How many times a cycle of the stride is sampled; how close to its lowest the toe of a
## foot on the ground is, in m.
const CYCLE_SAMPLES: int = 60
const ON_THE_GROUND: float = 0.02
## Long enough for a clip to blend in, in fixed steps.
const SETTLE_STEPS: int = 20
## How far apart two phases may be read, the tree having played a frame since: a share of
## the cycle.
const PHASE_TOLERANCE: float = 0.06
## How close to the speed of the ground the foot on it goes back, as a share of it.
const GROUND_TOLERANCE: float = 0.1
## The precision of a pace computed by the logic.
const TOLERANCE: float = 0.0001
## How many times a second the tree is advanced to follow a foot; the feet followed, and
## the bones of each one (its ankle, its toe) in RunnerCharacter's names of the left one.
const FOOT_SAMPLES_PER_SECOND: float = 240.0
const FEET: Array[String] = ["left", "right"]
const FOOT_BONES: Array[String] = [RunnerCharacter.LEFT_FOOT, RunnerCharacter.LEFT_TOE]

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_blend_space_weights_follow_the_speed() -> void:
	# Running alone at 1.2 times its own speed (under the cap of 1.25 of
	# docs/specs/motion-weight.md), Sprint alone from the top speed
	# (docs/specs/locomotion-blend.md, decision 1 as amended); Jogging between the walk and the
	# run (docs/specs/motion-weight.md, decision 4).
	var run_point: float = _tuning.animation_run_speed * _tuning.animation_run_alone_pace
	assert_almost_eq(_tuning.animation_run_alone_pace, 1.2, 0.0001, "Running alone at 1.2 times")
	var still: PackedFloat32Array = _weights_of(_running_at(0.0))
	var between: float = (_tuning.animation_jog_speed + run_point) / 2.0
	var walking_and_running: PackedFloat32Array = _weights_of(_running_at(between))
	var running: PackedFloat32Array = _weights_of(_running_at(run_point))
	var faster: float = (run_point + _tuning.top_speed) / 2.0
	var running_and_sprinting: PackedFloat32Array = _weights_of(_running_at(faster))
	var at_top_speed: PackedFloat32Array = _weights_of(_running_at(_tuning.top_speed))
	var flowing: MotorBody = _running_at(_tuning.top_speed)
	# Tier 2 of the flow: faster than the top speed.
	flowing.motor.top_speed_bonus = _tuning.flow_tier_speed_bonus[1]
	for step: int in FLOW_STEPS:
		flowing.step(_push(FORWARD))
	var with_the_flow: PackedFloat32Array = _weights_of(flowing)

	_assert_weights(still, [1.0, 0.0, 0.0, 0.0, 0.0], "still: Idle alone")
	assert_almost_eq(walking_and_running[JOGGING], 0.5, 0.02, "between: half Jogging")
	assert_almost_eq(walking_and_running[RUNNING], 0.5, 0.02, "and half Running")
	_assert_weights(running, [0.0, 0.0, 0.0, 1.0, 0.0], "at 1.2 times its speed: Running alone")
	assert_almost_eq(running_and_sprinting[RUNNING], 0.5, 0.02, "faster: half Running")
	assert_almost_eq(running_and_sprinting[SPRINT], 0.5, 0.02, "and half Sprint")
	_assert_weights(at_top_speed, [0.0, 0.0, 0.0, 0.0, 1.0], "at the top speed: Sprint alone")
	assert_gt(flowing.motor.real_speed(), _tuning.top_speed, "with the flow, faster")
	_assert_weights(with_the_flow, [0.0, 0.0, 0.0, 0.0, 1.0], "beyond, with the flow: Sprint alone")

	var walking: PackedFloat32Array = RunnerAnimation.locomotion_weights(
		_tuning.animation_walk_speed, _tuning
	)
	_assert_weights(walking, [0.0, 1.0, 0.0, 0.0, 0.0], "at its own speed: Walking alone")
	var walk_and_jog: float = (_tuning.animation_walk_speed + _tuning.animation_jog_speed) / 2.0
	var walking_and_jogging: PackedFloat32Array = _weights_of(_running_at(walk_and_jog))
	assert_almost_eq(walking_and_jogging[WALKING], 0.5, 0.02, "slower: half Walking")
	assert_almost_eq(walking_and_jogging[JOGGING], 0.5, 0.02, "and half Jogging")
	var animation: RunnerAnimation = RunnerAnimation.of(_running_at(between).motor, STEP)
	assert_eq(animation.clip, RunnerAnimation.Clip.RUNNING, "moving on its feet: the locomotion")
	assert_eq(animation.locomotion, walking_and_running, "with its weights")
	# The game's tuning, whatever its values: Running alone where it says, between the walk
	# and the top speed.
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	var game_point: float = game_tuning.animation_run_speed * game_tuning.animation_run_alone_pace
	assert_between(
		game_point, game_tuning.animation_walk_speed, game_tuning.top_speed, "the game's run alone"
	)
	_assert_weights(
		RunnerAnimation.locomotion_weights(game_point, game_tuning),
		[0.0, 0.0, 0.0, 1.0, 0.0],
		"the game's tuning: Running alone there"
	)
	_assert_weights(
		RunnerAnimation.locomotion_weights(game_tuning.top_speed, game_tuning),
		[0.0, 0.0, 0.0, 0.0, 1.0],
		"the game's tuning: Sprint alone at the top speed"
	)


func test_the_stop_goes_through_the_walk() -> void:
	# A runner at the top speed stops dead, stands, then sets off again at full push: step
	# after step, how much the clips that stride show over Idle, and the weights.
	var tuning: MovementTuning = _tuning
	var body: MotorBody = _running_at(tuning.top_speed)
	var shown: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
	var pushes: Array[Vector3] = []
	for step: int in STOP_STEPS:
		pushes.append(Vector3.ZERO)
	for step: int in STOP_STEPS:
		pushes.append(FORWARD)
	var moving: Array[float] = [1.0 - shown.locomotion[IDLE]]
	var set_off: bool = false
	for step: int in pushes.size():
		body.step(_push(pushes[step]))
		var before: RunnerAnimation = shown
		shown = RunnerAnimation.of(body.motor, STEP, before)
		var context: String = "step %d" % step
		assert_eq(
			shown.locomotion.size(), RunnerAnimation.LOCOMOTION.size(), context + ": on its feet"
		)
		# In smoothly: no part of the blend space crossed faster than in the tuned time.
		var share: float = 1.0 - shown.locomotion[IDLE]
		var most: float = STEP / tuning.animation_start_stop_time + 0.0001
		var was: float = moving[moving.size() - 1]
		assert_lte(absf(share - was), most, context + ": Idle comes and goes smoothly")
		for clip: int in [WALKING, JOGGING, RUNNING, SPRINT]:
			var change: float = absf(shown.locomotion[clip] - before.locomotion[clip])
			# No faster than from Walking to Sprint in the tuned time (locomotion_moved): the
			# clips that stride, one after the other, less one.
			var along: float = RunnerAnimation.LOCOMOTION.size() - 2
			assert_lte(change, along * most, context + ": no clip jumps in or out")
		moving.append(share)
		# Without skipping the walk: as Idle comes, Walking is the clip it blends with; as it
		# goes, Walking shows, and alone with it at first.
		if share > 0.0 and share < 1.0:
			var walking: float = shown.locomotion[WALKING]
			var others: float = maxf(
				shown.locomotion[JOGGING], maxf(shown.locomotion[RUNNING], shown.locomotion[SPRINT])
			)
			if step < STOP_STEPS:
				assert_gt(walking, others, context + ": stopping, through the walk")
			else:
				assert_gt(walking, 0.0, context + ": setting off, through the walk")
				if not set_off:
					assert_eq(others, 0.0, context + ": setting off, the walk first")
				set_off = true
	# Over the tuned duration, down then up.
	var stopping: int = _steps_between(moving, 1.0, 0.0)
	var starting: int = _steps_between(moving.slice(STOP_STEPS), 0.0, 1.0)
	var tuned: int = roundi(tuning.animation_start_stop_time / STEP)
	gut.p("Idle comes in %d steps, goes in %d; tuned: %d" % [stopping, starting, tuned])
	assert_almost_eq(stopping, tuned, 1, "the stop blends into Idle over the tuned time")
	assert_almost_eq(starting, tuned, 1, "the start blends out of it over the tuned time")
	assert_true(set_off, "it set off")
	assert_eq(shown.clip, RunnerAnimation.Clip.RUNNING, "it runs again")
	assert_almost_eq(moving[moving.size() - 1], 1.0, 0.0001, "Idle gone")


func test_the_weights_always_make_a_whole() -> void:
	for speed: float in SPEEDS:
		var weights: PackedFloat32Array = RunnerAnimation.locomotion_weights(speed, _tuning)
		var context: String = "at %.2f m/s" % speed
		assert_eq(weights.size(), RunnerAnimation.LOCOMOTION.size(), context + ": a weight a clip")
		var total: float = 0.0
		var non_zero: int = 0
		for weight: float in weights:
			assert_between(weight, 0.0, 1.0, context + ": between 0 and 1")
			total += weight
			non_zero += int(weight > 0.0)
		assert_lte(non_zero, 2, context + ": two clips at most")
		assert_almost_eq(total, 1.0, 0.0001, context + ": they sum to 1")


func test_the_locomotion_goes_through_jogging() -> void:
	# docs/specs/motion-weight.md, decision 4: from the walk to the run, Jogging has its
	# share, alone at its own speed; the weights always make a whole.
	var run_point: float = _tuning.animation_run_speed * _tuning.animation_run_alone_pace
	var walk: float = _tuning.animation_walk_speed
	var jog: float = _tuning.animation_jog_speed
	assert_between(jog, walk, run_point, "Jogging between the walk and the run")
	var most: float = 0.0
	var speed: float = walk
	while speed <= run_point:
		var weights: PackedFloat32Array = _weights_of(_running_at(speed))
		var context: String = "at %.2f m/s" % speed
		var total: float = 0.0
		for weight: float in weights:
			assert_between(weight, 0.0, 1.0, context + ": between 0 and 1")
			total += weight
		assert_almost_eq(total, 1.0, 0.0001, context + ": a whole")
		most = maxf(most, weights[JOGGING])
		if speed > walk and speed < run_point - 0.01:
			assert_gt(weights[JOGGING], 0.0, context + ": Jogging has its share")
		speed += 0.05
	assert_almost_eq(most, 1.0, 0.01, "Jogging alone somewhere")
	_assert_weights(
		RunnerAnimation.locomotion_weights(jog, _tuning),
		[0.0, 0.0, 1.0, 0.0, 0.0],
		"at its own speed: Jogging alone"
	)
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	_assert_weights(
		RunnerAnimation.locomotion_weights(game_tuning.animation_jog_speed, game_tuning),
		[0.0, 0.0, 1.0, 0.0, 0.0],
		"the game's tuning: Jogging alone at its own speed"
	)


func test_the_blended_clips_keep_the_same_phase() -> void:
	# The rule, on the measures of two made-up clips: where the left foot touches the
	# ground in each, read from its heights; the blended stride then goes as fast as the
	# ground, whatever the weights.
	for index: int in MADE_UP_ANKLES.size():
		var feet: Array[PackedFloat32Array] = [MADE_UP_ANKLES[index], MADE_UP_TOES[index]]
		var touchdown: float = Stride.touchdown(feet)
		assert_almost_eq(
			touchdown, MADE_UP_TOUCHDOWNS[index], 0.001, "clip %d: its touchdown" % index
		)
	_assert_the_walk_keeps_up_with_the_ground()
	var speeds: PackedFloat32Array = [0.0, 1.5, 4.5, 0.0]
	var lengths: PackedFloat32Array = [5.0, MADE_UP_LENGTHS[0], MADE_UP_LENGTHS[1], 1.0]
	for share: float in [0.0, 0.25, 0.5, 1.0]:
		var weights: PackedFloat32Array = [0.0, 1.0 - share, share, 0.0]
		var own: float = (1.0 - share) * speeds[1] + share * speeds[2]
		var ground: float = 3.0
		var cycles: float = Stride.cycles_per_second(ground / own, weights, speeds, lengths)
		# Each clip plays its own cycle in the same time: at the same phase; the foot on the
		# ground of each goes back at its own speed times its rate.
		var foot: float = 0.0
		for clip: int in [1, 2]:
			foot += weights[clip] * speeds[clip] * cycles * lengths[clip]
		assert_almost_eq(foot, ground, 0.001, "%d%% Running: the feet keep up" % (share * 100))

	# The character's tree, with the files: the blended clips are read at the same phase,
	# each started at its own touchdown.
	var character: RunnerCharacter = _character()
	if character == null:
		pass_test("without the Mixamo files, the rule alone")
		return
	var tree: AnimationTree = _tree_of(character)
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	var game_run: float = game_tuning.animation_run_speed * game_tuning.animation_run_alone_pace
	var between: float = (game_tuning.animation_jog_speed + game_run) / 2.0
	var animation: RunnerAnimation = _locomotion_at(between, game_tuning)
	assert_gt(animation.locomotion[JOGGING], 0.0, "jogging")
	assert_gt(animation.locomotion[RUNNING], 0.0, "and running")
	for step: int in SETTLE_STEPS:
		await get_tree().physics_frame
		character.play(animation)
	await get_tree().process_frame
	var phases: PackedFloat32Array = []
	for clip: RunnerAnimation.Clip in RunnerCharacter.STRIDES:
		var phase: float = tree.get(RunnerCharacter.stride_position(clip))
		phases.append(phase)
	gut.p("phases of Walking, Jogging, Running, Sprint: %s" % [phases])
	assert_almost_eq(phases[0], phases[1], 0.001, "Walking and Jogging at the same phase")
	assert_almost_eq(phases[1], phases[2], 0.001, "Jogging and Running at the same phase")
	assert_almost_eq(phases[2], phases[3], 0.001, "Running and Sprint at the same phase")
	assert_gt(phases[0], 0.0, "the stride moves on")

	# At the phase 0 of each clip alone, as the tree plays it, its left foot touches the
	# ground (its heel or its toe at its lowest): the phase means the same moment of the
	# stride in every clip.
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var skeleton: Skeleton3D = _skeleton_of(character)
	var foot: Array[int] = [
		skeleton.find_bone(RunnerCharacter.LEFT_FOOT), skeleton.find_bone(RunnerCharacter.LEFT_TOE)
	]
	var points: Array[float] = [
		game_tuning.animation_walk_speed,
		game_tuning.animation_jog_speed,
		game_run,
		game_tuning.top_speed,
	]
	for point: int in points.size():
		character.play(_locomotion_at(points[point], game_tuning))
		var lowest: Array[float] = [INF, INF]
		var strides: float = tree.get(RunnerCharacter.STRIDE_SCALE)
		for sample: int in CYCLE_SAMPLES:
			tree.advance(1.0 / CYCLE_SAMPLES / strides)
			for bone: int in foot.size():
				var height: float = skeleton.get_bone_global_pose(foot[bone]).origin.y
				lowest[bone] = minf(lowest[bone], height)
		tree.set(RunnerCharacter.RESUME_REQUEST, 0.0)
		tree.advance(0.0)
		var above: float = INF
		for bone: int in foot.size():
			var height: float = skeleton.get_bone_global_pose(foot[bone]).origin.y
			above = minf(above, height - lowest[bone])
		var clip: String = RunnerAnimation.Clip.keys()[RunnerCharacter.STRIDES[point]]
		gut.p("%s at phase 0: its left foot %.3f m above its lowest" % [clip, above])
		assert_lt(above, ON_THE_GROUND, "%s at phase 0: the left foot on the ground" % clip)

	# Each clip that strides, alone at its own speed: each of its feet on the ground goes
	# back as fast as the ground passes under the runner, the left one as the right one
	# (docs/specs/animation-polish.md, decision 9).
	var speeds_of_the_strides: PackedFloat32Array = RunnerAnimation.stride_speeds(game_tuning)
	for point: int in RunnerCharacter.STRIDES.size():
		var clip: RunnerAnimation.Clip = RunnerCharacter.STRIDES[point]
		var ground: float = speeds_of_the_strides[point + 1]
		var back: PackedFloat32Array = _planted_feet_speeds(character, clip, ground)
		for side: int in back.size():
			var named: String = "%s, its %s foot" % [RunnerAnimation.Clip.keys()[clip], FEET[side]]
			gut.p("%s at %.2f m/s: planted, it goes back at %.2f m/s" % [named, ground, back[side]])
			assert_almost_eq(back[side], ground, ground * GROUND_TOLERANCE, named + ": it keeps up")


func test_the_feet_follow_the_ground_up_to_tier_3() -> void:
	# docs/specs/realistic-tempo.md, decision 7: the project's tuning, on the ground from the
	# walk to the top speed of tier 3 of the flow. The rule: the locomotion chosen for the
	# runner plays under its cap, and its stride goes back at the speed of the ground, within
	# 10 %.
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	var bonuses: Array[float] = game_tuning.flow_tier_speed_bonus
	var tier_3: float = bonuses[game_tuning.flow_tier_count - 1]
	var fastest: float = game_tuning.top_speed * (1.0 + tier_3)
	var speeds: Array[float] = []
	var sampled: float = game_tuning.animation_walk_speed
	while sampled < fastest:
		speeds.append(sampled)
		sampled += 0.05
	speeds.append(fastest)
	for speed: float in speeds:
		var animation: RunnerAnimation = _locomotion_of_a_runner_at(speed, tier_3, game_tuning)
		var context: String = "%.2f m/s" % speed
		var stride: float = RunnerAnimation.own_speed(animation.locomotion, game_tuning)
		stride *= animation.speed
		assert_lte(
			animation.speed, game_tuning.animation_max_pace + TOLERANCE, context + ": capped"
		)
		assert_almost_eq(stride, speed, speed * GROUND_TOLERANCE, context + ": the stride keeps up")

	# With the files: the planted foot of the character, at the speed of each clip that
	# strides, at the top speed and at the top speed of each tier.
	var character: RunnerCharacter = _character()
	if character == null:
		pass_test("without the Mixamo files, the rule alone")
		return
	var points: Array[float] = [
		game_tuning.animation_walk_speed,
		game_tuning.animation_jog_speed,
		game_tuning.animation_run_speed * game_tuning.animation_run_alone_pace,
		game_tuning.top_speed,
	]
	for bonus: float in bonuses:
		points.append(game_tuning.top_speed * (1.0 + bonus))
	for ground: float in points:
		var animation: RunnerAnimation = _locomotion_of_a_runner_at(ground, tier_3, game_tuning)
		var named: String = "at %.2f m/s" % ground
		var back: PackedFloat32Array = _planted_feet_speeds_playing(character, animation, named)
		for side: int in back.size():
			var foot: String = "%s, its %s foot" % [named, FEET[side]]
			gut.p(
				(
					"%s: planted, it goes back at %.2f m/s (%+.1f %%), the clips at %.2f times"
					% [foot, back[side], (back[side] / ground - 1.0) * 100.0, animation.speed]
				)
			)
			assert_almost_eq(back[side], ground, ground * GROUND_TOLERANCE, foot + ": it keeps up")


func test_each_transition_has_its_blend_time() -> void:
	var pairs: Array[Array] = [
		[RunnerAnimation.Clip.RUNNING, RunnerAnimation.Clip.JUMP, 0.05, "run → jump"],
		[RunnerAnimation.Clip.RUNNING_SLIDE, RunnerAnimation.Clip.RUNNING, 0.2, "slide → run"],
		[
			RunnerAnimation.Clip.LEDGE_PULL_UP,
			RunnerAnimation.Clip.FALLING_IDLE,
			_tuning.animation_blend_time,
			"a pair absent from the table: the default",
		],
		[RunnerAnimation.Clip.IDLE, RunnerAnimation.Clip.JUMP, 0.05, "standing is part of the run"],
		[RunnerAnimation.Clip.FALLING_IDLE, RunnerAnimation.Clip.TUCK, 0.08, "into the tuck pose"],
		[
			RunnerAnimation.Clip.TUCK,
			RunnerAnimation.Clip.FALLING_IDLE,
			0.12,
			"out of the tuck pose"
		],
	]
	for pair: Array in pairs:
		var from: RunnerAnimation.Clip = pair[0]
		var to: RunnerAnimation.Clip = pair[1]
		var expected: float = pair[2]
		var context: String = pair[3]
		assert_eq(RunnerAnimation.blend_time_between(from, to, _tuning), expected, context)

	# What the runner shows: the blend time of the pair it goes through.
	var body: MotorBody = _running_at(_tuning.top_speed)
	var running: RunnerAnimation = RunnerAnimation.of(body.motor, STEP)
	var jump: MoveIntent = _push(FORWARD)
	jump.jump_pressed = true
	jump.jump_held = true
	body.step(jump)
	var jumping: RunnerAnimation = RunnerAnimation.of(body.motor, STEP, running)
	assert_eq(jumping.clip, RunnerAnimation.Clip.RUNNING_JUMP, "it jumps from the run")
	assert_eq(jumping.blend_time, 0.05, "with the blend time of run → jump")


func test_an_abrupt_entry_stays_without_a_blend() -> void:
	# Even a table that would give them one. A hard landing now takes it
	# (docs/specs/motion-weight.md, decision 8): only a crash stays without a blend.
	_tuning.animation_blend_times["falling_idle>hard_landing"] = 0.3
	_tuning.animation_blend_times["*>hard_landing"] = 0.3
	_tuning.animation_blend_times["tuck>*"] = 0.3

	var falling: MotorBody = MotorBody.new(_tuning, _tuning.roll_fall_height + 1.0)
	falling.velocity = FORWARD * _tuning.top_speed
	var before: RunnerAnimation = RunnerAnimation.of(falling.motor, STEP)
	var steps: int = 0
	while falling.motor.state != RunnerMotor.State.HARD_LANDING and steps < MANY_STEPS:
		before = RunnerAnimation.of(falling.motor, STEP, before)
		falling.step(_push(FORWARD))
		steps += 1
	var hard: RunnerAnimation = RunnerAnimation.of(falling.motor, STEP, before)
	assert_eq(hard.clip, RunnerAnimation.Clip.HARD_LANDING, "a hard landing")
	assert_eq(hard.blend_time, 0.3, "with the blend of the table")

	var tricking: MotorBody = _running_at(_tuning.top_speed)
	var release: MoveIntent = _push(FORWARD)
	release.trick_released = true
	release.trick_recipe = TrickRecipe.of_the_context()
	tricking.step(release)
	assert_not_null(tricking.motor.current_trick(), "a trick from the run")
	var shown: RunnerAnimation = RunnerAnimation.of(tricking.motor, STEP)
	var crashed: bool = false
	steps = 0
	while not crashed and steps < MANY_STEPS:
		tricking.step(_push(FORWARD))
		for event: RunnerEvent in tricking.motor.events:
			crashed = crashed or event.kind == RunnerEvent.Kind.CRASH
		if not crashed:
			shown = RunnerAnimation.of(tricking.motor, STEP, shown)
		steps += 1
	assert_true(crashed, "a crash")
	assert_ne(shown.clip, RunnerAnimation.Clip.HARD_LANDING, "out of another clip")
	var crash: RunnerAnimation = RunnerAnimation.of(tricking.motor, STEP, shown)
	assert_eq(crash.clip, RunnerAnimation.Clip.HARD_LANDING, "a crash lands hard")
	assert_eq(crash.blend_time, 0.0, "without a blend")


func test_the_run_resumes_at_the_right_stride() -> void:
	# The rule, on a made-up cycle: the phase whose pose is nearest the one it comes from,
	# not the start of the cycle.
	var after_the_slide: float = Stride.nearest_phase(OUT_OF_A_SLIDE, MADE_UP_CYCLE)
	var after_the_landing: float = Stride.nearest_phase(OUT_OF_A_LANDING, MADE_UP_CYCLE)
	assert_almost_eq(after_the_slide, AFTER_THE_SLIDE, 0.001, "out of a slide")
	assert_almost_eq(after_the_landing, AFTER_THE_LANDING, 0.001, "out of a landing")
	for phase: int in MADE_UP_CYCLE.size():
		var exact: float = Stride.nearest_phase(MADE_UP_CYCLE[phase], MADE_UP_CYCLE)
		assert_almost_eq(exact, float(phase) / MADE_UP_CYCLE.size(), 0.001, "a pose of the cycle")

	# The character, with the files: out of a slide, then out of a landing, the run resumes
	# at the phase whose pose is nearest the one shown as it comes back to the run.
	var character: RunnerCharacter = _character()
	if character == null:
		pass_test("without the Mixamo files, the rule alone")
		return
	var tree: AnimationTree = _tree_of(character)
	var skeleton: Skeleton3D = _skeleton_of(character)
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	# Where Running plays alone: the cycle the nearest phase is looked for in.
	var alone: float = game_tuning.animation_run_speed * game_tuning.animation_run_alone_pace
	var running: RunnerAnimation = _locomotion_at(alone, game_tuning)
	var ways_in: Array[RunnerAnimation.Clip] = [
		RunnerAnimation.Clip.RUNNING_SLIDE, RunnerAnimation.Clip.LANDING
	]
	for way_in: RunnerAnimation.Clip in ways_in:
		var before: RunnerAnimation = RunnerAnimation.new()
		before.clip = way_in
		before.blend_time = game_tuning.animation_blend_time
		for step: int in SETTLE_STEPS:
			await get_tree().physics_frame
			character.play(before)
		await get_tree().physics_frame
		var pose: Vector2 = _stride_pose(skeleton)
		var expected: float = Stride.nearest_phase(pose, _running_cycle(tree, skeleton))
		running.blend_time = RunnerAnimation.blend_time_between(way_in, running.clip, game_tuning)
		character.play(running)
		# The tree plays in the frame that follows, after the signal.
		await get_tree().process_frame
		await get_tree().process_frame
		var resumed: float = tree.get(RunnerCharacter.stride_position(RunnerAnimation.Clip.RUNNING))
		var context: String = "out of %s" % RunnerAnimation.Clip.keys()[way_in]
		gut.p("%s: pose %s, resumed at %.3f, nearest %.3f" % [context, pose, resumed, expected])
		var apart: float = absf(wrapf(resumed - expected, -0.5, 0.5))
		assert_lt(apart, PHASE_TOLERANCE, context + ": the nearest phase")


## Between standing and walking, Idle blended with Walking: the stride is as much shorter
## as Idle weighs, and the walk plays as much faster, so that its foot on the ground keeps
## up with the ground, as long as the walk plays no faster than the tuning allows.
func _assert_the_walk_keeps_up_with_the_ground() -> void:
	var lengths: PackedFloat32Array = [0.0, 1.0, 0.9, 0.7, 0.5]
	var speeds: PackedFloat32Array = RunnerAnimation.stride_speeds(_tuning)
	var kept_up: int = 0
	var speed: float = _tuning.animation_still_speed + 0.05
	while speed < _tuning.animation_walk_speed:
		var animation: RunnerAnimation = RunnerAnimation.of(_running_at(speed).motor, STEP)
		var weights: PackedFloat32Array = animation.locomotion
		var context: String = "%.2f m/s" % speed
		assert_gt(weights[IDLE], 0.0, context + ": Idle weighs")
		assert_gt(weights[WALKING], 0.0, context + ": and Walking")
		var cycles: float = Stride.cycles_per_second(animation.speed, weights, speeds, lengths)
		var foot: float = 0.0
		for clip: int in weights.size():
			foot += weights[clip] * speeds[clip] * cycles * lengths[clip]
		if animation.speed < _tuning.animation_max_pace:
			assert_almost_eq(foot, speed, 0.001, context + ": the foot keeps up")
			kept_up += 1
		else:
			assert_lt(foot, speed, context + ": the walk at its fastest, the foot slips")
		speed += 0.05
	assert_gt(kept_up, 0, "the foot keeps up over the walk")


## How fast each foot of `character` (FEET) goes back while it is on the ground, in m/s,
## the clip `clip` of the locomotion alone at the ground speed `ground`: followed over one
## cycle, at each instant the lowest of its bones (its ankle, its toe: a heel strikes the
## ground, a toe pushes off it), when that bone is within ON_THE_GROUND of its lowest; the
## median of those speeds.
func _planted_feet_speeds(
	character: RunnerCharacter, clip: RunnerAnimation.Clip, ground: float
) -> PackedFloat32Array:
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	var animation: RunnerAnimation = RunnerAnimation.new()
	animation.clip = RunnerAnimation.Clip.RUNNING
	animation.locomotion = [0.0, 0.0, 0.0, 0.0, 0.0]
	animation.locomotion[RunnerAnimation.LOCOMOTION.find(clip)] = 1.0
	animation.speed = ground / RunnerAnimation.own_speed(animation.locomotion, game_tuning)
	var title: String = RunnerAnimation.Clip.keys()[clip]
	return _planted_feet_speeds_playing(character, animation, title)


## The same, the tree of `character` playing the locomotion `animation`; `title` names it
## in the messages.
func _planted_feet_speeds_playing(
	character: RunnerCharacter, animation: RunnerAnimation, title: String
) -> PackedFloat32Array:
	var tree: AnimationTree = _tree_of(character)
	var skeleton: Skeleton3D = _skeleton_of(character)
	for step: int in SETTLE_STEPS:
		character.play(animation)
		tree.advance(1.0 / ReplayTest.STEPS_PER_SECOND)
	var bones: Array[PackedInt32Array] = []
	for foot: String in FEET:
		var named: PackedInt32Array = []
		for bone: String in FOOT_BONES:
			named.append(skeleton.find_bone(bone.replace("Left", foot.capitalize())))
		bones.append(named)
	var strides: float = tree.get(RunnerCharacter.STRIDE_SCALE)
	var samples: int = ceili(FOOT_SAMPLES_PER_SECOND / strides)
	# For each foot, the places of its bones at each instant, and the lowest each one goes.
	var places: Array[Array] = [[], []]
	var lowest: Array[PackedFloat32Array] = [[INF, INF], [INF, INF]]
	for sample: int in samples + 1:
		for foot: int in FEET.size():
			var place: PackedVector3Array = []
			for bone: int in FOOT_BONES.size():
				var pose: Vector3 = skeleton.get_bone_global_pose(bones[foot][bone]).origin
				var at: Vector3 = skeleton.global_transform * pose
				place.append(at)
				lowest[foot][bone] = minf(lowest[foot][bone], at.y)
			places[foot].append(place)
		tree.advance(1.0 / FOOT_SAMPLES_PER_SECOND)
	var speeds: PackedFloat32Array = []
	for foot: int in FEET.size():
		var back: Array[float] = []
		for sample: int in samples:
			var here: PackedVector3Array = places[foot][sample]
			var next: PackedVector3Array = places[foot][sample + 1]
			var low: int = 0 if here[0].y <= here[1].y else 1
			if maxf(here[low].y, next[low].y) - lowest[foot][low] <= ON_THE_GROUND:
				# The character faces -Z: a foot that goes back goes towards +Z.
				back.append((next[low].z - here[low].z) * FOOT_SAMPLES_PER_SECOND)
		var context: String = "%s, its %s foot" % [title, FEET[foot]]
		assert_gt(back.size(), 0, context + ": planted")
		back.sort()
		speeds.append(back[back.size() / 2] if not back.is_empty() else 0.0)
	return speeds


## How many steps `shares` takes to go from its last `from` to its first `to` after it.
func _steps_between(shares: Array[float], from: float, to: float) -> int:
	var left: int = -1
	for step: int in shares.size():
		if is_equal_approx(shares[step], from):
			left = step
		elif left >= 0 and is_equal_approx(shares[step], to):
			return step - left
	return -1


## The weights of the locomotion of `body`'s runner, as it shows them.
func _weights_of(body: MotorBody) -> PackedFloat32Array:
	return RunnerAnimation.of(body.motor, STEP).locomotion


func _assert_weights(weights: PackedFloat32Array, expected: Array[float], context: String) -> void:
	for index: int in expected.size():
		assert_almost_eq(weights[index], expected[index], 0.001, context)


## A body on the floor that runs at `speed` along -Z, as it starts its next step.
func _running_at(speed: float) -> MotorBody:
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, speed)
	body.step(_push(FORWARD * speed / _tuning.top_speed))
	return body


## The locomotion RunnerAnimation chooses for a runner on its feet at `speed`, with
## `tuning`, its top speed raised by `bonus` (the share a tier of the flow gives).
func _locomotion_of_a_runner_at(
	speed: float, bonus: float, tuning: MovementTuning
) -> RunnerAnimation:
	var body: MotorBody = MotorBody.new(tuning)
	body.motor.top_speed_bonus = bonus
	body.velocity = FORWARD * speed
	body.step(_push(FORWARD * minf(speed / body.motor.top_speed(), 1.0)))
	return RunnerAnimation.of(body.motor, STEP)


## The locomotion of a runner at `speed`, with `tuning`.
func _locomotion_at(speed: float, tuning: MovementTuning) -> RunnerAnimation:
	var animation: RunnerAnimation = RunnerAnimation.new()
	animation.clip = RunnerAnimation.Clip.RUNNING
	animation.locomotion = RunnerAnimation.locomotion_weights(speed, tuning)
	animation.speed = speed / RunnerAnimation.own_speed(animation.locomotion, tuning)
	animation.blend_time = tuning.animation_blend_time
	return animation


## The character with the files, in the tree; null without them.
func _character() -> RunnerCharacter:
	var character: RunnerCharacter = RunnerCharacter.create(
		RunnerCharacter.MODEL, load(TUNING) as MovementTuning
	)
	if character != null:
		add_child_autofree(character)
	return character


func _tree_of(character: RunnerCharacter) -> AnimationTree:
	return character.find_children("*", "AnimationTree", true, false)[0] as AnimationTree


func _skeleton_of(character: RunnerCharacter) -> Skeleton3D:
	return character.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D


## How far the left foot of the pose `skeleton` shows is ahead of the right one, and how
## much higher.
func _stride_pose(skeleton: Skeleton3D) -> Vector2:
	var left: Vector3 = (
		skeleton.get_bone_global_pose(skeleton.find_bone(RunnerCharacter.LEFT_FOOT)).origin
	)
	var right: Vector3 = (
		skeleton.get_bone_global_pose(skeleton.find_bone(RunnerCharacter.RIGHT_FOOT)).origin
	)
	return Vector2(left.z - right.z, left.y - right.y)


## The pose of Running at evenly spaced phases of its stride, from the left foot's
## touchdown, read from the clip the tree plays.
func _running_cycle(tree: AnimationTree, skeleton: Skeleton3D) -> PackedVector2Array:
	var library: AnimationLibrary = tree.get_animation_library(RunnerCharacter.LIBRARY)
	var clip: Animation = library.get_animation(&"running")
	var touchdown: float = RunnerCharacter.touchdown_of(RunnerAnimation.Clip.RUNNING)
	var cycle: PackedVector2Array = []
	for sample: int in RunnerCharacter.STRIDE_SAMPLES:
		var time: float = fposmod(
			touchdown + clip.length * sample / RunnerCharacter.STRIDE_SAMPLES, clip.length
		)
		var places: PackedVector3Array = RunnerCharacter.bone_places(clip, time, skeleton)
		var left: Vector3 = places[skeleton.find_bone(RunnerCharacter.LEFT_FOOT)]
		var right: Vector3 = places[skeleton.find_bone(RunnerCharacter.RIGHT_FOOT)]
		cycle.append(Vector2(left.z - right.z, left.y - right.y))
	return cycle


func _push(direction: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = direction
	return intent
