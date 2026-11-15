extends ReplayTest
## The chase online (docs/specs/online-chase.md) played by two machines side by side, each
## in a world of its own, joined by the fake network (OnlinePair): a friend joining a game
## hosted, each runner answering at once, each machine seeing the other run, the start held
## until the GO of the host, the catch judged on the screen of the cat, a catch arriving too
## late, the same score on both, a rematch for both, the other player gone. Faster than real
## time with the same fixed step of 1/60 s (see ReplayTest).

const ONE: int = Chase.PLAYER_ONE
const TWO: int = Chase.PLAYER_TWO
## Steps: of 100 ms, the latency of the scenarios; of the delay of the interpolation.
const LATENCY_MS: int = 100
const LATENCY_STEPS: int = 6
## One snapshot in this many lost.
const LOSE_EVERY: int = 4
## How far within the reach of a touch the cat stands, in m.
const IN_REACH_MARGIN: float = 0.1
## The longest a round, a countdown or a pause of the short tuning lasts, in steps.
const LONGEST: int = 400
## The short tuning: a round of 2 s, a countdown of 0.6 s, a short pause after a catch.
const SHORT_ROUND: float = 2.0
const SHORT_NUMBER: float = 0.2
const SHORT_PAUSE: float = 0.3
## Steps the guest runs and jumps, watched from the host.
const RUN_STEPS: int = 90
const JUMP_AT: int = 30
## How far the shown body may go in one step, at most, past the speed of the runner, in m.
const SMOOTH: float = 0.05
## How near the body shown is to where the runner was that many steps before, in m.
const NEAR: float = 0.2
## The steps of the silence after which the other player is gone: 3 s.
const SILENCE_STEPS: int = 180


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_a_friend_joins_the_hosted_game() -> void:
	var pair: OnlinePair = OnlinePair.new(self)
	var hosting: Main = pair.add_game()
	var joining: Main = pair.add_game()
	await get_tree().process_frame

	_screen_of(hosting).host_chosen.emit()
	_screen_of(joining).join_chosen.emit(OnlinePair.ADDRESS)
	var both: bool = await pair.until(
		func() -> bool: return hosting.mode is Chase and joining.mode is Chase, 60
	)

	assert_true(both, "the game starts on both machines")
	if not both:
		return
	pair.host = hosting.mode as Chase
	pair.guest = joining.mode as Chase
	assert_true(pair.host.link.hosting, "the host hosts")
	assert_eq(pair.guest.local_player, TWO, "the guest is player 2")
	assert_true(await pair.until_go(), "the round starts on both")
	for chase: Chase in [pair.host, pair.guest]:
		assert_eq(chase.chase.cat, ONE, "the host is the cat of the first round")
	assert_false(_screen_of(hosting).visible, "no start screen any more")


func test_my_runner_answers_without_waiting_for_the_network() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS)
	await pair.start_chases()
	assert_true(await pair.until_go(), "the round is on")
	var runner: Player = pair.guest.players[TWO]
	var shown_on_the_host: Player = pair.host.players[TWO]
	var from: Vector3 = runner.global_position
	var shown_from: Vector3 = shown_on_the_host.global_position

	runner.intent_source = ScriptedIntentSource.new().hold(Vector3.LEFT, false, 30)
	await get_tree().physics_frame

	assert_gt(runner.velocity.length(), 0.0, "it moves at the very step of the input")
	assert_gt(runner.global_position.distance_to(from), 0.0, "from where it was")
	var seen: float = shown_on_the_host.global_position.distance_to(shown_from)
	assert_almost_eq(seen, 0.0, 0.001, "while the host does not see it yet")


