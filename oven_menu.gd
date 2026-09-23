extends Control
class_name OvenMenu


@export var slot_size: = Vector2(60, 60)
@export var slot_gap: = Vector2(16, 18)
@export var panel_pad: = Vector2(12, 12)

@export var bg_color: Color = Color(0, 0, 0, 0.65)
@export var panel_outline: Color = Color(1, 1, 1, 0.25)
@export var slot_fill: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var slot_outline: Color = Color(1, 1, 1, 0.45)
@export var bar_bg: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var bar_fg: Color = Color(1.0, 1.0, 1.0, 0.85)

const COUNT_FONT = preload("res://Shag-Lounge.otf")
@export var count_font_size: int = 16
@export var count_outline_size: int = 4
@export var count_outline_color: Color = Color(0, 0, 0, 0.85)


var world: Node = null
@onready var hotbar = get_tree().get_first_node_in_group("hotbar")
@onready var inventory = get_tree().get_first_node_in_group("inventory")

func _get_world() -> Node:
	if world != null and is_instance_valid(world):
		return world
	world = get_tree().get_first_node_in_group("world")
	return world



var slot_input: = {"id": 0, "count": 0}
var slot_fuel: = {"id": 0, "count": 0}
var slot_out: = {"id": 0, "count": 0}


const COOK_TIME: = 5.0
var cook_progress: = 0.0


var FUEL_TIME: = {}
var fuel_time_left: = 0.0


var RECIPES: = {}


var hover_input: = false
var hover_fuel: = false
var hover_out: = false

const CLOSE_SIZE: = Vector2(28, 28)
const CLOSE_GAP: = Vector2(10, 0)
var hover_close: = false

const NEAR_RADIUS_CELLS: = 2
const OVEN_SRC: = 0
const OVEN_AC: = Vector2i(3, 2)

func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p
	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

func _is_near_oven() -> bool:
	var w: = get_tree().get_first_node_in_group("world")
	if w == null: return false
	var ground = w.get("ground")
	if ground == null: return false

	var player: = _get_local_player()
	if player == null: return false

	var pc: Vector2i = ground.local_to_map(ground.to_local(player.global_position))

	for dx in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
		for dy in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
			var c: = pc + Vector2i(dx, dy)
			if ground.get_cell_source_id(c) != OVEN_SRC:
				continue
			if ground.get_cell_atlas_coords(c) == OVEN_AC:
				return true
	return false

func _panel_rect() -> Rect2:
	var r_in = _rect_input()
	var r_fu = _rect_fuel()
	var r_out = _rect_output()
	var outer: = r_in.grow_individual(70, 70, 70, 70)
	outer = outer.expand(r_fu.position).expand(r_fu.position + r_fu.size)
	outer = outer.expand(r_out.position).expand(r_out.position + r_out.size)
	return outer

func _close_button_rect() -> Rect2:
	var pr: = _panel_rect()

	var pos: = pr.position + Vector2(pr.size.x + CLOSE_GAP.x, - CLOSE_SIZE.y * 0.5 + CLOSE_GAP.y)
	return Rect2(pos, CLOSE_SIZE)

func _has_icon_in_hotbar(hb: Hotbar, id: int) -> bool:
	return hb != null and hb.icon_by_item.has(id) and hb.icon_by_item[id] != null

func _register_icon_from_atlas(hb: Hotbar, item_id: int, coords: Vector2i) -> void :
	var w = _get_world()
	if w == null: return
	var ground = w.get("ground")
	if ground == null: return
	var ts: TileSet = ground.tile_set
	if ts == null: return
	var src: = ts.get_source(w.SRC)
	if src is TileSetAtlasSource:
		var atlas: = src as TileSetAtlasSource
		if atlas.has_tile(coords):
			var region: = atlas.get_tile_texture_region(coords, 0)
			var at: = AtlasTexture.new()
			at.atlas = atlas.texture
			at.region = Rect2(region.position, region.size)
			at.filter_clip = true
			hb.register_item_icon(item_id, at)

