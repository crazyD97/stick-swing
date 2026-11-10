class_name Hud
extends CanvasLayer
## In-level overlay: score, coins, pause button and a start hint.

signal pause_pressed

@onready var _score: Label = %ScoreLabel
@onready var _coins: Label = %CoinsLabel
@onready var _hint: Label = %HintLabel
@onready var _pause: Button = %PauseButton


func _ready() -> void:
	_pause.pressed.connect(pause_pressed.emit)
	EventBus.score_changed.connect(set_score)
	EventBus.coins_changed.connect(set_coins)


func set_score(value: int) -> void:
	_score.text = str(value)


func set_coins(value: int) -> void:
	_coins.text = "Coins %d" % value


func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = text != ""
