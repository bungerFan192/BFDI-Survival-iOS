extends Control
class_name InventoryMenu


const COLS: = 8
const ROWS: = 4
const SLOT_COUNT: = COLS * ROWS
@export var slot_size: = Vector2(60, 60)
@export var slot_gap: = Vector2(8, 8)
@export var panel_pad: = Vector2(12, 12)

const CRAFT_COST_LOGS: = 10
const CRAFT_BUTTON_SIZE: = Vector2(270, 60)

var craft_btn_hover: = false


@export var bg_color: Color = Color(0, 0, 0, 0.65)
@export var panel_outline: Color = Color(1, 1, 1, 0.25)
@export var slot_fill: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var slot_outline: Color = Color(1, 1, 1, 0.45)
@export var carry_tint: Color = Color(1, 1, 1, 0.95)


const COUNT_FONT = preload("res://Shag-Lounge.otf")
@export var count_font_size: int = 16
@export var count_outline_size: int = 4
@export var count_outline_color: Color = Color(0, 0, 0, 0.85)
var world: Node = null


var creative_mode: bool = false
var creative_show_menu: bool = false
var creative_page: int = 0
var _creative_ids: Array[int] = []
var _creative_dirty: bool = true

func set_creative_mode(enabled: bool) -> void :
	creative_mode = enabled
	if not creative_mode:
		creative_show_menu = false
		creative_page = 0

	_creative_dirty = true
	queue_redraw()

func is_creative_mode() -> bool:
	return creative_mode

const PAGE_BTN_SIZE: = Vector2(44, 44)
var page_left_hover: bool = false
var page_right_hover: bool = false

func _page_left_rect() -> Rect2:
	var btn: = _craft_button_rect()
	var pos: = btn.position + Vector2( - PAGE_BTN_SIZE.x - 10, (btn.size.y - PAGE_BTN_SIZE.y) * 0.5)
	return Rect2(pos, PAGE_BTN_SIZE)

func _page_right_rect() -> Rect2:
	var btn: = _craft_button_rect()
	var pos: = btn.position + Vector2(btn.size.x + 10, (btn.size.y - PAGE_BTN_SIZE.y) * 0.5)
	return Rect2(pos, PAGE_BTN_SIZE)


func _creative_total_pages() -> int:
	_build_creative_catalog_if_needed()
	if _creative_ids.is_empty():
		return 1
	return int(ceil(float(_creative_ids.size()) / float(SLOT_COUNT)))

func _build_creative_catalog_if_needed() -> void :
	if not _creative_dirty:
		return
	_creative_dirty = false
	_creative_ids.clear()

	var w: = _get_world()

	if w != null and w.has_method("get_all_block_item_ids"):
		var ids = w.call("get_all_block_item_ids")
		if ids is Array:
			for v in ids:
				_creative_ids.append(int(v))
		_creative_ids = _unique_sorted_ints(_creative_ids)
		return


	if hotbar != null and hotbar.icon_by_item != null:
		for k in hotbar.icon_by_item.keys():
			var id: = int(k)
			if id != 0:
				_creative_ids.append(id)

	_creative_ids = _unique_sorted_ints(_creative_ids)

func _unique_sorted_ints(a: Array) -> Array[int]:
	var seen: = {}
	var out: Array[int] = []
	for v in a:
		var id: = int(v)
		if not seen.has(id):
			seen[id] = true
			out.append(id)
	out.sort()
	return out

func _creative_id_at_slot(idx: int) -> int:
	_build_creative_catalog_if_needed()
	var start: = creative_page * SLOT_COUNT
	var p: = start + idx
	if p < 0 or p >= _creative_ids.size():
		return 0
	return int(_creative_ids[p])

