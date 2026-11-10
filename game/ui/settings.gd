extends Control
## Sound, music, vibration, reset progress and credits.

const CREDITS: String = "res://game/ui/credits.tscn"

var _reset_armed: bool = false


func _ready() -> void:
	%MusicSlider.value = Settings.music_volume
	%SfxSlider.value = Settings.sfx_volume
	%VibrationToggle.button_pressed = Settings.vibration
	_update_vibration_label()
	%MusicSlider.value_changed.connect(func(v: float) -> void: Settings.music_volume = v)
	%SfxSlider.value_changed.connect(_on_sfx_changed)
	%VibrationToggle.toggled.connect(_on_vibration_toggled)
	%ResetButton.pressed.connect(_on_reset)
	%CreditsButton.pressed.connect(SceneRouter.go_to.bind(CREDITS))
	%BackButton.pressed.connect(SceneRouter.back)
	StudioUI.focus(%BackButton)


func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value
	AudioManager.play_sfx("coin")


func _on_vibration_toggled(on: bool) -> void:
	Settings.vibration = on
	_update_vibration_label()
	Haptics.medium()


func _update_vibration_label() -> void:
	%VibrationToggle.text = "Vibration: %s" % ("On" if Settings.vibration else "Off")


func _on_reset() -> void:
	# Two taps to confirm, so progress is never lost by accident.
	if not _reset_armed:
		_reset_armed = true
		%ResetButton.text = "Tap again to confirm"
		return
	SaveManager.reset()
	Settings.reload()
	%MusicSlider.set_value_no_signal(Settings.music_volume)
	%SfxSlider.set_value_no_signal(Settings.sfx_volume)
	%VibrationToggle.set_pressed_no_signal(Settings.vibration)
	_update_vibration_label()
	%ResetButton.text = "Progress reset"
	%ResetButton.disabled = true
