extends GutTest
## The Mixamo files (docs/specs/character-animations.md): they live in assets/mixamo/,
## which Git ignores, since the repository is public; the copy command (tools/mixamo.py)
## puts there the character, the animations the game uses, and the one clip of the pistol
## pack it uses.

## The folder of the Mixamo files, from the root of the repository.
const MIXAMO_FOLDER: String = "assets/mixamo"
## A file the copy command puts there, as Git would see it.
const A_MIXAMO_FILE: String = "assets/mixamo/ch08_nonpbr.fbx"
## The copy command, from the root of the repository.
const COPY_TOOL: String = "tools/mixamo.py"
## A download folder made up for the test, and the folder the copy goes into.
const DOWNLOADS: String = "user://mixamo_downloads"
const COPY: String = "user://mixamo_copy"
## The files of a download folder, as mixamo.com names them, and the name each one the
## game uses takes once copied. Running Forward Flip is downloaded, but the tuck pose comes
## from Backflip: it is not copied. Wall Run is not needed: along a wall the character runs
## (docs/specs/animation-polish.md), and a folder without it is enough.
const DOWNLOADED: Dictionary[String, String] = {
	"Ch08_nonPBR.fbx": "ch08_nonpbr.fbx",
	"Idle.fbx": "idle.fbx",
	"Running.fbx": "running.fbx",
	"Jump.fbx": "jump.fbx",
	"Falling Idle.fbx": "falling_idle.fbx",
	"Landing.fbx": "landing.fbx",
	"Hard Landing.fbx": "hard_landing.fbx",
	"Falling To Roll.fbx": "falling_to_roll.fbx",
	"Running Slide.fbx": "running_slide.fbx",
	"Sprint To Wall Climb.fbx": "",
	"Backflip.fbx": "backflip.fbx",
	"Running Forward Flip.fbx": "",
	"Walking.fbx": "walking.fbx",
	"Sprint.fbx": "sprint.fbx",
	"Vault One Hand.fbx": "vault_one_hand.fbx",
	"Vault Two Hands.fbx": "vault_two_hands.fbx",
	"Ledge Pull Up.fbx": "ledge_pull_up.fbx",
	"Jogging.fbx": "jogging.fbx",
	"Running Jump.fbx": "running_jump.fbx",
	"Land To Run.fbx": "land_to_run.fbx",
	"Fast Run.fbx": "",
	"Two Cycle Sprint.fbx": "",
	"Running Quickly.fbx": "",
}
## The clips of docs/specs/motion-weight.md, downloaded without the character, and the name
## each one takes once copied; and the runs measured for it and not retained: none of them
## strides fast enough for the top speed under the cap of the tuning.
const MOTION_WEIGHT_CLIPS: Dictionary[String, String] = {
	"Jogging.fbx": "jogging.fbx",
	"Running Jump.fbx": "running_jump.fbx",
	"Land To Run.fbx": "land_to_run.fbx",
}
const NOT_RETAINED: Array[String] = ["Fast Run.fbx", "Two Cycle Sprint.fbx", "Running Quickly.fbx"]
## The clips of the vault and of the mantle (docs/specs/vault.md), downloaded without the
## character, and the name each one takes once copied.
const VAULT_CLIPS: Dictionary[String, String] = {
	"Vault One Hand.fbx": "vault_one_hand.fbx",
	"Vault Two Hands.fbx": "vault_two_hands.fbx",
	"Ledge Pull Up.fbx": "ledge_pull_up.fbx",
}
## The walk and the sprint of the locomotion (docs/specs/locomotion-blend.md), downloaded
## without the character, and the name each one takes once copied.
const LOCOMOTION: Dictionary[String, String] = {
	"Walking.fbx": "walking.fbx",
	"Sprint.fbx": "sprint.fbx",
}
## The pistol pack, the clips it holds, and the name of the one the game uses. Its
## character is not the one downloaded: it must not replace it.
const PACK: String = "Pistol_Handgun Locomotion Pack.zip"
const PACK_CLIPS: Dictionary[String, String] = {
	"Ch08_nonPBR.fbx": "",
	"pistol idle.fbx": "pistol_idle.fbx",
	"pistol run.fbx": "",
	"pistol walk.fbx": "",
}
## A Python script that runs the copy command with its folder argument ending with a
## quote (chr(34)), as cmd.exe gives a quoted folder that ends with a backslash. Its
## arguments: the folder of the tool, the download folder, the folder to copy into.
const AS_CMD_GIVES_IT: String = "user://mixamo_as_cmd_gives_it.py"
const AS_CMD_GIVES_IT_SCRIPT: String = """import sys
sys.path.insert(0, sys.argv[1])
import mixamo
sys.argv = ["mixamo.py", sys.argv[2] + chr(34), "--into", sys.argv[3]]
sys.exit(mixamo.main())
"""
## What the clips of the made-up pack hold before their name: they differ from the
## downloads of the same name.
const PACKED: String = "pack:"


