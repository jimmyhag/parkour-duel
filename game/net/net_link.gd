class_name NetLink
extends RefCounted
## The contract of the link of an online chase to the other machine
## (docs/specs/online-chase.md, decision 14), written with the types of game/core: host on a
## port, or join an address; send a message of the match (OnlineMessage, so that it arrives,
## in order) or a snapshot of the runner (RunnerSnapshot, at once, lost if it must be); take
## what arrived; the state of the link (LinkStatus) and the ping; close. The expected
## failures are a typed result (LinkStatus.Failure), never a crash or an error.
## The protocol is the same over every transport, here: as it connects, each machine tells
## the other the version of the protocol and of the game, and either refuses a different
## one; the host refuses a third player, and lets go a machine that tells no version within
## CONNECT_TIMEOUT_MS (silent strangers would fill its places); a link that hears nothing
## from the other for
## SILENCE_TIMEOUT_MS, or a join that has no answer in CONNECT_TIMEOUT_MS, fails. Every
## packet that arrives is read as plain numbers and checked: a packet too short, of a kind
## unknown, out of its range, or from a machine that is not the other player, is ignored.
## The adapters (ENetLink, the real one; FakeLink, deterministic, for the tests) only carry
## the bytes, through the methods whose names start with an underscore. The time is the one
## of the clock given (in ms).

## The kinds of packets: the protocol's own, then a message and a snapshot.
enum Packet { HELLO = 1, REFUSE, BYE, PING, PONG, MESSAGE, SNAPSHOT }
## Why the host refuses a player.
enum Refusal { VERSION = 1, FULL }
## What a transport tells: a machine connected, sent bytes, or disconnected.
enum Happening { CONNECTED, RECEIVED, DISCONNECTED }

const DEFAULT_PORT: int = 24680
const PROTOCOL_VERSION: int = 1
## How long a join waits for an answer, and how long a link hears nothing before the other
## player is gone, in ms.
const CONNECT_TIMEOUT_MS: int = 5000
const SILENCE_TIMEOUT_MS: int = 3000
## How often each machine measures the ping, in ms.
const PING_INTERVAL_MS: int = 500
## The longest version of the game told, in bytes.
const LONGEST_VERSION: int = 64
## A machine that is not there.
const NO_PEER: int = -1
## The lowest and the highest port.
const LOWEST_PORT: int = 1
const HIGHEST_PORT: int = 65535


## One thing a transport tells, about one machine at the other end, which it numbers.
class Happened:
	extends RefCounted

	var what: Happening
	var peer: int
	var bytes: PackedByteArray

	func _init(happening: Happening, from_peer: int, received: PackedByteArray) -> void:
		what = happening
		peer = from_peer
		bytes = received


var state: LinkStatus.State = LinkStatus.State.CLOSED
## Why it failed; while it hosts, why it refused the last player that came.
var failure: LinkStatus.Failure = LinkStatus.Failure.NONE
## It hosts: its machine is the server, and player 1.
var hosting: bool = false
## The version of the game of this machine.
var game_version: String

## The clock, in ms.
var _clock: Callable
## The other player, once it is known; the host the guest joins.
var _other: int = NO_PEER
var _joined_at: int = 0
var _last_heard: int = 0
var _last_ping: int = 0
var _ping: int = -1
## The host's machines connected that have not told their versions yet, with when they
## connected (ms): let go once a join would have given up on them.
var _unknown: Dictionary[int, int] = {}
var _messages: Array[OnlineMessage] = []
var _snapshots: Array[RunnerSnapshot] = []


## A link of the game of version `version`, timed by `clock` (a function giving ms).
func _init(version: String, clock: Callable) -> void:
	game_version = version
	_clock = clock


## Opens the port `port` to host: WAITING, or the failure.
func host(port: int = DEFAULT_PORT) -> LinkStatus.Failure:
	hosting = true
	var opened: LinkStatus.Failure = _open_host(port)
	if opened != LinkStatus.Failure.NONE:
		return _fail(opened)
	state = LinkStatus.State.WAITING
	failure = LinkStatus.Failure.NONE
	return opened


## Joins the host at `address`, an IPv4 address with a port or not ("192.168.1.20",
## "86.12.3.4:24680"): CONNECTING, or the failure (an address that cannot be read is one
## nobody answers at).
func join(address: String) -> LinkStatus.Failure:
	hosting = false
	var ip: String = address.strip_edges()
	var port: int = DEFAULT_PORT
	var colon: int = ip.rfind(":")
	if colon >= 0:
		var port_text: String = ip.substr(colon + 1)
		ip = ip.substr(0, colon)
		port = port_text.to_int() if port_text.is_valid_int() else 0
	if port < LOWEST_PORT or port > HIGHEST_PORT or ip.contains(":"):
		return _fail(LinkStatus.Failure.COULD_NOT_CONNECT)
	if not ip.is_valid_ip_address():
		return _fail(LinkStatus.Failure.COULD_NOT_CONNECT)
	var opened: LinkStatus.Failure = _open_join(ip, port)
	if opened != LinkStatus.Failure.NONE:
		return _fail(opened)
	state = LinkStatus.State.CONNECTING
	_joined_at = _now()
	return opened


