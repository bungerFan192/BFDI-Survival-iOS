extends Node2D

const DEFAULT_PORT: = 24565
const WORLD_SCENE: = preload("res://world.tscn")
const WORLDS_DIR: = "user://worlds"

var _peer: ENetMultiplayerPeer

@onready var ip_edit: LineEdit = $CanvasLayer / IpEdit
@onready var port_edit: LineEdit = $CanvasLayer / PortEdit
@onready var host_btn: Button = $CanvasLayer / HostBtn
@onready var join_btn: Button = $CanvasLayer / JoinBtn
@onready var creative_btn: Button = $CanvasLayer / CreativeBtn


@onready var world_name_edit: LineEdit = $CanvasLayer / WorldName
@onready var saved_worlds: OptionButton = $CanvasLayer / SavedWorlds
@onready var create_btn: Button = $CanvasLayer / CreateBtn
@onready var load_btn: Button = $CanvasLayer / LoadBtn
@onready var hosting_on: Label = $CanvasLayer / HostingOn

@onready var internet_chk: CheckBox = $CanvasLayer / InternetMode

var _last_public_ip: String = ""
@onready var http: HTTPRequest = $CanvasLayer / HTTPRequest

var _upnp: UPNP
var _upnp_mapped_port: int = 0
@onready var character: Sprite2D = $CanvasLayer / Control4 / Character
@onready var music: AudioStreamPlayer2D = $CanvasLayer / Control2 / Music
@onready var musicsprite: Sprite2D = $CanvasLayer / Control5 / Music

func _ready() -> void :
	_wire_net_debug()
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	AdManager.maybe_show_lobby_interstitial()

	create_btn.pressed.connect(_on_create_world_pressed)
	load_btn.pressed.connect(_on_load_world_pressed)


	ip_edit.text = _get_wifi_ipv4()
	port_edit.text = str(DEFAULT_PORT)


	if not multiplayer.connected_to_server.is_connected(_on_connected_ok):
		multiplayer.connected_to_server.connect(_on_connected_ok)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


	internet_chk.toggled.connect(_on_internet_mode_toggled)
	port_edit.text_changed.connect( func(_t): _update_hosting_label_from_fields())
	http.request_completed.connect(_on_http_request_completed)
	if GameSession.character != null:
		current_name = GameSession.character
	else:
		GameSession.character = current_name

	GameSession.creative = false

	_update_creative_button_text()


	if not AdManager.rewarded_granted.is_connected(_on_creative_reward_granted):
		AdManager.rewarded_granted.connect(_on_creative_reward_granted)
	swap_texture()
	_ensure_worlds_dir()
	_refresh_saved_worlds()
	_update_hosting_label_from_fields()
	_upnp_unmap_if_any()
	musicon()

func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile")

func _update_creative_button_text() -> void :
	if creative_btn == null:
		return

	if GameSession.creative:
		creative_btn.text = "Turn off creative menu"
	else:
		if _is_mobile_platform():
			creative_btn.text = "Turn on creative menu (watch ad)"
		else:
			creative_btn.text = "Turn on creative menu"

func _on_creative_reward_granted() -> void :
	GameSession.creative = true
	_update_creative_button_text()

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
	print("HTTP result: %d, response_code: %d, headers: %s, body: %s" % [result, response_code, headers, body.get_string_from_utf8()])

func _ensure_upnp_discovered(timeout_ms: = 1000) -> bool:
	if _upnp == null:
		_upnp = UPNP.new()
	var r: = _upnp.discover(timeout_ms, 2, "InternetGatewayDevice")
	var gw: = _upnp.get_gateway()
	return r == UPNP.UPNP_RESULT_SUCCESS and gw != null and gw.is_valid_gateway()

func _on_internet_mode_toggled(pressed: bool) -> void :
	var lan_ip: = _get_wifi_ipv4()
	var port: = _parse_port_field()

	if not pressed:
		_update_hosting_label("", lan_ip, port)
		return


	if hosting_on:
		hosting_on.text = "Public: (checking…)  •  LAN: %s:%d" % [lan_ip, port]


	if _last_public_ip != "":
		_update_hosting_label(_last_public_ip, lan_ip, port)
		return


	if _upnp == null:
		_upnp = UPNP.new()
	var d: = _upnp.discover(1000, 2, "InternetGatewayDevice")
	if d == UPNP.UPNP_RESULT_SUCCESS and _upnp.get_gateway().is_valid_gateway():
		var wan: = _upnp.query_external_address()
		if wan != "":
			_last_public_ip = wan
			_update_hosting_label(_last_public_ip, lan_ip, port)
			return

	if _ensure_upnp_discovered(1000):
		var wan: = _get_public_ip_via_upnp()
		if wan != "":
			_last_public_ip = wan
			_update_hosting_label(_last_public_ip, lan_ip, port)
			return


	_fetch_public_ip_async()

