extends Control
class_name WheelMenu

@export var title_font_size: = 22
const BTN_SIZE: = Vector2(180, 36)


@export var bg_color: Color = Color(0, 0, 0, 0.65)
@export var panel_outline: Color = Color(1, 1, 1, 0.25)
@export var title_color: Color = Color8(255, 153, 1)
@export var title_text: String = "The Prize Wheel"

@export var panel_pad: = Vector2(18, 18)
@export var panel_width: = 520.0
@export var panel_height: = 420.0

@export var random_loot_min: = 1
@export var random_loot_max: = 20

@export var test_mode_no_ads: = false

@export var lucky_block_item_id: = 70
@export var lucky_blocks_min: = 1
@export var lucky_blocks_max: = 20

func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p
	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null

class ConfettiOverlay:
	extends Control
	var wm: WheelMenu

	func _ready():
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw():
		if wm:
			wm._draw_confetti_on(self)

func _ads_ok() -> bool:
	return test_mode_no_ads or ((typeof(AdManager) != TYPE_NIL) and AdManager.is_reward_ready())

func _grant_spins_bundle() -> void :
	drag_unlocked = true
	if spins_left <= 0:
		spins_left = SPINS_PER_AD
	queue_redraw()

const TITLE_FONT: = preload("res://Shag-Lounge.otf")


const CLOSE_SIZE: = Vector2(28, 28)
const CLOSE_GAP: = Vector2(10, 0)
const BTN_GAP: = 12.0

var spins_left: = 0
const SPINS_PER_AD: = 5

var last_winner: String = ""
var repeat_btn_visible: = false
var pending_repeat: = false


var _ad_mode: = ""


var _repeat_btn_rect: = Rect2()


@onready var wheel: Node2D = $Wheel
@onready var ticker: AnimatedSprite2D = $Ticker
@onready var spinning_sound: AudioStreamPlayer = $SpinningSound
@onready var confetti_sound: AudioStreamPlayer = $ConfettiSound

var ad_loading: = false
var ad_fail_count: = 0
const AD_FAIL_THRESHOLD: = 3

var _confetti_overlay: ConfettiOverlay = null

const CONFETTI_COUNT: = 40
const CONFETTI_LIFETIME: = 1.25
const CONFETTI_MIN_SPEED: = 220.0
const CONFETTI_MAX_SPEED: = 560.0
const CONFETTI_GRAVITY: = 980.0
const CONFETTI_DRAG: = 0.98
const CONFETTI_MIN_SIZE: = Vector2(4, 7)
const CONFETTI_MAX_SIZE: = Vector2(9, 14)
var _confetti: = []


var WHEEL_FONT: Font = null
var entries: Array = []
var radius: = 140


var spin_time: = 7.5
var spinning: = false
var time_elapsed: = 0.0
var angular_velocity: = 0.0
var start_ang_vel_range: = Vector2(23.0, 29.0)
var final_rotation: = 0.0


var dragging: = false
var last_mouse_angle: = 0.0
var velocity_samples: Array[float] = []
const MAX_SAMPLES: = 5
const DRAG_SPIN_THRESHOLD: = 12.0


var drag_unlocked: = false


var ad_ready: = false
var ad_consumed: = false


var _panel_rect: = Rect2()
var _btn_rect: = Rect2()
var _close_rect: = Rect2()


func _world() -> Node: return get_tree().get_first_node_in_group("world")
func _player() -> Node:
	return _get_local_player()
func _hotbar(): return get_tree().get_first_node_in_group("hotbar")
func _inventory(): return get_tree().get_first_node_in_group("inventory")


