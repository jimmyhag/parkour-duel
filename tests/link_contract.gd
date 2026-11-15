class_name LinkContract
extends RefCounted
## The contract suite of the link of an online chase (NetLink, docs/specs/online-chase.md,
## decision 14), one suite for every adapter: ENet on this machine (127.0.0.1), or the fake
## network. Two links connect, exchange messages and snapshots both ways, measure the ping;
## the guest leaving, or going silent for 3 s, is the other player gone; a port taken, an
## address where nobody hosts (5 s), another version, a third player are the same typed
## failures; machines that connect and never tell their version are let go after 5 s, and do
## not keep the friend out. The clock of the links is the suite's own, moved on by 1 ms per
## poll, and as far as a test needs at once; ENet runs in real time beside it.

enum Adapter { ENET, FAKE }

const VERSION: String = "1.0.0"
const OTHER_VERSION: String = "1.0.1"
## The ports of the suite, away from the port of the game.
const PORT: int = 24690
const NOBODY_PORT: int = 24691
const TAKEN_PORT: int = 24692
## The polls a step of the suite may take at most.
const MOST_POLLS: int = 1000
## The polls that let what is on its way arrive.
const SETTLING_POLLS: int = 50
## A silence well under 3 s, in ms.
const SHORT_SILENCE: int = 1000
const LOCAL: String = "127.0.0.1"

var adapter: Adapter
## The clock of the links.
var clock: ManualClock = ManualClock.new()

var _test: GutTest
var _network: FakeNetwork
var _links: Array[NetLink] = []
var _taken: PacketPeerUDP = null
## Machines that connect to the host and never say a word: raw ENet hosts, or fake links
## never polled.
var _enet_strangers: Array[ENetConnection] = []
var _fake_strangers: Array[NetLink] = []


func _init(test: GutTest, kind: Adapter) -> void:
	_test = test
	adapter = kind
	_network = FakeNetwork.new(clock.read)
	_network.latency_ms = 20


## A new link of the adapter, of the game of version `version`.
func link(version: String = VERSION) -> NetLink:
	var made: NetLink
	if adapter == Adapter.ENET:
		made = ENetLink.new(version, clock.read, LOCAL)
	else:
		made = FakeLink.new(_network, version)
	_links.append(made)
	return made


## Polls every link, 1 ms later each time, until `done` says so; whether it did. Never done,
## it lets what is on its way arrive.
func until(done: Callable, most: int = MOST_POLLS) -> bool:
	for poll: int in most:
		if done.call():
			return true
		clock.ms += 1
		if adapter == Adapter.ENET:
			OS.delay_msec(1)
		for stranger: ENetConnection in _enet_strangers:
			_service(stranger)
		for each: NetLink in _links:
			each.poll()
	return done.call()


## A host and a guest connected.
func pair() -> Array[NetLink]:
	var host: NetLink = link()
	var guest: NetLink = link()
	_test.assert_eq(host.host(PORT), LinkStatus.Failure.NONE, "the host opens its port")
	_test.assert_eq(host.state, LinkStatus.State.WAITING, "and waits")
	_test.assert_eq(guest.join("%s:%d" % [LOCAL, PORT]), LinkStatus.Failure.NONE, "joins")
	_test.assert_eq(guest.state, LinkStatus.State.CONNECTING, "and connects")
	var connected: bool = until(
		func() -> bool:
			return (
				host.state == LinkStatus.State.CONNECTED
				and guest.state == LinkStatus.State.CONNECTED
			)
	)
	_test.assert_true(connected, "both connected")
	return [host, guest]


## Every link closed, the port taken let go.
func close_all() -> void:
	for each: NetLink in _links:
		each.close()
	_links.clear()
	if _taken != null:
		_taken.close()
		_taken = null
	for stranger: ENetConnection in _enet_strangers:
		stranger.destroy()
	_enet_strangers.clear()
	for stranger: NetLink in _fake_strangers:
		stranger.close()
	_fake_strangers.clear()


func run() -> void:
	_connects_and_exchanges()
	close_all()
	_silence_is_the_other_player_gone()
	close_all()
	_the_failures_are_typed()
	close_all()
	_silent_strangers_are_let_go()
	close_all()