func _give_one_slot_to_hotbar(item_id: int) -> void :
	if hotbar == null:
		return

	var cap: = _stack_cap_for(item_id)


	var sel: = int(hotbar.selected)
	var hs = hotbar.slots[sel]

	if hs.id == 0:
		hotbar.slots[sel] = _sanitize_slot({"id": item_id, "count": cap})
		hotbar.queue_redraw()
		queue_redraw()
		hotbar._ensure_spyglass()
		_touch_player_save()
		return

	if hs.id == item_id and int(hs.count) < cap:
		hs.count = cap
		hotbar.slots[sel] = _sanitize_slot(hs)
		hotbar.queue_redraw()
		queue_redraw()
		hotbar._ensure_spyglass()
		_touch_player_save()
		return


	for i in hotbar.SLOT_COUNT:
		var s = hotbar.slots[i]
		if int(s.id) == 0:
			hotbar.slots[i] = _sanitize_slot({"id": item_id, "count": cap})
			hotbar.queue_redraw()
			queue_redraw()
			hotbar._ensure_spyglass()
			_touch_player_save()
			return


	for i in hotbar.SLOT_COUNT:
		var s = hotbar.slots[i]
		if int(s.id) == item_id and int(s.count) < cap:
			s.count = cap
			hotbar.slots[i] = _sanitize_slot(s)
			hotbar.queue_redraw()
			queue_redraw()
			hotbar._ensure_spyglass()
			_touch_player_save()
			return







const STACK_CAP_BY_ITEM: = {
	35: 16, 
	71: 16, 
	72: 1, 
	73: 1
}

func _craft_any_ids() -> Array:
	var w = _get_world()
	if w == null:
		return []

	return [w.ITEM_LOG, w.ITEM_DARK_LOG, w.ITEM_YOYLE_LOG, w.ITEM_BUSH_LOG]

func _count_total_any_of(ids: Array) -> int:
	var tot: = 0
	for id in ids:
		tot += _count_total(int(id))
	return tot


func _take_from_sources(item_id: int, need: int) -> Dictionary:
	var took_inv: = 0
	var took_hb: = 0

	if need > 0:
		took_inv = int(take_item(item_id, need))
		need -= took_inv

	if need > 0 and hotbar and hotbar.has_method("consume_item_id"):
		took_hb = int(hotbar.consume_item_id(item_id, need))
		need -= took_hb
	return {"id": item_id, "inv": took_inv, "hb": took_hb, "left": need}

func _record_consumption(consumed: Array, id: int, took_inv: int, took_hb: int) -> void :
	consumed.append({"id": id, "inv": took_inv, "hb": took_hb})

func _refund(consumed: Array) -> void :

	for rec in consumed:
		var id: = int(rec["id"])
		var inv: = int(rec["inv"])
		var hb: = int(rec["hb"])
		if inv > 0:
			try_add(id, inv)
		if hb > 0 and hotbar and hotbar.has_method("try_add"):
			hotbar.try_add(id, hb)
	if hotbar: hotbar.queue_redraw()
	queue_redraw()



func _take_any_of(ids: Array, need: int) -> Array:
	var consumed: Array = []
	var left: = need


	for id in ids:
		if left <= 0: break
		var before: = left
		var took: = int(take_item(int(id), left))
		left -= took
		if took > 0:
			_record_consumption(consumed, int(id), took, 0)


	if left > 0 and hotbar and hotbar.has_method("consume_item_id"):
		for id in ids:
			if left <= 0: break
			var took_hb: = int(hotbar.consume_item_id(int(id), left))
			left -= took_hb
			if took_hb > 0:
				_record_consumption(consumed, int(id), 0, took_hb)


	return consumed

func _sum_consumed(consumed_list: Array) -> int:
	var s: = 0
	for rec in consumed_list:
		s += int(rec["inv"]) + int(rec["hb"])
	return s

func _get_world() -> Node:
	if world != null and is_instance_valid(world):
		return world
	world = get_tree().get_first_node_in_group("world")
	return world

var slots: Array = []
var hover: = -1


var carry: = {"id": 0, "count": 0}

var _craft_icon_warmed: bool = false


@onready var hotbar: Hotbar = get_tree().get_first_node_in_group("hotbar") as Hotbar

