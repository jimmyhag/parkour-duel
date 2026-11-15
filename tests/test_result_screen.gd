extends GutTest
## The result screen of a round (game/ui): the verdict, one line per runner with its time
## or DNF and its style score, and the two choices, REMATCH and MENU; and the end of a
## chase, by two or against the bot.

const SCREEN_SCENE: PackedScene = preload("res://game/ui/result_screen.tscn")
const STEPS_PER_SECOND: int = 60
const PLAYER: int = 0
const OPPONENT: int = 1
## 30.5 s of fixed steps.
const PLAYER_STEPS: int = 1830

var _rematches: int = 0
var _menus: int = 0


func after_each() -> void:
	for action: StringName in [&"menu_down", &"jump", &"menu"]:
		Input.action_release(action)


func test_the_result_screen_shows_the_round() -> void:
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	round_state.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 2500))
	var screen: ResultScreen = _add_screen()
	assert_false(screen.visible, "hidden during the round")

	screen.show_round(round_state, ResultScreen.Opponent.BOT, [2500, 700] as Array[int])

	assert_true(screen.visible, "shown at the end of the round")
	assert_eq(_text(screen, "%Verdict"), "YOU WIN")
	var you: String = _text(screen, "%YouLine")
	assert_string_contains(you, "YOU")
	assert_string_contains(you, "0:30.50")
	assert_string_contains(you, "STYLE 2500")
	var them: String = _text(screen, "%ThemLine")
	assert_string_contains(them, "BOT")
	assert_string_contains(them, "DNF")
	assert_string_contains(them, "STYLE 700")
	assert_eq(screen.choice_texts(), ["REMATCH", "MENU"] as Array[String], "two choices")
	assert_eq(screen.selected(), ResultScreen.Choice.REMATCH, "the first one selected")


func test_the_result_screen_shows_the_end_of_a_chase() -> void:
	var chase: ChaseState = ChaseState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	var step: int = 0
	# Player 2 wins three rounds: the mouse holds out, then the cat catches the mouse.
	for round_number: int in 3:
		chase.receive(ChaseMessage.start(step))
		if chase.cat == OPPONENT:
			chase.receive(ChaseMessage.catch(step + 60, chase.cat, Tag.Gesture.TOUCH))
		else:
			chase.receive(ChaseMessage.time_up(step + chase.round_steps()))
		step += 2000
	assert_eq(chase.winner, OPPONENT, "player 2 won the match")
	var screen: ResultScreen = _add_screen()

	screen.show_chase(chase)

	assert_true(screen.visible, "shown at the end of the match")
	assert_eq(_text(screen, "%Verdict"), "PLAYER 2 WINS")
	assert_eq(_text(screen, "%YouLine"), "PLAYER 1   0", "the rounds of player 1")
	assert_eq(_text(screen, "%ThemLine"), "PLAYER 2   3", "and of player 2")
	assert_eq(screen.choice_texts(), ["REMATCH", "MENU"] as Array[String], "two choices")
	assert_eq(screen.selected(), ResultScreen.Choice.REMATCH, "the first one selected")


func test_the_end_of_the_match_says_who_won() -> void:
	# docs/specs/chase-bot.md: against the bot, player 2. The player wins its third round,
	# as the cat; then, in another match, the bot wins its own.
	var won: ChaseState = _chase_won_by(PLAYER)
	var lost: ChaseState = _chase_won_by(OPPONENT)
	var screen: ResultScreen = _add_screen()

	screen.show_chase(won, true)

	assert_eq(_text(screen, "%Verdict"), "YOU WIN", "the player won")
	assert_eq(_text(screen, "%YouLine"), "YOU   3", "the rounds of the player")
	assert_eq(_text(screen, "%ThemLine"), "BOT   0", "and of the bot")
	assert_eq(screen.choice_texts(), ["REMATCH", "MENU"] as Array[String], "two choices")

	screen.show_chase(lost, true)

	assert_eq(_text(screen, "%Verdict"), "BOT WINS", "the bot won")
	assert_eq(_text(screen, "%YouLine"), "YOU   0")
	assert_eq(_text(screen, "%ThemLine"), "BOT   3")
	# Between two rounds, the screen of the chase names them so too.
	var round_screen: ChaseRoundScreen = (
		(load("res://game/ui/chase_round_screen.tscn") as PackedScene).instantiate()
		as ChaseRoundScreen
	)
	add_child_autofree(round_screen)
	var under_way: ChaseState = ChaseState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	under_way.receive(ChaseMessage.start(0))
	under_way.receive(ChaseMessage.catch(60, under_way.cat, Tag.Gesture.TOUCH))
	round_screen.chase = under_way
	round_screen.names = ["YOU", "BOT"] as Array[String]
	round_screen.refresh()
	assert_eq(
		round_screen.lines(), ["CAUGHT!", "CAT WINS", "YOU   1 - 0   BOT"], "the winner, the score"
	)


