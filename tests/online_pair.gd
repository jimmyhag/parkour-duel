class_name OnlinePair
extends RefCounted
## Two machines of an online chase side by side in one test (docs/specs/online-chase.md):
## each one in a SubViewport with a World3D of its own, so that their arenas, their physics
## and their runners never meet; joined by fake links over one FakeNetwork, with the latency
## and the losses chosen, timed by the physics frames (1/60 s of game each, see ReplayTest).
## Either two chases (game/levels/chase.tscn) given their links once connected, or two games
## (Main) whose lobbies host and join as their start screens are told to.

const CHASE_SCENE: String = "res://game/levels/chase.tscn"
const MAIN_SCENE_SETTING: String = "application/run/main_scene"
const VERSION: String = "0.5.0"
## Who sends, in the calls of the network.
const HOST: String = "host"
const GUEST: String = "guest"
const ADDRESS: String = "127.0.0.1"
## The frames two links are given to connect, at most.
const CONNECT_FRAMES: int = 120

var network: FakeNetwork
var clock: FrameClock = FrameClock.new()
## The chase of the host and of the guest.
var host: Chase
var guest: Chase

var _test: GutTest


func _init(test: GutTest, latency_ms: int = 0, lose_every: int = 0) -> void:
	_test = test
	network = FakeNetwork.new(clock.read)
	network.latency_ms = latency_ms
	network.lose_every = lose_every


## Two chases joined, each in its world, every runner on `tuning` (none: the tuning of the
## project), those of the guest on `guest_tuning` if one is given, the match of the host
## started with `first_cat` its first cat.
func start_chases(
	tuning: MovementTuning = null,
	first_cat: int = Chase.PLAYER_ONE,
	guest_tuning: MovementTuning = null
) -> void:
	var hosting: NetLink = FakeLink.new(network, VERSION)
	var joining: NetLink = FakeLink.new(network, VERSION)
	hosting.host()
	joining.join(ADDRESS)
	for frame: int in CONNECT_FRAMES:
		if (
			hosting.state == LinkStatus.State.CONNECTED
			and joining.state == LinkStatus.State.CONNECTED
		):
			break
		await _test.get_tree().physics_frame
		hosting.poll()
		joining.poll()
	host = _add_chase(hosting)
	guest = _add_chase(joining)
	if tuning != null:
		for chase: Chase in [host, guest]:
			for runner: Player in chase.players:
				var given: bool = chase == guest and guest_tuning != null
				runner.apply_tuning(guest_tuning if given else tuning)
	if tuning != null or host.chase.first_cat != first_cat:
		host.rematch()
	if host.chase.first_cat != first_cat:
		host.rematch()


## A game (Main) in a world of its own, its links on the fake network.
func add_game() -> Main:
	var main_scene: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	var main: Main = (load(main_scene) as PackedScene).instantiate() as Main
	main.make_link = func() -> NetLink: return FakeLink.new(network, VERSION)
	_world().add_child(main)
	return main


## Waits a physics frame at a time until `done` says so, `most` frames at most; whether it
## did.
func until(done: Callable, most: int) -> bool:
	for frame: int in most:
		if done.call():
			return true
		await _test.get_tree().physics_frame
	return done.call()


## Waits until both machines play a round.
func until_go() -> bool:
	return await until(
		func() -> bool:
			return (
				host.chase.phase == ChaseState.Phase.RUNNING
				and guest.chase.phase == ChaseState.Phase.RUNNING
			),
		600
	)


func _add_chase(link: NetLink) -> Chase:
	var chase: Chase = (load(CHASE_SCENE) as PackedScene).instantiate() as Chase
	chase.link = link
	_world().add_child(chase)
	return chase


## A SubViewport with a World3D of its own, freed after the test.
func _world() -> SubViewport:
	var world: SubViewport = SubViewport.new()
	world.own_world_3d = true
	world.size = Vector2i(64, 64)
	_test.add_child_autofree(world)
	return world
