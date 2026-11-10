extends GutTest

const TEST_PATH: String = "user://test_save.json"

var _original_path: String
var _original_data: Dictionary


func before_each() -> void:
	_original_path = SaveManager.save_path
	_original_data = SaveManager.data.duplicate(true)
	SaveManager.save_path = TEST_PATH
	SaveManager.reset()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SaveManager.save_path = _original_path
	SaveManager.data = _original_data


func test_values_survive_save_and_reload() -> void:
	SaveManager.set_value("stats", "jumps", 42)
	SaveManager.data = {}
	SaveManager.load_data()
	assert_eq(SaveManager.get_value("stats", "jumps", 0), 42)


func test_missing_key_returns_default() -> void:
	assert_eq(SaveManager.get_value("stats", "nope", "fallback"), "fallback")


func test_first_level_unlocked_by_default() -> void:
	assert_true(SaveManager.is_level_unlocked("level_01"))
	assert_false(SaveManager.is_level_unlocked("level_02"))


func test_record_result_keeps_best_and_unlocks_next() -> void:
	SaveManager.record_level_result("level_01", 2, 900, "level_02")
	SaveManager.record_level_result("level_01", 1, 300, "level_02")
	assert_eq(SaveManager.get_level_stars("level_01"), 2)
	assert_eq(SaveManager.get_best_score("level_01"), 900)
	assert_true(SaveManager.is_level_unlocked("level_02"))


func test_corrupt_file_falls_back_to_defaults() -> void:
	var f: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	SaveManager.load_data()
	assert_true(SaveManager.is_level_unlocked("level_01"))
	assert_eq(int(SaveManager.data["version"]), SaveManager.SAVE_VERSION)


func test_old_save_is_migrated_with_new_sections() -> void:
	var f: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 0, "stats": {"jumps": 5}}))
	f.close()
	SaveManager.load_data()
	assert_eq(SaveManager.get_value("stats", "jumps", 0), 5)
	assert_true(SaveManager.data.has("progress"))
	assert_eq(int(SaveManager.data["version"]), SaveManager.SAVE_VERSION)


func test_no_temp_file_left_behind() -> void:
	SaveManager.save()
	assert_true(FileAccess.file_exists(TEST_PATH))
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"))