func _ready() -> void :
	visible = false
	set_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	add_to_group("wheel_menu")


	var maybe_font = load("res://Helvetica-Neue-LT-Com-55-Roman.ttf")
	if maybe_font is Font:
		WHEEL_FONT = maybe_font
	else:
		var sf: = SystemFont.new()
		sf.font_names = PackedStringArray(["Arial", "Liberation Sans", "Noto Sans"])
		WHEEL_FONT = sf

	_load_entries()
	_rebuild_wheel()

	if Engine.has_singleton("AdManager") or (typeof(AdManager) != TYPE_NIL):

		AdManager.connect("rewarded_ready", Callable(self, "_on_rewarded_ready"))
		AdManager.connect("rewarded_failed", Callable(self, "_on_rewarded_failed"))
		AdManager.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))
		AdManager.connect("rewarded_granted", Callable(self, "_on_rewarded_granted"))


		if not AdManager.is_reward_ready():
			ad_loading = true
			AdManager._ensure_reward_loaded()

	_confetti_overlay = ConfettiOverlay.new()
	_confetti_overlay.name = "ConfettiOverlay"
	_confetti_overlay.wm = self
	_confetti_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confetti_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confetti_overlay.z_as_relative = true
	_confetti_overlay.z_index = 9999
	add_child(_confetti_overlay)
	move_child(_confetti_overlay, get_child_count() - 1)

	queue_redraw()

func _draw_confetti() -> void :
	if is_instance_valid(_confetti_overlay):
		_confetti_overlay.queue_redraw()

func _random_item_id() -> int:
	var EXCLUDE: = {69: true}


	var w: = _world()
	if w and w.has_method("name_map_for_hotbar"):
		var m: Dictionary = w.name_map_for_hotbar()
		var ids: Array[int] = []
		for k in m.keys():
			var id: = int(k)
			if not EXCLUDE.has(id):
				ids.append(id)
		if ids.size() > 0:
			return ids[randi() % ids.size()]


	var id: = 69
	while id == 69:
		id = 1 + (randi() % 20)
	return id

func _give_like_pickup(item_id: int, amount: int) -> int:
	var left: = amount
	var hb = _hotbar()
	if hb and hb.has_method("try_add"):
		left = int(hb.try_add(item_id, left))
	var inv = _inventory()
	if left > 0 and inv and inv.has_method("try_add"):
		left = int(inv.try_add(item_id, left))
	if hb: hb.queue_redraw()
	if inv and inv.has_method("queue_redraw"): inv.queue_redraw()
	return left

func toggle_visible() -> void :
	var is_pc: = OS.get_name() in ["Windows", "Linux", "macOS"]
	if is_pc and not test_mode_no_ads:
		return
	var want: = not visible


	if want:
		var inv: = get_tree().get_first_node_in_group("inventory")
		if inv and inv.visible:
			inv.toggle_visible()

		var craft: = get_tree().get_first_node_in_group("crafting")
		if craft and craft.visible:
			craft.toggle_visible()

		var oven: = get_tree().get_first_node_in_group("oven")
		if oven and oven.visible:
			oven.toggle_visible()

	visible = want
	if visible:
		top_level = true
		z_index = 1000
		grab_focus()
	else:
		top_level = false
		release_focus()

	dragging = false
	velocity_samples.clear()


	var lp: = _get_local_player()
	if lp and lp.has_method("set_input_enabled"):
		lp.call("set_input_enabled", not visible)

	if ticker:
		if visible:
			ticker.visible = true
			ticker.speed_scale = 1.0
			if not spinning:
				ticker.play("default")
		else:
			if spinning_sound and spinning_sound.playing:
				spinning_sound.stop()
			spinning = false
			time_elapsed = 0.0
			angular_velocity = 0.0
			ticker.stop()
			ticker.visible = false


	drag_unlocked = false
	ad_ready = false
	ad_consumed = false
	spins_left = 0

	if not want:

		repeat_btn_visible = false
		last_winner = ""
		pending_repeat = false
		_ad_mode = ""

	queue_redraw()

func is_open() -> bool: return visible


func _load_entries() -> void :
	entries.clear()

	var pool: = [
		"Nothing", 
		"Add Health", 
		"Add Hunger", 
		"Random Loot", 
		"Lucky Blocks"
	]

	var total_slots: = randi_range(6, 18)
	for i in total_slots:
		var pick = pool[randi() % pool.size()]
		entries.append(pick)

	entries.shuffle()

