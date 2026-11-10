extends GutTest

const MENU: String = "res://game/ui/main_menu.tscn"
const SETTINGS: String = "res://game/ui/settings.tscn"

var _fade: float


func before_all() -> void:
	_fade = SceneRouter.fade_time
	SceneRouter.fade_time = 0.0


func after_all() -> void:
	SceneRouter.fade_time = _fade


func test_go_to_changes_scene_and_passes_params() -> void:
	await SceneRouter.go_to(SETTINGS, {"from": "test"})
	assert_eq(SceneRouter.current_scene_path(), SETTINGS)
	assert_eq(SceneRouter.params.get("from"), "test")
	assert_false(SceneRouter.is_transitioning)


func test_back_from_a_screen_goes_home() -> void:
	await SceneRouter.go_to(SETTINGS)
	SceneRouter.back()
	await wait_for_signal(SceneRouter.transition_finished, 3.0)
	assert_eq(SceneRouter.current_scene_path(), MENU)


func test_missing_scene_is_rejected() -> void:
	await SceneRouter.go_to("res://does/not/exist.tscn")
	assert_push_error("scene not found")
	assert_false(SceneRouter.is_transitioning)


func test_game_scene_loads() -> void:
	var scene: PackedScene = load("res://game/swing/swing_game.tscn")
	var node: Node = scene.instantiate()
	assert_true(node is SwingGame)
	node.free()
