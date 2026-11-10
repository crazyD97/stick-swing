extends Control
## Studio splash: shows briefly, tap to skip.

const NEXT_SCENE: String = "res://game/ui/main_menu.tscn"
@export var duration: float = 1.6

var _leaving: bool = false


func _ready() -> void:
	%Logo.modulate.a = 0.0
	create_tween().tween_property(%Logo, "modulate:a", 1.0, 0.4)
	%Figure.play(&"win")
	await get_tree().create_timer(duration).timeout
	_leave()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	SceneRouter.go_to(NEXT_SCENE)