func _ensure_icons() -> void :
	var w = _get_world(); if w == null: return
	var hb: = _get_hotbar(); if hb == null: return
	for id in [w.ITEM_COAL, w.ITEM_RAW_IRON, w.ITEM_IRON, w.ITEM_RAW_GOLD, w.ITEM_GOLD, w.ITEM_LOG, w.ITEM_DARK_LOG, w.ITEM_YOYLE_LOG, w.ITEM_BUSH_LOG, w.ITEM_STICK]:
		if not hb.icon_by_item.has(id) or hb.icon_by_item[id] == null:
			var tex: Texture2D = w.ITEM_SPRITES.get(id, null)
			if tex != null:
				hb.register_item_icon(id, tex)

func _ensure_icon_for(id: int) -> void :
	_ensure_tables()
	_ensure_icons()

func _ready() -> void :
	add_to_group("oven")
	visible = false
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	set_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)


	if not InputMap.has_action("toggle_oven"):
		InputMap.add_action("toggle_oven")
		var ev: = InputEventKey.new();ev.physical_keycode = KEY_X
		InputMap.action_add_event("toggle_oven", ev)

	var w = _get_world()
	if w:

		RECIPES = {
			w.ITEM_RAW_IRON: w.ITEM_IRON, 
			w.ITEM_RAW_GOLD: w.ITEM_GOLD
		}

		FUEL_TIME = {
			w.ITEM_COAL: 10.0, 
			w.ITEM_LOG: 1.0, 
			w.ITEM_DARK_LOG: 1.0, 
			w.ITEM_YOYLE_LOG: 1.0, 
			w.ITEM_BERRY_LOG: 1.0, 
			w.ITEM_STICK: 0.5
		}

	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _ensure_tables() -> void :

	var w = _get_world()
	if w == null:
		return


	if RECIPES.is_empty():
		RECIPES[w.ITEM_RAW_IRON] = w.ITEM_IRON
		RECIPES[w.ITEM_RAW_GOLD] = w.ITEM_GOLD

	if FUEL_TIME.is_empty():
		FUEL_TIME[w.ITEM_COAL] = 10.0
		FUEL_TIME[w.ITEM_LOG] = 1.0
		FUEL_TIME[w.ITEM_DARK_LOG] = 1.0
		FUEL_TIME[w.ITEM_YOYLE_LOG] = 1.0
		FUEL_TIME[w.ITEM_BUSH_LOG] = 1.0
		FUEL_TIME[w.ITEM_STICK] = 0.5


func toggle_visible() -> void :
	var want_open: = not visible


	if want_open and not _is_near_oven():
		return

	if want_open:
		var inv = get_tree().get_first_node_in_group("inventory")
		if inv and inv.visible: inv.toggle_visible()
		var craft = get_tree().get_first_node_in_group("crafting")
		if craft and craft.visible: craft.toggle_visible()
		var wheel_menu = get_tree().get_first_node_in_group("wheel_menu")
		if wheel_menu and wheel_menu.visible: wheel_menu.toggle_visible()

		var box: = get_tree().get_first_node_in_group("yoylite_box_menu")
		if want_open and box and box.visible and box.has_method("_commit_and_close"):
			box._commit_and_close()

	visible = want_open
	if visible:
		top_level = true
		z_index = 1000
		grab_focus()
	else:
		top_level = false
		release_focus()

	_update_player_input_gate()
	queue_redraw()

func is_open() -> bool: return visible


func _process(delta: float) -> void :

	_ensure_tables()
	var w = _get_world(); if w == null: return

	if visible and not _is_near_oven():
		toggle_visible()


	if fuel_time_left <= 0.0:
		_try_consume_one_fuel()


	var can_cook: = _has_valid_input() and fuel_time_left > 0.0 and _output_accepts(active_recipe_out)
	if can_cook:
		fuel_time_left = max(0.0, fuel_time_left - delta)
		cook_progress += delta

		while cook_progress >= COOK_TIME and slot_input.count > 0 and _output_accepts(active_recipe_out):
			cook_progress -= COOK_TIME
			slot_input.count -= 1
			if slot_out.id == 0:
				slot_out.id = active_recipe_out
			slot_out.count += 1
			if slot_out.count >= Hotbar.STACK_MAX:
				slot_out.count = Hotbar.STACK_MAX
				break


		if slot_input.count <= 0:
			slot_input.id = 0
			active_recipe_out = 0


		if fuel_time_left <= 0.0 and not _try_consume_one_fuel():
			cook_progress = 0.0


	if visible:
		queue_redraw()