func _update_hosting_label_from_fields() -> void :
	var lan_ip: = _get_wifi_ipv4()
	var port: = _parse_port_field()

	if internet_chk and internet_chk.button_pressed:
		if _last_public_ip != "":
			_update_hosting_label(_last_public_ip, lan_ip, port)
		else:

			if hosting_on and not hosting_on.text.contains("Public:"):
				hosting_on.text = "Public: (checking…)  •  LAN: %s:%d" % [lan_ip, port]
	else:
		_update_hosting_label("", lan_ip, port)

func _update_hosting_label(public_ip: String, lan_ip: String, port: int) -> void :
	if hosting_on == null: return
	if public_ip == "" or public_ip == "(unknown)":
		hosting_on.text = "LAN: %s:%d" % [lan_ip, port]
	else:
		hosting_on.text = "Public: %s:%d  •  LAN: %s:%d" % [public_ip, port, lan_ip, port]

func _get_public_ip_via_upnp() -> String:
	if _upnp == null:
		return ""
	var gw: = _upnp.get_gateway()
	if gw == null or not gw.is_valid_gateway():
		return ""
	var ip: = _upnp.query_external_address()
	return ip if ip != "" else ""

func _fetch_public_ip_async() -> void :

	if _last_public_ip != "":
		_update_hosting_label(_last_public_ip, _get_wifi_ipv4(), _parse_port_field())
		return

	var lan: = _get_wifi_ipv4()
	var port: = _parse_port_field()

	if http == null:

		if hosting_on:
			hosting_on.text = "Public: (unavailable)  •  LAN: %s:%d" % [lan, port]
		return


	var url: = "http://api.ipify.org"
	var err: = http.request(url)
	if err != OK:
		if hosting_on:
			hosting_on.text = "Public: (failed)  •  LAN: %s:%d" % [lan, port]
		return

	var sig = await http.request_completed
	var response_code: int = sig[1]
	var body: PackedByteArray = sig[3]

	if response_code == 200:
		_last_public_ip = body.get_string_from_utf8().strip_edges()
		_update_hosting_label(_last_public_ip, lan, port)
	else:
		if hosting_on:
			hosting_on.text = "Public: (failed %d)  •  LAN: %s:%d" % [response_code, lan, port]

func _try_upnp_map(port: int) -> Dictionary:

	var res: = {"ok": false, "public_ip": "", "port": port, "reason": ""}

	_upnp = UPNP.new()

	var d: = _upnp.discover(2000, 2, "InternetGatewayDevice")
	if d != UPNP.UPNP_RESULT_SUCCESS:
		res.reason = "Discovery failed: %s" % _upnp_result_to_string(d)
		return res

	if not _upnp.get_gateway().is_valid_gateway():
		res.reason = "No valid UPnP gateway found on this network."
		return res


	var add: = _upnp.add_port_mapping(port, port, "MyGame ENet Host", "UDP", 0)
	if add != UPNP.UPNP_RESULT_SUCCESS:
		res.reason = "Port map failed: %s" % _upnp_result_to_string(add)
		return res


	var pub_ip: = _upnp.query_external_address()
	if pub_ip == "":

		pub_ip = "(unknown)"
	res.public_ip = pub_ip
	res.ok = true
	_upnp_mapped_port = port
	return res


func _upnp_unmap_if_any() -> void :
	if _upnp and _upnp_mapped_port > 0:
		var gw: = _upnp.get_gateway()
		if gw != null and gw.is_valid_gateway():
			_upnp.delete_port_mapping(_upnp_mapped_port, "UDP")
	_upnp_mapped_port = 0
	_upnp = null

