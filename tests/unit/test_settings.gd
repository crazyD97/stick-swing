extends GutTest

var _original_path: String
var _original_data: Dictionary


func before_each() -> void:
	_original_path = SaveManager.save_path
	_original_data = SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://test_settings_save.json"
	SaveManager.reset()
	Settings.reload()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path))
	SaveManager.save_path = _original_path
	SaveManager.data = _original_data
	Settings.reload()


func test_defaults() -> void:
	assert_almost_eq(Settings.music_volume, 0.7, 0.001)
	assert_true(Settings.vibration)


func test_volume_is_clamped_and_applied_to_bus() -> void:
	Settings.music_volume = 3.0
	assert_eq(Settings.music_volume, 1.0)
	Settings.sfx_volume = 0.5
	assert_almost_eq(AudioManager.get_bus_volume(AudioManager.BUS_SFX), 0.5, 0.01)


func test_zero_volume_mutes_bus() -> void:
	Settings.music_volume = 0.0
	var index: int = AudioServer.get_bus_index(AudioManager.BUS_MUSIC)
	assert_true(AudioServer.is_bus_mute(index))


func test_settings_persist_through_save_manager() -> void:
	Settings.vibration = false
	Settings.sfx_volume = 0.25
	SaveManager.save()
	SaveManager.load_data()
	Settings.reload()
	assert_false(Settings.vibration)
	assert_almost_eq(Settings.sfx_volume, 0.25, 0.001)


func test_change_emits_event() -> void:
	watch_signals(EventBus)
	Settings.vibration = false
	assert_signal_emitted_with_parameters(EventBus, "settings_changed", ["vibration", false])
