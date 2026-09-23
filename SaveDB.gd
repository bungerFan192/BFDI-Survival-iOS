extends Node
class_name WorldSave














const SINGLE_SRC: = 0





static func _find_source_for_ac_alt(ts: TileSet, ac: Vector2i, alt: int) -> int:
	if ts == null: return -1
	for i in ts.get_source_count():
		var sid: = ts.get_source_id(i)
		var s = ts.get_source(sid)
		if s is TileSetAtlasSource:
			var asrc: = s as TileSetAtlasSource
			if asrc.has_tile(ac):

				if alt == 0 or asrc.has_alternative_tile(ac, alt):
					return sid
	return -1

static func _safe_set_cell(node: Node, cell: Vector2i, src: int, ac: Vector2i, alt: int, li: int = -1) -> void :
	if node == null: return
	if node is TileMapLayer:
		var l: = node as TileMapLayer
		if l.tile_set == null: return

		var final_src: = src
		if not l.tile_set.has_source(final_src):
			final_src = _find_source_for_ac_alt(l.tile_set, ac, alt)
			if final_src == -1:

				final_src = _find_source_for_ac_alt(l.tile_set, ac, 0)
			if final_src == -1:
				print("No source for ac=", ac, " alt=", alt, " (requested src=", src, ") at ", cell)
				return

		var s = l.tile_set.get_source(final_src)
		if s is TileSetAtlasSource:
			var asrc: = s as TileSetAtlasSource
			if not asrc.has_tile(ac):
				return

			if not asrc.has_alternative_tile(ac, alt):
				alt = 0

		l.set_cell(cell, final_src, ac, alt)

	elif node is TileMap:
		var t: = node as TileMap
		if li < 0: return
		if li >= t.get_layers_count(): return
		if t.tile_set == null: return

		var final_src: = src
		if not t.tile_set.has_source(final_src):
			final_src = _find_source_for_ac_alt(t.tile_set, ac, alt)
			if final_src == -1:

				final_src = _find_source_for_ac_alt(t.tile_set, ac, 0)
			if final_src == -1:
				print("No source for ac=", ac, " alt=", alt, " (requested src=", src, ") at ", cell)
				return

		var s = t.tile_set.get_source(final_src)
		if s is TileSetAtlasSource:
			var asrc: = s as TileSetAtlasSource
			if not asrc.has_tile(ac):
				return

			if not asrc.has_alternative_tile(ac, alt):
				alt = 0

		t.set_cell(li, cell, final_src, ac, alt)

static func _ground(world: Node) -> TileMapLayer:
	var n: = world.get_node_or_null("TileMapLayer")
	if n == null or not (n is TileMapLayer):
		print("TileMapLayer node not found")
		return null
	return n

static func save_chunk_full(world_name: String, world: Node, cx: int) -> void :
	if has_chunk(world_name, cx):
		return
	var x0 = cx * world.CHUNK_SIZE
	var x1 = x0 + world.CHUNK_SIZE - 1

	var layers: = []
	for tm in _gather_layers(world):
		var tiles: = []
		if tm is TileMapLayer:
			var l: = tm as TileMapLayer
			for cell: Vector2i in l.get_used_cells():
				if cell.x < x0 or cell.x > x1: continue
				var src: = l.get_cell_source_id(cell)
				if src == -1: continue
				var ac: = l.get_cell_atlas_coords(cell)
				var alt: = int(l.get_cell_alternative_tile(cell)) if l.has_method("get_cell_alternative_tile") else 0
				tiles.append({"pos": [cell.x, cell.y], "src": src, "ac": [ac.x, ac.y], "alt": alt})
			layers.append({"path": String(l.get_path()), "type": "TileMapLayer", "tiles": tiles})

		elif tm is TileMap:
			var t: = tm as TileMap
			for li in range(t.get_layers_count()):
				for cell: Vector2i in t.get_used_cells(li):
					if cell.x < x0 or cell.x > x1: continue
					var src: = t.get_cell_source_id(li, cell)
					if src == -1: continue
					var ac: = t.get_cell_atlas_coords(li, cell)
					var alt: = int(t.get_cell_alternative_tile(li, cell))
					tiles.append({"pos": [cell.x, cell.y], "src": src, "ac": [ac.x, ac.y], "alt": alt, "layer": li})
			layers.append({"path": String(t.get_path()), "type": "TileMap", "tiles": tiles})

	var payload: = {
		"sealed": true, 
		"rev": int(Time.get_unix_time_from_system()), 
		"base": {"layers": layers}, 
		"removed": [], "overrides": {}, "pickups": [], 
		"cakes_collected": [], "containers": {}
	}
	DirAccess.make_dir_recursive_absolute("%s/chunks" % _world_dir(world_name))
	_write_json_atomic(_chunk_path(world_name, cx), payload)

var _chunk_mutex: = {}

func _lock(cx: int) -> void :
	if !_chunk_mutex.has(cx):
		_chunk_mutex[cx] = Mutex.new()
	(_chunk_mutex[cx] as Mutex).lock()

func _unlock(cx: int) -> void :
	if _chunk_mutex.has(cx):
		(_chunk_mutex[cx] as Mutex).unlock()


static func _gather_layers(world: Node) -> Array:
	var out: = []
	var stack: = [world]
	while stack.size() > 0:
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is TileMap or c is TileMapLayer:
				out.append(c)
	return out

static func capture_base_and_seal(world_name: String, world: Node, cx: int) -> void :
	if has_chunk(world_name, cx):
		return
	var x0 = cx * world.CHUNK_SIZE
	var x1 = x0 + world.CHUNK_SIZE - 1
	var layers_payload: = []

	for tm in _gather_layers(world):
		var tiles: = []
		if tm is TileMapLayer:
			var l: = tm as TileMapLayer
			for cell: Vector2i in l.get_used_cells():
				if cell.x < x0 or cell.x > x1: continue
				var src: = l.get_cell_source_id(cell)
				if src == -1: continue
				var ac: = l.get_cell_atlas_coords(cell)
				var alt: = int(l.get_cell_alternative_tile(cell)) if l.has_method("get_cell_alternative_tile") else 0
				tiles.append({"pos": [cell.x, cell.y], "src": src, "ac": [ac.x, ac.y], "alt": alt})
		elif tm is TileMap:
			var t: = tm as TileMap
			for li in range(t.get_layers_count()):
				for cell: Vector2i in t.get_used_cells(li):
					if cell.x < x0 or cell.x > x1: continue
					var src: = t.get_cell_source_id(li, cell)
					if src == -1: continue
					var ac: = t.get_cell_atlas_coords(li, cell)
					var alt: = int(t.get_cell_alternative_tile(li, cell))
					tiles.append({"pos": [cell.x, cell.y], "src": src, "ac": [ac.x, ac.y], "alt": alt, "layer": li})

		layers_payload.append({"path": String(tm.get_path()), "tiles": tiles})

	var payload: = {
		"sealed": true, 
		"base": {"layers": layers_payload}, 
		"removed": [], "overrides": {}, "pickups": [], 
		"cakes_collected": [], "containers": {}
	}
	_write_json_atomic(_chunk_path(world_name, cx), payload)

static func _tm_set_cell(node: Node, cell: Vector2i, src: int, ac: Vector2i, alt: int, li: int) -> void :
	_safe_set_cell(node, cell, src, ac, alt, li)

