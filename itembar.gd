extends Control
class_name Hotbar

const SLOT_COUNT: = 7
const STACK_MAX: = 64



const ITEM_LOG: = 5
const ITEM_CRAFT: = 7



@export var tileset: TileSet
@export var craft_src_id: = 0
@export var craft_coords: = Vector2i(0, 2)



const VISUAL_SLOTS: = SLOT_COUNT + 1
const INV_BTN_INDEX: = SLOT_COUNT


@export var slot_size: = Vector2(60, 60)
@export var slot_gap: = 8.0

const count_font = preload("res://Shag-Lounge.otf")
@export var count_font_size: int = 16
@export var count_outline_size: int = 4
@export var count_outline_color: Color = Color(0, 0, 0, 0.85)

var icon_by_item: Dictionary = {}

var slots: Array = []
var selected: = 0
var hover_idx: = -1

const CRAFT_SRC_ID: = 0
const CRAFT_COORDS: = Vector2i(0, 2)

@export var name_by_item: Dictionary = {}

var _select_tween: Tween
var _hint: PanelContainer
var _hint_label: Label


const STACK_CAP_BY_ITEM: = {
	35: 16, 
	71: 16, 
	72: 1, 
	73: 1
}


var _icon_scale: = []
var _icon_tween: = []

func sync_held_item_now() -> void :


	if not is_inside_tree():
		return

	var w: = get_tree().get_first_node_in_group("world")
	if w and w.has_method("cli_set_local_held_item"):
		var s = slots[selected] if selected >= 0 and selected < slots.size() else {"id": 0}
		var id: = int(s.get("id", 0))
		w.call_deferred("cli_set_local_held_item", id)

func _notify_held_item_changed() -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w == null:
		return
	var item_id: = 0
	if selected >= 0 and selected < slots.size():
		var s = slots[selected]
		item_id = int(s.get("id", 0))


	if w.has_method("client_set_held_item"):
		w.call_deferred("client_set_held_item", item_id)

func get_selected_item_icon() -> Texture2D:
	var id: = get_selected_item_id()
	if id == 0:
		return null
	return icon_by_item.get(id, null)

func _register_craft_icon_from_tileset() -> void :
	if tileset == null: return
	var src: = tileset.get_source(CRAFT_SRC_ID)
	if src is TileSetAtlasSource:
		var atlas: = src as TileSetAtlasSource
		if atlas.has_tile(CRAFT_COORDS):
			var region: = atlas.get_tile_texture_region(CRAFT_COORDS, 0)
			var at: = AtlasTexture.new()
			at.atlas = atlas.texture
			at.region = Rect2(region.position, region.size)
			register_item_icon(ITEM_CRAFT, at)

func _cmd_box_node() -> LineEdit:
	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_node("CanvasLayer/CommandBox"):
		return world.get_node("CanvasLayer/CommandBox") as LineEdit

	var n: = get_tree().get_root().find_child("CommandBox", true, false)
	return n as LineEdit

var _retry_icon_frames: = 0

func _is_command_box_open() -> bool:
	var cb: = _cmd_box_node()
	return cb != null and cb.visible

func _kick_icon_rehydrate() -> void :

	_retry_icon_frames = 120
	rehydrate_icons_from_slots()

func rehydrate_icons_from_slots() -> void :
	for i in SLOT_COUNT:
		var id: = int(slots[i].get("id", 0))
		if id != 0:
			_ensure_icon_for(id)
	queue_redraw()















@export var status_pc_scale: = 0.7
@export var status_margin_y: = 6.0
@export var status_gap_y: = 4.0


@export var health_visual_offset: = Vector2(0, -90)
@export var hunger_visual_offset: = Vector2(12, -50)
@export var oxygen_visual_offset: = Vector2(12, -90)


@export var health_visual_size_override: = Vector2.ZERO
@export var hunger_visual_size_override: = Vector2.ZERO
@export var oxygen_visual_size_override: = Vector2.ZERO


@export var desktop_slot_scale: = 0.8
@export var desktop_gap_scale: = 0.8
@export var desktop_font_scale: = 0.8
@export var desktop_status_scale: = 0.8


@export var bottom_margin_px: = 0


func _place_bottom_center_desktop() -> void :
	if not _is_pc():
		return

	top_level = true
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	anchor_left = 0;anchor_top = 0;anchor_right = 0;anchor_bottom = 0
	pivot_offset = Vector2.ZERO


	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2((VISUAL_SLOTS * slot_size.x) + ((VISUAL_SLOTS - 1) * slot_gap), slot_size.y)

	var vp: = get_viewport().get_visible_rect().size

	var want_pos: = Vector2(
		floor((vp.x - size.x) * 0.5), 
		floor(vp.y - size.y - bottom_margin_px)
	)
	position = want_pos

