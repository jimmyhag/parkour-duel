class_name FlowHud
extends Control
## The flow of the runner, at the bottom of the screen: the gauge as a bar with one mark
## per tier, the multiplier at its left, the ammunition at its right as pips (filled or
## only outlined), and above it the moves of the last step and their points, the tier
## just crossed (FLOW and its number, while the gauge flashes) or COMBO BROKEN, which fade
## out after about a second. Above them, while the trick button is held, the name of the
## recipe its drawing reads (? while nothing is read); then the name of the trick under
## way in the air, and after a landing PERFECT or CRASH, or SABOTAGED when a sabotage hit
## the runner, which fade out the same way. Nothing takes the focus.

const MOVE: String = "%s +%d"
const MULTIPLIER: String = "x%d"
const TIER: String = "FLOW %d"
const COMBO_BROKEN: String = "COMBO BROKEN"
const PERFECT: String = "PERFECT"
const CRASH: String = "CRASH"
const SABOTAGED: String = "SABOTAGED"
## Drawn so far, nothing that can be read: neither a recipe nor the trick of the context.
const UNREAD: String = "?"
## Between the moves of one step.
const SEPARATOR: String = "   "
const MOVE_NAMES: Dictionary[RunnerEvent.Kind, String] = {
	RunnerEvent.Kind.JUMP: "JUMP",
	RunnerEvent.Kind.SLIDE: "SLIDE",
	RunnerEvent.Kind.PERFECT_SLIDE: "PERFECT SLIDE",
	RunnerEvent.Kind.ROLL: "ROLL",
	RunnerEvent.Kind.MANTLE: "MANTLE",
	RunnerEvent.Kind.WALL_RUN: "WALL RUN",
	RunnerEvent.Kind.WALL_JUMP: "WALL JUMP",
}
## How long a text stays on screen, and how long the gauge flashes, in s.
const TEXT_SECONDS: float = 1.0
const FLASH_SECONDS: float = 0.4
const FLASH: Color = Color(2.0, 2.0, 2.0)
const MARK_WIDTH: float = 3.0
const MARK_COLOR: Color = Color(1.0, 1.0, 1.0)
const PIP_SIZE: Vector2 = Vector2(18.0, 18.0)
const PIP_COLOR: Color = Color(1.0, 0.85, 0.3)

## The flow to display, and the motor whose drawing and trick under way it names.
var flow: FlowState
var motor: RunnerMotor

## What was already announced: the counts of the flow at the last refresh.
var _moves_seen: int = 0
var _tiers_seen: int = 0
var _breaks_seen: int = 0
var _perfects_seen: int = 0
var _crashes_seen: int = 0
var _sabotages_seen: int = 0
## What is left of the move text, of the landing text, of the tier text and of the
## flash, in s.
var _move_seconds: float = 0.0
var _landing_seconds: float = 0.0
var _tier_seconds: float = 0.0
var _flash_seconds: float = 0.0

@onready var _move_label: Label = %MoveLabel as Label
@onready var _trick_label: Label = %TrickLabel as Label
@onready var _tier_label: Label = %TierLabel as Label
@onready var _multiplier_label: Label = %MultiplierLabel as Label
@onready var _gauge: ProgressBar = %Gauge as ProgressBar
@onready var _ammo: HBoxContainer = %Ammo as HBoxContainer


func _process(delta: float) -> void:
	_move_seconds = maxf(_move_seconds - delta, 0.0)
	_landing_seconds = maxf(_landing_seconds - delta, 0.0)
	_tier_seconds = maxf(_tier_seconds - delta, 0.0)
	_flash_seconds = maxf(_flash_seconds - delta, 0.0)
	refresh()


## Writes the current state of the flow on screen.
func refresh() -> void:
	if flow == null:
		return
	_announce()
	_move_label.visible = _move_seconds > 0.0
	_name_the_trick()
	_tier_label.visible = _tier_seconds > 0.0
	_multiplier_label.text = MULTIPLIER % flow.multiplier()
	_gauge.max_value = flow.max_gauge()
	_gauge.value = flow.gauge
	_gauge.self_modulate = Color.WHITE.lerp(FLASH, _flash_seconds / FLASH_SECONDS)
	_place_the_marks(flow.tuning.flow_tier_count)
	_fill_the_pips(flow.tuning.flow_max_ammo, flow.ammo)


