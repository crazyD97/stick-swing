class_name StudioUI
extends RefCounted
## Small UI helpers shared by every screen.


## Gives keyboard/gamepad focus to `control` at the end of the frame, if it still exists.
## Skipped on touch screens, where a focus outline on the first button just looks odd.
static func focus(control: Control) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	var grab := func() -> void:
		if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
			control.grab_focus()
	grab.call_deferred()
