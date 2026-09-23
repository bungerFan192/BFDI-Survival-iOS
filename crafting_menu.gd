extends Control
class_name CraftingMenu


const PANEL_PAD: = Vector2(12, 12)
const BTN_SIZE: = Vector2(270, 60)
const BTN_GAP_Y: = 10.0
const PANEL_W: = 320.0


@export var bg_color: Color = Color(0, 0, 0, 0.65)
@export var panel_outline: Color = Color(1, 1, 1, 0.25)
@export var slot_outline: Color = Color(1, 1, 1, 0.45)
const COUNT_FONT = preload("res://Shag-Lounge.otf")


const NEAR_RADIUS_CELLS: = 2
const CRAFT_SRC: = 0
const CRAFT_AC: = Vector2i(0, 2)

const CLOSE_SIZE: = Vector2(28, 28)
const CLOSE_GAP: = Vector2(10, 0)

const RECIPES_PER_PAGE: = 6
const NAV_H: = 36
const NAV_BTN_SIZE: = Vector2(84, 28)
const NAV_GAP: = 10.0

var _page: = 0


var _hover_idx: = -1
var _warm_icon_done: = false


var RECIPES: = []


@onready var hotbar: Hotbar = get_tree().get_first_node_in_group("hotbar") as Hotbar
@onready var inventory = get_tree().get_first_node_in_group("inventory")
@onready var world = get_tree().get_first_node_in_group("world")




const VARIANT_PREFIXES: = [
	"dark ", "yoyle ", "bush ", 
	"oak ", "birch ", "spruce ", "jungle ", 
	"acacia ", "mangrove ", "cherry ", "crimson ", "warped "
]


const IRREG_PLURALS: = {
	"leaf": "leaves", 
	"berry": "berries"
}

func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p

	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

func _strip_variant_prefixes(s: String) -> String:
	var lower: = s.strip_edges().to_lower()
	for p in VARIANT_PREFIXES:
		if lower.begins_with(p):
			return lower.substr(p.length())
	return lower

func _pluralize_base(word: String, count: int) -> String:
	if count == 1:
		return word
	if IRREG_PLURALS.has(word):
		return String(IRREG_PLURALS[word])

	return word + "s"

func _base_name_for_id(id: int) -> String:

	var raw: = _item_name(id, 1)
	return _strip_variant_prefixes(raw)

func _all_same_base_name(ids: Array) -> Dictionary:

	var seen: = {}
	for _id in ids:
		var id: = int(_id)
		var base: = _base_name_for_id(id)
		seen[base] = true
	if seen.size() == 1:
		for k in seen.keys():
			return {"same": true, "base": String(k)}
	return {"same": false, "base": ""}

func _count_total_any_of(ids: Array) -> int:
	var tot: = 0
	for id in ids:
		tot += _count_total(int(id))
	return tot

func _find_consumed_rec(consumed: Array, id: int) -> int:
	for i in consumed.size():
		if int(consumed[i]["id"]) == id:
			return i
	return -1

func _record_consumption(consumed: Array, id: int, took_inv: int, took_hb: int) -> void :
	var idx: = _find_consumed_rec(consumed, id)
	if idx == -1:
		consumed.append({"id": id, "inv": took_inv, "hb": took_hb})
	else:
		consumed[idx]["inv"] = int(consumed[idx]["inv"]) + took_inv
		consumed[idx]["hb"] = int(consumed[idx]["hb"]) + took_hb

func _take_from_sources(item_id: int, need: int) -> Dictionary:
	var took_inv: = 0
	var took_hb: = 0
	if need > 0 and inventory and inventory.has_method("take_item"):
		took_inv = int(inventory.take_item(item_id, need))
		need -= took_inv
	if need > 0 and hotbar and hotbar.has_method("consume_item_id"):
		took_hb = int(hotbar.consume_item_id(item_id, need))
		need -= took_hb
	return {"id": item_id, "inv": took_inv, "hb": took_hb, "left": need}

