class_name Player
extends CharacterBody2D
## The sample runner hero: runs right on its own, jumps on tap.
## Movement numbers come from its CharacterStyle so each character can feel different.

signal died

## Forgiveness windows that make touch jumping feel good.
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.15

@export var style: CharacterStyle

var running: bool = false
var alive: bool = true

var _coyote: float = 0.0
var _jump_buffer: float = 0.0

@onready var view: CharacterView = $View


func _ready() -> void:
	collision_layer = 1 << 0  # player
	collision_mask = 1 << 1  # world
	if style == null:
		style = CharacterStyle.new()
	view.style = style
	view.play(&"idle")


func start_running() -> void:
	running = true


func request_jump() -> void:
	_jump_buffer = JUMP_BUFFER_TIME


func _unhandled_input(event: InputEvent) -> void:
	if alive and event.is_action_pressed(&"jump"):
		request_jump()


func _physics_process(delta: float) -> void:
	velocity.y += style.gravity * delta
	if not alive:
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		move_and_slide()
		return

	velocity.x = style.run_speed if running else 0.0
	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_jump_buffer -= delta
	if running and _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = -style.jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0
		AudioManager.play_sfx("jump", randf_range(0.95, 1.05))
		Haptics.light()
	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if view.is_playing(&"win"):
		return
	if not is_on_floor():
		view.play(&"jump" if velocity.y < 0.0 else &"fall")
	elif running:
		view.play(&"run")
	else:
		view.play(&"idle")


func die() -> void:
	if not alive:
		return
	alive = false
	running = false
	velocity = Vector2(-300.0, -700.0)
	view.play(&"die")
	AudioManager.play_sfx("hit")
	Haptics.heavy()
	EventBus.player_died.emit()
	died.emit()


func revive() -> void:
	alive = true
	velocity = Vector2.ZERO
	view.play(&"idle", true)


func celebrate() -> void:
	running = false
	view.play(&"win")
