extends Control
class_name CharacterSelect

const MAX_POINTS := 5
const MAX_IMAGE_SIDE := 192
const MAX_ASSET_BASE64_BYTES := 48 * 1024
const LOCAL_PROFILE_PATH := "user://custom_character.json"

const STAT_INFO := {
	"damage": {"label": "Damage", "description": "+5 damage per point"},
	"jumps": {"label": "Extra jumps", "description": "+1 air jump per point"},
	"speed": {"label": "Speed", "description": "+0.5 movement speed per point"},
	"health": {"label": "Health", "description": "+25 max HP per point"},
	"range": {"label": "Range", "description": "+10 ray range per point"},
}

const DEFAULT_PROFILE := {
	"name": "My Character",
	"stats": {
		"damage": 0,
		"jumps": 0,
		"speed": 0,
		"health": 0,
		"range": 0,
	},
	"asset_png": "",
}

const SPONGY_USERS = [
	"frevoro",
	"kiwiig92"
]

@export var font: FontFile

var profile: Dictionary = {}
var stat_buttons: Dictionary = {}
var stat_labels: Dictionary = {}
var preview: TextureRect
var name_edit: LineEdit
var status_label: Label
var total_label: Label
var file_dialog: FileDialog


func _ready() -> void:
	profile = _default_profile_copy()
	await _load_saved_profile()
	_build_ui()

func _apply_font(label:Control, size:int):
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)


func _default_profile_copy() -> Dictionary:
	return {
		"name": DEFAULT_PROFILE["name"],
		"stats": DEFAULT_PROFILE["stats"].duplicate(true),
		"asset_png": DEFAULT_PROFILE["asset_png"],
	}


func _build_ui() -> void:
	for child in get_children():
		if child != $DumbAhhLogo:
			child.queue_free()

	var root := VBoxContainer.new()
	root.position = Vector2(35, 30)
	root.size = Vector2(570, 300)
	root.add_theme_constant_override("separation", 5)
	add_child(root)

	var title := Label.new()
	title.text = "MAKE YOUR CHARACTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(title, 38)
	root.add_child(title)

	name_edit = LineEdit.new()
	name_edit.text = str(profile.get("name", "My Character"))
	name_edit.placeholder_text = "Character name"
	name_edit.max_length = 24
	name_edit.custom_minimum_size.y = 32
	_apply_font(name_edit, 20)
	root.add_child(name_edit)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	root.add_child(content)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	left.add_theme_constant_override("separation", 4)
	content.add_child(left)

	total_label = Label.new()
	_apply_font(total_label, 25)
	left.add_child(total_label)

	for stat_key in STAT_INFO.keys():
		_add_stat_row(left, stat_key)

	var help := Label.new()
	help.text = "You have 5 Character Points. Spend them however you want."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(help, 15)
	left.add_child(help)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 230
	right.add_theme_constant_override("separation", 6)
	content.add_child(right)

	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(180, 150)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(preview)

	var import_button := Button.new()
	import_button.text = "Import PNG"
	import_button.custom_minimum_size.y = 34
	_apply_font(import_button, 20)
	import_button.pressed.connect(_open_file_dialog)
	right.add_child(import_button)

	var user_dir_button := Button.new()
	user_dir_button.text = "Open user:// folder"
	user_dir_button.custom_minimum_size.y = 30
	_apply_font(user_dir_button, 16)
	user_dir_button.pressed.connect(_show_user_directory)
	right.add_child(user_dir_button)

	var reset_button := Button.new()
	reset_button.text = "Remove custom PNG"
	reset_button.custom_minimum_size.y = 30
	_apply_font(reset_button, 16)
	reset_button.pressed.connect(_remove_asset)
	right.add_child(reset_button)

	var preset_row := HBoxContainer.new()
	preset_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preset_row.add_theme_constant_override("separation", 6)
	root.add_child(preset_row)

	var teardrop_button := Button.new()
	teardrop_button.text = "Teardrop"
	_apply_font(teardrop_button, 17)
	teardrop_button.pressed.connect(_play_preset.bind("teardrop"))
	preset_row.add_child(teardrop_button)

	var firey_button := Button.new()
	firey_button.text = "Firey"
	_apply_font(firey_button, 17)
	firey_button.pressed.connect(_play_preset.bind("firey"))
	preset_row.add_child(firey_button)

	var username := str(get_tree().get_meta("player_username", ""))
	if is_spongy_allowed(username):
		var spongy_button := Button.new()
		spongy_button.text = "Spongy"
		_apply_font(spongy_button, 17)
		spongy_button.pressed.connect(_play_preset.bind("spongy"))
		preset_row.add_child(spongy_button)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	var back := Button.new()
	back.text = "Back"
	_apply_font(back, 20)
	back.pressed.connect(_back_to_menu)
	button_row.add_child(back)

	var save := Button.new()
	save.text = "SAVE & PLAY"
	save.custom_minimum_size = Vector2(210, 42)
	_apply_font(save, 23)
	save.pressed.connect(_save_and_play)
	button_row.add_child(save)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(status_label, 16)
	root.add_child(status_label)

	# IMPORTANT:
	# ACCESS_FILESYSTEM forces Godot to use the operating system's
	# native/system file picker instead of Godot's built-in dialog.
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.current_dir = OS.get_user_data_dir()
	file_dialog.filters = PackedStringArray(["*.png ; PNG images"])
	file_dialog.title = "Choose your character PNG"
	file_dialog.file_selected.connect(_on_png_selected)
	add_child(file_dialog)

	_refresh_ui()