func test_each_one_sees_the_other_run() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS, LOSE_EVERY)
	await pair.start_chases()
	assert_true(await pair.until_go(), "the round is on")
	var runner: Player = pair.guest.players[TWO]
	var shown: Player = pair.host.players[TWO]
	runner.intent_source = (
		ScriptedIntentSource
		. new()
		. hold(Vector3.LEFT, false, JUMP_AT)
		. hold(Vector3.LEFT, true, 15)
		. hold(Vector3.LEFT, false, RUN_STEPS)
	)
	var real: Array[Vector3] = []
	var seen: Array[Vector3] = []
	var clips_run: Array[RunnerAnimation.Clip] = []
	var clips_seen: Array[RunnerAnimation.Clip] = []
	for step: int in RUN_STEPS + JUMP_AT:
		await get_tree().physics_frame
		real.append(runner.global_position)
		seen.append(shown.global_position)
		clips_run.append(runner.animation.clip)
		clips_seen.append(shown.animation.clip)

	var tuning: MovementTuning = runner.tuning
	var delay: int = roundi(tuning.net_interpolation_delay * STEPS_PER_SECOND)
	var largest_step: float = 0.0
	for step: int in range(1, seen.size()):
		largest_step = maxf(largest_step, seen[step].distance_to(seen[step - 1]))
	var fastest: float = tuning.top_speed / STEPS_PER_SECOND
	assert_lt(largest_step, fastest + SMOOTH, "no jump, packets lost or not")
	var late: int = LATENCY_STEPS + delay
	var farthest: float = 0.0
	for step: int in range(late + 2, seen.size()):
		var nearest: float = INF
		for lag: int in range(late - 2, late + 3):
			nearest = minf(nearest, seen[step].distance_to(real[step - lag]))
		farthest = maxf(farthest, nearest)
	assert_lt(farthest, NEAR, "it follows the runner, the latency and the delay later")
	assert_true(clips_run.any(func(clip: int) -> bool: return clip in RunnerAnimation.JUMPS))
	assert_true(
		clips_seen.any(func(clip: int) -> bool: return clip in RunnerAnimation.JUMPS),
		"with its animation: the jump"
	)
	var colour: Color = (shown.get_node("Visual/Body") as MeshInstance3D).material_override.get(
		"albedo_color"
	)
	assert_eq(colour, tuning.chase_mouse_colour, "and the colour of its role")


func test_the_start_waits_for_the_go_of_the_host() -> void:
	# The countdown starts on both at once; the latency comes before GO: the clock of the
	# guest says GO before the GO of the host arrives.
	var pair: OnlinePair = OnlinePair.new(self)
	await pair.start_chases()
	var counting: bool = await pair.until(
		func() -> bool: return pair.guest.chase.phase == ChaseState.Phase.COUNTDOWN, 10
	)
	assert_true(counting, "the countdown is on")
	pair.network.latency_ms = LATENCY_MS
	var runner: Player = pair.guest.players[TWO]
	runner.intent_source = ScriptedIntentSource.new().hold(Vector3.LEFT, false, 1000)
	var host_go: int = -1
	var guest_go: int = -1
	var moved_before: bool = false
	var start: Vector3 = runner.global_position
	for step: int in LONGEST * 2:
		await get_tree().physics_frame
		if host_go < 0 and pair.host.chase.phase == ChaseState.Phase.RUNNING:
			host_go = step
			start = runner.global_position
		if guest_go < 0 and pair.guest.chase.phase == ChaseState.Phase.RUNNING:
			guest_go = step
		if host_go >= 0 and guest_go < 0:
			moved_before = moved_before or runner.global_position.distance_to(start) > 0.001
		if guest_go >= 0:
			break

	assert_gt(host_go, 0, "the host says GO")
	assert_gte(guest_go - host_go, LATENCY_STEPS - 1, "the guest's GO comes after the latency")
	assert_false(moved_before, "its runner held until then")


