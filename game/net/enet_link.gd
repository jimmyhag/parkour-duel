class_name ENetLink
extends NetLink
## The real adapter of the link (NetLink): UDP, through ENet (ENetConnection), straight from
## one machine to the other, with no server between them. The messages go on a channel
## where they arrive, in order; the snapshots on another, at once, unsequenced. A port taken
## by another program is found by trying to bind it first, so that ENet is never asked to
## open a port it cannot; an address is joined only once it reads as one: neither ever
## pushes an error.

## The channels: the messages, and the snapshots.
const RELIABLE_CHANNEL: int = 0
const SNAPSHOT_CHANNEL: int = 1
const CHANNELS: int = 2
## The machines a host lets connect at once: the other player, and those it refuses.
const MOST_PEERS: int = 4
## Every interface of the machine.
const EVERY_INTERFACE: String = "*"

## The interface it hosts and joins from: every one, or one address (127.0.0.1 in the
## tests).
var bind_address: String = EVERY_INTERFACE

var _connection: ENetConnection = null
var _peers: Dictionary[int, ENetPacketPeer] = {}
var _next_peer: int = 1


## A link of the game of version `version`, timed by `clock` (a function giving ms), from
## the interface `interface`.
func _init(version: String, clock: Callable, interface: String = EVERY_INTERFACE) -> void:
	super(version, clock)
	bind_address = interface


func _open_host(port: int) -> LinkStatus.Failure:
	var probe: PacketPeerUDP = PacketPeerUDP.new()
	var free: bool = probe.bind(port, bind_address) == OK
	probe.close()
	if not free:
		return LinkStatus.Failure.PORT_ALREADY_IN_USE
	_connection = ENetConnection.new()
	if _connection.create_host_bound(bind_address, port, MOST_PEERS, CHANNELS) != OK:
		_connection = null
		return LinkStatus.Failure.PORT_ALREADY_IN_USE
	return LinkStatus.Failure.NONE


func _open_join(ip: String, port: int) -> LinkStatus.Failure:
	_connection = ENetConnection.new()
	var created: Error = OK
	if bind_address == EVERY_INTERFACE:
		created = _connection.create_host(1, CHANNELS)
	else:
		created = _connection.create_host_bound(bind_address, 0, 1, CHANNELS)
	if created != OK:
		_connection = null
		return LinkStatus.Failure.COULD_NOT_CONNECT
	var peer: ENetPacketPeer = _connection.connect_to_host(ip, port, CHANNELS)
	if peer == null:
		_shut()
		return LinkStatus.Failure.COULD_NOT_CONNECT
	_number(peer)
	return LinkStatus.Failure.NONE


func _pump() -> Array[NetLink.Happened]:
	var found: Array[NetLink.Happened] = []
	while _connection != null:
		var event: Array = _connection.service(0)
		var type: int = event[0]
		if type == ENetConnection.EVENT_NONE or type == ENetConnection.EVENT_ERROR:
			break
		var peer: ENetPacketPeer = event[1]
		var number: int = _number(peer)
		var bytes: PackedByteArray = PackedByteArray()
		if type == ENetConnection.EVENT_CONNECT:
			found.append(NetLink.Happened.new(NetLink.Happening.CONNECTED, number, bytes))
		elif type == ENetConnection.EVENT_DISCONNECT:
			_peers.erase(number)
			found.append(NetLink.Happened.new(NetLink.Happening.DISCONNECTED, number, bytes))
		elif type == ENetConnection.EVENT_RECEIVE:
			bytes = peer.get_packet()
			found.append(NetLink.Happened.new(NetLink.Happening.RECEIVED, number, bytes))
	return found


func _send_raw(peer: int, bytes: PackedByteArray, reliable: bool) -> void:
	var to: ENetPacketPeer = _peers.get(peer)
	if to == null or to.get_state() != ENetPacketPeer.STATE_CONNECTED:
		return
	if reliable:
		to.send(RELIABLE_CHANNEL, bytes, ENetPacketPeer.FLAG_RELIABLE)
	else:
		to.send(SNAPSHOT_CHANNEL, bytes, ENetPacketPeer.FLAG_UNSEQUENCED)
	_connection.flush()


func _drop(peer: int) -> void:
	var to: ENetPacketPeer = _peers.get(peer)
	_peers.erase(peer)
	if to != null and to.get_state() == ENetPacketPeer.STATE_CONNECTED:
		to.peer_disconnect_later()
		_connection.flush()


func _shut() -> void:
	if _connection == null:
		return
	for peer: ENetPacketPeer in _peers.values():
		if peer.get_state() == ENetPacketPeer.STATE_CONNECTED:
			peer.peer_disconnect_later()
	_connection.flush()
	_connection.destroy()
	_connection = null
	_peers.clear()


## The number of `peer`, given the first time it is seen.
func _number(peer: ENetPacketPeer) -> int:
	for number: int in _peers:
		if _peers[number] == peer:
			return number
	var number: int = _next_peer
	_next_peer += 1
	_peers[number] = peer
	return number
