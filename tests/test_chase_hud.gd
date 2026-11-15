extends GutTest
## The display of a player of the chase (game/ui): its role (CAT or MOUSE), the time left
## in the round, and at the edge of its view an indicator of the other player when it is
## out of sight.

const HUD_SCENE: PackedScene = preload("res://game/ui/chase_hud.tscn")
const STEPS_PER_SECOND: int = 60
## The size of the view of one player of a split screen, in pixels.
const VIEW_SIZE: Vector2i = Vector2i(960, 1080)
const EYES: Vector3 = Vector3(0.0, 1.6, 0.0)


func test_each_hud_shows_its_role_and_the_time() -> void:
	var chase: ChaseState = ChaseState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	chase.receive(ChaseMessage.start(100))
	var huds: Array[ChaseHud] = [_add_hud(chase, 0), _add_hud(chase, 1)]

	for hud: ChaseHud in huds:
		hud.step = 100 + 5 * STEPS_PER_SECOND + 30
		hud.refresh()

	assert_eq(_text(huds[0], "%RoleLabel"), "CAT", "player 1 is the cat")
	assert_eq(_text(huds[1], "%RoleLabel"), "MOUSE", "player 2 the mouse")
	for hud: ChaseHud in huds:
		assert_eq(_text(hud, "%TimeLabel"), "0:14.50", "the time left, on both")
		assert_true((hud.get_node("%RoleLabel") as Label).is_visible_in_tree(), "the role is shown")
	var cat_colour: Color = (huds[0].get_node("%RoleLabel") as Label).modulate
	var mouse_colour: Color = (huds[1].get_node("%RoleLabel") as Label).modulate
	assert_eq(cat_colour, chase.tuning.chase_cat_colour, "in the colour of the cat")
	assert_eq(mouse_colour, chase.tuning.chase_mouse_colour, "in the colour of the mouse")

	chase.receive(ChaseMessage.catch(800, chase.cat, Tag.Gesture.TOUCH))
	for hud: ChaseHud in huds:
		hud.refresh()
	assert_eq(_text(huds[0], "%RoleLabel"), "MOUSE", "between two rounds: the coming role")
	assert_eq(_text(huds[1], "%TimeLabel"), "0:20.00", "and the time of the coming round")


func test_the_indicator_shows_the_other_off_screen() -> void:
	var view: SubViewport = SubViewport.new()
	view.size = VIEW_SIZE
	add_child_autofree(view)
	var camera: Camera3D = Camera3D.new()
	view.add_child(camera)
	camera.position = EYES
	camera.current = true
	var other: Node3D = Node3D.new()
	view.add_child(other)
	var chase: ChaseState = ChaseState.new(MotorBody.fixed_tuning(), STEPS_PER_SECOND)
	# The display covers the view, as in the split screen.
	var frame: Control = Control.new()
	frame.size = Vector2(VIEW_SIZE)
	add_child_autofree(frame)
	var hud: ChaseHud = _add_hud(chase, 0, frame)
	assert_eq(hud.size, Vector2(VIEW_SIZE), "the display covers the view")
	hud.camera = camera
	hud.other = other

	# In front of the camera, in sight: no indicator.
	other.position = Vector3(0.5, 0.0, -8.0)
	hud.refresh()
	assert_false(hud.indicator_shown, "the other in sight: no indicator")

	# Behind the camera and to its right.
	other.position = Vector3(3.0, 0.0, 6.0)
	hud.refresh()

	assert_true(hud.indicator_shown, "the other behind the camera: an indicator")
	_assert_on_the_edge(hud, "behind")
	assert_gt(hud.indicator_direction.x, 0.0, "pointing to its right")

	# Far to the left, in front but out of the field of view.
	other.position = Vector3(-30.0, 1.6, -2.0)
	hud.refresh()
	assert_true(hud.indicator_shown, "the other out of the field of view: an indicator")
	_assert_on_the_edge(hud, "to the left")
	assert_lt(hud.indicator_direction.x, 0.0, "pointing to its left")
	assert_almost_eq(hud.indicator_position.x, ChaseHud.INDICATOR_MARGIN, 0.5, "on the left edge")


## The indicator is on the edge of the view, its margin inside it.
func _assert_on_the_edge(hud: ChaseHud, context: String) -> void:
	var at: Vector2 = hud.indicator_position
	var margin: float = ChaseHud.INDICATOR_MARGIN
	var inside: Rect2 = Rect2(Vector2.ZERO, hud.size).grow(-margin + 0.5)
	assert_true(inside.has_point(at), context + ": inside the view")
	var to_the_edge: float = minf(minf(at.x, hud.size.x - at.x), minf(at.y, hud.size.y - at.y))
	assert_almost_eq(to_the_edge, margin, 0.5, context + ": at the edge")


func _add_hud(chase: ChaseState, player: int, parent: Node = null) -> ChaseHud:
	var hud: ChaseHud = HUD_SCENE.instantiate() as ChaseHud
	hud.chase = chase
	hud.player = player
	if parent == null:
		add_child_autofree(hud)
	else:
		parent.add_child(hud)
	return hud


func _text(hud: ChaseHud, path: String) -> String:
	return (hud.get_node(path) as Label).text
