extends TrickTest
## The risk of the aerial tricks of the runner's motor (game/core): how long a trick lasts
## against the height of a jump, so that only a single fits in a jump on the flat; what a
## riskless loop on the flat earns; and the perfect landings that do not raise the speed
## without end. The tests of the risk weigh the tuning of the project, the one the player
## plays with.

## Fixed steps in one minute.
const MINUTE: int = 3600
const PERFECT_LANDINGS: int = 10
## The most style a minute of riskless tricks on the flat may earn: proposed from the
## measure of decision 15 of docs/specs/trick-gestures.md (156 200 with the tuning of
## 2026-11-14), a guard against more, not yet a small number.
const RISKLESS_STYLE_PER_MINUTE: int = 160000


## What a minute of jumps earned.
class Minute:
	var style: int = 0
	var tricks_paid: int = 0
	var crashes: int = 0
	var jumps: int = 0
	var ammo: int = 0
	var top_speed: float = 0.0
	var mean_speed: float = 0.0


# --- Durations ---


func test_a_single_fits_in_a_jump_on_the_flat() -> void:
	var tuning: MovementTuning = _project_tuning()
	var singles: Array[TrickRecipe] = [
		_front_flip(),
		_backflip(),
		TrickRecipe.drawn(SIDE_FLIP),
		TrickRecipe.drawn(SPIN),
		TrickRecipe.of_the_context(),
	]
	for recipe: TrickRecipe in singles:
		var context: String = recipe.name()
		var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)

		var events: Array[RunnerEvent] = _hop(body, null, recipe, 1)

		_assert_events(events, [TRICK])
		if events.size() == 1 and events[0].trick != null:
			assert_true(events[0].trick.perfect, context + ": finished before the ground, posed")


func test_a_double_does_not_fit_in_a_jump_on_the_flat() -> void:
	var tuning: MovementTuning = _project_tuning()
	for recipe: TrickRecipe in [_backflip(2), TrickRecipe.drawn(FRONT_FLIP, 2)]:
		var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)

		# Released with the jump itself, the earliest it can be, and posed.
		var events: Array[RunnerEvent] = _hop(body, null, recipe, 0)

		_assert_events(events, [CRASH])
		assert_eq(body.motor.state, RunnerMotor.State.HARD_LANDING, recipe.name())


func test_a_twist_makes_the_trick_longer() -> void:
	var plain: MotorBody = _high()
	var twisted: MotorBody = _high()
	plain.step(_release(_backflip()))
	twisted.step(_release(_backflip(1, 1)))
	var plain_trick: AirTrick = plain.motor.current_trick()
	var twisted_trick: AirTrick = twisted.motor.current_trick()

	for step: int in 2 * TURN_STEPS:
		plain.step(_push(Vector3.ZERO))
		twisted.step(_push(Vector3.ZERO))

	assert_true(plain_trick.finished and twisted_trick.finished, "both are over")
	assert_eq(plain_trick.finished_at - 1, TURN_STEPS, "a turn")
	var later: int = twisted_trick.finished_at - plain_trick.finished_at
	assert_eq(later, TWIST_STEPS, "the twisted one ends a twist later")


# --- The loop without risk ---


func test_a_riskless_loop_on_the_flat_earns_little() -> void:
	var tuning: MovementTuning = _project_tuning()
	var plain: Minute = _hop_for_a_minute(tuning, [])
	# Every recipe that fits in a jump on the flat, released at the first step in the air,
	# one after the other: the most varied loop.
	var fitting: Array[TrickRecipe] = [
		_front_flip(),
		_backflip(),
		TrickRecipe.drawn(SIDE_FLIP),
		TrickRecipe.drawn(SPIN),
		_backflip(1, 1),
		TrickRecipe.drawn(FRONT_FLIP, 1, 1),
	]
	var tricking: Minute = _hop_for_a_minute(tuning, fitting)
	gut.p(_report("running and jumping alone", plain))
	gut.p(_report("a trick at every jump", tricking))

	assert_gt(tricking.tricks_paid, 60, "a runner that poses a trick at every jump")
	assert_eq(tricking.crashes, 0, "and never crashes")
	assert_lt(tricking.style, RISKLESS_STYLE_PER_MINUTE, "earns less style than the threshold")


