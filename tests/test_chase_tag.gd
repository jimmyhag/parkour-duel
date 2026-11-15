extends GutTest
## The gestures of the cat of a chase (docs/specs/chase-tag.md, game/core): the touch and
## the dive of its motor (Tag), the reach and the cone in which they catch, the dated
## message of a catch and the chase that reads it, played as the level plays them, on
## runners without a scene (MotorBody). The tuning is the fixed one of MotorBody, with the
## values of the spec. The distance between the cat and the mouse is the gap between
## their bodies (their capsules), as the reach of a gesture.

const STEPS_PER_SECOND: int = 60
const CAT: int = 0
const MOUSE: int = 1
const RUNNING: ChaseState.Phase = ChaseState.Phase.RUNNING
const ROUND_OVER: ChaseState.Phase = ChaseState.Phase.ROUND_OVER
## The values of the spec in fixed steps at 60 per second, written out on purpose: a touch
## reaches 0.25 s and costs 0.35 s; a dive lasts 0.4 s and costs 0.9 s down.
const TOUCH_STEPS: int = 15
const TOUCH_RECOVERY_STEPS: int = 21
const DIVE_STEPS: int = 24
const DOWN_STEPS: int = 54
## The share of its top speed a cat runs at most after a touch missed.
const RECOVERY_SPEED_SHARE: float = 0.6
## Steps played after a gesture, well past its end and its recovery.
const LONG_ENOUGH: int = 120
const NEAR: float = 0.001

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_contact_alone_catches_no_more() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	# The bodies overlap by 0.4 m.
	var mouse: MotorBody = _mouse(-0.4, 0.0)

	for step: int in 10:
		_play(chase, cat, _run(), mouse, _stand(), step + 1)

	assert_eq(chase.phase, RUNNING, "the round goes on")
	assert_null(cat.motor.tag, "the cat made no gesture")


func test_a_touch_in_reach_catches() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	var mouse: MotorBody = _mouse(0.8, _tuning.top_speed)

	_play(chase, cat, _run(true), mouse, _run(), 7)

	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner, CAT, "the cat wins it")
	assert_eq(chase.round_winner_role, ChaseState.Role.CAT, "as the cat")
	assert_eq(chase.end_step, 7, "dated by the message of the touch")
	assert_eq(cat.motor.tag.gesture, Tag.Gesture.TOUCH, "a touch")


func test_a_touch_out_of_reach_is_a_miss_that_slows_down() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	var mouse: MotorBody = _mouse(2.0, _tuning.top_speed)

	_play(chase, cat, _run(true), mouse, _run(), 1)
	var touch: Tag = cat.motor.tag
	assert_not_null(touch, "the cat touches")
	for step: int in TOUCH_STEPS - 1:
		_play(chase, cat, _run(), mouse, _run(), step + 2)
	assert_eq(chase.phase, RUNNING, "it does not catch the mouse")
	var slowest_cap: float = _tuning.top_speed * RECOVERY_SPEED_SHARE
	var fastest: float = 0.0
	var recovering: int = 0
	for step: int in TOUCH_RECOVERY_STEPS:
		# It asks again, at every step of the recovery: nothing starts.
		var again: MoveIntent = _run(step % 2 == 0, step % 2 == 1)
		_play(chase, cat, again, mouse, _run(), TOUCH_STEPS + step + 1)
		recovering += int(touch.phase == Tag.Phase.RECOVERING)
		fastest = maxf(fastest, cat.horizontal_speed())
		assert_same(cat.motor.tag, touch, "no new touch nor dive")
		assert_ne(cat.motor.state, RunnerMotor.State.DIVING, "no dive")
	assert_eq(recovering, TOUCH_RECOVERY_STEPS, "a recovery of 0.35 s")
	assert_lte(fastest, slowest_cap + NEAR, "at 60 % of its top speed at most")
	assert_gt(fastest, slowest_cap - NEAR * 100.0, "running at that pace")
	for step: int in LONG_ENOUGH:
		_play(chase, cat, _run(), mouse, _run(), TOUCH_STEPS + TOUCH_RECOVERY_STEPS + step + 1)
	assert_true(touch.is_over(), "then the touch is over")
	assert_almost_eq(cat.horizontal_speed(), _tuning.top_speed, NEAR, "and it runs again")
	assert_eq(chase.phase, RUNNING, "the round never ended")


