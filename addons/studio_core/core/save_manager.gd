extends Node
## Versioned JSON save file in user://. Holds settings, level progress and anything else a game needs.
##
##   SaveManager.set_value("stats", "jumps", 12)   # sections are free-form dictionaries
##   SaveManager.get_value("stats", "jumps", 0)
##   SaveManager.record_level_result("level_01", 3, 1200)
##
## Writes are atomic (temp file + rename) so a crash mid-save never corrupts progress.

signal saved
signal loaded

## Bump when the save layout changes, and add a step to _migrate().
const SAVE_VERSION: int = 1
const DEFAULT_PATH: String = "user://save.json"

## Tests point this at a throwaway file.
var save_path: String = DEFAULT_PATH
var data: Dictionary = {}


func _ready() -> void:
	load_data()


func _notification(what: int) -> void:
	# Persist when the app goes to background or closes: on Android the OS may kill it afterwards.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"settings": {},
		"progress": {"levels": {}, "unlocked": ["level_01"]},
		"purchases": {},
		"stats": {},
	}


func load_data() -> void:
	data = default_data()
	if FileAccess.file_exists(save_path):
		var text: String = FileAccess.get_file_as_string(save_path)
		var json := JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			data = _migrate(json.data as Dictionary)
		else:
			push_warning("SaveManager: save file unreadable, starting fresh (%s)" % save_path)
	loaded.emit()


func save() -> bool:
	data["version"] = SAVE_VERSION
	var tmp_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var err: Error = DirAccess.rename_absolute(tmp_path, save_path)
	if err != OK:
		push_error("SaveManager: rename failed (%s)" % error_string(err))
		return false
	saved.emit()
	return true


## Wipes all progress and settings (used by the settings screen and tests).
func reset() -> void:
	data = default_data()
	save()


func get_section(section: String) -> Dictionary:
	if not data.has(section) or not (data[section] is Dictionary):
		data[section] = {}
	return data[section]


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return get_section(section).get(key, default)


func set_value(section: String, key: String, value: Variant, autosave: bool = true) -> void:
	get_section(section)[key] = value
	if autosave:
		save()


# --- Level progress ---------------------------------------------------------


func is_level_unlocked(level_id: String) -> bool:
	return level_id in _unlocked()


func unlock_level(level_id: String) -> void:
	var unlocked: Array = _unlocked()
	if not level_id in unlocked:
		unlocked.append(level_id)
		save()


func get_level_stars(level_id: String) -> int:
	return int(_level_entry(level_id).get("stars", 0))


func get_best_score(level_id: String) -> int:
	return int(_level_entry(level_id).get("best_score", 0))


## Keeps the best stars and score; unlocks `next_level_id` when given.
func record_level_result(level_id: String, stars: int, score: int, next_level_id: String = "") -> void:
	var levels: Dictionary = get_section("progress").get_or_add("levels", {})
	var entry: Dictionary = levels.get_or_add(level_id, {})
	entry["stars"] = maxi(int(entry.get("stars", 0)), stars)
	entry["best_score"] = maxi(int(entry.get("best_score", 0)), score)
	entry["completed"] = true
	if next_level_id != "" and not next_level_id in _unlocked():
		_unlocked().append(next_level_id)
	save()


func _unlocked() -> Array:
	return get_section("progress").get_or_add("unlocked", ["level_01"])


func _level_entry(level_id: String) -> Dictionary:
	var levels: Dictionary = get_section("progress").get("levels", {})
	return levels.get(level_id, {})


# --- Migration ---------------------------------------------------------------


func _migrate(loaded_data: Dictionary) -> Dictionary:
	var version: int = int(loaded_data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveManager: save is from a newer build (v%d); loading as-is" % version)
	# Example for the future:
	# if version < 2:
	#     loaded_data["stats"] = loaded_data.get("stats", {})
	#     version = 2
	var result: Dictionary = default_data()
	result.merge(loaded_data, true)
	result["version"] = SAVE_VERSION
	return result
