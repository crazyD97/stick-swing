class_name Level
extends Node2D
## Base for every level of the sample runner. A level scene is just this script plus data:
## obstacle and coin positions, length and colours. It builds the world, HUD and overlays,
## and runs the flow: ready -> running -> won/lost, with pause and "continue after ad".
## You can also hand-place Obstacle and Coin nodes as children; they are picked up too.

enum State { READY, RUNNING, WON, LOST }

const HUD_SCENE: PackedScene = preload("res://game/ui/hud.tscn")
const PAUSE_SCENE: PackedScene = preload("res://game/ui/pause_menu.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://game/ui/game_over.tscn")
const MUSIC: String = "res://assets/audio/music/theme.wav"
const GROUND_Y: float = 1300.0

@export var level_id: String = "level_01"
## Distance in pixels from start to the finish flag.
@export var level_length: float = 5000.0
## One entry per box: x = position, y = height in pixels.
@export var obstacles: PackedVector2Array = PackedVector2Array()
## One entry per coin: x = position, y = height above the ground.
@export var coins: PackedVector2Array = PackedVector2Array()
@export_group("Look")
@export var sky_color: Color = Color(0.53, 0.78, 0.98)
@export var ground_color: Color = Color(0.36, 0.72, 0.36)
@export var dirt_color: Color = Color(0.45, 0.3, 0.2)

var state: State = State.READY
var score: int = 0
var coins_collected: int = 0
var total_coins: int = 0
var used_continue: bool = false

var camera: ShakeCamera
var hud: Hud
var pause_menu: PauseMenu
var game_over: GameOver

var _killer: Node = null

@onready var player: Player = $Player


func _ready() -> void:
	_build_world()
	_build_ui()
	player.position = Vector2(0.0, GROUND_Y)
	player.died.connect(_on_player_died)
	TouchInput.touch_started.connect(_on_touch)
	EventBus.score_changed.emit(0)
	EventBus.coins_changed.emit(0)
	EventBus.level_started.emit(level_id)
	AudioManager.play_music(MUSIC)


func _physics_process(_delta: float) -> void:
	if state != State.RUNNING:
		return
	var distance_score: int = int(maxf(0.0, player.position.x) / 10.0)
	var new_score: int = distance_score + coins_collected * 100
	if new_score != score:
		score = new_score
		EventBus.score_changed.emit(score)
	if player.position.y > GROUND_Y + 600.0:
		player.die()


func _notification(what: int) -> void:
	# Auto-pause when the player switches apps or gets a call.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.RUNNING:
		set_paused(true)


## Called by SceneRouter for the Android back button / Escape.
func handle_back() -> bool:
	if get_tree().paused:
		set_paused(false)
		return true
	if state == State.READY or state == State.RUNNING:
		set_paused(true)
		return true
	return false


func set_paused(paused: bool) -> void:
	if state == State.WON or state == State.LOST:
		return
	get_tree().paused = paused
	pause_menu.visible = paused
	EventBus.game_paused.emit(paused)


func start() -> void:
	if state != State.READY:
		return
	state = State.RUNNING
	hud.show_hint("")
	player.start_running()


# --- Flow --------------------------------------------------------------------


func _on_touch(_pos: Vector2) -> void:
	if get_tree().paused:
		return
	if state == State.READY:
		start()
	if state == State.RUNNING:
		player.request_jump()


func _on_hazard_body_entered(body: Node2D, hazard: Node) -> void:
	if body == player and state == State.RUNNING:
		_killer = hazard
		camera.shake(0.7)
		player.die()


func _on_coin_collected(_coin: Coin) -> void:
	coins_collected += 1
	EventBus.coins_changed.emit(coins_collected)
	AudioManager.play_sfx("coin", randf_range(0.97, 1.08))
	Haptics.light()


func _on_goal_reached() -> void:
	if state != State.RUNNING:
		return
	state = State.WON
	player.celebrate()
	var stars: int = calculate_stars(coins_collected, total_coins)
	score += 500
	EventBus.score_changed.emit(score)
	var next_id: String = LevelCatalog.next_id(level_id)
	SaveManager.record_level_result(level_id, stars, score, next_id)
	EventBus.level_won.emit(level_id, score, stars)
	AudioManager.play_sfx("win")
	Haptics.medium()
	await get_tree().create_timer(1.2).timeout
	game_over.show_result(true, score, stars, SaveManager.get_best_score(level_id), next_id != "", false)


func _on_player_died() -> void:
	if state != State.RUNNING:
		return
	state = State.LOST
	EventBus.level_lost.emit(level_id, score)
	await get_tree().create_timer(1.0).timeout
	AudioManager.play_sfx("lose")
	game_over.show_result(false, score, 0, SaveManager.get_best_score(level_id), false, not used_continue)


