class_name OnlineLobby
extends Node
## HOST and JOIN of the chase online (docs/specs/online-chase.md): a link of the adapter the
## composition root chose (make_link) opens to host or to join as the start screen asks,
## is polled at every fixed step meanwhile, and the start screen shows what it says: the
## port and the addresses of the machine while it waits, why a player was refused,
## CONNECTING…, why it could not host or join. Once the other player is there, the link is
## handed over (connected). The address joined is remembered for the session. Leaving the
## tree, it closes the link it still has.

## The other player is there, on `link`.
signal connected(link: NetLink)

## Makes a link: () -> NetLink.
var make_link: Callable
var session: Session
var screen: StartScreen
## The link hosting or joining; null when there is none.
var link: NetLink = null


func _ready() -> void:
	screen.host_chosen.connect(_host)
	screen.join_chosen.connect(_join)
	screen.online_cancelled.connect(_cancel)
	screen.remember(session.last_address)


func _exit_tree() -> void:
	_cancel()


func _physics_process(_delta: float) -> void:
	if link == null:
		return
	link.poll()
	match link.state:
		LinkStatus.State.WAITING:
			if link.failure != LinkStatus.Failure.NONE:
				screen.show_refusal(link.failure)
		LinkStatus.State.FAILED:
			screen.show_join_failure(link.failure)
			link = null
		LinkStatus.State.CONNECTED:
			var made: NetLink = link
			link = null
			connected.emit(made)


func _host() -> void:
	_cancel()
	link = make_link.call()
	var failure: LinkStatus.Failure = link.host()
	if failure != LinkStatus.Failure.NONE:
		link = null
		screen.show_host_failure(failure)
		return
	screen.show_waiting(NetLink.DEFAULT_PORT, NetLink.local_addresses())


func _join(address: String) -> void:
	_cancel()
	session.last_address = address
	link = make_link.call()
	var failure: LinkStatus.Failure = link.join(address)
	if failure != LinkStatus.Failure.NONE:
		link = null
		screen.show_join_failure(failure)
		return
	screen.show_connecting()


func _cancel() -> void:
	if link != null:
		link.close()
		link = null