func test_the_dive_catches_farther() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	var mouse: MotorBody = _mouse(1.4, _tuning.top_speed)
	var touch_reach: bool = Tag.reaches(
		_axis(cat), _axis(mouse), _radii(), Vector3.FORWARD, _tuning.tag_touch_reach, 60.0
	)
	assert_false(touch_reach, "beyond the reach of a touch")

	_play(chase, cat, _run(false, true), mouse, _run(), 9)

	assert_eq(cat.motor.state, RunnerMotor.State.DIVING, "the cat dives")
	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner, CAT, "the cat wins it")
	assert_eq(chase.end_step, 9, "dated by the message of the dive")
	assert_eq(cat.motor.tag.gesture, Tag.Gesture.DIVE, "a dive")


func test_a_missed_dive_leaves_the_cat_on_the_ground() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	var mouse: MotorBody = _mouse(4.0, _tuning.top_speed)

	_play(chase, cat, _run(false, true), mouse, _run(), 1)
	var diving: int = 1
	var highest: float = cat.position.y
	for step: int in DIVE_STEPS + DOWN_STEPS + LONG_ENOUGH:
		if cat.motor.state != RunnerMotor.State.DIVING:
			break
		_play(chase, cat, _run(), mouse, _run(), step + 2)
		highest = maxf(highest, cat.position.y)
		diving += int(cat.motor.state == RunnerMotor.State.DIVING)
	assert_eq(diving, DIVE_STEPS, "a dive of 0.4 s")
	assert_lte(highest, 0.4, "low: 0.4 m high at most")
	assert_eq(chase.phase, RUNNING, "it does not catch the mouse")
	assert_eq(cat.motor.state, RunnerMotor.State.DOWN, "it ends on the ground")
	var down_at: Vector3 = cat.position
	var down: int = 0
	while cat.motor.state == RunnerMotor.State.DOWN and down <= DOWN_STEPS:
		down += 1
		assert_almost_eq(cat.position.distance_to(down_at), 0.0, NEAR, "without moving")
		_play(chase, cat, _run(true, true), mouse, _run(), DIVE_STEPS + down + 1)
	assert_eq(down, DOWN_STEPS, "0.9 s")
	assert_eq(cat.motor.state, RunnerMotor.State.GROUNDED, "then it gets up")
	for step: int in LONG_ENOUGH:
		_play(chase, cat, _run(), mouse, _run(), DIVE_STEPS + DOWN_STEPS + step + 2)
	assert_almost_eq(cat.horizontal_speed(), _tuning.top_speed, NEAR, "and runs again")


func test_the_dive_asks_for_momentum() -> void:
	var walking: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, 2.0)
	walking.motor.can_tag = true
	var walk: MoveIntent = _run(false, true)
	walk.direction = Vector3.FORWARD * 2.0 / _tuning.top_speed
	walking.step(walk)
	assert_ne(walking.motor.state, RunnerMotor.State.DIVING, "at 2 m/s, no dive")
	assert_null(walking.motor.tag, "nor any gesture")

	var flying: MotorBody = MotorBody.new(_tuning, 2.0)
	flying.motor.can_tag = true
	flying.velocity = Vector3.FORWARD * _tuning.top_speed
	flying.step(_run(false, true))
	assert_eq(flying.motor.state, RunnerMotor.State.FALLING, "in the air, no dive")
	assert_null(flying.motor.tag, "nor any gesture")


