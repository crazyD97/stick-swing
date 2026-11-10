extends Node
## One analytics API. Today it is a STUB that prints events in debug builds.
## Phase 4 forwards these to Firebase (godot-x/firebase) behind the same calls.
##
##   Analytics.log_event("level_complete", {"level": "level_01", "stars": 3})

var enabled: bool = true
var verbose: bool = false


func _ready() -> void:
	EventBus.level_started.connect(func(id: String) -> void: log_event("level_start", {"level": id}))
	EventBus.level_won.connect(
		func(id: String, score: int, stars: int) -> void:
			log_event("level_complete", {"level": id, "score": score, "stars": stars})
	)
	EventBus.level_lost.connect(
		func(id: String, score: int) -> void: log_event("level_fail", {"level": id, "score": score})
	)


func log_event(event_name: String, params: Dictionary = {}) -> void:
	if not enabled:
		return
	if verbose and OS.is_debug_build():
		print("Analytics(stub): %s %s" % [event_name, params])
