extends Control
## Title screen. "Play" continues from the furthest unlocked level.

const LEVEL_SELECT: String = "res://game/ui/level_select.tscn"
const SETTINGS: String = "res://game/ui/settings.tscn"
const MUSIC: String = "res://assets/audio/music/theme.wav"


func _ready() -> void:
	%Title.text = str(ProjectSettings.get_setting("application/config/name", "Game"))
	%PlayButton.pressed.connect(_on_play)
	%LevelsButton.pressed.connect(SceneRouter.go_to.bind(LEVEL_SELECT))
	%SettingsButton.pressed.connect(SceneRouter.go_to.bind(SETTINGS))
	%QuitButton.pressed.connect(get_tree().quit)
	%QuitButton.visible = not OS.has_feature("mobile")
	StudioUI.focus(%PlayButton)
	%Figure.play(&"run")
	%FigureSpace.resized.connect(_center_figure)
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	AudioManager.play_music(MUSIC)


func _on_play() -> void:
	var level: Dictionary = LevelCatalog.get_level(LevelCatalog.current_id())
	SceneRouter.go_to(level["scene"], {"level_id": level["id"]})


func _center_figure() -> void:
	%Figure.position.x = %FigureSpace.size.x / 2.0