func test_the_verdict_of_a_lost_round_and_of_a_draw() -> void:
	var screen: ResultScreen = _add_screen()
	var lost: RoundState = RoundState.new(STEPS_PER_SECOND)
	lost.receive(RoundMessage.start(0))
	lost.receive(RoundMessage.finish(OPPONENT, PLAYER_STEPS, 0))
	screen.show_round(lost, ResultScreen.Opponent.GHOST, [0, 0] as Array[int])
	assert_eq(_text(screen, "%Verdict"), "YOU LOSE")
	assert_string_contains(_text(screen, "%YouLine"), "DNF")
	assert_string_contains(_text(screen, "%ThemLine"), "GHOST")

	var drawn: RoundState = RoundState.new(STEPS_PER_SECOND)
	drawn.receive(RoundMessage.start(0))
	drawn.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 10))
	drawn.receive(RoundMessage.finish(OPPONENT, PLAYER_STEPS, 10))
	screen.show_round(drawn, ResultScreen.Opponent.BOT, [10, 10] as Array[int])
	assert_eq(_text(screen, "%Verdict"), "DRAW")


func test_the_result_screen_chooses_the_rematch_or_the_menu() -> void:
	var round_state: RoundState = RoundState.new(STEPS_PER_SECOND)
	round_state.receive(RoundMessage.start(0))
	round_state.receive(RoundMessage.finish(PLAYER, PLAYER_STEPS, 0))
	var screen: ResultScreen = _add_screen()
	screen.show_round(round_state, ResultScreen.Opponent.BOT, [0, 0] as Array[int])

	await _tap(&"jump")
	assert_eq(_rematches, 1, "jump on REMATCH: the rematch")

	screen.show_round(round_state, ResultScreen.Opponent.BOT, [0, 0] as Array[int])
	await _tap(&"menu_down")
	assert_eq(screen.selected(), ResultScreen.Choice.MENU, "down: MENU")
	await _tap(&"jump")
	assert_eq(_menus, 1, "jump on MENU: the start screen")

	screen.show_round(round_state, ResultScreen.Opponent.BOT, [0, 0] as Array[int])
	await _tap(&"menu")
	assert_eq(_menus, 2, "Esc or Back: the start screen too")
	assert_eq(_rematches, 1, "and no rematch")


## A match won by `winner`, which wins every round: the cat touches the mouse, the mouse
## holds out.
func _chase_won_by(winner: int) -> ChaseState:
	var chase: ChaseState = ChaseState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	var step: int = 0
	while chase.phase != ChaseState.Phase.MATCH_OVER:
		chase.receive(ChaseMessage.start(step))
		if chase.cat == winner:
			chase.receive(ChaseMessage.catch(step + 60, chase.cat, Tag.Gesture.TOUCH))
		else:
			chase.receive(ChaseMessage.time_up(step + chase.round_steps()))
		step += 2000
	return chase


func _add_screen() -> ResultScreen:
	var screen: ResultScreen = SCREEN_SCENE.instantiate() as ResultScreen
	add_child_autofree(screen)
	screen.rematch_chosen.connect(func() -> void: _rematches += 1)
	screen.menu_chosen.connect(func() -> void: _menus += 1)
	return screen


func _text(screen: ResultScreen, path: NodePath) -> String:
	return (screen.get_node(path) as Label).text


## Presses an action of the input map for one frame, as a finger would, once the screen
## has been on screen for a frame: it ignores the frame it opens.
func _tap(action: StringName) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame
