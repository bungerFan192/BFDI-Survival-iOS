extends Control
class_name PinsOverlay


const PIN_SIZE: = Vector2(28, 28)
const PIN_GAP_Y: = 20.0
const PIN_OUTLINE: = Color(1, 1, 1, 0.75)

const PIN_CRAFT: = Color(0.12, 0.12, 0.12, 0.95)
const PIN_OVEN: = Color(0.18, 0.18, 0.18, 0.95)
const PIN_BOX: = Color(0.12, 0.17, 0.22, 0.95)
const PIN_HOVER: = Color(0.22, 0.22, 0.22, 0.98)


const NEAR_RADIUS_CELLS: = 2
const SRC_ID: = 0

const AC_CRAFT: = Vector2i(0, 2)
const AC_OVEN: = Vector2i(3, 2)
const AC_YOYLITE_BOX: = Vector2i(7, 2)


var _has_craft: = false
var _craft_cell: = Vector2i()
var _hover_craft: = false

var _has_oven: = false
var _oven_cell: = Vector2i()
var _hover_oven: = false

var _has_box: = false
var _box_cell: = Vector2i()
var _hover_box: = false

@onready var crafting_menu: CraftingMenu = get_tree().get_first_node_in_group("crafting") as CraftingMenu
@onready var oven_menu: OvenMenu = get_tree().get_first_node_in_group("oven") as OvenMenu

func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p

	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

func _ready() -> void :
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_dt: float) -> void :
	var world = get_tree().get_first_node_in_group("world")
	if world == null: return
	var ground = world.get("ground")
	if ground == null: return

	var player: = _get_local_player()
	if player == null: return

	var pc: Vector2i = ground.local_to_map(ground.to_local(player.global_position))

	_has_craft = false
	_has_oven = false
	_has_box = false

	var best_craft_d: = 999999
	var best_craft: = Vector2i()
	var best_oven_d: = 999999
	var best_oven: = Vector2i()
	var best_box_d: = 999999
	var best_box: = Vector2i()

	for dx in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
		for dy in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
			var c: = pc + Vector2i(dx, dy)
			if ground.get_cell_source_id(c) != SRC_ID:
				continue
			var ac = ground.get_cell_atlas_coords(c)
			var dist = max(abs(dx), abs(dy))

			if ac == AC_CRAFT and dist < best_craft_d:
				best_craft_d = dist
				best_craft = c
			elif ac == AC_OVEN and dist < best_oven_d:
				best_oven_d = dist
				best_oven = c
			elif ac == AC_YOYLITE_BOX and dist < best_box_d:
				best_box_d = dist
				best_box = c

	if best_craft_d <= NEAR_RADIUS_CELLS:
		_has_craft = true
		_craft_cell = best_craft
	if best_oven_d <= NEAR_RADIUS_CELLS:
		_has_oven = true
		_oven_cell = best_oven
	if best_box_d <= NEAR_RADIUS_CELLS:
		_has_box = true
		_box_cell = best_box

	queue_redraw()

func _gui_input(e: InputEvent) -> void :
	if e is InputEventMouseMotion:
		var p = e.position
		_hover_craft = _has_craft and _pin_rect(_craft_cell).has_point(p)
		_hover_oven = _has_oven and _pin_rect(_oven_cell).has_point(p)
		_hover_box = _has_box and _pin_rect(_box_cell).has_point(p)

		var any_hover: = _hover_craft or _hover_oven or _hover_box
		mouse_default_cursor_shape = (CURSOR_POINTING_HAND if any_hover else CURSOR_ARROW)
		queue_redraw()
		return

	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p = e.position
		var hit_craft: = _has_craft and _pin_rect(_craft_cell).has_point(p)
		var hit_oven: = _has_oven and _pin_rect(_oven_cell).has_point(p)
		var hit_box: = _has_box and _pin_rect(_box_cell).has_point(p)

		if not hit_craft and not hit_oven and not hit_box:
			return


		var candidates: = []
		if hit_craft: candidates.append({"t": "craft", "cell": _craft_cell})
		if hit_oven: candidates.append({"t": "oven", "cell": _oven_cell})
		if hit_box: candidates.append({"t": "box", "cell": _box_cell})

		var best = candidates[0]
		var best_d = (_pin_center(best.cell) - p).length_squared()
		for i in range(1, candidates.size()):
			var d = (_pin_center(candidates[i].cell) - p).length_squared()
			if d < best_d:
				best = candidates[i]
				best_d = d

		accept_event()
		match best.t:
			"craft":
				if crafting_menu == null:
					crafting_menu = get_tree().get_first_node_in_group("crafting") as CraftingMenu
				if crafting_menu and not crafting_menu.visible:
					crafting_menu.toggle_visible()
			"oven":
				if oven_menu == null:
					oven_menu = get_tree().get_first_node_in_group("oven") as OvenMenu
				if oven_menu and not oven_menu.visible:
					oven_menu.toggle_visible()

			"box":
				var world = get_tree().get_first_node_in_group("world")
				if world:
					if multiplayer.is_server() or multiplayer.multiplayer_peer == null:

						world.srv_request_open_box(best.cell)
					else:

						world.rpc_id(1, "srv_request_open_box", best.cell)

