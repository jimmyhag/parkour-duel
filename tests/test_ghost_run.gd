extends GutTest
## A solo run as the ghost replays it (game/core): where the visible body was at every
## fixed step from the one before the runner first acted, the checkpoints and the finish
## of the run, with the animation the body showed at each of them; and the session, which
## keeps the best finished one.

const STEPS_PER_SECOND: int = 60


func test_a_run_is_recorded_from_the_step_before_the_runner_first_acts() -> void:
	var run: GhostRun = GhostRun.new()
	for step: int in 5:
		run.record(_at(0.0), false)
	assert_eq(run.frames.size(), 1, "waiting at the start: only the last frame is kept")

	for step: int in 10:
		run.record(_at(-step - 1.0), true)
	run.reach(1)
	for step: int in 5:
		run.record(_at(-step - 11.0), false)
	run.finish(400, 1234)
	run.record(_at(-100.0), true)

	assert_eq(run.frames.size(), 16, "the start, then every step, acting or not")
	assert_eq(run.frames[0].origin.z, 0.0, "frame 0: at the start")
	assert_eq(run.frames[10].origin.z, -10.0, "frame 10: after ten steps")
	assert_eq(run.checkpoint_frames[1], 10, "the checkpoint reached at frame 10")
	assert_true(run.is_finished())
	assert_eq(run.finish_frame, 15, "finished at frame 15")
	assert_eq(run.race_steps, 400, "its time")
	assert_eq(run.style_score, 1234, "its style score")
	assert_eq(run.frame(99).origin.z, -15.0, "past its end, the ghost stays at its finish")


func test_the_ghost_replays_the_animation_recorded_with_each_frame() -> void:
	var run: GhostRun = GhostRun.new()
	run.record(_at(0.0), false, _showing(RunnerAnimation.Clip.FALLING_IDLE))
	run.record(_at(0.0), false, _showing(RunnerAnimation.Clip.IDLE))
	run.record(_at(-1.0), true, _showing(RunnerAnimation.Clip.RUNNING))
	run.record(_at(-2.0), true, _showing(RunnerAnimation.Clip.JUMP))
	run.finish(2, 0)

	assert_eq(run.animation(0).clip, RunnerAnimation.Clip.IDLE, "frame 0: as it waited")
	assert_eq(run.animation(1).clip, RunnerAnimation.Clip.RUNNING, "frame 1: running")
	assert_eq(run.animation(2).clip, RunnerAnimation.Clip.JUMP, "frame 2: jumping")
	assert_eq(run.animation(99).clip, RunnerAnimation.Clip.JUMP, "past its end, as it finished")


func test_the_session_keeps_the_best_solo_run() -> void:
	var session: Session = Session.new()
	assert_false(session.has_solo_run(), "no solo run finished yet")
	var slow: GhostRun = _finished(500)
	var fast: GhostRun = _finished(400)

	session.offer(slow)
	session.offer(fast)
	session.offer(_finished(450))
	session.offer(GhostRun.new())

	assert_true(session.has_solo_run())
	assert_same(session.best_run, fast, "the fastest run")


func _at(z: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, z))


func _showing(clip: RunnerAnimation.Clip) -> RunnerAnimation:
	var animation: RunnerAnimation = RunnerAnimation.new()
	animation.clip = clip
	return animation


func _finished(race_steps: int) -> GhostRun:
	var run: GhostRun = GhostRun.new()
	run.record(_at(0.0), true)
	run.finish(race_steps, 0)
	return run