## Everything that arrived since the last poll, and what time says: the handshake, the
## refusals, the ping, the other player gone or silent, a join without an answer.
func poll() -> void:
	if state == LinkStatus.State.CLOSED or state == LinkStatus.State.FAILED:
		return
	for happened: Happened in _pump():
		_follow(happened)
		if state == LinkStatus.State.FAILED:
			return
	var now: int = _now()
	for peer: int in _unknown.keys():
		if now - _unknown[peer] >= CONNECT_TIMEOUT_MS:
			_unknown.erase(peer)
			_drop(peer)
	if state == LinkStatus.State.CONNECTING and now - _joined_at >= CONNECT_TIMEOUT_MS:
		_shut()
		_fail(LinkStatus.Failure.COULD_NOT_CONNECT)
	elif state == LinkStatus.State.CONNECTED:
		if now - _last_heard >= SILENCE_TIMEOUT_MS:
			_shut()
			_fail(LinkStatus.Failure.THE_OTHER_PLAYER_LEFT)
		elif now - _last_ping >= PING_INTERVAL_MS:
			_last_ping = now
			_send_packet(Packet.PING, _u32(now), false)


## Sends `message` to the other player, to arrive, in order.
func send_message(message: OnlineMessage) -> void:
	if state == LinkStatus.State.CONNECTED:
		_send_packet(Packet.MESSAGE, message.encode(), true)


## Sends `snapshot` to the other player, at once, lost if it must be.
func send_snapshot(snapshot: RunnerSnapshot) -> void:
	if state == LinkStatus.State.CONNECTED:
		_send_packet(Packet.SNAPSHOT, snapshot.encode(), false)


## The messages arrived since the last time, in their order.
func take_messages() -> Array[OnlineMessage]:
	var taken: Array[OnlineMessage] = _messages
	_messages = []
	return taken


## The snapshots arrived since the last time, in the order they arrived.
func take_snapshots() -> Array[RunnerSnapshot]:
	var taken: Array[RunnerSnapshot] = _snapshots
	_snapshots = []
	return taken


## The time of the last round trip to the other machine, in ms; -1 before the first.
func ping_ms() -> int:
	return _ping


## Leaves: the other player is told, and everything closes.
func close() -> void:
	if state == LinkStatus.State.CLOSED:
		return
	if _other != NO_PEER:
		_send_raw(_other, PackedByteArray([Packet.BYE]), true)
	_shut()
	_other = NO_PEER
	state = LinkStatus.State.CLOSED


## The IPv4 addresses of this machine on the networks it is on (the home network), without
## the loopback and the addresses a machine gives itself without a network.
static func local_addresses() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for address: String in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		found.append(address)
	found.sort()
	return found


## What one happening at the transport means.
func _follow(happened: Happened) -> void:
	match happened.what:
		Happening.CONNECTED:
			_on_connected(happened.peer)
		Happening.DISCONNECTED:
			_on_disconnected(happened.peer)
		Happening.RECEIVED:
			_on_received(happened.peer, happened.bytes)


func _on_connected(peer: int) -> void:
	if hosting:
		if _other != NO_PEER:
			_refuse(peer, Refusal.FULL)
		else:
			_unknown[peer] = _now()
		return
	if state == LinkStatus.State.CONNECTING:
		_other = peer
		_send_raw(peer, _hello(), true)


func _on_disconnected(peer: int) -> void:
	_unknown.erase(peer)
	if peer != _other:
		return
	_other = NO_PEER
	if state == LinkStatus.State.CONNECTED:
		_shut()
		_fail(LinkStatus.Failure.THE_OTHER_PLAYER_LEFT)
	elif state == LinkStatus.State.CONNECTING:
		_shut()
		_fail(LinkStatus.Failure.COULD_NOT_CONNECT)