func _count_in_inventory(item_id: int) -> int:
	var total: = 0
	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == item_id:
			total += int(s.count)
	return total

func _craft_button_rect() -> Rect2:
	var origin: = _panel_origin()
	var grid_sz: = Vector2(
		COLS * slot_size.x + (COLS - 1) * slot_gap.x, 
		ROWS * slot_size.y + (ROWS - 1) * slot_gap.y
	)
	var panel_sz: = grid_sz + panel_pad * 2.0
	var panel_pos: = Vector2(
		floor((size.x - panel_sz.x) / 2.0), 
		floor((size.y - panel_sz.y) / 2.0)
	)

	var btn_pos: = Vector2(
		panel_pos.x + (panel_sz.x - CRAFT_BUTTON_SIZE.x) * 0.5, 
		panel_pos.y + panel_sz.y + 10
	)
	return Rect2(btn_pos, CRAFT_BUTTON_SIZE)


func _count_total(item_id: int) -> int:
	var tot: = _count_in_inventory(item_id)
	if hotbar:
		for i in hotbar.SLOT_COUNT:
			var s = hotbar.slots[i]
			if s.id == item_id:
				tot += int(s.count)
	return tot


func _client_can_take_like_pickup(id: int, amount: int) -> bool:
	var need: = amount
	var inv: = get_tree().get_first_node_in_group("inventory")
	if inv and inv.has_method("space_for"):
		need -= int(inv.space_for(id, need))
	var hb: = get_tree().get_first_node_in_group("hotbar")
	if hb and hb.has_method("space_for") and need > 0:
		need -= int(hb.space_for(id, need))
	return need <= 0



func _give_like_pickup(id: int, amount: int) -> int:
	var left: = amount
	if hotbar and hotbar.has_method("try_add"):
		left = int(hotbar.try_add(id, left))
	if left > 0:
		left = int(try_add(id, left))
	if hotbar: hotbar.queue_redraw()
	queue_redraw()
	return left


func _ensure_craft_icon_registered() -> void :
	if hotbar == null: return
	var w = _get_world()
	if w == null: return
	if hotbar.icon_by_item.has(w.ITEM_CRAFT) and hotbar.icon_by_item[w.ITEM_CRAFT] != null:
		return

	var ground = w.get("ground")
	if ground == null: return
	var ts: TileSet = ground.tile_set
	if ts == null: return

	var src: = ts.get_source(w.SRC)
	if src is TileSetAtlasSource:
		var atlas: = src as TileSetAtlasSource
		if atlas.has_tile(w.T_CRAFT):
			var region: = atlas.get_tile_texture_region(w.T_CRAFT, 0)
			var at: = AtlasTexture.new()
			at.atlas = atlas.texture
			at.region = Rect2(region.position, region.size)
			at.filter_clip = true
			if hotbar.has_method("register_item_icon"):
				hotbar.register_item_icon(w.ITEM_CRAFT, at)


func _attempt_craft_table() -> void :
	var w = _get_world()
	if w == null or hotbar == null: return

	var any_ids: = _craft_any_ids()
	if any_ids.is_empty():
		return


	if _count_total_any_of(any_ids) < CRAFT_COST_LOGS:
		return

	_ensure_craft_icon_registered()


	var consumed: = _take_any_of(any_ids, CRAFT_COST_LOGS)
	if _sum_consumed(consumed) < CRAFT_COST_LOGS:

		_refund(consumed)
		return


	var leftover: = _give_like_pickup(w.ITEM_CRAFT, 1)
	if leftover > 0:

		_refund(consumed)
	else:
		_touch_player_save()

func _ready() -> void :
	add_to_group("inventory")
	set_process_input(true)
	set_process_unhandled_input(true)


	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var ev: = InputEventKey.new();ev.physical_keycode = KEY_Z
		InputMap.action_add_event("toggle_inventory", ev)

	if GameSession.creative and _is_host():
		creative_mode = true


	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = {"id": 0, "count": 0}

	visible = false
	_warm_craft_icon()
	queue_redraw()

