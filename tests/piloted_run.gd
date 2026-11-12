class_name PilotedRun
extends RefCounted
## One run led by the test pilot (tests/pilot_intent_source.gd), in the real physics:
## a runner is led, once it stands on the floor, straight towards a goal. A test calls
## observe_step() after every fixed step until the run is over (see ReplayTest), then
## reads here how it ended and what the runner did while the pilot was leading it.

## REACHED: the runner entered the goal, then came to rest on the floor.
## FELL: the runner went lower than every block of its course.
## OUT_OF_STEPS: the step budget ran out before either happened.
enum Outcome { REACHED, FELL, OUT_OF_STEPS }

## A run may last this many times the time its distance takes at top speed.
const BUDGET_MARGIN: int = 3

var is_over: bool = false
var outcome: Outcome = Outcome.OUT_OF_STEPS
## The runner entered the goal, whatever happened next.
var goal_reached: bool = false
## Jumps the pilot asked for: every step at which it pressed the jump.
var jumps: int = 0
## Steps the runner spent off the floor while the pilot was leading it.
var steps_in_the_air: int = 0

var _runner: Player
var _to_goal: Vector3
var _steps: int = 0
var _budget: int
var _under_the_blocks: float
var _pilot_leads: bool = false


## `runner` must already be where the run starts, with the tuning it will obey: the
## step budget comes from its distance to `goal` and its top speed, with a wide margin.
## `course` holds the blocks the runner may fall under.
func _init(runner: Player, goal: Area3D, course: Node) -> void:
	_runner = runner
	_to_goal = goal.global_position - runner.global_position
	_to_goal.y = 0.0
	var seconds_at_top_speed: float = _to_goal.length() / runner.tuning.top_speed
	var steps_at_top_speed: int = ceili(
		seconds_at_top_speed / runner.get_physics_process_delta_time()
	)
	_budget = BUDGET_MARGIN * steps_at_top_speed
	_under_the_blocks = bounds_of_the_blocks(course).position.y
	goal.body_entered.connect(_on_goal_entered)
	runner.stepped.connect(_on_runner_stepped)
	runner.intent_source = IntentSource.new()


## The box that holds every block (static body) of `course`, in the world.
static func bounds_of_the_blocks(course: Node) -> AABB:
	var colliders: Array[CollisionShape3D] = []
	for block: Node in course.find_children("*", "StaticBody3D", true, false):
		for child: Node in block.get_children():
			if child is CollisionShape3D:
				colliders.append(child as CollisionShape3D)
	var bounds: AABB = AABB()
	for index: int in colliders.size():
		var collider: CollisionShape3D = colliders[index]
		var box: AABB = collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
		bounds = box if index == 0 else bounds.merge(box)
	return bounds


## To call after every fixed step, until the run is over.
func observe_step() -> void:
	if is_over:
		return
	_steps += 1
	if _runner.global_position.y < _under_the_blocks:
		_end(Outcome.FELL)
	elif goal_reached:
		_let_the_runner_stop()
	elif _pilot_leads:
		steps_in_the_air += int(not _runner.is_on_floor())
	elif _runner.is_on_floor():
		_runner.intent_source = PilotIntentSource.new(_runner, _to_goal)
		_pilot_leads = true
	if not is_over and _steps >= _budget:
		_end(Outcome.OUT_OF_STEPS)


## Past the goal the pilot lets go: the run is won once the runner stands still.
func _let_the_runner_stop() -> void:
	_release_the_runner()
	if _runner.is_on_floor() and _runner.velocity.is_zero_approx():
		_end(Outcome.REACHED)


func _release_the_runner() -> void:
	if _pilot_leads:
		_runner.intent_source = IntentSource.new()
		_pilot_leads = false


func _end(with: Outcome) -> void:
	_release_the_runner()
	outcome = with
	is_over = true


func _on_goal_entered(body: Node3D) -> void:
	if body == _runner:
		goal_reached = true


func _on_runner_stepped(intent: MoveIntent) -> void:
	if _pilot_leads and intent.jump_pressed:
		jumps += 1
