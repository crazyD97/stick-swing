class_name SwingGame
extends Node2D
## Endless rope swinger. Hold anywhere to grab the highlighted ring, let go to fly. Don't fall in the lava.
## Score = distance in metres (100 px = 1 m). Coins go to the wallet in the save file.
##
## All per-tick logic lives in tick(delta) so tests (and a bot) can simulate the game quickly.

signal game_over_shown

enum State { READY, PLAYING, OVER }

const HUD_SCENE: PackedScene = preload("res://game/ui/hud.tscn")
const PAUSE_SCENE: PackedScene = preload("res://game/ui/pause_menu.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://game/ui/game_over.tscn")
const MUSIC: String = "res://assets/audio/music/theme.wav"

const PLATFORM_TOP: float = 1100.0
const LAVA_Y: float = 1750.0
const GRAB_RANGE: float = 640.0
const LAUNCH_VELOCITY: Vector2 = Vector2(780.0, -1150.0)
const PIXELS_PER_METRE: float = 100.0
const GENERATE_AHEAD: float = 2600.0
const CLEANUP_BEHIND: float = 1600.0
const COIN_PICKUP_RADIUS: float = 95.0
const MIN_ANCHOR_Y: float = 260.0
const MAX_ANCHOR_Y: float = 760.0

## 0 = random every run. Tests set a fixed seed.
@export var rng_seed: int = 0

var state: State = State.READY
var score: int = 0
var coins_collected: int = 0
var used_continue: bool = false
var holding: bool = false
var anchors: Array[Anchor] = []
var coins: Array[Coin] = []
var target: Anchor = null

var swinger: Swinger
var camera: ShakeCamera
var hud: Hud
var pause_menu: PauseMenu
var game_over: GameOver

var _rng := RandomNumberGenerator.new()
var _next_x: float = 520.0
var _prev_y: float = 480.0
var _clouds: PackedVector2Array = PackedVector2Array()
var _time: float = 0.0


func _ready() -> void:
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	_build_sky()
	swinger = $Swinger
	swinger.global_position = Vector2(170.0, PLATFORM_TOP - Swinger.GRIP_TO_FEET)
	swinger.died.connect(_on_swinger_died)
	_generate_until(swinger.global_position.x + GENERATE_AHEAD)
	camera = ShakeCamera.new()
	camera.follow_target = swinger
	camera.follow_offset_x = 220.0
	camera.position = Vector2(swinger.position.x + 220.0, 960.0)
	add_child(camera)
	camera.make_current()
	_build_ui()
	TouchInput.touch_started.connect(func(_p: Vector2) -> void: press())
	TouchInput.touch_ended.connect(func(_p: Vector2) -> void: release_hold())
	EventBus.score_changed.emit(0)
	EventBus.coins_changed.emit(0)
	EventBus.level_started.emit("endless")
	AudioManager.play_music(MUSIC)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump") and not event.is_echo():
		press()
	elif event.is_action_released(&"jump"):
		release_hold()


func _physics_process(delta: float) -> void:
	tick(delta)


func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(swinger):
		var want_y: float = minf(960.0, swinger.global_position.y + 450.0)
		camera.position.y = lerpf(camera.position.y, want_y, 1.0 - exp(-4.0 * delta))
	queue_redraw()


# --- Player input -------------------------------------------------------------


## Finger down: start the run, or grab the highlighted ring (or the next one that comes in range).
func press() -> void:
	if get_tree().paused or state == State.OVER:
		return
	holding = true
	if state == State.READY:
		_start()
		return
	_try_grab()


## Finger up: let go of the rope.
func release_hold() -> void:
	holding = false
	if state == State.PLAYING:
		swinger.release()


func _start() -> void:
	state = State.PLAYING
	hud.show_hint("")
	swinger.launch(LAUNCH_VELOCITY)


func _try_grab() -> void:
	if state == State.PLAYING and swinger.state == Swinger.State.FLYING and target != null:
		swinger.attach(target)


# --- Simulation ---------------------------------------------------------------


