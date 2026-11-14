class_name DebugOverlay
extends Label
## The debug display, for tuning the feel: the runner's state, its horizontal and
## vertical speeds, and what is left of its coyote time, of its jump buffer, of its roll
## window, of the roll or the hard landing under way, of the mantle under way, of the
## wall run under way and of the time a jump is still a jump off a wall; then its flow:
## the gauge, the tier, the time left to chain a move, the repeated move and its count,
## the multiplier and the speed bonus; then its aim: whether it aims, the target under
## the reticle with its type, its state and how far it is, and the time left to the state
## of each target that is not ready. Hidden until its action shows it.

const TOGGLE_DEBUG: StringName = &"toggle_debug"
const LINES: Array[String] = [
	"STATE %s",
	"SPEED H %.2f m/s",
	"SPEED V %.2f m/s",
	"COYOTE %.2f s",
	"BUFFER %.2f s",
	"ROLL WINDOW %.2f s",
	"LANDING %.2f s",
	"MANTLE %.2f s",
	"WALL RUN %.2f s",
	"WALL JUMP %.2f s",
]
const FLOW_LINES: Array[String] = [
	"GAUGE %d",
	"TIER %d",
	"CHAIN %.2f s",
	"REPEAT %s",
	"MULTIPLIER x%d",
	"SPEED BONUS %d %%",
]
const REPEATED: String = "%s x%d"
const NO_REPEAT: String = "-"
const AIM_ON: String = "AIM ON"
const AIM_OFF: String = "AIM OFF"
const AIMED: String = "AIMED %d %s %s %.1f m"
const NOTHING_AIMED: String = "AIMED -"
const TARGET: String = "TARGET %d %s %s %.2f s"

## The runner to display, its flow, its weapon and the targets of its course.
var motor: RunnerMotor
var flow: FlowState
var shooter: Shooter
var targets: TargetBoard


func _process(_delta: float) -> void:
	if visible:
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_DEBUG):
		visible = not visible
		refresh()


## Writes the current state of the runner on screen.
func refresh() -> void:
	if motor == null:
		return
	var state: String = RunnerMotor.State.keys()[motor.state]
	var horizontal: float = Vector2(motor.velocity.x, motor.velocity.z).length()
	text = (
		"\n".join(LINES)
		% [
			state,
			horizontal,
			motor.velocity.y,
			motor.coyote_time_left(),
			motor.jump_buffer_left(),
			motor.roll_window_left(),
			motor.landing_time_left(),
			motor.mantle_time_left(),
			motor.wall_run_time_left(),
			motor.wall_jump_time_left(),
		]
	)
	if flow != null:
		text += "\n" + _flow_lines()
	if shooter != null and targets != null:
		text += "\n" + _aim_lines()


func _flow_lines() -> String:
	var repeated: String = NO_REPEAT
	if flow.repeat_count > 0:
		var move: String = RunnerEvent.Kind.keys()[flow.repeated_move]
		repeated = REPEATED % [move, flow.repeat_count]
	return (
		"\n".join(FLOW_LINES)
		% [
			floori(flow.gauge),
			flow.tier(),
			flow.chain_time_left(),
			repeated,
			flow.multiplier(),
			roundi(flow.speed_bonus() * 100.0),
		]
	)


func _aim_lines() -> String:
	var lines: Array[String] = [AIM_ON if shooter.aiming else AIM_OFF]
	var aimed: SabotageTarget = targets.target(shooter.aim.target)
	if aimed == null:
		lines.append(NOTHING_AIMED)
	else:
		lines.append(AIMED % [aimed.id, _kind(aimed), _state(aimed), shooter.aim.distance])
	for target: SabotageTarget in targets.targets.values():
		if not target.is_ready():
			lines.append(TARGET % [target.id, _kind(target), _state(target), target.time_left()])
	return "\n".join(lines)


func _kind(target: SabotageTarget) -> String:
	return SabotageTarget.Kind.keys()[target.kind]


func _state(target: SabotageTarget) -> String:
	return SabotageTarget.State.keys()[target.state]
