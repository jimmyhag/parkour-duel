extends GutTest
## The sounds of the gestures of the cat (game/ui, docs/specs/chase-tag.md, decision 8): a
## catch plays an impact, a gesture that misses while the round is on plays a short sound,
## from assets/sounds/.

const SOUNDS_SCENE: PackedScene = preload("res://game/ui/chase_sounds.tscn")
const STEPS_PER_SECOND: int = 60
## The steps a touch of the fixed tuning reaches.
const TOUCH_STEPS: int = 15
## More steps than the recovery of a touch lasts.
const RECOVERY_STEPS: int = 30
## The players of the scene, and the sound each one plays.
const SOUNDS: Dictionary[String, String] = {
	"Catch": "res://assets/sounds/impactPunch_heavy_000.ogg",
	"Miss": "res://assets/sounds/back_002.ogg",
}


func test_a_catch_and_a_miss_play_their_sounds() -> void:
	var tuning: MovementTuning = MotorBody.fixed_tuning()
	var chase: ChaseState = ChaseState.new(tuning, STEPS_PER_SECOND)
	chase.receive(ChaseMessage.start(0))
	var cat: MotorBody = MotorBody.running(tuning, Vector3.FORWARD, tuning.top_speed)
	cat.motor.can_tag = true
	var sounds: ChaseSounds = SOUNDS_SCENE.instantiate() as ChaseSounds
	sounds.chase = chase
	sounds.motors = [cat.motor]
	add_child_autofree(sounds)
	for player: String in SOUNDS:
		var stream: AudioStream = _player(sounds, player).stream
		assert_not_null(stream, player + " has a sound")
		if stream != null:
			assert_eq(stream.resource_path, SOUNDS[player], player + " plays its file")
	_assert_plays(sounds, [], "nothing happened: silence")

	# A touch reaches: silence; it reaches nobody: the miss.
	var touch: MoveIntent = MoveIntent.new()
	touch.direction = Vector3.FORWARD
	touch.touch_pressed = true
	cat.step(touch)
	_assert_plays(sounds, [], "a touch that reaches: silence")
	for step: int in TOUCH_STEPS:
		cat.step(MoveIntent.new())
	_assert_plays(sounds, ["Miss"], "a touch missed")
	cat.step(MoveIntent.new())
	_assert_plays(sounds, [], "once only")

	# A touch catches the mouse: the impact, and no miss for it once the round is over.
	for step: int in RECOVERY_STEPS:
		cat.step(MoveIntent.new())
	cat.step(touch)
	chase.receive(ChaseMessage.catch(100, chase.cat, Tag.Gesture.TOUCH))
	_assert_plays(sounds, ["Catch"], "a catch")
	for step: int in TOUCH_STEPS:
		cat.step(MoveIntent.new())
	assert_eq(
		cat.motor.tag.phase, Tag.Phase.RECOVERING, "the touch that caught has stopped reaching"
	)
	_assert_plays(sounds, [], "no miss for the touch that caught, the round over")


## Refreshes the sounds and checks that exactly `players` started, then silences them.
func _assert_plays(sounds: ChaseSounds, players: Array[String], context: String) -> void:
	sounds.refresh()
	var playing: Array[String] = []
	for player: String in SOUNDS:
		if _player(sounds, player).playing:
			playing.append(player)
		_player(sounds, player).stop()
	assert_eq(playing, players, context)


func _player(sounds: ChaseSounds, player: String) -> AudioStreamPlayer:
	return sounds.get_node(player) as AudioStreamPlayer
