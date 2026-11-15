extends GutTest
## The link of an online chase (game/net, docs/specs/online-chase.md): the contract suite run
## against its two adapters (LinkContract), a third player refused while the game goes on,
## and what arrives from the network that is ignored, at the link and among the snapshots
## (SnapshotBuffer, game/core).

const PORT: int = LinkContract.PORT
const ADDRESS: String = "127.0.0.1:24690"

var _contract: LinkContract


func after_each() -> void:
	if _contract != null:
		_contract.close_all()
		_contract = null


func test_the_two_links_hold_the_same_contract() -> void:
	for adapter: LinkContract.Adapter in LinkContract.Adapter.values():
		_contract = LinkContract.new(self, adapter)
		_contract.run()
		_contract = null


func test_a_third_player_is_refused() -> void:
	_contract = LinkContract.new(self, LinkContract.Adapter.FAKE)
	var pair: Array[NetLink] = _contract.pair()
	var host: NetLink = pair[0]
	var guest: NetLink = pair[1]
	var third: NetLink = _contract.link()

	third.join(ADDRESS)
	_contract.until(func() -> bool: return third.state == LinkStatus.State.FAILED)

	assert_eq(third.failure, LinkStatus.Failure.COULD_NOT_CONNECT, "the third is refused")
	assert_eq(host.state, LinkStatus.State.CONNECTED, "the host plays on")
	host.send_message(OnlineMessage.countdown(12))
	var arrived: Array[OnlineMessage] = []
	_contract.until(
		func() -> bool:
			arrived.append_array(guest.take_messages())
			return not arrived.is_empty()
	)
	assert_eq(arrived.size(), 1, "with its guest")
	assert_eq(third.take_messages().size(), 0, "the third hears nothing of the game")


func test_a_malformed_packet_is_ignored() -> void:
	_contract = LinkContract.new(self, LinkContract.Adapter.FAKE)
	var pair: Array[NetLink] = _contract.pair()
	var host: FakeLink = pair[0] as FakeLink
	var guest: NetLink = pair[1]
	var network: FakeNetwork = host.network
	var good: RunnerSnapshot = _snapshot(10)
	var buffer: SnapshotBuffer = SnapshotBuffer.new()
	guest.send_snapshot(good)
	_contract.until(func() -> bool: return buffer.receive_all(host.take_snapshots()) > 0)
	buffer.show_next(0.0)

	var unreadable: PackedByteArray = PackedByteArray([NetLink.Packet.SNAPSHOT, 1, 2, 3])
	var unknown: PackedByteArray = PackedByteArray([200, 0, 0, 0, 0, 0, 0, 0, 0])
	var not_a_number: PackedByteArray = PackedByteArray([NetLink.Packet.SNAPSHOT])
	var poisoned: PackedByteArray = _snapshot(11).encode()
	poisoned.encode_float(4, NAN)
	not_a_number.append_array(poisoned)
	var absurd_message: PackedByteArray = PackedByteArray([NetLink.Packet.MESSAGE])
	absurd_message.append_array(OnlineMessage.countdown(OnlineMessage.LATEST_STEP + 1).encode())
	var older: PackedByteArray = PackedByteArray([NetLink.Packet.SNAPSHOT])
	older.append_array(_snapshot(9).encode())
	for bytes: PackedByteArray in [
		PackedByteArray(), unreadable, unknown, not_a_number, absurd_message, older
	]:
		network.inject(host, bytes)
	host.poll()

	assert_eq(host.take_messages().size(), 0, "no message made of them")
	var arrived: Array[RunnerSnapshot] = host.take_snapshots()
	assert_eq(arrived.size(), 1, "only the older snapshot reads")
	assert_eq(buffer.receive_all(arrived), 0, "and it is older than the one shown")
	assert_eq(host.state, LinkStatus.State.CONNECTED, "the game goes on")
	guest.send_message(OnlineMessage.rematch())
	var later: Array[OnlineMessage] = []
	_contract.until(
		func() -> bool:
			later.append_array(host.take_messages())
			return not later.is_empty()
	)
	assert_eq(later.size(), 1, "what comes next is read")


func _snapshot(step: int) -> RunnerSnapshot:
	var made: RunnerSnapshot = RunnerSnapshot.new()
	made.step = step
	made.capsule_height = 1.8
	return made