static func load_chunk_full(world_name: String, world: Node, cx: int) -> void :
	var j = _read_json(_chunk_path(world_name, cx))
	if j == null: return

	var x0 = cx * world.CHUNK_SIZE
	var x1 = x0 + world.CHUNK_SIZE - 1


	for layer in j.get("base", {}).get("layers", []):
		var path: = String(layer.get("path", ""))
		var node: = world.get_node_or_null(path)
		if node == null: continue

		if node is TileMapLayer:
			var l: = node as TileMapLayer
			for cell: Vector2i in l.get_used_cells():
				if cell.x >= x0 and cell.x <= x1:
					l.erase_cell(cell)
		elif node is TileMap:
			var t: = node as TileMap
			for li in range(t.get_layers_count()):
				for cell: Vector2i in t.get_used_cells(li):
					if cell.x >= x0 and cell.x <= x1:
						t.erase_cell(li, cell)


	for layer in j.get("base", {}).get("layers", []):
		var path: = String(layer.get("path", ""))
		var node: = world.get_node_or_null(path)
		if node == null: continue

		for t in layer.get("tiles", []):
			var pos = t.get("pos", null)
			var ac = t.get("ac", null)
			if pos == null or ac == null: continue
			var cell: = Vector2i(int(pos[0]), int(pos[1]))
			var alt: = int(t.get("alt", 0))
			var src: = int(t.get("src", 0))
			var li: = int(t.get("layer", -1))
			_tm_set_cell(node, cell, src, Vector2i(int(ac[0]), int(ac[1])), alt, li)


	apply_chunk_diff(world_name, world, cx)


	var tm: = _ground(world)
	if tm != null:
		var applied: = 0
		for k in read_chunk(world_name, cx).get("overrides", {}).keys():
			var cell: = _cell_from_k(k)
			if cell.x >= x0 and cell.x <= x1:
				var sid: = tm.get_cell_source_id(cell)
				if sid == -1:
					print("Override at %s failed to place (src -1)" % [cell])
				else:
					applied += 1
		print("Overrides applied in chunk ", cx, ": ", applied)


	if tm != null: tm.update_internals()

static func _base_layers(world: Node) -> Array:
	if world.has_method("get_base_layers"): return world.get_base_layers()
	var out: = []
	for c in world.get_children():
		if c is TileMap or c is TileMapLayer: out.append(c)
	return out

static func _find_layer(world: Node, name: String) -> Node:
	return world.get_node_or_null(name)

static func replay_base_and_edits(world_name: String, world: Node, cx: int) -> void :
	var j = _read_json(_chunk_path(world_name, cx))
	if j == null: return

	for layer in j.get("base", {}).get("layers", []):
		var path: = String(layer.get("path", ""))
		var node: = world.get_node_or_null(path)
		if node == null: continue

		for t in layer.get("tiles", []):
			var pos = t.get("pos", null)
			var ac = t.get("ac", null)
			if pos == null or ac == null: continue
			var cell: = Vector2i(int(pos[0]), int(pos[1]))
			var alt: = int(t.get("alt", 0))
			var src: = int(t.get("src", 0))
			var li: = int(t.get("layer", -1))
			_tm_set_cell(node, cell, src, Vector2i(int(ac[0]), int(ac[1])), alt, li)

	apply_chunk_diff(world_name, world, cx)

	var tm: = _ground(world)
	if tm != null: tm.update_internals()

static func has_chunk(world_name: String, cx: int) -> bool:
	return FileAccess.file_exists(_chunk_path(world_name, cx))

static func read_chunk(world_name: String, cx: int) -> Variant:
	return _read_json(_chunk_path(world_name, cx))


