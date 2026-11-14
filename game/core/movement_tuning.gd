class_name MovementTuning
extends Resource
## The single tuning resource of the feel: every speed, gravity, tolerance window, flow
## and camera value lives here and nowhere else. The values are in movement_tuning.tres; the
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

@export_group("Push")
## Where a push stops being along a wall or a ledge and becomes towards it or away from
## it: its angle from the surface, in degrees. A push exactly on the limit counts for a
## wall run and for a mantle; leaving a wall takes a push beyond it.
@export_range(0.0, 90.0) var push_split_angle: float = 0.0

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

@export_group("Flow")
## Points of each move, before the repetition and the multiplier.
@export var flow_points_jump: int = 0
@export var flow_points_slide: int = 0
@export var flow_points_perfect_slide: int = 0
@export var flow_points_roll: int = 0
@export var flow_points_mantle: int = 0
@export var flow_points_wall_run: int = 0
@export var flow_points_wall_jump: int = 0
## Least horizontal speed of a jump that counts, as a share of the top speed (0 to 1).
@export_range(0.0, 1.0) var flow_jump_min_speed_share: float = 0.0
## How many of the last moves of a combo a move is judged against.
@export var flow_repetition_window: int = 0
## Share of its points a move is worth when it is once among those last moves (0 to 1).
@export_range(0.0, 1.0) var flow_second_time_share: float = 0.0
## Share of its points a move is worth when it is twice or more among them (0 to 1).
@export_range(0.0, 1.0) var flow_later_times_share: float = 0.0
## Longest time on the ground between two moves of a combo, in s.
@export var flow_chain_delay: float = 0.0
## Moves of a combo that raise its multiplier by one.
@export var flow_moves_per_multiplier: int = 0
## Highest multiplier of a combo.
@export var flow_max_multiplier: int = 0
## Points of the gauge in one tier, and number of tiers: the gauge holds their product.
@export var flow_tier_value: float = 0.0
@export var flow_tier_count: int = 0
## What the gauge loses out of a combo, in points per second.
@export var flow_decay: float = 0.0
## Share of the top speed added at each tier, from the first; a tier past the end of the
## list has the bonus of its last one.
@export var flow_tier_speed_bonus: Array[float] = []
## Most ammunition held at once.
@export var flow_max_ammo: int = 0
## Style points that give one ammunition.
@export var flow_points_per_ammo: int = 0
## Time before and after a landing during which a slide press makes a perfect slide, in s.
@export var perfect_slide_window: float = 0.0
## Horizontal speed a perfect slide gains, in m/s.
@export var perfect_slide_speed_gain: float = 0.0
## Horizontal speed under which a runner on the ground is stopped, in m/s, and how long
## it must stay so for the stop to break its combo, in s.
@export var flow_stop_speed: float = 0.0
@export var flow_stop_duration: float = 0.0

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
