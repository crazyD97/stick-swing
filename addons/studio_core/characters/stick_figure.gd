@tool
class_name StickFigure
extends CharacterView
## A stick figure drawn entirely in code: no art needed. Poses are joint angles, animations
## are functions of time, and poses blend smoothly. Origin = feet. Works in the editor (@tool).
##
## Angle convention: 0 = limb points straight down, positive = rotated toward facing direction.

## How fast poses blend into each other (higher = snappier).
@export var blend_speed: float = 22.0

var _pose: Dictionary = {}
var _rotation_amount: float = 0.0
var _flash: float = 0.0
var _finished_emitted: bool = false


func _ready() -> void:
	super._ready()
	_pose = _target_pose(current_animation if current_animation != &"" else &"idle", 0.0)


func _process(delta: float) -> void:
	anim_time += delta
	var target: Dictionary = _target_pose(current_animation, anim_time)
	var weight: float = 1.0 - exp(-blend_speed * delta)
	for key: String in target:
		_pose[key] = lerpf(float(_pose.get(key, target[key])), float(target[key]), weight)
	_flash = maxf(0.0, _flash - delta * 3.0)
	_check_finished()
	queue_redraw()


func _on_animation_started(anim_name: StringName) -> void:
	_finished_emitted = false
	if anim_name == &"hit" or anim_name == &"die":
		_flash = 1.0


func _on_style_changed() -> void:
	queue_redraw()


func _check_finished() -> void:
	if _finished_emitted or not current_animation in ONE_SHOTS:
		return
	var length: float = 0.35 if current_animation == &"hit" else 0.7
	if anim_time >= length:
		_finished_emitted = true
		animation_finished.emit(current_animation)


# --- Poses -------------------------------------------------------------------


static func _base_pose() -> Dictionary:
	return {
		"lean": 0.0,
		"bob": 0.0,
		"rot": 0.0,
		"grounded": 1.0,
		"l_thigh": 0.08,
		"l_shin": 0.05,
		"r_thigh": -0.08,
		"r_shin": 0.05,
		"l_upper": 0.25,
		"l_fore": 0.15,
		"r_upper": -0.25,
		"r_fore": 0.15,
	}


func _target_pose(anim: StringName, t: float) -> Dictionary:
	var p: Dictionary = _base_pose()
	match anim:
		&"idle":
			var breathe: float = sin(t * 2.5)
			p["lean"] = 0.03
			p["bob"] = breathe * 2.0
			p["l_upper"] = 0.22 + breathe * 0.03
			p["r_upper"] = -0.22 - breathe * 0.03
		&"run":
			var ph: float = t * TAU * 2.1
			p["lean"] = 0.22
			p["l_thigh"] = sin(ph) * 0.85
			p["r_thigh"] = -sin(ph) * 0.85
			p["l_shin"] = 0.2 + 1.3 * maxf(0.0, cos(ph))
			p["r_shin"] = 0.2 + 1.3 * maxf(0.0, -cos(ph))
			p["l_upper"] = -sin(ph) * 0.8
			p["r_upper"] = sin(ph) * 0.8
			p["l_fore"] = 1.3
			p["r_fore"] = 1.3
		&"jump":
			p["grounded"] = 0.0
			p["lean"] = 0.1
			p["l_thigh"] = 1.0
			p["l_shin"] = 1.5
			p["r_thigh"] = 0.3
			p["r_shin"] = 1.0
			p["l_upper"] = 2.6
			p["r_upper"] = 2.2
			p["l_fore"] = 0.3
			p["r_fore"] = 0.4
		&"fall":
			p["grounded"] = 0.0
			p["lean"] = 0.05
			p["l_thigh"] = 0.35
			p["l_shin"] = 0.5
			p["r_thigh"] = -0.25
			p["r_shin"] = 0.7
			p["l_upper"] = 1.9 + sin(t * 14.0) * 0.15
			p["r_upper"] = -1.9 - sin(t * 14.0) * 0.15
			p["l_fore"] = 0.3
			p["r_fore"] = -0.3
		&"hit":
			p["lean"] = -0.35
			p["l_thigh"] = 0.3
			p["r_thigh"] = -0.1
			p["l_upper"] = 1.4
			p["r_upper"] = 1.0
			p["l_fore"] = 0.6
			p["r_fore"] = 0.6
		&"die":
			var k: float = ease(clampf(t / 0.5, 0.0, 1.0), 0.4)
			p["lean"] = -0.35
			p["rot"] = -k * PI * 0.5
			p["l_thigh"] = 0.3
			p["r_thigh"] = -0.1
			p["l_upper"] = 1.4 + k
			p["r_upper"] = 1.0 + k
			p["l_fore"] = 0.4
			p["r_fore"] = 0.4
		&"win":
			p["bob"] = -absf(sin(t * 6.0)) * 30.0
			p["l_upper"] = 2.8 + sin(t * 12.0) * 0.25
			p["r_upper"] = -2.8 + sin(t * 12.0 + 1.0) * 0.25
			p["l_fore"] = 0.4
			p["r_fore"] = -0.4
	return p