func _connects_and_exchanges() -> void:
	var pair_made: Array[NetLink] = pair()
	var host: NetLink = pair_made[0]
	var guest: NetLink = pair_made[1]
	_test.assert_true(host.hosting, "the host hosts")
	_test.assert_false(guest.hosting, "the guest does not")

	host.send_message(OnlineMessage.match_start(0, 0, 16.0, 3))
	host.send_message(OnlineMessage.countdown(7))
	host.send_message(OnlineMessage.of_chase(ChaseMessage.start(187)))
	guest.send_message(OnlineMessage.of_chase(ChaseMessage.catch(300, 1, Tag.Gesture.DIVE)))
	var snapshot: RunnerSnapshot = RunnerSnapshot.new()
	snapshot.step = 42
	snapshot.position = Vector3(1.5, 0.0, -2.0)
	snapshot.capsule_height = 1.8
	snapshot.animation.clip = RunnerAnimation.Clip.RUNNING_JUMP
	guest.send_snapshot(snapshot)
	host.send_snapshot(snapshot)
	var to_guest: Array[OnlineMessage] = []
	var to_host: Array[OnlineMessage] = []
	var seen_by: Array[Array] = [[], []]
	until(
		func() -> bool:
			to_guest.append_array(guest.take_messages())
			to_host.append_array(host.take_messages())
			seen_by[0].append_array(host.take_snapshots())
			seen_by[1].append_array(guest.take_snapshots())
			return (
				to_guest.size() == 3
				and to_host.size() == 1
				and not seen_by[0].is_empty()
				and not seen_by[1].is_empty()
			)
	)
	_test.assert_eq(to_guest.size(), 3, "the messages of the host arrive")
	if to_guest.size() == 3:
		_test.assert_eq(to_guest[0].kind, OnlineMessage.Kind.MATCH, "in order: the match")
		_test.assert_eq(to_guest[0].round_time, 16.0, "the time of its rounds")
		_test.assert_eq(to_guest[0].rounds_to_win, 3, "the rounds to win")
		_test.assert_eq(to_guest[1].step, 7, "the countdown, dated")
		_test.assert_eq(to_guest[2].chase.kind, ChaseMessage.Kind.START, "the start")
		_test.assert_eq(to_guest[2].chase.step, 187, "dated")
	_test.assert_eq(to_host.size(), 1, "and the one of the guest")
	if to_host.size() == 1:
		_test.assert_eq(to_host[0].chase.gesture, Tag.Gesture.DIVE, "with its gesture")
		_test.assert_eq(to_host[0].chase.player, 1, "and its player")
	for seen: Array in seen_by:
		_test.assert_eq(seen.size(), 1, "the snapshot arrives")
		if seen.size() == 1:
			var arrived: RunnerSnapshot = seen[0]
			_test.assert_eq(arrived.step, 42, "dated")
			_test.assert_eq(arrived.position, snapshot.position, "the place")
			_test.assert_eq(arrived.animation.clip, RunnerAnimation.Clip.RUNNING_JUMP, "the clip")

	var measured: bool = until(func() -> bool: return host.ping_ms() >= 0 and guest.ping_ms() >= 0)
	_test.assert_true(measured, "each measures the ping")

	guest.close()
	_test.assert_eq(guest.state, LinkStatus.State.CLOSED, "the guest leaves")
	until(func() -> bool: return host.state == LinkStatus.State.FAILED)
	_test.assert_eq(host.failure, LinkStatus.Failure.THE_OTHER_PLAYER_LEFT, "the host sees it")


func _silence_is_the_other_player_gone() -> void:
	var pair_made: Array[NetLink] = pair()
	var host: NetLink = pair_made[0]
	until(func() -> bool: return false, SETTLING_POLLS)
	# From now on the guest polls no more: it sends nothing.
	clock.ms += SHORT_SILENCE
	host.poll()
	_test.assert_eq(host.state, LinkStatus.State.CONNECTED, "a silence under 3 s is nothing")
	clock.ms += NetLink.SILENCE_TIMEOUT_MS
	host.poll()
	_test.assert_eq(host.state, LinkStatus.State.FAILED, "3 s of silence")
	_test.assert_eq(host.failure, LinkStatus.Failure.THE_OTHER_PLAYER_LEFT, "the other is gone")


