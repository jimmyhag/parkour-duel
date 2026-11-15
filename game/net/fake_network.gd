class_name FakeNetwork
extends RefCounted
## The network the fake links of the tests (FakeLink) are joined by, deterministic: its clock
## is given (in ms); every packet and every connection arrives after the latency it has when
## it is sent, in the order sent; the packets sent at once (the snapshots) are lost as
## chosen, one in `lose_every`; a port may be taken as another program would; every call is
## recorded. Every address reaches the hosts of the network by their port alone, as on one
## home network.


## Something on its way to a link, arriving at `at` (ms).
class Flight:
	extends RefCounted

	var at: int
	var to: NetLink
	var happened: NetLink.Happened

	func _init(arrival: int, link: NetLink, what: NetLink.Happened) -> void:
		at = arrival
		to = link
		happened = what


## How long anything takes to arrive, in ms.
var latency_ms: int = 0
## One packet sent at once in this many is lost; 0: none.
var lose_every: int = 0
## Every call, in order: "host <port>", "join <address>:<port>", "send <peer> <size>
## reliable|at once", "drop <peer>", "leave".
var calls: Array[String] = []

var _clock: Callable
var _hosts: Dictionary[int, NetLink] = {}
var _taken: Dictionary[int, bool] = {}
## The two ends of each connection, by its number.
var _host_ends: Dictionary[int, NetLink] = {}
var _guest_ends: Dictionary[int, NetLink] = {}
var _next_connection: int = 1
var _sent_at_once: int = 0
var _in_flight: Array[Flight] = []


## A network timed by `clock` (a function giving ms).
func _init(clock: Callable) -> void:
	_clock = clock


func now() -> int:
	var time: int = _clock.call()
	return time


## Another program holds `port`: nobody may host on it.
func take_port(port: int) -> void:
	_taken[port] = true


## `link` hosts on `port`, unless the port is held; whether it does.
func open_host(link: NetLink, port: int) -> bool:
	calls.append("host %d" % port)
	if _taken.has(port) or _hosts.has(port):
		return false
	_hosts[port] = link
	return true


## `link` joins whoever hosts on `port`: both learn of the connection, the host after the
## latency, the guest after twice that. Nobody hosting, nothing comes.
func join(link: NetLink, ip: String, port: int) -> void:
	calls.append("join %s:%d" % [ip, port])
	var host: NetLink = _hosts.get(port)
	if host == null:
		return
	var connection: int = _next_connection
	_next_connection += 1
	_host_ends[connection] = host
	_guest_ends[connection] = link
	var none: PackedByteArray = PackedByteArray()
	_fly(host, NetLink.Happened.new(NetLink.Happening.CONNECTED, connection, none), latency_ms)
	_fly(link, NetLink.Happened.new(NetLink.Happening.CONNECTED, connection, none), 2 * latency_ms)


## `link` sends `bytes` over its connection `connection`; sent at once, it may be lost.
func send(link: NetLink, connection: int, bytes: PackedByteArray, reliable: bool) -> void:
	calls.append(
		"send %d %d %s" % [connection, bytes.size(), "reliable" if reliable else "at once"]
	)
	var other: NetLink = _other_end(link, connection)
	if other == null:
		return
	if not reliable:
		_sent_at_once += 1
		if lose_every > 0 and _sent_at_once % lose_every == 0:
			return
	_fly(other, NetLink.Happened.new(NetLink.Happening.RECEIVED, connection, bytes), latency_ms)


## `link` lets its connection `connection` go: the other end learns it after what was sent.
func drop(link: NetLink, connection: int) -> void:
	calls.append("drop %d" % connection)
	var other: NetLink = _other_end(link, connection)
	_host_ends.erase(connection)
	_guest_ends.erase(connection)
	if other != null:
		var none: PackedByteArray = PackedByteArray()
		var gone: NetLink.Happened = NetLink.Happened.new(
			NetLink.Happening.DISCONNECTED, connection, none
		)
		_fly(other, gone, latency_ms)


## `link` closes: its connections go, its port is free, nothing more arrives to it.
func leave(link: NetLink) -> void:
	calls.append("leave")
	for connection: int in _host_ends.keys():
		if _host_ends.get(connection) == link or _guest_ends.get(connection) == link:
			drop(link, connection)
	for port: int in _hosts.keys():
		if _hosts[port] == link:
			_hosts.erase(port)
	_in_flight = _in_flight.filter(func(flight: Flight) -> bool: return flight.to != link)


## `bytes` arrive at `link` at once, as if its other player had sent them: what a test makes
## of a packet from the network.
func inject(link: NetLink, bytes: PackedByteArray) -> void:
	for connection: int in _host_ends.keys():
		if _host_ends[connection] == link or _guest_ends[connection] == link:
			var received: NetLink.Happened = NetLink.Happened.new(
				NetLink.Happening.RECEIVED, connection, bytes
			)
			_fly(link, received, 0)
			return


## What has arrived at `link` by now, in order.
func arrived(link: NetLink) -> Array[NetLink.Happened]:
	var found: Array[NetLink.Happened] = []
	var left: Array[Flight] = []
	var time: int = now()
	for flight: Flight in _in_flight:
		if flight.to == link and flight.at <= time:
			found.append(flight.happened)
		else:
			left.append(flight)
	_in_flight = left
	return found


## `happened` arrives at `link` after `delay` ms, never before what was sent to it earlier.
func _fly(link: NetLink, happened: NetLink.Happened, delay: int) -> void:
	var at: int = now() + delay
	for flight: Flight in _in_flight:
		if flight.to == link:
			at = maxi(at, flight.at)
	_in_flight.append(Flight.new(at, link, happened))


func _other_end(link: NetLink, connection: int) -> NetLink:
	if _host_ends.get(connection) == link:
		return _guest_ends.get(connection)
	if _guest_ends.get(connection) == link:
		return _host_ends.get(connection)
	return null
