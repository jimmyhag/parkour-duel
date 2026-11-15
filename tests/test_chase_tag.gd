extends GutTest
## The gestures of the cat of a chase (docs/specs/chase-tag.md, game/core): the touch and
## the dive of its motor (Tag), the reach and the cone in which they catch, the dated
## message of a catch and the chase that reads it, played as the level plays them, on
## runners without a scene (MotorBody). The tuning is the fixed one of MotorBody, with the
## values of the spec; the tests of docs/specs/chase-tag-reach.md use the game's tuning, whose
## reaches are measured on the body. The distance between the cat and the mouse is the gap
## between their bodies (their capsules), as the reach of a gesture, the shortest during the
## step.

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
## The height of the block a cat dives off, in m.
const BLOCK_TOP: float = 2.0
## The tuning of the game, and how far under or beyond a reach the mouse is, in m: a little.
const GAME_TUNING: String = "res://game/core/movement_tuning.tres"
const A_LITTLE: float = 0.02
## How far from the run of the cat a mouse on its side is, in degrees: out of the cone of
## docs/specs/chase-tag.md (60), within the one of docs/specs/chase-tag-reach.md (120).
const ON_THE_SIDE: float = 50.0
## How much lower than the cat a mouse below it stands, and how far aside of the cat a mouse
## that passes beside it goes, in m.
const LOWER: float = 0.6
const BESIDE: float = 0.9

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
	var touch_reach: bool = TagReach.touch(_tuning).reaches(
		_axis(cat), _axis(mouse), _tuning.capsule_radius, Vector3.FORWARD
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


func test_a_dive_off_an_edge_falls() -> void:
	# A cat on a block 2 m high, its edge 1.5 m ahead: its dive leaves the block and falls,
	# instead of going on level over the void.
	var cat: MotorBody = MotorBody.new(_tuning, BLOCK_TOP)
	cat.has_ledge = true
	cat.ledge_face = 0.5
	cat.ledge_top = BLOCK_TOP
	cat.ledge_depth = 2.0
	cat.on_floor = true
	cat.motor.can_tag = true
	cat.velocity = Vector3.FORWARD * _tuning.top_speed
	cat.step(_run())
	assert_true(cat.on_floor, "the cat runs on the block")

	cat.step(_run(false, true))
	assert_eq(cat.motor.state, RunnerMotor.State.DIVING, "it dives")
	var highest: float = cat.position.y
	for step: int in DIVE_STEPS - 1:
		cat.step(_run())
		highest = maxf(highest, cat.position.y)
	assert_lte(highest, BLOCK_TOP + 0.4, "low, as any dive")
	assert_lt(cat.position.z, -1.5, "past the edge")
	assert_lt(cat.position.y, BLOCK_TOP - 1.0, "falling, not level over the void")
	for step: int in DOWN_STEPS + LONG_ENOUGH:
		cat.step(_run())
	assert_almost_eq(cat.position.y, 0.0, NEAR, "down on the floor under the block")
	assert_eq(cat.motor.state, RunnerMotor.State.GROUNDED, "then up again")


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
	var touch: TagReach = TagReach.touch(_tuning)
	var ahead: bool = touch.reaches(_axis(cat), _axis(mouse), _tuning.capsule_radius, Vector3.RIGHT)
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


func test_a_fingertip_touch_catches() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	var mouse: MotorBody = _mouse(_tuning.tag_touch_reach - A_LITTLE, 0.0)

	for step: int in TOUCH_STEPS:
		_play(chase, cat, _touch(step == 0), mouse, _stand(), step + 1)

	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner_role, ChaseState.Role.CAT, "the cat wins it")
	assert_eq(cat.motor.tag.gesture, Tag.Gesture.TOUCH, "with a touch")


func test_a_touch_just_out_of_reach_misses() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	var mouse: MotorBody = _mouse(_tuning.tag_touch_reach + A_LITTLE, 0.0)

	_play(chase, cat, _touch(true), mouse, _stand(), 1)
	var touch: Tag = cat.motor.tag
	for step: int in TOUCH_STEPS:
		_play(chase, cat, _touch(true), mouse, _stand(), step + 2)

	assert_eq(chase.phase, RUNNING, "the round goes on")
	assert_same(cat.motor.tag, touch, "the touch asked for again starts nothing")
	assert_eq(touch.phase, Tag.Phase.RECOVERING, "the cat pays the miss")


