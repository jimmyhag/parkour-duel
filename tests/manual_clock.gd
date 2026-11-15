class_name ManualClock
extends RefCounted
## A clock in ms that only moves when a test moves it: what the links of the tests are timed
## by (NetLink).

var ms: int = 0


func read() -> int:
	return ms
