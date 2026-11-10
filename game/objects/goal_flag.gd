class_name GoalFlag
extends Area2D
## The finish line. Emits `reached` when the player touches it.

signal reached

var _t: float = 0.0
var _done: bool = false


func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 0
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 400)
	shape.shape = rect
	shape.position = Vector2(0, -200)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(_body: Node2D) -> void:
	if not _done:
		_done = true
		reached.emit()


func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -360), Color(0.9, 0.9, 0.95), 12.0)
	var wave: float = sin(_t * 6.0) * 14.0
	var flag := PackedVector2Array(
		[
			Vector2(6, -360),
			Vector2(150, -330 + wave),
			Vector2(6, -280),
		]
	)
	draw_colored_polygon(flag, Color(0.3, 0.85, 0.4))
	draw_circle(Vector2(0, -366), 14.0, Color(1, 0.85, 0.3))
