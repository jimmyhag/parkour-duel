class_name TrickRecipe
extends RefCounted
## What a trick is made of, before the runner does it: its flip, its turns and its
## twists, as the drawing reads them (TrickGesture); or the trick of the context, when
## nothing was drawn, whose flip the motor chooses from what the runner does. It travels
## in the intent, as the network will carry it tomorrow. Two tricks of the same recipe
## are the same move for the flow.

enum Flip {
	FRONT_FLIP,
	BACKFLIP,
	SIDE_FLIP,
	SPIN,
}

const FLIP_NAMES: Dictionary[Flip, String] = {
	Flip.FRONT_FLIP: "FRONT FLIP",
	Flip.BACKFLIP: "BACKFLIP",
	Flip.SIDE_FLIP: "SIDE FLIP",
}
const TURN_PREFIXES: Array[String] = ["", "", "DOUBLE ", "TRIPLE "]
const TWIST_SUFFIXES: Array[String] = ["", " FULL", " DOUBLE FULL", " TRIPLE FULL"]
const MANY_TURNS: String = "%dX "
const MANY_TWISTS: String = " %dX FULL"
const DEGREES_PER_TURN: int = 360

var flip: Flip = Flip.FRONT_FLIP
## The side of a side flip: 1 to the right, -1 to the left.
var side: int = 1
var turns: int = 1
var twists: int = 0
## The way the twists turn around the body (right-hand rule around up): -1 to the
## right, 1 to the left.
var twist_way: float = -1.0
## Nothing was drawn: the trick of the context, worth less. Before the motor chooses its
## flip, its flip means nothing.
var context: bool = false


## A recipe drawn: `flip` (to the `side` given for a side flip), `turns` and `twists`.
static func drawn(
	drawn_flip: Flip, drawn_turns: int = 1, drawn_twists: int = 0, drawn_side: int = 1
) -> TrickRecipe:
	var recipe: TrickRecipe = TrickRecipe.new()
	recipe.flip = drawn_flip
	recipe.turns = drawn_turns
	recipe.twists = drawn_twists
	recipe.side = drawn_side
	return recipe


## The trick of the context: a single `flip` of one turn, to the `side` given for a side
## flip. Without a flip, the one the motor will choose.
static func of_the_context(
	context_flip: Flip = Flip.FRONT_FLIP, context_side: int = 1
) -> TrickRecipe:
	var recipe: TrickRecipe = TrickRecipe.drawn(context_flip, 1, 0, context_side)
	recipe.context = true
	return recipe


## The name of the trick, built from its bricks: the turns as a prefix, the flip, the
## twists as a suffix; a spin is named by its degrees.
func name() -> String:
	if flip == Flip.SPIN:
		return str(turns * DEGREES_PER_TURN)
	var prefix: String = MANY_TURNS % turns
	if turns < TURN_PREFIXES.size():
		prefix = TURN_PREFIXES[turns]
	var suffix: String = MANY_TWISTS % twists
	if twists < TWIST_SUFFIXES.size():
		suffix = TWIST_SUFFIXES[twists]
	return prefix + FLIP_NAMES[flip] + suffix


## What tells two tricks apart for the repetition of the flow: their flip, their turns
## and their twists; the side of a side flip and the context do not.
func identity() -> String:
	return "%s %d %d" % [Flip.keys()[flip], turns, twists]


## The points of the trick, before a perfect landing: the trick of the context has its
## own; otherwise the points of the flip, multiplied for a double or a triple, plus the
## points of each twist.
func points(tuning: MovementTuning) -> int:
	if context:
		return tuning.trick_points_context
	var flip_points: float = tuning.trick_points_flip
	if flip == Flip.SIDE_FLIP or flip == Flip.SPIN:
		flip_points = tuning.trick_points_side_flip
	if turns == 2:
		flip_points *= tuning.trick_double_multiplier
	elif turns >= 3:
		flip_points *= tuning.trick_triple_multiplier
	return roundi(flip_points) + twists * tuning.trick_points_per_twist
