extends GutTest
## End-to-end: drives the real screens the way a player would, by pressing their buttons.
## menu -> play -> pause -> resume -> die -> continue (ad) -> win -> next level -> progress survives restart.

const MENU: String = "res://game/ui/main_menu.tscn"
const TEST_SAVE: String = "user://test_flow_save.json"

var _fade: float
var _save_path: String
var _save_data: Dictionary


func before_all() -> void:
	_fade = SceneRouter.fade_time
	SceneRouter.fade_time = 0.0
	_save_path = SaveManager.save_path
	_save_data = SaveManager.data.duplicate(true)
	SaveManager.save_path = TEST_SAVE
	SaveManager.reset()
	Ads.stub_delay = 0.05


func after_all() -> void:
	get_tree().paused = false
	SceneRouter.fade_time = _fade
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	SaveManager.save_path = _save_path
	SaveManager.data = _save_data
	Ads.stub_delay = 0.5
	await SceneRouter.go_to(MENU)


func _scene() -> Node:
	return get_tree().current_scene


func _press(button: BaseButton) -> void:
	assert_true(button.visible and not button.disabled, "%s should be pressable" % button.name)
	button.pressed.emit()


func _go_and_wait(action: Callable) -> void:
	action.call()
	await wait_for_signal(SceneRouter.transition_finished, 5.0)


func test_full_player_journey() -> void:
	await SceneRouter.go_to(MENU)
	assert_eq(SceneRouter.current_scene_path(), MENU)

	# Menu -> Play opens the first level.
	await _go_and_wait(func() -> void: _press(_scene().get_node("%PlayButton")))
	var level := _scene() as Level
	assert_not_null(level, "Play should open a level")
	assert_eq(level.level_id, "level_01")

	# Tap starts the run.
	level.start()
	await wait_seconds(0.3)
	assert_true(level.player.running, "player runs after the first tap")
	assert_gt(level.player.position.x, 0.0)

	# Back button pauses, Resume unpauses.
	assert_true(level.handle_back())
	assert_true(get_tree().paused)
	assert_true(level.pause_menu.visible)
	_press(level.pause_menu.get_node("%ResumeButton"))
	assert_false(get_tree().paused)
	assert_false(level.pause_menu.visible)

	# Dying shows game over with a continue offer.
	level.player.die()
	await wait_seconds(1.3)
	assert_eq(level.state, Level.State.LOST)
	assert_true(level.game_over.visible)
	var continue_button: Button = level.game_over.get_node("%ContinueButton")
	assert_true(continue_button.visible)

	# Continue (rewarded ad stub) revives the player and the run goes on.
	_press(continue_button)
	await wait_seconds(0.4)
	assert_eq(level.state, Level.State.RUNNING)
	assert_true(level.player.alive)
	assert_false(level.game_over.visible)

	# Reaching the goal wins, saves stars and unlocks level 2.
	level._on_goal_reached()
	await wait_seconds(1.5)
	assert_eq(level.state, Level.State.WON)
	assert_true(level.game_over.visible)
	assert_true(SaveManager.is_level_unlocked("level_02"))
	assert_gt(SaveManager.get_level_stars("level_01"), 0)

	# Next Level opens level 2.
	await _go_and_wait(func() -> void: _press(level.game_over.get_node("%NextButton")))
	assert_eq((_scene() as Level).level_id, "level_02")

	# Progress survives an app restart (reload from disk).
	SaveManager.data = {}
	SaveManager.load_data()
	assert_true(SaveManager.is_level_unlocked("level_02"))


func test_level_select_respects_locks() -> void:
	SaveManager.reset()
	await SceneRouter.go_to("res://game/ui/level_select.tscn")
	var grid: GridContainer = _scene().get_node("%Grid")
	var first: Button = grid.get_child(0).get_child(0)
	var second: Button = grid.get_child(1).get_child(0)
	assert_false(first.disabled, "level 1 is always open")
	assert_true(second.disabled, "level 2 is locked on a fresh save")


func test_back_from_menu_quits_only_from_home() -> void:
	await SceneRouter.go_to("res://game/ui/settings.tscn")
	await _go_and_wait(SceneRouter.back)
	assert_eq(SceneRouter.current_scene_path(), MENU)
