extends GutTest
## End-to-end: drives the real screens the way a player would, by pressing their buttons.
## menu -> play -> hold/swing -> pause -> resume -> fall -> continue (ad) -> fall -> retry -> menu shows best.

const MENU: String = "res://game/ui/main_menu.tscn"
const GAME: String = "res://game/swing/swing_game.tscn"
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
	await _go_and_wait(func() -> void: _press(_scene().get_node("%PlayButton")))
	var game := _scene() as SwingGame
	assert_not_null(game, "Play should open the swing game")

	# First press launches; holding grabs a ring once one is in range.
	game.press()
	assert_eq(game.state, SwingGame.State.PLAYING)
	await wait_seconds(1.2)
	assert_eq(game.swinger.state, Swinger.State.SWINGING, "holding grabs the first ring")
	game.release_hold()
	assert_eq(game.swinger.state, Swinger.State.FLYING)

	# Back button pauses, Resume unpauses.
	assert_true(game.handle_back())
	assert_true(get_tree().paused)
	assert_true(game.pause_menu.visible)
	_press(game.pause_menu.get_node("%ResumeButton"))
	assert_false(get_tree().paused)

	# Never grabbing again: fall into the lava, game over offers Continue.
	await wait_for_signal(game.game_over_shown, 8.0)
	assert_eq(game.state, SwingGame.State.OVER)
	var continue_button: Button = game.game_over.get_node("%ContinueButton")
	assert_true(continue_button.visible)

	# Continue (rewarded ad stub) puts the swinger back on a ring.
	_press(continue_button)
	await wait_seconds(0.3)
	assert_eq(game.state, SwingGame.State.PLAYING)
	assert_eq(game.swinger.state, Swinger.State.SWINGING)

	# Let go and fall again: no second continue.
	game.release_hold()
	await wait_for_signal(game.game_over_shown, 8.0)
	assert_false(continue_button.visible, "only one continue per run")
	var best: int = int(SaveManager.get_value("stats", "best_distance", 0))
	assert_eq(best, game.score)

	# Retry restarts the scene; Main Menu shows the best distance.
	await _go_and_wait(func() -> void: _press(game.game_over.get_node("%RetryButton")))
	assert_eq((_scene() as SwingGame).state, SwingGame.State.READY)
	await _go_and_wait(func() -> void: SceneRouter.go_to(MENU))
	var stats: Label = _scene().get_node("%Stats")
	assert_string_contains(stats.text, "%d m" % best)

	# Progress survives an app restart.
	SaveManager.data = {}
	SaveManager.load_data()
	assert_eq(int(SaveManager.get_value("stats", "best_distance", 0)), best)


func test_back_from_settings_goes_home() -> void:
	await SceneRouter.go_to("res://game/ui/settings.tscn")
	await _go_and_wait(SceneRouter.back)
	assert_eq(SceneRouter.current_scene_path(), MENU)
