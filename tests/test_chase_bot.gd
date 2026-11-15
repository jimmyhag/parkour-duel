extends GutTest
## The mind of the bot of the chase (ChaseBot, game/core), without a scene: at each
## decision it is given its role, its position and its velocity, those of the other
## runner, and flee points with the distances of their paths, and gives back its goal.
## The tuning is the fixed one of MotorBody, but for the levels of the project's.

const PROJECT_TUNING: String = "res://game/core/movement_tuning.tres"
const EASY: ChaseBot.Level = ChaseBot.Level.EASY
const NORMAL: ChaseBot.Level = ChaseBot.Level.NORMAL
const HARD: ChaseBot.Level = ChaseBot.Level.HARD
const NEAR: float = 0.001

var _tuning: MovementTuning


func before_each() -> void:
	_tuning = MotorBody.fixed_tuning()


func test_the_cat_aims_where_the_player_is_going_to_be() -> void:
	var bot: ChaseBot = ChaseBot.new(_tuning, NORMAL)
	bot.play(ChaseState.Role.CAT)
	var player: Vector3 = Vector3(2.0, 0.0, -3.0)
	var running: Vector3 = Vector3(6.0, 0.0, 0.0)
	var none: Array[ChaseBotCandidate] = []

	var goal: Vector3 = bot.decide(Vector3(-5.0, 0.0, 0.0), Vector3.ZERO, player, running, none)

	assert_almost_eq(bot.lead(), 0.3, NEAR, "NORMAL anticipates 0.3 s")
	var expected: Vector3 = player + running * 0.3
	assert_almost_eq(goal.distance_to(expected), 0.0, NEAR, "where the player is 0.3 s later")
	var jumping: Vector3 = running + Vector3.UP * 5.0
	goal = bot.decide(Vector3(-5.0, 0.0, 0.0), Vector3.ZERO, player, jumping, none)
	assert_almost_eq(goal.distance_to(expected), 0.0, NEAR, "along the ground: a jump is no lead")
	var easy: ChaseBot = ChaseBot.new(_tuning, EASY)
	easy.play(ChaseState.Role.CAT)
	goal = easy.decide(Vector3.ZERO, Vector3.ZERO, player, running, none)
	assert_almost_eq(goal.distance_to(player), 0.0, NEAR, "EASY aims at the player itself")


func test_the_mouse_flees_to_the_safest_point() -> void:
	var bot: ChaseBot = ChaseBot.new(_tuning, NORMAL)
	bot.play(ChaseState.Role.MOUSE)
	var mouse: Vector3 = Vector3.ZERO
	var cat: Vector3 = Vector3(6.0, 0.0, 0.0)
	# Three flee points: one behind the cat, far from it but past it; one to the side, the
	# cat a little farther from it than the mouse; one away from the cat, with the most
	# margin of the three.
	var behind: ChaseBotCandidate = _candidate(Vector3(12.0, 0.0, 0.0), 12.0, 6.0, 0.0)
	var aside: ChaseBotCandidate = _candidate(Vector3(0.0, 0.0, 8.0), 8.0, 10.0, 6.0)
	var away: ChaseBotCandidate = _candidate(Vector3(-8.0, 0.0, 0.0), 8.0, 14.0, 6.0)
	# Behind the cat, the cat's own path is the longer one would it not pass by the cat.
	behind.cat_distance = 30.0

	var goal: Vector3 = bot.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, [behind, aside, away])

	assert_almost_eq(goal.distance_to(away.point), 0.0, NEAR, "the point of the most margin")
	assert_eq(bot.flee_point, 2, "the third one")
	# The same, without the point away: the one behind the cat has the most margin, but its
	# path passes by the cat.
	var other: ChaseBot = ChaseBot.new(_tuning, NORMAL)
	other.play(ChaseState.Role.MOUSE)
	goal = other.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, [behind, aside])
	assert_almost_eq(goal.distance_to(aside.point), 0.0, NEAR, "never the one behind the cat")
	var unreachable: ChaseBotCandidate = _candidate(Vector3(-9.0, 0.0, 0.0), INF, 20.0, 6.0)
	var third: ChaseBot = ChaseBot.new(_tuning, NORMAL)
	third.play(ChaseState.Role.MOUSE)
	goal = third.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, [unreachable, aside])
	assert_almost_eq(goal.distance_to(aside.point), 0.0, NEAR, "nor one it cannot reach")


