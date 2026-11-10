class_name Swinger
extends Node2D
## The rope-swinging stick figure. Its origin is the grip point (hands); the figure hangs below.
## Physics is hand-rolled and deterministic: SwingGame calls step(delta) once per physics tick.
##
## Rope model: while attached, the grip can never be further from the anchor than rope_length
## (a taut rope pulls, a slack rope does not push). A small forward "pump" keeps swings lively.

signal grabbed(anchor: Anchor)
signal released
signal died

enum State { READY, FLYING, SWINGING, DEAD }

## Distance from the grip point down to the feet.
const GRIP_TO_FEET: float = 178.0

@export var style: CharacterStyle
@export var gravity: float = 2200.0
@export var min_rope: float = 140.0
@export var max_rope: float = 650.0
## Forward acceleration while swinging forward (px/s²).
@export var pump: float = 420.0
@export var max_speed: float = 2600.0

var state: State = State.READY
var velocity: Vector2 = Vector2.ZERO
var anchor: Anchor = null
var rope_length: float = 0.0

@onready var view: CharacterView = $View


func _ready() -> void:
	if style:
		view.style = style
	view.play(&"idle")
	view.position = Vector2(0, GRIP_TO_FEET)


func launch(initial_velocity: Vector2) -> void:
	state = State.FLYING
	velocity = initial_velocity
	AudioManager.play_sfx("jump")
	Haptics.light()


func attach(target: Anchor) -> void:
	if state == State.DEAD or target == null:
		return
	anchor = target
	anchor.used = true
	rope_length = clampf(global_position.distance_to(target.global_position), min_rope, max_rope)
	state = State.SWINGING
	AudioManager.play_sfx("jump", 1.3)
	Haptics.light()
	grabbed.emit(target)


func release() -> void:
	if state != State.SWINGING:
		return
	anchor = null
	state = State.FLYING
	released.emit()


func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	anchor = null
	velocity = Vector2(velocity.x * 0.2, -400.0)
	view.play(&"die")
	AudioManager.play_sfx("hit")
	Haptics.heavy()
	EventBus.player_died.emit()
	died.emit()


## Continue after an ad: hang from `target` with a forward push.
func revive_on(target: Anchor) -> void:
	state = State.FLYING
	global_position = target.global_position + Vector2(-120.0, 260.0)
	velocity = Vector2(900.0, 0.0)
	view.play(&"jump", true)
	attach(target)


func step(delta: float) -> void:
	if state == State.READY:
		return
	velocity.y += gravity * delta
	if state == State.SWINGING:
		var out: Vector2 = (global_position - anchor.global_position).normalized()
		var tangent := Vector2(-out.y, out.x)
		if tangent.x < 0.0:
			tangent = -tangent
		if velocity.dot(tangent) > 0.0:
			velocity += tangent * pump * delta
	velocity = velocity.limit_length(max_speed)
	global_position += velocity * delta
	if state == State.SWINGING:
		var offset: Vector2 = global_position - anchor.global_position
		if offset.length() > rope_length:
			var dir: Vector2 = offset.normalized()
			global_position = anchor.global_position + dir * rope_length
			var radial: float = velocity.dot(dir)
			if radial > 0.0:
				velocity -= dir * radial


func _process(delta: float) -> void:
	_update_view(delta)
	queue_redraw()


func _update_view(delta: float) -> void:
	var target_rot: float = 0.0
	match state:
		State.SWINGING:
			target_rot = (anchor.global_position - global_position).angle() + PI / 2.0
			view.play(&"jump")
		State.FLYING:
			target_rot = clampf(velocity.x * 0.0002, -0.4, 0.4)
			view.play(&"jump" if velocity.y < 0.0 else &"fall")
	if state != State.DEAD:
		view.rotation = lerp_angle(view.rotation, target_rot, 1.0 - exp(-14.0 * delta))
		view.position = Vector2(0, GRIP_TO_FEET).rotated(view.rotation)


func _draw() -> void:
	if state == State.SWINGING and is_instance_valid(anchor):
		draw_line(Vector2.ZERO, to_local(anchor.global_position), Color(0.95, 0.9, 0.75), 6.0, true)
