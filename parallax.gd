
extends ParallaxLayer

@export var auto_speed: = Vector2(200.0, 0.0)
@export var bottom_offset_px: = 200.0
@export var bleed_px: = 2.0
@export var snap_to_pixels: = true

var _last_screen: = Vector2.ZERO
var _last_zoom: = Vector2.ONE

func _ready() -> void :
	var spr: = $Mountain
	spr.centered = false



	get_viewport().size_changed.connect(_layout_band)
	_layout_band()

func _process(dt: float) -> void :

	motion_offset += auto_speed * motion_scale * dt


	var cam: = get_viewport().get_camera_2d()
	var zoom: = Vector2.ONE
	if cam and not _is_in_canvas_layer():
		zoom = cam.zoom

	var screen: = get_viewport_rect().size
	if screen != _last_screen or zoom != _last_zoom:
		_layout_band()
		_last_screen = screen
		_last_zoom = zoom

	if snap_to_pixels:
		position = position.floor()

func _layout_band() -> void :
	var spr: = $Mountain
	if spr.texture == null:
		return


	var screen: = get_viewport_rect().size
	var cam: = get_viewport().get_camera_2d()
	var zoom: = Vector2.ONE
	if cam and not _is_in_canvas_layer():
		zoom = cam.zoom
	var visible: = Vector2(screen.x * zoom.x, screen.y * zoom.y)


	var target_w = ceil(visible.x + 2.0 * bleed_px)
	var target_h = ceil(visible.y + 2.0 * bleed_px)

	var tex_size = spr.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return


	var s = max(target_w / tex_size.x, target_h / tex_size.y)
	if s <= 0.0:
		s = 1.0
	spr.scale = Vector2(s, s)


	var drawn_w = ceil(tex_size.x * spr.scale.x)
	var drawn_h = ceil(tex_size.y * spr.scale.y)




	spr.position.x = - bleed_px
	spr.position.y = - bleed_px + (visible.y - drawn_h) + bottom_offset_px


	motion_mirroring = Vector2(drawn_w, 0.0)

func _is_in_canvas_layer() -> bool:
	var n: Node = self
	while n:
		if n is CanvasLayer:
			return true
		n = n.get_parent()
	return false