func _infer_visual_size_from_children(node: Node) -> Vector2:
	var max_w: = 0.0
	var max_h: = 0.0


	var consider_size = func(sz: Vector2) -> void :
		max_w = max(max_w, sz.x)
		max_h = max(max_h, sz.y)


	if node is Control:
		var c: = node as Control
		var s: = c.size
		if s.x > 1.0 and s.y > 1.0:
			return s
		var ms: = c.get_combined_minimum_size()
		if ms.x > 1.0 and ms.y > 1.0:
			return ms


	for child in node.get_children():
		if child is TextureRect:
			var tr: = child as TextureRect
			if tr.texture:
				consider_size.call(tr.size * tr.scale)
		elif child is Sprite2D:
			var sp: = child as Sprite2D
			if sp.texture:
				var tex_sz: = sp.texture.get_size()
				consider_size.call(Vector2(abs(sp.scale.x), abs(sp.scale.y)) * tex_sz)
		elif child is NinePatchRect:
			var np: = child as NinePatchRect
			consider_size.call(np.size * np.scale)
		elif child is Label:
			var lb: = child as Label
			consider_size.call(lb.get_minimum_size() * lb.scale)


		if child.get_child_count() > 0:
			var sub: = _infer_visual_size_from_children(child)
			if sub.x > 0.0 and sub.y > 0.0:
				consider_size.call(sub)

	return Vector2(max_w, max_h)


func _adopt_into_hotbar(c: Control) -> void :
	if c == null: return
	if c.get_parent() != self:
		var old_parent: = c.get_parent()
		if old_parent:
			old_parent.remove_child(c)
		add_child(c)

	c.top_level = false
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.anchor_left = 0;c.anchor_top = 0;c.anchor_right = 0;c.anchor_bottom = 0
	c.pivot_offset = Vector2.ZERO
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _prep_status_widgets(health: Control, hunger: Control, oxygen: Control) -> void :
	for c in [health, hunger, oxygen]:
		if c == null: continue

		c.top_level = true
		c.scale = Vector2.ONE * status_pc_scale
		var cms = c.get_combined_minimum_size()
		if cms.x > 1.0 and cms.y > 1.0:
			c.custom_minimum_size = cms
			c.size = cms


func _infer_visual_aabb(node: Node) -> Array:
	var min_x: = INF
	var min_y: = INF
	var max_x: = - INF
	var max_y: = - INF


	var include_point = func(p: Vector2) -> void :
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	var include_rect = func(top_left: Vector2, size: Vector2) -> void :
		include_point.call(top_left)
		include_point.call(top_left + size)


	if node is Control:
		var c: = node as Control
		var s: = c.size
		if s.x > 1.0 and s.y > 1.0:
			return [Vector2.ZERO, s]
		var ms: = c.get_combined_minimum_size()
		if ms.x > 1.0 and ms.y > 1.0:
			return [Vector2.ZERO, ms]


	for child in node.get_children():
		if child is Control:
			var cc: = child as Control
			var top_left: = cc.position
			var sz: = cc.size
			if sz.x <= 1.0 or sz.y <= 1.0:
				var cms: = cc.get_combined_minimum_size()
				if cms.x > 1.0 and cms.y > 1.0:
					sz = cms
			if sz.x > 0.0 and sz.y > 0.0:
				var sc: = cc.scale
				sz = Vector2(abs(sc.x), abs(sc.y)) * sz
				include_rect.call(top_left, sz)

		elif child is Sprite2D:
			var sp: = child as Sprite2D
			if sp.texture:
				var tex_sz: = sp.texture.get_size()
				var sc: = Vector2(abs(sp.scale.x), abs(sp.scale.y))
				var actual: = tex_sz * sc
				var pivot: = (tex_sz * 0.5) if sp.centered else Vector2.ZERO
				var tl: = sp.position - (pivot * sc) - (sp.offset * sc)
				include_rect.call(tl, actual)


		if child.get_child_count() > 0:
			var sub: = _infer_visual_aabb(child)
			var sub_off: = sub[0] as Vector2
			var sub_sz: = sub[1] as Vector2
			if sub_sz.x > 0.0 and sub_sz.y > 0.0:
				var parent_pos: = Vector2.ZERO
				if child is Control:
					parent_pos = (child as Control).position
				include_rect.call(sub_off + parent_pos, sub_sz)


	if min_x == INF or min_y == INF or max_x == - INF or max_y == - INF:
		return [Vector2.ZERO, Vector2(32, 32)]

	return [Vector2(min_x, min_y), Vector2(max(0.0, max_x - min_x), max(0.0, max_y - min_y))]




func _visual_offset_and_size(c: Control, override_size: Vector2, explicit_offset: Vector2) -> Array:
	var off: = explicit_offset
	var sz: = override_size


	if sz.x <= 0.0 or sz.y <= 0.0 or off == Vector2.ZERO:
		var inferred: = _infer_visual_aabb(c)
		var inf_off: Vector2 = inferred[0]
		var inf_sz: Vector2 = inferred[1]

		if off == Vector2.ZERO:
			off = inf_off
		if sz.x <= 0.0 or sz.y <= 0.0:
			sz = inf_sz


	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = Vector2(32, 32)


	return [off * status_pc_scale, sz * status_pc_scale]

func _visual_size(c: Control, override_size: Vector2) -> Vector2:

	if override_size.x > 0.0 and override_size.y > 0.0:
		return override_size * status_pc_scale


	var base: = c.get_combined_minimum_size()
	if base.x <= 1.0 or base.y <= 1.0:
		base = c.size


	if base.x <= 1.0 or base.y <= 1.0:
		base = _infer_visual_size_from_children(c)


	if base.x <= 1.0 or base.y <= 1.0:
		base = Vector2(32, 32)

	return base * status_pc_scale

