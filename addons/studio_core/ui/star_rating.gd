@tool
class_name StarRating
extends Control
## Draws 0..max_stars filled stars (no font or texture needed).

@export_range(0, 5) var stars: int = 0:
	set(value):
		stars = value
		queue_redraw()
@export_range(1, 5) var max_stars: int = 3:
	set(value):
		max_stars = value
		update_minimum_size()
		queue_redraw()
@export var star_size: float = 120.0:
	set(value):
		star_size = value
		update_minimum_size()
		queue_redraw()
@export var filled_color: Color = Color(1, 0.82, 0.2)
@export var empty_color: Color = Color(1, 1, 1, 0.18)


func _get_minimum_size() -> Vector2:
	return Vector2(star_size * max_stars * 1.15, star_size)


func _draw() -> void:
	var total_width: float = star_size * max_stars * 1.15
	var start_x: float = (size.x - total_width) / 2.0 + star_size * 0.575
	for i: int in max_stars:
		var center := Vector2(start_x + i * star_size * 1.15, size.y / 2.0)
		draw_colored_polygon(star_points(center, star_size * 0.5), filled_color if i < stars else empty_color)


static func star_points(center: Vector2, outer: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 10:
		var r: float = outer if i % 2 == 0 else outer * 0.45
		var a: float = -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points
