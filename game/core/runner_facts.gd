class_name RunnerFacts
extends RefCounted
## What the player layer observed about its runner before one fixed step: the facts the
## motor decides from. The simulation reads nothing else about the world.

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
