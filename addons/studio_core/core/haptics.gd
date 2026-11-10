extends Node
## Short vibrations that respect the player's setting. No-op on desktop.
## Android needs the VIBRATE permission (already enabled in export_presets.cfg).
##
##   Haptics.light()   Haptics.medium()   Haptics.heavy()   Haptics.buzz(80)

## Set true to log buzzes on desktop while testing.
var debug_log: bool = false


func buzz(duration_ms: int, amplitude: float = -1.0) -> void:
	if not Settings.vibration:
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, amplitude)
	elif debug_log:
		print("Haptics: buzz %d ms" % duration_ms)


func light() -> void:
	buzz(15, 0.3)


func medium() -> void:
	buzz(35, 0.6)


func heavy() -> void:
	buzz(80, 1.0)
