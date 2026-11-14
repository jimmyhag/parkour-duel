class_name MoveIntent
extends RefCounted
## What a runner wants to do during one fixed step. The simulation only knows intents:
## it knows neither keys nor camera, and tomorrow they will come from the network.

## Wanted direction in the world: horizontal, length from 0 (none) to 1 (full).
var direction: Vector3 = Vector3.ZERO
## The jump was pressed at this step.
var jump_pressed: bool = false
## The jump is held down.
var jump_held: bool = false
## The slide was pressed at this step.
var slide_pressed: bool = false
## The slide is held down.
var slide_held: bool = false
## The trick is held down: the runner draws its trick.
var trick_held: bool = false
## The trick was released at this step: the trick drawn starts, if it can.
var trick_released: bool = false
## What the drawing of the trick reads, while it is held and as it is released: the
## recipe drawn, the trick of the context if nothing was drawn, or null if it cannot be
## read.
var trick_recipe: TrickRecipe
## The aim is held down: the runner aims.
var aim_held: bool = false
## Where the runner aims from its head, in the world; ZERO: through the centre of its
## camera, as a player does.
var aim_direction: Vector3 = Vector3.ZERO
## The shot was pressed at this step.
var shoot_pressed: bool = false
## The return to the last checkpoint was asked at this step.
var respawn_requested: bool = false
## Restarting the course was asked at this step.
var restart_requested: bool = false
