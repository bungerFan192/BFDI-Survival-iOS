
extends Node


const MINING_TOOL_IDS: = {10: true, 12: true, 13: true, 14: true, 15: true, 16: true, 24: true, 25: true, 26: true, 64: true, 65: true, 66: true}
const SWORD_IDS: = {11: true, 17: true, 27: true, 67: true}


const UTILITY_IDS: = {37: true}

signal tool_broke(item_id: int, slot_index: int)


func is_tool_id(id: int) -> bool:
	return MINING_TOOL_IDS.has(id) or SWORD_IDS.has(id) or UTILITY_IDS.has(id)


const MAX: = {
	37: 64, 
	10: 60, 11: 60, 12: 60, 13: 60, 
	14: 132, 15: 132, 16: 132, 17: 132, 
	24: 251, 25: 251, 26: 251, 27: 251, 
	64: 640, 65: 640, 66: 640, 67: 640, 
}
func max_for(id: int) -> int: return int(MAX.get(id, 60))


func ensure_meta(stack: Dictionary) -> Dictionary:
	if not is_tool_id(int(stack.get("id", 0))):
		return stack
	var m = stack.get("meta", {})
	if typeof(m) != TYPE_DICTIONARY: m = {}
	if not m.has("max"): m["max"] = max_for(int(stack["id"]))
	if not m.has("dur"): m["dur"] = int(m["max"])
	if not m.has("used"): m["used"] = false
	stack["meta"] = m
	return stack


func damage_selected_tool(hotbar: Node, amount: int = 1) -> void :
	var idx: = int(hotbar.selected)
	var s = hotbar.slots[idx]


	s = ensure_meta(s)
	var m = s["meta"]

	var before: = int(m["dur"])
	m["dur"] = max(0, before - amount)
	m["used"] = true
	s["meta"] = m
	hotbar.slots[idx] = s
	hotbar.queue_redraw()


	if before > 0 and m["dur"] <= 0:

		var world: = get_tree().get_first_node_in_group("world")
		if world and world.has_method("_play_tool_break_local"):
			world._play_tool_break_local()

		emit_signal("tool_broke", int(s.get("id", 0)), idx)


		hotbar.slots[idx] = {"id": 0, "count": 0}
		if hotbar.has_method("_sanitize_slot"):
			hotbar.slots[idx] = hotbar._sanitize_slot(hotbar.slots[idx])
		hotbar.queue_redraw()
		return


	print("[cli] DUR ", s.id, ": ", m["dur"], "/", m["max"])
