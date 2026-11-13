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

@export_group("Slide")
## Slowest horizontal speed at which a slide can start, in m/s.
@export var slide_min_speed: float = 0.0
## Speed under which a slide ends, and the least speed of a runner kept low by a low
## ceiling, in m/s.
@export var slide_stop_speed: float = 0.0
## How fast a slide slows down on flat ground, in m/s².
@export var slide_deceleration: float = 0.0
## How fast the direction of a slide can be corrected, in rad/s.
@export var slide_turn_speed: float = 0.0
## Height of the capsule during a slide and a roll, in m.
@export var slide_capsule_height: float = 0.0

@export_group("Landing")
## Fall height above which a landing must be rolled, in m.
@export var roll_fall_height: float = 0.0
## Time before a landing during which a slide press makes it a roll, in s.
@export var roll_window: float = 0.0
## How long a roll lasts, in s.
@export var roll_duration: float = 0.0
## Share of the horizontal speed kept by a hard landing, and share of the top speed
## the runner cannot exceed while it lasts (0 to 1).
@export_range(0.0, 1.0) var hard_landing_speed_ratio: float = 0.0
## How long a hard landing lasts, in s.
@export var hard_landing_duration: float = 0.0

@export_group("Momentum")
## How fast a speed above the top speed comes back down on the floor, in m/s².
@export var momentum_deceleration: float = 0.0
## The horizontal speed nothing can exceed, in m/s.
@export var max_horizontal_speed: float = 0.0

@export_group("Mantle")
## Lowest height of a ledge above the feet that a mantle climbs, in m.
@export var mantle_min_height: float = 0.0
## Highest height of a ledge above the feet that a mantle climbs, in m.
@export var mantle_max_height: float = 0.0
## How long a mantle lasts, from the air to standing on the ledge, in s.
@export var mantle_duration: float = 0.0
## Speed at which a mantle leaves the runner on its ledge, forwards, in m/s.
@export var mantle_exit_speed: float = 0.0

@export_group("Wall run")
## Farthest a wall can be from the runner's side for a wall run, in m.
@export var wall_run_distance: float = 0.0
## How far from vertical a wall may lean and still be run along, in degrees.
@export var wall_run_max_tilt: float = 0.0
## Shortest wall that can be run along, from its foot to its top, in m.
@export var wall_run_min_wall_height: float = 0.0
## Least height of the feet above the ground for a wall run to start, in m.
@export var wall_run_min_height: float = 0.0
## Least horizontal speed for a wall run to start, in m/s.
@export var wall_run_start_speed: float = 0.0
## Speed along the wall under which a wall run ends, in m/s.
@export var wall_run_stop_speed: float = 0.0
## Longest a wall run lasts, in s.
@export var wall_run_duration: float = 0.0
## Gravity of a wall run on its way down, in m/s².
@export var wall_run_gravity: float = 0.0
## How far the capsule one sees leans towards the wall it runs along, in degrees.
@export var wall_run_lean: float = 0.0

@export_group("Wall jump")
## Speed a wall jump gives away from the wall, in m/s.
@export var wall_jump_away_speed: float = 0.0
## Speed a wall jump gives upwards, in m/s.
@export var wall_jump_up_speed: float = 0.0
## Time after leaving a wall run during which a jump is still a wall jump, in s.
@export var wall_jump_grace_time: float = 0.0

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
