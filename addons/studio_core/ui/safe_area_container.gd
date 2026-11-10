class_name SafeAreaContainer
extends MarginContainer
## Keeps its children out of notches, rounded corners and the gesture bar.
## Use it as the root of every screen's UI. `extra_margin` is added on all sides.

@export var extra_margin: int = 32


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var left: float = 0.0
	var top: float = 0.0
	var right: float = 0.0
	var bottom: float = 0.0
	if OS.has_feature("mobile") and window_size.x > 0.0 and safe.size.x > 0.0:
		# Convert from screen pixels to viewport (canvas) units.
		var scale: Vector2 = viewport_rect.size / window_size
		left = safe.position.x * scale.x
		top = safe.position.y * scale.y
		right = (window_size.x - safe.end.x) * scale.x
		bottom = (window_size.y - safe.end.y) * scale.y
	add_theme_constant_override("margin_left", int(left) + extra_margin)
	add_theme_constant_override("margin_top", int(top) + extra_margin)
	add_theme_constant_override("margin_right", int(right) + extra_margin)
	add_theme_constant_override("margin_bottom", int(bottom) + extra_margin)