func _has_valid_input() -> bool:
	return slot_input.id != 0 and slot_input.count > 0 and RECIPES.has(slot_input.id)

func _is_fuel(id: int) -> bool:
	return id != 0 and FUEL_TIME.has(id) and FUEL_TIME[id] > 0.0

func _output_has_room() -> bool:
	if slot_out.id == 0:

		return true

	if _has_valid_input():
		var want = RECIPES[slot_input.id]
		if slot_out.id != want: return false
	return slot_out.count < Hotbar.STACK_MAX

func _try_consume_one_fuel() -> bool:
	if slot_fuel.id == 0 or slot_fuel.count <= 0: return false
	if not _is_fuel(slot_fuel.id): return false
	var add: = float(FUEL_TIME.get(slot_fuel.id, 0.0))
	if add <= 0.0: return false
	slot_fuel.count -= 1
	if slot_fuel.count <= 0: slot_fuel.id = 0
	fuel_time_left += add
	return true

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

	if e.is_action_pressed("toggle_oven"):
		if visible:
			toggle_visible()
		elif _is_near_oven():
			toggle_visible()
		return

	if e.is_action_pressed("ui_cancel") and visible:
		toggle_visible()

var _hb_cached: Hotbar

func _get_hotbar() -> Hotbar:
	if _hb_cached == null or not is_instance_valid(_hb_cached):
		_hb_cached = get_tree().get_first_node_in_group("hotbar") as Hotbar
	return _hb_cached

func _get_inventory() -> Control:
	if inventory == null or not is_instance_valid(inventory):
		inventory = get_tree().get_first_node_in_group("inventory")
	return inventory


func _gui_input(e: InputEvent) -> void :
	if not visible:
		return

	if e is InputEventMouse:
		accept_event()

	if e is InputEventMouseMotion:
		_update_hovers(e.position)
		hover_close = _close_button_rect().has_point(e.position)
		mouse_default_cursor_shape = (
			CURSOR_POINTING_HAND if (hover_input or hover_fuel or hover_out or hover_close) else CURSOR_ARROW
		)
		queue_redraw()
		return

	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:

		if _close_button_rect().has_point(e.position):
			toggle_visible()
			queue_redraw()
			return

		_update_hovers(e.position)
		if hover_input:
			_click_input_slot()
		elif hover_fuel:
			_click_fuel_slot()
		elif hover_out:
			_click_output_slot()
		queue_redraw()

var active_recipe_out: = 0

func _swap_with_hotbar_for(which: String) -> void :
	_ensure_tables()

	var hb: = _get_hotbar()
	if hb == null:
		print_debug("[oven] hotbar not ready")
		return

	var slot_ref: = slot_out
	if which == "input":
		slot_ref = slot_input
	elif which == "fuel":
		slot_ref = slot_fuel

	var hb_stack: Dictionary = hb.slots[hb.selected]
	var hb_id: int = int(hb_stack.get("id", 0))
	var hb_count: int = int(hb_stack.get("count", 0))

	var incoming_ok: bool = (hb_id == 0)
	if which == "input":
		incoming_ok = incoming_ok or RECIPES.has(hb_id)
	elif which == "fuel":
		incoming_ok = incoming_ok or _is_fuel(hb_id)

	if not incoming_ok:
		print_debug("[oven] item not allowed into %s (hb_id=%d) | inputs=%s | fuels=%s"
			%[which, hb_id, str(RECIPES.keys()), str(FUEL_TIME.keys())])
		return


	var tmp_id: int = int(slot_ref.get("id", 0))
	var tmp_cnt: int = int(slot_ref.get("count", 0))
	slot_ref["id"] = hb_id
	slot_ref["count"] = hb_count
	hb.slots[hb.selected] = {"id": tmp_id, "count": tmp_cnt}


	if which == "input":
		slot_input = slot_ref
		cook_progress = 0.0
		active_recipe_out = RECIPES.get(slot_input.id, 0)
	elif which == "fuel":
		slot_fuel = slot_ref
	else:
		slot_out = slot_ref

	hb.queue_redraw()
	queue_redraw()

