extends GutTest
## The sounds of the shot and of the targets (game/ui): the shot, the warning of a target
## hit, the start of its effect and its return each play their own sound, from
## assets/sounds/.

const SOUNDS_SCENE: PackedScene = preload("res://game/ui/sabotage_sounds.tscn")
const STEPS_PER_SECOND: int = 60
const WARNING_STEPS: int = 36
const PLATFORM_STEPS: int = 300
const SHOOTER: int = 1
const TARGET: int = 4
const NOBODY: Array[int] = []
## The players of the scene, and the sound each one plays.
const SOUNDS: Dictionary[String, String] = {
	"Shot": "res://assets/sounds/impactMetal_light_000.ogg",
	"Warning": "res://assets/sounds/glitch_001.ogg",
	"Effect": "res://assets/sounds/impactWood_heavy_000.ogg",
	"Return": "res://assets/sounds/back_002.ogg",
}


func test_every_sabotage_event_plays_its_sound() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var board: TargetBoard = TargetBoard.new()
	var platform: SabotageTarget = SabotageTarget.new(
		TARGET, SabotageTarget.Kind.PLATFORM, tuning, STEPS_PER_SECOND
	)
	board.add(platform)
	var flow: FlowState = FlowState.new(tuning, STEPS_PER_SECOND)
	flow.ammo = 3
	var shooter: Shooter = Shooter.new(SHOOTER, tuning)
	var sounds: SabotageSounds = SOUNDS_SCENE.instantiate() as SabotageSounds
	sounds.shooter = shooter
	sounds.targets = board
	add_child_autofree(sounds)
	for player: String in SOUNDS:
		var stream: AudioStream = _player(sounds, player).stream
		assert_not_null(stream, player + " has a sound")
		if stream != null:
			assert_eq(stream.resource_path, SOUNDS[player], player + " plays its file")
	sounds.refresh()
	assert_eq(_playing(sounds), [] as Array[String], "nothing happened: silence")

	# A shot that hits: the shot and the warning of the target.
	var shot: MoveIntent = MoveIntent.new()
	shot.aim_held = true
	shot.shoot_pressed = true
	shooter.follow(shot, AimFacts.new(TARGET, 10.0), 0, board, flow)
	_assert_plays(sounds, ["Shot", "Warning"], "a shot that hits")

	# The effect starts, then the target comes back.
	for step: int in WARNING_STEPS:
		platform.step(NOBODY)
	_assert_plays(sounds, ["Effect"], "the effect starts")
	for step: int in PLATFORM_STEPS:
		platform.step(NOBODY)
	_assert_plays(sounds, ["Return"], "the target comes back")


## Refreshes the sounds and checks that exactly `players` started, then silences them.
func _assert_plays(sounds: SabotageSounds, players: Array[String], context: String) -> void:
	sounds.refresh()
	var expected: Array[String] = players.duplicate()
	expected.sort()
	assert_eq(_playing(sounds), expected, context)
	for player: String in SOUNDS:
		_player(sounds, player).stop()


func _player(sounds: SabotageSounds, player: String) -> AudioStreamPlayer:
	return sounds.get_node(player) as AudioStreamPlayer


## The players that are playing, sorted by name.
func _playing(sounds: SabotageSounds) -> Array[String]:
	var playing: Array[String] = []
	for player: String in SOUNDS:
		if _player(sounds, player).playing:
			playing.append(player)
	playing.sort()
	return playing
