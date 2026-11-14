class_name DebugOverlay
extends Label
## The debug display, for tuning the feel: the runner's state, its horizontal and
## vertical speeds, and what is left of its coyote time, of its jump buffer, of its roll
## window, of the roll or the hard landing under way, of the mantle under way, of the
## wall run under way and of the time a jump is still a jump off a wall; then its flow:
## the gauge, the tier, the time left to chain a move, the repeated move and its count,
## the multiplier and the speed bonus. Hidden until its action shows it.

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

## The runner to display, and its flow.
var motor: RunnerMotor
var flow: FlowState


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
	if flow == null:
		return
	var repeated: String = NO_REPEAT
	if flow.repeat_count > 0:
		var move: String = RunnerEvent.Kind.keys()[flow.repeated_move]
		repeated = REPEATED % [move, flow.repeat_count]
	text += (
		"\n"
		+ (
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
	)
