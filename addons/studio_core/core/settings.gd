extends Node
## Player settings. Each property applies itself immediately and persists through SaveManager.
##
##   Settings.music_volume = 0.5
##   if Settings.vibration: ...

const SECTION: String = "settings"

var music_volume: float = 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, music_volume)
		_store("music_volume", music_volume)

var sfx_volume: float = 0.9:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		AudioManager.set_bus_volume(AudioManager.BUS_SFX, sfx_volume)
		_store("sfx_volume", sfx_volume)

var vibration: bool = true:
	set(value):
		vibration = value
		_store("vibration", vibration)

## Locale code, e.g. "en". Applied to TranslationServer.
var language: String = "en":
	set(value):
		language = value
		TranslationServer.set_locale(language)
		_store("language", language)

var _loading: bool = false
var _save_pending: bool = false


func _ready() -> void:
	reload()
	SaveManager.loaded.connect(reload)


## Re-reads every setting from SaveManager (call after SaveManager.reset()).
func reload() -> void:
	_loading = true
	music_volume = float(SaveManager.get_value(SECTION, "music_volume", 0.7))
	sfx_volume = float(SaveManager.get_value(SECTION, "sfx_volume", 0.9))
	vibration = bool(SaveManager.get_value(SECTION, "vibration", true))
	language = str(SaveManager.get_value(SECTION, "language", "en"))
	_loading = false


func _store(key: String, value: Variant) -> void:
	if _loading or not is_inside_tree():
		return
	SaveManager.set_value(SECTION, key, value, false)
	EventBus.settings_changed.emit(key, value)
	_queue_save()


## Sliders fire many changes per second; batch them into one disk write.
func _queue_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	await get_tree().create_timer(0.4, true).timeout
	_save_pending = false
	SaveManager.save()