func _is_host() -> bool:

	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()

func _warm_craft_icon() -> void :
	var w = _get_world()
	if w == null:
		return
	_ensure_craft_icon_registered()
	_craft_icon_warmed = hotbar != null\
	and hotbar.icon_by_item.has(w.ITEM_CRAFT)\
	and hotbar.icon_by_item[w.ITEM_CRAFT] != null



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


	var box: = get_tree().get_first_node_in_group("yoylite_box_menu")
	if want_open and box and box.visible and box.has_method("_commit_and_close"):
		box._commit_and_close()

	visible = want_open
	if visible: grab_focus()
	_update_player_input_gate()
	queue_redraw()


func is_open() -> bool: return visible

func _stack_cap_for(id: int) -> int:

	if hotbar and hotbar.has_method("_stack_cap_for"):
		return int(hotbar._stack_cap_for(id))

	if ToolDurability.is_tool_id(id):
		return 1
	return int(STACK_CAP_BY_ITEM.get(id, Hotbar.STACK_MAX))

func try_add(item_id: int, amount: int = 1) -> int:
	var left: = amount
	var cap: = _stack_cap_for(item_id)
	var is_meta_bearer: = (cap == 1) or ToolDurability.is_tool_id(item_id)


	if cap > 1:
		for i in SLOT_COUNT:
			var s = slots[i]
			if s.id == item_id and s.count < cap:
				var take = min(cap - s.count, left)
				s.count += take
				left -= take
				slots[i] = _sanitize_slot(s)
				if left == 0: queue_redraw();_touch_player_save();return 0


	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == 0:
			var take = min(cap, left)
			var entry: = {"id": item_id, "count": take}
			if is_meta_bearer:



				entry["meta"] = entry.get("meta", {})
				if ToolDurability.is_tool_id(item_id):
					entry = ToolDurability.ensure_meta(entry)
			elif ToolDurability.is_tool_id(item_id):
				entry = ToolDurability.ensure_meta(entry)

			slots[i] = _sanitize_slot(entry)
			left -= take
			if left == 0: queue_redraw();_touch_player_save();return 0

	queue_redraw();_touch_player_save();return left

func add_with_meta(item_id: int, amount: int = 1, meta: Dictionary = {}) -> int:
	var left: = amount
	var cap: = _stack_cap_for(item_id)
	var is_meta_bearer: = (cap == 1) or ToolDurability.is_tool_id(item_id)


	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == item_id and s.count < cap:
			var take = min(cap - s.count, left)
			s.count += take
			left -= take
			slots[i] = s
			slots[i] = _sanitize_slot(slots[i])
			if left == 0:
				queue_redraw();_touch_player_save();return 0


	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == 0:
			var take = min(cap, left)
			var entry: = {"id": item_id, "count": take}
			if is_meta_bearer:

				entry["meta"] = (entry.get("meta", {}) as Dictionary).merged(meta, true)
			elif ToolDurability.is_tool_id(item_id):
				entry = ToolDurability.ensure_meta(entry)

			slots[i] = entry
			slots[i] = _sanitize_slot(slots[i])
			left -= take
			if left == 0:
				queue_redraw();_touch_player_save();return 0

	queue_redraw();_touch_player_save();return left


func space_for(item_id: int, amount: int) -> int:
	var free: = 0
	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == item_id and s.count < _stack_cap_for(item_id):
			free += min(_stack_cap_for(item_id) - s.count, amount - free)
			if free >= amount: return amount
	for i in SLOT_COUNT:
		if slots[i].id == 0:
			free += min(_stack_cap_for(item_id), amount - free)
			if free >= amount: return amount
	return free

