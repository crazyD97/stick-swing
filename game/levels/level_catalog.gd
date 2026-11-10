class_name LevelCatalog
extends RefCounted
## The ordered list of this game's levels. Level select, progress and "next level" read it.
## /add-level appends an entry here.

const LEVELS: Array[Dictionary] = [
	{"id": "level_01", "name": "First Steps", "scene": "res://game/levels/level_01.tscn"},
	{"id": "level_02", "name": "Box Jumper", "scene": "res://game/levels/level_02.tscn"},
	{"id": "level_03", "name": "Sunset Sprint", "scene": "res://game/levels/level_03.tscn"},
]


static func all() -> Array[Dictionary]:
	return LEVELS


static func count() -> int:
	return LEVELS.size()


static func index_of(level_id: String) -> int:
	for i: int in LEVELS.size():
		if LEVELS[i]["id"] == level_id:
			return i
	return -1


static func get_level(level_id: String) -> Dictionary:
	var i: int = index_of(level_id)
	return LEVELS[i] if i >= 0 else {}


## Id of the level after `level_id`, or "" for the last one.
static func next_id(level_id: String) -> String:
	var i: int = index_of(level_id)
	if i < 0 or i + 1 >= LEVELS.size():
		return ""
	return LEVELS[i + 1]["id"]


## The furthest unlocked level: where "Play" on the main menu takes you.
static func current_id() -> String:
	var result: String = LEVELS[0]["id"]
	for level: Dictionary in LEVELS:
		if SaveManager.is_level_unlocked(level["id"]):
			result = level["id"]
	return result