static func apply_chunk_diff(world_name: String, world: Node, cx: int) -> void :
	var j = read_chunk(world_name, cx)
	if j == null: return

	var tm: = _ground(world)
	if tm == null:
		print("apply_chunk_diff: TileMapLayer missing")
		return


	if world.multiplayer.is_server():
		world._server_despawn_pickups_in_chunk(Vector2i(cx, 0))


	for pair in j.get("removed", []):
		var cell: = Vector2i(int(pair[0]), int(pair[1]))
		world.removed_cells[cell] = true
		tm.erase_cell(cell)


	for k in j.get("overrides", {}).keys():
		var cell: = _cell_from_k(k)
		var raw = j["overrides"][k]

		var ac: Vector2i
		var alt_i: = 0

		if typeof(raw) == TYPE_ARRAY and raw.size() >= 2:
			ac = Vector2i(int(raw[0]), int(raw[1]))
			if ac == world.T_POLE:
				alt_i = world.ALT_POLE
		elif typeof(raw) == TYPE_DICTIONARY:
			var arr: Array = raw.get("ac", [0, 0])
			ac = Vector2i(int(arr[0]), int(arr[1]))
			alt_i = int(raw.get("alt", 0))
		else:
			continue

		world.cell_overrides[cell] = ac


		var src_i: = SINGLE_SRC
		var ts = null
		var g = _ground(world)
		if g != null:
			ts = g.tile_set

		var guess: = _find_source_for_ac_alt(ts, ac, alt_i)

		if typeof(raw) == TYPE_DICTIONARY and raw.has("src"):
			src_i = int(raw["src"])
		elif guess != -1:
			src_i = guess
		else:
			print("Legacy override: cannot resolve src for ", ac, " alt=", alt_i, " at ", cell)
			return

		_safe_set_cell(_ground(world), cell, src_i, ac, alt_i, -1)


	for pair in j.get("cakes_collected", []):
		var cell: = Vector2i(int(pair[0]), int(pair[1]))
		world.collected_cake_cells[cell] = true
		world.collected_cake_columns[cell.x] = true


	for p in j.get("pickups", []):
		var pos: = Vector2(float(p["pos"][0]), float(p["pos"][1]))
		var ac: = Vector2i(int(p["ac"][0]), int(p["ac"][1]))
		var alt: = int(p["alt"])
		var metaa: = {}
		if p.has("meta") and typeof(p["meta"]) == TYPE_DICTIONARY:
			metaa = (p["meta"] as Dictionary).duplicate(true)
		world._server_spawn_pickup(int(p["item_id"]), pos, ac, alt, {"meta": metaa})


	var cont = j.get("containers", {})
	for k in cont.keys():
		var cell: = _cell_from_k(k)
		var key_xy: = str(cell.x) + "," + str(cell.y)
		var box: = (cont[k] as Dictionary).duplicate(true)
		world._server_boxes[key_xy] = {"box": box}







	var _ov = j.get("overrides", {}).size()
	var _rm = j.get("removed", []).size()
	var _pk = j.get("pickups", []).size()
	var _bg = j.get("bugs", []).size()
	var _ck = j.get("cakes_collected", []).size()
	var _ct = j.get("containers", {}).size()
	print("[LOAD c=", cx, "] removed=", _rm, 
		" overrides=", _ov, 
		" pickups=", _pk, 
		" bugs=", _bg, 
		" cakes=", _ck, 
		" containers=", _ct)