func take_item(item_id: int, amount: int = 1) -> int:

	var need: = amount
	for i in SLOT_COUNT:
		if need <= 0: break
		var s = slots[i]
		if s.id == item_id and s.count > 0:
			var take = min(s.count, need)
			s.count -= take
			need -= take
			if s.count == 0: s.id = 0
			s = _sanitize_slot(s)
			slots[i] = s
	if amount != need: queue_redraw()
	_touch_player_save()
	return amount - need

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

	if e.is_action_pressed("toggle_inventory"):
		toggle_visible()

	if not visible:
		return

	if e.is_action_pressed("ui_cancel"):
		toggle_visible()

func _swap_with_hotbar(idx: int) -> void :
	if hotbar == null:
		return

	var inv_stack = slots[idx]
	var hb_stack = hotbar.slots[hotbar.selected]

	if inv_stack.id != 0 and hb_stack.id != 0 and inv_stack.id == hb_stack.id:
		var cap: = _stack_cap_for(int(inv_stack.id))
		if cap > 1:
			var total: = int(inv_stack.count) + int(hb_stack.count)
			var to_inv = min(total, cap)
			var leftover = total - to_inv

			inv_stack.count = to_inv
			if leftover > 0:
				hb_stack.count = leftover
				hb_stack.id = inv_stack.id
			else:
				hb_stack = {"id": 0, "count": 0}

			slots[idx] = _sanitize_slot(inv_stack)
			hotbar.slots[hotbar.selected] = _sanitize_slot(hb_stack)
		else:

			slots[idx] = _sanitize_slot(hb_stack)
			hotbar.slots[hotbar.selected] = _sanitize_slot(inv_stack)
	else:

		slots[idx] = _sanitize_slot(hb_stack)
		hotbar.slots[hotbar.selected] = _sanitize_slot(inv_stack)
	hotbar._ensure_spyglass()
	hotbar.queue_redraw()
	queue_redraw()
	_touch_player_save()


func _gui_input(e: InputEvent) -> void :
	if not visible:
		return


	if e is InputEventMouse:
		accept_event()

	if e is InputEventMouseMotion:
		hover = _index_at_pos(e.position)
		craft_btn_hover = _craft_button_rect().has_point(e.position)
		page_left_hover = creative_mode and creative_show_menu and _page_left_rect().has_point(e.position)
		page_right_hover = creative_mode and creative_show_menu and _page_right_rect().has_point(e.position)


		mouse_default_cursor_shape = (
			CURSOR_POINTING_HAND if (hover != -1 or craft_btn_hover or page_left_hover or page_right_hover)
			else CURSOR_ARROW
		)

		queue_redraw()
		return

	elif e is InputEventMouseButton and e.pressed:


		if creative_mode and creative_show_menu and e.button_index == MOUSE_BUTTON_LEFT:
			if _page_left_rect().has_point(e.position):
				creative_page = max(creative_page - 1, 0)
				queue_redraw()
				return
			if _page_right_rect().has_point(e.position):
				var tp: = _creative_total_pages()
				creative_page = min(creative_page + 1, tp - 1)
				queue_redraw()
				return


		if e.button_index == MOUSE_BUTTON_LEFT and _craft_button_rect().has_point(e.position):
			if creative_mode:

				creative_show_menu = not creative_show_menu
				queue_redraw()
				return
			else:
				_attempt_craft_table()
				queue_redraw()
				return



		var idx: = _index_at_pos(e.position)
		if idx == -1:

			mouse_default_cursor_shape = CURSOR_ARROW
			return


		mouse_default_cursor_shape = CURSOR_POINTING_HAND

		if e.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(idx, e)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click(idx, e)

		queue_redraw()

func _on_left_click(idx: int, _e: InputEventMouseButton) -> void :
	if creative_mode and creative_show_menu:
		var id: = _creative_id_at_slot(idx)
		if id != 0:
			_give_one_slot_to_hotbar(id)
		return


	_swap_with_hotbar(idx)



