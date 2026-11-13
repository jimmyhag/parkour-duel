class_name RunnerFacts
extends RefCounted
## What the player layer observed about its runner before one fixed step: the facts the
## motor decides from. The simulation reads nothing else about the world.

## The identity of no wall.
const NO_WALL: int = 0

## The runner stands on a floor.
var on_floor: bool = false
## The real velocity, after the collisions of the last step, in m/s.
var velocity: Vector3 = Vector3.ZERO
## The altitude of the runner's feet, in m.
var altitude: float = 0.0
## The normal of the ground under the runner's feet: its slope. Straight up when there
## is none there, as in the air or over the edge of a block.
var floor_normal: Vector3 = Vector3.UP
## There is room above the runner to stand up.
var can_stand: bool = true
## How far down the ground is under the runner's feet, in m; INF when there is none
## within the depth the player probes.
var ground_clearance: float = INF

## The wall at the runner's left or right, if any: which one it is (a wall is one
## physics object, NO_WALL when there is none), its normal (pointing away from the wall,
## towards the runner), how far it is from the runner's side, in m, and how tall it is,
## from its foot to its top, in m.
var wall_id: int = NO_WALL
var wall_normal: Vector3 = Vector3.ZERO
var wall_distance: float = INF
var wall_height: float = 0.0

## The ledge right in front of the runner, if any: the normal of its face (pointing
## towards the runner, ZERO when there is none), the height of its top above the
## runner's feet, in m, and whether its top is free for the runner to stand on.
var ledge_normal: Vector3 = Vector3.ZERO
var ledge_height: float = 0.0
var ledge_clear: bool = false