func _rebuild_wheel() -> void :
	for c in wheel.get_children():
		c.queue_free()

	var count = max(1, entries.size())
	var angle_per: = TAU / float(count)
	var hue: = Color("#E08080").h

	for i in range(count):
		var start_angle: = angle_per * i
		var end_angle: = angle_per * (i + 1)

		var poly: = Polygon2D.new()
		var pts: = PackedVector2Array([Vector2.ZERO])
		for a in range(31):
			var t = lerp(start_angle, end_angle, a / 30.0)
			pts.append(Vector2(cos(t), sin(t)) * radius)
		poly.polygon = pts
		poly.color = Color.from_hsv(fmod(hue + i * 0.0555, 1.0), 0.5, 1.0)
		wheel.add_child(poly)

		if count > 1:
			var line: = Line2D.new()
			line.width = 3
			line.default_color = Color.BLACK
			line.add_point(Vector2.ZERO)
			line.add_point(Vector2(cos(start_angle), sin(start_angle)) * radius)
			line.z_index = 1
			wheel.add_child(line)

		var label: = Label.new()
		label.text = entries[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.modulate = Color.BLACK
		label.add_theme_font_override("font", WHEEL_FONT)
		var mid: = start_angle + angle_per * 0.5
		var dir: = Vector2(cos(mid), sin(mid))
		var arc_dist: = radius * 0.98
		label.position = dir * arc_dist
		label.rotation = mid + PI

		var text_size: = label.get_minimum_size()
		var inner_limit = radius * (0.1 + 0.2 * (count / 36.0))
		var avail = arc_dist - inner_limit
		var k = (avail / text_size.x) if text_size.x > 0 else 1.0

		var min_scale: = 0.15
		var max_scale: = 1.0
		k = clamp(k, min_scale, max_scale)
		label.scale = Vector2(k, k)
		var sh = text_size.y * k
		label.position -= dir.orthogonal().normalized() * (sh / 2.0)
		wheel.add_child(label)

	var ring: = Line2D.new()
	ring.width = 3
	ring.default_color = Color.BLACK
	for i in range(129):
		var a: = i * TAU / 128.0
		ring.add_point(Vector2(cos(a), sin(a)) * radius)
	ring.add_point(ring.points[0])
	wheel.add_child(ring)

	_position_wheel()

func _position_wheel() -> void :
	var pr: = _compute_panel_rect()

	radius = clamp(min(pr.size.x, pr.size.y) * 0.35, 80.0, 220.0)
	wheel.position = pr.position + pr.size * 0.5


func _compute_panel_rect() -> Rect2:
	var outer: = Rect2(Vector2.ZERO, size)

	var max_w: = outer.size.x * 0.8
	var max_h: = outer.size.y * 0.8
	var w = min(panel_width, max_w)
	var h = min(panel_height, max_h)
	var pos: = Vector2(floor((outer.size.x - w) / 2.0), floor((outer.size.y - h) / 2.0))
	_panel_rect = Rect2(pos, Vector2(w, h))
	return _panel_rect

func _close_button_rect() -> Rect2:
	var pr: = _compute_panel_rect()
	var pos: = pr.position + Vector2(pr.size.x + CLOSE_GAP.x, - CLOSE_SIZE.y * 0.5 + CLOSE_GAP.y)
	_close_rect = Rect2(pos, CLOSE_SIZE)
	return _close_rect

func _watch_button_rect() -> Rect2:
	var pr: = _compute_panel_rect()
	var y: = pr.position.y + pr.size.y - BTN_SIZE.y - 24.0


	if repeat_btn_visible and last_winner != "":
		var total_w: = BTN_SIZE.x * 2.0 + BTN_GAP
		var start_x: = pr.position.x + (pr.size.x - total_w) * 0.5
		_btn_rect = Rect2(Vector2(start_x, y), BTN_SIZE)
	else:

		var x: = pr.position.x + (pr.size.x - BTN_SIZE.x) * 0.5
		_btn_rect = Rect2(Vector2(x, y), BTN_SIZE)
	return _btn_rect

func _repeat_button_rect() -> Rect2:
	var pr: = _compute_panel_rect()
	var y: = pr.position.y + pr.size.y - BTN_SIZE.y - 24.0


	if repeat_btn_visible and last_winner != "":
		var total_w: = BTN_SIZE.x * 2.0 + BTN_GAP
		var start_x: = pr.position.x + (pr.size.x - total_w) * 0.5
		var right_x: = start_x + BTN_SIZE.x + BTN_GAP
		_repeat_btn_rect = Rect2(Vector2(right_x, y), BTN_SIZE)
	else:

		_repeat_btn_rect = Rect2(Vector2(-9999, -9999), BTN_SIZE)
	return _repeat_btn_rect

func _draw() -> void :
	if not visible: return
	var pr: = _compute_panel_rect()

	draw_rect(pr, bg_color, true)
	draw_rect(pr, panel_outline, false, 2.0)

	var font: Font = (TITLE_FONT if TITLE_FONT != null else get_theme_default_font())
	var tsize: = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)
	var tpos: = Vector2(pr.position.x + (pr.size.x - tsize.x) * 0.5, pr.position.y + font.get_ascent(title_font_size) + 12.0)
	draw_string_outline(font, tpos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, 2, Color(0, 0, 0, 0.85))
	draw_string(font, tpos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, title_color)

	var cr: = _close_button_rect()
	var inside_close: = cr.has_point(get_local_mouse_position())
	var fill: = Color(0.12, 0.12, 0.12, (0.98 if inside_close else 0.95))
	draw_rect(cr, fill, true)
	draw_rect(cr, Color(1, 1, 1, 0.75), false, 2.0)
	var cx: = cr.position + cr.size * 0.5
	draw_line(cx + Vector2(-6, -6), cx + Vector2(6, 6), Color(1, 1, 1, 0.95), 2.0)
	draw_line(cx + Vector2(6, -6), cx + Vector2(-6, 6), Color(1, 1, 1, 0.95), 2.0)


	var br: = _watch_button_rect()
	var inside_btn: = br.has_point(get_local_mouse_position())
	var btn_fill: = Color(0.18, 0.18, 0.18, (0.98 if inside_btn else 0.95))
	var btn_outline: = Color(1, 1, 1, 0.75 if inside_btn else 0.45)
	draw_rect(br, btn_fill, true)
	draw_rect(br, btn_outline, false, 2.0)

	var btn_label: = ""
	if spinning:
		btn_label = "SPINNING..."
	elif drag_unlocked:
		if spins_left > 0:
			btn_label = "DRAG TO SPIN " + str(spins_left) + " LEFT"
		else:
			btn_label = "WATCH AD TO SPIN"
			drag_unlocked = false
	else:
		var ready = _ads_ok()
		var need_manual: = ad_fail_count >= AD_FAIL_THRESHOLD
		if ready:
			btn_label = "WATCH AD TO SPIN"
		elif need_manual:
			btn_label = "LOAD AN AD"
		else:
			btn_label = "AD IS LOADING..."

	var bsize: = font.get_string_size(btn_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	var bl: = Vector2(br.position.x + (br.size.x - bsize.x) / 2.0, br.position.y + (br.size.y + font.get_ascent(20)) * 0.5 - 2.0)
	draw_string_outline(font, bl, btn_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 2, Color(0, 0, 0, 0.85))
	draw_string(font, bl, btn_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.95))


	if repeat_btn_visible and (last_winner != "") and not spinning:
		var rr: = _repeat_button_rect()
		var inside_repeat: = rr.has_point(get_local_mouse_position())
		var rp_fill: = Color(0.18, 0.18, 0.18, (0.98 if inside_repeat else 0.95))
		var rp_outline: = Color(1, 1, 1, 0.75 if inside_repeat else 0.45)
		draw_rect(rr, rp_fill, true)
		draw_rect(rr, rp_outline, false, 2.0)

		var ad_ok: = _ads_ok()
		var label: = "GET AGAIN" if ad_ok else "AD IS LOADING..."
		var rs: = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		var rl: = Vector2(rr.position.x + (rr.size.x - rs.x) / 2.0, rr.position.y + (rr.size.y + font.get_ascent(20)) * 0.5 - 2.0)
		draw_string_outline(font, rl, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 2, Color(0, 0, 0, 0.85))
		draw_string(font, rl, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.95))

	_draw_confetti()