static func save_chunk(world_name: String, world: Node, cx: int) -> void :
	var x0 = cx * world.CHUNK_SIZE
	var x1 = x0 + world.CHUNK_SIZE - 1


	var removed: Array = []
	for cell in world.removed_cells.keys():
		if cell.x >= x0 and cell.x <= x1:
			removed.append([cell.x, cell.y])

	var overrides: = {}
	var tm: = _ground(world)
	for cell in world.cell_overrides.keys():
		if cell.x < x0 or cell.x > x1: continue
		var ac: Vector2i = world.cell_overrides[cell]

		var alt_i: = 0
		if tm != null and tm.has_method("get_cell_alternative_tile"):
			alt_i = int(tm.get_cell_alternative_tile(cell))

		var src_i: = -1
		if tm != null:
			src_i = tm.get_cell_source_id(cell)
		if src_i == -1:


			if tm != null and tm.tile_set != null and tm.tile_set.get_source_count() > 0:
				src_i = tm.tile_set.get_source_id(0)
			else:
				continue

		overrides[_k(cell)] = {"src": int(src_i), "ac": [ac.x, ac.y], "alt": alt_i}

	if not overrides.is_empty() and not removed.is_empty():
		var ov_set: = {}
		for k in overrides.keys():
			ov_set[_cell_from_k(k)] = true

		var filtered: = []
		for p in removed:
			var c: = Vector2i(int(p[0]), int(p[1]))
			if not ov_set.has(c):
				filtered.append(p)
		removed = filtered

	var cakes_collected: Array = []
	for c in world.collected_cake_cells.keys():
		if c.x >= x0 and c.x <= x1:
			cakes_collected.append([c.x, c.y])

	var pickups: Array = []
	for pid in world._server_pickups.keys():
		var info = world._server_pickups[pid]
		var pos: Vector2 = info.get("pos", Vector2.ZERO)
		if world._chunk_index_from_world_x(pos.x) != cx: continue
		var ac: Vector2i = info.get("ac", Vector2i(-1, -1))
		var alt: = int(info.get("alt", 0))
		var metaa: = {}
		if info.has("meta") and typeof(info["meta"]) == TYPE_DICTIONARY:
			metaa = _json_sanitize_meta(info["meta"])
		pickups.append({"item_id": int(info.get("item_id", 0)), 
			"pos": [pos.x, pos.y], "ac": [ac.x, ac.y], "alt": alt, "meta": metaa})

	var containers: = {}
	var boxes = world.get("_server_boxes")
	if typeof(boxes) == TYPE_DICTIONARY:
		for key in boxes.keys():
			var cell: = _parse_xy_key(str(key))
			if cell.x < x0 or cell.x > x1: continue
			var box: = (boxes[key].get("box", {}) as Dictionary).duplicate(true)
			containers[_k(cell)] = _json_sanitize_meta(box)









	if removed.is_empty() and overrides.is_empty() and pickups.is_empty()\
	and cakes_collected.is_empty() and containers.is_empty():
		return

	var path: = _chunk_path(world_name, cx)
	var prev = _read_json(path)

	var prev_removed: = []
	var prev_overrides: = {}
	var prev_pickups: = []

	var prev_cakes: = []
	var prev_containers: = {}

	if typeof(prev) == TYPE_DICTIONARY:

		prev_removed = prev.get("removed", [])
		prev_overrides = prev.get("overrides", {})
		prev_pickups = prev.get("pickups", [])

		prev_cakes = prev.get("cakes_collected", [])
		prev_containers = prev.get("containers", {})

		if prev_removed == removed\
		and prev_overrides == overrides\
		and prev_pickups == pickups\
		and prev_cakes == cakes_collected\
		and prev_containers == containers:
			return


	var out: = {
		"sealed": true, 
		"removed": removed, 
		"overrides": overrides, 
		"pickups": pickups, 

		"cakes_collected": cakes_collected, 
		"containers": containers, 
	}

	DirAccess.make_dir_recursive_absolute("%s/chunks" % _world_dir(world_name))
	_write_json_atomic(path, out)

static func _write_json_atomic(path: String, data: Variant) -> bool:
	var tmp: = path + ".tmp"
	var f: = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f = null

	DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK

static func write_meta(world_name: String, meta: Dictionary) -> void :
	_write_json("%s/world.json" % _world_dir(world_name), meta)

const META_SUMMIT_KEY: = "yoyle_summit_v1"

static func get_summit_record(world_name: String) -> Dictionary:
	var meta: = read_meta(world_name)
	return meta.get(META_SUMMIT_KEY, {}) as Dictionary

static func has_summit(world_name: String) -> bool:
	var rec: = get_summit_record(world_name)
	return bool(rec.get("placed", false))

static func set_summit_record(world_name: String, x: int, y: int, placing: bool = false) -> void :
	var meta: = read_meta(world_name)
	meta[META_SUMMIT_KEY] = {
		"x": x, 
		"y": y, 
		"placed": not placing, 
		"placing": placing
	}
	write_meta(world_name, meta)

static func mark_summit_placed(world_name: String) -> void :
	var meta: = read_meta(world_name)
	if meta.has(META_SUMMIT_KEY):
		var rec: Dictionary = meta[META_SUMMIT_KEY]
		rec.erase("placing")
		rec["placed"] = true
		meta[META_SUMMIT_KEY] = rec
		write_meta(world_name, meta)