func _take_any_of(ids: Array, need: int) -> Array:

	var consumed: = []
	var left: = need


	for id in ids:
		if left <= 0: break
		var r: = _take_from_sources(int(id), left)

		if int(r.inv) > 0:
			_record_consumption(consumed, int(id), int(r.inv), 0)
			left -= int(r.inv)

		if int(r.hb) > 0:
			_record_consumption(consumed, int(id), 0, int(r.hb))
			left -= int(r.hb)


	if left > 0:
		for id in ids:
			if left <= 0: break
			var took_hb: = 0
			if hotbar and hotbar.has_method("consume_item_id"):
				took_hb = int(hotbar.consume_item_id(int(id), left))
			if took_hb > 0:
				_record_consumption(consumed, int(id), 0, took_hb)
				left -= took_hb

	return consumed

func _sum_consumed(consumed_list: Array) -> int:
	var s: = 0
	for rec in consumed_list:
		s += int(rec.inv) + int(rec.hb)
	return s

func _page_count() -> int:
	return (RECIPES.size() + RECIPES_PER_PAGE - 1) / RECIPES_PER_PAGE if RECIPES.size() > 0 else 1

func _clamp_page() -> void :
	_page = clamp(_page, 0, max(0, _page_count() - 1))

func _page_first_index() -> int:
	return _page * RECIPES_PER_PAGE

func _visible_count() -> int:
	return min(RECIPES_PER_PAGE, max(0, RECIPES.size() - _page_first_index()))

func _ready() -> void :
	add_to_group("crafting")
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	if not InputMap.has_action("toggle_crafting"):
		InputMap.add_action("toggle_crafting")
		var ev: = InputEventKey.new()
		ev.physical_keycode = KEY_C
		InputMap.action_add_event("toggle_crafting", ev)
	visible = false
	call_deferred("_ensure_recipes_built")
	queue_redraw()

func _process(_dt: float) -> void :

	if visible and not _is_near_crafting_table():
		toggle_visible()

	_ensure_recipes_built()

func _ensure_recipes_built() -> void :
	if RECIPES.is_empty():
		if world == null:
			world = get_tree().get_first_node_in_group("world")
		if world != null:
			RECIPES = _build_recipes_from_world()
			_warm_icons()
			queue_redraw()



func _is_valid_ac(ac: Vector2i) -> bool:
	return ac.x >= 0 and ac.y >= 0

func _tex_from_path_safe(p: Variant) -> Texture2D:
	if typeof(p) == TYPE_STRING and String(p) != "":
		var w = get_tree().get_first_node_in_group("world")
		if w and w.has_method("_get_tex_from_path"):
			return w._get_tex_from_path(String(p))
	return null

