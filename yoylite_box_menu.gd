extends Control
class_name YoyliteBoxMenu

@export var slot_size: = Vector2(60, 60)
@export var slot_gap: = Vector2(8, 8)
@export var panel_pad: = Vector2(12, 12)


@export var bg_color: Color = Color(0, 0, 0, 0.65)
@export var panel_outline: Color = Color(1, 1, 1, 0.25)
@export var slot_fill: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var slot_outline: Color = Color(1, 1, 1, 0.45)
@export var carry_tint: Color = Color(1, 1, 1, 0.95)
@export var count_font_size: int = 16
@export var count_outline_size: int = 4
@export var count_outline_color: Color = Color(0, 0, 0, 0.85)
const COUNT_FONT = preload("res://Shag-Lounge.otf")

const SHULKER_BOX_CLOSE = preload("uid://dj8cql3mvtno5")
const SHULKER_BOX_OPEN = preload("uid://ql6dthlbdduu")


var _sfx_open: AudioStreamPlayer
var _sfx_close: AudioStreamPlayer

func _ensure_sfx():
	if _sfx_open == null:
		_sfx_open = AudioStreamPlayer.new()
		_sfx_open.stream = SHULKER_BOX_OPEN
		_sfx_open.bus = "SFX"
		add_child(_sfx_open)
	if _sfx_close == null:
		_sfx_close = AudioStreamPlayer.new()
		_sfx_close.stream = SHULKER_BOX_CLOSE
		_sfx_close.bus = "SFX"
		add_child(_sfx_close)

var _box_uuid: String = ""


@export var close_radius_cells: = 2

var _mode: = ""
var _item_ref: = {"owner": null, "slot_index": -1}
var _world_cell: = Vector2i.ZERO
var _box_data: = {}
var _carry: = {"id": 0, "count": 0, "meta": {}}


var _panel_rect: = Rect2()
var _grid_rect: = Rect2()
var _x_rect: = Rect2()
var _hover_x: = false


func _get_inv() -> Node: return get_tree().get_first_node_in_group("inventory")
func _get_hb() -> Node: return get_tree().get_first_node_in_group("hotbar")
func _get_craft() -> Node: return get_tree().get_first_node_in_group("crafting")
func _get_oven() -> Node: return get_tree().get_first_node_in_group("oven")
func _get_wheel() -> Node: return get_tree().get_first_node_in_group("wheel_menu")
func _get_world() -> Node: return get_tree().get_first_node_in_group("world")


var _hover_idx: = -1

func _player_try_add(id: int, amount: int, meta: Dictionary = {}) -> int:

	var hb: = _get_hb()
	var inv: = _get_inv()
	var left: = amount
	if hb and hb.has_method("try_add"):
		left = int(hb.try_add(id, left))
	if left > 0 and inv and inv.has_method("add_with_meta"):
		left = int(inv.add_with_meta(id, left, meta))
	if hb: hb.queue_redraw()
	if inv: inv.queue_redraw()
	return left

func _quick_move_to_player(idx: int) -> void :
	var slots: = _box_data.get("slots", []) as Array
	var s = slots[idx]
	var id: = int(s.get("id", 0))
	var cnt: = int(s.get("count", 0))
	if id == 0 or cnt <= 0: return
	var meta: = (s.get("meta", {}) as Dictionary)
	var left: = _player_try_add(id, cnt, meta)
	var moved: = cnt - left
	if moved > 0:
		s["count"] = left
		if left <= 0:
			s["id"] = 0
			if s.has("meta"): s.erase("meta")
		slots[idx] = s
		_box_data["slots"] = slots
		_push_slot_delta(idx)
		queue_redraw()

func _quick_move_one_to_player(idx: int) -> void :
	var slots: = _box_data.get("slots", []) as Array
	var s = slots[idx]
	var id: = int(s.get("id", 0))
	var cnt: = int(s.get("count", 0))
	if id == 0 or cnt <= 0: return
	var meta: = (s.get("meta", {}) as Dictionary)
	var left: = _player_try_add(id, 1, meta)
	if left == 0:
		s["count"] = cnt - 1
		if s["count"] <= 0:
			s["id"] = 0
			if s.has("meta"): s.erase("meta")
		slots[idx] = s
		_box_data["slots"] = slots
		_push_slot_delta(idx)
		queue_redraw()

