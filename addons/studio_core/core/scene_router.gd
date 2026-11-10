extends CanvasLayer
## Screen changes with a fade, background loading, and Android back-button handling.
##
##   SceneRouter.go_to("res://game/ui/main_menu.tscn")
##   SceneRouter.go_to(level_path, {"level_id": "level_02"})   # read with SceneRouter.params
##   SceneRouter.reload()
##
## Back button / Escape: the current scene may define `func handle_back() -> bool`.
## Return true if it handled it (closed a popup, paused...). Otherwise the router goes
## to `home_scene`, and from the home scene it quits the app.

signal transition_started(path: String)
signal transition_finished(path: String)

@export var fade_time: float = 0.25
@export var fade_color: Color = Color(0.06, 0.07, 0.12)
var home_scene: String = "res://game/ui/main_menu.tscn"

## Parameters passed to the scene being opened.
var params: Dictionary = {}
var is_transitioning: bool = false

var _fade: ColorRect
var _spinner: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = fade_color
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_spinner = Label.new()
	_spinner.text = "Loading..."
	_spinner.set_anchors_preset(Control.PRESET_CENTER)
	_spinner.visible = false
	_fade.add_child(_spinner)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		back()


func go_to(path: String, scene_params: Dictionary = {}) -> void:
	if is_transitioning:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: scene not found: %s" % path)
		return
	is_transitioning = true
	params = scene_params
	transition_started.emit(path)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	ResourceLoader.load_threaded_request(path)
	await _tween_fade(1.0)

	var packed: PackedScene = await _wait_for_load(path)
	get_tree().paused = false
	if packed == null:
		push_error("SceneRouter: failed to load %s" % path)
	else:
		get_tree().change_scene_to_packed(packed)
		await get_tree().scene_changed
		EventBus.scene_changed.emit(path)

	await _tween_fade(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	transition_finished.emit(path)


func reload() -> void:
	var current: Node = get_tree().current_scene
	if current and current.scene_file_path != "":
		go_to(current.scene_file_path, params)


func back() -> void:
	if is_transitioning:
		return
	var current: Node = get_tree().current_scene
	if current and current.has_method("handle_back") and current.call("handle_back"):
		return
	if current and current.scene_file_path == home_scene:
		get_tree().quit()
	else:
		go_to(home_scene)


func current_scene_path() -> String:
	var current: Node = get_tree().current_scene
	return current.scene_file_path if current else ""


func _wait_for_load(path: String) -> PackedScene:
	var waited: float = 0.0
	while true:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_spinner.visible = false
			return null
		waited += get_process_delta_time()
		_spinner.visible = waited > 0.3
		await get_tree().process_frame
	_spinner.visible = false
	return ResourceLoader.load_threaded_get(path) as PackedScene


func _tween_fade(target_alpha: float) -> void:
	if fade_time <= 0.0:
		_fade.modulate.a = target_alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target_alpha, fade_time)
	await tween.finished