func _upnp_result_to_string(code: int) -> String:
	match code:
		UPNP.UPNP_RESULT_SUCCESS: return "SUCCESS"
		UPNP.UPNP_RESULT_NOT_AUTHORIZED: return "NOT_AUTHORIZED"
		UPNP.UPNP_RESULT_PORT_MAPPING_NOT_FOUND: return "PORT_MAPPING_NOT_FOUND"
		UPNP.UPNP_RESULT_INCONSISTENT_PARAMETERS: return "INCONSISTENT_PARAMETERS"
		UPNP.UPNP_RESULT_NO_SUCH_ENTRY_IN_ARRAY: return "NO_SUCH_ENTRY_IN_ARRAY"
		UPNP.UPNP_RESULT_ACTION_FAILED: return "ACTION_FAILED"
		UPNP.UPNP_RESULT_INVALID_ARGS: return "INVALID_ARGS"
		_: return "UNRECOGNIZED(%d)" % code

func _looks_like_cgnat(ip: String) -> bool:

	return ip.begins_with("10.")\
	or ip.begins_with("192.168.")\
	or (ip.begins_with("172.") and _is_172_private(ip))\
	or ip.begins_with("100.64.") or ip.begins_with("100.65.")\
	or ip.begins_with("100.66.") or ip.begins_with("100.67.")\
	or ip.begins_with("100.68.") or ip.begins_with("100.69.")\
	or ip.begins_with("100.7")

func _is_cgnat_or_private(ip: String) -> bool:
	var p: = ip.split(".")
	if p.size() != 4: return false
	var a: = int(p[0]); var b: = int(p[1])
	return a == 10\
	or (a == 192 and b == 168)\
	or (a == 172 and b >= 16 and b <= 31)\
	or (a == 100 and b >= 64 and b <= 127)



func _ensure_worlds_dir() -> void :
	DirAccess.make_dir_recursive_absolute(WORLDS_DIR)

func _world_meta_exists(name: String) -> bool:
	var p: = "%s/%s/world.json" % [WORLDS_DIR, name]
	return FileAccess.file_exists(p)

func _refresh_saved_worlds() -> void :
	saved_worlds.clear()
	var d: = DirAccess.open(WORLDS_DIR)
	if d:
		d.list_dir_begin()
		while true:
			var fn: = d.get_next()
			if fn == "": break
			if d.current_is_dir() and not fn.begins_with("."):

				if _world_meta_exists(fn):
					saved_worlds.add_item(fn)
		d.list_dir_end()

	if saved_worlds.item_count > 0 and saved_worlds.get_selected() < 0:
		saved_worlds.select(0)




func _dedupe_world_name(name: String) -> String:
	var base: = name
	var i: = 2
	while _world_meta_exists(name):
		name = "%s_%d" % [base, i]
		i += 1
	return name


func _on_create_world_pressed() -> void :
	var raw: = world_name_edit.text
	var name: = GameSession.safe_name(raw)
	if name.is_empty():
		name = "World_%d" % int(Time.get_unix_time_from_system())
	name = _dedupe_world_name(name)

	randomize()
	GameSession.current_world_name = name
	GameSession.new_world = true
	GameSession.world_seed = int(randi() & 2147483647)
	GameSession.appearance_seed = int(randi() & 2147483647)

	_host_with_session_and_go()

func _on_load_world_pressed() -> void :
	var name: = world_name_edit.text.strip_edges()
	if name == "" and saved_worlds.item_count > 0:
		var idx: = saved_worlds.get_selected()
		if idx >= 0:
			name = saved_worlds.get_item_text(idx)
	if name == "":
		push_error("Pick a world name or select one from the list.")
		return

	GameSession.current_world_name = GameSession.safe_name(name)
	GameSession.new_world = false

	_host_with_session_and_go()