@onready var heart: Sprite2D = $"../health/Heart"
@onready var heart_2: Sprite2D = $"../health/Heart2"
@onready var heart_3: Sprite2D = $"../health/Heart3"
@onready var heart_4: Sprite2D = $"../health/Heart4"
@onready var heart_5: Sprite2D = $"../health/Heart5"
@onready var absorb: Sprite2D = $"../health/Absorb"
@onready var absorb_2: Sprite2D = $"../health/Absorb2"
@onready var absorb_3: Sprite2D = $"../health/Absorb3"
@onready var absorb_4: Sprite2D = $"../health/Absorb4"
@onready var absorb_5: Sprite2D = $"../health/Absorb5"

func _layout_status_over_slots() -> void :
	if not _is_pc(): return
	var n: = _find_status_nodes()
	var health = n["health"]; var hunger = n["hunger"]; var oxygen = n["oxygen"]
	if health == null or hunger == null or oxygen == null: return

	_prep_status_widgets(health, hunger, oxygen)
	await get_tree().process_frame


	var left_rect: = _slot_rect(0)
	var right_rect: = _slot_rect(INV_BTN_INDEX)


	var sz_h: = _visual_size(health, health_visual_size_override)
	var sz_u: = _visual_size(hunger, hunger_visual_size_override)
	var sz_o: = _visual_size(oxygen, oxygen_visual_size_override)


	var slot0_left_x: = left_rect.position.x
	var slot0_top_y: = left_rect.position.y

	var inv_right_x: = right_rect.position.x + right_rect.size.x
	var inv_top_y: = right_rect.position.y


	var health_local: = Vector2(
		slot0_left_x, 
		slot0_top_y - status_margin_y - sz_h.y
	)

	var total_stack_h: = sz_u.y + status_gap_y + sz_o.y
	var stack_top_y: = inv_top_y - status_margin_y - total_stack_h

	var hunger_local: = Vector2(
		inv_right_x - sz_u.x, 
		stack_top_y
	)
	var oxygen_local: = Vector2(
		inv_right_x - sz_o.x, 
		stack_top_y + sz_u.y + status_gap_y
	)


	var off_h: = health_visual_offset * status_pc_scale + Vector2(0, 35)
	var off_u: = hunger_visual_offset * status_pc_scale + Vector2(0, 40)
	var off_o: = oxygen_visual_offset * status_pc_scale - Vector2(0, 35)

	var health_canvas = _to_ctrl_canvas(health, health_local + off_h)
	var hunger_canvas = _to_ctrl_canvas(hunger, hunger_local + off_u)
	var oxygen_canvas = _to_ctrl_canvas(oxygen, oxygen_local + off_o)

	health.position = health_canvas.round()
	hunger.position = hunger_canvas.round()
	oxygen.position = oxygen_canvas.round()

	_place_absorb_above_hearts()

@export var heart_fallback_size: = Vector2(839, 803)
@export var absorb_fallback_size: = Vector2(839, 803)
@export var absorb_gap: = 1.0

func _sprite_visual_size(s: Sprite2D, fallback: Vector2) -> Vector2:
	if s == null:
		return fallback
	if s.texture != null:
		return s.texture.get_size() * s.scale

	return fallback * s.scale

func _place_absorb_above_hearts(gap: float = absorb_gap) -> void :
	var hearts: = [heart, heart_2, heart_3, heart_4, heart_5]
	var absorbs: = [absorb, absorb_2, absorb_3, absorb_4, absorb_5]

	var top_y: = INF


	for h in hearts:
		if h == null: continue
		var h_size: = _sprite_visual_size(h, heart_fallback_size)
		var h_top = h.position.y - h_size.y * 0.5
		top_y = min(top_y, h_top)

	if top_y == INF:
		return


	for a in absorbs:
		if a == null: continue
		var a_size: = _sprite_visual_size(a, absorb_fallback_size)
		a.position.y = top_y - gap - a_size.y * 0.5


func _to_ctrl_canvas(ctrl: CanvasItem, p_local_in_hotbar: Vector2) -> Vector2:
	var hotbar_canvas_pos: = get_global_transform_with_canvas() * p_local_in_hotbar
	var their_canvas_xform: = ctrl.get_canvas_transform()

	return their_canvas_xform.affine_inverse() * hotbar_canvas_pos

func _is_pc() -> bool:
	return OS.has_feature("pc") or ( not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available())

func _find_status_nodes() -> Dictionary:
	var root: = get_tree().get_root()
	return {
		"health": root.find_child("health", true, false) as Control, 
		"hunger": root.find_child("hunger", true, false) as Control, 
		"oxygen": root.find_child("oxygen", true, false) as Control, 
	}

func _scaled_min(c: Control) -> Vector2:
	return c.get_combined_minimum_size() * status_pc_scale


func _place_canvas_top_left(ctrl: Control, canvas_top_left: Vector2) -> void :
	ctrl.top_level = true
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.anchor_left = 0;ctrl.anchor_top = 0;ctrl.anchor_right = 0;ctrl.anchor_bottom = 0
	ctrl.pivot_offset = Vector2.ZERO
	ctrl.scale = Vector2.ONE * status_pc_scale
	ctrl.position = canvas_top_left