static func _write_json(path: String, data: Variant) -> bool:
	var f: = FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data))
	return true

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null: return null
	var txt: = f.get_as_text()
	var parse = JSON.parse_string(txt)
	return parse

static func _world_dir(name: String) -> String:
	return "user://worlds/%s" % name

static func _chunk_path(name: String, cx: int) -> String:
	return "%s/chunks/c_%d.json" % [_world_dir(name), cx]


static func _k(cell: Vector2i) -> String: return "[%d,%d]" % [cell.x, cell.y]
static func _cell_from_k(s: String) -> Vector2i:
	var a: = s.strip_edges(true, true).replace("[", "").replace("]", "").split(",")
	return Vector2i(int(a[0]), int(a[1]))



static func save_world(world_name: String, world: Node) -> void :
	DirAccess.make_dir_recursive_absolute("%s/chunks" % _world_dir(world_name))
	var meta: = read_meta(world_name)
	if not meta.has("world_id") or str(meta["world_id"]) == "":
		meta["world_id"] = _make_uuid()

	meta["version"] = 1
	meta["created_at"] = Time.get_unix_time_from_system()
	meta["world_seed"] = int(world.get("world_seed"))
	meta["appearance_seed"] = int(world.get("appearance_seed"))
	meta["dn_epoch_server_sec"] = float(world.get("_dn_epoch_server_sec"))
	meta["sky_epoch_sec"] = float(world.get("_sky_epoch_sec"))
	var wv: Vector2 = world.get("_sky_wind")
	meta["sky_wind"] = [wv.x, wv.y]

	_write_json("%s/world.json" % _world_dir(world_name), meta)



	var touched: = {}
	for c in world.removed_cells.keys():
		var cx: = floori(c.x / world.CHUNK_SIZE)
		touched[cx] = true
	for c in world.cell_overrides.keys():
		var cx: = floori(c.x / world.CHUNK_SIZE)
		touched[cx] = true
	for pid in world._server_pickups.keys():
		var p = world._server_pickups[pid]
		var cx = world._chunk_index_from_world_x(float(p["pos"].x))
		touched[cx] = true







	for cell in world.collected_cake_cells.keys():
		var cx: = floori(cell.x / world.CHUNK_SIZE)
		touched[cx] = true

	for k in touched.keys():
		var cx: int = int(k)
		save_chunk(world_name, world, cx)