func _draw() -> void :
	if _has_craft:
		_draw_pin(_pin_rect(_craft_cell), _hover_craft, true)
	if _has_oven:
		_draw_pin(_pin_rect(_oven_cell), _hover_oven, false)
	if _has_box:
		_draw_pin_box(_pin_rect(_box_cell), _hover_box)



func _draw_pin_box(r: Rect2, hovered: bool) -> void :

	var center: = r.position + r.size * 0.5
	var head_r = min(r.size.x, r.size.y) * 0.42
	var stem_h = head_r * 0.95
	var stem_w = max(2.0, head_r * 0.28)
	var scale: = (1.1 if hovered else 1.0)

	var base_col: = PIN_BOX
	var head_col: = (PIN_HOVER if hovered else base_col)

	draw_circle(center + Vector2(0, 2), head_r * scale * 1.02, Color(0, 0, 0, 0.35))
	var stem_top: = center + Vector2( - stem_w * 0.5, head_r * 0.35)
	var stem_rect: = Rect2(stem_top, Vector2(stem_w, stem_h) * scale)
	draw_rect(stem_rect, head_col, true)
	draw_rect(stem_rect, PIN_OUTLINE, false, 1.5)
	draw_circle(center, head_r * scale, head_col)
	draw_arc(center, head_r * scale, 0, TAU, 64, PIN_OUTLINE, 2.0)
	var tip_w = max(6.0, head_r * 0.9) * scale
	var tip_h = max(6.0, head_r * 0.9) * scale
	var tip_a: = center + Vector2(0, head_r * 0.35 + stem_h * scale + 1.0)
	var p1: = tip_a + Vector2(0, tip_h)
	var p2: = tip_a + Vector2( - tip_w * 0.5, 0)
	var p3: = tip_a + Vector2(tip_w * 0.5, 0)
	draw_colored_polygon([p1, p2, p3], head_col)
	draw_polyline([p1, p2, p3, p1], PIN_OUTLINE, 1.5)


func _draw_pin(r: Rect2, hovered: bool, is_craft: bool) -> void :
	var center: = r.position + r.size * 0.5
	var head_r = min(r.size.x, r.size.y) * 0.42
	var stem_h = head_r * 0.95
	var stem_w = max(2.0, head_r * 0.28)
	var scale: = (1.1 if hovered else 1.0)

	var base_col: = (PIN_CRAFT if is_craft else PIN_OVEN)
	var head_col: = (PIN_HOVER if hovered else base_col)


	draw_circle(center + Vector2(0, 2), head_r * scale * 1.02, Color(0, 0, 0, 0.35))


	var stem_top: = center + Vector2( - stem_w * 0.5, head_r * 0.35)
	var stem_rect: = Rect2(stem_top, Vector2(stem_w, stem_h) * scale)
	draw_rect(stem_rect, head_col, true)
	draw_rect(stem_rect, PIN_OUTLINE, false, 1.5)


	draw_circle(center, head_r * scale, head_col)
	draw_arc(center, head_r * scale, 0, TAU, 64, PIN_OUTLINE, 2.0)


	var tip_w = max(6.0, head_r * 0.9) * scale
	var tip_h = max(6.0, head_r * 0.9) * scale
	var tip_a: = center + Vector2(0, head_r * 0.35 + stem_h * scale + 1.0)
	var p1: = tip_a + Vector2(0, tip_h)
	var p2: = tip_a + Vector2( - tip_w * 0.5, 0)
	var p3: = tip_a + Vector2(tip_w * 0.5, 0)
	draw_colored_polygon([p1, p2, p3], head_col)
	draw_polyline([p1, p2, p3, p1], PIN_OUTLINE, 1.5)

func _pin_rect(cell: Vector2i) -> Rect2:
	var a: = _cell_top_center_screen(cell)
	var size: = PIN_SIZE + Vector2(8, 8)
	var pos: = a + Vector2( - size.x * 0.5, - size.y - PIN_GAP_Y)
	return Rect2(pos, size)

func _pin_center(cell: Vector2i) -> Vector2:
	return _pin_rect(cell).position + _pin_rect(cell).size * 0.5


func _cell_top_center_screen(cell: Vector2i) -> Vector2:
	var world = get_tree().get_first_node_in_group("world")
	if world == null:
		return Vector2.ZERO
	var ground = world.get("ground")
	if ground == null:
		return Vector2.ZERO

	var cell_center_w = ground.to_global(ground.map_to_local(cell))
	var right_w = ground.to_global(ground.map_to_local(cell + Vector2i(1, 0)))
	var down_w = ground.to_global(ground.map_to_local(cell + Vector2i(0, 1)))
	var size = Vector2(abs(right_w.x - cell_center_w.x), abs(down_w.y - cell_center_w.y))
	var top_center_w = cell_center_w + Vector2(0, - size.y * 0.5)

	var xform: Transform2D = get_viewport().get_canvas_transform()
	return xform * top_center_w
