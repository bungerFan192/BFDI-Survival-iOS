extends Control

@export var radius: float = 148.0
@export var bar_thickness_ratio: float = 0.35
@export var bar_alpha: float = 0.22
@export var knob_alpha: float = 0.55
@export var knob_radius: float = 48.0

@export var horizontal_only: bool = true
@export var floating: bool = false
@export var deadzone: float = 0.12
@export var run_threshold: float = 0.9
@export var tap_must_be_on_bar: bool = true
@export var tap_highlight_color: Color = Color(0.4, 0.8, 1.0, 0.28)
@export var show_tap_highlight: bool = true


@export var outline_thickness_px: float = 2.0
@export var outline_color: Color = Color(0, 0, 0, 0.45)

var _center: Vector2
var _offset: Vector2 = Vector2.ZERO
var _active: = false
var _pointer_id: = -1
var _pressing_on_bar: = false

var _pressed_left: = false
var _pressed_right: = false
var _pressed_run: = false

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_hitbox_to_bar()
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_RESIZED and not floating:
		_center = size * 0.5
		queue_redraw()


func _update_hitbox_to_bar() -> void :
	var half_w: = radius
	var half_h: = _bar_half_height()
	var pad: = 6.0 + knob_radius * 0.25 + outline_thickness_px
	var new_size: = Vector2(
		half_w * 2.0 + pad * 2.0, 
		max(half_h * 2.0, knob_radius * 2.0) + pad * 2.0
	)


	var center_g: = global_position + size * 0.5


	custom_minimum_size = new_size
	size = new_size
	_center = size * 0.5


	global_position = center_g - size * 0.5

func _bar_half_height() -> float:
	return max(6.0, radius * bar_thickness_ratio)


func _has_point(p: Vector2) -> bool:
	if not tap_must_be_on_bar:
		return true
	return _is_point_on_bar(p)

func _is_point_on_bar(p: Vector2) -> bool:
	var half_w: = radius
	var half_h: = _bar_half_height() + outline_thickness_px

	var rect: = Rect2(_center.x - half_w, _center.y - half_h, half_w * 2.0, half_h * 2.0)
	if rect.has_point(p):
		return true

	var left_c: = _center + Vector2( - half_w, 0)
	var right_c: = _center + Vector2( + half_w, 0)
	return (p.distance_to(left_c) <= half_h) or (p.distance_to(right_c) <= half_h)

func _update_offset_from_local(local_pos: Vector2) -> void :
	var raw: = local_pos - _center
	if horizontal_only:
		raw.y = 0.0
	if raw.length() > radius:
		raw = raw.normalized() * radius
	_offset = raw
	_emit_actions()
	queue_redraw()

func _snap_knob_to_tap(local_pos: Vector2) -> void :
	_update_offset_from_local(local_pos)


func _gui_input(event: InputEvent) -> void :
	if event is InputEventScreenTouch:
		var local_pos = event.position
		if event.pressed:
			if floating:
				_center = local_pos
			_pressing_on_bar = _is_point_on_bar(local_pos)
			if _pressing_on_bar:
				_pointer_id = event.index
				_active = true
				_snap_knob_to_tap(local_pos)
				accept_event()
		elif event.index == _pointer_id:
			_reset_actions()
			_active = false
			_pointer_id = -1
			_offset = Vector2.ZERO
			_pressing_on_bar = false
			queue_redraw()
			accept_event()

	elif event is InputEventScreenDrag and event.index == _pointer_id:
		var local_pos = event.position
		_pressing_on_bar = _is_point_on_bar(local_pos)
		_update_offset_from_local(local_pos)
		accept_event()


func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		var mb: = event as InputEventMouseButton
		var local_pos: = get_local_mouse_position()
		if mb.pressed:
			if tap_must_be_on_bar and not _is_point_on_bar(local_pos):
				return
			_pointer_id = -42
			_active = true
			_pressing_on_bar = true
			_snap_knob_to_tap(local_pos)
		elif _pointer_id == -42:
			_reset_actions()
			_active = false
			_pointer_id = -1
			_offset = Vector2.ZERO
			_pressing_on_bar = false
			queue_redraw()

	elif event is InputEventMouseMotion and _active and _pointer_id == -42:
		_pressing_on_bar = _is_point_on_bar(get_local_mouse_position())
		_update_offset_from_local(get_local_mouse_position())


func _emit_actions() -> void :
	var strength: = 0.0
	if radius > 0.0:
		strength = clamp(_offset.length() / radius, 0.0, 1.0)
	var dir: = 0
	if abs(_offset.x) > deadzone * radius:
		dir = int(sign(_offset.x))
	_press_action("right", dir > 0, _pressed_right);_pressed_right = dir > 0
	_press_action("left", dir < 0, _pressed_left);_pressed_left = dir < 0
	var want_run: = strength >= run_threshold
	_press_action("ui_run", want_run, _pressed_run);_pressed_run = want_run

func _reset_actions() -> void :
	_press_action("left", false, _pressed_left);_pressed_left = false
	_press_action("right", false, _pressed_right);_pressed_right = false
	_press_action("ui_run", false, _pressed_run);_pressed_run = false

func _press_action(name: String, want_press: bool, currently_pressed: bool) -> void :
	if want_press and not currently_pressed:
		Input.action_press(name)
	elif not want_press and currently_pressed:
		Input.action_release(name)

func _draw() -> void :
	var half_w: = radius
	var half_h: = _bar_half_height()
	var rect: = Rect2(_center.x - half_w, _center.y - half_h, half_w * 2.0, half_h * 2.0)
	var base_col: = Color(1, 1, 1, bar_alpha)


	if outline_thickness_px > 0.0:
		var half_h_o: = half_h + outline_thickness_px

		var rect_o: = Rect2(_center.x - half_w, _center.y - half_h_o, half_w * 2.0, half_h_o * 2.0)
		draw_rect(rect_o, outline_color, true)
		_draw_semicircle(_center + Vector2( - half_w, 0), half_h_o, outline_color, true)
		_draw_semicircle(_center + Vector2( + half_w, 0), half_h_o, outline_color, false)


	draw_rect(rect, base_col, true)
	_draw_semicircle(_center + Vector2( - half_w, 0), half_h, base_col, true)
	_draw_semicircle(_center + Vector2( + half_w, 0), half_h, base_col, false)


	if show_tap_highlight and _pressing_on_bar:
		draw_rect(rect, tap_highlight_color, true)
		_draw_semicircle(_center + Vector2( - half_w, 0), half_h, tap_highlight_color, true)
		_draw_semicircle(_center + Vector2( + half_w, 0), half_h, tap_highlight_color, false)


	var knob_col: = Color(1, 1, 1, knob_alpha)
	if outline_thickness_px > 0.0:
		draw_circle(_center + _offset, knob_radius + outline_thickness_px, outline_color)
	draw_circle(_center + _offset, knob_radius, knob_col)

func _draw_semicircle(center: Vector2, r: float, color: Color, left: bool, segments: int = 32) -> void :
	var pts: = PackedVector2Array()
	pts.append(center)
	var start: = PI * 0.5
	var end: = PI * 1.5
	if not left:
		start = - PI * 0.5
		end = PI * 0.5
	for i in range(segments + 1):
		var t = lerp(start, end, float(i) / float(segments))
		pts.append(center + Vector2(cos(t), sin(t)) * r)
	draw_colored_polygon(pts, color)
