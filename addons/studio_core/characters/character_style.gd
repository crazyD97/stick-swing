class_name CharacterStyle
extends Resource
## Look and feel of one character, saved as a .tres in assets/characters/<name>/.
## Gameplay reads the movement numbers; the view reads the visuals.

@export_group("Look")
@export var color: Color = Color(0.1, 0.1, 0.12)
@export var accent_color: Color = Color(0.95, 0.35, 0.3)
@export var head_fill: Color = Color(1, 1, 1)
## Draws a little scarf in accent_color (set false for a plain stick figure).
@export var scarf: bool = true
@export var line_width: float = 10.0
## Total height in pixels from feet to top of head.
@export var height: float = 180.0
@export var head_scale: float = 1.0
@export var show_face: bool = true

@export_group("Movement")
@export var run_speed: float = 520.0
@export var jump_velocity: float = 1350.0
@export var gravity: float = 3000.0
