class_name GameOver
extends CanvasLayer
## End-of-level overlay for both outcomes. Call show_result() to fill it in.

signal next_pressed
signal retry_pressed
signal menu_pressed
signal continue_pressed

@onready var _title: Label = %Title
@onready var _stars: StarRating = %Stars
@onready var _score: Label = %ScoreLabel
@onready var _best: Label = %BestLabel
@onready var _next: Button = %NextButton
@onready var _continue: Button = %ContinueButton
@onready var _retry: Button = %RetryButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_next.pressed.connect(next_pressed.emit)
	_retry.pressed.connect(retry_pressed.emit)
	%MenuButton.pressed.connect(menu_pressed.emit)
	_continue.pressed.connect(_on_continue)
	hide()


func show_result(won: bool, score: int, stars: int, best: int, has_next: bool, can_continue: bool) -> void:
	_title.text = "Level Complete!" if won else "Ouch!"
	_stars.visible = won
	_stars.stars = stars
	_score.text = "Score  %d" % score
	_best.text = "Best  %d" % best
	_next.visible = won and has_next
	_continue.visible = not won and can_continue
	_continue.disabled = false
	show()
	var first: Button = _next if _next.visible else _retry
	StudioUI.focus(first)
	var panel: Control = %Panel
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


func _on_continue() -> void:
	_continue.disabled = true
	continue_pressed.emit()