func test_a_fingertip_dive_catches() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	# The mouse flees as fast as the cat dives: their bodies stay as far apart all along.
	var mouse: MotorBody = _mouse(_tuning.tag_dive_reach - A_LITTLE, 0.0)

	for step: int in DIVE_STEPS:
		var moved: Vector3 = _play_beside(chase, cat, _run(false, step == 0), mouse, step + 1)
		mouse.position += moved
		if chase.phase != RUNNING:
			break

	assert_eq(cat.motor.tag.gesture, Tag.Gesture.DIVE, "the cat dived")
	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner_role, ChaseState.Role.CAT, "the cat wins it")


func test_two_runners_crossing_do_not_miss_each_other() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	# The mouse crosses in front of the cat, at its top speed, along +X: at the closest, its
	# body is just within the reach of a touch; at the start and at the end of the step it
	# crosses, a half step aside, it is just beyond.
	var stride: float = _tuning.top_speed * MotorBody.STEP
	var mouse: MotorBody = MotorBody.running(_tuning, Vector3.RIGHT, _tuning.top_speed)
	var closest: float = _tuning.tag_touch_reach + _radii() - 0.001
	mouse.position = Vector3(-1.5 * stride, 0.0, -closest)
	_play(chase, cat, _touch(true), mouse, _run_along(Vector3.RIGHT), 1)
	assert_eq(chase.phase, RUNNING, "not yet in reach")
	assert_almost_eq(mouse.position.x, -stride / 2.0, NEAR, "half a step before the closest")
	assert_false(_in_touch_reach(cat, _axis(mouse)), "out of reach at the start of the step")

	_play(chase, cat, _touch(), mouse, _run_along(Vector3.RIGHT), 2)

	assert_almost_eq(mouse.position.x, stride / 2.0, NEAR, "half a step past the closest")
	assert_false(_in_touch_reach(cat, _axis(mouse)), "out of reach at its end")
	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner_role, ChaseState.Role.CAT, "the cat wins it")


func test_the_arm_reaches_for_a_mouse_on_the_side() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(_tuning.top_speed)
	# The mouse runs along with the cat, on its side, its body within the reach of a touch.
	var side: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, -deg_to_rad(ON_THE_SIDE))
	var mouse: MotorBody = _mouse(-_radii(), 0.0)
	mouse.position = side * (_tuning.tag_touch_reach - A_LITTLE + _radii())
	var touch: TagReach = TagReach.touch(_tuning)
	touch.cone = 60.0
	var narrow: bool = touch.reaches(
		_axis(cat), _axis(mouse), _tuning.capsule_radius, Vector3.FORWARD
	)
	assert_false(narrow, "out of a cone of 60 degrees")

	for step: int in TOUCH_STEPS:
		var moved: Vector3 = _play_beside(chase, cat, _run(step == 0), mouse, step + 1)
		mouse.position += moved
		if chase.phase != RUNNING:
			break

	assert_eq(cat.motor.tag.gesture, Tag.Gesture.TOUCH, "the cat touched, running straight")
	assert_eq(chase.phase, ROUND_OVER, "the round is over")
	assert_eq(chase.round_winner_role, ChaseState.Role.CAT, "the cat wins it")


func test_a_touch_catches_a_sliding_mouse_only_where_the_hand_reaches() -> void:
	# docs/specs/chase-tag-reach.md, decision 1: the arm reaches out from the shoulder, so a
	# mouse low on the ground is caught only where the fingertips come down to its body.
	_tuning = load(GAME_TUNING) as MovementTuning
	var low: PackedVector3Array = _low_axis(0.0, _tuning.slide_capsule_height)
	var farthest: float = _farthest_touched(low)
	assert_true(_touch_against(low, farthest - A_LITTLE), "the hand reaches it: caught")
	assert_false(_touch_against(low, farthest + A_LITTLE), "the hand stops short: missed")
	assert_lt(farthest + A_LITTLE - 2.0 * _radii(), _tuning.tag_touch_reach, "the bodies alone")


func test_a_touch_catches_a_lower_mouse_only_where_the_hand_reaches() -> void:
	_tuning = load(GAME_TUNING) as MovementTuning
	var low: PackedVector3Array = _low_axis(-LOWER, _tuning.capsule_height)
	var farthest: float = _farthest_touched(low)
	assert_true(_touch_against(low, farthest - A_LITTLE), "the hand reaches it: caught")
	assert_false(_touch_against(low, farthest + A_LITTLE), "the hand stops short: missed")
	assert_lt(farthest + A_LITTLE - 2.0 * _radii(), _tuning.tag_touch_reach, "the bodies alone")


