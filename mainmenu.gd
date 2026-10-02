extends Control

const DEFAULT_LOBBY := "BFDI Arena"
const SESSION_VALID_TIME := 60.0 * 60.0 * 24.0 * 30.0

@export var username: LineEdit
@export var password: LineEdit
@export var registerbutton: Button
@export var loginbutton: Button
@export var font: FontFile

var email_edit: LineEdit
var account_username_edit: LineEdit
var account_password_edit: LineEdit
var lobby_edit: LineEdit
var status_label: Label
var register_account_button: Button
var login_account_button: Button
var create_lobby_button: Button
var join_lobby_button: Button
var auth_panel: VBoxContainer
var lobby_panel: VBoxContainer
var busy := false
var gd_sync_connected := false
var logged_in := false
var logged_account_username := ""


func _ready() -> void:
	if font == null:
		font = load("res://Shag-Lounge.otf") as FontFile
	_build_ui()

	if not GDSync.connected.is_connected(_on_gdsync_connected):
		GDSync.connected.connect(_on_gdsync_connected)
	if not GDSync.connection_failed.is_connected(_on_connection_failed):
		GDSync.connection_failed.connect(_on_connection_failed)
	if not GDSync.lobby_joined.is_connected(_on_lobby_joined):
		GDSync.lobby_joined.connect(_on_lobby_joined)
	if not GDSync.lobby_join_failed.is_connected(_on_lobby_join_failed):
		GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	if not GDSync.account_logged_in.is_connected(_on_account_logged_in):
		GDSync.account_logged_in.connect(_on_account_logged_in)
	if not GDSync.account_logged_out.is_connected(_on_account_logged_out):
		GDSync.account_logged_out.connect(_on_account_logged_out)

	if not GDSync.lobby_created.is_connected(_on_lobby_created):
		GDSync.lobby_created.connect(_on_lobby_created)
	if not GDSync.lobby_creation_failed.is_connected(_on_lobby_creation_failed):
		GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)

	if GDSync.is_active():
		_on_gdsync_connected()
	else:
		_set_status("Connecting to GD-Sync...")
		GDSync.start_multiplayer()


