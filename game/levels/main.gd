class_name Main
extends Node
## The game: the start screen (game/ui), then the mode chosen there, solo practice (Course)
## or a duel against the ghost or the bot (Duel), until the mode asks to go back to the
## start screen. It keeps the session from one mode to the next: the best solo run, which
## opens the duel against the ghost.

const COURSE_SCENE: PackedScene = preload("res://game/levels/test_course.tscn")
const DUEL_SCENE: PackedScene = preload("res://game/levels/duel.tscn")

var session: Session = Session.new()
## The mode under way; null on the start screen.
var mode: Node

@onready var _start_screen: StartScreen = $StartScreen as StartScreen


func _ready() -> void:
	_start_screen.mode_chosen.connect(_on_mode_chosen)
	_show_the_start_screen()


func _show_the_start_screen() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_screen.open(session.has_solo_run())


func _on_mode_chosen(choice: StartScreen.Choice) -> void:
	if mode != null:
		return
	if choice == StartScreen.Choice.SOLO_PRACTICE:
		var course: Course = COURSE_SCENE.instantiate() as Course
		course.session = session
		course.menu_requested.connect(_on_menu_requested)
		mode = course
	else:
		var duel: Duel = DUEL_SCENE.instantiate() as Duel
		duel.session = session
		duel.opponent = Duel.Opponent.GHOST
		if choice == StartScreen.Choice.DUEL_VS_BOT:
			duel.opponent = Duel.Opponent.BOT
		duel.menu_requested.connect(_on_menu_requested)
		mode = duel
	_start_screen.close()
	add_child(mode)


func _on_menu_requested() -> void:
	if mode == null:
		return
	mode.queue_free()
	mode = null
	_show_the_start_screen()