func test_a_dive_catches_a_sliding_mouse_only_where_the_fingertips_reach() -> void:
	# The fingertips of a dive go out at their height: a mouse lower than them is caught only
	# where they come down to its body.
	_tuning = load(GAME_TUNING) as MovementTuning
	var low: PackedVector3Array = _low_axis(0.0, _tuning.slide_capsule_height)
	var up: float = _tuning.tag_dive_fingertips_height - low[1].y
	var across: float = sqrt(_tuning.capsule_radius ** 2 - up ** 2)
	var farthest: float = _tuning.capsule_radius + _tuning.tag_dive_reach + across
	for apart: float in [farthest - A_LITTLE, farthest + A_LITTLE]:
		var chase: ChaseState = _running_chase()
		var cat: MotorBody = _cat(_tuning.top_speed)
		var mouse: PackedVector3Array = low.duplicate()
		for index: int in mouse.size():
			mouse[index] += Vector3.FORWARD * apart
		# The mouse slides away as fast as the cat dives: as far apart all along.
		for step: int in DIVE_STEPS:
			var cat_from: PackedVector3Array = _axis(cat)
			var start: Vector3 = cat.position
			cat.step(_run(false, step == 0))
			var moved: Vector3 = Vector3(cat.position.x - start.x, 0.0, cat.position.z - start.z)
			var mouse_to: PackedVector3Array = [mouse[0] + moved, mouse[1] + moved]
			_observe(chase, cat, cat_from, mouse, mouse_to, step + 1)
			mouse = mouse_to
		var caught: bool = chase.phase == ROUND_OVER
		assert_eq(caught, apart < farthest, "%.2f m apart: caught or not" % apart)
	assert_lt(farthest + A_LITTLE - 2.0 * _radii(), _tuning.tag_dive_reach, "the bodies alone")


func test_a_mouse_passing_beside_is_caught_at_the_edge_of_the_cone() -> void:
	# The mouse passes beside the cat, the way the cat faces, in one step: at its nearest it
	# is square to the cat, out of the cone; at both ends of the step, out of reach; it is in
	# the cone and in reach only around its edge.
	_tuning = load(GAME_TUNING) as MovementTuning
	var reach: TagReach = TagReach.touch(_tuning)
	var cat: PackedVector3Array = _axis(_cat(0.0))
	var mouse: Array[PackedVector3Array] = [
		_axis_at(Vector3(BESIDE, 0.0, BESIDE)), _axis_at(Vector3(BESIDE, 0.0, -BESIDE))
	]
	var radius: float = _tuning.capsule_radius
	var nearest: PackedVector3Array = _axis_at(Vector3(BESIDE, 0.0, 0.0))
	assert_false(reach.reaches(cat, nearest, radius, Vector3.FORWARD), "square: out of the cone")
	assert_false(reach.reaches(cat, mouse[0], radius, Vector3.FORWARD), "out of reach as it starts")
	assert_false(reach.reaches(cat, mouse[1], radius, Vector3.FORWARD), "and as it ends")
	var edge: float = -BESIDE / tan(deg_to_rad(_tuning.tag_touch_cone) / 2.0)
	var at_the_edge: PackedVector3Array = _axis_at(Vector3(BESIDE, 0.0, edge))
	assert_true(reach.reaches(cat, at_the_edge, radius, Vector3.FORWARD), "at the edge: in reach")

	var caught: bool = reach.reaches_during([cat, cat], mouse, radius, Vector3.FORWARD)

	assert_true(caught, "caught during the step")


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
## then, if a gesture of the cat reaches the mouse in its cone during the step, facing the
## way it runs, the chase gets a dated message of the catch.
func _play(
	chase: ChaseState,
	cat: MotorBody,
	cat_intent: MoveIntent,
	mouse: MotorBody,
	mouse_intent: MoveIntent,
	step: int
) -> void:
	var mouse_from: PackedVector3Array = _axis(mouse)
	var cat_from: PackedVector3Array = _axis(cat)
	cat.step(cat_intent)
	mouse.step(mouse_intent)
	_observe(chase, cat, cat_from, mouse_from, _axis(mouse), step)


