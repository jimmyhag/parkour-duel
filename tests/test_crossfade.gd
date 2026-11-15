extends GutTest
## The blend of the animations of the character (Crossfade, game/player), frame by frame,
## without the Mixamo files (docs/specs/animation-polish.md, decision 3): a state comes in
## its blend time while the others go as much, and a blend cut short by another one goes on
## from where it got to. No weight ever jumps, but into a state that comes at once (a hard
## landing, a crash).

## A frame of a display at 144 images a second.
const FRAME: float = 1.0 / 144.0
## The states of the made-up chain: each one, its blend time, and how many frames it lasts
## before the next one comes, fewer than its blend takes for the first three.
const CHAIN: Array[Array] = [
	[&"wall_run", 0.1, 6],
	[&"falling", 0.15, 9],
	[&"landing", 0.05, 4],
	[&"running", 0.15, 60],
]


func test_an_interrupted_blend_does_not_jump() -> void:
	var fade: Crossfade = Crossfade.new()
	assert_true(fade.go_to(&"running", 0.0), "the first state comes from nothing")
	fade.advance(FRAME)
	assert_almost_eq(fade.weight(&"running"), 1.0, 0.0001, "at once, without a blend")

	for link: Array in CHAIN:
		var state: StringName = link[0]
		var blend: float = link[1]
		var frames: int = link[2]
		var before: Dictionary[StringName, float] = fade.weights.duplicate()
		var shown: float = before.get(state, 0.0)
		var fresh: bool = fade.go_to(state, blend)
		assert_eq(fresh, shown <= 0.0, "%s: from nothing or not" % state)
		for frame: int in frames:
			before = fade.weights.duplicate()
			fade.advance(FRAME)
			var context: String = "into %s, frame %d" % [state, frame]
			var total: float = 0.0
			for named: StringName in fade.weights:
				var weight: float = fade.weight(named)
				total += weight
				assert_between(weight, 0.0, 1.0, context + ": a weight from 0 to 1")
				var was: float = before.get(named, 0.0)
				var change: float = absf(weight - was)
				# Eased (docs/specs/motion-weight.md, decision 8): at most the steepest slope
				# of its curve, in the middle of the blend.
				var most: float = Crossfade.STEEPEST * FRAME / blend
				assert_lte(change, most + 0.0001, "%s: %s does not jump" % [context, named])
			assert_almost_eq(total, 1.0, 0.0001, context + ": the weights make a whole")
	assert_almost_eq(fade.weight(&"running"), 1.0, 0.0001, "the last state, wholly in")
	assert_almost_eq(fade.weight(&"landing"), 0.0, 0.0001, "the others, gone")

	# Back into a state still blending out: it comes back from where it is, not from nothing.
	fade.go_to(&"jump", 0.1)
	fade.advance(FRAME * 3.0)
	assert_false(fade.go_to(&"running", 0.1), "running, still shown: not from nothing")

	# A hard landing comes at once.
	fade.go_to(&"hard_landing", 0.0)
	fade.advance(FRAME)
	assert_almost_eq(fade.weight(&"hard_landing"), 1.0, 0.0001, "a hard landing, at once")
	assert_almost_eq(fade.weight(&"running"), 0.0, 0.0001, "nothing else shown")


func test_the_blends_are_eased() -> void:
	# docs/specs/motion-weight.md, decision 8: out of a slide into the run, with the game's
	# table; the weight of the run, frame by frame at 144 images a second.
	var tuning: MovementTuning = load("res://game/core/movement_tuning.tres") as MovementTuning
	var pair: float = RunnerAnimation.blend_time_between(
		RunnerAnimation.Clip.RUNNING_SLIDE, RunnerAnimation.Clip.RUNNING, tuning
	)
	var fade: Crossfade = Crossfade.new()
	fade.go_to(&"running_slide", 0.0)
	fade.advance(FRAME)
	fade.go_to(&"locomotion", pair)
	var weights: Array[float] = [0.0]
	while fade.weight(&"locomotion") < 1.0 and weights.size() < 1000:
		fade.advance(FRAME)
		weights.append(fade.weight(&"locomotion"))
		var total: float = fade.weight(&"locomotion") + fade.weight(&"running_slide")
		assert_almost_eq(total, 1.0, 0.0001, "frame %d: a whole" % weights.size())
	var frames: int = weights.size() - 1
	var linear: float = FRAME / pair
	gut.p(
		(
			"slide to run: %d frames for %.3f s; first and last change %.4f, %.4f"
			% [frames, pair, weights[1] - weights[0], weights[-1] - weights[-2]]
		)
	)
	assert_almost_eq(frames * FRAME, pair, FRAME, "it lasts the time of its pair")
	assert_lt(weights[1] - weights[0], linear / 4.0, "it starts at a speed near nothing")
	assert_lt(weights[-1] - weights[-2], linear / 4.0, "and arrives at one")
	var middle: int = roundi(pair / 2.0 / FRAME)
	assert_almost_eq(weights[middle], 0.5, linear, "half way, half of it")
	for frame: int in range(1, weights.size()):
		assert_gte(weights[frame], weights[frame - 1], "frame %d: it only comes" % frame)
	assert_almost_eq(Crossfade.eased(0.0), 0.0, 0.0001, "the curve starts at 0")
	assert_almost_eq(Crossfade.eased(0.5), 0.5, 0.0001, "is half at mid-way")
	assert_almost_eq(Crossfade.eased(1.0), 1.0, 0.0001, "and ends at 1")


func test_a_blend_asked_for_again_keeps_its_time() -> void:
	# Out of a slide into the run: the run is asked for again at every fixed step, with the
	# blend time of a clip into itself (the default); the blend takes the time of its pair.
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var slide: RunnerAnimation.Clip = RunnerAnimation.Clip.RUNNING_SLIDE
	var run: RunnerAnimation.Clip = RunnerAnimation.Clip.RUNNING
	var pair: float = RunnerAnimation.blend_time_between(slide, run, tuning)
	var again: float = RunnerAnimation.blend_time_between(run, run, tuning)
	assert_ne(pair, again, "the pair has its own time, not the default")
	var fade: Crossfade = Crossfade.new()
	fade.go_to(&"running_slide", 0.0)
	fade.advance(FRAME)
	assert_true(fade.go_to(&"locomotion", pair), "the run comes from nothing")
	var frames: int = 0
	while fade.weight(&"locomotion") < 1.0 and frames < 1000:
		fade.advance(FRAME)
		frames += 1
		# A fixed step at least every other frame of a display at 144 images a second.
		if frames % 2 == 0:
			assert_false(fade.go_to(&"locomotion", again), "asked for again: not from nothing")
	var lasted: float = frames * FRAME
	gut.p("slide to run lasted %.3f s, its pair %.3f s" % [lasted, pair])
	assert_almost_eq(lasted, pair, FRAME, "the blend lasts the time of the pair slide to run")
