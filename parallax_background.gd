extends ParallaxBackground

@export var overscan: = 1.25
@export var pin_from_bottom_px: = 0
@onready var mountain: Sprite2D = $Far / Mountain
@onready var redwood_tree: Sprite2D = $Far / RedwoodTreeLayer
@onready var yoyle: Sprite2D = $Far / Yoyle
@onready var mountain2: Sprite2D = $Near / Mountain
@onready var redwood_tree2: Sprite2D = $Near / RedwoodTreeLayer
@onready var yoyle2: Sprite2D = $Near / Yoyle

func _ready() -> void :
	add_to_group("parallax_biome")
	_setup_layers()
	get_viewport().size_changed.connect(_setup_layers)

func _setup_layers() -> void :
	var vp: = get_viewport().get_visible_rect().size

	for layer in get_children():
		if !(layer is ParallaxLayer):
			continue
		for node in layer.get_children():
			if !(node is Sprite2D):
				continue

			var spr: = node as Sprite2D
			if spr.texture == null:
				continue

			spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			spr.centered = true

			var tex_size: = spr.texture.get_size()
			var sx: = (vp.x * overscan) / tex_size.x
			var sy: = (vp.y * overscan) / tex_size.y
			var scale = max(sx, sy)
			spr.scale = Vector2(scale, scale)

			var scaled_w = tex_size.x * scale
			var scaled_h = tex_size.y * scale
			layer.motion_mirroring = Vector2(scaled_w, 0.0)

			if pin_from_bottom_px != 0:
				spr.position.y = (vp.y * 0.5) + (vp.y * 0.5 - pin_from_bottom_px)

			spr.z_as_relative = false
			spr.z_index = -100

var _biome_flip_tween: Tween
var _redwoods_enabled: = false
var _yoyle_enabled: = false



func set_redwoods_enabled(on: bool, instant: bool = false) -> void :
	if _redwoods_enabled == on:
		return
	_redwoods_enabled = on
	_apply_biome_layers(instant)

func set_yoyle_enabled(on: bool, instant: bool = false) -> void :
	if _yoyle_enabled == on:
		return
	_yoyle_enabled = on
	_apply_biome_layers(instant)



func _apply_biome_layers(instant: bool) -> void :
	if _biome_flip_tween and _biome_flip_tween.is_running():
		_biome_flip_tween.kill()

	var want_mountains: = ( not _redwoods_enabled) and ( not _yoyle_enabled)
	var targets: = []


	for m in [mountain, mountain2]:
		if m:
			targets.append([m, (1.0 if want_mountains else 0.0)])


	for r in [redwood_tree, redwood_tree2]:
		if r:
			targets.append([r, (1.0 if _redwoods_enabled else 0.0)])


	for y in [yoyle, yoyle2]:
		if y:
			targets.append([y, (1.0 if _yoyle_enabled else 0.0)])

	if instant:
		for pair in targets:
			var spr: Sprite2D = pair[0]
			var a: float = pair[1]
			var c: = spr.modulate
			spr.modulate = Color(c.r, c.g, c.b, a)
		return

	_biome_flip_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for pair in targets:
		var spr: Sprite2D = pair[0]
		var a: float = pair[1]
		_biome_flip_tween.tween_property(spr, "modulate:a", a, 0.35)


func set_brightness_factor(a: float) -> void :
	var night_v: = 148.0 / 255.0
	var day_v: = 1.0
	var v = lerp(night_v, day_v, a)


	for r in [redwood_tree, redwood_tree2]:
		if r:
			var c = r.modulate
			r.modulate = Color(v, v, v, c.a)


	for y in [yoyle, yoyle2]:
		if y:
			var c = y.modulate
			y.modulate = Color(v, v, v, c.a)


	for m in [mountain, mountain2]:
		if m:
			var c = m.modulate
			m.modulate = Color(v, v, v, c.a)