func _input(e: InputEvent) -> void :
	if e.is_action_pressed("toggle_wheel"):
		toggle_visible()
		return
	if e.is_action_pressed("ui_cancel") and visible:
		toggle_visible()

func _on_watch_ad_pressed() -> void :
	if spinning: return


	if test_mode_no_ads:
		_ad_mode = "unlock"
		_grant_spins_bundle()
		return

	if typeof(AdManager) == TYPE_NIL:
		return

	if AdManager.is_reward_ready():
		ad_ready = true
		ad_consumed = false
		drag_unlocked = false
		_ad_mode = "unlock"
		queue_redraw()
		AdManager.show_reward_ad()
	else:
		ad_loading = true
		AdManager._ensure_reward_loaded()
		queue_redraw()

func _on_rewarded_ready() -> void :
	ad_loading = false
	ad_fail_count = 0
	queue_redraw()

func _on_rewarded_failed() -> void :
	ad_loading = false
	ad_fail_count += 1
	_ad_mode = ""
	pending_repeat = false
	queue_redraw()

func _on_rewarded_closed() -> void :
	ad_loading = true
	_ad_mode = ""
	pending_repeat = false

	if _pending_confetti:
		_pending_confetti = false
		_celebrate_confetti()

	queue_redraw()

var _pending_confetti: = false

