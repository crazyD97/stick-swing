class_name Coin
extends Area2D
## A collectible. Emits `collected` once and disappears.

signal collected(coin: Coin)

@export var radius: float = 34.0
@export var value: int = 1

var _taken: bool = false
var _t: float = randf() * TAU


func _ready() -> void:
	collision_layer = 1 << 3  # pickup
	collision_mask = 1 << 0  # player
	monitorable = false
	add_to_group(&"coin")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(_body: Node2D) -> void:
	if _taken:
		return
	_taken = true
	collected.emit(self)
	set_deferred(&"monitoring", false)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 120.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	# Fake a spinning coin by squashing it horizontally.
	var squash: float = absf(cos(_t * 3.0)) * 0.7 + 0.3
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash, 1.0))
	draw_circle(Vector2.ZERO, radius, Color(1, 0.8, 0.15))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.75, 0.5, 0.05), 6.0, true)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 0.9, 0.45))
	draw_set_transform(Vector2.ZERO)
