extends GutTest
## The sounds of the flow and of the tricks (game/ui): each event the flow counted plays
## its own sound, from assets/sounds/.

const SOUNDS_SCENE: PackedScene = preload("res://game/ui/flow_sounds.tscn")
const STEPS_PER_SECOND: int = 60
## The turn (0.35 s) and the twist (0.15 s) of the fixed tuning in fixed steps.
const TURN_STEPS: int = 21
const TWIST_STEPS: int = 9
## The players of the scene, and the sound each one plays.
const SOUNDS: Dictionary[String, String] = {
	"TrickLanded": "res://assets/sounds/confirmation_001.ogg",
	"PerfectLanding": "res://assets/sounds/confirmation_002.ogg",
	"Crash": "res://assets/sounds/impactPunch_heavy_000.ogg",
	"TierCrossed": "res://assets/sounds/maximize_006.ogg",
	"ComboBroken": "res://assets/sounds/error_004.ogg",
}

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_every_event_plays_its_sound() -> void:
	var flow: FlowState = FlowState.new(_tuning, STEPS_PER_SECOND)
	var sounds: FlowSounds = SOUNDS_SCENE.instantiate() as FlowSounds
	sounds.flow = flow
	add_child_autofree(sounds)
	for player: String in SOUNDS:
		var stream: AudioStream = _player(sounds, player).stream
		assert_not_null(stream, player + " has a sound")
		if stream != null:
			assert_eq(stream.resource_path, SOUNDS[player], player + " plays its file")
	sounds.refresh()
	assert_eq(_playing(sounds), [] as Array[String], "nothing happened: silence")

	# A trick posed, then posed perfect.
	_step(flow, [_trick(false)])
	_assert_plays(sounds, ["TrickLanded"], "a trick posed")
	_step(flow, [_trick(true)])
	_assert_plays(sounds, ["PerfectLanding"], "a trick posed perfect")

	# A tier crossed.
	flow.gauge = _tuning.flow_tier_value - 10.0
	_step(flow, [RunnerEvent.new(RunnerEvent.Kind.WALL_RUN, 0)])
	_assert_plays(sounds, ["TierCrossed"], "a tier crossed")

	# A combo broken by a hard landing, then a crash, which breaks the combo too.
	_step(flow, [RunnerEvent.new(RunnerEvent.Kind.HARD_LANDING, 0)])
	_assert_plays(sounds, ["ComboBroken"], "a combo broken")
	_step(flow, [RunnerEvent.new(RunnerEvent.Kind.WALL_JUMP, 0)])
	_stop_all(sounds)
	_step(flow, [RunnerEvent.new(RunnerEvent.Kind.CRASH, 0)])
	_assert_plays(sounds, ["Crash", "ComboBroken"], "a crash, in a combo")


## Refreshes the sounds and checks that exactly `players` started, then silences them.
func _assert_plays(sounds: FlowSounds, players: Array[String], context: String) -> void:
	sounds.refresh()
	var expected: Array[String] = players.duplicate()
	expected.sort()
	assert_eq(_playing(sounds), expected, context)
	_stop_all(sounds)


func _step(flow: FlowState, events: Array[RunnerEvent]) -> void:
	flow.step(events, _tuning.top_speed, false)


func _trick(perfect: bool) -> RunnerEvent:
	var recipe: TrickRecipe = TrickRecipe.drawn(TrickRecipe.Flip.BACKFLIP)
	var trick: AirTrick = AirTrick.new(recipe, Vector3.FORWARD, TURN_STEPS, TWIST_STEPS)
	trick.finished = true
	trick.perfect = perfect
	return RunnerEvent.new(RunnerEvent.Kind.TRICK, 0, trick)


func _player(sounds: FlowSounds, player: String) -> AudioStreamPlayer:
	return sounds.get_node(player) as AudioStreamPlayer


## The players that are playing, sorted by name.
func _playing(sounds: FlowSounds) -> Array[String]:
	var playing: Array[String] = []
	for player: String in SOUNDS:
		if _player(sounds, player).playing:
			playing.append(player)
	playing.sort()
	return playing


func _stop_all(sounds: FlowSounds) -> void:
	for player: String in SOUNDS:
		_player(sounds, player).stop()