func test_perfect_landings_in_a_row_do_not_raise_the_speed_without_end() -> void:
	var flow: FlowState = _flow()
	var body: MotorBody = MotorBody.running(_tuning, FORWARD, _tuning.top_speed)
	var gain: float = _tuning.trick_perfect_speed_gain
	var perfect: int = 0
	var fastest: float = 0.0

	# Jump after jump on the flat, a different single with each jump, posed perfect.
	var singles: Array[TrickRecipe] = [_front_flip(), _backflip(), TrickRecipe.drawn(SPIN)]
	for landing: int in PERFECT_LANDINGS:
		var top: float = body.motor.top_speed()
		var events: Array[RunnerEvent] = _hop(body, flow, singles[landing % singles.size()], 1)
		for event: RunnerEvent in events:
			perfect += int(event.trick != null and event.trick.perfect)
		fastest = maxf(fastest, body.horizontal_speed())
		var limit: float = maxf(top, body.motor.top_speed()) + gain + TOLERANCE
		assert_lte(
			body.horizontal_speed(),
			limit,
			"landing %d: within the top speed and the gain" % landing
		)

	assert_eq(perfect, PERFECT_LANDINGS, "ten perfect landings")
	assert_gt(fastest, _tuning.top_speed, "the gain is felt")
	assert_lt(fastest, _tuning.max_horizontal_speed - 5.0, "far from the absolute cap")


## From the ground, a held jump on the flat, `recipe` released `release_after` steps after
## the take-off (0: with the jump), the slide pressed two steps before the ground: what
## the motor announced at the landing.
func _hop(
	body: MotorBody, flow: FlowState, recipe: TrickRecipe, release_after: int
) -> Array[RunnerEvent]:
	var landing: int = _steps_to_land(body.motor.tuning)
	for step: int in landing + 1:
		var intent: MoveIntent = _push(FORWARD)
		if step == release_after:
			intent = _release(recipe, FORWARD)
		intent.jump_pressed = step == 0
		intent.jump_held = step == 0 or body.motor.state == RunnerMotor.State.RISING
		intent.slide_pressed = step == landing - 2
		_play(body, flow, intent)
	return body.motor.events.duplicate()


## How many steps after it jumps on the flat at the top speed, holding the jump, a runner
## of `tuning` sees the floor again.
func _steps_to_land(tuning: MovementTuning) -> int:
	var copy: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var intent: MoveIntent = _push(FORWARD)
	intent.jump_pressed = true
	intent.jump_held = true
	copy.step(intent)
	var steps: int = 0
	while not copy.on_floor and steps < MANY_STEPS:
		steps += 1
		var flight: MoveIntent = _push(FORWARD)
		flight.jump_held = copy.motor.state == RunnerMotor.State.RISING
		copy.step(flight)
	return steps + 1


## A minute of a runner on the flat that jumps whenever it stands, holding the jump to
## its top; with `recipes`, it releases the next of them at the first step of every jump,
## and poses it perfect.
func _hop_for_a_minute(tuning: MovementTuning, recipes: Array[TrickRecipe]) -> Minute:
	var body: MotorBody = MotorBody.running(tuning, FORWARD, tuning.top_speed)
	var flow: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	var minute: Minute = Minute.new()
	var since_take_off: int = -1
	var speeds: float = 0.0
	var ammo_before: int = 0
	for step: int in MINUTE:
		var intent: MoveIntent = _push(FORWARD)
		var state: RunnerMotor.State = body.motor.state
		if state == RunnerMotor.State.GROUNDED:
			intent.jump_pressed = true
			intent.jump_held = true
			since_take_off = 0
		else:
			intent.jump_held = state == RunnerMotor.State.RISING
			since_take_off += 1
		if not recipes.is_empty() and since_take_off == 1:
			intent = _release(recipes[minute.jumps % recipes.size()], FORWARD)
			intent.jump_held = true
		var ground_soon: bool = body.position.y + 2.0 * body.velocity.y * MotorBody.STEP <= 0.0
		intent.slide_pressed = body.velocity.y < 0.0 and ground_soon
		_follow(body, flow, intent)
		speeds += body.horizontal_speed()
		minute.top_speed = maxf(minute.top_speed, body.horizontal_speed())
		minute.ammo += maxi(flow.ammo - ammo_before, 0)
		ammo_before = flow.ammo
		for event: RunnerEvent in body.motor.events:
			minute.tricks_paid += int(event.kind == TRICK)
			minute.crashes += int(event.kind == CRASH)
			minute.jumps += int(event.kind == RunnerEvent.Kind.JUMP)
	minute.style = flow.style_score
	minute.mean_speed = speeds / MINUTE
	return minute


func _report(title: String, minute: Minute) -> String:
	return (
		"%s: style %d, ammunition %d, jumps %d, tricks %d, crashes %d, speed %.2f m/s (top %.2f)"
		% [
			title,
			minute.style,
			minute.ammo,
			minute.jumps,
			minute.tricks_paid,
			minute.crashes,
			minute.mean_speed,
			minute.top_speed
		]
	)
