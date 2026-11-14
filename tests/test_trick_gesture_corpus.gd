extends GutTest
## The human gestures (game/core): the corpus of the drawings a hand makes, on the mouse
## and on the right stick, measured by the two inspections of 2026-11-14 (63 gestures,
## then the ones the second one found misread), each with the recipe the hand means, read
## with the tuning of the project. Motions are in pixels for the mouse and in deflections
## for the stick (see GestureHand). After a flip, an arc is twists, never a spin, even a
## whole circle drawn on from the stroke (decision 24 of docs/specs/trick-gestures.md).

const PROJECT_TUNING: String = "res://game/core/movement_tuning.tres"
const D: Vector2 = Vector2.DOWN
const U: Vector2 = Vector2.UP
const R: Vector2 = Vector2.RIGHT
const L: Vector2 = Vector2.LEFT
const BACKFLIP: String = "BACKFLIP"
const DOUBLE: String = "DOUBLE BACKFLIP"
const FULL: String = "BACKFLIP FULL"
const DOUBLE_FULL: String = "DOUBLE BACKFLIP FULL"
const FULL_FULL: String = "BACKFLIP DOUBLE FULL"
const FRONT_FLIP: String = "FRONT FLIP"
const SIDE_FLIP: String = "SIDE FLIP"
## The gestures of the first inspection, and of the second.
const FIRST_INSPECTION: int = 63
const SECOND_INSPECTION: int = 20
## The gestures released right after the hand comes to rest.
const QUICK_RELEASES: int = 2
const SPIN: String = "360"
const CONTEXT: String = "CONTEXT"


## One gesture of the corpus: what it is, on which device, its motions, what the hand
## means, and for the mouse the share of the sensitivity of the project its player set
## the camera to; `released`, when what the hand means is the trick the release starts at
## its end, rather than what the drawing reads.
class Gesture:
	var label: String
	var on_the_stick: bool
	var motions: Array
	var meant: String
	var sensitivity: float = 1.0
	var released: bool = false

	func _init(what: String, stick: bool, steps: Array, recipe: String) -> void:
		label = what
		on_the_stick = stick
		motions = steps
		meant = recipe


var _tuning: MovementTuning


func before_all() -> void:
	_tuning = load(PROJECT_TUNING) as MovementTuning


func test_human_gestures_are_read_as_the_hand_means_them() -> void:
	var corpus: Array[Gesture] = _mouse_gestures()
	corpus.append_array(_stick_gestures())
	assert_eq(corpus.size(), FIRST_INSPECTION, "the gestures of the first inspection")
	var second: Array[Gesture] = _second_mouse_gestures()
	second.append_array(_second_stick_gestures())
	assert_eq(second.size(), SECOND_INSPECTION, "the gestures of the second inspection")
	corpus.append_array(second)
	var quick: Array[Gesture] = _quick_releases()
	assert_eq(quick.size(), QUICK_RELEASES, "the gestures released right away")
	corpus.append_array(quick)
	for gesture: Gesture in corpus:
		var drawing: TrickGesture = TrickGesture.new(_tuning)

		if gesture.on_the_stick:
			GestureHand.stick(drawing, gesture.motions)
		else:
			GestureHand.mouse(drawing, gesture.motions, gesture.sensitivity)
		if gesture.released:
			var started: TrickRecipe = drawing.validated_recipe()
			var name: String = "NOTHING" if started == null else started.name()
			if started != null and started.context:
				name = CONTEXT
			assert_eq(name, gesture.meant, gesture.label + ": what the release starts")
			continue

		assert_eq(GestureHand.read(drawing), gesture.meant, gesture.label)


