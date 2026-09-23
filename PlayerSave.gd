extends Node

const DIR: = "user://player_saves"

var _dirty: = false
var _last_world_id: = ""

static func _path(world_id: String) -> String:
	return "%s/%s.json" % [DIR, world_id]

func _ready() -> void :
	DirAccess.make_dir_recursive_absolute(DIR)




func load_and_apply(world_id: String) -> void :
	_last_world_id = world_id
	var p: = _path(world_id)
	if not FileAccess.file_exists(p):

		save_now(world_id)
		return

	var j = _read_json(p)
	if typeof(j) != TYPE_DICTIONARY:
		return


	var hb: = _hotbar()
	if hb:
		if j.has("hotbar") and j["hotbar"] is Array:
			_apply_slots_to_hotbar(hb, j["hotbar"])
		if j.has("selected"):
			hb.selected = clamp(int(j["selected"]), 0, hb.SLOT_COUNT - 1)
		hb.queue_redraw()

	var inv: = _inventory()
	if inv and j.has("inventory") and j["inventory"] is Array:
		_apply_slots_to_inventory(inv, j["inventory"])


func queue_save() -> void :
	_dirty = true

	if not has_node("Flush"):
		var t: = Timer.new()
		t.name = "Flush"
		t.one_shot = true
		t.wait_time = 0.1
		add_child(t)
		t.timeout.connect( func():
			if _dirty and GameSession.current_world_id != "":
				save_now(GameSession.current_world_id)
			_dirty = false
			if is_instance_valid(t): t.queue_free()
		)
		t.start()


func save_now(world_id: String) -> void :
	_last_world_id = world_id
	var p: = _path(world_id)


	var j: = _read_or_default(world_id)


	j["version"] = 1
	j["world_id"] = world_id


	var hb: = _hotbar()
	if hb:
		j["hotbar"] = _export_hotbar(hb)
		j["selected"] = int(hb.selected)


	var inv: = _inventory()
	if inv:
		j["inventory"] = _export_inventory(inv)


	if not j.has("stats"):
		j["stats"] = {"health": 10, "hunger": 10, "saturation": 0.0, "exhaustion": 0.0, "oxygen": 5.0, "absorption": 0.0}
	else:

		var s: = get_stats(world_id)
		j["stats"] = s


	_write_json(p, j)



func _hotbar() -> Node:
	return get_tree().get_first_node_in_group("hotbar")

func _inventory() -> Node:
	return get_tree().get_first_node_in_group("inventory")

func _export_hotbar(hb: Node) -> Array:
	var out: Array = []
	for i in hb.SLOT_COUNT:
		var s
		if i < hb.slots.size() and typeof(hb.slots[i]) == TYPE_DICTIONARY:
			s = hb.slots[i]
		else:
			s = {"id": 0, "count": 0}
		var norm: = _sanitize_for_node(hb, s)
		var entry: = {"id": int(norm.id), "count": int(norm.count)}
		if norm.has("meta") and typeof(norm["meta"]) == TYPE_DICTIONARY and norm["meta"].size() > 0:
			entry["meta"] = norm["meta"]
		out.append(entry)
	return out

func _export_inventory(inv: Node) -> Array:
	var out: Array = []
	for i in inv.SLOT_COUNT:
		var s
		if i < inv.slots.size() and typeof(inv.slots[i]) == TYPE_DICTIONARY:
			s = inv.slots[i]
		else:
			s = {"id": 0, "count": 0}
		var norm: = _sanitize_for_node(inv, s)
		var entry: = {"id": int(norm.id), "count": int(norm.count)}
		if norm.has("meta") and typeof(norm["meta"]) == TYPE_DICTIONARY and norm["meta"].size() > 0:
			entry["meta"] = norm["meta"]
		out.append(entry)
	return out

func _apply_slots_to_hotbar(hb: Node, arr: Array) -> void :
	var n = min(arr.size(), hb.SLOT_COUNT)

	hb.slots.resize(hb.SLOT_COUNT)
	for i in hb.SLOT_COUNT:
		hb.slots[i] = {"id": 0, "count": 0}

	for i in n:
		var s = arr[i]
		if typeof(s) == TYPE_DICTIONARY:
			hb.slots[i] = _sanitize_for_node(hb, s)
		else:
			hb.slots[i] = {"id": 0, "count": 0}


	hb.selected = clamp(int(hb.selected), 0, hb.SLOT_COUNT - 1)

	hb.queue_redraw()

func _apply_slots_to_inventory(inv: Node, arr: Array) -> void :
	var n = min(arr.size(), inv.SLOT_COUNT)
	inv.slots.resize(inv.SLOT_COUNT)
	for i in inv.SLOT_COUNT:
		inv.slots[i] = {"id": 0, "count": 0}

	for i in n:
		var s = arr[i]
		if typeof(s) == TYPE_DICTIONARY:
			inv.slots[i] = _sanitize_for_node(inv, s)
		else:
			inv.slots[i] = {"id": 0, "count": 0}

	inv.queue_redraw()


