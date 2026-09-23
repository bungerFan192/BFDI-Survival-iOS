
extends Node

const BOX_VER: = 1

const FALLBACK_COLS: = 8
const FALLBACK_ROWS: = 4

static func _target_cols_rows() -> Vector2i:

	var cols: = FALLBACK_COLS
	var rows: = FALLBACK_ROWS
	var ml: = Engine.get_main_loop()
	if ml is SceneTree:
		var inv = ml.get_first_node_in_group("inventory")
		if inv:
			if "COLS" in inv: cols = int(inv.COLS)
			if "ROWS" in inv: rows = int(inv.ROWS)
	return Vector2i(cols, rows)

static func empty_slots(cols: int, rows: int) -> Array:
	var total = max(0, cols) * max(0, rows)
	var a: Array = []
	a.resize(total)
	for i in total:
		a[i] = {"id": 0, "count": 0}
	return a

static func skeleton(cols: int = -1, rows: int = -1) -> Dictionary:
	if cols < 0 or rows < 0:
		var tr: = _target_cols_rows()
		cols = tr.x
		rows = tr.y
	return {
		"box_v": BOX_VER, 
		"cols": cols, 
		"rows": rows, 
		"slots": empty_slots(cols, rows), 
		"uuid": str(Time.get_unix_time_from_system()) + "-" + str(randi())
	}

static func ensure_for_slot(slot: Dictionary) -> Dictionary:

	var s: = slot.duplicate(true)
	if int(s.get("id", 0)) != 72:
		return s


	var m: = (s.get("meta", {}) as Dictionary)
	var box: = (m.get("box", {}) as Dictionary)


	var tr: = _target_cols_rows()
	var tcols: = tr.x
	var trows: = tr.y


	if not (box.has("slots") and (box["slots"] is Array)):
		box = skeleton(tcols, trows)
	else:

		if not box.has("cols"): box["cols"] = tcols
		if not box.has("rows"): box["rows"] = trows


		var want: = int(tcols) * int(trows)
		var slots: = (box["slots"] as Array).duplicate(true)
		if slots.size() < want:
			for i in want - slots.size():
				slots.append({"id": 0, "count": 0})
		elif slots.size() > want:
			slots.resize(want)
		box["slots"] = slots
		box["cols"] = tcols
		box["rows"] = trows

	m["box"] = box
	s["meta"] = m
	return s