func _on_received(peer: int, bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		return
	var kind: int = bytes[0]
	var payload: PackedByteArray = bytes.slice(1)
	if kind == Packet.HELLO:
		_on_hello(peer, payload)
	elif peer != _other:
		return
	elif kind == Packet.REFUSE and state == LinkStatus.State.CONNECTING:
		_on_refused(payload)
	elif kind == Packet.BYE and state == LinkStatus.State.CONNECTED:
		_shut()
		_fail(LinkStatus.Failure.THE_OTHER_PLAYER_LEFT)
	elif state == LinkStatus.State.CONNECTED and _read(kind, payload):
		_last_heard = _now()


## Reads a packet of the game from the other player: whether it was one, well formed.
func _read(kind: int, payload: PackedByteArray) -> bool:
	match kind:
		Packet.PING:
			if payload.size() != 4:
				return false
			_send_packet(Packet.PONG, payload, false)
		Packet.PONG:
			if payload.size() != 4 or payload.decode_u32(0) > _now():
				return false
			_ping = _now() - payload.decode_u32(0)
		Packet.MESSAGE:
			var message: OnlineMessage = OnlineMessage.decode(payload)
			if message == null:
				return false
			_messages.append(message)
		Packet.SNAPSHOT:
			var snapshot: RunnerSnapshot = RunnerSnapshot.decode(payload)
			if snapshot == null:
				return false
			_snapshots.append(snapshot)
		_:
			return false
	return true


## The other machine tells its versions: the host takes it as the other player, or refuses
## it; the guest is connected, or refuses the host.
func _on_hello(peer: int, payload: PackedByteArray) -> void:
	if payload.size() < 3 or payload.size() - 3 != payload[2] or payload[2] > LONGEST_VERSION:
		return
	var same: bool = (
		payload.decode_u16(0) == PROTOCOL_VERSION and payload.slice(3) == _version_bytes()
	)
	if hosting:
		_unknown.erase(peer)
		if state != LinkStatus.State.WAITING or _other != NO_PEER:
			if peer != _other:
				_refuse(peer, Refusal.FULL)
			return
		if not same:
			_refuse(peer, Refusal.VERSION)
			failure = LinkStatus.Failure.DIFFERENT_GAME_VERSION
			return
		_other = peer
		_send_raw(peer, _hello(), true)
		_connect()
	elif peer == _other and state == LinkStatus.State.CONNECTING:
		if not same:
			_shut()
			_fail(LinkStatus.Failure.DIFFERENT_GAME_VERSION)
			return
		_connect()


func _on_refused(payload: PackedByteArray) -> void:
	_shut()
	if payload.size() == 1 and payload[0] == Refusal.VERSION:
		_fail(LinkStatus.Failure.DIFFERENT_GAME_VERSION)
	else:
		_fail(LinkStatus.Failure.COULD_NOT_CONNECT)


func _connect() -> void:
	state = LinkStatus.State.CONNECTED
	failure = LinkStatus.Failure.NONE
	_last_heard = _now()
	_last_ping = _last_heard - PING_INTERVAL_MS


func _refuse(peer: int, why: Refusal) -> void:
	_send_raw(peer, PackedByteArray([Packet.REFUSE, why]), true)
	_drop(peer)


## The packet that tells the versions of this machine.
func _hello() -> PackedByteArray:
	var version: PackedByteArray = _version_bytes()
	var bytes: PackedByteArray = PackedByteArray([Packet.HELLO, 0, 0, version.size()])
	bytes.encode_u16(1, PROTOCOL_VERSION)
	bytes.append_array(version)
	return bytes


## The version of the game as it is told: its bytes, never read back as text.
func _version_bytes() -> PackedByteArray:
	return game_version.to_utf8_buffer().slice(0, LONGEST_VERSION)


func _send_packet(kind: Packet, payload: PackedByteArray, reliable: bool) -> void:
	if _other == NO_PEER:
		return
	var bytes: PackedByteArray = PackedByteArray([kind])
	bytes.append_array(payload)
	_send_raw(_other, bytes, reliable)


func _fail(why: LinkStatus.Failure) -> LinkStatus.Failure:
	state = LinkStatus.State.FAILED
	failure = why
	return why


func _now() -> int:
	var now: int = _clock.call()
	return now


static func _u32(value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, value)
	return bytes


## Of an adapter: opens `port` to host, or says why it cannot.
func _open_host(_port: int) -> LinkStatus.Failure:
	return LinkStatus.Failure.PORT_ALREADY_IN_USE


## Of an adapter: starts to join `ip` on `port`, or says why it cannot.
func _open_join(_ip: String, _port: int) -> LinkStatus.Failure:
	return LinkStatus.Failure.COULD_NOT_CONNECT


## Of an adapter: what happened at the transport since the last time, in order.
func _pump() -> Array[Happened]:
	return []


## Of an adapter: sends `bytes` to `peer`, to arrive or at once.
func _send_raw(_peer: int, _bytes: PackedByteArray, _reliable: bool) -> void:
	pass


## Of an adapter: lets `peer` go, once what was sent to it has gone.
func _drop(_peer: int) -> void:
	pass


## Of an adapter: closes everything.
func _shut() -> void:
	pass