static func load_world(world_name: String, world: Node) -> bool:
	var meta = _read_json("%s/world.json" % _world_dir(world_name))
	if meta == null: return false


	world.rpc("cli_set_world_seeds", int(meta["world_seed"]), int(meta["appearance_seed"]))
	world._dn_epoch_server_sec = float(meta.get("dn_epoch_server_sec", 0.0))
	world._sky_epoch_sec = float(meta.get("sky_epoch_sec", 0.0))
	var w = meta.get("sky_wind", [world.SKY_WIND_DEFAULT.x, world.SKY_WIND_DEFAULT.y])
	world._sky_wind = Vector2(float(w[0]), float(w[1]))


	world.removed_cells.clear()
	world.cell_overrides.clear()
	world._server_pickups.clear()



	var dir: = DirAccess.open("%s/chunks" % _world_dir(world_name))
	if dir:
		dir.list_dir_begin()
		while true:
			var fn: = dir.get_next()
			if fn == "": break
			if not fn.ends_with(".json"): continue
			var j = _read_json("%s/chunks/%s" % [_world_dir(world_name), fn])
			if j == null: continue


			for pair in j.get("removed", []):
				var cell: = Vector2i(int(pair[0]), int(pair[1]))
				world.removed_cells[cell] = true
				world.ground.erase_cell(cell)


			for k in j.get("overrides", {}).keys():
				var cell: = _cell_from_k(k)
				var raw = j["overrides"][k]

				var ac: Vector2i
				var alt_i: = 0

				if typeof(raw) == TYPE_ARRAY and raw.size() >= 2:

					ac = Vector2i(int(raw[0]), int(raw[1]))

					if ac == world.T_POLE:
						alt_i = world.ALT_POLE
				elif typeof(raw) == TYPE_DICTIONARY:
					var arr: Array = raw.get("ac", [0, 0])
					ac = Vector2i(int(arr[0]), int(arr[1]))
					alt_i = int(raw.get("alt", 0))
				else:
					continue

				world.cell_overrides[cell] = ac

				var g = _ground(world)
				var ts = null
				if g != null:
					ts = g.tile_set

				var guess: = _find_source_for_ac_alt(ts, ac, alt_i)

				var src_i = world.SRC
				if typeof(raw) == TYPE_DICTIONARY and raw.has("src"):
					src_i = int(raw["src"])
				elif guess != -1:
					src_i = guess
				else:
					print("Legacy override: cannot resolve src for ", ac, " alt=", alt_i, " at ", cell)
					continue

				_safe_set_cell(_ground(world), cell, src_i, ac, alt_i, -1)



			for pair in j.get("cakes_collected", []):
				var cell: = Vector2i(int(pair[0]), int(pair[1]))
				world.collected_cake_cells[cell] = true
				world.collected_cake_columns[cell.x] = true


			for p in j.get("pickups", []):
				var pos: = Vector2(float(p["pos"][0]), float(p["pos"][1]))
				var ac: = Vector2i(int(p["ac"][0]), int(p["ac"][1]))
				var alt: = int(p["alt"])

				var metaa: = {}
				if p.has("meta") and typeof(p["meta"]) == TYPE_DICTIONARY:
					metaa = (p["meta"] as Dictionary).duplicate(true)

				world._server_spawn_pickup(int(p["item_id"]), pos, ac, alt, {"meta": metaa})


			var cont = j.get("containers", {})
			for k in cont.keys():
				var cell: = _cell_from_k(k)
				var key_xy: = str(cell.x) + "," + str(cell.y)
				var box: = (cont[k] as Dictionary).duplicate(true)
				world._server_boxes[key_xy] = {"box": box}








	world._broadcast_bug_reconcile()
	return true


static func read_meta(world_name: String) -> Dictionary:
	var p: = "%s/world.json" % _world_dir(world_name)
	var j = _read_json(p)
	return j if typeof(j) == TYPE_DICTIONARY else {}


static func _make_uuid() -> String:
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	var bytes: = PackedByteArray()
	for i in 16: bytes.append(rng.randi() & 255)
	var s: = bytes.hex_encode()

	return "%s-%s-%s-%s-%s" % [s.substr(0, 8), s.substr(8, 4), s.substr(12, 4), s.substr(16, 4), s.substr(20, 12)]

static func ensure_world_id(world_name: String) -> String:
	var meta: = read_meta(world_name)
	var id: = str(meta.get("world_id", ""))
	if id == "":
		id = _make_uuid()
		meta["world_id"] = id
		_write_json("%s/world.json" % _world_dir(world_name), meta)
	return id

static func world_id_of(world_name: String) -> String:
	var meta: = read_meta(world_name)
	return str(meta.get("world_id", ""))




static func _parse_xy_key(s: String) -> Vector2i:
	var parts: = s.split(",")
	if parts.size() >= 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO

static func _json_sanitize_meta(v: Variant) -> Variant:
	var t: = typeof(v)
	if t == TYPE_DICTIONARY:
		var out: = {}
		for k in (v as Dictionary).keys():
			out[str(k)] = _json_sanitize_meta((v as Dictionary)[k])
		return out
	elif t == TYPE_ARRAY:
		var out: = []
		for x in (v as Array):
			out.append(_json_sanitize_meta(x))
		return out
	elif t == TYPE_NIL or t == TYPE_BOOL or t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING:
		return v
	else:

		return str(v)
