class_name MovementTuning
extends Resource
## The single tuning resource of the feel: every speed, gravity, tolerance window and
## camera value lives here and nowhere else. The values are in movement_tuning.tres; the
## zeros below are only the neutral defaults of an empty resource. Durations are in
## seconds: the runner applies them in fixed steps.

@export_group("Run")
## Top horizontal speed, in m/s.
@export var top_speed: float = 0.0
## Acceleration towards the wanted speed on the floor, in m/s².
@export var ground_acceleration: float = 0.0
## Braking on the floor when no direction is asked, in m/s².
@export var ground_deceleration: float = 0.0
## Acceleration towards the wanted speed in the air, in m/s².
@export var air_acceleration: float = 0.0

@export_group("Jump")
## Height of a jump whose button is held up to the top, in m.
@export var jump_height: float = 0.0
## Gravity while rising, in m/s².
@export var rise_gravity: float = 0.0
## Gravity while falling, in m/s².
@export var fall_gravity: float = 0.0
## Share of the vertical speed kept when the jump is released while rising (0 to 1).
@export_range(0.0, 1.0) var jump_release_velocity_ratio: float = 0.0
## Fastest fall, in m/s.
@export var max_fall_speed: float = 0.0
## Time after leaving the floor during which a jump is still accepted, in s.
@export var coyote_time: float = 0.0
## Time before landing during which a jump press is remembered, in s.
@export var jump_buffer_time: float = 0.0

@export_group("Character")
## Dead zone of both sticks (0 to 1).
@export_range(0.0, 1.0) var stick_deadzone: float = 0.0
## Height of the capsule, in m.
@export var capsule_height: float = 0.0
## Radius of the capsule, in m.
@export var capsule_radius: float = 0.0
## How fast the character turns towards its movement, in rad/s.
@export var turn_speed: float = 0.0

@export_group("Camera")
## Distance between the camera and the point it looks at, in m.
@export var camera_distance: float = 0.0
## Height of the point the camera looks at, above the runner's feet, in m.
@export var camera_look_height: float = 0.0
## How far the camera can look down, in degrees.
@export var camera_look_down_limit: float = 0.0
## How far the camera can look up, in degrees.
@export var camera_look_up_limit: float = 0.0
## Radius of the sphere that keeps the camera away from walls and floors, in m.
@export var camera_collision_radius: float = 0.0
## Mouse sensitivity, in rad per pixel.
@export var camera_mouse_sensitivity: float = 0.0
## Rotation speed with the stick fully pushed, in rad/s.
@export var camera_stick_speed: float = 0.0