func _output_accepts(out_id: int) -> bool:
	if out_id == 0:
		return false
	if slot_out.id != 0 and slot_out.id != out_id:
		return false
	return slot_out.count < Hotbar.STACK_MAX

func _click_input_slot() -> void :
	_swap_with_hotbar_for("input")

func _click_fuel_slot() -> void :
	_swap_with_hotbar_for("fuel")

func _click_output_slot() -> void :
	if slot_out.id == 0 or slot_out.count <= 0: return
	var hb: = _get_hotbar()
	var inv: = _get_inventory()
	var left = slot_out.count
	if hb and hb.has_method("try_add"):
		left = int(hb.try_add(slot_out.id, left))
	if left > 0 and inv and inv.has_method("try_add"):
		left = int(inv.try_add(slot_out.id, left))
	slot_out.count = left
	if slot_out.count <= 0: slot_out.id = 0
	if hb: hb.queue_redraw()
	queue_redraw()


func _update_hovers(p: Vector2) -> void :
	var r_in = _rect_input()
	var r_fu = _rect_fuel()
	var r_out = _rect_output()
	hover_input = r_in.has_point(p)
	hover_fuel = r_fu.has_point(p)
	hover_out = r_out.has_point(p)

func _draw_slot(rect: Rect2, s: Dictionary, hovered: bool) -> void :
	var fill: = slot_fill
	if hovered: fill.a = 0.95
	draw_rect(rect, fill, true)
	draw_rect(rect, slot_outline, false, 2.0)

	if s.id != 0:
		var tex: = _icon_for(s.id)
		if tex:
			var tsize: = tex.get_size()
			var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
			draw_texture_rect(tex, Rect2(rect.position + Vector2(4, 4), tsize * sc), false)
		if s.count > 1:
			_draw_count(rect, s.count)

func _draw() -> void :
	if not visible: return
	_ensure_icons()


	var r_in: = _rect_input()
	var r_fu: = _rect_fuel()
	var r_out: = _rect_output()


	var bar_h: = 6.0
	var gap_y: = 6.0
	var cook_p = clamp(cook_progress / COOK_TIME, 0.0, 1.0)

	var cook_bg: = Rect2(
		r_in.position + Vector2(0, r_in.size.y + gap_y), 
		Vector2(r_in.size.x, bar_h)
	)
	var cook_fg: = Rect2(cook_bg.position, Vector2(cook_bg.size.x * cook_p, cook_bg.size.y))

	var fuel_cap: = 10.0
	var fuel_p = clamp(fuel_time_left / max(fuel_cap, 0.001), 0.0, 1.0)
	var fuel_bg: = Rect2(
		r_fu.position + Vector2(0, r_fu.size.y + gap_y), 
		Vector2(r_fu.size.x, bar_h)
	)
	var fuel_fg: = Rect2(fuel_bg.position, Vector2(fuel_bg.size.x * fuel_p, fuel_bg.size.y))


	var bounds: = r_in
	bounds = bounds.merge(r_fu)
	bounds = bounds.merge(r_out)
	bounds = bounds.merge(cook_bg)
	bounds = bounds.merge(fuel_bg)


	var title_font: = _get_title_font()
	var title_text: = "OVEN-O-TRON"
	var title_h: = float(title_font.get_height(title_font_size)) + 8.0


	var side_pad: = 30.0
	var bottom_pad: = 20.0
	var top_pad: = title_h + 14.0
	var outer: = bounds.grow_individual(side_pad, top_pad, side_pad, bottom_pad)


	draw_rect(outer, bg_color, true)
	draw_rect(outer, panel_outline, false, 2.0)


	var title_size: = title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)
	var title_pos: = Vector2(
		outer.position.x + (outer.size.x - title_size.x) * 0.5, 
		outer.position.y + title_font.get_ascent(title_font_size) + 6.0
	)

	draw_string_outline(title_font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, 2, Color(0, 0, 0, 0.85))
	draw_string(title_font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, TITLE_COLOR)


	_draw_slot(r_in, slot_input, hover_input)
	_draw_slot(r_fu, slot_fuel, hover_fuel)
	_draw_slot(r_out, slot_out, hover_out)


	draw_rect(cook_bg, bar_bg, true)
	draw_rect(cook_fg, bar_fg, true)
	draw_rect(fuel_bg, bar_bg, true)
	draw_rect(fuel_fg, bar_fg, true)

	var cr: = _close_button_rect()
	var inside: = cr.has_point(get_local_mouse_position())
	var fill: = Color(0.12, 0.12, 0.12, (0.98 if inside else 0.95))
	draw_rect(cr, fill, true)
	draw_rect(cr, Color(1, 1, 1, 0.75), false, 2.0)

	var cx: = cr.position + cr.size * 0.5
	draw_line(cx + Vector2(-6, -6), cx + Vector2(6, 6), Color(1, 1, 1, 0.95), 2.0)
	draw_line(cx + Vector2(6, -6), cx + Vector2(-6, 6), Color(1, 1, 1, 0.95), 2.0)