func _scaled_size(c: Control) -> Vector2:

	var s: = c.size
	if s.x <= 1.0 or s.y <= 1.0:
		s = c.get_combined_minimum_size()
	return s * status_pc_scale

func _wire_status_layout_triggers() -> void :

	if not resized.is_connected(_on_hotbar_resized):
		resized.connect(_on_hotbar_resized)


	var vp: = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

func _on_hotbar_resized() -> void :

	call_deferred("_layout_status_over_slots")

func _on_viewport_resized() -> void :

	call_deferred("_place_bottom_center_desktop")
	call_deferred("_apply_desktop_scaling")
	call_deferred("_layout_status_over_slots")
	await get_tree().process_frame
	call_deferred("_layout_status_over_slots")


var _orig_slot_size: Vector2
var _orig_slot_gap: float
var _orig_count_font_size: int
var _orig_count_outline_size: int
var _orig_status_pc_scale: float

func _apply_desktop_scaling() -> void :

	if _orig_slot_size == Vector2.ZERO:
		_orig_slot_size = slot_size
		_orig_slot_gap = slot_gap
		_orig_count_font_size = count_font_size
		_orig_count_outline_size = count_outline_size
		_orig_status_pc_scale = status_pc_scale


	if not _is_pc():
		slot_size = _orig_slot_size
		slot_gap = _orig_slot_gap
		count_font_size = _orig_count_font_size
		count_outline_size = _orig_count_outline_size
		status_pc_scale = _orig_status_pc_scale
		return


	slot_size = _orig_slot_size * desktop_slot_scale
	slot_gap = _orig_slot_gap * desktop_gap_scale
	count_font_size = int(round(_orig_count_font_size * desktop_font_scale))
	count_outline_size = max(1, int(round(_orig_count_outline_size * desktop_font_scale)))


	status_pc_scale = _orig_status_pc_scale * desktop_status_scale


	custom_minimum_size = Vector2(
		(VISUAL_SLOTS * slot_size.x) + ((VISUAL_SLOTS - 1) * slot_gap), 
		max(48.0, slot_size.y)
	)


	call_deferred("_place_bottom_center_desktop")
	call_deferred("_layout_status_over_slots")
	queue_redraw()

func _ready() -> void :
	add_to_group("hotbar")
	process_mode = Node.PROCESS_MODE_ALWAYS

	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(
			(VISUAL_SLOTS * slot_size.x) + ((VISUAL_SLOTS - 1) * slot_gap), 64
		)

	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = {"id": 0, "count": 0}

	if not InputMap.has_action("drop_one"):
		InputMap.add_action("drop_one")
		var ev: = InputEventKey.new()
		ev.physical_keycode = KEY_Q
		InputMap.action_add_event("drop_one", ev)


	_register_craft_icon_from_tileset()
	call_deferred("_wait_for_world_ready")
	call_deferred("_kick_icon_rehydrate")

	resized.connect( func(): queue_redraw())
	set_process_unhandled_input(true)
	_register_craft_icon_from_tileset()
	call_deferred("_sync_icons_from_world")
	call_deferred("_sync_names_from_world")

	_hint = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_hint.add_theme_stylebox_override("panel", sb)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_hint.modulate.a = 0.0

	_hint_label = Label.new()

	if count_font != null:
		_hint_label.add_theme_font_override("font", count_font)
	_hint_label.add_theme_font_size_override("font_size", max(16, count_font_size + 2))
	_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	_hint.add_child(_hint_label)

	add_child(_hint)

	_icon_scale.resize(SLOT_COUNT)
	_icon_tween.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		_icon_scale[i] = Vector2.ONE
		_icon_tween[i] = null
	_wire_status_layout_triggers()
	_place_bottom_center_desktop()
	_apply_desktop_scaling()
	call_deferred("_layout_status_over_slots")
	queue_redraw()

func _set_icon_scale(idx: int, v: Vector2) -> void :
	_icon_scale[idx] = v
	queue_redraw()

func _kick_icon_squeeze(idx: int) -> void :
	if idx < 0 or idx >= SLOT_COUNT: return

	var t = _icon_tween[idx]
	if t:
		t.kill()
		_icon_tween[idx] = null


	var start: = Vector2(0.48, 1.56)
	var overs: = Vector2(0.98, 1.03)
	_set_icon_scale(idx, start)

	var tw: = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method( func(v): _set_icon_scale(idx, v), start, overs, 0.08)
	tw.tween_method( func(v): _set_icon_scale(idx, v), overs, Vector2.ONE, 0.12)
	_icon_tween[idx] = tw

func _wait_for_world_ready() -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w == null:
		await get_tree().create_timer(0.5).timeout
		call_deferred("_wait_for_world_ready")
		return

	_sync_icons_from_world()

	call_deferred("_ensure_spyglass")

func _sync_names_from_world() -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w == null: return
	if w.has_method("name_map_for_hotbar"):
		var nmap: Dictionary = w.name_map_for_hotbar()
		for id in nmap.keys():
			var nm: = str(nmap[id])
			if nm.strip_edges() != "":
				name_by_item[int(id)] = nm

func _slot_id(idx: int) -> int:
	if idx >= 0 and idx < SLOT_COUNT and idx < slots.size():
		var s = slots[idx]
		return int(s.get("id", 0))
	return 0