func _host_with_session_and_go() -> void :
	var port: = _parse_port_field()
	if port <= 0:
		port = DEFAULT_PORT
	var lan_ip: = _get_wifi_ipv4()
	var want_internet: = internet_chk and internet_chk.button_pressed


	_update_hosting_label("", lan_ip, port)

	var public_ip: = ""


	if want_internet:
		if _ensure_upnp_discovered(1000):
			var up: = _try_upnp_map(port)
			if up.ok:
				public_ip = up.public_ip
			else:
				push_warning("[UPnP] " + up.reason + "\n" + 
					"If friends can’t connect, you may need manual port forwarding on UDP %d." % port)
		else:
			push_warning("[UPnP] No gateway discovered. Router may have UPnP disabled.")


	_peer = ENetMultiplayerPeer.new()
	var ok: = _peer.create_server(port, 16)
	if ok != OK:
		var fallback: = _find_open_port(port)
		if fallback != port and _peer.create_server(fallback, 16) == OK:
			if want_internet:
				_upnp_unmap_if_any()
				if _ensure_upnp_discovered(800):
					var up2: = _try_upnp_map(fallback)
					if up2.ok:
						public_ip = up2.public_ip
					else:
						push_warning("[UPnP] " + up2.reason)
			port = fallback
		else:
			push_error("Failed to host on %d (err=%s)" % [port, str(ok)])
			_upnp_unmap_if_any()
			return

	multiplayer.multiplayer_peer = _peer


	if want_internet:
		if public_ip == "" or public_ip == "(unknown)":

			_fetch_public_ip_async()
			public_ip = "(unknown)"
		if _looks_like_cgnat(public_ip):
			push_warning("Your external IP appears private/CGNAT (%s). Direct hosting may not work over the internet." % public_ip)
		_update_hosting_label(public_ip, lan_ip, port)
		if public_ip != "" and public_ip != "(unknown)":
			_last_public_ip = public_ip
			ip_edit.text = public_ip
		else:
			ip_edit.text = lan_ip
	else:
		_update_hosting_label("", lan_ip, port)
		ip_edit.text = lan_ip

	port_edit.text = str(port)
	print("HOST READY  LAN=%s:%d  PUBLIC=%s:%d  status=%d"
		%[lan_ip, port, public_ip, port, _peer.get_connection_status()])

	get_tree().change_scene_to_packed(WORLD_SCENE)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_upnp_unmap_if_any()

func _on_server_disconnected() -> void :
	var s: = _peer_status()
	_upnp_unmap_if_any()
	push_error("Disconnected from server, peer state: %d" % s)
	get_tree().change_scene_to_file("res://Lobby.tscn")



func _get_lan_ipv4() -> String:
	var fallback: = ""
	for a in IP.get_local_addresses():
		if a.find(":") != -1:
			continue
		if a.begins_with("127.") or a.begins_with("169.254."):
			continue
		if a.begins_with("10.") or a.begins_with("192.168.") or _is_172_private(a):
			return a
		if fallback == "":
			fallback = a
	return fallback if fallback != "" else "0.0.0.0"

func _get_wifi_ipv4() -> String:
	if IP.has_method("get_local_interfaces"):
		for iface in IP.get_local_interfaces():
			var name: = String(iface.get("name", "")).to_lower()
			if name.begins_with("wlan") or name.begins_with("ap") or name.begins_with("wl") or name.begins_with("en"):
				for addr in iface.get("addresses", []):
					var s: = String(addr)
					if s.find(":") == -1 and not s.begins_with("127.") and not s.begins_with("169.254."):
						return s
	return _get_lan_ipv4()

func _is_172_private(a: String) -> bool:
	if not a.begins_with("172."):
		return false
	var parts: = a.split(".")
	if parts.size() < 2:
		return false
	var n: = int(parts[1])
	return n >= 16 and n <= 31



func _on_host() -> void :
	var port: = _parse_port_field()
	if port <= 0: port = DEFAULT_PORT

	_peer = ENetMultiplayerPeer.new()
	var ok: = _peer.create_server(port, 16)
	if ok != OK:
		push_error("Failed to host on %d err=%s" % [port, str(ok)])
		return
	multiplayer.multiplayer_peer = _peer

	var ip: = _get_wifi_ipv4()
	print("HOST READY on %s:%d  status=%d" % [ip, port, _peer.get_connection_status()])
	ip_edit.text = ip
	port_edit.text = str(port)
	get_tree().change_scene_to_packed(WORLD_SCENE)

func _peer_status() -> int:
	var p: = multiplayer.multiplayer_peer
	if p == null:
		return MultiplayerPeer.CONNECTION_DISCONNECTED
	return p.get_connection_status()

func _on_join() -> void :
	var ip: = ip_edit.text.strip_edges()
	var port: = _parse_port_field()
	if ip == "":
		push_error("Enter a host IP")
		return

	_peer = ENetMultiplayerPeer.new()
	var ok: = _peer.create_client(ip, port)
	print("CLIENT create_client(%s:%d) -> %s  status=%d" % [ip, port, str(ok), _peer.get_connection_status()])
	if ok != OK:
		push_error("Failed to create client for %s:%d, error: %s" % [ip, port, str(ok)])
		return
	multiplayer.multiplayer_peer = _peer

	var t: = get_tree().create_timer(2.0)
	t.timeout.connect( func():
		var s: = _peer.get_connection_status()
		if s != MultiplayerPeer.CONNECTION_CONNECTED:
			push_error("Can’t reach host at %s:%d (status %d). Try phone hotspot as host." % [ip, port, s])
	)

