class_name IntentSource
extends RefCounted
## Where a runner's intents come from: asked once per fixed step. The player layer
## reads the inputs, a test replays a sequence written in advance, and later a ghost or
## the network will provide theirs. This base source wants nothing.


func next_intent() -> MoveIntent:
	return MoveIntent.new()
