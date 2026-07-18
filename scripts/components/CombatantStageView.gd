class_name CombatantStageView
extends Control

# Figure-only battlefield view. Visible alpha bounds are normalized to a shared ground line.

signal figure_ready

const STANDARD_TARGET_SIZE := Vector2(280, 290)
const COMPACT_TARGET_SIZE := Vector2(240, 250)
const BOSS_TARGET_SIZE := Vector2(340, 330)
const ALPHA_THRESHOLD := 0.12
const SHADOW_WIDTH_RATIO := 0.62
const SHADOW_OPACITY := 0.30
const SHADOW_HEIGHT := 28.0

const GRADE_ACTIVE := Color(0.98, 0.99, 1.05, 1.0)
const GRADE_IDLE := Color(0.84, 0.86, 0.92, 1.0)
const GRADE_ENEMY := Color(0.90, 0.92, 0.98, 1.0)

static var _opaque_bounds_cache: Dictionary = {}
static var _display_texture_cache: Dictionary = {}

@export var is_player_side: bool = true

var reduced_motion: bool = false
var is_active: bool = false:
	set(value):
		is_active = value
		_update_active_visual()
var _compact: bool = false
var _boss_scale: bool = false
var _opaque_bounds := Rect2()
var _draw_scale: float = 1.0
var _soft_ellipse_texture: Texture2D = null

@onready var figure_stack: Control = $FigureStack
@onready var figure: TextureRect = $FigureStack/Figure
@onready var contact_shadow: TextureRect = $FigureStack/ContactShadow
@onready var foot_mist: TextureRect = $FigureStack/FootMist


func _ready() -> void:
	clip_contents = false
	_setup_ground_effects()
	_layout_on_ground()
	_update_active_visual()
	figure_ready.emit()
	call_deferred("_layout_on_ground")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_on_ground()


func get_figure_node() -> CanvasItem:
	return figure


func get_visible_figure_rect() -> Rect2:
	if figure == null or figure.texture == null or _opaque_bounds.size == Vector2.ZERO:
		return Rect2()
	return Rect2(
		figure.global_position + _opaque_bounds.position * _draw_scale,
		_opaque_bounds.size * _draw_scale,
	)


func get_ground_contact_y() -> float:
	var visible_rect := get_visible_figure_rect()
	if visible_rect.size == Vector2.ZERO:
		return global_position.y + size.y
	return visible_rect.position.y + visible_rect.size.y


func set_figure_texture(texture: Texture2D) -> void:
	figure.texture = _prepare_display_texture(texture)
	_layout_on_ground()
	call_deferred("_layout_on_ground")


func set_compact_layout(enabled: bool) -> void:
	_compact = enabled
	custom_minimum_size = Vector2(250, 300) if enabled else Vector2(300, 360)
	_layout_on_ground()


func set_boss_scale(enabled: bool) -> void:
	_boss_scale = enabled
	_layout_on_ground()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled


func _layout_on_ground() -> void:
	if figure == null or figure_stack == null:
		return
	var texture := figure.texture
	if texture == null:
		return
	var texture_size := texture.get_size()
	if texture_size.x < 1.0 or texture_size.y < 1.0:
		return
	_opaque_bounds = _get_opaque_bounds(texture)
	var target_size := _get_target_size()
	_draw_scale = minf(
		target_size.x / maxf(1.0, _opaque_bounds.size.x),
		target_size.y / maxf(1.0, _opaque_bounds.size.y),
	)
	var draw_size := texture_size * _draw_scale
	var opaque_center_x := (_opaque_bounds.position.x + _opaque_bounds.size.x * 0.5) * _draw_scale
	var opaque_bottom_y := (_opaque_bounds.position.y + _opaque_bounds.size.y) * _draw_scale
	var left := -opaque_center_x
	var top := -opaque_bottom_y

	figure.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	figure.offset_left = left
	figure.offset_right = left + draw_size.x
	figure.offset_top = top
	figure.offset_bottom = top + draw_size.y
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_SCALE
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_ground_effects()


func _get_target_size() -> Vector2:
	if _boss_scale:
		return BOSS_TARGET_SIZE
	if _compact:
		return COMPACT_TARGET_SIZE
	return STANDARD_TARGET_SIZE