func tick(delta: float) -> void:
	if state == State.READY:
		_update_target()
		return
	swinger.step(delta)
	if state != State.PLAYING:
		return
	_update_target()
	if holding:
		_try_grab()
	_collect_coins()
	var metres: int = int(maxf(0.0, swinger.global_position.x - 170.0) / PIXELS_PER_METRE)
	if metres > score:
		score = metres
		EventBus.score_changed.emit(score)
	_generate_until(swinger.global_position.x + GENERATE_AHEAD)
	_cleanup_behind(swinger.global_position.x - CLEANUP_BEHIND)
	if swinger.global_position.y > LAVA_Y:
		swinger.die()


## The ring a press would grab: the nearest one that is ahead (or just behind), above-ish and in range.
func find_target() -> Anchor:
	var best: Anchor = null
	var best_d: float = GRAB_RANGE
	var p: Vector2 = swinger.global_position
	for a: Anchor in anchors:
		var ap: Vector2 = a.global_position
		if ap.x < p.x - 80.0 or ap.y > p.y + 60.0:
			continue
		var d: float = p.distance_to(ap)
		if d <= best_d:
			best_d = d
			best = a
	return best


func _update_target() -> void:
	var swinging: bool = swinger.state == Swinger.State.SWINGING
	target = null if swinging or swinger.state == Swinger.State.DEAD else find_target()
	for a: Anchor in anchors:
		a.highlighted = a == target and state == State.PLAYING


func _collect_coins() -> void:
	var grip: Vector2 = swinger.global_position + Vector2(0, 80)
	for i: int in range(coins.size() - 1, -1, -1):
		var coin: Coin = coins[i]
		if coin.global_position.distance_to(grip) < COIN_PICKUP_RADIUS:
			# The coin frees itself after its pop animation, so forget it now.
			coins.remove_at(i)
			coin.collect()
			coins_collected += 1
			EventBus.coins_changed.emit(coins_collected)
			AudioManager.play_sfx("coin", randf_range(0.97, 1.08))


# --- World generation ---------------------------------------------------------


## How hard the course is at x: 0 at the start, 1 from about 400 m on.
static func difficulty_at(x: float) -> float:
	return clampf(x / 40000.0, 0.0, 1.0)


func _generate_until(limit_x: float) -> void:
	while _next_x < limit_x:
		var d: float = difficulty_at(_next_x)
		# Random walk with a pull back to the middle so rings don't hug the top or bottom.
		var mid: float = (MIN_ANCHOR_Y + MAX_ANCHOR_Y) / 2.0
		var y: float = _prev_y + (mid - _prev_y) * 0.3 + _rng.randf_range(-240.0, 240.0)
		y = clampf(y, MIN_ANCHOR_Y, MAX_ANCHOR_Y)
		var pos := Vector2(_next_x, y)
		if not anchors.is_empty() and _rng.randf() < 0.6:
			_spawn_coin_arc(anchors[-1].global_position, pos)
		var a := Anchor.new()
		a.position = pos
		add_child(a)
		anchors.append(a)
		if _rng.randf() < 0.5:
			_clouds.append(Vector2(_next_x + _rng.randf_range(-200, 200), _rng.randf_range(-300, 200)))
		_prev_y = y
		_next_x += _rng.randf_range(360.0 + 160.0 * d, 480.0 + 260.0 * d)


func _spawn_coin_arc(from: Vector2, to: Vector2) -> void:
	var base_y: float = maxf(from.y, to.y) + 300.0
	for t: float in [0.3, 0.5, 0.7]:
		var coin := Coin.new()
		coin.position = Vector2(lerpf(from.x, to.x, t), base_y - sin(t * PI) * 90.0)
		coin.monitoring = false
		add_child(coin)
		coins.append(coin)


func _cleanup_behind(limit_x: float) -> void:
	while not anchors.is_empty() and anchors[0].global_position.x < limit_x and anchors[0] != swinger.anchor:
		anchors.pop_front().queue_free()
	# `coins` only holds coins that are still on screen (collected ones are removed immediately).
	while not coins.is_empty() and coins[0].global_position.x < limit_x:
		coins.pop_front().queue_free()


# --- Game over / continue -----------------------------------------------------


