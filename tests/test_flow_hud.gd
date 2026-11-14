extends GutTest
## The flow display (game/ui): the gauge and its tier marks, the multiplier, the
## ammunition and the text of the last move, at the bottom of the screen.

const HUD_SCENE: PackedScene = preload("res://game/ui/flow_hud.tscn")
const STEPS_PER_SECOND: int = 60
const JUMP: RunnerEvent.Kind = RunnerEvent.Kind.JUMP
const SLIDE: RunnerEvent.Kind = RunnerEvent.Kind.SLIDE
const ROLL: RunnerEvent.Kind = RunnerEvent.Kind.ROLL
const MANTLE: RunnerEvent.Kind = RunnerEvent.Kind.MANTLE
const WALL_RUN: RunnerEvent.Kind = RunnerEvent.Kind.WALL_RUN
const HARD_LANDING: RunnerEvent.Kind = RunnerEvent.Kind.HARD_LANDING

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_hud_shows_the_move_and_its_points() -> void:
	var flow: FlowState = _flow()
	var hud: FlowHud = _add_hud(flow)
	hud.refresh()
	assert_eq(_text(hud, "%MoveLabel"), "", "at the start: no text")
	assert_eq(_text(hud, "%TierLabel"), "")
	assert_eq(_text(hud, "%MultiplierLabel"), "x1", "x1")
	assert_eq(_gauge(hud).value, 0.0, "an empty gauge")
	assert_eq(_full_pips(hud), [false, false, false], "three empty pips")
	for kind: RunnerEvent.Kind in [JUMP, SLIDE, MANTLE, ROLL]:
		_count(flow, kind)
	assert_eq(flow.multiplier(), 2, "a runner in a combo at x2")

	_count(flow, WALL_RUN)
	hud.refresh()

	assert_eq(_text(hud, "%MoveLabel"), "WALL RUN +300")
	assert_eq(_text(hud, "%MultiplierLabel"), "x2")


func test_the_hud_signals_a_tier_crossed() -> void:
	var flow: FlowState = _flow()
	var hud: FlowHud = _add_hud(flow)
	flow.gauge = 2.0 * _tuning.flow_tier_value - 50.0
	hud.refresh()
	assert_eq(_text(hud, "%TierLabel"), "", "a runner just under tier 2")

	_count(flow, WALL_RUN)
	hud.refresh()

	assert_eq(_text(hud, "%TierLabel"), "FLOW 2")
	var gauge: ProgressBar = _gauge(hud)
	assert_eq(gauge.max_value, flow.max_gauge(), "the gauge holds every tier")
	assert_almost_eq(gauge.value, flow.gauge, gauge.step, "and shows the gauge")
	var marks: Array[float] = _marks(hud)
	assert_eq(marks.size(), 3, "three tier marks")
	var second: float = marks[1] if marks.size() == 3 else 1.0
	assert_almost_eq(second, 2.0 / 3.0, 0.001, "the second at two thirds of the gauge")
	assert_gte(gauge.value / gauge.max_value, second, "the gauge is past it")


func test_the_hud_signals_a_broken_combo() -> void:
	var flow: FlowState = _flow()
	var hud: FlowHud = _add_hud(flow)
	for kind: RunnerEvent.Kind in [JUMP, SLIDE]:
		_count(flow, kind)
	assert_true(flow.in_combo(), "a runner in a combo")

	var events: Array[RunnerEvent] = [RunnerEvent.new(HARD_LANDING, 0)]
	flow.step(events, 0.0, true)
	hud.refresh()

	assert_eq(_text(hud, "%MoveLabel"), "COMBO BROKEN")


func test_the_hud_shows_the_ammunition() -> void:
	var flow: FlowState = _flow()
	var hud: FlowHud = _add_hud(flow)
	flow.ammo = 2

	hud.refresh()

	assert_eq(_full_pips(hud), [true, true, false], "two ammunition out of three")


func _flow() -> FlowState:
	return FlowState.new(_tuning, STEPS_PER_SECOND)


func _add_hud(flow: FlowState) -> FlowHud:
	var hud: FlowHud = HUD_SCENE.instantiate() as FlowHud
	hud.flow = flow
	add_child_autofree(hud)
	return hud


## One step at which the motor announced `kind`, the runner in the air at the top speed.
func _count(flow: FlowState, kind: RunnerEvent.Kind) -> void:
	var events: Array[RunnerEvent] = [RunnerEvent.new(kind, 0)]
	flow.step(events, _tuning.top_speed, false)


func _text(hud: FlowHud, label_path: NodePath) -> String:
	return (hud.get_node(label_path) as Label).text


func _gauge(hud: FlowHud) -> ProgressBar:
	return hud.get_node("%Gauge") as ProgressBar


## Where the tier marks stand along the gauge, from 0 (its start) to 1 (its end).
func _marks(hud: FlowHud) -> Array[float]:
	var marks: Array[float] = []
	for child: Node in _gauge(hud).get_children():
		var mark: Control = child as Control
		if mark != null:
			marks.append(mark.anchor_left)
	return marks


## Whether each pip of the ammunition is full: drawn filled, not only outlined.
func _full_pips(hud: FlowHud) -> Array[bool]:
	var full: Array[bool] = []
	for child: Node in hud.get_node("%Ammo").get_children():
		var pip: Panel = child as Panel
		var style: StyleBoxFlat = pip.get_theme_stylebox("panel") as StyleBoxFlat
		full.append(style.draw_center)
	return full
