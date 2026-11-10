extends Control
## Shows assets/CREDITS.md (exported via include_filter in export_presets.cfg).

const CREDITS_FILE: String = "res://assets/CREDITS.md"


func _ready() -> void:
	%Body.text = format_credits(FileAccess.get_file_as_string(CREDITS_FILE))
	%BackButton.pressed.connect(SceneRouter.back)
	StudioUI.focus(%BackButton)


## Turns the markdown table into plain readable lines.
static func format_credits(markdown: String) -> String:
	var lines: PackedStringArray = []
	for raw: String in markdown.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("# ") or line.begins_with("| ---") or line.begins_with("| Asset"):
			continue
		if line.begins_with("|"):
			var cells: PackedStringArray = []
			for cell: String in line.trim_prefix("|").trim_suffix("|").split("|"):
				cells.append(cell.strip_edges())
			if cells.size() >= 4:
				line = "%s\n%s - %s (%s)\n" % [cells[0], cells[2], cells[1], cells[3]]
		lines.append(line)
	return "\n".join(lines).strip_edges()


func handle_back() -> bool:
	SceneRouter.go_to("res://game/ui/settings.tscn")
	return true