func _set_selected(i: int, announce: bool = true) -> void :
	var prev_idx: = selected
	var prev_id: = _slot_id(prev_idx)

	selected = clamp(i, 0, SLOT_COUNT - 1)
	var cur_id: = _slot_id(selected)

	if announce:
		_announce_selection()


	var w: = get_tree().get_first_node_in_group("world")
	if w and w.has_method("cli_reset_local_mine_progress"):
		w.call_deferred("cli_reset_local_mine_progress")


	if w:
		var was_active = (prev_id == w.ITEM_SPYGLASS)
		var now_active = (cur_id == w.ITEM_SPYGLASS)
		if was_active != now_active:

			if w.has_method("cli_toggle_spyglass"):
				w.call_deferred("cli_toggle_spyglass", now_active)
			elif w.has_method("cli_set_spyglass"):
				w.call_deferred("cli_set_spyglass", now_active)


	_notify_held_item_changed()

	queue_redraw()

func _item_name(id: int) -> String:
	if id == 0:
		return ""
	return name_by_item.get(id, "Item %d" % id)

func _announce_selection() -> void :

	var s = slots[selected]
	var nm: = _item_name(s.id)
	if nm == "":

		if _select_tween: _select_tween.kill()
		_hint.visible = false
		_hint.modulate.a = 0.0
		return


	_hint_label.text = nm
	await get_tree().process_frame
	var r: = _slot_rect(selected)
	var want_size: = _hint.get_combined_minimum_size()
	_hint.size = want_size


	var pos: = Vector2(
		r.position.x + (r.size.x - want_size.x) * 0.5, 
		r.position.y - want_size.y - 10
	)

	pos.x = clamp(pos.x, 0.0, max(0.0, size.x - want_size.x))
	pos.y = max(0.0, pos.y)
	_hint.position = pos


	if _select_tween:
		_select_tween.kill()
	_select_tween = create_tween()
	_hint.visible = true
	_hint.modulate.a = 0.0
	_select_tween.tween_property(_hint, "modulate:a", 1.0, 0.1)
	_select_tween.tween_interval(0.9)
	_select_tween.tween_property(_hint, "modulate:a", 0.0, 0.25)
	_select_tween.finished.connect( func():
		_hint.visible = false
	)

func _sync_icons_from_world() -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w and w.has_method("icon_map_for_hotbar"):
		var m: Dictionary = w.icon_map_for_hotbar()
		for id in m.keys():
			var v = m[id]
			if v is Texture2D:
				register_item_icon(int(id), v)
			elif typeof(v) == TYPE_STRING and w.has_method("_get_tex_from_path"):
				var tex = w._get_tex_from_path(String(v))
				if tex: register_item_icon(int(id), tex)
		rehydrate_icons_from_slots()
		_kick_icon_rehydrate()
		queue_redraw()

func _gui_input(e: InputEvent) -> void :
	if e is InputEventMouseMotion:
		hover_idx = _index_at_pos(e.position)
		mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if hover_idx != -1 else Control.CURSOR_ARROW
		)
		queue_redraw()
		return

	if e is InputEventMouseButton and e.pressed:
		var idx: = _index_at_pos(e.position)
		if idx == -1:
			return


		if idx == INV_BTN_INDEX and e.button_index == MOUSE_BUTTON_LEFT:
			_toggle_inventory()

			queue_redraw()
			return



		if idx < SLOT_COUNT:
			if e.button_index == MOUSE_BUTTON_LEFT:
				_set_selected(idx)
				queue_redraw()
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			var prev: = selected
			_set_selected(idx, false)
			var dropped: = drop_one()
			_set_selected(prev, false)
			if dropped.id != 0:
				_drop_via_server(dropped.id, _local_player(), dropped.meta)
			queue_redraw()

	elif e is InputEventScreenTouch and e.pressed:
		var idx: = _index_at_pos(e.position)
		if idx != -1 and idx < SLOT_COUNT:
			_set_selected(idx)
			queue_redraw()

func _input(e: InputEvent) -> void :

	if _is_command_box_open():
		return

	if e is InputEventKey and e.pressed and not e.echo:
		for i in SLOT_COUNT:
			if e.physical_keycode == KEY_1 + i or e.keycode == KEY_1 + i:
				_set_selected(i)
				queue_redraw()

	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_selected((selected - 1 + SLOT_COUNT) % SLOT_COUNT)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_selected((selected + 1) % SLOT_COUNT)

	if e.is_action_pressed("drop_one"):
		var dropped: = drop_one()
		if dropped.id != 0:
			_drop_via_server(dropped.id, _local_player(), dropped.meta)


func _stack_cap_for(id: int) -> int:

	if ToolDurability.is_tool_id(id):
		return 1
	return int(STACK_CAP_BY_ITEM.get(id, STACK_MAX))