func test_the_cat_catches_what_it_touches_on_its_screen() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS)
	await pair.start_chases(null, TWO)
	assert_true(await pair.until_go(), "the round is on")
	assert_eq(pair.guest.chase.cat, TWO, "the guest is the cat")
	await _put_the_mouse_in_reach(pair)
	var cat: Player = pair.guest.players[TWO]

	cat.intent_source = ScriptedIntentSource.new().gesture(Vector3.ZERO)
	var over: bool = await pair.until(
		func() -> bool:
			return (
				pair.host.chase.phase != ChaseState.Phase.RUNNING
				and pair.guest.chase.phase != ChaseState.Phase.RUNNING
			),
		LATENCY_STEPS * 4
	)

	assert_true(over, "the round ends on both machines")
	for chase: Chase in [pair.host, pair.guest]:
		assert_eq(chase.chase.round_winner, TWO, "won by the cat")
		assert_eq(chase.chase.round_winner_role, ChaseState.Role.CAT, "by a catch")
		assert_gt(chase.catch_pause, 0, "the catch is shown")
	await get_tree().physics_frame
	var stumble: RunnerAnimation.Clip = RunnerAnimation.Clip.STUMBLE
	assert_eq(pair.host.players[ONE].animation.clip, stumble, "the mouse reacts on the host")
	assert_eq(pair.guest.players[ONE].animation.clip, stumble, "and on the screen of the cat")


func test_a_catch_arriving_after_the_time_is_up_does_not_count() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS)
	await pair.start_chases(_short_tuning(1), TWO)
	assert_true(await pair.until_go(), "the round is on")
	await _put_the_mouse_in_reach(pair)
	var guest: Chase = pair.guest
	var steps_left: Callable = func() -> int:
		return guest.chase.start_step + guest.chase.round_steps() - guest.match_steps
	await pair.until(func() -> bool: return steps_left.call() <= 2, LONGEST)
	assert_eq(guest.chase.phase, ChaseState.Phase.RUNNING, "the time is not up on the guest")

	var cat: Player = guest.players[TWO]
	cat.intent_source = ScriptedIntentSource.new().gesture(Vector3.ZERO)
	var touched_in_time: Array[bool] = [false]
	var over: bool = await pair.until(
		func() -> bool:
			var running: bool = guest.chase.phase == ChaseState.Phase.RUNNING
			if running and Chase.catches(cat, guest.players[ONE]):
				touched_in_time[0] = true
			return (
				pair.host.chase.phase == ChaseState.Phase.MATCH_OVER
				and guest.chase.phase == ChaseState.Phase.MATCH_OVER
			),
		LATENCY_STEPS * 4
	)

	assert_true(touched_in_time[0], "the cat touched the mouse on its screen in time")
	assert_true(over, "the round is over on both machines")
	for chase: Chase in [pair.host, guest]:
		assert_eq(chase.chase.round_winner, ONE, "won by the mouse")
		assert_eq(chase.chase.round_winner_role, ChaseState.Role.MOUSE, "the time was up")


func test_both_machines_count_the_same_score() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS, LOSE_EVERY)
	await pair.start_chases(_short_tuning(2))

	var over: bool = await _play_to_the_result(pair)

	assert_true(over, "the match is over on both machines")
	assert_eq(pair.guest.chase.score, pair.host.chase.score, "the same score")
	assert_eq(pair.guest.chase.round_number, pair.host.chase.round_number, "the same rounds")
	assert_eq(pair.guest.chase.winner, pair.host.chase.winner, "the same winner")
	assert_eq(pair.host.chase.score, [1, 2] as Array[int], "each mouse won its round")
	assert_eq(_verdict(pair.host), "FRIEND WINS", "the host lost")
	assert_eq(_verdict(pair.guest), "YOU WIN", "the guest won")


func test_the_rematch_of_one_restarts_for_both() -> void:
	var pair: OnlinePair = OnlinePair.new(self, LATENCY_MS)
	await pair.start_chases(_short_tuning(1))
	assert_true(await _play_to_the_result(pair), "the match is over")

	var result: ResultScreen = pair.guest.get_node("Screens/ResultScreen") as ResultScreen
	result.rematch_chosen.emit()
	var again: bool = await pair.until(
		func() -> bool:
			return (
				pair.host.chase.phase == ChaseState.Phase.COUNTDOWN
				and pair.guest.chase.phase == ChaseState.Phase.COUNTDOWN
			),
		LATENCY_STEPS * 4
	)

	assert_true(again, "a match starts again on both machines")
	for chase: Chase in [pair.host, pair.guest]:
		assert_eq(chase.chase.first_cat, TWO, "the other role first")
		assert_eq(chase.chase.score, [0, 0] as Array[int], "from zero")
		var shown: ResultScreen = chase.get_node("Screens/ResultScreen") as ResultScreen
		assert_false(shown.visible, "the result is gone")
	assert_true(await pair.until_go(), "and plays")


