class_name ShakeCamera
extends Camera2D
## Camera2D with screen shake and optional horizontal follow.
##
##   $Camera.shake(0.6)    # strength 0..1, decays over time

@export var max_offset: Vector2 = Vector2(40, 30)
@export var decay: float = 2.5
## When set, the camera's x follows this node (plus follow_offset_x); y stays fixed.
@export var follow_target: Node2D
@export var follow_offset_x: float = 250.0

var _trauma: float = 0.0


func _ready() -> void:
	ignore_rotation = true


func shake(strength: float = 0.5) -> void:
	_trauma = minf(1.0, _trauma + strength)


func _process(delta: float) -> void:
	if is_instance_valid(follow_target):
		global_position.x = follow_target.global_position.x + follow_offset_x
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - decay * delta)
		var amount: float = _trauma * _trauma
		offset = Vector2(max_offset.x * amount * randf_range(-1, 1), max_offset.y * amount * randf_range(-1, 1))
	else:
		offset = Vector2.ZERO
