extends GutTest


func test_touch_classification() -> void:
	assert_eq(TouchInput.classify(Vector2(5, 5), 0.1, false), &"tap")
	assert_eq(TouchInput.classify(Vector2(300, 10), 0.2, false), &"swipe")
	assert_eq(TouchInput.classify(Vector2(5, 5), 1.0, true), &"none")
	assert_eq(TouchInput.direction_of(Vector2(-300, 20)), Vector2.LEFT)
	assert_eq(TouchInput.direction_of(Vector2(10, -200)), Vector2.UP)


func test_health_component() -> void:
	var health: Health = autofree(Health.new())
	health.max_health = 2
	add_child(health)
	watch_signals(health)
	health.damage(1)
	health.damage(1)
	assert_true(health.is_dead())
	assert_signal_emitted(health, "died")
	health.heal(1)
	assert_eq(health.current, 0, "dead characters do not heal")


func test_stick_figure_plays_every_animation() -> void:
	var figure: StickFigure = autofree(StickFigure.new())
	add_child(figure)
	for anim: StringName in CharacterView.ANIMATIONS:
		figure.play(anim)
		assert_eq(figure.current_animation, anim)
		var joints: Dictionary = figure.compute_joints()
		assert_true(joints.has("head") and joints.has("l_foot"), "joints for %s" % anim)


func test_stick_figure_one_shot_emits_finished() -> void:
	var figure: StickFigure = autofree(StickFigure.new())
	add_child(figure)
	watch_signals(figure)
	figure.play(&"hit")
	await wait_seconds(0.5)
	assert_signal_emitted_with_parameters(figure, "animation_finished", [&"hit"])


func test_idle_figure_stands_on_its_feet() -> void:
	var figure: StickFigure = autofree(StickFigure.new())
	add_child(figure)
	var joints: Dictionary = figure.compute_joints()
	var lowest: float = maxf((joints["l_foot"] as Vector2).y, (joints["r_foot"] as Vector2).y)
	assert_almost_eq(lowest, 0.0, 3.0, "feet should touch the origin")
	assert_lt((joints["head"] as Vector2).y, -figure.style.height * 0.8, "head near the top")


func test_dev_tools_arg_parsing() -> void:
	var args: Dictionary = DevTools.parse_args(
		PackedStringArray(["--shot=3", "--reset-save", "x", "--scene=res://a.tscn"])
	)
	assert_eq(args["shot"], "3")
	assert_true(args["reset-save"])
	assert_eq(args["scene"], "res://a.tscn")
	assert_false(args.has("x"))


func test_purchase_stub_remembers_and_removes_ads() -> void:
	var path: String = SaveManager.save_path
	var data: Dictionary = SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://test_purchase_save.json"
	SaveManager.reset()
	assert_false(Purchases.is_owned("remove_ads"))
	var ok: bool = await Purchases.buy("remove_ads")
	assert_true(ok)
	assert_true(Purchases.is_owned("remove_ads"))
	assert_true(Ads.ads_removed)
	Ads.ads_removed = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path))
	SaveManager.save_path = path
	SaveManager.data = data
