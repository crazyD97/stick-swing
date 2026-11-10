class_name Health
extends Node
## Drop-in health component. Add as a child, connect `died`.
##
##   $Health.damage(1)
##   $Health.died.connect(_on_died)

signal changed(current: int, max_value: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 3
## Seconds of invulnerability after taking damage.
@export var invulnerable_time: float = 0.0

var current: int
var _invulnerable_left: float = 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)


func is_dead() -> bool:
	return current <= 0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func damage(amount: int = 1) -> void:
	if is_dead() or is_invulnerable() or amount <= 0:
		return
	current = maxi(0, current - amount)
	_invulnerable_left = invulnerable_time
	damaged.emit(amount)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()


func heal(amount: int = 1) -> void:
	if is_dead() or amount <= 0:
		return
	var before: int = current
	current = mini(max_health, current + amount)
	if current != before:
		healed.emit(current - before)
		changed.emit(current, max_health)


func revive(invulnerable_seconds: float = 1.0) -> void:
	current = max_health
	_invulnerable_left = invulnerable_seconds
	changed.emit(current, max_health)