func _on_rewarded_granted() -> void :
	match _ad_mode:
		"unlock":
			drag_unlocked = true
			spins_left = SPINS_PER_AD
		"repeat":
			if last_winner != "":
				_apply_reward(last_winner)
				_pending_confetti = true
		_:
			drag_unlocked = true
			spins_left = SPINS_PER_AD

	ad_loading = true
	ad_fail_count = 0
	pending_repeat = false
	_ad_mode = ""
	if typeof(AdManager) != TYPE_NIL:
		AdManager._ensure_reward_loaded()
	queue_redraw()



func _begin_spin() -> void :
	if entries.is_empty(): return
	spinning = true
	time_elapsed = 0.0
	angular_velocity = randf_range(start_ang_vel_range.x, start_ang_vel_range.y) * (1 if randi() % 2 == 0 else -1)


	if ticker:
		ticker.visible = true
		ticker.play("spin")
		ticker.speed_scale = 1.0

	if spinning_sound:
		spinning_sound.play()

	queue_redraw()

func _process(dt: float) -> void :
	if not visible: return
	_position_wheel()

	if spinning:
		time_elapsed += dt
		var t = clamp(time_elapsed / spin_time, 0.0, 1.0)
		var eased_vel: = angular_velocity * pow(1.0 - t, 2)
		wheel.rotation += eased_vel * dt
		final_rotation = wheel.rotation

		var transition_duration: = spin_time - 1.875
		if time_elapsed <= transition_duration:
			var tt = clamp(time_elapsed / transition_duration, 0.0, 1.0)
			ticker.speed_scale = lerp(1.0, 0.2, pow(tt, 2))
		else:
			ticker.speed_scale = 0.2

		if time_elapsed >= spin_time:
			spinning = false
			if ticker:
				ticker.play("default")
				ticker.speed_scale = 1.0
			_select_and_award()

	_update_confetti(dt)
	queue_redraw()