func _build_recipes_from_world() -> Array:
	if world == null:
		return []
	return [
		{
			"id_out": world.ITEM_CRAFT, 
			"label": "Crafting Table", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 10}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_CRAFT, 
			"tile_ac": world.T_CRAFT
		}, 
		{
			"id_out": world.ITEM_OVEN, 
			"label": "Oven", 
			"cost": [{"id": world.ITEM_STONE, "count": 25}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_OVEN, 
			"tile_ac": world.T_OVEN
		}, 
		{
			"id_out": world.ITEM_STICK, 
			"label": "Stick", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 1}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_STICK
		}, 
		{
			"id_out": world.ITEM_WOODEN_AXE, 
			"label": "Wooden Axe", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 10}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 3}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_WOODEN_AXE
		}, 
		{
			"id_out": world.ITEM_WOODEN_PICKAXE, 
			"label": "Wooden Pickaxe", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 14}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_WOODEN_PICKAXE
		}, 
		{
			"id_out": world.ITEM_WOODEN_SHOVEL, 
			"label": "Wooden Shovel", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 16}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 3}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_WOODEN_SHOVEL
		}, 
		{
			"id_out": world.ITEM_WOODEN_SWORD, 
			"label": "Wooden Sword", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 20}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 8}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_WOODEN_SWORD
		}, 
		{
			"id_out": world.ITEM_STONE_AXE, 
			"label": "Stone Axe", 
			"cost": [{"id": world.ITEM_STONE, "count": 10}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_STONE_AXE
		}, 
		{
			"id_out": world.ITEM_STONE_PICKAXE, 
			"label": "Stone Pickaxe", 
			"cost": [{"id": world.ITEM_STONE, "count": 14}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_STONE_PICKAXE
		}, 
		{
			"id_out": world.ITEM_STONE_SHOVEL, 
			"label": "Stone Shovel", 
			"cost": [{"id": world.ITEM_STONE, "count": 16}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 7}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_STONE_SHOVEL
		}, 
		{
			"id_out": world.ITEM_STONE_SWORD, 
			"label": "Stone Sword", 
			"cost": [{"id": world.ITEM_STONE, "count": 20}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 8}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_STONE_SWORD
		}, 
		{
			"id_out": world.ITEM_IRON_AXE, 
			"label": "Iron Axe", 
			"cost": [{"id": world.ITEM_IRON, "count": 10}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_IRON_AXE
		}, 
		{
			"id_out": world.ITEM_IRON_PICKAXE, 
			"label": "Iron Pickaxe", 
			"cost": [{"id": world.ITEM_IRON, "count": 14}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_IRON_PICKAXE
		}, 
		{
			"id_out": world.ITEM_IRON_SHOVEL, 
			"label": "Iron Shovel", 
			"cost": [{"id": world.ITEM_IRON, "count": 16}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 7}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_IRON_SHOVEL
		}, 
		{
			"id_out": world.ITEM_IRON_SWORD, 
			"label": "Iron Sword", 
			"cost": [{"id": world.ITEM_IRON, "count": 20}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 8}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_IRON_SWORD
		}, 
		{
			"id_out": world.ITEM_YOYLITE_AXE, 
			"label": "Yoylite Axe", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 10}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_YOYLITE_AXE
		}, 
		{
			"id_out": world.ITEM_YOYLITE_PICKAXE, 
			"label": "Yoylite Pickaxe", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 14}, {"id": world.ITEM_STICK, "count": 10}, {"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_YOYLITE_PICKAXE
		}, 
		{
			"id_out": world.ITEM_YOYLITE_SHOVEL, 
			"label": "Yoylite Shovel", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 16}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 7}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_YOYLITE_SHOVEL
		}, 
		{
			"id_out": world.ITEM_YOYLITE_SWORD, 
			"label": "Yoylite Sword", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 20}, {"id": world.ITEM_STICK, "count": 6}, {"id": world.ITEM_STRING, "count": 8}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_YOYLITE_SWORD
		}, 
		{
			"id_out": world.ITEM_YOYLE_CRYSTAL, 
			"label": "Yoyle Crystal", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 1}, {"id": world.ITEM_STONE, "count": 4}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLE_CRYSTAL, 
			"tile_ac": world.T_YOYLE_CRYSTAL
		}, 
		{
			"id_out": world.ITEM_YOYLITE_ANCHOR_0, 
			"label": "Yoylite Anchor", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 2}, {"id": world.ITEM_STONE, "count": 4}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLITE_ANCHOR_0, 
			"tile_ac": world.T_YOYLITE_ANCHOR_0
		}, 
		{
			"id_out": world.ITEM_YOYLITE_BOX, 
			"label": "Yoylite Box", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 1}, {"id": world.ITEM_STONE, "count": 8}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLITE_BOX, 
			"tile_ac": world.T_YOYLITE_BOX
		}, 
		{
			"id_out": world.ITEM_YOYLITE_PEARL, 
			"label": "Yoylite Pearl", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 1}, {"id": world.ITEM_IRON, "count": 4}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_YOYLITE_PEARL
		}, 
		{
			"id_out": world.ITEM_YOYLITE_WIRE, 
			"label": "Yoylite Wire", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 1}, {"id": world.ITEM_STONE, "count": 1}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLITE_WIRE_OFF, 
			"tile_ac": world.T_YOYLITE_WIRE_OFF
		}, 
		{
			"id_out": world.ITEM_YOYLITE_DELAYER, 
			"label": "Yoylite Delayer", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 2}, {"id": world.ITEM_STONE, "count": 1}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLITE_DELAYER_1_OFF, 
			"tile_ac": world.T_YOYLITE_DELAYER_1_OFF
		}, 
		{
			"id_out": world.ITEM_YOYLITE_EMITTER, 
			"label": "Yoylite Emitter", 
			"cost": [{"id": world.ITEM_YOYLITE, "count": 3}, {"id": world.ITEM_STONE, "count": 1}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_YOYLITE_EMITTER_ON, 
			"tile_ac": world.T_YOYLITE_EMITTER_ON
		}, 
		{
			"id_out": world.ITEM_PISTON, 
			"label": "Piston", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 5}, {"id": world.ITEM_STONE, "count": 10}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_PISTON_RIGHT, 
			"tile_ac": world.T_PISTON_RIGHT
		}, 
		{
			"id_out": world.ITEM_STRINGY_PISTON, 
			"label": "Stringy Piston", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 5}, {"id": world.ITEM_STRING, "count": 2}, {"id": world.ITEM_STONE, "count": 10}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_STRINGY_PISTON_RIGHT, 
			"tile_ac": world.T_STRINGY_PISTON_RIGHT
		}, 
		{
			"id_out": world.ITEM_LEVER, 
			"label": "Lever", 
			"cost": [{"any_of": [world.ITEM_LOG, world.ITEM_DARK_LOG, world.ITEM_YOYLE_LOG, world.ITEM_BUSH_LOG], "count": 3}, {"id": world.ITEM_STONE, "count": 10}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_LEVER_OFF, 
			"tile_ac": world.T_LEVER_OFF
		}, 
		{
			"id_out": world.ITEM_STRING_BLOCK, 
			"label": "String Block", 
			"cost": [{"id": world.ITEM_STRING, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_STRING_BLOCK, 
			"tile_ac": world.T_STRING_BLOCK
		}, 
		{
			"id_out": world.ITEM_LIGHTER, 
			"label": "Lighter", 
			"cost": [{"id": world.ITEM_IRON, "count": 5}, {"id": world.ITEM_COAL, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_LIGHTER
		}, 
		{
			"id_out": world.ITEM_DYNAMITE, 
			"label": "Dynamite", 
			"cost": [{"id": world.ITEM_SAND, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": world.T_DYNAMITE, 
			"tile_ac": world.T_DYNAMITE
		}, 
		{
			"id_out": world.ITEM_AOU, 
			"label": "Announcer of Undying", 
			"cost": [{"id": world.ITEM_GOLD, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_AOU
		}, 
		{
			"id_out": world.ITEM_SPYGLASS, 
			"label": "Spyglass", 
			"cost": [{"id": world.ITEM_GOLD, "count": 5}, {"id": world.ITEM_IRON, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_SPYGLASS
		}, 
		{
			"id_out": world.ITEM_GOLDEN_CAKE, 
			"label": "Golden Cake Slice", 
			"cost": [{"id": world.ITEM_CAKE, "count": 1}, {"id": world.ITEM_GOLD, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_GOLDEN_CAKE
		}, 
		{
			"id_out": world.ITEM_GOLDENBERRY, 
			"label": "Golden Berry", 
			"cost": [{"id": world.ITEM_YOYLEBERRY, "count": 1}, {"id": world.ITEM_GOLD, "count": 5}], 
			"atlas_src": world.SRC, 
			"atlas_ac": Vector2i(-1, -1), 
			"tile_ac": Vector2i(-1, -1), 
			"icon_path": world.PATH_GOLDENBERRY
		}, 
	]
	_clamp_page()

func _cost_string(cost: Array) -> String:
	var parts: Array[String] = []
	for entry in cost:
		var cnt: = int(entry["count"])
		if entry.has("any_of"):
			var ids: Array = entry["any_of"]

			var chk: = _all_same_base_name(ids)
			if bool(chk.same):
				var base: = String(chk.base)
				var label: = _pluralize_base(base, cnt)
				parts.append("%d %s of any variant" % [cnt, label])
			else:

				var names: Array[String] = []
				for id in ids:
					names.append(_item_name(int(id), cnt))
				parts.append("%d %s" % [cnt, " or ".join(names)])
		else:
			var id: = int(entry["id"])
			parts.append("%d %s" % [cnt, _item_name(id, cnt)])
	return ", ".join(parts)

func _item_name(id: int, count: int) -> String:
	if world == null:
		return "item"
	if id == world.ITEM_LOG:
		if count == 1: return "log"
		else: return "logs"
	elif id == world.ITEM_GRASS:
		return "grass"
	elif id == world.ITEM_STONE:
		if count == 1: return "stone"
		else: return "stones"
	elif id == world.ITEM_DIRT:
		return "dirt"
	elif id == world.ITEM_LEAVES:
		if count == 1: return "leaf"
		else: return "leaves"
	elif id == world.ITEM_CRAFT:
		if count == 1: return "table"
		else: return "tables"
	elif id == world.ITEM_CAKE:
		if count == 1: return "cake"
		else: return "cakes"
	elif id == world.ITEM_STICK:
		if count == 1: return "stick"
		else: return "sticks"
	elif id == world.ITEM_STRING:
		if count == 1: return "string"
		else: return "strings"
	elif id == world.ITEM_IRON:
		if count == 1: return "iron"
		else: return "irons"
	elif id == world.ITEM_DARK_LOG:
		if count == 1: return "dark log"
		else: return "dark logs"
	elif id == world.ITEM_YOYLE_LOG:
		if count == 1: return "yoyle log"
		else: return "yoyle logs"
	elif id == world.ITEM_BUSH_LOG:
		if count == 1: return "bush log"
		else: return "bush logs"
	elif id == world.ITEM_SAND:
		if count == 1: return "sand"
		else: return "sands"
	elif id == world.ITEM_COAL:
		if count == 1: return "coal"
		else: return "coals"
	elif id == world.ITEM_GOLD:
		if count == 1: return "gold"
		else: return "golds"
	elif id == world.ITEM_YOYLEBERRY:
		if count == 1: return "yoyle berry"
		else: return "yoyle berries"
	elif id == world.ITEM_YOYLITE:
		if count == 1: return "yoylite"
		else: return "yoylites"
	return "item"


func _panel_rect() -> Rect2:
	var n: = _visible_count()

	var rows_h = max(1, n) * BTN_SIZE.y + max(0, n - 1) * BTN_GAP_Y
	var content_h = rows_h + NAV_H
	var panel_h = content_h + PANEL_PAD.y * 2.0
	var panel_w = max(PANEL_W, BTN_SIZE.x + PANEL_PAD.x * 2.0)
	var pos: = Vector2(
		floor((size.x - panel_w) * 0.5), 
		floor((size.y - panel_h) * 0.5)
	)
	return Rect2(pos, Vector2(panel_w, panel_h))

func _button_rect_local(li: int) -> Rect2:

	var pr: = _panel_rect()
	var start: = pr.position + PANEL_PAD
	var btn_pos: = start + Vector2(0, li * (BTN_SIZE.y + BTN_GAP_Y))
	btn_pos.x = pr.position.x + (pr.size.x - BTN_SIZE.x) * 0.5
	return Rect2(btn_pos, BTN_SIZE)

func _nav_bar_rect() -> Rect2:
	var pr: = _panel_rect()
	var y: = pr.position.y + pr.size.y - PANEL_PAD.y - NAV_H
	return Rect2(Vector2(pr.position.x + PANEL_PAD.x, y), Vector2(pr.size.x - PANEL_PAD.x * 2.0, NAV_H))

func _prev_button_rect() -> Rect2:
	var nb: = _nav_bar_rect()
	var pos: = Vector2(nb.position.x, nb.position.y + (nb.size.y - NAV_BTN_SIZE.y) * 0.5)
	return Rect2(pos, NAV_BTN_SIZE)

func _next_button_rect() -> Rect2:
	var nb: = _nav_bar_rect()
	var pos: = Vector2(nb.position.x + nb.size.x - NAV_BTN_SIZE.x, nb.position.y + (nb.size.y - NAV_BTN_SIZE.y) * 0.5)
	return Rect2(pos, NAV_BTN_SIZE)


func _close_button_rect() -> Rect2:
	var pr: = _panel_rect()

	var pos: = pr.position + Vector2(pr.size.x + CLOSE_GAP.x, - CLOSE_SIZE.y * 0.5 + CLOSE_GAP.y)
	return Rect2(pos, CLOSE_SIZE)



func toggle_visible() -> void :
	var want_open: = not visible


	if want_open:
		var inv: = get_tree().get_first_node_in_group("inventory")
		if inv and inv.visible:
			inv.toggle_visible()

		var oven: = get_tree().get_first_node_in_group("oven")
		if oven and oven.visible:
			oven.toggle_visible()

		var wheel_menu: = get_tree().get_first_node_in_group("wheel_menu")
		if want_open and wheel_menu and wheel_menu.visible:
			wheel_menu.toggle_visible()


		var box: = get_tree().get_first_node_in_group("yoylite_box_menu")
		if want_open and box and box.visible and box.has_method("_commit_and_close"):
			box._commit_and_close()

	visible = want_open
	if visible:
		grab_focus()
	_update_player_input_gate()
	queue_redraw()


func is_open() -> bool: return visible

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

	if e.is_action_pressed("toggle_crafting"):
		if visible:

			toggle_visible()
		else:

			if _is_near_crafting_table():
				toggle_visible()

	if not visible: return

	if e.is_action_pressed("ui_cancel"):
		toggle_visible()

func _gui_input(e: InputEvent) -> void :
	if not visible: return
	if e is InputEventMouse:
		accept_event()

	if e is InputEventMouseMotion:
		_hover_idx = _button_index_at(e.position)
		var over_close: = _close_button_rect().has_point(e.position)
		var over_prev: = _over_prev(e.position)
		var over_next: = _over_next(e.position)
		mouse_default_cursor_shape = (CURSOR_POINTING_HAND if over_close or over_prev or over_next or _hover_idx != -1 else CURSOR_ARROW)
		queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _close_button_rect().has_point(e.position):
			toggle_visible();return

		if _over_prev(e.position) and _page > 0:
			_page -= 1
			queue_redraw()
			return

		if _over_next(e.position) and _page < _page_count() - 1:
			_page += 1
			queue_redraw()
			return

		var idx: = _button_index_at(e.position)
		if idx != -1:
			_on_recipe_pressed(idx)
			queue_redraw()




func _on_recipe_pressed(i: int) -> void :
	if i < 0 or i >= RECIPES.size(): return
	_attempt_craft(RECIPES[i])

func _attempt_craft(r: Dictionary) -> void :

	for c in r["cost"]:
		if c.has("any_of"):
			if _count_total_any_of(c["any_of"]) < int(c["count"]):
				return
		else:
			if _count_total(int(c["id"])) < int(c["count"]):
				return


	if r.has("icon"):
		_ensure_icon_registered_tex(int(r["id_out"]), r["icon"])
	else:
		_ensure_icon_registered(int(r["id_out"]), int(r["atlas_src"]), Vector2i(r["atlas_ac"]))


	var consumed: Array = []
	for c in r["cost"]:
		if c.has("any_of"):
			var took: = _take_any_of(c["any_of"], int(c["count"]))
			if _sum_consumed(took) < int(c["count"]):
				consumed.append_array(took)
				_refund(consumed)
				return
			consumed.append_array(took)
		else:
			var item_id: = int(c["id"])
			var need: = int(c["count"])
			var r1: = _take_from_sources(item_id, need)
			consumed.append({"id": item_id, "inv": int(r1.inv), "hb": int(r1.hb)})
			if int(r1.left) > 0:
				_refund(consumed);return


	var leftover: = _give_like_pickup(int(r["id_out"]), 1)
	if leftover > 0:
		_refund(consumed)



func _refund(consumed: Array) -> void :
	for rec in consumed:
		var id: = int(rec["id"])
		var inv: = int(rec["inv"])
		var hb: = int(rec["hb"])
		if hb > 0 and hotbar and hotbar.has_method("try_add"):
			hotbar.try_add(id, hb)
		if inv > 0 and inventory and inventory.has_method("try_add"):
			inventory.try_add(id, inv)
	if hotbar: hotbar.queue_redraw()
	if inventory: inventory.queue_redraw()


func _client_can_take_like_pickup(id: int, amount: int) -> bool:
	var need: = amount
	if inventory and inventory.has_method("space_for"):
		need -= int(inventory.space_for(id, need))
	if hotbar and hotbar.has_method("space_for") and need > 0:
		need -= int(hotbar.space_for(id, need))
	return need <= 0

func _give_like_pickup(id: int, amount: int) -> int:
	var left: = amount
	if hotbar and hotbar.has_method("try_add"):
		left = int(hotbar.try_add(id, left))
	if left > 0 and inventory and inventory.has_method("try_add"):
		left = int(inventory.try_add(id, left))
	if hotbar: hotbar.queue_redraw()
	if inventory: inventory.queue_redraw()
	return left



func _count_total(item_id: int) -> int:
	var tot: = 0
	if inventory:
		if inventory.has_method("_count_in_inventory"):
			tot += int(inventory._count_in_inventory(item_id))
		else:
			for i in inventory.SLOT_COUNT:
				var s = inventory.slots[i]
				if int(s.id) == item_id:
					tot += int(s.count)
	if hotbar:
		for i in hotbar.SLOT_COUNT:
			var s = hotbar.slots[i]
			if int(s.id) == item_id:
				tot += int(s.count)
	return tot


func _is_near_crafting_table() -> bool:
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return false
	var ground = world.get("ground")
	if ground == null: return false

	var player: = _get_local_player()
	if player == null: return false

	var pc: Vector2i = ground.local_to_map(ground.to_local(player.global_position))

	for dx in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
		for dy in range( - NEAR_RADIUS_CELLS, NEAR_RADIUS_CELLS + 1):
			var c: = pc + Vector2i(dx, dy)
			if ground.get_cell_source_id(c) != CRAFT_SRC:
				continue
			if ground.get_cell_atlas_coords(c) == CRAFT_AC:
				return true
	return false

func _button_rect(i: int) -> Rect2:
	var pr: = _panel_rect()
	var start: = pr.position + PANEL_PAD
	var btn_pos: = start + Vector2(0, i * (BTN_SIZE.y + BTN_GAP_Y))
	btn_pos.x = pr.position.x + (pr.size.x - BTN_SIZE.x) * 0.5
	return Rect2(btn_pos, BTN_SIZE)

func _button_index_at(p: Vector2) -> int:
	var first: = _page_first_index()
	var vis: = _visible_count()
	for li in vis:
		if _button_rect_local(li).has_point(p):
			return first + li
	return -1

func _over_prev(p: Vector2) -> bool: return _prev_button_rect().has_point(p)
func _over_next(p: Vector2) -> bool: return _next_button_rect().has_point(p)



func _draw() -> void :
	if not visible: return
	if not _warm_icon_done: _warm_icons()

	var pr: = _panel_rect()
	draw_rect(pr, bg_color, true)
	draw_rect(pr, panel_outline, false, 2.0)

	var first: = _page_first_index()
	var vis: = _visible_count()

	for li in vis:
		var ri: = first + li
		var r: Dictionary = RECIPES[ri]

		var can_craft: = true
		for c in r["cost"]:
			var need: = int(c["count"])
			var have: = 0
			if c.has("any_of"):
				have = _count_total_any_of(c["any_of"])
			else:
				have = _count_total(int(c["id"]))
			if have < need:
				can_craft = false
				break

		var br: = _button_rect_local(li)
		var fill: = Color(0.12, 0.12, 0.12, (0.95 if can_craft else 0.45))
		if _hover_idx == ri and can_craft:
			fill = Color(0.18, 0.18, 0.18, 0.98)
		draw_rect(br, fill, true)
		draw_rect(br, slot_outline, false, 2.0)


		var icon: Texture2D = null
		if r.has("icon"):
			icon = r["icon"]
		elif r.has("__icon"):
			icon = r["__icon"]
		elif r.has("icon_path"):
			icon = _tex_from_path_safe(r["icon_path"])
		else:
			icon = _icon_for(int(r["id_out"]))
		var text_x: = 10.0
		if icon:
			var tsize: = icon.get_size()
			var sc = min((br.size.y - 10.0) / tsize.y, 1.0)
			var isz = tsize * sc
			var ipos: = br.position + Vector2(6, (br.size.y - isz.y) * 0.5)
			draw_texture_rect(icon, Rect2(ipos, isz), false)
			text_x = isz.x + 14.0


		var label: = "%s  (%s)" % [String(r["label"]), _cost_string(r["cost"])]
		var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
		var color: = Color(1, 1, 1, (0.95 if can_craft else 0.6))


		var text_rect: = Rect2(
			br.position + Vector2(text_x, 0), 
			Vector2(br.size.x - text_x - 10.0, br.size.y)
		)
		_draw_label_fit(font, text_rect, label, 16, color)


	var cr: = _close_button_rect()
	var inside: = cr.has_point(get_local_mouse_position())
	var fill: = Color(0.12, 0.12, 0.12, 0.95 if not inside else 0.98)
	draw_rect(cr, fill, true)
	draw_rect(cr, Color(1, 1, 1, 0.75), false, 2.0)

	var cx: = cr.position + cr.size * 0.5
	draw_line(cx + Vector2(-6, -6), cx + Vector2(6, 6), Color(1, 1, 1, 0.95), 2.0)
	draw_line(cx + Vector2(6, -6), cx + Vector2(-6, 6), Color(1, 1, 1, 0.95), 2.0)

	var prev_r: = _prev_button_rect()
	var next_r: = _next_button_rect()
	var over_prev: = prev_r.has_point(get_local_mouse_position())
	var over_next: = next_r.has_point(get_local_mouse_position())

	var prev_enabled: = (_page > 0)
	var next_enabled: = (_page < _page_count() - 1)


	var prev_fill: = Color(0.12, 0.12, 0.12, 0.95 if prev_enabled else 0.45)
	if prev_enabled and over_prev: prev_fill = Color(0.18, 0.18, 0.18, 0.98)
	draw_rect(prev_r, prev_fill, true)
	draw_rect(prev_r, slot_outline, false, 2.0)
	_draw_centered_text(prev_r, "<< Prev", prev_enabled)


	var next_fill: = Color(0.12, 0.12, 0.12, 0.95 if next_enabled else 0.45)
	if next_enabled and over_next: next_fill = Color(0.18, 0.18, 0.18, 0.98)
	draw_rect(next_r, next_fill, true)
	draw_rect(next_r, slot_outline, false, 2.0)
	_draw_centered_text(next_r, "Next >>", next_enabled)


	var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
	var page_text: = "Page %d / %d" % [_page + 1, _page_count()]
	var nb: = _nav_bar_rect()
	var center: = nb.position + nb.size * 0.5
	var pos: = center + Vector2(-60, 9)
	draw_string_outline(font, pos, page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 2, Color(0, 0, 0, 0.85))
	draw_string(font, pos, page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))

func _draw_centered_text(r: Rect2, txt: String, enabled: bool) -> void :
	var font: = (COUNT_FONT if COUNT_FONT != null else get_theme_default_font())
	var col: = Color(1, 1, 1, 0.95 if enabled else 0.6)

	var pos: = r.position + Vector2(10, r.size.y * 0.65)
	draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 2, Color(0, 0, 0, 0.85))
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)

func _draw_label_fit(font: Font, rect: Rect2, text: String, base_size: int, col: Color) -> void :
	var size: = base_size
	var max_w: = rect.size.x
	var width: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	while width > max_w and size > 8:
		size -= 1
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


	var pos: = rect.position + Vector2(0, rect.size.y * 0.65)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)




func _warm_icons() -> void :
	if world == null:
		return
	for i in RECIPES.size():
		var r: Dictionary = RECIPES[i]


		if r.has("icon_path"):
			var tex: = _tex_from_path_safe(r["icon_path"])
			if tex:
				RECIPES[i]["__icon"] = tex
				continue


		if r.has("tile_ac"):
			var ac: = Vector2i(r["tile_ac"])
			if _is_valid_ac(ac):
				var icon: = _icon_from_world_tile(ac)
				if icon:
					RECIPES[i]["__icon"] = icon
	_warm_icon_done = true

func _icon_from_world_tile(tile_ac: Vector2i) -> Texture2D:
	if world == null: return null
	if not _is_valid_ac(tile_ac): return null
	if not world.has_method("_texture_from_atlas_cached"): return null
	return world._texture_from_atlas_cached(world.SRC, tile_ac, 0)


func _ensure_icon_registered(item_id: int, src_id: int, ac: Vector2i) -> void :
	if not hotbar: return
	if hotbar.icon_by_item.has(item_id) and hotbar.icon_by_item[item_id] != null:
		return
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("get"):
		var ground = world.get("ground")
		if ground:
			var ts: TileSet = ground.tile_set
			if ts:
				var src: = ts.get_source(src_id)
				if src is TileSetAtlasSource:
					var atlas: = src as TileSetAtlasSource
					if atlas.has_tile(ac):
						var region: = atlas.get_tile_texture_region(ac, 0)
						var at: = AtlasTexture.new()
						at.atlas = atlas.texture
						at.region = Rect2(region.position, region.size)
						at.filter_clip = true
						if hotbar.has_method("register_item_icon"):
							hotbar.register_item_icon(item_id, at)

func _ensure_icon_registered_tex(item_id: int, tex: Texture2D) -> void :
	if not hotbar: return
	if hotbar.icon_by_item.has(item_id) and hotbar.icon_by_item[item_id] != null:
		return
	if tex != null and hotbar.has_method("register_item_icon"):
		hotbar.register_item_icon(item_id, tex)

func _icon_for(id: int) -> Texture2D:
	if hotbar and hotbar.icon_by_item.has(id):
		return hotbar.icon_by_item[id]
	return null


func _update_player_input_gate() -> void :
	var lp: = _get_local_player()
	if lp and lp.has_method("set_input_enabled"):
		lp.call("set_input_enabled", not visible)