func _on_right_click(idx: int, _e: InputEventMouseButton) -> void :
	if creative_mode and creative_show_menu:

		return
	var s = slots[idx]

	if carry.id == 0 and s.id != 0 and s.count > 1:
		var half: = int(ceil(s.count / 2.0))
		carry = {"id": s.id, "count": half}
		s.count -= half
		if s.count <= 0: s.id = 0
		slots[idx] = s
		return


	if carry.id != 0:
		if s.id == 0:
			slots[idx] = _sanitize_slot({"id": carry.id, "count": 1})
			carry.count -= 1
			if carry.count <= 0: carry = {"id": 0, "count": 0}
			return
		if s.id == carry.id and s.count < _stack_cap_for(s.id):
			s.count += 1
			carry.count -= 1
			slots[idx] = _sanitize_slot(s)
			if carry.count <= 0: carry = {"id": 0, "count": 0}
			return


func _quick_move_to_hotbar(idx: int) -> void :
	if hotbar == null: return
	var s = slots[idx]
	if s.id == 0 or s.count == 0: return
	var left: = hotbar.try_add(s.id, s.count)
	var moved = s.count - left
	if moved > 0:
		s.count = left
		if s.count <= 0: s.id = 0
		slots[idx] = s
	_touch_player_save()


func _draw() -> void :
	if not visible: return

	if not _craft_icon_warmed:
		_ensure_craft_icon_registered()
		_craft_icon_warmed = hotbar != null\
		and hotbar.icon_by_item.has(Hotbar.ITEM_CRAFT)\
		and hotbar.icon_by_item[Hotbar.ITEM_CRAFT] != null

	var grid_sz: = Vector2(
		COLS * slot_size.x + (COLS - 1) * slot_gap.x, 
		ROWS * slot_size.y + (ROWS - 1) * slot_gap.y
	)
	var panel_sz: = grid_sz + panel_pad * 2.0
	var panel_pos: = Vector2(
		floor((size.x - panel_sz.x) / 2.0), 
		floor((size.y - panel_sz.y) / 2.0)
	)


	var panel_rect: = Rect2(panel_pos, panel_sz)
	draw_rect(panel_rect, bg_color, true)
	draw_rect(panel_rect, panel_outline, false, 2.0)


	for i in SLOT_COUNT:
		var r: = _slot_rect_local(i, panel_pos + panel_pad)
		var fill: = slot_fill
		if i == hover: fill.a = 0.95
		draw_rect(r, fill, true)
		draw_rect(r, slot_outline, false, 2.0)


		if creative_mode and creative_show_menu:
			var cid: = _creative_id_at_slot(i)
			if cid != 0:
				var tex: = _icon_for(cid)
				if tex:
					var tsize: = tex.get_size()
					var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
					draw_texture_rect(tex, Rect2(r.position + Vector2(4, 4), tsize * sc), false)
		else:
			var s = slots[i]
			if s.id != 0:
				var tex: = _icon_for(s.id)
				if tex:
					var tsize: = tex.get_size()
					var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
					draw_texture_rect(tex, Rect2(r.position + Vector2(4, 4), tsize * sc), false)
				if s.count > 1:
					_draw_count(r, s.count)


			if ToolDurability.is_tool_id(int(s.get("id", 0)))\
			and s.has("meta") and typeof(s.meta) == TYPE_DICTIONARY:
				var m = s.meta
				if m.get("used", false) and int(m.get("max", 0)) > 0:
					var dur = clamp(int(m.get("dur", 0)), 0, int(m["max"]))
					var pct: = float(dur) / float(m["max"])
					var h: = 5.0
					var pad: = 3.0
					var bar: = Rect2(r.position + Vector2(pad, r.size.y - h - pad), Vector2(r.size.x - pad * 2.0, h))
					draw_rect(bar, Color(0, 0, 0, 0.35), true)
					var filla: = Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y))
					var col: = _durability_color(pct, 0.95)
					draw_rect(filla, col, true)


	if carry.id != 0:
		var tex: = _icon_for(carry.id)
		if tex:
			var mp: = get_local_mouse_position()
			var tsize: = tex.get_size()
			var sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)
			var rect: = Rect2(mp - (tsize * sc) * 0.5, tsize * sc)
			draw_texture_rect(tex, rect, false, carry_tint)
		if carry.count > 1:
			var rect2: = Rect2(get_local_mouse_position() + Vector2(12, 10), slot_size)
			_draw_count(rect2, carry.count)

	var btn: = _craft_button_rect()

	var btn_fill: = Color(0.12, 0.12, 0.12, 0.95)
	var btn_outline: = Color(1, 1, 1, 0.45)

	var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
	var label: = ""
	var color: = Color(1, 1, 1, 0.95)

	var text_x_offset: = 10.0

	if creative_mode:
		_build_creative_catalog_if_needed()
		var tp: = _creative_total_pages()
		creative_page = clamp(creative_page, 0, tp - 1)

		label = ("Show Inventory" if creative_show_menu else "Show Creative Menu")
		if creative_show_menu:
			label += "   (Page %d / %d)" % [creative_page + 1, tp]

		if craft_btn_hover:
			btn_fill = Color(0.18, 0.18, 0.18, 0.98)

		draw_rect(btn, btn_fill, true)
		draw_rect(btn, btn_outline, false, 2.0)

		var text_rect: = Rect2(
			btn.position + Vector2(text_x_offset, 0), 
			Vector2(btn.size.x - text_x_offset - 10.0, btn.size.y)
		)
		_draw_text_center(font, text_rect, label, 16, color)

	else:
		var can_craft: = _count_total_any_of(_craft_any_ids()) >= CRAFT_COST_LOGS
		if not can_craft:
			btn_fill.a = 0.45
			color = Color(1, 1, 1, 0.6)
		if craft_btn_hover and can_craft:
			btn_fill = Color(0.18, 0.18, 0.18, 0.98)

		draw_rect(btn, btn_fill, true)
		draw_rect(btn, btn_outline, false, 2.0)


		var w = _get_world()
		var craft_tex: = _icon_for(w.ITEM_CRAFT) if w != null else null
		if craft_tex:
			var tsize: = craft_tex.get_size()
			var sc = min((btn.size.y - 10.0) / tsize.y, 1.0)
			var icon_size = tsize * sc
			var icon_pos: = btn.position + Vector2(6, (btn.size.y - icon_size.y) * 0.5)
			draw_texture_rect(craft_tex, Rect2(icon_pos, icon_size), false)
			text_x_offset = icon_size.x + 14.0

		label = "Craft Crafting Table  (10 logs of any variant)"

		var text_rect: = Rect2(
			btn.position + Vector2(text_x_offset, 0), 
			Vector2(btn.size.x - text_x_offset - 10.0, btn.size.y)
		)
		_draw_label_fit(font, text_rect, label, 16, color)

	if creative_mode and creative_show_menu:
		var tp: = _creative_total_pages()
		creative_page = clamp(creative_page, 0, tp - 1)

		var l: = _page_left_rect()
		var r: = _page_right_rect()

		var l_enabled: = creative_page > 0
		var r_enabled: = creative_page < tp - 1

		var fill: = Color(0.12, 0.12, 0.12, 0.95)
		var outline: = Color(1, 1, 1, 0.45)

		var lf: = fill
		var rf: = fill
		if not l_enabled: lf.a = 0.45
		if not r_enabled: rf.a = 0.45
		if page_left_hover and l_enabled: lf = Color(0.18, 0.18, 0.18, 0.98)
		if page_right_hover and r_enabled: rf = Color(0.18, 0.18, 0.18, 0.98)

		draw_rect(l, lf, true)
		draw_rect(l, outline, false, 2.0)
		draw_rect(r, rf, true)
		draw_rect(r, outline, false, 2.0)


		var f: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
		var cL: = Color(1, 1, 1, 0.95 if l_enabled else 0.6)
		var cR: = Color(1, 1, 1, 0.95 if r_enabled else 0.6)

		_draw_text_center(f, l, "<", 26, cL)
		_draw_text_center(f, r, ">", 26, cR)



