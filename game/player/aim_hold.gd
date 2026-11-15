class_name AimHold
extends SkeletonModifier3D
## Holds the upper body of the character (RunnerCharacter) in the aim of Pistol Idle, turned
## as in that clip, whatever the hips of the legs do: the aim faces where the runner faces.

## How much of the aim the upper body holds (0 to 1).
var weight: float = 0.0
var _hips: int = -1
var _spine: int = -1
## The rotation of the hips in Pistol Idle.
var _aim_hips: Quaternion = Quaternion.IDENTITY


func _init(hips: int, spine: int, aim_hips: Quaternion) -> void:
	_hips = hips
	_spine = spine
	_aim_hips = aim_hips


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if weight <= 0.0 or skeleton == null:
		return
	var hips: Quaternion = skeleton.get_bone_pose_rotation(_hips)
	var turn: Quaternion = Quaternion.IDENTITY.slerp(hips.inverse() * _aim_hips, weight)
	skeleton.set_bone_pose_rotation(_spine, turn * skeleton.get_bone_pose_rotation(_spine))