func _swap_with_hotbar_from_box(idx: int) -> void :
	var hb: = _get_hb()
	if hb == null: return

	var slots: = (_box_data.get("slots", []) as Array)
	var box_stack: = (slots[idx] as Dictionary).duplicate(true)
	var hb_stack: = (hb.slots[hb.selected] as Dictionary).duplicate(true)


	var cap: = 64
	if hb and hb.has_method("_stack_cap_for"):
		cap = int(hb._stack_cap_for(int(box_stack.get("id", 0))))

	if int(box_stack.get("id", 0)) != 0\
	and int(hb_stack.get("id", 0)) != 0\
	and int(box_stack["id"]) == int(hb_stack["id"])\
	and cap > 1:
		var total: = int(box_stack.get("count", 0)) + int(hb_stack.get("count", 0))
		var to_box = min(total, cap)
		var leftover = total - to_box

		box_stack["count"] = to_box
		if leftover > 0:
			hb_stack["count"] = leftover
			hb_stack["id"] = box_stack["id"]
		else:
			hb_stack = {"id": 0, "count": 0}
	else:

		var tmp: = hb_stack
		hb_stack = box_stack
		box_stack = tmp


	if hb.has_method("_sanitize_slot"):
		hb_stack = hb._sanitize_slot(hb_stack)
		box_stack = hb._sanitize_slot(box_stack)

	if hb and hb.has_method("_sync_icons_from_world"):
		hb._sync_icons_from_world()


	hb.slots[hb.selected] = hb_stack.duplicate(true)
	slots[idx] = box_stack.duplicate(true)
	_box_data["slots"] = slots


	_ensure_hotbar_icon_for(int(hb.slots[hb.selected].get("id", 0)))
	_ensure_hotbar_icon_for(int(slots[idx].get("id", 0)))
	hb._ensure_spyglass()
	if hb.has_method("queue_redraw"):
		hb.queue_redraw()
	_push_slot_delta(idx)
	queue_redraw()




func _ready() -> void :
	visible = false
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	mouse_filter = MOUSE_FILTER_IGNORE

	_adopt_inventory_theme()


func _adopt_inventory_theme() -> void :
	var inv: = _get_inv()
	if inv == null: return
	for k in ["bg_color", "panel_outline", "slot_fill", "slot_outline", "carry_tint", 
			"count_font_size", "count_outline_size", "count_outline_color"]:
		set(k, inv.get(k))

func open_for_item(owner_node: Node, slot_index: int, slot: Dictionary) -> void :
	_mode = "item"
	_item_ref = {"owner": owner_node, "slot_index": slot_index}
	_box_data = (slot.get("meta", {}).get("box", {}) as Dictionary).duplicate(true)
	_box_uuid = str(_box_data.get("uuid", ""))
	if _box_uuid == "":
		_box_uuid = str(Time.get_unix_time_from_system()) + "-" + str(randi())
		_box_data["uuid"] = _box_uuid
	_adopt_inventory_theme()
	_ensure_grid_size()
	_open_exclusive()

func _push_slot_delta(idx: int) -> void :
	if _mode != "world": return
	var world: = _get_world()
	if world == null: return
	var s = (_box_data.get("slots", []) as Array)[idx]

	if multiplayer.is_server() or multiplayer.multiplayer_peer == null:
		world.srv_box_set_slot(_world_cell, idx, s, _box_rev)
	else:
		world.rpc_id(1, "srv_box_set_slot", _world_cell, idx, s, _box_rev)


func _on_box_snapshot(cell: Vector2i, snapshot: Dictionary) -> void :
	if _mode != "world" or cell != _world_cell: return
	_box_data = snapshot.duplicate(true)
	_box_rev = int(_box_data.get("_rev", _box_rev))
	_ensure_grid_size()
	queue_redraw()