func _mouse_gestures() -> Array[Gesture]:
	var still: Array = GestureHand.still(6)
	var pause: Array = GestureHand.still(4)
	var down: Array = _bell(D, 150, 5)
	var up_and_down: Array = down + _bell(U, 150, 5) + down
	var wrist_30: Array = []
	var wrist_50: Array = []
	for step: int in 6:
		wrist_30.append(D.rotated(deg_to_rad(-15.0 + 6.0 * step)) * 25.0)
		wrist_50.append(D.rotated(deg_to_rad(-25.0 + 10.0 * step)) * 25.0)
	var round_2: Array = [Vector2(8, 10), Vector2(10, 2), Vector2(6, -8)]
	var round_3: Array = [Vector2(5, 15), Vector2(12, 4), Vector2(8, -10), Vector2(2, -25)]
	var half: Array = _arc(R, 180.0, 60.0, 10)
	var jitter: Array = [Vector2(5, 3), Vector2(-4, 6), Vector2(7, -2), Vector2(-3, -5)]
	return [
		_mouse("M1 flick down, recoil up 15 px", down + _bell(U, 15, 2) + still, BACKFLIP),
		_mouse("M1b 100 px, recoil 30 px", _bell(D, 100, 4) + _bell(U, 30, 2) + still, BACKFLIP),
		_mouse("M1c flick down 85 px", _bell(D, 85, 3) + still, BACKFLIP),
		_mouse("M1d flick down 70 px", _bell(D, 70, 3) + still, BACKFLIP),
		_mouse(
			"M2 back up through a tight U-turn",
			down + _arc(D, -180.0, 20.0, 4) + _bell(U, 130, 5) + still,
			BACKFLIP
		),
		_mouse("M2b back up, drifting aside", down + round_2 + _bell(U, 140, 5) + still, BACKFLIP),
		_mouse("M2c back up, rounder", down + round_3 + _bell(U, 120, 4) + still, BACKFLIP),
		_mouse("M3 wrist arc of 30 degrees", wrist_30 + still, BACKFLIP),
		_mouse("M3b wrist arc of 50 degrees", wrist_50 + still, BACKFLIP),
		_mouse(
			"M4 40 degrees off down", _bell(D.rotated(deg_to_rad(40)), 150, 5) + still, BACKFLIP
		),
		_mouse("M5 down, up, down", up_and_down + still, DOUBLE),
		_mouse(
			"M5b down, back 20 degrees aside, down",
			down + _bell(U.rotated(0.35), 150, 5) + down + still,
			DOUBLE
		),
		_mouse("M5c down, back 40 px, down", down + _bell(U, 40, 3) + down + still, DOUBLE),
		_mouse("M6 down curling into a J", down + _arc(D, 180.0, 60.0, 10) + still, FULL),
		_mouse("M6b down, pause, half circle", down + pause + half + still, FULL),
		_mouse(
			"M6c down, back up, half circle from the left",
			down + _bell(U, 150, 5) + _arc(L, -180.0, 60.0, 10) + still,
			FULL
		),
		_mouse(
			"M6d down, back up, half circle starting down",
			down + _bell(U, 150, 5) + _arc(D, 180.0, 60.0, 10) + still,
			FULL
		),
		_mouse("M6e down curling 130 degrees", down + _arc(D, 130.0, 60.0, 8) + still, FULL),
		_mouse(
			"M6f half circle overshot to 280 degrees",
			down + pause + _arc(R, 280.0, 60.0, 14) + still,
			FULL
		),
		_mouse(
			"M6g half circle of 250 degrees", down + pause + _arc(R, 250.0, 60.0, 14) + still, FULL
		),
		_mouse("M6h small half circle", down + pause + _arc(R, 180.0, 25.0, 10) + still, FULL),
		_mouse(
			"M6i half circle after a straight 40 px",
			down + pause + _bell(D, 40, 2) + _arc(D, 180.0, 60.0, 10) + still,
			FULL
		),
		_mouse(
			"M6j half circle after a straight 90 px",
			down + pause + _bell(D, 90, 3) + _arc(D, 180.0, 60.0, 10) + still,
			FULL
		),
		_mouse("M7 circle", _arc(R, 360.0, 80.0, 20) + still, SPIN),
		_mouse(
			"M7b circle after 50 px down", _bell(D, 50, 3) + _arc(D, 360.0, 80.0, 20) + still, SPIN
		),
		_mouse(
			"M7c circle after 120 px down: the flip, and twists",
			_bell(D, 120, 4) + _arc(D, 360.0, 80.0, 20) + still,
			FULL_FULL
		),
		_mouse(
			"M7d circle after 120 px right: a side flip takes no twist",
			_bell(R, 120, 4) + _arc(R, 360.0, 80.0, 20) + still,
			SIDE_FLIP
		),
		_mouse("M7e fast circle", _arc(R, 360.0, 80.0, 8) + still, SPIN),
		_mouse("M7f very fast circle", _arc(R, 360.0, 80.0, 5) + still, SPIN),
		_mouse("M7g circle of 290 degrees", _arc(L, -290.0, 80.0, 16) + still, SPIN),
		_mouse("M7h small circle", _arc(R, 360.0, 20.0, 16) + still, SPIN),
		_mouse(
			"M8 fast flick, recoil 100 px", _bell(D, 600, 3) + _bell(U, 100, 2) + still, BACKFLIP
		),
		_mouse(
			"M8b fast flick up, recoil 100 px",
			_bell(U, 600, 3) + _bell(D, 100, 2) + still,
			"FRONT FLIP"
		),
		_mouse("M9 the camera turned 50 px as F goes down", _bell(R, 50, 3) + _hold0(10), CONTEXT),
		_mouse(
			"M9b 120 px to the right as F goes down", _bell(R, 120, 3) + _hold0(10), "SIDE FLIP"
		),
		_mouse("M9c a hand that trembles", jitter + _hold0(10), CONTEXT),
		_mouse(
			"M10 flick, recoil, pause, half circle",
			down + _bell(U, 15, 2) + pause + half + still,
			FULL
		),
		_mouse(
			"M11 down, up, down, pause, half circle",
			up_and_down + pause + half + still,
			DOUBLE_FULL
		),
	]


