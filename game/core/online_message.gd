class_name OnlineMessage
extends RefCounted
## A message of the match of an online chase between the two machines
## (docs/specs/online-chase.md, decision 4), sent so that it arrives, in order: from the host,
## a match starts (and who is its first cat), the countdown of a round starts, a dated message
## of the chase (ChaseMessage) its state received; from the guest, the catch its cat made on
## its screen (a dated message of the chase too), and the rematch it chose. It travels as a
## fixed layout of plain numbers (encode); what comes from the network is read back only as
## numbers, each one checked (decode).

enum Kind { MATCH, COUNTDOWN, CHASE, REMATCH }

## The bytes of an encoded message.
const SIZE: int = 8
## The latest step a message may be dated at: a day of fixed steps at 60 per second.
const LATEST_STEP: int = 60 * 60 * 60 * 24
## The player of a message of the chase without one (ChaseState.NOBODY).
const NO_PLAYER: int = 255

var kind: Kind = Kind.MATCH
## The match step it is dated at, on the machine that sent it.
var step: int = 0
## Of a match: its first cat.
var first_cat: int = 0
## Of a message of the chase: that message.
var chase: ChaseMessage


## A match starts, at the match step `at_step`, `first` its first cat.
static func match_start(at_step: int, first: int) -> OnlineMessage:
	var made: OnlineMessage = OnlineMessage.new()
	made.kind = Kind.MATCH
	made.step = at_step
	made.first_cat = first
	return made


## The countdown of a round starts, at the match step `at_step`.
static func countdown(at_step: int) -> OnlineMessage:
	var made: OnlineMessage = OnlineMessage.new()
	made.kind = Kind.COUNTDOWN
	made.step = at_step
	return made


## The dated message of the chase `message`.
static func of_chase(message: ChaseMessage) -> OnlineMessage:
	var made: OnlineMessage = OnlineMessage.new()
	made.kind = Kind.CHASE
	made.step = message.step
	made.chase = message
	return made


## A rematch is chosen.
static func rematch() -> OnlineMessage:
	var made: OnlineMessage = OnlineMessage.new()
	made.kind = Kind.REMATCH
	return made


## The message as bytes: SIZE of them, little-endian.
func encode() -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(SIZE)
	bytes.encode_u8(0, kind)
	bytes.encode_u32(1, step)
	if kind == Kind.MATCH:
		bytes.encode_u8(5, first_cat)
	elif kind == Kind.CHASE:
		bytes.encode_u8(5, chase.kind)
		bytes.encode_u8(6, NO_PLAYER if chase.player == ChaseState.NOBODY else chase.player)
		bytes.encode_u8(7, chase.gesture)
	return bytes


## The message `bytes` hold, or null when they are not one: the wrong size, a kind, a player
## or a gesture that does not exist, a step past the latest.
static func decode(bytes: PackedByteArray) -> OnlineMessage:
	if bytes.size() != SIZE:
		return null
	var kind_read: int = bytes.decode_u8(0)
	var step_read: int = bytes.decode_u32(1)
	if kind_read >= Kind.size() or step_read > LATEST_STEP:
		return null
	var made: OnlineMessage = OnlineMessage.new()
	made.kind = kind_read as Kind
	made.step = step_read
	if made.kind == Kind.MATCH:
		made.first_cat = bytes.decode_u8(5)
		if made.first_cat >= ChaseState.PLAYERS:
			return null
	elif made.kind == Kind.CHASE:
		var chase_kind: int = bytes.decode_u8(5)
		var player: int = bytes.decode_u8(6)
		var gesture: int = bytes.decode_u8(7)
		if chase_kind >= ChaseMessage.Kind.size() or gesture >= Tag.Gesture.size():
			return null
		if player != NO_PLAYER and player >= ChaseState.PLAYERS:
			return null
		made.chase = ChaseMessage.new(chase_kind as ChaseMessage.Kind, step_read)
		made.chase.player = ChaseState.NOBODY if player == NO_PLAYER else player
		made.chase.gesture = gesture as Tag.Gesture
	return made
