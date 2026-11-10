extends Control
## Grid of levels from LevelCatalog, showing stars and locks from SaveManager.

const COLUMNS: int = 3


func _ready() -> void:
	var grid: GridContainer = %Grid
	grid.columns = COLUMNS
	var number: int = 1
	for level: Dictionary in LevelCatalog.all():
		grid.add_child(_make_tile(level, number))
		number += 1
	%BackButton.pressed.connect(SceneRouter.back)
	var first: Control = %BackButton
	if grid.get_child_count() > 0:
		first = grid.get_child(0).get_child(0)
	StudioUI.focus(first)


func _make_tile(level: Dictionary, number: int) -> Control:
	var id: String = level["id"]
	var unlocked: bool = SaveManager.is_level_unlocked(id)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.custom_minimum_size = Vector2(240, 240)
	button.text = str(number) if unlocked else "?"
	button.add_theme_font_size_override("font_size", 96)
	button.disabled = not unlocked
	button.tooltip_text = level["name"]
	button.pressed.connect(SceneRouter.go_to.bind(level["scene"], {"level_id": id}))
	box.add_child(button)
	var stars := StarRating.new()
	stars.star_size = 60.0
	stars.stars = SaveManager.get_level_stars(id)
	stars.visible = unlocked
	box.add_child(stars)
	return box