func _stick_gestures() -> Array[Gesture]:
	var still: Array = GestureHand.still(6)
	var flick: Array = _hold(D, 6)
	return [
		_stick(
			"S1 flick: half, 4 full, half", [D * 0.5] + _hold(D, 4) + [D * 0.5] + still, BACKFLIP
		),
		_stick(
			"S1b flick: half, 3 full, 0.4", [D * 0.5] + _hold(D, 3) + [D * 0.4] + still, BACKFLIP
		),
		_stick(
			"S1c flick: 0.6, 2 full, 0.4", [D * 0.6] + _hold(D, 2) + [D * 0.4] + still, BACKFLIP
		),
		_stick("S1d flick of 5 steps", _hold(D, 5) + still, BACKFLIP),
		_stick("S1e flick of 4 steps", _hold(D, 4) + still, BACKFLIP),
		_stick("S2 two flicks, 1 step apart", flick + _hold0(1) + flick + still, DOUBLE),
		_stick("S2b two flicks, 2 steps apart", flick + _hold0(2) + flick + still, DOUBLE),
		_stick("S2c two flicks, 3 steps apart", flick + _hold0(3) + flick + still, DOUBLE),
		_stick(
			"S2d two flicks with ramps, 1 step apart",
			(
				[D * 0.5]
				+ _hold(D, 5)
				+ [D * 0.4, Vector2.ZERO, D * 0.5]
				+ _hold(D, 5)
				+ [D * 0.4]
				+ still
			),
			DOUBLE
		),
		_stick("S3 flick overshooting the centre", flick + [U * 0.3] + still, BACKFLIP),
		_stick("S4 flick, half roll", flick + still + _roll(R, 180.0, 18) + still, FULL),
		_stick(
			"S5 flick, held down 0.1 s, half roll",
			flick + still + _hold(D, 6) + _roll(D, 180.0, 18) + still,
			FULL
		),
		_stick(
			"S5b flick, held down 0.05 s, half roll",
			flick + still + _hold(D, 3) + _roll(D, 180.0, 18) + still,
			FULL
		),
		_stick("S5c flick, half roll from down", flick + still + _roll(D, 180.0, 18) + still, FULL),
		_stick("S6 J: down 0.1 s, half roll", _hold(D, 6) + _roll(D, 180.0, 18) + still, FULL),
		_stick("S6b J: down 0.05 s, half roll", _hold(D, 3) + _roll(D, 180.0, 18) + still, FULL),
		_stick(
			"S6c J: down 0.1 s, slow half roll", _hold(D, 6) + _roll(D, 180.0, 30) + still, FULL
		),
		_stick("S7 right 0.1 s, a roll", _hold(R, 6) + _roll(R, 360.0, 18) + still, SIDE_FLIP),
		_stick("S7b down 0.1 s, a roll", _hold(D, 6) + _roll(D, 360.0, 18) + still, FULL_FULL),
		_stick("S7c a roll", _roll(R, 360.0, 24) + still, SPIN),
		_stick("S7d up 0.05 s, a slow roll", _hold(U, 3) + _roll(U, 360.0, 30) + still, SPIN),
		_stick("S7e right 0.15 s, a roll", _hold(R, 9) + _roll(R, 360.0, 18) + still, SIDE_FLIP),
		_stick("S7f down 0.15 s, a roll", _hold(D, 9) + _roll(D, 360.0, 24) + still, FULL_FULL),
		_stick("S8 a roll of 300 degrees", _roll(R, 300.0, 18) + still, SPIN),
		_stick("S9 pushed at 60 % for 8 steps", _hold(D * 0.6, 8) + still, BACKFLIP),
	]


