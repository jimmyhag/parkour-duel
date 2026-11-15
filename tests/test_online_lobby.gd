extends GutTest
## HOST and JOIN of the chase online (docs/specs/online-chase.md): the start screen (game/ui)
## and the lobby (OnlineLobby, game/levels) over a link of the fake network, or of ENet on
## this machine; what the screen shows of another version refused, of an address where
## nobody hosts, of a port already taken; the address typed on the gamepad.

const SCREEN_SCENE: PackedScene = preload("res://game/ui/start_screen.tscn")
const VERSION: String = "0.5.0"
const OTHER_VERSION: String = "0.4.0"
const ADDRESS: String = "127.0.0.1"
const LOCAL: String = "127.0.0.1"
## Frames a pressed button is held, then left released.
const FRAMES: int = 2

var _clock: ManualClock
var _network: FakeNetwork
var _taken: PacketPeerUDP = null


func before_each() -> void:
	_clock = ManualClock.new()
	_network = FakeNetwork.new(_clock.read)


func after_each() -> void:
	if _taken != null:
		_taken.close()
		_taken = null


func test_another_version_of_the_game_is_refused() -> void:
	var hosting: OnlineLobby = _add_lobby(_fake(VERSION))
	var joining: OnlineLobby = _add_lobby(_fake(OTHER_VERSION))
	var host: StartScreen = hosting.screen
	var guest: StartScreen = joining.screen
	var started: Array[NetLink] = []
	for lobby: OnlineLobby in [hosting, joining]:
		lobby.connected.connect(started.append)

	host.host_chosen.emit()
	guest.join_chosen.emit(ADDRESS)
	await _steps(10)

	assert_has(host.shown_texts(), "DIFFERENT GAME VERSION", "the host sees it")
	assert_has(host.shown_texts(), "WAITING FOR A PLAYER", "and waits on")
	assert_has(guest.shown_texts(), "DIFFERENT GAME VERSION", "the guest sees it")
	assert_has(guest.shown_texts(), "ADDRESS OF THE HOST", "back at its address")
	assert_eq(started.size(), 0, "no game starts")


func test_the_connection_fails_cleanly() -> void:
	var screen: StartScreen = _add_lobby(_fake(VERSION)).screen

	screen.join_chosen.emit(ADDRESS)
	await _steps(2)
	assert_has(screen.shown_texts(), "CONNECTING…", "it connects")
	_clock.ms += NetLink.CONNECT_TIMEOUT_MS - 10
	await _steps(2)
	assert_has(screen.shown_texts(), "CONNECTING…", "not yet given up")
	_clock.ms += 10
	await _steps(2)

	assert_has(screen.shown_texts(), "COULD NOT CONNECT", "after 5 s")
	assert_has(screen.shown_texts(), "ADDRESS OF THE HOST", "the screen JOIN is back")
	assert_does_not_have(screen.shown_texts(), "CONNECTING…", "it connects no more")


func test_the_port_already_taken_is_said() -> void:
	_taken = PacketPeerUDP.new()
	assert_eq(_taken.bind(NetLink.DEFAULT_PORT, LOCAL), OK, "another program takes the port")
	var screen: StartScreen = (
		_add_lobby(func() -> NetLink: return ENetLink.new(VERSION, _clock.read, LOCAL)).screen
	)

	screen.host_chosen.emit()
	await _steps(2)

	assert_has(screen.shown_texts(), "PORT ALREADY IN USE", "it is said")
	assert_has(screen.shown_texts(), "HOST", "on the choice of HOST and JOIN")
	assert_does_not_have(screen.shown_texts(), "WAITING FOR A PLAYER", "nothing waits")


func test_the_address_is_typed_on_the_gamepad() -> void:
	var screen: StartScreen = _add_lobby(_fake(VERSION)).screen
	for down: int in StartScreen.Choice.CHASE_ONLINE:
		await _press(JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_A)
	await _press(JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_A)
	assert_has(screen.shown_texts(), "ADDRESS OF THE HOST", "JOIN asks for the address")

	# Up from nothing gives 0, then 1, 2...; down from nothing gives :, then the dot.
	var ups: Dictionary[String, int] = {"0": 1, "1": 2, "2": 3, "7": 8}
	var typed: String = "127.0.0.1"
	for index: int in typed.length():
		var character: String = typed[index]
		if character == ".":
			await _press(JOY_BUTTON_DPAD_DOWN)
			await _press(JOY_BUTTON_DPAD_DOWN)
		else:
			for up: int in ups[character]:
				await _press(JOY_BUTTON_DPAD_UP)
		if index < typed.length() - 1:
			await _press(JOY_BUTTON_DPAD_RIGHT)
	var field: AddressField = screen.get_node("%AddressField") as AddressField
	assert_eq(field.address, typed, "composed on the pad")
	await _press(JOY_BUTTON_A)
	await _steps(1)

	assert_has(_network.calls, "join %s:%d" % [typed, NetLink.DEFAULT_PORT], "joins it")
	assert_has(screen.shown_texts(), "CONNECTING…", "and says so")


func _fake(version: String) -> Callable:
	return func() -> NetLink: return FakeLink.new(_network, version)


## A start screen and its lobby, making its links with `make_link`; the lobby closes its link
## as it goes.
func _add_lobby(make_link: Callable) -> OnlineLobby:
	var screen: StartScreen = SCREEN_SCENE.instantiate() as StartScreen
	add_child_autofree(screen)
	screen.open(true)
	var lobby: OnlineLobby = OnlineLobby.new()
	lobby.make_link = make_link
	lobby.session = Session.new()
	lobby.screen = screen
	add_child_autofree(lobby)
	return lobby


func _steps(count: int) -> void:
	for step: int in count:
		await get_tree().physics_frame


## Presses the gamepad button `button` for a few frames, then releases it, once the screen
## has been on screen for a frame: it ignores the frame it opens.
func _press(button: JoyButton) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame
	var release: InputEventJoypadButton = event.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	for frame: int in FRAMES:
		await get_tree().process_frame