func _on_box_slot(cell: Vector2i, idx: int, s: Dictionary, new_rev: int) -> void :
	if _mode != "world" or cell != _world_cell: return
	var slots: = (_box_data.get("slots", []) as Array)
	if idx >= 0 and idx < slots.size():
		slots[idx] = s.duplicate(true)
		_box_data["slots"] = slots
	_box_rev = int(new_rev)
	queue_redraw()

var _box_rev: int = 0

func open_for_world(cell: Vector2i, snapshot: Dictionary) -> void :
	_mode = "world"
	_world_cell = cell
	_box_data = snapshot.duplicate(true)
	_box_rev = int(_box_data.get("_rev", 0))
	_box_uuid = str(_box_data.get("uuid", ""))
	if _box_uuid == "":
		_box_uuid = str(Time.get_unix_time_from_system()) + "-" + str(randi())
		_box_data["uuid"] = _box_uuid
	_adopt_inventory_theme()
	_ensure_grid_size()
	_open_exclusive()



func _target_cols_rows() -> Vector2i:
	var inv: = get_tree().get_first_node_in_group("inventory")
	var cols: = 8
	var rows: = 4
	if inv:

		if "COLS" in inv: cols = int(inv.COLS)
		if "ROWS" in inv: rows = int(inv.ROWS)
	return Vector2i(cols, rows)




func _ensure_grid_size() -> void :
	var tr: = _target_cols_rows()
	var cols: = tr.x
	var rows: = tr.y
	var want: = cols * rows

	var slots: Array
	if _box_data.has("slots") and typeof(_box_data["slots"]) == TYPE_ARRAY:
		slots = (_box_data["slots"] as Array).duplicate(true)
	else:
		slots = []


	while slots.size() < want:
		slots.append({"id": 0, "count": 0})
	if slots.size() > want:
		slots.resize(want)

	_box_data["cols"] = cols
	_box_data["rows"] = rows
	_box_data["slots"] = slots


func _open_exclusive() -> void :
	var inv = _get_inv()
	var cr = _get_craft()
	var ov = _get_oven()
	var wh = _get_wheel()
	if inv and inv.visible: inv.toggle_visible()
	if cr and cr.visible: cr.toggle_visible()
	if ov and ov.visible: ov.toggle_visible()
	if wh and wh.visible: wh.toggle_visible()


	top_level = true
	z_index = 9999
	if not is_in_group("yoylite_box_menu"):
		add_to_group("yoylite_box_menu")

	visible = true
	grab_focus()
	mouse_filter = MOUSE_FILTER_PASS
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	_ensure_sfx()
	_sfx_open.play()
	queue_redraw()

func _process(_dt: float) -> void :
	if not visible: return


	for n in [_get_inv(), _get_craft(), _get_oven(), _get_wheel()]:
		if n and n.visible:
			_commit_and_close()
			return

	if _mode == "world":
		var world: = _get_world()
		if world == null:
			_commit_and_close();return
		var ground = world.get("ground")
		if ground == null:
			_commit_and_close();return


		var src = ground.get_cell_source_id(_world_cell)
		var ac = ground.get_cell_atlas_coords(_world_cell)
		var is_box = (src == world.SRC and ac == world.T_YOYLITE_BOX)
		if not is_box:
			_commit_and_close()
			return


		var p: = _local_player_tile()
		if p != Vector2i(1 << 30, 1 << 30):
			var dist = max(abs(p.x - _world_cell.x), abs(p.y - _world_cell.y))
			if dist > close_radius_cells:
				_commit_and_close()
				return

func _local_player_tile() -> Vector2i:
	var world: = _get_world()
	if world == null: return Vector2i(1 << 30, 1 << 30)
	var ground = world.get("ground")
	if ground == null: return Vector2i(1 << 30, 1 << 30)

	var my: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		if n.get_multiplayer_authority() == my:
			return ground.local_to_map(ground.to_local(n.global_position))

	return Vector2i(1 << 30, 1 << 30)


