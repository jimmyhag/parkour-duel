class_name DebugOverlay
extends Label
## The debug display, for tuning the feel: the runner's state, its horizontal and
## vertical speeds, and what is left of its coyote time and of its jump buffer. Hidden
## until its action shows it.

const TOGGLE_DEBUG: StringName = &"toggle_debug"
const LINES: String = "STATE %s\nSPEED H %.2f m/s\nSPEED V %.2f m/s\nCOYOTE %.2f s\nBUFFER %.2f s"

## The runner to display.
var motor: RunnerMotor


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
		LINES
		% [state, horizontal, motor.velocity.y, motor.coyote_time_left(), motor.jump_buffer_left()]
	)
