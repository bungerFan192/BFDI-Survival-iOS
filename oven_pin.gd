extends Control
class_name OvenPinOverlay


const PIN_SIZE: = Vector2(28, 28)
const PIN_GAP_Y: = 20.0
const PIN_COLOR: = Color(0.1, 0.1, 0.1, 0.9)
const PIN_OUTLINE: = Color(1, 1, 1, 0.75)


const NEAR_RADIUS_CELLS: = 2
const SRC_ID: = 0
const AC_OVEN: = Vector2i(3, 2)

var _hover: = false
var _nearest_cell: Vector2i
var _has_target: = false

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
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hover = false

func _process(_dt: float) -> void :
	_has_target = false
	var world = get_tree().get_first_node_in_group("world")
	if world == null: return
	var ground = world.get("ground")
	if ground == null: return

	var player: = _get_local_player()
	if player == null: return

	var pc: Vector2i = ground.local_to_map(ground.to_local(player.global_position))

	var best_d: = 999999
	var best: = Vector2i()

	for dx in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
		for dy in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
			var c: = pc + Vector2i(dx, dy)
			if ground.get_cell_source_id(c) != SRC_ID: continue
			if ground.get_cell_atlas_coords(c) != AC_OVEN: continue
			var d = max(abs(dx), abs(dy))
			if d < best_d:
				best_d = d
				best = c

	if best_d <= NEAR_RADIUS_CELLS:
		_has_target = true
		_nearest_cell = best

	queue_redraw()

func _gui_input(e: InputEvent) -> void :
	if not _has_target:
		return

	if e is InputEventMouseMotion:
		_hover = _pin_rect().has_point(e.position)
		mouse_default_cursor_shape = (CURSOR_POINTING_HAND if _hover else CURSOR_ARROW)
		accept_event()
		queue_redraw()

	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _pin_rect().has_point(e.position):
			accept_event()
			if oven_menu == null:
				oven_menu = get_tree().get_first_node_in_group("oven") as OvenMenu
			if oven_menu:

				if not oven_menu.visible:
					oven_menu.toggle_visible()

func _draw() -> void :
	if not _has_target:
		return

	var r: = _pin_rect()


	var head_r = min(r.size.x, r.size.y) * 0.42
	var center: = r.position + r.size * 0.5
	var stem_h = head_r * 0.95
	var stem_w = max(2.0, head_r * 0.28)
	var scale: = (1.1 if _hover else 1.0)
	var head_col: = Color(0.18, 0.18, 0.18, 0.98) if _hover else PIN_COLOR


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

func _pin_rect() -> Rect2:
	var a: = _cell_top_center_screen(_nearest_cell)
	var size: = PIN_SIZE + Vector2(8, 8)
	var pos: = a + Vector2( - size.x * 0.5, - size.y - PIN_GAP_Y)
	return Rect2(pos, size)

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