# --- Drawing -----------------------------------------------------------------


static func _dir(angle: float) -> Vector2:
	return Vector2(sin(angle), cos(angle))


## Joint positions for the current pose. Public so tests and gameplay (e.g. hand position) can use it.
func compute_joints() -> Dictionary:
	var s: CharacterStyle = style if style else CharacterStyle.new()
	var h: float = s.height
	var head_r: float = h * 0.11 * s.head_scale
	var thigh: float = h * 0.24
	var shin: float = h * 0.24
	var torso: float = h * 0.28
	var upper: float = h * 0.17
	var fore: float = h * 0.16
	var p: Dictionary = _pose if not _pose.is_empty() else _base_pose()

	var j: Dictionary = {}
	var hip := Vector2(0.0, -(thigh + shin))
	var lean: float = float(p["lean"])
	j["hip"] = hip
	j["neck"] = hip + Vector2(sin(lean), -cos(lean)) * torso
	j["head"] = (j["neck"] as Vector2) + Vector2(sin(lean), -cos(lean)) * head_r * 1.1
	var shoulder: Vector2 = (j["neck"] as Vector2) + Vector2(-sin(lean), cos(lean)) * h * 0.04
	j["shoulder"] = shoulder
	for side: String in ["l", "r"]:
		var ta: float = float(p[side + "_thigh"])
		var knee: Vector2 = hip + _dir(ta) * thigh
		j[side + "_knee"] = knee
		j[side + "_foot"] = knee + _dir(ta - float(p[side + "_shin"])) * shin
		var ua: float = float(p[side + "_upper"])
		var elbow: Vector2 = shoulder + _dir(ua) * upper
		j[side + "_elbow"] = elbow
		j[side + "_hand"] = elbow + _dir(ua + float(p[side + "_fore"])) * fore

	# Keep the lowest foot on the ground for grounded poses, then apply bob and rotation.
	var lowest: float = maxf((j["l_foot"] as Vector2).y, (j["r_foot"] as Vector2).y)
	var shift := Vector2(0.0, -lowest * float(p["grounded"]) + float(p["bob"]))
	var rot: float = float(p["rot"])
	for key: String in j:
		j[key] = ((j[key] as Vector2) + shift).rotated(rot)
	j["head_radius"] = head_r
	return j


func _draw() -> void:
	var s: CharacterStyle = style if style else CharacterStyle.new()
	var j: Dictionary = compute_joints()
	var col: Color = s.color.lerp(s.accent_color, _flash)
	var w: float = s.line_width

	# Back limbs first (r = far side), then body, then front limbs.
	_limb([j["shoulder"], j["r_elbow"], j["r_hand"]], col.darkened(0.25), w)
	_limb([j["hip"], j["r_knee"], j["r_foot"]], col.darkened(0.25), w)
	_limb([j["hip"], j["neck"]], col, w * 1.1)
	if s.scarf:
		_draw_scarf(j["neck"], s.accent_color, w)
	_limb([j["hip"], j["l_knee"], j["l_foot"]], col, w)
	_limb([j["shoulder"], j["l_elbow"], j["l_hand"]], col, w)

	var head: Vector2 = j["head"]
	var r: float = j["head_radius"]
	draw_circle(head, r, s.head_fill)
	draw_arc(head, r, 0.0, TAU, 32, col, w * 0.9, true)
	if s.show_face:
		_draw_face(head, r, col, w)


func _limb(points: Array, color: Color, width: float) -> void:
	for i: int in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)
	for point: Vector2 in points:
		draw_circle(point, width * 0.5, color)


func _draw_scarf(neck: Vector2, color: Color, width: float) -> void:
	var wave: float = sin(anim_time * 10.0) * 6.0
	var tail_a := neck + Vector2(-width * 3.5, width * 0.8 + wave)
	var tail_b := neck + Vector2(-width * 3.0, width * 2.0 - wave)
	draw_line(neck, tail_a, color, width * 0.9, true)
	draw_line(neck, tail_b, color, width * 0.7, true)
	draw_circle(neck, width * 0.8, color)


func _draw_face(head: Vector2, r: float, color: Color, width: float) -> void:
	var eye := head + Vector2(r * 0.4, -r * 0.15)
	if current_animation == &"die":
		var e: float = r * 0.18
		draw_line(eye - Vector2(e, e), eye + Vector2(e, e), color, width * 0.4, true)
		draw_line(eye - Vector2(e, -e), eye + Vector2(e, -e), color, width * 0.4, true)
		return
	draw_circle(eye, maxf(2.0, width * 0.35), color)
	var mouth_center := head + Vector2(r * 0.35, r * 0.2)
	if current_animation == &"hit":
		draw_circle(mouth_center + Vector2(0, r * 0.1), r * 0.14, color)
	else:
		draw_arc(mouth_center, r * 0.28, 0.3, 1.6, 8, color, width * 0.35, true)
