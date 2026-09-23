
extends Control

const SHAG: = preload("res://Shag-Lounge.otf")


@onready var death_overlay: Control = $"."
var title_lbl: Label
var respawn_btn: Button
var watch_ad_btn: Button

func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p
	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

func _is_pc() -> bool:
	return OS.get_name() in ["Windows", "Linux", "macOS"]

func _ready() -> void :
	_create_death_ui()


	if _is_pc():
		if is_instance_valid(watch_ad_btn):
			watch_ad_btn.queue_free()
	else:
		_connect_ad_signals()




func _create_death_ui() -> void :

	death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	death_overlay.visible = false


	var bg: = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.5, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.add_child(bg)


	var center: = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.add_child(center)

	var vbox: = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_h_size_flags(Control.SIZE_SHRINK_CENTER)
	vbox.set_v_size_flags(Control.SIZE_SHRINK_CENTER)
	vbox.custom_minimum_size = Vector2(420, 240)
	center.add_child(vbox)


	title_lbl = Label.new()
	title_lbl.text = "YOU DIED"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", SHAG)
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_lbl)


	watch_ad_btn = Button.new()
	watch_ad_btn.text = "RESPAWN WITH INVENTORY"
	watch_ad_btn.focus_mode = Control.FOCUS_ALL
	watch_ad_btn.add_theme_font_override("font", SHAG)
	watch_ad_btn.add_theme_font_size_override("font_size", 26)
	watch_ad_btn.custom_minimum_size = Vector2(300, 80)
	watch_ad_btn.pressed.connect(_on_watch_ad_pressed)
	vbox.add_child(watch_ad_btn)


	respawn_btn = Button.new()
	respawn_btn.text = "RESPAWN"
	respawn_btn.focus_mode = Control.FOCUS_ALL
	respawn_btn.add_theme_font_override("font", SHAG)
	respawn_btn.add_theme_font_size_override("font_size", 22)
	respawn_btn.custom_minimum_size = Vector2(180, 40)
	respawn_btn.pressed.connect(_on_respawn_pressed)
	vbox.add_child(respawn_btn)

func show_death() -> void :
	_set_ad_loading( not _ad_ready())
	death_overlay.visible = true


	if is_instance_valid(watch_ad_btn) and _ad_ready():
		watch_ad_btn.grab_focus()
	else:
		if is_instance_valid(respawn_btn):
			respawn_btn.grab_focus()
	var inv: = get_tree().get_first_node_in_group("inventory")
	if inv and inv.visible:
		inv.toggle_visible()

	var oven: = get_tree().get_first_node_in_group("oven")
	if oven and oven.visible:
		oven.toggle_visible()

	var wheel_menu: = get_tree().get_first_node_in_group("wheel_menu")
	if wheel_menu and wheel_menu.visible:
		wheel_menu.toggle_visible()

	var craft = get_tree().get_first_node_in_group("crafting")
	if craft and craft.visible: craft.toggle_visible()

func hide_death() -> void :
	death_overlay.visible = false
	var world = get_tree().get_first_node_in_group("world")
	world._ui_lock(false)




func _connect_ad_signals() -> void :
	if typeof(AdManager) == TYPE_NIL:
		return
	if not AdManager.is_connected("rewarded_ready", Callable(self, "_on_rewarded_ready")):
		AdManager.rewarded_ready.connect(_on_rewarded_ready)
	if not AdManager.is_connected("rewarded_failed", Callable(self, "_on_rewarded_failed")):
		AdManager.rewarded_failed.connect(_on_rewarded_failed)
	if not AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.rewarded_closed.connect(_on_rewarded_closed)
	if not AdManager.is_connected("rewarded_granted", Callable(self, "_on_rewarded_granted")):
		AdManager.rewarded_granted.connect(_on_rewarded_granted)

func _ad_ready() -> bool:
	return (typeof(AdManager) != TYPE_NIL) and AdManager.is_reward_ready()

func _set_ad_loading(loading: bool) -> void :
	if watch_ad_btn == null: return
	if loading:
		watch_ad_btn.text = "LOADING AD..."
		watch_ad_btn.disabled = true
	else:
		watch_ad_btn.text = "RESPAWN WITH INVENTORY"
		watch_ad_btn.disabled = not _ad_ready()

func _on_watch_ad_pressed() -> void :
	if typeof(AdManager) == TYPE_NIL:
		return
	if _ad_ready():
		AdManager.show_reward_ad()
		_set_ad_loading(true)
	else:

		_set_ad_loading(true)
		AdManager._ensure_reward_loaded()

func _on_rewarded_ready() -> void :
	_set_ad_loading(false)

func _on_rewarded_failed() -> void :
	_set_ad_loading(false)

func _on_rewarded_closed() -> void :

	_set_ad_loading(false)

func _player() -> Node:
	return _get_local_player()

func _on_rewarded_granted() -> void :

	if not death_overlay.visible:
		return


	var p: = _player()
	if p:
		var dead: = false
		if p.has_method("is_dead"):
			dead = bool(p.call("is_dead"))
		else:
			var v = p.get("_dead")
			dead = (typeof(v) == TYPE_BOOL and v)
		if not dead:
			return


	hide_death()
	var world: = get_tree().get_first_node_in_group("world")
	if world:
		if multiplayer.is_server():
			world.srv_request_respawn(true)
		else:
			world.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_respawn", true)




func _on_respawn_pressed() -> void :

	hide_death()
	var world: = get_tree().get_first_node_in_group("world")
	if world:
		if multiplayer.is_server():
			world.srv_request_respawn(false)
		else:
			world.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_respawn", false)

func _respawn_player(keep_inventory: bool) -> void :

	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	if keep_inventory and world.has_method("srv_request_respawn_with_inventory"):
		if multiplayer.is_server():
			world.srv_request_respawn_with_inventory()
		else:
			world.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_respawn_with_inventory")
	else:
		if multiplayer.is_server():
			world.srv_request_respawn()
		else:
			world.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_respawn")