func test_a_gesture_only_works_in_its_cone() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	# 0.8 m aside of the cat, at 90 degrees from its run, running along with it.
	var mouse: MotorBody = _mouse(-_radii(), _tuning.top_speed)
	mouse.position.x = 0.8 + _radii()

	for step: int in TOUCH_STEPS:
		_play(chase, cat, _run(step == 0), mouse, _run(), step + 1)

	assert_eq(cat.motor.tag.gesture, Tag.Gesture.TOUCH, "the cat touched")
	assert_eq(chase.phase, RUNNING, "it does not catch the mouse")
	var ahead: bool = Tag.reaches(_axis(cat), _axis(mouse), _radii(), Vector3.RIGHT, 1.0, 60.0)
	assert_true(ahead, "it would, facing it")


func test_the_mouse_has_no_gesture() -> void:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	var mouse: MotorBody = _mouse(0.8, _tuning.top_speed)
	assert_false(mouse.motor.can_tag, "the mouse may not tag")

	for step: int in 10:
		_play(chase, cat, _stand(), mouse, _run(step % 2 == 0, step % 2 == 1), step + 1)

	assert_null(mouse.motor.tag, "nothing happens: no touch, no dive")
	assert_eq(mouse.motor.state, RunnerMotor.State.GROUNDED, "it runs on")
	assert_almost_eq(mouse.horizontal_speed(), _tuning.top_speed, NEAR, "at its top speed")
	chase.receive(ChaseMessage.catch(20, MOUSE, Tag.Gesture.TOUCH))
	assert_eq(chase.phase, RUNNING, "a catch the mouse would claim counts for nothing")


## A chase whose first round is on, player 0 the cat.
func _running_chase() -> ChaseState:
	var chase: ChaseState = ChaseState.new(_tuning, STEPS_PER_SECOND)
	chase.receive(ChaseMessage.start(0))
	return chase


## The cat, at the origin, running along -Z at `speed`, allowed to tag.
func _cat(speed: float) -> MotorBody:
	var cat: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, speed)
	cat.position = Vector3.ZERO
	cat.motor.can_tag = true
	return cat


## The mouse, its body `ahead` m ahead of the body of the cat along -Z, running along -Z at
## `speed`.
func _mouse(ahead: float, speed: float) -> MotorBody:
	var mouse: MotorBody = MotorBody.running(_tuning, Vector3.FORWARD, speed)
	mouse.position = Vector3.FORWARD * (ahead + _radii())
	return mouse


## The radii of the two capsules together.
func _radii() -> float:
	return 2.0 * _tuning.capsule_radius


## One fixed step of the chase as its level plays it, dated `step`: both runners step,
## then, if a gesture of the cat reaches the mouse in its cone, facing the way it runs, the
## chase gets a dated message of the catch.
func _play(
	chase: ChaseState,
	cat: MotorBody,
	cat_intent: MoveIntent,
	mouse: MotorBody,
	mouse_intent: MoveIntent,
	step: int
) -> void:
	cat.step(cat_intent)
	mouse.step(mouse_intent)
	var facing: Vector3 = Vector3(cat.velocity.x, 0.0, cat.velocity.z)
	if facing.length() < RunnerMotor.ALMOST_STILL:
		facing = Vector3.FORWARD
	if Tag.catches(cat.motor, _axis(cat), _axis(mouse), _radii(), facing.normalized()):
		chase.receive(ChaseMessage.catch(step, chase.cat, cat.motor.tag.gesture))


## The lowest and the highest points of the axis of the capsule of `body`.
func _axis(body: MotorBody) -> PackedVector3Array:
	var radius: float = _tuning.capsule_radius
	var top: float = _tuning.capsule_height - radius
	return PackedVector3Array(
		[body.position + Vector3.UP * radius, body.position + Vector3.UP * top]
	)


## Running along -Z at full push; the touch or the dive pressed at this step, or not.
func _run(touch: bool = false, dive: bool = false) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = Vector3.FORWARD
	intent.touch_pressed = touch
	intent.dive_pressed = dive
	return intent


func _stand() -> MoveIntent:
	return MoveIntent.new()
