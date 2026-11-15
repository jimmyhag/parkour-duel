class_name Main
extends Node
## The game: the start screen (game/ui), then the mode chosen there, solo practice (Course),
## a duel against the ghost or the bot (Duel), the trick park (TrickPark) or the chase
## (Chase), by two or against the bot of the level chosen, until the menu action (Esc,
## Start) or the result of a duel or of a chase goes back to the start screen. It keeps the
## session from one mode to the next: the best solo run, which opens the duel against the
## ghost, and the last address joined online. It is the composition root of the chase online
## (docs/specs/online-chase.md): it chooses the adapter of the link, ENet (make_link; the tests
## give the fake one), gives it to the lobby (OnlineLobby) that hosts or joins, then to the
## chase once the other player is there; back at the start screen, the link is closed, and why
## the chase ended (the other player left) shows there.

const COURSE_SCENE: PackedScene = preload("res://game/levels/test_course.tscn")
const DUEL_SCENE: PackedScene = preload("res://game/levels/duel.tscn")
const TRICK_PARK_SCENE: PackedScene = preload("res://game/levels/trick_park.tscn")
const CHASE_SCENE: PackedScene = preload("res://game/levels/chase.tscn")
const MENU: StringName = &"menu"
## The version of the game two machines must share to play online.
const VERSION_SETTING: String = "application/config/version"

var session: Session = Session.new()
## The mode under way; null on the start screen.
var mode: Node
## Makes the link of a chase online: () -> NetLink. To replace before the game enters the
## tree.
var make_link: Callable = func() -> NetLink:
	var version: String = ProjectSettings.get_setting(VERSION_SETTING, "")
	return ENetLink.new(version, func() -> int: return Time.get_ticks_msec())

var _lobby: OnlineLobby = OnlineLobby.new()

@onready var _start_screen: StartScreen = $StartScreen as StartScreen


func _ready() -> void:
	_start_screen.mode_chosen.connect(_on_mode_chosen)
	_lobby.make_link = make_link
	_lobby.session = session
	_lobby.screen = _start_screen
	_lobby.connected.connect(_on_connected)
	add_child(_lobby)
	_show_the_start_screen()


func _unhandled_input(event: InputEvent) -> void:
	if mode != null and event.is_action_pressed(MENU):
		_on_menu_requested()


func _show_the_start_screen(notice: LinkStatus.Failure = LinkStatus.Failure.NONE) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_screen.open(session.has_solo_run(), notice)


func _on_mode_chosen(choice: StartScreen.Choice) -> void:
	if mode != null:
		return
	if choice == StartScreen.Choice.SOLO_PRACTICE:
		var course: Course = COURSE_SCENE.instantiate() as Course
		course.session = session
		mode = course
	elif choice == StartScreen.Choice.TRICK_PARK:
		mode = TRICK_PARK_SCENE.instantiate() as TrickPark
	elif choice == StartScreen.Choice.CHASE or choice == StartScreen.Choice.CHASE_VS_BOT:
		var chase: Chase = CHASE_SCENE.instantiate() as Chase
		chase.against_the_bot = choice == StartScreen.Choice.CHASE_VS_BOT
		chase.bot_level = _start_screen.chosen_level
		chase.menu_requested.connect(_on_menu_requested)
		mode = chase
	else:
		var duel: Duel = DUEL_SCENE.instantiate() as Duel
		duel.session = session
		duel.opponent = Duel.Opponent.GHOST
		if choice == StartScreen.Choice.DUEL_VS_BOT:
			duel.opponent = Duel.Opponent.BOT
		duel.menu_requested.connect(_on_menu_requested)
		mode = duel
	_start(mode)


## The other player of a chase online is there, on `link`: the chase starts.
func _on_connected(link: NetLink) -> void:
	if mode != null:
		link.close()
		return
	var chase: Chase = CHASE_SCENE.instantiate() as Chase
	chase.link = link
	chase.menu_requested.connect(_on_menu_requested)
	_start(chase)


func _start(chosen: Node) -> void:
	mode = chosen
	_start_screen.close()
	add_child(mode)


## Back to the start screen; a chase online closes its link, and says why it ended if the
## link failed.
func _on_menu_requested() -> void:
	if mode == null:
		return
	var notice: LinkStatus.Failure = LinkStatus.Failure.NONE
	var chase: Chase = mode as Chase
	if chase != null and chase.link != null:
		notice = chase.link.failure if chase.link.state == LinkStatus.State.FAILED else notice
		chase.link.close()
	mode.queue_free()
	mode = null
	_show_the_start_screen(notice)
