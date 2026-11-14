class_name Main
extends Node
## The game: the start screen (game/ui), then the mode chosen there, solo practice (Course),
## a duel against the ghost or the bot (Duel) or the trick park (TrickPark), until the
## menu action (Esc, Start) or the result of a duel goes back to the start screen. It
## keeps the session from one mode to the next: the best solo run, which opens the duel
## against the ghost.

const COURSE_SCENE: PackedScene = preload("res://game/levels/test_course.tscn")
const DUEL_SCENE: PackedScene = preload("res://game/levels/duel.tscn")
const TRICK_PARK_SCENE: PackedScene = preload("res://game/levels/trick_park.tscn")
const MENU: StringName = &"menu"

var session: Session = Session.new()
## The mode under way; null on the start screen.
var mode: Node

@onready var _start_screen: StartScreen = $StartScreen as StartScreen


func _ready() -> void:
	_start_screen.mode_chosen.connect(_on_mode_chosen)
	_show_the_start_screen()


func _unhandled_input(event: InputEvent) -> void:
	if mode != null and event.is_action_pressed(MENU):
		_on_menu_requested()


func _show_the_start_screen() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_screen.open(session.has_solo_run())


func _on_mode_chosen(choice: StartScreen.Choice) -> void:
	if mode != null:
		return
	if choice == StartScreen.Choice.SOLO_PRACTICE:
		var course: Course = COURSE_SCENE.instantiate() as Course
		course.session = session
		mode = course
	elif choice == StartScreen.Choice.TRICK_PARK:
		mode = TRICK_PARK_SCENE.instantiate() as TrickPark
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
