extends GutTest
## The runner of the other machine of an online chase (Player.remote, docs/specs/online-chase.md):
## it simulates nothing and shows its snapshots; caught by the cat on this machine, it reacts
## at once, until its own machine tells it is caught: from then on it shows the reaction its
## machine plays.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
## Steps enough for the snapshots fed to be shown, past the delay.
const SHOWN_STEPS: int = 12


func test_the_remote_runner_shows_the_catch_its_machine_tells() -> void:
	var runner: Player = PLAYER_SCENE.instantiate() as Player
	runner.remote = SnapshotBuffer.new()
	add_child_autofree(runner)
	runner.remote.receive(_snapshot(0, false, RunnerAnimation.Clip.IDLE))
	runner.react_to_the_catch(Tag.Gesture.TOUCH)
	# The signal of a physics frame comes before its step: two of them, one step played.
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(runner.animation.clip, RunnerAnimation.Clip.STUMBLE, "it reacts at once")

	for step: int in range(1, SHOWN_STEPS):
		runner.remote.receive(_snapshot(step, true, RunnerAnimation.Clip.FALL_FLAT))
	for step: int in SHOWN_STEPS:
		await get_tree().physics_frame

	assert_eq(runner.animation.clip, RunnerAnimation.Clip.FALL_FLAT, "then as its machine says")


func _snapshot(step: int, caught: bool, clip: RunnerAnimation.Clip) -> RunnerSnapshot:
	var made: RunnerSnapshot = RunnerSnapshot.new()
	made.step = step
	made.capsule_height = 1.8
	made.caught = caught
	made.animation.clip = clip
	return made