func _build_ui() -> void:
	# The old menu nodes are kept in the scene for compatibility, but the new
	# menu is generated here so the account and lobby flow stays easy to edit.
	if username:
		username.hide()
	if password:
		password.hide()
	if registerbutton:
		registerbutton.hide()
	if loginbutton:
		loginbutton.hide()

	var center := VBoxContainer.new()
	center.name = "AccountMenu"
	center.position = Vector2(70, 205)
	center.size = Vector2(500, 145)
	center.add_theme_constant_override("separation", 6)
	add_child(center)

	var title := Label.new()
	title.text = "ACCOUNT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(title, 28)
	center.add_child(title)

	email_edit = _make_edit("Email")
	center.add_child(email_edit)

	account_username_edit = _make_edit("Username")
	account_username_edit.max_length = 20
	center.add_child(account_username_edit)

	account_password_edit = _make_edit("Password")
	account_password_edit.secret = true
	account_password_edit.max_length = 20
	center.add_child(account_password_edit)

	var auth_buttons := HBoxContainer.new()
	auth_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	auth_buttons.add_theme_constant_override("separation", 10)
	center.add_child(auth_buttons)

	register_account_button = _make_button("Create Account", 20)
	register_account_button.pressed.connect(_register_account)
	auth_buttons.add_child(register_account_button)

	login_account_button = _make_button("Log In", 20)
	login_account_button.pressed.connect(_login_account)
	auth_buttons.add_child(login_account_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(status_label, 18)
	center.add_child(status_label)

	auth_panel = center

	lobby_panel = VBoxContainer.new()
	lobby_panel.name = "LobbyMenu"
	lobby_panel.position = Vector2(70, 225)
	lobby_panel.size = Vector2(500, 115)
	lobby_panel.add_theme_constant_override("separation", 8)
	add_child(lobby_panel)
	lobby_panel.hide()

	var lobby_title := Label.new()
	lobby_title.text = "LOBBY"
	lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(lobby_title, 28)
	lobby_panel.add_child(lobby_title)

	lobby_edit = _make_edit("Lobby name (blank = BFDI Arena)")
	lobby_panel.add_child(lobby_edit)

	var lobby_buttons := HBoxContainer.new()
	lobby_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	lobby_buttons.add_theme_constant_override("separation", 10)
	lobby_panel.add_child(lobby_buttons)

	create_lobby_button = _make_button("Create Lobby", 20)
	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	lobby_buttons.add_child(create_lobby_button)

	join_lobby_button = _make_button("Join Lobby", 20)
	join_lobby_button.pressed.connect(_on_join_lobby_pressed)
	lobby_buttons.add_child(join_lobby_button)

	var logout_button := _make_button("Log out", 16)
	logout_button.pressed.connect(_logout)
	lobby_panel.add_child(logout_button)


func _make_edit(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(0, 31)
	_apply_font(edit, 20)
	return edit


func _make_button(text_value: String, size: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(180, 38)
	_apply_font(button, size)
	return button


func _apply_font(control: Control, size: int) -> void:
	if font:
		control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)


func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print("[MENU] ", message)


func _on_gdsync_connected() -> void:
	gd_sync_connected = true
	_set_status("Connected. Checking account session...")
	_set_buttons_enabled(true)

	# Restore a previous session when possible.
	if not GDSync.account_is_logged_in():
		var response: int = await GDSync.account_login_from_session(SESSION_VALID_TIME)
		if response == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
			logged_in = true
			_show_lobby()
			return

	_set_status("Log in or create an account.")


func _on_connection_failed(error: int) -> void:
	gd_sync_connected = false
	busy = false
	_set_buttons_enabled(false)
	_set_status("GD-Sync connection failed: %s" % _get_connection_error_name(error))


func _set_buttons_enabled(enabled: bool) -> void:
	for button in [register_account_button, login_account_button, create_lobby_button, join_lobby_button]:
		if is_instance_valid(button):
			button.disabled = not enabled or busy


func _register_account() -> void:
	if busy:
		return

	if not gd_sync_connected:
		_set_status("Still connecting to GD-Sync...")
		return

	var email := email_edit.text.strip_edges()
	var account_username := account_username_edit.text.strip_edges()
	var account_password := account_password_edit.text

	if email.is_empty() or account_username.is_empty() or account_password.is_empty():
		_set_status("Fill in email, username, and password.")
		return

	busy = true
	_set_buttons_enabled(false)
	_set_status("Creating account...")

	var code: int = await GDSync.account_create(email, account_username, account_password)
	if code == ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.SUCCESS:
		_set_status("Account created! Logging in...")
		await _login_with_credentials(email, account_password)
	else:
		busy = false
		_set_buttons_enabled(true)
		_set_status(_account_creation_error(code))


func _login_account() -> void:
	if busy:
		return

	if not gd_sync_connected:
		_set_status("Still connecting to GD-Sync...")
		return

	var email := email_edit.text.strip_edges()
	var account_password := account_password_edit.text
	if email.is_empty() or account_password.is_empty():
		_set_status("Enter your email and password.")
		return

	busy = true
	_set_buttons_enabled(false)
	_set_status("Logging in...")
	await _login_with_credentials(email, account_password)


func _login_with_credentials(email: String, account_password: String) -> void:
	var response: Dictionary = await GDSync.account_login(email, account_password, SESSION_VALID_TIME)
	var code := int(response.get("Code", -1))

	if code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		logged_in = true
		var account_name := logged_account_username
		if account_name.is_empty():
			account_name = account_username_edit.text.strip_edges()
		GDSync.player_set_username(account_name)
		get_tree().set_meta("player_username", account_name)
		get_tree().set_meta("account_email", email)
		busy = false
		_show_lobby()
	else:
		busy = false
		_set_buttons_enabled(true)
		_set_status(_account_login_error(response))


func _on_account_logged_in(account_name: String) -> void:
	logged_account_username = account_name
	if gd_sync_connected:
		GDSync.player_set_username(account_name)
		get_tree().set_meta("player_username", account_name)


func _on_account_logged_out() -> void:
	logged_account_username = ""


func _show_lobby() -> void:
	auth_panel.hide()
	lobby_panel.show()
	_set_buttons_enabled(true)
	_set_status("Logged in. Choose a lobby.")


func _logout() -> void:
	if GDSync.account_is_logged_in():
		await GDSync.account_logout()
	logged_in = false
	get_tree().set_meta("player_username", "")
	lobby_panel.hide()
	auth_panel.show()
	_set_buttons_enabled(true)
	_set_status("Logged out.")


func _get_lobby_name() -> String:
	var lobby := lobby_edit.text.strip_edges()
	return DEFAULT_LOBBY if lobby.is_empty() else lobby


func _on_create_lobby_pressed() -> void:
	if busy or not logged_in:
		return

	var lobby_name := _get_lobby_name()
	if lobby_name.length() < 3 or lobby_name.length() > 32:
		_set_status("Lobby name must be 3-32 characters.")
		return

	busy = true
	_set_buttons_enabled(false)
	_set_status("Creating lobby...")
	GDSync.lobby_create(lobby_name, "", true, 8, {"Game": "BFDI"})


func _on_join_lobby_pressed() -> void:
	if busy or not logged_in:
		return

	var lobby_name := _get_lobby_name()
	if lobby_name.length() < 3 or lobby_name.length() > 32:
		_set_status("Lobby name must be 3-32 characters.")
		return

	busy = true
	_set_buttons_enabled(false)
	_set_status("Joining lobby...")
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_created(lobby_name: String) -> void:
	print("GD-Sync lobby created: ", lobby_name)
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_creation_failed(lobby_name: String, error: int) -> void:
	print("GD-Sync lobby creation failed: ", lobby_name, " error=", error)
	if error == ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
		GDSync.lobby_join(lobby_name, "")
		return

	busy = false
	_set_buttons_enabled(true)
	_set_status("Could not create lobby (error %s)." % error)


func _on_lobby_joined(lobby_name: String) -> void:
	print("GD-Sync lobby joined: ", lobby_name)
	get_tree().set_meta("lobby_name", lobby_name)
	busy = false
	get_tree().change_scene_to_file("res://character_select.tscn")


func _on_lobby_join_failed(lobby_name: String, error: int) -> void:
	busy = false
	_set_buttons_enabled(true)
	_set_status("Could not join lobby (error %s)." % error)


func _account_creation_error(code: int) -> String:
	var table := {
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.EMAIL_ALREADY_EXISTS: "That email already has an account.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.USERNAME_ALREADY_EXISTS: "That username is already taken.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.INVALID_EMAIL: "That email is invalid.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.INVALID_USERNAME: "That username is invalid.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.PASSWORD_TOO_SHORT: "Password is too short.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.PASSWORD_TOO_LONG: "Password is too long.",
		ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.NO_DATABASE: "GD-Sync has no database linked to this API key.",
	}
	return str(table.get(code, "Account creation failed (code %s)." % code))


func _account_login_error(response: Dictionary) -> String:
	var code := int(response.get("Code", -1))
	if code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.BANNED:
		return "This account is currently unavailable."
	if code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.NO_DATABASE:
		return "GD-Sync has no database linked to this API key."
	if code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.EMAIL_OR_PASSWORD_INCORRECT:
		return "Email or password is incorrect."
	return "Login failed (code %s)." % code


func _get_connection_error_name(error: int) -> String:
	for key in ENUMS.CONNECTION_FAILED.keys():
		if ENUMS.CONNECTION_FAILED[key] == error:
			return key
	return "(unknown)"