@export var header_pad_y: = 8.0
func _panel_origin() -> Vector2:
	var cols: = int(_box_data.get("cols", 8))
	var rows: = int(_box_data.get("rows", 4))
	var grid_sz: = Vector2(cols * slot_size.x + (cols - 1) * slot_gap.x, 
		rows * slot_size.y + (rows - 1) * slot_gap.y)
	var panel: = grid_sz + Vector2(panel_pad.x * 2.0, panel_pad.y * 2.0 + header_pad_y)
	return Vector2(floor((size.x - panel.x) / 2.0), floor((size.y - panel.y) / 2.0))

func _layout_rects() -> void :
	var origin: = _panel_origin()
	var cols: = int(_box_data.get("cols", 8))
	var rows: = int(_box_data.get("rows", 4))
	var grid_sz: = Vector2(cols * slot_size.x + (cols - 1) * slot_gap.x, 
		rows * slot_size.y + (rows - 1) * slot_gap.y)

	_panel_rect = Rect2(origin, grid_sz + Vector2(panel_pad.x * 2.0, panel_pad.y * 2.0 + header_pad_y))
	_grid_rect = Rect2(origin + panel_pad + Vector2(0, header_pad_y), grid_sz)


	var x_size: = Vector2(24, 24)
	var x_gap: = Vector2(8, -8)
	_x_rect = Rect2(_panel_rect.position + Vector2(_panel_rect.size.x, 0) + x_gap, x_size)

func _draw() -> void :
	if not visible: return
	_layout_rects()

	draw_rect(_panel_rect, bg_color, true)
	draw_rect(_panel_rect, panel_outline, false, 2.0)


	var x_fill: = Color(0.18, 0.18, 0.18, 0.98 if _hover_x else 0.92)
	draw_rect(_x_rect, x_fill, true)
	draw_rect(_x_rect, Color(1, 1, 1, 0.45), false, 2.0)

	var pad: = 6.0

	var a: = _x_rect.position + Vector2(pad, pad)
	var b: = _x_rect.position + _x_rect.size - Vector2(pad, pad)
	var x3: = Vector2(_x_rect.position.x + pad, _x_rect.position.y + _x_rect.size.y - pad)
	var x4: = Vector2(_x_rect.position.x + _x_rect.size.x - pad, _x_rect.position.y + pad)
	draw_line(a, b, Color(1, 1, 1, 0.95), 2.0)
	draw_line(x3, x4, Color(1, 1, 1, 0.95), 2.0)


	var cols: = int(_box_data.get("cols", 8))
	var rows: = int(_box_data.get("rows", 4))
	var slots: = _box_data.get("slots", []) as Array
	for row_i in rows:
		for col_i in cols:
			var idx: = row_i * cols + col_i
			var pos: = _grid_rect.position + Vector2(
				col_i * (slot_size.x + slot_gap.x), 
				row_i * (slot_size.y + slot_gap.y)
			)
			var rect: = Rect2(pos, slot_size)
			var fill: = slot_fill
			if idx == _hover_idx:
				fill.a = 0.95
			draw_rect(rect, fill, true)
			draw_rect(rect, slot_outline, false, 2.0)

			if idx < slots.size():
				var s = slots[idx]
				if int(s.get("id", 0)) != 0:

					var tex: = _icon_for(int(s["id"]))
					if tex != null:
						var tsize: = tex.get_size()
						var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
						draw_texture_rect(tex, Rect2(rect.position + Vector2(4, 4), tsize * sc), false)
					else:

						var inner: = Rect2(rect.position + Vector2(6, 6), slot_size - Vector2(12, 12))
						draw_rect(inner, Color(0.2, 0.2, 0.25, 0.7), true)
						draw_rect(inner, Color(1, 1, 1, 0.35), false, 2.0)


					var cnt: = int(s.get("count", 0))
					if cnt > 1:
						_draw_count(rect, cnt)


					if ToolDurability.is_tool_id(int(s.get("id", 0)))\
					and s.has("meta") and typeof(s.meta) == TYPE_DICTIONARY:
						var m = s.meta
						if m.get("used", false) and int(m.get("max", 0)) > 0:
							var dur = clamp(int(m.get("dur", 0)), 0, int(m["max"]))
							var pct: = float(dur) / float(m["max"])
							var h: = 5.0
							var pada: = 3.0
							var bar: = Rect2(
								rect.position + Vector2(pada, rect.size.y - h - pada), 
								Vector2(rect.size.x - pada * 2.0, h)
							)
							draw_rect(bar, Color(0, 0, 0, 0.35), true)
							var filla: = Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y))
							var col: = _durability_color(pct, 0.95)
							draw_rect(filla, col, true)


	if _carry["id"] != 0:
		var tex: = _icon_for(int(_carry["id"]))
		if tex:
			var mp: = get_local_mouse_position()
			var tsize: = tex.get_size()
			var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
			var rect: = Rect2(mp - (tsize * sc) * 0.5, tsize * sc)
			draw_texture_rect(tex, rect, false, carry_tint)
		if int(_carry["count"]) > 1:
			var rect2: = Rect2(get_local_mouse_position() + Vector2(12, 10), slot_size)
			_draw_count(rect2, int(_carry["count"]))