func _on_swinger_died() -> void:
	if state != State.PLAYING:
		return
	state = State.OVER
	holding = false
	camera.shake(0.6)
	var best: int = int(SaveManager.get_value("stats", "best_distance", 0))
	var new_best: bool = score > best
	if new_best:
		SaveManager.set_value("stats", "best_distance", score, false)
	var wallet: int = int(SaveManager.get_value("stats", "coins", 0))
	SaveManager.set_value("stats", "coins", wallet + coins_collected, false)
	coins_collected = 0
	SaveManager.save()
	EventBus.level_lost.emit("endless", score)
	await get_tree().create_timer(1.0).timeout
	AudioManager.play_sfx("win" if new_best else "lose")
	game_over.show_result(false, score, 0, maxi(best, score), false, not used_continue)
	game_over.set_title("New best!" if new_best else "Splash!")
	game_over_shown.emit()


func _on_continue_pressed() -> void:
	var rewarded: bool = await Ads.show_rewarded("continue")
	if not rewarded:
		return
	used_continue = true
	game_over.hide()
	var revive_anchor: Anchor = null
	for a: Anchor in anchors:
		if a.global_position.x >= swinger.global_position.x - 150.0:
			revive_anchor = a
			break
	if revive_anchor == null:
		revive_anchor = anchors[-1]
	state = State.PLAYING
	swinger.revive_on(revive_anchor)
	holding = false


## Called by SceneRouter for the Android back button / Escape.
func handle_back() -> bool:
	if get_tree().paused:
		set_paused(false)
		return true
	if state != State.OVER:
		set_paused(true)
		return true
	return false


func set_paused(paused: bool) -> void:
	if state == State.OVER:
		return
	holding = false
	get_tree().paused = paused
	pause_menu.visible = paused
	EventBus.game_paused.emit(paused)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		set_paused(true)


# --- Building -----------------------------------------------------------------


func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.16, 0.18, 0.42))
	gradient.set_color(1, Color(0.98, 0.62, 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = tex
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sky)
	add_child(layer)


func _build_ui() -> void:
	hud = HUD_SCENE.instantiate()
	hud.score_suffix = " m"
	add_child(hud)
	hud.pause_pressed.connect(set_paused.bind(true))
	hud.show_hint("Hold to grab a ring\nlet go to fly")

	pause_menu = PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.resume_pressed.connect(set_paused.bind(false))
	pause_menu.restart_pressed.connect(SceneRouter.reload)
	pause_menu.menu_pressed.connect(SceneRouter.go_to.bind(SceneRouter.home_scene))

	game_over = GAME_OVER_SCENE.instantiate()
	game_over.score_suffix = " m"
	add_child(game_over)
	game_over.retry_pressed.connect(SceneRouter.reload)
	game_over.menu_pressed.connect(SceneRouter.go_to.bind(SceneRouter.home_scene))
	game_over.continue_pressed.connect(_on_continue_pressed)


func _draw() -> void:
	var cam_x: float = camera.global_position.x if camera else 540.0
	var left: float = cam_x - 1200.0
	var right: float = cam_x + 1200.0
	for c: Vector2 in _clouds:
		if c.x > left - 200.0 and c.x < right + 200.0:
			for k: int in 3:
				draw_circle(
					c + Vector2(k * 75.0 - 75.0, absf(k - 1.0) * 20.0),
					62.0 - absf(k - 1.0) * 16.0,
					Color(1, 1, 1, 0.55)
				)
	# Start platform.
	if left < 400.0:
		draw_rect(Rect2(20.0, PLATFORM_TOP, 300.0, 50.0), Color(0.45, 0.3, 0.2))
		draw_rect(Rect2(140.0, PLATFORM_TOP + 50.0, 60.0, LAVA_Y - PLATFORM_TOP), Color(0.35, 0.23, 0.16))
	# Lava with a wobbling surface.
	var surface := PackedVector2Array()
	var x: float = left
	while x <= right:
		surface.append(Vector2(x, LAVA_Y + 40.0 + sin(x * 0.01 + _time * 3.0) * 14.0))
		x += 60.0
	surface.append(Vector2(right, LAVA_Y + 1600.0))
	surface.append(Vector2(left, LAVA_Y + 1600.0))
	draw_colored_polygon(surface, Color(0.95, 0.35, 0.12))
	draw_polyline(surface.slice(0, surface.size() - 2), Color(1, 0.75, 0.25), 10.0, true)