func _the_failures_are_typed() -> void:
	_take(TAKEN_PORT)
	var on_taken: NetLink = link()
	var taken: LinkStatus.Failure = on_taken.host(TAKEN_PORT)
	_test.assert_eq(taken, LinkStatus.Failure.PORT_ALREADY_IN_USE, "a port taken")
	_test.assert_eq(on_taken.state, LinkStatus.State.FAILED, "fails at once")

	var alone: NetLink = link()
	alone.join("%s:%d" % [LOCAL, NOBODY_PORT])
	clock.ms += NetLink.CONNECT_TIMEOUT_MS - 10
	alone.poll()
	_test.assert_eq(alone.state, LinkStatus.State.CONNECTING, "nobody answers yet")
	clock.ms += 10
	alone.poll()
	_test.assert_eq(alone.failure, LinkStatus.Failure.COULD_NOT_CONNECT, "nobody in 5 s")
	_test.assert_eq(link().join("12.3"), LinkStatus.Failure.COULD_NOT_CONNECT, "no address")

	var host: NetLink = link()
	var other_version: NetLink = link(OTHER_VERSION)
	host.host(PORT)
	other_version.join(LOCAL + ":%d" % PORT)
	until(func() -> bool: return other_version.state == LinkStatus.State.FAILED)
	until(func() -> bool: return host.failure != LinkStatus.Failure.NONE)
	var refused: LinkStatus.Failure = LinkStatus.Failure.DIFFERENT_GAME_VERSION
	_test.assert_eq(other_version.failure, refused, "another version is refused")
	_test.assert_eq(host.failure, refused, "the host says why")
	_test.assert_eq(host.state, LinkStatus.State.WAITING, "and waits on")

	var guest: NetLink = link()
	guest.join(LOCAL + ":%d" % PORT)
	until(func() -> bool: return guest.state == LinkStatus.State.CONNECTED)
	var third: NetLink = link()
	third.join(LOCAL + ":%d" % PORT)
	until(func() -> bool: return third.state == LinkStatus.State.FAILED)
	_test.assert_eq(third.failure, LinkStatus.Failure.COULD_NOT_CONNECT, "a third is refused")
	_test.assert_eq(host.state, LinkStatus.State.CONNECTED, "the host plays on")
	_test.assert_eq(guest.state, LinkStatus.State.CONNECTED, "with its guest")


## Another program holds `port`.
func _take(port: int) -> void:
	if adapter == Adapter.FAKE:
		_network.take_port(port)
		return
	_taken = PacketPeerUDP.new()
	_test.assert_eq(_taken.bind(port, LOCAL), OK, "another program takes the port")


## As many machines as the host has places connect and say nothing: after 5 s they are let
## go, and the friend joins.
func _silent_strangers_are_let_go() -> void:
	var host: NetLink = link()
	host.host(PORT)
	for stranger: int in ENetLink.MOST_PEERS:
		if adapter == Adapter.ENET:
			var raw: ENetConnection = ENetConnection.new()
			raw.create_host_bound(LOCAL, 0, 1, ENetLink.CHANNELS)
			raw.connect_to_host(LOCAL, PORT, ENetLink.CHANNELS)
			_enet_strangers.append(raw)
		else:
			var silent: NetLink = FakeLink.new(_network, VERSION)
			silent.join("%s:%d" % [LOCAL, PORT])
			_fake_strangers.append(silent)
	until(func() -> bool: return false, SETTLING_POLLS)
	clock.ms += NetLink.CONNECT_TIMEOUT_MS
	until(func() -> bool: return false, SETTLING_POLLS)

	var friend: NetLink = link()
	friend.join("%s:%d" % [LOCAL, PORT])
	var joined: bool = until(func() -> bool: return friend.state == LinkStatus.State.CONNECTED)
	_test.assert_true(joined, "silent strangers let go, the friend joins")
	_test.assert_eq(host.state, LinkStatus.State.CONNECTED, "the host plays with it")


## Lets a raw ENet host shuttle what comes and goes, saying nothing.
func _service(raw: ENetConnection) -> void:
	for event: int in MOST_POLLS:
		var happened: Array = raw.service(0)
		var type: int = happened[0]
		if type == ENetConnection.EVENT_NONE or type == ENetConnection.EVENT_ERROR:
			return