func _wire_net_debug() -> void :
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void :
	print("peer_connected: ", id)

func _on_peer_disconnected(id: int) -> void :
	print("peer_disconnected: ", id)

func _on_connected_ok() -> void :
	print("connected_to_server -> WORLD")
	get_tree().change_scene_to_packed(WORLD_SCENE)

func _on_connection_failed() -> void :
	var s: = _peer_status()
	print("connection_failed, status=", s)
	push_error("Connection failed (status %d)" % s)



func _parse_port_field() -> int:
	var t: = port_edit.text.strip_edges()
	if t == "": return DEFAULT_PORT
	return int(t) if t.is_valid_int() else DEFAULT_PORT

func _find_open_port(preferred: int) -> int:
	var candidates: = [preferred]
	for i in range(1, 8):
		candidates.append(preferred + i)
	var test: = ENetMultiplayerPeer.new()
	for p in candidates:
		if test.create_server(p, 1) == OK:
			test = null
			return p
	test = null
	return preferred

const names: = ["LEAFY", "FIREY", "COINY", "PIN", "TENNISBALL", "GOLFBALL", "PENCIL", "MATCH", "NEEDLE", "PEN", "ICECUBE", "TEARDROP", "ROCKY", "FLOWER", "BUBBLE", "SNOWBALL", "BLOCKY", "WOODY", "ERASER", "SPONGY"]
var current_index: = 0
var current_name: = "LEAFY"

func _on_switch_character_pressed() -> void :
	current_index += 1
	if current_index >= names.size():
		current_index = 0
	current_name = names[current_index]
	GameSession.character = current_name
	swap_texture()

func swap_texture():
	match current_name:
		"LEAFY":
			character.texture = load("res://leafy/idle/idle0001.png")
			current_index = 0
		"FIREY":
			character.texture = load("res://firey/idle/idle0001.png")
			current_index = 1
		"COINY":
			character.texture = load("res://coiny/idle/idle0001.png")
			current_index = 2
		"PIN":
			character.texture = load("res://pin/idle/idle0001.png")
			current_index = 3
		"TENNISBALL":
			character.texture = load("res://tennisball/idle/idle0001.png")
			current_index = 4
		"GOLFBALL":
			character.texture = load("res://golfball/idle/idle0001.png")
			current_index = 5
		"PENCIL":
			character.texture = load("res://pencil/idle/idle0001.png")
			current_index = 6
		"MATCH":
			character.texture = load("res://match/idle/idle0001.png")
			current_index = 7
		"NEEDLE":
			character.texture = load("res://needle/idle/idle0001.png")
			current_index = 8
		"PEN":
			character.texture = load("res://pen/idle/idle0001.png")
			current_index = 9
		"ICECUBE":
			character.texture = load("res://ice cube/idle/idle0001.png")
			current_index = 10
		"TEARDROP":
			character.texture = load("res://teardrop/idle/idle0001.png")
			current_index = 11
		"ROCKY":
			character.texture = load("res://rocky/idle/idle0001.png")
			current_index = 12
		"FLOWER":
			character.texture = load("res://flower/idle/idle0001.png")
			current_index = 13
		"BUBBLE":
			character.texture = load("res://bubble/idle/idle0001.png")
			current_index = 14
		"SNOWBALL":
			character.texture = load("res://snowball/idle/idle0001.png")
			current_index = 15
		"BLOCKY":
			character.texture = load("res://blocky/idle/idle0001.png")
			current_index = 16
		"WOODY":
			character.texture = load("res://woody/idle/idle0001.png")
			current_index = 17
		"ERASER":
			character.texture = load("res://eraser/idle/idle0001.png")
			current_index = 18
		"SPONGY":
			character.texture = load("res://spongy/idle/idle0001.png")
			current_index = 19

func musicon():
	if GameSession.music:
		music.play()
		musicsprite.modulate.a = 1
	else:
		music.stop()
		musicsprite.modulate.a = 0.5

func _on_music_toggle_pressed() -> void :
	GameSession.music = !GameSession.music
	musicon()


func _on_creative_btn_pressed() -> void :

	if GameSession.creative:
		GameSession.creative = false
		_update_creative_button_text()
		return


	if not _is_mobile_platform():
		GameSession.creative = true
		_update_creative_button_text()
		return


	if AdManager.is_reward_ready():
		AdManager.show_reward_ad()
	else:
		AdManager.manual_load()
		push_warning("Reward ad is loading. Try again in a moment.")
