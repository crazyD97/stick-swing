class_name Obstacle
extends Area2D
## A box the player must jump over. Touching it kills the player.

@export var size: Vector2 = Vector2(90, 100):
	set(value):
		size = value
		_rebuild()
@export var color: Color = Color(0.85, 0.45, 0.2)


func _ready() -> void:
	collision_layer = 1 << 2  # hazard
	collision_mask = 1 << 0  # player
	monitorable = false
	add_to_group(&"obstacle")
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var shape_node: CollisionShape2D = get_node_or_null(^"Shape")
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "Shape"
		add_child(shape_node)
	var rect := RectangleShape2D.new()
	# Slightly smaller hitbox than the drawing feels fairer.
	rect.size = size * 0.85
	shape_node.shape = rect
	shape_node.position = Vector2(0, -size.y / 2.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(-size.x / 2.0, -size.y), size)
	draw_rect(r, color)
	draw_rect(r, color.darkened(0.45), false, 8.0)
	draw_line(r.position, r.end, color.darkened(0.3), 6.0)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), color.darkened(0.3), 6.0)