func test_the_other_player_leaves() -> void:
	var pair: OnlinePair = OnlinePair.new(self)
	var hosting: Main = pair.add_game()
	var joining: Main = pair.add_game()
	await get_tree().process_frame
	await _connect(pair, hosting, joining)

	# The guest closes the game.
	joining.get_parent().queue_free()
	var back: bool = await pair.until(func() -> bool: return hosting.mode == null, 30)

	assert_true(back, "the host is back at the menu")
	assert_has(_screen_of(hosting).shown_texts(), "THE OTHER PLAYER LEFT", "and says why")

	# Another guest, who gives no news for 3 s.
	var silent: Main = pair.add_game()
	await get_tree().process_frame
	await _connect(pair, hosting, silent)
	silent.process_mode = Node.PROCESS_MODE_DISABLED
	await pair.until(func() -> bool: return hosting.mode == null, SILENCE_STEPS - 10)
	assert_true(hosting.mode is Chase, "under 3 s, the game goes on")
	back = await pair.until(func() -> bool: return hosting.mode == null, 20)
	assert_true(back, "after 3 s, the host is back at the menu")
	assert_has(_screen_of(hosting).shown_texts(), "THE OTHER PLAYER LEFT", "and says why")


## The host hosts, `joining` joins it, until both play.
func _connect(pair: OnlinePair, hosting: Main, joining: Main) -> void:
	_screen_of(hosting).host_chosen.emit()
	_screen_of(joining).join_chosen.emit(OnlinePair.ADDRESS)
	var both: bool = await pair.until(
		func() -> bool: return hosting.mode is Chase and joining.mode is Chase, 60
	)
	assert_true(both, "both play")


## The mouse of the host at the centre, the cat of the guest within the reach of a touch
## behind it, facing it, once the guest shows the mouse there.
func _put_the_mouse_in_reach(pair: OnlinePair) -> void:
	var mouse: Player = pair.host.players[ONE]
	mouse.intent_source = ScriptedIntentSource.new()
	mouse.teleport(Transform3D(Basis.IDENTITY, Vector3.ZERO))
	var shown: Player = pair.guest.players[ONE]
	var there: bool = await pair.until(
		func() -> bool: return shown.global_position.length() < 0.01, LATENCY_STEPS * 4
	)
	assert_true(there, "the guest shows the mouse where it is")
	var cat: Player = pair.guest.players[TWO]
	var reach: float = 2.0 * cat.tuning.capsule_radius + cat.tuning.tag_touch_reach
	cat.intent_source = ScriptedIntentSource.new()
	cat.teleport(Transform3D(Basis.IDENTITY, Vector3.BACK * (reach - IN_REACH_MARGIN)))
	await get_tree().physics_frame


## Both machines play until the match is over and its result shows; whether it did.
func _play_to_the_result(pair: OnlinePair) -> bool:
	return await pair.until(
		func() -> bool:
			var shown: bool = true
			for chase: Chase in [pair.host, pair.guest]:
				var result: ResultScreen = chase.get_node("Screens/ResultScreen") as ResultScreen
				shown = shown and result.visible
			return shown,
		LONGEST * 4
	)


## The tuning of the project with short rounds, `rounds` to win.
func _short_tuning(rounds: int) -> MovementTuning:
	var tuning: MovementTuning = (
		load("res://game/core/movement_tuning.tres").duplicate() as MovementTuning
	)
	tuning.chase_round_time = SHORT_ROUND
	tuning.round_countdown_number_time = SHORT_NUMBER
	tuning.chase_catch_pause = SHORT_PAUSE
	tuning.chase_rounds_to_win = rounds
	return tuning


func _screen_of(main: Main) -> StartScreen:
	return main.get_node("StartScreen") as StartScreen


func _verdict(chase: Chase) -> String:
	var result: ResultScreen = chase.get_node("Screens/ResultScreen") as ResultScreen
	return (result.get_node("%Verdict") as Label).text