func test_the_mouse_changes_point_when_the_cat_comes_near() -> void:
	var bot: ChaseBot = ChaseBot.new(_tuning, NORMAL)
	bot.play(ChaseState.Role.MOUSE)
	var radius: float = _tuning.chase_bot_danger_radius
	var mouse: Vector3 = Vector3.ZERO
	var cat: Vector3 = Vector3(radius + 6.0, 0.0, 0.0)
	var west: ChaseBotCandidate = _candidate(Vector3(-8.0, 0.0, 0.0), 8.0, 18.0, 10.0)
	var south: ChaseBotCandidate = _candidate(Vector3(0.0, 0.0, 8.0), 8.0, 13.0, 10.0)
	var points: Array[ChaseBotCandidate] = [west, south]
	bot.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, points)
	assert_eq(bot.flee_point, 0, "it runs to the west")
	# On its way, the south gains the more margin: the mouse keeps its point while the cat
	# stays out of the radius.
	mouse = Vector3(-2.0, 0.0, 0.0)
	west.distance = 6.0
	south.distance = 8.5
	south.cat_distance = 25.0
	bot.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, points)
	assert_eq(bot.flee_point, 0, "it keeps its point while the cat is far")

	# The cat comes into the radius, from the west: the point of the west is past it.
	cat = mouse + Vector3(-radius + 0.5, 0.0, 0.0)
	west.cat_distance = 4.5
	west.cat_clearance = 0.0
	south.cat_clearance = radius
	var goal: Vector3 = bot.decide(mouse, Vector3.ZERO, cat, Vector3.ZERO, points)

	assert_eq(bot.flee_point, 1, "another point")
	assert_almost_eq(goal.distance_to(south.point), 0.0, NEAR, "the south")
	# Once there, it goes on to another one.
	south.distance = 0.5
	west.cat_clearance = 10.0
	bot.decide(south.point, Vector3.ZERO, cat + Vector3.LEFT * 20.0, Vector3.ZERO, points)
	assert_eq(bot.flee_point, 0, "a point reached is left for another one")


func test_a_higher_level_decides_more_often_and_anticipates_more() -> void:
	var tuning: MovementTuning = load(PROJECT_TUNING) as MovementTuning
	var easy: ChaseBot = ChaseBot.new(tuning, EASY)
	var normal: ChaseBot = ChaseBot.new(tuning, NORMAL)
	var hard: ChaseBot = ChaseBot.new(tuning, HARD)

	assert_eq(tuning.chase_bot_decision_time.size(), 3, "a decision time per level")
	assert_eq(tuning.chase_bot_lead.size(), 3, "a lead per level")
	assert_lt(hard.decision_time(), normal.decision_time(), "HARD decides more often")
	assert_lt(normal.decision_time(), easy.decision_time(), "NORMAL more often than EASY")
	assert_gt(hard.lead(), normal.lead(), "HARD anticipates more")
	assert_gt(normal.lead(), easy.lead(), "NORMAL more than EASY")
	# The rest of the levels, as the spec has them.
	assert_false(easy.climbs(), "EASY neither mantles nor climbs")
	assert_true(normal.climbs() and hard.climbs(), "NORMAL and HARD do")
	assert_lt(easy.push(), 1.0, "EASY pushes its stick less than fully")
	assert_eq(normal.push(), 1.0, "NORMAL fully")
	assert_eq(hard.push(), 1.0, "HARD fully")
	assert_false(easy.tricks(), "EASY does no trick")
	assert_true(normal.tricks() and hard.tricks(), "NORMAL and HARD do")
	var perfect: float = tuning.trick_perfect_window
	assert_lt(hard.landing_press(), perfect, "HARD poses its trick perfect")
	assert_gt(normal.landing_press(), perfect, "NORMAL in the landing window, not perfect")
	assert_lt(normal.landing_press(), tuning.trick_landing_window, "but in it")


func _candidate(
	point: Vector3, distance: float, cat_distance: float, cat_clearance: float
) -> ChaseBotCandidate:
	var candidate: ChaseBotCandidate = ChaseBotCandidate.new()
	candidate.point = point
	candidate.distance = distance
	candidate.cat_distance = cat_distance
	candidate.cat_clearance = cat_clearance
	return candidate