## Shows what the flow counted since the last refresh: the moves of the last step and
## their points, a combo broken, a tier crossed, a perfect landing, a crash or a
## sabotage received.
func _announce() -> void:
	if flow.moves_counted != _moves_seen:
		_moves_seen = flow.moves_counted
		var texts: Array[String] = []
		for index: int in flow.step_moves.size():
			var move: RunnerEvent = flow.step_moves[index]
			var move_name: String = MOVE_NAMES.get(move.kind, "")
			if move.trick != null:
				move_name = move.trick.name()
			texts.append(MOVE % [move_name, flow.step_points[index]])
		_move_label.text = SEPARATOR.join(texts)
		_move_seconds = TEXT_SECONDS
	if flow.perfect_landings != _perfects_seen:
		_perfects_seen = flow.perfect_landings
		_trick_label.text = PERFECT
		_landing_seconds = TEXT_SECONDS
	if flow.crashes != _crashes_seen:
		_crashes_seen = flow.crashes
		_trick_label.text = CRASH
		_landing_seconds = TEXT_SECONDS
	if flow.sabotages != _sabotages_seen:
		_sabotages_seen = flow.sabotages
		_trick_label.text = SABOTAGED
		_landing_seconds = TEXT_SECONDS
	if flow.combos_broken != _breaks_seen:
		_breaks_seen = flow.combos_broken
		_move_label.text = COMBO_BROKEN
		_move_seconds = TEXT_SECONDS
	if flow.tiers_crossed != _tiers_seen:
		_tiers_seen = flow.tiers_crossed
		_tier_label.text = TIER % flow.last_tier_crossed
		_tier_seconds = TEXT_SECONDS
		_flash_seconds = FLASH_SECONDS


## The name of the recipe drawn, while the trick button is held; otherwise the name of
## the trick of the jump under way, while there is one; otherwise what is left of the
## text of the last landing.
func _name_the_trick() -> void:
	var drawing: bool = motor != null and motor.is_drawing()
	var trick: AirTrick = null if motor == null else motor.current_trick()
	if drawing:
		var recipe: TrickRecipe = motor.drawn_recipe()
		_trick_label.text = UNREAD if recipe == null or recipe.context else recipe.name()
		_landing_seconds = 0.0
	elif trick != null:
		_trick_label.text = trick.name()
		_landing_seconds = 0.0
	_trick_label.visible = drawing or trick != null or _landing_seconds > 0.0


## One mark at the end of each tier along the gauge.
func _place_the_marks(count: int) -> void:
	if _gauge.get_child_count() == count:
		return
	for mark: Node in _gauge.get_children():
		_gauge.remove_child(mark)
		mark.queue_free()
	for index: int in count:
		var mark: ColorRect = ColorRect.new()
		mark.color = MARK_COLOR
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var at: float = float(index + 1) / count
		mark.anchor_left = at
		mark.anchor_right = at
		mark.anchor_bottom = 1.0
		mark.offset_left = -MARK_WIDTH / 2.0
		mark.offset_right = MARK_WIDTH / 2.0
		_gauge.add_child(mark)


## One pip per ammunition the runner may hold: filled for each one it holds, only
## outlined for the others.
func _fill_the_pips(count: int, held: int) -> void:
	if _ammo.get_child_count() != count:
		for pip: Node in _ammo.get_children():
			_ammo.remove_child(pip)
			pip.queue_free()
		for index: int in count:
			var pip: Panel = Panel.new()
			pip.custom_minimum_size = PIP_SIZE
			pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = PIP_COLOR
			style.border_color = PIP_COLOR
			style.set_border_width_all(2)
			style.set_corner_radius_all(9)
			pip.add_theme_stylebox_override("panel", style)
			_ammo.add_child(pip)
	for index: int in count:
		var pip: Panel = _ammo.get_child(index) as Panel
		var style: StyleBoxFlat = pip.get_theme_stylebox("panel") as StyleBoxFlat
		style.draw_center = index < held