func _durability_color(pct: float, alpha: float = 0.95) -> Color:
	pct = clamp(pct, 0.0, 1.0)
	var hue: = pct * 0.33
	return Color.from_hsv(hue, 0.95, 0.95, alpha)

func _icon_for(id: int) -> Texture2D:
	var hb: = _get_hb()
	if hb and hb.icon_by_item.has(id) and hb.icon_by_item[id] != null:
		return hb.icon_by_item[id]


	var w: = _get_world()
	if w and w.has_method("icon_map_for_hotbar") and hb:
		var m: Dictionary = w.icon_map_for_hotbar()
		if m.has(id) and m[id] != null:
			hb.register_item_icon(int(id), m[id])
			return m[id]
	return null

func _draw_count(r: Rect2, n: int) -> void :
	var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())

	var pad_x: = 4.0
	var pad_y: = 6.0


	var pos: = r.position + Vector2(pad_x, r.size.y - pad_y)
	var w: = r.size.x - pad_x * 2.0

	var text: = str(n)

	if count_outline_size > 0:
		draw_string_outline(
			font, pos, text, 
			HORIZONTAL_ALIGNMENT_RIGHT, w, count_font_size, 
			count_outline_size, count_outline_color
		)

	draw_string(
		font, pos, text, 
		HORIZONTAL_ALIGNMENT_RIGHT, w, count_font_size, 
		Color(1, 1, 1, 0.95)
	)


func _text_input_has_focus() -> bool:
	var f: = get_viewport().gui_get_focus_owner()
	if f == null:
		return false
	if f is LineEdit:
		return (f as LineEdit).editable
	if f is TextEdit:
		return not (f as TextEdit).read_only

	if f.name == "CommandBox":
		return true
	return false

func _cmd_box_node() -> LineEdit:
	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_node("CanvasLayer/CommandBox"):
		return world.get_node("CanvasLayer/CommandBox") as LineEdit

	var n: = get_tree().get_root().find_child("CommandBox", true, false)
	return n as LineEdit

func _is_command_box_open() -> bool:
	var cb: = _cmd_box_node()
	return cb != null and cb.visible


func _input(e: InputEvent) -> void :
	if _is_command_box_open():
		return

	if e.is_action_pressed("toggle_box"):

		if _text_input_has_focus():
			return

		if visible:
			_commit_and_close()
			accept_event()
		else:
			var cell: = _nearest_yoylite_box_cell(close_radius_cells)
			if cell != Vector2i(1 << 30, 1 << 30):
				var world: = _get_world()
				if world:
					if multiplayer.is_server() or multiplayer.multiplayer_peer == null:
						world.srv_request_open_box(cell)
					else:
						world.rpc_id(1, "srv_request_open_box", cell)
					accept_event()
		return

	if not visible:
		return

	if e.is_action_pressed("ui_cancel"):
		_commit_and_close()
		accept_event()