func after_each() -> void:
	_remove_folder(DOWNLOADS)
	_remove_folder(COPY)


func test_mixamo_files_are_never_tracked_by_git() -> void:
	var root: String = ProjectSettings.globalize_path("res://")
	for path: String in [MIXAMO_FOLDER + "/", A_MIXAMO_FILE, A_MIXAMO_FILE + ".import"]:
		var ignored: int = OS.execute("git", ["-C", root, "check-ignore", "--quiet", path])
		assert_eq(ignored, 0, "%s is ignored by Git" % path)

	var output: Array = []
	var listed: int = OS.execute("git", ["-C", root, "ls-files"], output)
	assert_eq(listed, 0, "git lists the tracked files")
	var listing: String = output[0]
	var tracked: PackedStringArray = listing.split("\n", false)
	assert_gt(tracked.size(), 0, "the repository tracks files")
	for path: String in tracked:
		assert_false(path.begins_with(MIXAMO_FOLDER + "/"), "%s is not tracked" % path)
		assert_false(path.to_lower().ends_with(".fbx"), "%s: no FBX file is tracked" % path)


func test_the_copy_command_puts_away_the_used_files() -> void:
	_make_the_downloads()

	var output: Array = []
	var code: int = _copy(_absolute(DOWNLOADS), output)
	assert_eq(code, 0, "the copy command succeeds: %s" % [output])

	# What each copied file holds: a download, or a clip of the pack.
	var expected: Dictionary[String, String] = {}
	for download: String in DOWNLOADED:
		if not DOWNLOADED[download].is_empty():
			expected[DOWNLOADED[download]] = download
	for clip: String in PACK_CLIPS:
		if not PACK_CLIPS[clip].is_empty():
			expected[PACK_CLIPS[clip]] = PACKED + clip
	var copied: PackedStringArray = []
	for file: String in DirAccess.get_files_at(COPY):
		if file.get_extension() == "fbx":
			copied.append(file)
	copied.sort()
	var wanted: PackedStringArray = PackedStringArray(expected.keys())
	wanted.sort()
	assert_eq(copied, wanted, "the character, each animation used and pistol idle, nothing else")
	for file: String in expected:
		var content: String = FileAccess.get_file_as_string(COPY.path_join(file))
		assert_eq(content, expected[file], "%s holds %s" % [file, expected[file]])
		var settings: String = COPY.path_join(file + ".import")
		assert_true(FileAccess.file_exists(settings), "%s has its import settings" % file)


func test_the_copy_also_puts_away_the_walk_and_the_sprint() -> void:
	_make_the_downloads()

	var output: Array = []
	var code: int = _copy(_absolute(DOWNLOADS), output)
	assert_eq(code, 0, "the copy command succeeds: %s" % [output])

	for download: String in LOCOMOTION:
		var copied: String = COPY.path_join(LOCOMOTION[download])
		assert_true(FileAccess.file_exists(copied), "%s is copied" % download)
		assert_eq(FileAccess.get_file_as_string(copied), download, "%s holds it" % copied)
		var settings: String = copied + ".import"
		assert_true(FileAccess.file_exists(settings), "%s has its import settings" % copied)

	# Without them, nothing is copied: the character needs every clip.
	_remove_folder(COPY)
	for download: String in LOCOMOTION:
		DirAccess.remove_absolute(DOWNLOADS.path_join(download))
	output.clear()
	code = _copy(_absolute(DOWNLOADS), output)
	assert_ne(code, 0, "without the walk and the sprint, the copy fails")
	for download: String in LOCOMOTION:
		assert_string_contains(str(output), download, false)
	assert_false(DirAccess.dir_exists_absolute(COPY), "nothing is copied")


