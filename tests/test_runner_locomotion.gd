extends GutTest
## The locomotion of the runner's body (docs/specs/locomotion-blend.md): on its feet, a
## blend of Idle, Walking, Running and Sprint on its horizontal speed, the clips at the
## same phase of their stride, a blend time for each pair of animations, and the run
## resumed at the stride nearest the pose it comes from. The weights, the table and the
## phases are logic, tested without the Mixamo files; with them (on the owner's machine),
## the same rules are checked on the character's animation tree. The tuning of the logic is
## the fixed one of MotorBody; the runners go along -Z.

const FORWARD: Vector3 = Vector3.FORWARD
const STEP: float = MotorBody.STEP
## The tuning of the game, for the character with the files.
const TUNING: String = "res://game/core/movement_tuning.tres"
## More steps than any fall of these tests lasts.
const MANY_STEPS: int = 600
## The weights of the locomotion, in the order of RunnerAnimation.LOCOMOTION.
const IDLE: int = 0
const WALKING: int = 1
const RUNNING: int = 2
const SPRINT: int = 3
## Speeds well spread over the whole range of the locomotion, in m/s.
const SPEEDS: Array[float] = [0.0, 0.3, 0.5, 0.9, 1.4, 2.0, 4.4, 7.0, 9.0, 9.4, 10.0, 10.35, 14.0]
## A made-up stride of two clips: the height of the left foot (its ankle and its toe) above
## the ground at evenly spaced instants of one cycle, and the length of that cycle, in s.
## The first touches the ground at its third sample; the second, longer, at its sixth.
const MADE_UP_ANKLES: Array[PackedFloat32Array] = [
	[0.30, 0.20, 0.12, 0.10, 0.10, 0.11, 0.25, 0.40],
	[0.25, 0.30, 0.31, 0.29, 0.20, 0.11, 0.10, 0.10, 0.10, 0.18],
]
const MADE_UP_TOES: Array[PackedFloat32Array] = [
	[0.20, 0.10, 0.005, 0.00, 0.00, 0.00, 0.10, 0.30],
	[0.15, 0.20, 0.20, 0.18, 0.10, 0.005, 0.00, 0.00, 0.00, 0.08],
]
const MADE_UP_TOUCHDOWNS: Array[float] = [2.0 / 8.0, 5.0 / 10.0]
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

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_blend_space_weights_follow_the_speed() -> void:
	var still: PackedFloat32Array = _weights_of(_running_at(0.0))
	var between: float = (_tuning.animation_walk_speed + _tuning.top_speed) / 2.0
	var walking_and_running: PackedFloat32Array = _weights_of(_running_at(between))
	var at_top_speed: PackedFloat32Array = _weights_of(_running_at(_tuning.top_speed))
	var flowing: MotorBody = _running_at(_tuning.top_speed)
	# Tier 2 of the flow: faster than the top speed, slower than tier 3.
	flowing.motor.top_speed_bonus = _tuning.flow_tier_speed_bonus[1]
	for step: int in FLOW_STEPS:
		flowing.step(_push(FORWARD))
	var with_the_flow: PackedFloat32Array = _weights_of(flowing)

	_assert_weights(still, [1.0, 0.0, 0.0, 0.0], "still: Idle alone")
	assert_almost_eq(walking_and_running[WALKING], 0.5, 0.02, "between: half Walking")
	assert_almost_eq(walking_and_running[RUNNING], 0.5, 0.02, "and half Running")
	_assert_weights(at_top_speed, [0.0, 0.0, 1.0, 0.0], "at its top speed: Running alone")
	assert_gt(flowing.motor.real_speed(), _tuning.top_speed, "with the flow, faster")
	assert_gt(with_the_flow[RUNNING], 0.0, "with the flow: Running")
	assert_gt(with_the_flow[SPRINT], 0.0, "blended with Sprint")
	assert_almost_eq(with_the_flow[RUNNING] + with_the_flow[SPRINT], 1.0, 0.001, "only them")

	var sprint_point: float = _tuning.top_speed * (1.0 + _tuning.flow_tier_speed_bonus[2])
	var sprinting: PackedFloat32Array = RunnerAnimation.locomotion_weights(sprint_point, _tuning)
	_assert_weights(sprinting, [0.0, 0.0, 0.0, 1.0], "at the top speed of tier 3: Sprint alone")
	var walking: PackedFloat32Array = RunnerAnimation.locomotion_weights(
		_tuning.animation_walk_speed, _tuning
	)
	_assert_weights(walking, [0.0, 1.0, 0.0, 0.0], "at its own speed: Walking alone")
	var animation: RunnerAnimation = RunnerAnimation.of(_running_at(between).motor, STEP)
	assert_eq(animation.clip, RunnerAnimation.Clip.RUNNING, "moving on its feet: the locomotion")
	assert_eq(animation.locomotion, walking_and_running, "with its weights")


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
	var between: float = (_tuning.animation_walk_speed + _tuning.top_speed) / 2.0
	var game_tuning: MovementTuning = load(TUNING) as MovementTuning
	var animation: RunnerAnimation = _locomotion_at(between, game_tuning)
	assert_gt(animation.locomotion[WALKING], 0.0, "walking")
	assert_gt(animation.locomotion[RUNNING], 0.0, "and running")
	for step: int in SETTLE_STEPS:
		await get_tree().physics_frame
		character.play(animation)
	await get_tree().process_frame
	var phases: PackedFloat32Array = []
	for clip: RunnerAnimation.Clip in RunnerCharacter.STRIDES:
		var phase: float = tree.get(RunnerCharacter.stride_position(clip))
		phases.append(phase)
	gut.p("phases of Walking, Running, Sprint: %s" % [phases])
	assert_almost_eq(phases[0], phases[1], 0.001, "Walking and Running at the same phase")
	assert_almost_eq(phases[1], phases[2], 0.001, "Running and Sprint at the same phase")
	assert_gt(phases[0], 0.0, "the stride moves on")

	# At the phase 0 of each clip alone, as the tree plays it, its left foot touches the
	# ground (its heel or its toe at its lowest): the phase means the same moment of the
	# stride in every clip.
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var skeleton: Skeleton3D = _skeleton_of(character)
	var foot: Array[int] = [
		skeleton.find_bone(RunnerCharacter.LEFT_FOOT), skeleton.find_bone(RunnerCharacter.LEFT_TOE)
	]
	var sprint_point: float = game_tuning.top_speed * (1.0 + game_tuning.flow_tier_speed_bonus[2])
	var points: Array[float] = [
		game_tuning.animation_walk_speed, game_tuning.top_speed, sprint_point
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


func test_each_transition_has_its_blend_time() -> void:
	var pairs: Array[Array] = [
		[RunnerAnimation.Clip.RUNNING, RunnerAnimation.Clip.JUMP, 0.05, "run → jump"],
		[RunnerAnimation.Clip.RUNNING_SLIDE, RunnerAnimation.Clip.RUNNING, 0.2, "slide → run"],
		[
			RunnerAnimation.Clip.SPRINT_TO_WALL_CLIMB,
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
	assert_eq(jumping.clip, RunnerAnimation.Clip.JUMP, "it jumps")
	assert_eq(jumping.blend_time, 0.05, "with the blend time of run → jump")


func test_an_abrupt_entry_stays_without_a_blend() -> void:
	# Even a table that would give them one.
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
	assert_eq(hard.blend_time, 0.0, "without a blend")

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
	var running: RunnerAnimation = _locomotion_at(game_tuning.top_speed, game_tuning)
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