func add_with_meta(item_id: int, amount: int = 1, meta: Dictionary = {}) -> int:
	var left: = amount
	var cap: = _stack_cap_for(item_id)
	var is_meta_bearer: = (cap == 1) or ToolDurability.is_tool_id(item_id)
	var touched_selected: = false


	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == item_id and s.count < cap:
			var take = min(cap - s.count, left)
			s.count += take
			left -= take
			slots[i] = s
			slots[i] = _sanitize_slot(slots[i])
			_ensure_icon_for(item_id)
			_kick_icon_squeeze(i)
			if i == selected:
				touched_selected = true
			if left == 0:
				queue_redraw();_touch_player_save()
				if touched_selected: _ensure_spyglass()
				return 0


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
			_ensure_icon_for(item_id)
			_kick_icon_squeeze(i)
			if i == selected:
				touched_selected = true
			left -= take
			if left == 0:
				queue_redraw();_touch_player_save()
				if touched_selected: _ensure_spyglass()
				return 0

	queue_redraw();_touch_player_save()
	if touched_selected: _ensure_spyglass()
	return left

func try_add(item_id: int, amount: int = 1) -> int:
	var left: = amount
	var cap: = _stack_cap_for(item_id)
	var is_meta_bearer: = (cap == 1) or ToolDurability.is_tool_id(item_id)
	var touched_selected: = false


	if cap > 1:
		for i in SLOT_COUNT:
			var s = slots[i]
			if s.id == item_id and s.count < cap:
				var take = min(cap - s.count, left)
				s.count += take
				left -= take
				slots[i] = _sanitize_slot(s)
				_ensure_icon_for(item_id)
				_kick_icon_squeeze(i)
				if i == selected:
					touched_selected = true
				if left == 0:
					queue_redraw();_touch_player_save()
					if touched_selected: _ensure_spyglass()
					return 0


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
			_ensure_icon_for(item_id)
			_kick_icon_squeeze(i)
			if i == selected:
				touched_selected = true
			left -= take
			if left == 0:
				queue_redraw();_touch_player_save()
				if touched_selected: _ensure_spyglass()
				return 0

	queue_redraw();_touch_player_save()
	if touched_selected: _ensure_spyglass()
	return left


func space_for(item_id: int, amount: int = 1) -> int:
	var left: = amount
	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == item_id and s.count < _stack_cap_for(item_id):
			left -= min(_stack_cap_for(item_id) - s.count, left)
			if left <= 0: return amount
	for i in SLOT_COUNT:
		var s = slots[i]
		if s.id == 0:
			left -= min(_stack_cap_for(item_id), left)
			if left <= 0: return amount
	return amount - left

func drop_one() -> Dictionary:
	var s = slots[selected]
	if s.id == 0 or s.count == 0:
		return {"id": 0, "meta": {}}

	var meta: = (s.get("meta", {}) as Dictionary).duplicate(true)
	var id = s.id

	s.count -= 1
	if s.count == 0:
		s.id = 0
	s = _sanitize_slot(s)
	slots[selected] = s
	queue_redraw()
	_touch_player_save()


	_ensure_spyglass()

	return {"id": id, "meta": meta}

func _unhandled_input(e: InputEvent) -> void :

	if _is_command_box_open():
		return

	if e is InputEventKey and e.pressed and not e.echo:
		for i in SLOT_COUNT:
			if e.keycode == KEY_1 + i:
				selected = i
				_set_selected(i)
				queue_redraw()

func _draw() -> void :

	var total_w: = VISUAL_SLOTS * slot_size.x + (VISUAL_SLOTS - 1) * slot_gap
	var start_x = floor((size.x - total_w) / 2.0)
	var start_y = floor((size.y - slot_size.y) / 2.0)
	var start: = Vector2(start_x, start_y)

	for i in VISUAL_SLOTS:
		var pos: = start + Vector2(i * (slot_size.x + slot_gap), 0)
		var rect: = Rect2(pos, slot_size)

		var is_inv: = (i == INV_BTN_INDEX)
		var is_selected: = (i == selected) and not is_inv

		var fill_col: = (Color(0.15, 0.15, 0.15, 0.9) if is_selected else Color(0, 0, 0, 0.45))
		if is_inv:
			fill_col = Color(0.08, 0.08, 0.08, 0.85)

		draw_rect(rect, fill_col, true)

		var outline_a: = (1.0 if is_selected else 0.55 if is_inv else 0.45)
		var outline_w: = (4.0 if is_selected else 2.0)
		draw_rect(rect, Color(1, 1, 1, outline_a), false, outline_w)

		if is_selected:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color(1, 1, 1, 0.85), true)

		if is_inv:
			_draw_inv_button_dots(rect)
		else:
			var s = slots[i]
			if s.id != 0:
				var key_id: = int(s.id)
				var tex: Texture2D = icon_by_item.get(key_id, null)
				if tex == null:
					_ensure_icon_for(key_id)
					tex = icon_by_item.get(key_id, null)
				var tsize: = Vector2.ZERO
				if tex:
					tsize = tex.get_size()

					var base_sc = min((slot_size.x - 8.0) / tsize.x, (slot_size.y - 8.0) / tsize.y)


					var anim: Vector2 = Vector2.ONE
					if i < _icon_scale.size():
						anim = _icon_scale[i]
					var final_sz: = tsize * Vector2(base_sc, base_sc) * anim


					var draw_pos: = pos + (slot_size - final_sz) * 0.5
					draw_texture_rect(tex, Rect2(draw_pos, final_sz), false)
				else:

					var inner: = Rect2(pos + Vector2(6, 6), slot_size - Vector2(12, 12))
					draw_rect(inner, Color(0.2, 0.2, 0.25, 0.7), true)
					draw_rect(inner, Color(1, 1, 1, 0.35), false, 2.0)

					var font: = count_font if count_font != null else get_theme_default_font()
					var font_size = max(14, count_font_size)
					var id_text: = str(s.id)
					var id_pos: = pos + Vector2(10, slot_size.y - 10)
					draw_string(font, id_pos, id_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.85))


				if s.count > 1:
					var font: = count_font if count_font != null else get_theme_default_font()
					var font_size: = count_font_size
					var text: = str(s.count)

					var pad_x: = 4.0
					var pad_y: = 6.0
					var text_width: = slot_size.x - pad_x * 2.0
					var base_pos: = pos + Vector2(pad_x, slot_size.y - pad_y)

					if count_outline_size > 0:
						draw_string_outline(font, base_pos, text, 
							HORIZONTAL_ALIGNMENT_RIGHT, text_width, font_size, 
							count_outline_size, count_outline_color)

					draw_string(font, base_pos, text, 
						HORIZONTAL_ALIGNMENT_RIGHT, text_width, font_size, 
						Color(1, 1, 1, 0.95))

			if ToolDurability.is_tool_id(int(s.get("id", 0)))\
			and s.has("meta") and typeof(s.meta) == TYPE_DICTIONARY:
				var m = s.meta
				if m.get("used", false) and int(m.get("max", 0)) > 0:
					var dur = clamp(int(m.get("dur", 0)), 0, int(m["max"]))
					var pct: = float(dur) / float(m["max"])
					var recta: = _slot_rect(i)
					var h: = 5.0
					var pad: = 3.0
					var bar: = Rect2(
						recta.position + Vector2(pad, recta.size.y - h - pad), 
						Vector2(recta.size.x - pad * 2.0, h)
					)
					draw_rect(bar, Color(0, 0, 0, 0.35), true)
					var fill: = Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y))
					var col: = _durability_color(pct, 0.95)
					draw_rect(fill, col, true)