func _gui_input(e: InputEvent) -> void :
	if not visible:
		return
	if e is InputEventMouse:
		accept_event()


	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:

		if _close_button_rect().has_point(e.position):
			toggle_visible()
			queue_redraw()
			return


		if _close_button_rect().has_point(e.position):
			toggle_visible()
			queue_redraw()
			return


		if repeat_btn_visible and _repeat_button_rect().has_point(e.position):
			if spinning: return


			if test_mode_no_ads:
				_apply_reward(last_winner)
				_celebrate_confetti()
				queue_redraw()
				return

			var ready = _ads_ok()
			var need_manual: = ad_fail_count >= AD_FAIL_THRESHOLD

			if need_manual:
				ad_loading = true
				ad_fail_count = 0
				_ad_mode = ""
				AdManager.manual_load()
				queue_redraw()
				return

			if ready:
				pending_repeat = true
				_ad_mode = "repeat"
				AdManager.show_reward_ad()
			else:
				ad_loading = true
				_ad_mode = ""
				AdManager._ensure_reward_loaded()
			queue_redraw()
			return


		if _watch_button_rect().has_point(e.position):
			if spinning:
				return
			if drag_unlocked:
				return

			_on_watch_ad_pressed()
			return


		if drag_unlocked:
			var center: = wheel.position
			var r: = float(radius)
			if (e.position - center).length() <= r:
				dragging = true
				last_mouse_angle = _angle_to_wheel(e.position)
				velocity_samples.clear()
				return


	if e is InputEventMouseMotion and dragging and drag_unlocked and not spinning:
		var current_angle: = _angle_to_wheel(e.position)
		var angle_diff: = current_angle - last_mouse_angle
		if angle_diff > PI: angle_diff -= TAU
		elif angle_diff < - PI: angle_diff += TAU

		wheel.rotation += angle_diff

		var dt = max(1.0 / 240.0, get_process_delta_time())
		var vel = angle_diff / dt
		velocity_samples.append(vel)
		if velocity_samples.size() > MAX_SAMPLES:
			velocity_samples.remove_at(0)

		last_mouse_angle = current_angle
		return


	if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if dragging:
			dragging = false
			if drag_unlocked and not spinning:
				var total: = 0.0
				for v in velocity_samples: total += v
				var avg = (total / max(1, velocity_samples.size()))
				angular_velocity = avg
				velocity_samples.clear()
				if abs(angular_velocity) >= DRAG_SPIN_THRESHOLD:
					_begin_spin()
				else:

					angular_velocity = 0.0
			return

func _angle_to_wheel(p: Vector2) -> float:

	var center: = wheel.position
	var v: = p - center
	if v.length() < 0.001:
		return last_mouse_angle
	return atan2(v.y, v.x)

func _select_and_award() -> void :
	var count = max(1, entries.size())
	var angle_per: = TAU / float(count)
	var norm: = fposmod(final_rotation, TAU)
	var ticker_angle: = 3.0 * PI / 2.0
	var rel: = fposmod(norm - ticker_angle, TAU)
	var index = count - 1 - int(rel / angle_per)
	index = clamp(index, 0, count - 1)

	var winner = entries[index]
	_play_ticker_stop()
	_apply_reward(winner)


	if spins_left > 0:
		spins_left -= 1

	if spins_left <= 0:
		drag_unlocked = false
		ad_ready = false
		ad_consumed = false

	last_winner = winner
	repeat_btn_visible = (winner != "Nothing")

	_celebrate_confetti()

	queue_redraw()

func _play_ticker_stop() -> void :
	if spinning_sound.playing:
		spinning_sound.stop()

func _celebrate_confetti() -> void :

	if confetti_sound:
		confetti_sound.play()

	_spawn_confetti_burst()
	queue_redraw()

func _spawn_confetti_burst() -> void :
	var pr: = _compute_panel_rect()
	var origin: = pr.position + pr.size * 0.5

	for i in CONFETTI_COUNT:
		var dir: = randf() * TAU
		var spd: = randf_range(CONFETTI_MIN_SPEED, CONFETTI_MAX_SPEED)
		var vel: = Vector2(cos(dir), sin(dir)) * spd

		var ang: = randf_range(-9.0, 9.0)
		var rot: = randf() * TAU


		var hue: = fmod(float(i) / float(max(1, CONFETTI_COUNT)) + randf() * 0.2, 1.0)
		var col: = Color.from_hsv(hue, 0.8, 1.0, 1.0)

		var sz: = Vector2(
			randf_range(CONFETTI_MIN_SIZE.x, CONFETTI_MAX_SIZE.x), 
			randf_range(CONFETTI_MIN_SIZE.y, CONFETTI_MAX_SIZE.y)
		)

		_confetti.append({
			"pos": origin, 
			"vel": vel, 
			"rot": rot, 
			"ang": ang, 
			"life": CONFETTI_LIFETIME, 
			"col": col, 
			"size": sz
		})