## The gestures the second inspection found misread on the mouse, and their neighbours.
func _second_mouse_gestures() -> Array[Gesture]:
	var still: Array = GestureHand.still(6)
	var down: Array = _bell(D, 150, 5)
	var u_turn: Array = _arc(D, -180.0, 20.0, 4)
	var tremor: Array = []
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 3
	for step: int in 30:
		tremor.append(Vector2(random.randf_range(-4.0, 4.0), random.randf_range(-4.0, 4.0)))
	var trembling: Gesture = _mouse(
		"N6 a hand that trembles 4 px a step, the camera at a quarter of the sensitivity",
		tremor,
		CONTEXT
	)
	trembling.sensitivity = 0.25
	var gestures: Array[Gesture] = [
		_mouse(
			"N1 a slow stroke that hesitates 3 steps midway",
			_bell(D, 80, 4) + GestureHand.still(3) + _bell(D, 80, 4) + still,
			BACKFLIP
		),
		_mouse(
			"N1b a slow stroke that hesitates 0.1 s midway",
			_bell(D, 80, 4) + GestureHand.still(6) + _bell(D, 80, 4) + still,
			BACKFLIP
		),
		_mouse(
			"N1c two strokes down 0.15 s apart", down + GestureHand.still(9) + down + still, DOUBLE
		),
		_mouse(
			"N2 down, sharp up, a small loop at the top, down",
			down + _bell(U, 130, 5) + _arc(U, 180.0, 20.0, 4) + down + still,
			DOUBLE
		),
		_mouse(
			"N2b zigzag: down, rounded turn, up, rounded turn the other way, down",
			down + u_turn + _bell(U, 150, 5) + _arc(U, 180.0, 20.0, 4) + down + still,
			DOUBLE
		),
		_mouse(
			"N2c ellipse: down, rounded turn, up, rounded turn the same way, down",
			down + u_turn + _bell(U, 150, 5) + _arc(U, -180.0, 20.0, 4) + down + still,
			DOUBLE
		),
		_mouse(
			"N2d down, rounded turn, up, sharp down",
			down + u_turn + _bell(U, 130, 5) + down + still,
			DOUBLE
		),
		_mouse("N3 J with a hook of 290 degrees", down + _arc(D, 290.0, 60.0, 14) + still, FULL),
		_mouse("N3b J with a hook of 260 degrees", down + _arc(D, 260.0, 60.0, 14) + still, FULL),
		_mouse("N4 a spin and a half", _arc(R, 540.0, 80.0, 30) + still, SPIN),
		trembling,
	]
	for degrees: float in [70.0, 80.0, 90.0]:
		var wrist: Array = []
		for step: int in 6:
			wrist.append(U.rotated(deg_to_rad(-degrees / 2.0 + degrees / 5.0 * step)) * 25.0)
		gestures.append(
			_mouse("N5 wrist arc up of %d degrees" % degrees, wrist + still, FRONT_FLIP)
		)
	return gestures


## The gestures the second inspection found misread on the right stick.
func _second_stick_gestures() -> Array[Gesture]:
	var still: Array = GestureHand.still(6)
	var ramp: Array = [D * 0.4, D * 0.9, D, D, D * 0.5, U * 0.35, U * 0.1]
	return [
		_stick("T1 short flick, a bounce back", [D * 0.7, D, D * 0.6, U * 0.4] + still, BACKFLIP),
		_stick("T1b two steps fully pushed", _hold(D, 2) + still, BACKFLIP),
		_stick("T1c four steps at 60 %", _hold(D * 0.6, 4) + still, BACKFLIP),
		_stick("T1d up: 0.6, 1, 0.5", [U * 0.6, U, U * 0.5] + still, FRONT_FLIP),
		_stick(
			"T2 two flicks, a dip to 0.3 between",
			_hold(D, 3) + [D * 0.3] + _hold(D, 3) + still,
			DOUBLE
		),
		_stick("T2b two flicks with ramps and bounces", ramp + ramp + still, DOUBLE),
	]


## A flick, then the button released after three steps of rest: the owner flicks and
## releases fast, and the flick must start, not the trick of the context.
func _quick_releases() -> Array[Gesture]:
	var rest: Array = GestureHand.still(3)
	var gestures: Array[Gesture] = [
		_mouse(
			"Q1 a flick down, released after 3 steps of rest", _bell(D, 150, 5) + rest, BACKFLIP
		),
		_stick("Q2 a flick up, released after 3 steps of rest", _hold(U, 4) + rest, FRONT_FLIP),
	]
	for gesture: Gesture in gestures:
		gesture.released = true
	return gestures


func _mouse(what: String, pixels: Array, meant: String) -> Gesture:
	return Gesture.new(what, false, pixels, meant)


func _stick(what: String, deflections: Array, meant: String) -> Gesture:
	return Gesture.new(what, true, deflections, meant)


func _bell(way: Vector2, total: float, steps: int) -> Array:
	return GestureHand.bell(way, total, steps)


func _arc(start: Vector2, degrees: float, radius: float, steps: int) -> Array:
	return GestureHand.arc(start, degrees, radius, steps)


func _roll(start: Vector2, degrees: float, steps: int) -> Array:
	return GestureHand.roll(start, degrees, steps)


func _hold(value: Vector2, steps: int) -> Array:
	return GestureHand.hold(value, steps)


func _hold0(steps: int) -> Array:
	return GestureHand.still(steps)
