class_name LinkStatus
extends RefCounted
## The state of the link of an online chase to the other machine (docs/specs/online-chase.md),
## and the expected failures it returns as a typed result, never as a crash or an error: the
## port already taken, nobody answering in time (or the address unreadable, or the game
## full), another version of the game, the other player gone or silent.

enum State {
	## Nothing open.
	CLOSED,
	## Hosting: the port is open, no player has joined yet.
	WAITING,
	## Joining: no answer from the host yet.
	CONNECTING,
	## The two machines know each other and play the same version.
	CONNECTED,
	## Over, for the reason of the failure.
	FAILED,
}

enum Failure {
	NONE,
	PORT_ALREADY_IN_USE,
	COULD_NOT_CONNECT,
	DIFFERENT_GAME_VERSION,
	THE_OTHER_PLAYER_LEFT,
}