func _update_confetti(dt: float) -> void :
	if _confetti.is_empty(): return
	var drag_factor: = pow(CONFETTI_DRAG, dt)
	for i in range(_confetti.size() - 1, -1, -1):
		var c = _confetti[i]

		c.vel.y += CONFETTI_GRAVITY * dt
		c.vel *= drag_factor
		c.pos += c.vel * dt
		c.rot += c.ang * dt
		c.life -= dt
		_confetti[i] = c
		if c.life <= 0.0:
			_confetti.remove_at(i)

	if is_instance_valid(_confetti_overlay):
		_confetti_overlay.queue_redraw()

func _draw_confetti_on(canvas: CanvasItem) -> void :
	for c in _confetti:
		var a = clamp(c.life / CONFETTI_LIFETIME, 0.0, 1.0)
		var col: = Color(c.col.r, c.col.g, c.col.b, a)

		var s = c.size * (0.85 + 0.25 * a)
		var hx = s.x * 0.5
		var hy = s.y * 0.5
		var cosr: = cos(c.rot)
		var sinr: = sin(c.rot)

		var p0 = c.pos + Vector2( - hx * cosr + - hy * - sinr, - hx * sinr + - hy * cosr)
		var p1 = c.pos + Vector2(hx * cosr + - hy * - sinr, hx * sinr + - hy * cosr)
		var p2 = c.pos + Vector2(hx * cosr + hy * - sinr, hx * sinr + hy * cosr)
		var p3 = c.pos + Vector2( - hx * cosr + hy * - sinr, - hx * sinr + hy * cosr)

		canvas.draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), col)


func _apply_reward(s: String) -> void :
	match s:
		"Add Health":
			var p = _player()
			if p:
				var heal_amt: = randi_range(1, 4)
				var new_hp = min(10, int(p.health) + heal_amt)
				p.cli_apply_stats({"health": new_hp})
				_notify("Healed +" + str(heal_amt) + " ♥")

		"Add Hunger":
			var p = _player()
			if p:
				var add_hunger: = randi_range(1, 5)
				var current_h: = int(p.hunger)
				var current_s: = float(p.saturation)

				var total: = current_h + add_hunger
				var new_h = min(10, total)
				var overflow = max(0, total - 10)
				var new_s: = current_s + float(overflow)

				p.cli_apply_stats({
					"hunger": new_h, 
					"saturation": new_s
				})

				if overflow > 0:
					_notify("You ate well: +" + str(add_hunger) + " hunger (overflow +" + str(overflow) + " sat).")
				else:
					_notify("You ate: +" + str(add_hunger) + " hunger.")

		"Random Loot":
			var id: = _random_item_id()
			var n: = randi_range(random_loot_min, random_loot_max)
			var leftover: = _give_like_pickup(id, n)

			var label: = "item"
			var w: = _world()
			if w and w.has_method("name_map_for_hotbar"):
				var nm: Dictionary = w.name_map_for_hotbar()
				if nm.has(id):
					label = String(nm[id])

			if leftover <= 0:
				_notify("You received %d × %s!" % [n, label])
			else:
				var got: = n - leftover
				_notify("Inventory full! You only received %d/%d × %s." % [got, n, label])
		"Lucky Blocks":
			var n: = randi_range(lucky_blocks_min, lucky_blocks_max)
			var leftover: = _give_like_pickup(lucky_block_item_id, n)

			var label: = "Lucky Block"
			var w: = _world()
			if w and w.has_method("name_map_for_hotbar"):
				var nm: Dictionary = w.name_map_for_hotbar()
				if nm.has(lucky_block_item_id):
					label = String(nm[lucky_block_item_id])

			if leftover <= 0:
				_notify("You received %d × %s!" % [n, label])
			else:
				var got: = n - leftover
				_notify("Inventory full! You only received %d/%d × %s." % [got, n, label])
		_:
			_notify("Nothing happens.")


func _notify(msg: String) -> void :
	print("[WHEEL]", msg)

func _notification(what):
	if what == NOTIFICATION_RESIZED:

		_position_wheel()
		_rebuild_wheel()
		queue_redraw()


func _on_prize_btn_pressed() -> void :
	toggle_visible()