func _nearest_yoylite_box_cell(radius: int) -> Vector2i:
	var world: = _get_world()
	if world == null:
		return Vector2i(1 << 30, 1 << 30)
	var ground = world.get("ground")
	if ground == null:
		return Vector2i(1 << 30, 1 << 30)


	var p: = _local_player_tile()
	if p == Vector2i(1 << 30, 1 << 30):
		return p

	var best: = Vector2i(1 << 30, 1 << 30)
	var best_d: = INF
	for dx in range( - radius, radius + 1):
		for dy in range( - radius, radius + 1):
			var c: = p + Vector2i(dx, dy)
			var src = ground.get_cell_source_id(c)
			var ac = ground.get_cell_atlas_coords(c)
			if src == world.SRC and ac == world.T_YOYLITE_BOX:
				var d: = float((c - p).length_squared())
				if d < best_d:
					best_d = d
					best = c
	return best

func _gui_input(e: InputEvent) -> void :
	if not visible: return

	if e is InputEventMouseMotion:
		_hover_x = _x_rect.has_point(e.position)
		_hover_idx = _slot_at(e.position)
		mouse_default_cursor_shape = (CURSOR_POINTING_HAND if (_hover_x or _hover_idx != -1) else CURSOR_ARROW)
		queue_redraw()
		return

	if e is InputEventMouseButton and e.pressed:

		if e.button_index == MOUSE_BUTTON_LEFT and _x_rect.has_point(e.position):
			accept_event()
			_commit_and_close()
			return

		var idx: = _slot_at(get_local_mouse_position())
		if idx < 0: return

		accept_event()





		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.shift_pressed:
				_quick_move_to_player(idx)
			else:
				_swap_with_hotbar_from_box(idx)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.shift_pressed:
				_quick_move_one_to_player(idx)
			else:
				_click_slot(idx)

func _unhandled_input(e: InputEvent) -> void :

	if not visible:
		return
	if e.is_action_pressed("ui_cancel"):
		_commit_and_close()
		accept_event()



func _commit_and_close() -> void :

	if _carry["id"] != 0:
		var inv: = _get_inv()
		var hb: = _get_hb()
		if hb and hb.has_method("add_with_meta"):
			_carry["count"] = int(hb.add_with_meta(int(_carry["id"]), int(_carry["count"]), _carry.get("meta", {})))
		if int(_carry["count"]) > 0 and inv and inv.has_method("add_with_meta"):
			inv.add_with_meta(int(_carry["id"]), int(_carry["count"]), _carry.get("meta", {}))
		_carry = {"id": 0, "count": 0, "meta": {}}

	_box_data["uuid"] = _box_uuid

	if _mode == "item":

		var owner = _item_ref["owner"]
		var idx: = int(_item_ref["slot_index"])
		if owner and is_instance_valid(owner) and owner.has_method("slots"):
			var slots = owner.slots
			if idx >= 0 and idx < slots.size():
				var s = slots[idx].duplicate(true)
				var m: = (s.get("meta", {}) as Dictionary)
				m["box"] = _box_data.duplicate(true)
				s["meta"] = m
				if owner.has_method("_sanitize_slot"):
					s = owner._sanitize_slot(s)
				slots[idx] = s
				owner.slots = slots
				if owner.has_method("queue_redraw"): owner.queue_redraw()
				if owner.has_method("_touch_player_save"): owner._touch_player_save()
	elif _mode == "world":
		var world: = _get_world()
		if world:

			if multiplayer.is_server() or multiplayer.multiplayer_peer == null:
				world.srv_container_commit(_world_cell, _box_data)
			else:
				world.rpc_id(1, "srv_container_commit", _world_cell, _box_data)
	_ensure_sfx()
	_sfx_close.play()

	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE


func _slot_at(p: Vector2) -> int:
	var cols: = int(_box_data.get("cols", 8))
	var rows: = int(_box_data.get("rows", 4))
	var origin: = _panel_origin() + panel_pad + Vector2(0, header_pad_y)
	for r in rows:
		for c in cols:
			var pos: = origin + Vector2(c * (slot_size.x + slot_gap.x), r * (slot_size.y + slot_gap.y))
			var rect: = Rect2(pos, slot_size)
			if rect.has_point(p): return r * cols + c
	return -1