func _on_continue_pressed() -> void:
	var rewarded: bool = await Ads.show_rewarded("continue")
	if not rewarded:
		return
	used_continue = true
	game_over.hide()
	if is_instance_valid(_killer):
		_killer.queue_free()
	player.position = Vector2(player.position.x, GROUND_Y)
	player.revive()
	state = State.RUNNING
	player.start_running()


## 1 star for finishing, +1 for half the coins, +1 for all of them.
static func calculate_stars(collected: int, total: int) -> int:
	if total <= 0:
		return 3
	var stars: int = 1
	if collected * 2 >= total:
		stars += 1
	if collected >= total:
		stars += 1
	return stars


# --- Building ----------------------------------------------------------------


func _build_world() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := ColorRect.new()
	sky.color = sky_color
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_layer.add_child(sky)
	add_child(sky_layer)

	var ground := StaticBody2D.new()
	ground.name = "Ground"
	ground.collision_layer = 1 << 1
	ground.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(level_length + 6000.0, 400.0)
	shape.shape = rect
	shape.position = Vector2(level_length / 2.0, GROUND_Y + 200.0)
	ground.add_child(shape)
	add_child(ground)

	for data: Vector2 in obstacles:
		var box := Obstacle.new()
		box.size = Vector2(90.0, data.y)
		box.position = Vector2(data.x, GROUND_Y)
		add_child(box)
	for data: Vector2 in coins:
		var coin := Coin.new()
		coin.position = Vector2(data.x, GROUND_Y - data.y)
		add_child(coin)

	var goal := GoalFlag.new()
	goal.position = Vector2(level_length, GROUND_Y)
	goal.reached.connect(_on_goal_reached)
	add_child(goal)

	# Wire everything, including hand-placed children.
	for hazard: Node in get_tree().get_nodes_in_group(&"obstacle"):
		if is_ancestor_of(hazard) and hazard is Area2D:
			(hazard as Area2D).body_entered.connect(_on_hazard_body_entered.bind(hazard))
	for node: Node in get_tree().get_nodes_in_group(&"coin"):
		if is_ancestor_of(node) and node is Coin:
			(node as Coin).collected.connect(_on_coin_collected)
			total_coins += 1

	camera = ShakeCamera.new()
	camera.follow_target = player
	camera.position = Vector2(player.position.x + 250.0, GROUND_Y - 250.0)
	add_child(camera)
	camera.make_current()
	move_child(player, -1)


func _build_ui() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.pause_pressed.connect(set_paused.bind(true))
	hud.show_hint("Tap to start!")

	pause_menu = PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.resume_pressed.connect(set_paused.bind(false))
	pause_menu.restart_pressed.connect(SceneRouter.reload)
	pause_menu.menu_pressed.connect(SceneRouter.go_to.bind(SceneRouter.home_scene))

	game_over = GAME_OVER_SCENE.instantiate()
	add_child(game_over)
	game_over.retry_pressed.connect(SceneRouter.reload)
	game_over.menu_pressed.connect(SceneRouter.go_to.bind(SceneRouter.home_scene))
	game_over.continue_pressed.connect(_on_continue_pressed)
	game_over.next_pressed.connect(_on_next_pressed)


func _on_next_pressed() -> void:
	var next: Dictionary = LevelCatalog.get_level(LevelCatalog.next_id(level_id))
	if next.is_empty():
		SceneRouter.go_to(SceneRouter.home_scene)
		return
	Ads.show_interstitial()
	SceneRouter.go_to(next["scene"], {"level_id": next["id"]})


func _draw() -> void:
	# Scenery is static, so it is drawn once: hills behind, then dirt and grass, then clouds.
	var left: float = -2000.0
	var width: float = level_length + 6000.0
	var hill_color: Color = ground_color.darkened(0.12)
	var x: float = left
	var i: int = 0
	while x < left + width:
		var r: float = 260.0 + float((i * 97) % 180)
		draw_circle(Vector2(x, GROUND_Y + r * 0.55), r, hill_color)
		var cloud := Vector2(x + 300.0, GROUND_Y - 800.0 - float((i * 53) % 400))
		for k: int in 3:
			draw_circle(
				cloud + Vector2(k * 70.0 - 70.0, -absf(k - 1.0) * -25.0),
				60.0 - absf(k - 1.0) * 15.0,
				Color(1, 1, 1, 0.85)
			)
		x += 700.0 + float((i * 131) % 400)
		i += 1
	draw_rect(Rect2(left, GROUND_Y, width, 1400.0), dirt_color)
	draw_rect(Rect2(left, GROUND_Y, width, 40.0), ground_color)
