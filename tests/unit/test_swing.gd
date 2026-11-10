extends GutTest
## Rope physics, targeting, generation and a bot that proves generated courses are playable.

const GAME_SCENE: PackedScene = preload("res://game/swing/swing_game.tscn")
const DT: float = 1.0 / 60.0

var game: SwingGame
var _save_path: String
var _save_data: Dictionary


func before_each() -> void:
	_save_path = SaveManager.save_path
	_save_data = SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://test_swing_save.json"
	SaveManager.reset()
	game = GAME_SCENE.instantiate()
	game.rng_seed = 12345
	add_child(game)
	game.set_physics_process(false)  # the tests drive tick() themselves


func after_each() -> void:
	game.free()
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path))
	SaveManager.save_path = _save_path
	SaveManager.data = _save_data


func _simulate(seconds: float, policy: Callable = Callable()) -> void:
	for i: int in int(seconds / DT):
		if policy.is_valid():
			policy.call()
		game.tick(DT)
		if game.state == SwingGame.State.OVER:
			return


## A simple player: grab once falling with a ring in range (or when about to lose the last chance),
## let go when swinging up and forward at about 40 degrees.
func _bot() -> void:
	var s: Swinger = game.swinger
	if s.state == Swinger.State.FLYING and not game.holding and game.target != null:
		var slipping_behind: bool = game.target.global_position.x < s.global_position.x + 120.0
		if s.velocity.y > 50.0 or s.global_position.y > 1200.0 or slipping_behind:
			game.press()
	elif s.state == Swinger.State.SWINGING:
		var ahead: bool = s.global_position.x > s.anchor.global_position.x
		if ahead and s.velocity.x > 200.0 and -s.velocity.y > s.velocity.x * 0.8:
			game.release_hold()


func test_first_press_launches() -> void:
	assert_eq(game.state, SwingGame.State.READY)
	game.press()
	assert_eq(game.state, SwingGame.State.PLAYING)
	assert_eq(game.swinger.state, Swinger.State.FLYING)
	assert_gt(game.swinger.velocity.x, 0.0)


func test_rope_never_stretches() -> void:
	game.press()
	game.release_hold()
	var a: Anchor = game.anchors[0]
	game.swinger.attach(a)
	var length: float = game.swinger.rope_length
	for i: int in 240:
		game.tick(DT)
		assert_true(game.swinger.global_position.distance_to(a.global_position) <= length + 0.5, "taut rope holds")
		if game.state == SwingGame.State.OVER:
			break


func test_release_keeps_momentum() -> void:
	game.press()
	game.swinger.attach(game.anchors[0])
	_simulate(0.6)
	var v: Vector2 = game.swinger.velocity
	game.release_hold()
	assert_eq(game.swinger.state, Swinger.State.FLYING)
	assert_eq(game.swinger.velocity, v)


func test_target_is_nearest_ring_ahead_in_range() -> void:
	game.swinger.global_position = Vector2(game.anchors[2].global_position.x - 100.0, 900.0)
	game.swinger.state = Swinger.State.FLYING
	var t: Anchor = game.find_target()
	assert_not_null(t)
	assert_true(t.global_position.x >= game.swinger.global_position.x - 80.0)
	assert_true(t.global_position.distance_to(game.swinger.global_position) <= SwingGame.GRAB_RANGE)


func test_generated_gaps_stay_reachable() -> void:
	game._generate_until(60000.0)
	for i: int in range(1, game.anchors.size()):
		var gap: float = game.anchors[i].position.x - game.anchors[i - 1].position.x
		assert_between(gap, 360.0, 740.0)
		assert_between(game.anchors[i].position.y, SwingGame.MIN_ANCHOR_Y, SwingGame.MAX_ANCHOR_Y)


func test_falling_into_lava_ends_run_and_saves_best() -> void:
	game.press()
	game.release_hold()
	_simulate(6.0)  # never grab: falls into the lava
	assert_eq(game.state, SwingGame.State.OVER)
	assert_eq(game.swinger.state, Swinger.State.DEAD)
	assert_eq(int(SaveManager.get_value("stats", "best_distance", -1)), game.score)


func test_bot_can_play_a_long_run() -> void:
	game.press()
	game.release_hold()
	_simulate(90.0, _bot)
	gut.p("bot reached %d m (state %s)" % [game.score, game.state])
	assert_gt(game.score, 250, "a simple bot should get far: the course must be playable")


func test_coins_are_collected_and_banked() -> void:
	game.press()
	game.release_hold()
	_simulate(90.0, _bot)
	game.swinger.die()
	game._on_swinger_died()
	assert_gt(int(SaveManager.get_value("stats", "coins", 0)), 0, "bot picks up some coins")


func test_continue_revives_on_a_ring() -> void:
	Ads.stub_delay = 0.01
	game.press()
	game.release_hold()
	_simulate(6.0)
	assert_eq(game.state, SwingGame.State.OVER)
	await wait_for_signal(game.game_over_shown, 3.0)
	await game._on_continue_pressed()
	Ads.stub_delay = 0.5
	assert_eq(game.state, SwingGame.State.PLAYING)
	assert_eq(game.swinger.state, Swinger.State.SWINGING)
	assert_true(game.used_continue)