static func _read_json(path: String) -> Variant:
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null: return null
	var txt: = f.get_as_text()
	return JSON.parse_string(txt)

static func _write_json(path: String, data: Variant) -> bool:
	var f: = FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data))
	return true


func set_last_pos(world_id: String, pos: Vector2) -> void :
	var j: = _read_or_default(world_id)
	j["last_pos"] = [pos.x, pos.y]
	_write_json(_path(world_id), j)

func get_last_pos(world_id: String) -> Variant:
	var j: = _read_or_default(world_id)
	if j.has("last_pos") and j["last_pos"] is Array and j["last_pos"].size() >= 2:
		return Vector2(float(j["last_pos"][0]), float(j["last_pos"][1]))
	return null


func _read_or_default(world_id: String) -> Dictionary:
	var p: = _path(world_id)
	if not FileAccess.file_exists(p):
		return {"version": 1, "world_id": world_id, "selected": 0, 
			"hotbar": [], "inventory": [], 
			"stats": {"health": 10, "hunger": 10, "saturation": 0.0, "exhaustion": 0.0, "oxygen": 5.0, "absorption": 0.0}}
	var j = _read_json(p)
	if typeof(j) != TYPE_DICTIONARY:
		return {"version": 1, "world_id": world_id, "selected": 0, 
			"hotbar": [], "inventory": [], 
			"stats": {"health": 10, "hunger": 10, "saturation": 0.0, "exhaustion": 0.0, "oxygen": 5.0, "absorption": 0.0}}
	if not j.has("stats"):
		j["stats"] = {"health": 10, "hunger": 10, "saturation": 0.0, "exhaustion": 0.0, "oxygen": 5.0, "absorption": 0.0}
	else:

		if not j["stats"].has("oxygen"):
			j["stats"]["oxygen"] = 5.0
		if not j["stats"].has("absorption"):
			j["stats"]["absorption"] = 0.0
	return j


func set_stats(world_id: String, health: int, hunger: int, sat: float, exh: float, oxygen: int, absorption: float = -1.0) -> void :
	var j: = _read_or_default(world_id)

	var old_stats: = {}
	if j.has("stats") and (j["stats"] is Dictionary):
		old_stats = j["stats"]

	var old_abs: = float(old_stats.get("absorption", 0.0))
	var new_abs: = old_abs
	if absorption >= 0.0:
		new_abs = absorption

	j["stats"] = {
		"health": clamp(health, 0, 10), 
		"hunger": clamp(hunger, 0, 10), 
		"saturation": max(0.0, sat), 
		"exhaustion": max(0.0, exh), 
		"oxygen": clamp(oxygen, 0, 5), 
		"absorption": max(0.0, new_abs), 
	}
	_write_json(_path(world_id), j)

func get_stats(world_id: String) -> Dictionary:
	var j: = _read_or_default(world_id)
	if j.has("stats") and typeof(j["stats"]) == TYPE_DICTIONARY:

		if not j["stats"].has("oxygen"):
			j["stats"]["oxygen"] = 5.0
		if not j["stats"].has("absorption"):
			j["stats"]["absorption"] = 0.0
		return j["stats"]
	return {"health": 10, "hunger": 10, "saturation": 0.0, "exhaustion": 0.0, "oxygen": 5.0, "absorption": 0.0}


func set_absorption(world_id: String, absorption: float) -> void :
	var s: = get_stats(world_id)
	s["absorption"] = max(0.0, absorption)
	var j: = _read_or_default(world_id)
	j["stats"] = s
	_write_json(_path(world_id), j)

func get_absorption(world_id: String) -> float:
	return float(get_stats(world_id).get("absorption", 0.0))


func _sanitize_for_node(owner: Node, slot: Dictionary) -> Dictionary:

	var out: = slot.duplicate(true)


	var id: = int(out.get("id", 0))
	var count: = int(out.get("count", 0))


	if id == 0 or count <= 0:
		return {"id": 0, "count": 0}


	var cap: = 64
	if owner and owner.has_method("_stack_cap_for"):
		cap = int(owner.call("_stack_cap_for", id))


	out["id"] = id
	out["count"] = clamp(count, 1, cap)



	if out.has("meta") and typeof(out["meta"]) == TYPE_DICTIONARY:
		out["meta"] = (out["meta"] as Dictionary).duplicate(true)


	if owner and owner.has_method("_sanitize_slot"):
		out = owner.call("_sanitize_slot", out)

		id = int(out.get("id", 0))
		count = int(out.get("count", 0))
		if id == 0 or count <= 0:
			return {"id": 0, "count": 0}
		if owner.has_method("_stack_cap_for"):
			cap = int(owner.call("_stack_cap_for", id))
		out["count"] = clamp(count, 1, cap)

	return out