@export var title_font_size: int = 24
const TITLE_COLOR: = Color8(255, 153, 1)
var _title_font: Font = null

func _get_title_font() -> Font:
	if _title_font == null:
		var sf: = SystemFont.new()
		sf.font_names = PackedStringArray(["Arial", "Arial Unicode MS", "Liberation Sans"])
		_title_font = sf
	return _title_font

func _draw_count(r: Rect2, n: int) -> void :
	var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
	var pos: = r.position + Vector2(slot_size.x - 4, slot_size.y - 6)
	if count_outline_size > 0:
		draw_string_outline(font, pos, str(n), 
			HORIZONTAL_ALIGNMENT_RIGHT, -1, count_font_size, 
			count_outline_size, count_outline_color)
	draw_string(font, pos, str(n), 
		HORIZONTAL_ALIGNMENT_RIGHT, -1, count_font_size, Color(1, 1, 1, 0.95))


func _panel_origin() -> Vector2:

	var total_w: = slot_size.x * 2 + slot_gap.x * 3
	var total_h: = slot_size.y * 2 + slot_gap.y
	var panel: = Vector2(total_w, total_h) + panel_pad * 2.0
	return Vector2(
		floor((size.x - panel.x) / 2.0), 
		floor((size.y - panel.y) / 2.0)
	) + panel_pad

func _rect_input() -> Rect2:
	var o: = _panel_origin()
	return Rect2(o, slot_size)

func _rect_fuel() -> Rect2:
	var o: = _panel_origin()
	var pos: = o + Vector2(0, slot_size.y + slot_gap.y)
	return Rect2(pos, slot_size)

func _rect_output() -> Rect2:
	var o: = _panel_origin()

	var left_column_h: = slot_size.y * 2 + slot_gap.y
	var y: = o.y + (left_column_h - slot_size.y) * 0.5
	var x: = o.x + slot_size.x + slot_gap.x * 2 + slot_size.x * 0.0
	return Rect2(Vector2(x, y), slot_size)


func _icon_for(id: int) -> Texture2D:
	var hb: = _get_hotbar()
	if hb and hb.icon_by_item.has(id) and hb.icon_by_item[id] != null:
		return hb.icon_by_item[id]
	var w = _get_world()
	if w and w.ITEM_SPRITES.has(id):
		var tex: Texture2D = w.ITEM_SPRITES[id]
		if tex != null:
			return tex
	return null

func _update_player_input_gate() -> void :
	var lp: = _get_local_player()
	if lp and lp.has_method("set_input_enabled"):
		lp.call("set_input_enabled", not visible)
