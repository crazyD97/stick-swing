extends Node
## Command-line helpers so tools (and Claude) can run the game unattended.
## Pass them after `--` on the Godot command line:
##
##   godot --path . -- --scene=res://game/levels/level_01.tscn --shot=3 --shot-path=build/shot.png
##
##   --scene=PATH     open this scene right after start-up (skips splash/menu)
##   --shot=SECONDS   save a screenshot after SECONDS, then quit
##   --shot-path=P    where to save it (default user://screenshots/shot.png); res:// paths and
##                    relative paths are resolved against the project folder
##   --tap-at=SECONDS simulate a tap in the middle of the screen at SECONDS (repeatable: 1,2.5)
##   --hold=A-B       press the middle of the screen at A seconds and release at B (repeatable: 1-2,3-3.5)
##   --quit=SECONDS   quit after SECONDS (smoke test without a screenshot)
##   --reset-save     start with a fresh save file (wipes your real desktop save)
##   --temp-save      use a throwaway save file, starting fresh (playtests use this)

var args: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	args = parse_args(OS.get_cmdline_user_args())
	if args.has("temp-save"):
		SaveManager.save_path = "user://devtools_temp_save.json"
	if args.has("reset-save") or args.has("temp-save"):
		SaveManager.reset()
		Settings.reload()
	if args.has("scene"):
		_open_scene.call_deferred(str(args["scene"]))
	if args.has("tap-at"):
		for t: String in str(args["tap-at"]).split(","):
			_tap_later(float(t))
	if args.has("hold"):
		for span: String in str(args["hold"]).split(","):
			var ends: PackedStringArray = span.split("-")
			if ends.size() == 2:
				_hold_later(float(ends[0]), float(ends[1]))
	if args.has("shot"):
		_screenshot_later(float(args["shot"]), str(args.get("shot-path", "user://screenshots/shot.png")))
	elif args.has("quit"):
		await get_tree().create_timer(float(args["quit"])).timeout
		get_tree().quit()


static func parse_args(raw: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	for arg: String in raw:
		if not arg.begins_with("--"):
			continue
		var body: String = arg.substr(2)
		var eq: int = body.find("=")
		if eq == -1:
			result[body] = true
		else:
			result[body.substr(0, eq)] = body.substr(eq + 1)
	return result


func _open_scene(path: String) -> void:
	var old_fade: float = SceneRouter.fade_time
	SceneRouter.fade_time = 0.0
	await SceneRouter.go_to(path)
	SceneRouter.fade_time = old_fade


func _tap_later(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var center: Vector2 = get_viewport().get_visible_rect().size / 2.0
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = center
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await get_tree().process_frame


func _hold_later(start: float, end: float) -> void:
	await get_tree().create_timer(start).timeout
	_send_touch(true)
	await get_tree().create_timer(maxf(0.0, end - start)).timeout
	_send_touch(false)


func _send_touch(pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = get_viewport().get_visible_rect().size / 2.0
	touch.pressed = pressed
	Input.parse_input_event(touch)


func _screenshot_later(seconds: float, path: String) -> void:
	await get_tree().create_timer(seconds).timeout
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var absolute: String = _resolve_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var err: Error = image.save_png(absolute)
	if err == OK:
		print("DevTools: screenshot saved to %s" % absolute)
	else:
		push_error("DevTools: could not save screenshot (%s)" % error_string(err))
	get_tree().quit()


func _resolve_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path("res://").path_join(path)
