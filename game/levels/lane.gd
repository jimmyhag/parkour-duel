class_name Lane
extends Node3D
## One lane of the course, and the place where the layers meet for it: it owns the state
## of its run, the flow of its runner, its weapon and its targets (game/core), listens to
## its lines and its checkpoints (game/world), brings its runner (game/player) back when
## the rule of game/core says so, gives the flow what the runner's motor announced and the
## motor the speed bonus of the flow, gives its targets the runner in their zones and the
## weapon what the runner aims at, and lets its target blocks (game/world) show what their
## targets say. It reads no input and decides nothing: it executes. The solo course is one
## lane; a duel puts two side by side. A lane without a runner (the ghost's) only plays the
## steps of its targets.
## Expected children: StartLine, FinishLine, Checkpoints (one Checkpoint per section,
## numbered from 0), Targets (one TargetBlock per target), and its runner, Player, if any.

## The runner reached a checkpoint farther than any before.
signal checkpoint_reached(index: int)
## The run was restarted from the start.
signal restarted
## The runner crossed the finish line.
signal finished

## The altitude under which a runner has fallen off the course.
@export var fall_limit: float = 0.0
## The tuning of a lane without a runner; a runner brings its own.
@export var tuning: MovementTuning

## The runner of the lane, as a player of a duel (0 or 1): who its shots come from, who
## its targets hit, and the lane of its targets. To set before the lane enters the tree.
var runner_id: int = 0
var race: RaceState
var flow: FlowState
var targets: TargetBoard
var shooter: Shooter
## Where the shots of its runner go: its own targets, or the opposing lane's in a duel.
var shot_board: TargetBoard
## The weapon whose aim sets off the targets of this lane that it could hit: its own
## runner's in solo, the player's on the opposing lane in a duel, none for nobody's.
var focus_from: Shooter
## The runner, if the lane has one.
var player: Player
## Fixed steps per second of game time, whatever the speed of the engine's clock.
var steps_per_second: int
## The start line starts the race; in a duel, GO does.
var started_by_its_line: bool = true

var _checkpoints: Dictionary[int, Checkpoint] = {}
var _blocks: Array[TargetBlock] = []

@onready var _start_line: RaceLine = $StartLine as RaceLine
@onready var _finish_line: RaceLine = $FinishLine as RaceLine


func _ready() -> void:
	steps_per_second = roundi(Engine.physics_ticks_per_second / Engine.time_scale)
	player = get_node_or_null("Player") as Player
	if player != null:
		tuning = player.tuning
	race = RaceState.new(steps_per_second)
	flow = FlowState.new(tuning, steps_per_second)
	targets = TargetBoard.new()
	targets.lane = runner_id
	shooter = Shooter.new(runner_id, tuning, steps_per_second)
	shot_board = targets
	focus_from = shooter
	for child: Node in $Checkpoints.get_children():
		var checkpoint: Checkpoint = child as Checkpoint
		_checkpoints[checkpoint.index] = checkpoint
		checkpoint.reached.connect(_on_checkpoint_reached)
	for child: Node in $Targets.get_children():
		var block: TargetBlock = child as TargetBlock
		block.target = SabotageTarget.new(block.target_id, block.kind, tuning, steps_per_second)
		block.lane = runner_id
		targets.add(block.target)
		_blocks.append(block)
	_start_line.crossed.connect(_on_start_line_crossed)
	_finish_line.crossed.connect(_on_finish_line_crossed)
	if player != null:
		player.stepped.connect(_on_player_stepped)
		respawn()


## Without a runner, the targets play their step all the same.
func _physics_process(_delta: float) -> void:
	if player == null:
		_step_the_targets()
		_show_the_targets()


## Brings the runner back to the last checkpoint reached, at rest. The timer is not
## touched.
func respawn() -> void:
	if player != null:
		player.teleport(_checkpoints[race.last_checkpoint].global_transform)


## A new run from the start: the timer, the flow and the targets from zero, the runner at
## the start.
func restart_the_run() -> void:
	race.restart()
	flow.restart()
	targets.reset()
	respawn()
	restarted.emit()


## The checkpoint of a section: where a runner respawns, its -Z axis towards what comes
## next.
func checkpoint(index: int) -> Checkpoint:
	return _checkpoints[index]


## The way forward in the section that the checkpoint `index` opens, in the world.
func way_forward(index: int) -> Vector3:
	return -_checkpoints[index].global_basis.z


func target_blocks() -> Array[TargetBlock]:
	return _blocks


## The box that holds every block (static body) of the lane, in the world.
func bounds() -> AABB:
	var bounds_so_far: AABB = AABB()
	var first: bool = true
	for block: Node in find_children("*", "StaticBody3D", true, false):
		for child: Node in block.get_children():
			var collider: CollisionShape3D = child as CollisionShape3D
			if collider == null:
				continue
			var box: AABB = collider.global_transform * collider.shape.get_debug_mesh().get_aabb()
			bounds_so_far = box if first else bounds_so_far.merge(box)
			first = false
	return bounds_so_far


## One fixed step of the runner has passed: the respawn rule first, then the flow counts
## the step (nothing of it after a return to a checkpoint) and gives its speed bonus back
## to the motor; then the targets play their step, and their effects may hit the runner;
## then the weapon follows what the runner aims at, and its shot reaches the targets it
## may shoot. Everything obeys the tuning the runner obeys. A restart puts every target
## back.
func _on_player_stepped(intent: MoveIntent) -> void:
	var altitude: float = player.global_position.y
	var order: RaceState.RespawnOrder = race.apply_respawn_rule(altitude, fall_limit, intent)
	if order == RaceState.RespawnOrder.RESTART:
		restart_the_run()
	elif order == RaceState.RespawnOrder.RESPAWN:
		respawn()
		flow.respawn()
	tuning = player.tuning
	flow.tuning = tuning
	flow.follow(player.motor)
	_step_the_targets()
	shooter.tuning = tuning
	shooter.follow(
		intent,
		player.aim_facts,
		player.motor.steps,
		shot_board,
		flow,
		player.motor.is_on_the_ground()
	)
	_show_the_targets()
	race.tick()


## Every target plays its step with the runner in its zone, whether it is in the air
## there, and whether its place is free; then the flow counts the effects that hit the
## runner.
func _step_the_targets() -> void:
	targets.set_tuning(tuning)
	for block: TargetBlock in _blocks:
		var inside: Array[int] = []
		var in_the_air_above: bool = false
		var place_free: bool = true
		if player != null:
			if block.holds(player):
				inside.append(runner_id)
				in_the_air_above = not player.is_on_floor()
			place_free = not block.place_holds(player)
		block.target.step(inside, place_free, in_the_air_above)
	flow.follow_targets(targets, runner_id)


## The target blocks show what their targets say, set off when the weapon watched aims at
## them and could hit them.
func _show_the_targets() -> void:
	for block: TargetBlock in _blocks:
		block.focused = focus_from != null and focus_from.shootable_target() == block.target_id
		block.follow()


func _on_checkpoint_reached(index: int) -> void:
	var before: int = race.last_checkpoint
	race.reach_checkpoint(index)
	if race.last_checkpoint > before:
		checkpoint_reached.emit(race.last_checkpoint)


func _on_start_line_crossed() -> void:
	if started_by_its_line:
		race.cross_start_line()


func _on_finish_line_crossed() -> void:
	if race.phase != RaceState.Phase.RUNNING:
		return
	race.cross_finish_line()
	flow.finish()
	finished.emit()