func _durability_color(pct: float, alpha: float = 0.95) -> Color:
	pct = clamp(pct, 0.0, 1.0)
	var hue: = pct * 0.33
	return Color.from_hsv(hue, 0.95, 0.95, alpha)


func _sanitize_slot(slot: Dictionary) -> Dictionary:
	var s: = slot.duplicate(true)
	s["id"] = int(s.get("id", 0))
	s["count"] = int(s.get("count", 0))
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

func _draw_inv_button_dots(rect: Rect2) -> void :

	var c: = rect.position + rect.size * 0.5
	var r: = 3.0
	var gap: = 10.0
	var col: = Color(1, 1, 1, 0.85)

	draw_circle(c + Vector2( - gap, 0), r, col)
	draw_circle(c, r, col)
	draw_circle(c + Vector2(gap, 0), r, col)



func register_item_icon(item_id: int, tex: Texture2D) -> void :
	if tex == null:
		return
	if not icon_by_item.has(item_id) or icon_by_item[item_id] == null:
		icon_by_item[item_id] = tex
		queue_redraw()

func _slot_rect(i: int) -> Rect2:
	var total_w: = VISUAL_SLOTS * slot_size.x + (VISUAL_SLOTS - 1) * slot_gap
	var start_x = floor((size.x - total_w) / 2.0)
	var start_y = floor((size.y - slot_size.y) / 2.0)
	var pos: = Vector2(start_x + i * (slot_size.x + slot_gap), start_y)
	return Rect2(pos, slot_size)

func _index_at_pos(local_pos: Vector2) -> int:
	for i in VISUAL_SLOTS:
		if _slot_rect(i).has_point(local_pos):
			return i
	return -1

func get_selected_item_id() -> int:
	var s = slots[selected]
	return s.id

func consume_selected(n: int = 1) -> int:
	var s = slots[selected]
	if s.id == 0 or s.count == 0:
		return 0
	var take = min(n, s.count)
	s.count -= take
	if s.count == 0: s.id = 0
	s = _sanitize_slot(s)
	slots[selected] = s
	queue_redraw()
	_touch_player_save()


	_ensure_spyglass()

	return take


func consume_one_with_meta() -> Dictionary:
	var s = slots[selected]
	if s.id == 0 or s.count == 0:
		return {"id": 0, "meta": {}}
	var meta: = (s.get("meta", {}) as Dictionary).duplicate(true)
	var id: = int(s.id)
	s.count -= 1
	if s.count <= 0:
		s.id = 0
		if s.has("meta"): s.erase("meta")
	s = _sanitize_slot(s)
	slots[selected] = s
	queue_redraw()
	_touch_player_save()


	_ensure_spyglass()

	return {"id": id, "meta": meta}

func add(item_id: int, amount: int = 1) -> int:
	_touch_player_save()
	return try_add(item_id, amount)

func consume_from_index(idx: int, n: int = 1) -> Dictionary:
	if idx < 0 or idx >= SLOT_COUNT: return {"id": 0, "count": 0, "meta": {}}
	var s = slots[idx]
	if int(s.get("id", 0)) == 0 or int(s.get("count", 0)) <= 0:
		return {"id": 0, "count": 0, "meta": {}}
	var id: = int(s.id)
	var take = min(n, int(s.count))
	var meta: = (s.get("meta", {}) as Dictionary).duplicate(true)
	s.count -= take
	if s.count <= 0:
		s = {"id": 0, "count": 0}
	else:
		s = _sanitize_slot(s)
	slots[idx] = s
	queue_redraw()
	_touch_player_save()


	if idx == selected:
		_ensure_spyglass()

	return {"id": id, "count": take, "meta": meta}