## One fixed step of the chase in which the mouse, moved by the test, goes as the cat does:
## the cat steps, the mouse goes the same way as far, then the chase observes the step as
## its level does (_play). Returns how far the cat went.
func _play_beside(
	chase: ChaseState, cat: MotorBody, cat_intent: MoveIntent, mouse: MotorBody, step: int
) -> Vector3:
	var mouse_from: PackedVector3Array = _axis(mouse)
	var cat_from: PackedVector3Array = _axis(cat)
	var start: Vector3 = cat.position
	cat.step(cat_intent)
	var moved: Vector3 = cat.position - start
	var mouse_to: PackedVector3Array = [mouse_from[0] + moved, mouse_from[1] + moved]
	_observe(chase, cat, cat_from, mouse_from, mouse_to, step)
	return moved


## The level observes the step `step` just played: the cat went from the axis `cat_from` to
## where it is, the mouse from `mouse_from` to `mouse_to`.
func _observe(
	chase: ChaseState,
	cat: MotorBody,
	cat_from: PackedVector3Array,
	mouse_from: PackedVector3Array,
	mouse_to: PackedVector3Array,
	step: int
) -> void:
	var facing: Vector3 = Vector3(cat.velocity.x, 0.0, cat.velocity.z)
	if facing.length() < RunnerMotor.ALMOST_STILL:
		facing = Vector3.FORWARD
	var cat_axes: Array[PackedVector3Array] = [cat_from, _axis(cat)]
	var mouse_axes: Array[PackedVector3Array] = [mouse_from, mouse_to]
	var radius: float = _tuning.capsule_radius
	if Tag.catches(cat.motor, cat_axes, mouse_axes, radius, facing.normalized()):
		chase.receive(ChaseMessage.catch(step, chase.cat, cat.motor.tag.gesture))


## Whether the mouse, its capsule of axis `mouse_axis`, is within the reach of a touch of
## `cat` and its cone at this instant, the cat facing -Z.
func _in_touch_reach(cat: MotorBody, mouse_axis: PackedVector3Array) -> bool:
	var touch: TagReach = TagReach.touch(_tuning)
	return touch.reaches(_axis(cat), mouse_axis, _tuning.capsule_radius, Vector3.FORWARD)


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


## Standing; the touch pressed at this step, or not.
func _touch(pressed: bool = false) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.touch_pressed = pressed
	return intent


## Running along `way` at full push.
func _run_along(way: Vector3) -> MoveIntent:
	var intent: MoveIntent = MoveIntent.new()
	intent.direction = way
	return intent


## The axis of the capsule of a runner of the tuning standing at `feet`.
func _axis_at(feet: Vector3) -> PackedVector3Array:
	var radius: float = _tuning.capsule_radius
	var top: float = _tuning.capsule_height - radius
	return PackedVector3Array([feet + Vector3.UP * radius, feet + Vector3.UP * top])


## The axis of the capsule, `height` m high, of a mouse whose feet are `below` m above the feet
## of the cat, on its axis.
func _low_axis(below: float, height: float) -> PackedVector3Array:
	var radius: float = _tuning.capsule_radius
	return PackedVector3Array(
		[Vector3.UP * (below + radius), Vector3.UP * (below + height - radius)]
	)


## How far ahead of the cat, axis to axis, the mouse whose axis is `low` (on the cat's axis)
## can be for its body to be within the arm of the shoulder of a touch, measured on the body.
func _farthest_touched(low: PackedVector3Array) -> float:
	var shoulder: float = _tuning.tag_touch_shoulder_height
	var up: float = maxf(maxf(low[0].y - shoulder, shoulder - low[1].y), 0.0)
	var offset: float = _tuning.tag_touch_shoulder_offset
	var arm: float = _tuning.capsule_radius + _tuning.tag_touch_reach - offset
	return offset + sqrt((_tuning.capsule_radius + arm) ** 2 - up ** 2)


## Whether the touch of a cat standing still catches the mouse whose axis is `low`, moved
## `apart` m ahead of the cat, standing still too.
func _touch_against(low: PackedVector3Array, apart: float) -> bool:
	var chase: ChaseState = _running_chase()
	var cat: MotorBody = _cat(0.0)
	var mouse: PackedVector3Array = low.duplicate()
	for index: int in mouse.size():
		mouse[index] += Vector3.FORWARD * apart
	for step: int in TOUCH_STEPS:
		var cat_from: PackedVector3Array = _axis(cat)
		cat.step(_touch(step == 0))
		_observe(chase, cat, cat_from, mouse, mouse, step + 1)
	return chase.phase == ROUND_OVER
