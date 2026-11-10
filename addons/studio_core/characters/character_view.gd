@tool
@abstract class_name CharacterView
extends Node2D
## The one interface every character style implements (stick figure, cartoon cutout, pixel art).
## Gameplay only ever calls play("run") / facing = -1 and never cares how it is drawn.
## The node's origin is at the character's feet.

signal animation_finished(anim_name: StringName)

const ANIMATIONS: Array[StringName] = [&"idle", &"run", &"jump", &"fall", &"hit", &"die", &"win"]
## These play once and then emit animation_finished; the rest loop.
const ONE_SHOTS: Array[StringName] = [&"hit", &"die"]

@export var style: CharacterStyle:
	set(value):
		style = value
		_on_style_changed()
## 1 = facing right, -1 = facing left.
@export var facing: int = 1:
	set(value):
		facing = -1 if value < 0 else 1
		scale.x = absf(scale.x) * facing
@export var autoplay: StringName = &"idle"

var current_animation: StringName = &""
## Seconds since the current animation started.
var anim_time: float = 0.0


func _ready() -> void:
	if style == null and not Engine.is_editor_hint():
		style = CharacterStyle.new()
	if autoplay != &"":
		play(autoplay)


func play(anim_name: StringName, restart: bool = false) -> void:
	if not anim_name in ANIMATIONS:
		push_warning("%s: unknown animation '%s'" % [name, anim_name])
		return
	if anim_name == current_animation and not restart:
		return
	current_animation = anim_name
	anim_time = 0.0
	_on_animation_started(anim_name)


func is_playing(anim_name: StringName) -> bool:
	return current_animation == anim_name


## Called when the style resource is replaced. Override to rebuild visuals.
func _on_style_changed() -> void:
	pass


## Called when a new animation starts. Override if the style needs setup per animation.
func _on_animation_started(_anim_name: StringName) -> void:
	pass
