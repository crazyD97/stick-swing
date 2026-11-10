extends Control
## Title screen: best distance, wallet, Play.

const GAME: String = "res://game/swing/swing_game.tscn"
const SETTINGS: String = "res://game/ui/settings.tscn"
const MUSIC: String = "res://assets/audio/music/theme.wav"


func _ready() -> void:
	%Title.text = str(ProjectSettings.get_setting("application/config/name", "Game"))
	%PlayButton.pressed.connect(_on_play)
	%LevelsButton.visible = false
	%Stats.text = (
		"Best  %d m      Coins  %d"
		% [
			int(SaveManager.get_value("stats", "best_distance", 0)),
			int(SaveManager.get_value("stats", "coins", 0)),
		]
	)
	%SettingsButton.pressed.connect(SceneRouter.go_to.bind(SETTINGS))
	%QuitButton.pressed.connect(get_tree().quit)
	%QuitButton.visible = not OS.has_feature("mobile")
	StudioUI.focus(%PlayButton)
	%Figure.play(&"jump")
	%FigureSpace.resized.connect(_center_figure)
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	AudioManager.play_music(MUSIC)


func _on_play() -> void:
	SceneRouter.go_to(GAME)


func _center_figure() -> void:
	%Figure.position.x = %FigureSpace.size.x / 2.0
