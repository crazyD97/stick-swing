class_name Anchor
extends Node2D
## A ring the swinger can grab. Lights up when it is the one a press would grab.

const RADIUS: float = 26.0

var highlighted: bool = false:
	set(value):
		if value != highlighted:
			highlighted = value
			queue_redraw()
var used: bool = false:
	set(value):
		used = value
		queue_redraw()


func _draw() -> void:
	if highlighted:
		draw_circle(Vector2.ZERO, RADIUS * 2.0, Color(1, 0.85, 0.3, 0.25))
	var ring: Color = Color(1, 0.85, 0.3) if highlighted else Color(0.82, 0.85, 0.92)
	if used and not highlighted:
		ring = ring.darkened(0.35)
	draw_line(Vector2(0, -RADIUS - 40.0), Vector2(0, -RADIUS), Color(0.5, 0.53, 0.6), 8.0)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 28, ring, 10.0, true)
	draw_circle(Vector2(0, -RADIUS - 44.0), 10.0, Color(0.5, 0.53, 0.6))