func _draw_text_center(font: Font, rect: Rect2, text: String, size: int, col: Color, outline_px: int = 2, outline_col: Color = Color(0, 0, 0, 0.85)) -> void :
	var ts: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)

	var ascent: = font.get_ascent(size)
	var pos: = rect.position + Vector2(
		(rect.size.x - ts.x) * 0.5, 
		(rect.size.y - ts.y) * 0.5 + ascent
	)

	if outline_px > 0:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_px, outline_col)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _durability_color(pct: float, alpha: float = 0.95) -> Color:
	pct = clamp(pct, 0.0, 1.0)
	var hue: = pct * 0.33
	return Color.from_hsv(hue, 0.95, 0.95, alpha)


func _sanitize_slot(slot: Dictionary) -> Dictionary:
	var s: = slot.duplicate(true)

	if not s.has("id"): s["id"] = 0
	if not s.has("count"): s["count"] = 0
	if not s.has("meta"): s["meta"] = {}

	var world: = get_tree().get_first_node_in_group("world")
	if world and s["id"] == world.ITEM_YOYLITE_BOX:
		s = BoxMeta.ensure_for_slot(s)
	return s

func _sanitize_tool_meta(m: Dictionary) -> Dictionary:
	return {
		"dur": int(m.get("dur", 0)), 
		"max": int(m.get("max", m.get("max_dur", 0))), 
		"max_dur": int(m.get("max_dur", m.get("max", 0)))
	}

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