func _click_slot(idx: int) -> void :
	var slots: = _box_data.get("slots", []) as Array
	if idx < 0 or idx >= slots.size():
		return

	var s = slots[idx]


	if int(_carry.get("id", 0)) == 0:
		_carry = {
			"id": int(s.get("id", 0)), 
			"count": int(s.get("count", 0)), 
			"meta": (s.get("meta", {}) as Dictionary).duplicate(true)
		}

		s["id"] = 0
		s["count"] = 0
		if s.has("meta"): s.erase("meta")


	else:
		var hb: = _get_hb()
		var cap: = 64
		if hb and hb.has_method("_stack_cap_for"):
			cap = int(hb._stack_cap_for(int(_carry["id"])))

		var slot_id: = int(s.get("id", 0))
		var slot_cnt: = int(s.get("count", 0))
		var carry_id: = int(_carry.get("id", 0))
		var carry_cnt: = int(_carry.get("count", 0))

		if slot_id == 0:

			var place = min(carry_cnt, cap)
			s = {"id": carry_id, "count": place}
			var cm: = (_carry.get("meta", {}) as Dictionary)
			if cm.size() > 0:
				s["meta"] = cm.duplicate(true)
			_carry["count"] = carry_cnt - place
			if int(_carry["count"]) <= 0:
				_carry = {"id": 0, "count": 0, "meta": {}}

		elif slot_id == carry_id and slot_cnt < cap:

			var take = min(cap - slot_cnt, carry_cnt)
			s["count"] = slot_cnt + take
			_carry["count"] = carry_cnt - take
			if int(_carry["count"]) <= 0:
				_carry = {"id": 0, "count": 0, "meta": {}}

		else:

			var tmp: = {
				"id": slot_id, 
				"count": slot_cnt, 
				"meta": (s.get("meta", {}) as Dictionary).duplicate(true)
			}
			s = {"id": carry_id, "count": carry_cnt}
			var cm2: = (_carry.get("meta", {}) as Dictionary)
			if cm2.size() > 0:
				s["meta"] = cm2.duplicate(true)
			_carry = tmp


	slots[idx] = s
	_box_data["slots"] = slots
	queue_redraw()
	_push_slot_delta(idx)

func toggle_visible() -> void :
	var want_open: = not visible


	var crafting: = get_tree().get_first_node_in_group("crafting")
	if want_open and crafting and crafting.visible:
		crafting.toggle_visible()

	var oven: = get_tree().get_first_node_in_group("oven")
	if want_open and oven and oven.visible:
		oven.toggle_visible()

	var wheel_menu: = get_tree().get_first_node_in_group("wheel_menu")
	if want_open and wheel_menu and wheel_menu.visible:
		wheel_menu.toggle_visible()

	var inv: = get_tree().get_first_node_in_group("inventory")
	if inv and inv.visible:
		inv.toggle_visible()

	visible = want_open
	if visible: grab_focus()
	_update_player_input_gate()
	queue_redraw()

func _update_player_input_gate() -> void :

	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_input_enabled"):
			p.call("set_input_enabled", not visible)

func current_box_id() -> String:
	return _box_uuid

func current_box_ref() -> Dictionary:
	return {
		"mode": _mode, 
		"cell": _world_cell, 
		"item_owner": _item_ref["owner"], 
		"item_slot": int(_item_ref["slot_index"]), 
		"uuid": _box_uuid
	}

func _ensure_hotbar_icon_for(id: int) -> void :
	if id == 0: return
	var hb: = _get_hb()
	if hb == null: return

	if hb.icon_by_item.has(id) and hb.icon_by_item[id] != null:
		return

	var w: = _get_world()
	if w and w.has_method("icon_map_for_hotbar"):
		var m: Dictionary = w.icon_map_for_hotbar()
		if m.has(id) and m[id] != null and hb.has_method("register_item_icon"):
			hb.register_item_icon(id, m[id])
