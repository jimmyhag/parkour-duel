class_name FakeLink
extends NetLink
## The fake adapter of the link (NetLink), deterministic, for the tests: it carries its bytes
## over a FakeNetwork, whose clock it shares, with the latency and the losses chosen there,
## every call recorded there.

var network: FakeNetwork


## A link of the game of version `version` on `on`.
func _init(on: FakeNetwork, version: String) -> void:
	super(version, on.now)
	network = on


func _open_host(port: int) -> LinkStatus.Failure:
	if not network.open_host(self, port):
		return LinkStatus.Failure.PORT_ALREADY_IN_USE
	return LinkStatus.Failure.NONE


func _open_join(ip: String, port: int) -> LinkStatus.Failure:
	network.join(self, ip, port)
	return LinkStatus.Failure.NONE


func _pump() -> Array[NetLink.Happened]:
	return network.arrived(self)


func _send_raw(peer: int, bytes: PackedByteArray, reliable: bool) -> void:
	network.send(self, peer, bytes, reliable)


func _drop(peer: int) -> void:
	network.drop(self, peer)


func _shut() -> void:
	network.leave(self)
