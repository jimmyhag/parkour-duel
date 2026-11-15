class_name Session
extends RefCounted
## What the game remembers from one mode to the next while it runs: the best finished solo
## run (the one the ghost replays), the best style score of the solo runs, and the last
## address joined online (docs/specs/online-chase.md). Nothing is saved to disk.

## The fastest finished solo run of the session; null before the first one.
var best_run: GhostRun
var best_style_score: int = 0
## The address of the host last joined in an online chase; empty before the first.
var last_address: String = ""


func has_solo_run() -> bool:
	return best_run != null


## A solo run is over: it becomes the best one if it is finished and faster.
func offer(run: GhostRun) -> void:
	if not run.is_finished():
		return
	if best_run == null or run.race_steps < best_run.race_steps:
		best_run = run
