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
				assert_lte(
					change, FRAME / blend + 0.0001, "%s: %s does not jump" % [context, named]
				)
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
