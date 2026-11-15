class_name PlayerView
extends Control
## One player's half of a split screen: its own view of the world the two players share,
## through a camera of its own that takes, at every frame, the place and the field of view
## of the camera of its runner (the runner's camera shows nothing itself); and over it,
## the displays of that player: its role and the time (ChaseHud), its flow (FlowHud) and
## the pad of its trick (TrickPad). It processes after the runners' cameras have moved.
## Nothing takes the focus.

## The camera whose eyes this view shows the world through.
var followed: Camera3D

@onready var camera: Camera3D = %Camera3D as Camera3D
@onready var hud: ChaseHud = %ChaseHud as ChaseHud
@onready var flow_hud: FlowHud = %FlowHud as FlowHud
@onready var trick_pad: TrickPad = %TrickPad as TrickPad


func _ready() -> void:
	hud.camera = camera


func _process(_delta: float) -> void:
	follow()


## Puts the camera of the view where the followed camera is, with its field of view.
func follow() -> void:
	if followed == null:
		return
	camera.global_transform = followed.global_transform
	camera.fov = followed.fov