func _get_opaque_bounds(texture: Texture2D) -> Rect2:
	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = "instance:%d" % texture.get_instance_id()
	if _opaque_bounds_cache.has(cache_key):
		return _opaque_bounds_cache[cache_key]
	var image := texture.get_image()
	if image == null:
		var fallback := Rect2(Vector2.ZERO, texture.get_size())
		_opaque_bounds_cache[cache_key] = fallback
		return fallback
	if image.is_compressed():
		image = image.duplicate()
		image.decompress()
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a < ALPHA_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	var bounds := Rect2(Vector2.ZERO, texture.get_size())
	if max_x >= min_x and max_y >= min_y:
		bounds = Rect2(
			Vector2(min_x, min_y),
			Vector2(max_x - min_x + 1, max_y - min_y + 1),
		)
	_opaque_bounds_cache[cache_key] = bounds
	return bounds


func _prepare_display_texture(texture: Texture2D) -> Texture2D:
	if texture == null or texture.resource_path != "res://assets/final_boss.png":
		return texture
	if _display_texture_cache.has(texture.resource_path):
		return _display_texture_cache[texture.resource_path]
	var image := texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image = image.duplicate()
		image.decompress()
	else:
		image = image.duplicate()
	_strip_corner_component(image)
	var cleaned := ImageTexture.create_from_image(image)
	_display_texture_cache[texture.resource_path] = cleaned
	return cleaned


func _strip_corner_component(image: Image) -> void:
	# The legacy final-boss cutout contains a disconnected translucent plate at (0, 0).
	# Flood only that alpha island so the connected character, weapon, and smoke remain intact.
	var pending: Array[Vector2i] = [Vector2i.ZERO]
	var width := image.get_width()
	var height := image.get_height()
	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			continue
		var color := image.get_pixelv(point)
		if color.a <= 0.0:
			continue
		color.a = 0.0
		image.set_pixelv(point, color)
		pending.append(point + Vector2i.LEFT)
		pending.append(point + Vector2i.RIGHT)
		pending.append(point + Vector2i.UP)
		pending.append(point + Vector2i.DOWN)


func _setup_ground_effects() -> void:
	if _soft_ellipse_texture == null:
		_soft_ellipse_texture = _make_soft_ellipse_texture(128, 48)
	contact_shadow.texture = _soft_ellipse_texture
	contact_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	contact_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	contact_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contact_shadow.modulate = Color(0.08, 0.10, 0.16, SHADOW_OPACITY)
	contact_shadow.z_index = -1
	foot_mist.texture = _soft_ellipse_texture
	foot_mist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot_mist.stretch_mode = TextureRect.STRETCH_SCALE
	foot_mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot_mist.modulate = Color(0.55, 0.62, 0.72, 0.18)
	foot_mist.z_index = 1


func _layout_ground_effects() -> void:
	var visible_width := _opaque_bounds.size.x * _draw_scale
	var shadow_width := clampf(visible_width * SHADOW_WIDTH_RATIO, 110.0, 230.0)
	contact_shadow.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	contact_shadow.offset_left = -shadow_width * 0.5
	contact_shadow.offset_right = shadow_width * 0.5
	contact_shadow.offset_top = -SHADOW_HEIGHT * 0.55
	contact_shadow.offset_bottom = SHADOW_HEIGHT * 0.45
	var mist_width := clampf(visible_width * 0.88, 130.0, 260.0)
	foot_mist.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	foot_mist.offset_left = -mist_width * 0.5
	foot_mist.offset_right = mist_width * 0.5
	foot_mist.offset_top = -34.0
	foot_mist.offset_bottom = 8.0


func _make_soft_ellipse_texture(width: int, height: int) -> Texture2D:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center_x := (width - 1) * 0.5
	var center_y := (height - 1) * 0.5
	var radius_x := maxf(1.0, width * 0.5)
	var radius_y := maxf(1.0, height * 0.5)
	for y in range(height):
		for x in range(width):
			var normalized_x: float = (x - center_x) / radius_x
			var normalized_y: float = (y - center_y) / radius_y
			var distance: float = sqrt(normalized_x * normalized_x + normalized_y * normalized_y)
			if distance >= 1.0:
				continue
			var alpha: float = 1.0 - distance
			alpha = pow(alpha * alpha * (3.0 - 2.0 * alpha), 1.35)
			if alpha > 0.004:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _update_active_visual() -> void:
	if figure == null:
		return
	if is_player_side:
		figure.modulate = GRADE_ACTIVE if is_active else GRADE_IDLE
		return
	figure.modulate = GRADE_ENEMY.lightened(0.07) if is_active else GRADE_ENEMY.darkened(0.06)