func _draw_label_fit(font: Font, rect: Rect2, text: String, base_size: int, col: Color, min_size: int = 8, ellipsize: bool = true) -> void :
	var size: = base_size
	var width: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var max_w: = rect.size.x


	while width > max_w and size > min_size:
		size -= 1
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


	var final_text: = text
	if ellipsize and width > max_w:
		var dots: = "..."
		var dots_w: = font.get_string_size(dots, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var i: = text.length()
		while i > 0 and font.get_string_size(text.substr(0, i) + dots, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
			i -= 1
		final_text = (text.substr(0, i) + dots) if i > 0 else dots


	var pos: = rect.position + Vector2(0, rect.size.y * 0.65)
	if count_outline_size > 0:
		draw_string_outline(font, pos, final_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0, 0, 0, 0.85))
	draw_string(font, pos, final_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _slot_rect_local(i: int, origin: Vector2) -> Rect2:
	var col: = i % COLS
	var row: = i / COLS
	var pos: = origin + Vector2(
		col * (slot_size.x + slot_gap.x), 
		row * (slot_size.y + slot_gap.y)
	)
	return Rect2(pos, slot_size)

func _index_at_pos(local_pos: Vector2) -> int:
	var origin: = _panel_origin()
	for i in SLOT_COUNT:
		if _slot_rect_local(i, origin).has_point(local_pos):
			return i
	return -1

func _panel_origin() -> Vector2:
	var grid_sz: = Vector2(
		COLS * slot_size.x + (COLS - 1) * slot_gap.x, 
		ROWS * slot_size.y + (ROWS - 1) * slot_gap.y
	)
	var panel_sz: = grid_sz + panel_pad * 2.0
	var panel_pos: = Vector2(
		floor((size.x - panel_sz.x) / 2.0), 
		floor((size.y - panel_sz.y) / 2.0)
	)
	return panel_pos + panel_pad

func _icon_for(id: int) -> Texture2D:
	if hotbar and hotbar.icon_by_item.has(id):
		return hotbar.icon_by_item[id]
	return null

func _update_player_input_gate() -> void :

	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_input_enabled"):
			p.call("set_input_enabled", not visible)

func clear_all() -> void :

	for i in SLOT_COUNT:
		slots[i] = {"id": 0, "count": 0}
	queue_redraw()
	_touch_player_save()

func _touch_player_save() -> void :
	if GameSession.current_world_id != "":
		PlayerSave.queue_save()