func _open_file_dialog() -> void:
	# Start the system file picker in the Godot user:// directory.
	file_dialog.current_dir = OS.get_user_data_dir()
	file_dialog.popup_centered_ratio(0.75)


func _show_user_directory() -> void:
	# Opens the actual OS directory corresponding to user://.
	var user_dir := OS.get_user_data_dir()

	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)

	OS.shell_open(user_dir)

func _add_stat_row(parent: VBoxContainer, key: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 34
	parent.add_child(row)

	var label := Label.new()
	label.custom_minimum_size.x = 120
	_apply_font(label, 19)
	row.add_child(label)
	stat_labels[key] = label

	var minus := Button.new()
	minus.text = "-"
	minus.custom_minimum_size.x = 35
	_apply_font(minus, 22)
	minus.pressed.connect(_change_stat.bind(key, -1))
	row.add_child(minus)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size.x = 35
	_apply_font(plus, 22)
	plus.pressed.connect(_change_stat.bind(key, 1))
	row.add_child(plus)

	var desc := Label.new()
	desc.text = STAT_INFO[key]["description"]
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(desc, 13)
	row.add_child(desc)

	stat_buttons[key] = [minus, plus]


func _change_stat(key: String, amount: int) -> void:
	var stats: Dictionary = profile["stats"]
	var old_value := int(stats.get(key, 0))
	var new_value := clampi(old_value + amount, 0, MAX_POINTS)

	if amount > 0 and _total_points() >= MAX_POINTS:
		return

	stats[key] = new_value
	_refresh_ui()


func _total_points() -> int:
	var total := 0
	for value in profile["stats"].values():
		total += int(value)
	return total


func _refresh_ui() -> void:
	if not is_instance_valid(total_label):
		return

	var total := _total_points()
	total_label.text = "CHARACTER POINTS: %d / %d" % [total, MAX_POINTS]

	for key in STAT_INFO.keys():
		var value := int(profile["stats"].get(key, 0))
		stat_labels[key].text = "%s: %d" % [STAT_INFO[key]["label"], value]
		var buttons: Array = stat_buttons[key]
		buttons[0].disabled = value <= 0
		buttons[1].disabled = total >= MAX_POINTS

	if preview:
		var png_data := _decode_asset()
		if not png_data.is_empty():
			var image := Image.new()
			if image.load_png_from_buffer(png_data) == OK:
				preview.texture = ImageTexture.create_from_image(image)
		else:
			preview.texture = null

	if status_label:
		status_label.text = "PNG: imported" if not str(profile.get("asset_png", "")).is_empty() else "PNG: none (you can still play)"


func _on_png_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Could not read that file.")
		return

	var bytes := file.get_buffer(file.get_length())
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		_set_status("That isn't a valid PNG.")
		return

	var largest := maxi(image.get_width(), image.get_height())
	if largest <= 0:
		_set_status("The PNG has no usable image data.")
		return

	if largest > MAX_IMAGE_SIDE:
		var scale := float(MAX_IMAGE_SIDE) / float(largest)
		image.resize(
			maxi(1, int(round(image.get_width() * scale))),
			maxi(1, int(round(image.get_height() * scale))),
			Image.INTERPOLATE_LANCZOS
		)

	var png_bytes := image.save_png_to_buffer()
	var encoded := Marshalls.raw_to_base64(png_bytes)

	if encoded.to_utf8_buffer().size() > MAX_ASSET_BASE64_BYTES:
		_set_status("PNG is still too large after resizing. Try a simpler image.")
		return

	profile["asset_png"] = encoded
	_refresh_ui()


func _remove_asset() -> void:
	profile["asset_png"] = ""
	_refresh_ui()


func _play_preset(character: String) -> void:
	if character == "spongy" and not is_spongy_allowed(str(get_tree().get_meta("player_username", ""))):
		return
	if GDSync.is_active():
		GDSync.player_set_data("character", character)
	get_tree().set_meta("selected_character", character)
	get_tree().change_scene_to_file("res://game.tscn")


func _save_and_play() -> void:
	var character_name := name_edit.text.strip_edges()
	if character_name.is_empty():
		character_name = "My Character"

	profile["name"] = character_name
	profile["stats"] = profile["stats"].duplicate(true)

	var file := FileAccess.open(LOCAL_PROFILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(profile))

	if GDSync.is_active():
		GDSync.player_set_username(GDSync.player_get_username(GDSync.get_client_id(), character_name))
		GDSync.player_set_data("character", "custom")
		GDSync.player_set_data("character_profile", {
			"name": profile["name"],
			"stats": profile["stats"],
			"asset_png": profile["asset_png"],
		})

		if GDSync.account_is_logged_in():
			var code: int = await GDSync.account_document_set("profile/character", {
				"name": profile["name"],
				"stats": profile["stats"],
				"asset_png": profile["asset_png"],
			}, true)
			if code != ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
				_set_status("Saved locally, but cloud save failed (code %s)." % code)
				return

	get_tree().set_meta("selected_character", "custom")
	get_tree().set_meta("custom_character", profile.duplicate(true))
	get_tree().change_scene_to_file("res://game.tscn")


func _load_saved_profile() -> void:
	var loaded := false

	if GDSync.is_active() and GDSync.account_is_logged_in():
		var response: Dictionary = await GDSync.account_get_document("profile/character")
		if int(response.get("Code", -1)) == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
			var remote: Dictionary = response.get("Result", {})
			if remote.has("stats") and remote["stats"] is Dictionary:
				profile = _sanitize_profile(remote)
				loaded = true

	if not loaded:
		var file := FileAccess.open(LOCAL_PROFILE_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				profile = _sanitize_profile(parsed)


func _sanitize_profile(raw: Dictionary) -> Dictionary:
	var result := _default_profile_copy()
	result["name"] = str(raw.get("name", result["name"])).left(24)

	var raw_stats = raw.get("stats", {})
	if raw_stats is Dictionary:
		for key in STAT_INFO.keys():
			result["stats"][key] = clampi(int(raw_stats.get(key, 0)), 0, MAX_POINTS)

	# Never accept a loaded profile that has more points than the budget.
	while _sum_stats(result["stats"]) > MAX_POINTS:
		var removed := false
		for key in STAT_INFO.keys():
			if int(result["stats"][key]) > 0:
				result["stats"][key] -= 1
				removed = true
				break
		if not removed:
			break

	var asset := str(raw.get("asset_png", ""))
	if asset.to_utf8_buffer().size() <= MAX_ASSET_BASE64_BYTES:
		result["asset_png"] = asset
	return result


func _sum_stats(stats: Dictionary) -> int:
	var total := 0
	for value in stats.values():
		total += int(value)
	return total


func _decode_asset() -> PackedByteArray:
	var encoded := str(profile.get("asset_png", ""))
	if encoded.is_empty():
		return PackedByteArray()
	return Marshalls.base64_to_raw(encoded)


func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message
	else:
		print("[CHARACTER MAKER] ", message)


func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://mainmenu.tscn")


static func is_spongy_allowed(username: String) -> bool:
	var normalized := username.strip_edges().to_lower()
	for allowed_username in SPONGY_USERS:
		if str(allowed_username).strip_edges().to_lower() == normalized:
			return true
	return false
