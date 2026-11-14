class_name Crosshair
extends Control
## The reticle, at the centre of the screen while the runner aims, hidden otherwise. It
## shows what the weapon of the runner (Shooter, game/core) judged of what it aims at,
## by its shape and not only its colour: a small cross on anything; a ring around the
## cross on a target the shot would hit; a slash across the cross on a target the runner
## cannot pay for. Nothing takes the focus.

enum Look { NEUTRAL, SHOOTABLE, BARRED }

## Half the length of a branch of the cross, the radius of the ring, the width of the
## lines, in pixels.
const ARM: float = 9.0
const GAP: float = 3.0
const RING: float = 16.0
const WIDTH: float = 2.0
const COLORS: Dictionary[Look, Color] = {
	Look.NEUTRAL: Color(1.0, 1.0, 1.0, 0.85),
	Look.SHOOTABLE: Color(1.0, 0.55, 0.15),
	Look.BARRED: Color(1.0, 0.25, 0.2),
}
const LOOKS: Dictionary[Shooter.Verdict, Look] = {
	Shooter.Verdict.NONE: Look.NEUTRAL,
	Shooter.Verdict.SHOOTABLE: Look.SHOOTABLE,
	Shooter.Verdict.TOO_EXPENSIVE: Look.BARRED,
}

## The weapon whose aim it shows.
var shooter: Shooter
var look: Look = Look.NEUTRAL


func _process(_delta: float) -> void:
	refresh()


## Shows the reticle while the runner aims, with the look of what it aims at.
func refresh() -> void:
	visible = shooter != null and shooter.aiming
	if shooter == null:
		return
	var new_look: Look = LOOKS[shooter.verdict]
	if new_look != look:
		look = new_look
		queue_redraw()


func _draw() -> void:
	var centre: Vector2 = size / 2.0
	var colour: Color = COLORS[look]
	for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(centre + way * GAP, centre + way * (GAP + ARM), colour, WIDTH)
	if look == Look.SHOOTABLE:
		draw_arc(centre, RING, 0.0, TAU, 32, colour, WIDTH)
	elif look == Look.BARRED:
		var slash: Vector2 = Vector2(RING, -RING)
		draw_line(centre - slash, centre + slash, colour, WIDTH)
