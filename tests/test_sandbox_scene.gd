extends GutTest
## Smoke test of the skeleton: the project's main scene loads and holds a floor and a
## camera.

const MAIN_SCENE_SETTING: String = "application/run/main_scene"


func test_main_scene_loads_with_a_floor_and_a_camera() -> void:
	var path: String = ProjectSettings.get_setting(MAIN_SCENE_SETTING)
	var packed: PackedScene = load(path) as PackedScene
	assert_not_null(packed, "the main scene should load")

	var root: Node = packed.instantiate()
	add_child_autofree(root)

	assert_true(root.get_node_or_null("Floor") is Camera3D, "a static floor")
	assert_true(root.get_node_or_null("Camera3D") is Camera3D, "a camera")
