class_name ChaseBotCandidate
extends RefCounted
## A flee point the mouse of the chase may run to (ChaseBot), with what the paths of the
## arena say of it at a decision: the player layer works them out, the bot only weighs
## them.

## Where the point is, in the world.
var point: Vector3 = Vector3.ZERO
## The length of the bot's path to the point, in m: INF when the bot cannot reach it.
var distance: float = INF
## The length of the cat's path to the point, in m.
var cat_distance: float = INF
## How near the cat can come to the bot as the bot runs its path to the point, in m: at the
## start, how far the cat is.
var cat_clearance: float = INF
