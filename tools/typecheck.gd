extends SceneTree
## The type gate inside Godot, run by tools/typecheck.py: loads every script named after
## `--`, all in this one process, the way `--check-only --script` loads one (a script loads,
## and compiles: it is valid), then quits, with a failure code if one of them is not valid.
## The [debug] section of project.godot raises the typing warnings to errors: a script with
## one does not compile. A script needed by several is read and compiled once.


func _init() -> void:
	var scripts: PackedStringArray = OS.get_cmdline_user_args()
	var invalid: PackedStringArray = []
	for path: String in scripts:
		var script: Script = ResourceLoader.load(path) as Script
		# At run time, a GDScript can be instantiated exactly when it compiled.
		if script == null or not script.can_instantiate():
			invalid.append(path)
	for path: String in invalid:
		print("typecheck: not valid: ", path)
	print("typecheck: %d script(s) loaded, %d not valid" % [scripts.size(), invalid.size()])
	quit(1 if scripts.is_empty() or not invalid.is_empty() else 0)