func test_the_copy_puts_away_the_vault_clips() -> void:
	_make_the_downloads()

	var output: Array = []
	var code: int = _copy(_absolute(DOWNLOADS), output)
	assert_eq(code, 0, "the copy command succeeds: %s" % [output])

	for download: String in VAULT_CLIPS:
		var copied: String = COPY.path_join(VAULT_CLIPS[download])
		assert_true(FileAccess.file_exists(copied), "%s is copied" % download)
		assert_eq(FileAccess.get_file_as_string(copied), download, "%s holds it" % copied)
		var settings: String = copied + ".import"
		assert_true(FileAccess.file_exists(settings), "%s has its import settings" % copied)
	assert_false(
		FileAccess.file_exists(COPY.path_join("sprint_to_wall_climb.fbx")),
		"Sprint To Wall Climb, which the mantle no longer plays, is not copied"
	)

	# Without them, nothing is copied: the character needs every clip.
	_remove_folder(COPY)
	for download: String in VAULT_CLIPS:
		DirAccess.remove_absolute(DOWNLOADS.path_join(download))
	output.clear()
	code = _copy(_absolute(DOWNLOADS), output)
	assert_ne(code, 0, "without the clips of the vault, the copy fails")
	for download: String in VAULT_CLIPS:
		assert_string_contains(str(output), download, false)
	assert_false(DirAccess.dir_exists_absolute(COPY), "nothing is copied")


func test_the_copy_puts_away_the_retained_clips() -> void:
	_make_the_downloads()

	var output: Array = []
	var code: int = _copy(_absolute(DOWNLOADS), output)
	assert_eq(code, 0, "the copy command succeeds: %s" % [output])

	for download: String in MOTION_WEIGHT_CLIPS:
		var copied: String = COPY.path_join(MOTION_WEIGHT_CLIPS[download])
		assert_true(FileAccess.file_exists(copied), "%s is copied" % download)
		assert_eq(FileAccess.get_file_as_string(copied), download, "%s holds it" % copied)
		assert_true(FileAccess.file_exists(copied + ".import"), "%s has its settings" % copied)
	for download: String in NOT_RETAINED:
		var named: String = download.to_lower().replace(" ", "_")
		assert_false(FileAccess.file_exists(COPY.path_join(named)), "%s is not copied" % download)

	# Without them, nothing is copied: the character needs every clip.
	_remove_folder(COPY)
	for download: String in MOTION_WEIGHT_CLIPS:
		DirAccess.remove_absolute(DOWNLOADS.path_join(download))
	output.clear()
	code = _copy(_absolute(DOWNLOADS), output)
	assert_ne(code, 0, "without the clips of the motion weight, the copy fails")
	for download: String in MOTION_WEIGHT_CLIPS:
		assert_string_contains(str(output), download, false)
	assert_false(DirAccess.dir_exists_absolute(COPY), "nothing is copied")


func test_a_download_folder_ending_with_a_backslash_is_read_under_cmd() -> void:
	_make_the_downloads()
	# cmd.exe hands "C:\downloads\" over as C:\downloads" : the backslash escapes the
	# closing quote. No shell may see that quote (sh would refuse the command): a script
	# gives the tool the folder with the quote, as its argument, the way cmd.exe does.
	_write(AS_CMD_GIVES_IT, AS_CMD_GIVES_IT_SCRIPT)
	var arguments: PackedStringArray = [
		_absolute(AS_CMD_GIVES_IT),
		_absolute("res://tools"),
		_absolute(DOWNLOADS),
		_absolute(COPY),
	]
	var output: Array = []
	var code: int = OS.execute(_venv_python(), arguments, output, true)
	DirAccess.remove_absolute(AS_CMD_GIVES_IT)

	assert_eq(code, 0, "the copy command succeeds: %s" % [output])
	assert_true(FileAccess.file_exists(COPY.path_join("ch08_nonpbr.fbx")), "the files are copied")


## A download folder: every file as mixamo.com names it, each holding its own name, and
## the pistol pack, each of its clips holding PACKED and its name.
func _make_the_downloads() -> void:
	DirAccess.make_dir_recursive_absolute(DOWNLOADS)
	for download: String in DOWNLOADED:
		_write(DOWNLOADS.path_join(download), download)
	var packer: ZIPPacker = ZIPPacker.new()
	assert_eq(packer.open(DOWNLOADS.path_join(PACK)), OK, "the pack is written")
	for clip: String in PACK_CLIPS:
		packer.start_file(clip)
		packer.write_file((PACKED + clip).to_utf8_buffer())
		packer.close_file()
	packer.close()


## Runs the copy command on the download folder given as `folder`, into COPY.
func _copy(folder: String, output: Array) -> int:
	var arguments: PackedStringArray = [
		_absolute("res://" + COPY_TOOL), folder, "--into", _absolute(COPY)
	]
	return OS.execute(_venv_python(), arguments, output, true)


## Where Godot finds `path`, on the disk.
func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)


## The Python of the tooling (`just setup`), on this system.
func _venv_python() -> String:
	var inside: String = "Scripts/python.exe" if OS.get_name() == "Windows" else "bin/python"
	return _absolute("res://.venv".path_join(inside))


func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func _remove_folder(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
