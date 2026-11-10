class_name PauseMenu
extends CanvasLayer
## Pause overlay. Keeps running while the tree is paused.

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var _resume: Button = %ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(resume_pressed.emit)
	%RestartButton.pressed.connect(restart_pressed.emit)
	%MenuButton.pressed.connect(menu_pressed.emit)
	visibility_changed.connect(_on_visibility_changed)
	hide()


func _on_visibility_changed() -> void:
	if visible:
		StudioUI.focus(_resume)