func consume_for_place(item_id: int, require_meta: bool = false, expect_meta: Dictionary = {}) -> Dictionary:
	var cap: = _stack_cap_for(item_id)
	var meta_bearer: = (cap == 1) or ToolDurability.is_tool_id(item_id)


	var s = slots[selected]
	if int(s.get("id", 0)) == item_id and int(s.get("count", 0)) > 0:
		var sm: = (s.get("meta", {}) as Dictionary)
		if require_meta or meta_bearer:
			if expect_meta.size() == 0 or sm == expect_meta:
				return consume_from_index(selected, 1)
			else:
				return {"id": 0, "meta": {}, "count": 0}
		else:
			return consume_from_index(selected, 1)


	if require_meta or meta_bearer:
		for i in SLOT_COUNT:
			var it = slots[i]
			if int(it.get("id", 0)) == item_id and int(it.get("count", 0)) > 0:
				if expect_meta.size() == 0 or (it.get("meta", {}) as Dictionary) == expect_meta:
					return consume_from_index(i, 1)
		return {"id": 0, "meta": {}, "count": 0}


	for i in SLOT_COUNT:
		var it = slots[i]
		if int(it.get("id", 0)) == item_id and int(it.get("count", 0)) > 0:
			return consume_from_index(i, 1)
	return {"id": 0, "meta": {}, "count": 0}

func _ensure_spyglass() -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w == null: return


	var spy_id: = 73



	var cur_id: = int(get_selected_item_id())
	var should_be_on: = (cur_id == spy_id)

	if w.has_method("cli_toggle_spyglass"):

		w.call_deferred("cli_toggle_spyglass", should_be_on)

	_notify_held_item_changed()

func consume_selected_exact_id(expected_id: int, n: int = 1) -> Dictionary:
	var idx: = int(selected)
	var s = slots[idx]
	if int(s.get("id", 0)) != expected_id:
		return {"id": 0, "count": 0, "meta": {}}
	return consume_from_index(idx, n)

func consume_item_id(id: int, n: int = 1) -> int:
	var to_consume: = n
	for i in SLOT_COUNT:
		if to_consume <= 0:
			break
		var s = slots[i]
		if s.id == id and s.count > 0:
			var take = min(s.count, to_consume)
			s.count -= take
			to_consume -= take
			if s.count <= 0:
				s.id = 0
			s = _sanitize_slot(s)
			slots[i] = s
	if n != to_consume:
		queue_redraw()
	_touch_player_save()


	_ensure_spyglass()

	return n - to_consume

func _local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p

	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

func _drop_via_server(item_id: int, from_player: Node2D, meta: Dictionary = {}) -> void :
	if from_player == null:
		return


	var dir_x: = 1
	var spr: = from_player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr and spr.flip_h:
		dir_x = -1

	var drop_pos: = from_player.global_position + Vector2(randi_range(120, 150) * dir_x, -10)

	var world: = get_tree().get_first_node_in_group("world")
	if world == null:
		return

	if multiplayer.is_server():
		world.call("srv_request_drop", item_id, 1, drop_pos, meta)
	else:
		world.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_drop", item_id, 1, drop_pos, meta)


func clear_all() -> void :
	for i in SLOT_COUNT:
		slots[i] = {"id": 0, "count": 0}
	selected = clamp(selected, 0, SLOT_COUNT - 1)

	if _select_tween: _select_tween.kill()
	_hint.visible = false
	_hint.modulate.a = 0.0
	queue_redraw()
	var inv: = _inventory_node()
	if inv:
		if inv.has_method("clear_all"):
			inv.call("clear_all")
		elif inv.has_method("clear"):
			inv.call("clear")
	_touch_player_save()

func has_space_for(item_id: int, amount: int = 1) -> bool:
	return space_for(item_id, amount) >= amount

func _inventory_node() -> Node:
	return get_tree().get_first_node_in_group("inventory")

func _toggle_inventory() -> void :
	var inv: = _inventory_node()
	if inv and inv.has_method("toggle_visible"):
		inv.call("toggle_visible")

func _touch_player_save() -> void :
	if GameSession.current_world_id != "":
		PlayerSave.queue_save()

func _ensure_icon_for(id: int) -> void :
	if id == 0: return
	if icon_by_item.has(id) and icon_by_item[id] != null: return
	var w: = get_tree().get_first_node_in_group("world")
	if w == null or not w.has_method("icon_map_for_hotbar"): return
	var m: Dictionary = w.icon_map_for_hotbar()
	if not m.has(id) or m[id] == null: return
	var v = m[id]
	var tex: Texture2D = null
	if v is Texture2D:
		tex = v
	elif typeof(v) == TYPE_STRING and w.has_method("_get_tex_from_path"):
		tex = w._get_tex_from_path(String(v))
	elif v is Dictionary and v.has("src") and v.has("ac") and w.has_method("_texture_from_atlas_cached"):
		tex = w._texture_from_atlas_cached(int(v.src), Vector2i(v.ac), 0)
	if tex != null:
		register_item_icon(id, tex)
