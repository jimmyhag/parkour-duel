class_name FrameClock
extends RefCounted
## A clock in ms that follows the physics frames of the engine, each one 1/60 s of game
## (ReplayTest): what the links of two machines side by side in a test are timed by.

const STEPS_PER_SECOND: float = 60.0


func read() -> int:
	return floori(Engine.get_physics_frames() * 1000.0 / STEPS_PER_SECOND)
