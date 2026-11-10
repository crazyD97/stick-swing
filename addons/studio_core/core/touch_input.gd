extends Node
## Turns raw touches into gestures: tap, swipe, hold and drag.
## Only touches that no UI control consumed reach it (it uses _unhandled_input),
## so tapping a HUD button never also makes the character jump.
## On desktop, mouse clicks act as touches (input_devices/pointing/emulate_touch_from_mouse).
##
##   TouchInput.tapped.connect(func(pos: Vector2) -> void: player.jump())
##   TouchInput.swiped.connect(func(dir: Vector2) -> void: if dir == Vector2.UP: ...)
##
## For an on-screen stick, use Godot 4.7's built-in VirtualJoystick node in your HUD.

signal touch_started(position: Vector2)
signal touch_ended(position: Vector2)
signal tapped(position: Vector2)
## Direction is one of Vector2.UP/DOWN/LEFT/RIGHT.
signal swiped(direction: Vector2)
signal hold_started(position: Vector2)
signal dragged(position: Vector2, relative: Vector2)

## Thresholds in viewport pixels (base resolution 1080x1920).
@export var swipe_min_distance: float = 120.0
@export var tap_max_distance: float = 40.0
@export var tap_max_time: float = 0.3
@export var hold_time: float = 0.5
@export var enabled: bool = true

## index -> {start: Vector2, pos: Vector2, time: float, held: bool}
var _touches: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = {"start": touch.position, "pos": touch.position, "time": 0.0, "held": false}
			touch_started.emit(touch.position)
		elif _touches.has(touch.index):
			_finish(touch.index, touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.has(drag.index):
			_touches[drag.index]["pos"] = drag.position
			dragged.emit(drag.position, drag.relative)


func _process(delta: float) -> void:
	for index: int in _touches:
		var t: Dictionary = _touches[index]
		t["time"] = float(t["time"]) + delta
		var moved: float = (t["pos"] as Vector2).distance_to(t["start"])
		if not t["held"] and float(t["time"]) >= hold_time and moved <= tap_max_distance:
			t["held"] = true
			hold_started.emit(t["pos"])


func is_touching() -> bool:
	return not _touches.is_empty()


func _finish(index: int, end_pos: Vector2) -> void:
	var t: Dictionary = _touches[index]
	_touches.erase(index)
	touch_ended.emit(end_pos)
	var delta_pos: Vector2 = end_pos - (t["start"] as Vector2)
	var gesture: StringName = classify(delta_pos, float(t["time"]), bool(t["held"]))
	if gesture == &"tap":
		tapped.emit(end_pos)
	elif gesture == &"swipe":
		swiped.emit(direction_of(delta_pos))


## Pure helper, also used by tests: returns &"tap", &"swipe" or &"none".
func classify(delta_pos: Vector2, duration: float, held: bool) -> StringName:
	if delta_pos.length() >= swipe_min_distance:
		return &"swipe"
	if not held and duration <= tap_max_time and delta_pos.length() <= tap_max_distance:
		return &"tap"
	return &"none"


static func direction_of(delta_pos: Vector2) -> Vector2:
	if absf(delta_pos.x) > absf(delta_pos.y):
		return Vector2.RIGHT if delta_pos.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if delta_pos.y > 0.0 else Vector2.UP
