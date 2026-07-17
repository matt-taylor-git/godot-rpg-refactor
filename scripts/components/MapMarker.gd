class_name MapMarker
extends Control

# MapMarker - Teardrop map pin with collision-aware name label

signal marker_pressed(area_id: String)

enum MarkerState {
	NEUTRAL,
	CURRENT,
	SELECTED,
	LOCKED,
	UNREACHABLE,
}

const PIN_SIZE := Vector2(22, 30)
const LABEL_PAD := Vector2(6, 2)

var area_id: String = ""
var display_name: String = ""
var marker_state: MarkerState = MarkerState.NEUTRAL
var lock_reason: String = ""
var body_font: Font = null

var pin_btn: Button
var name_label: Label
var lock_badge: Label
var _pulse_tween: Tween
var _fill_color: Color = Color(0.16, 0.12, 0.08, 0.96)
var _border_color: Color = Color(0.6, 0.45, 0.2, 0.7)
var _gem_color: Color = Color(0.85, 0.75, 0.45, 1.0)
var _pulse_alpha: float = 0.0
var _show_lock: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = PIN_SIZE
	_build_children()
	_apply_state_visuals()
	queue_redraw()


func setup(p_area_id: String, p_name: String, font: Font = null) -> void:
	area_id = p_area_id
	display_name = p_name
	body_font = font
	if is_node_ready():
		if name_label:
			name_label.text = display_name
		if body_font and name_label:
			name_label.add_theme_font_override("font", body_font)
		_apply_state_visuals()


func set_marker_state(state: MarkerState, reason: String = "") -> void:
	marker_state = state
	lock_reason = reason
	if is_node_ready():
		_apply_state_visuals()


func get_label_size() -> Vector2:
	if name_label == null:
		return Vector2.ZERO
	var font := name_label.get_theme_font("font")
	var font_size := name_label.get_theme_font_size("font_size")
	if font == null:
		return Vector2(display_name.length() * 7.0, 16.0) + LABEL_PAD * 2.0
	var text_size := font.get_string_size(
		display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	)
	return text_size + LABEL_PAD * 2.0


func place_label_at_local(local_pos: Vector2) -> void:
	if name_label == null:
		return
	var label_size := get_label_size()
	name_label.position = local_pos
	name_label.size = label_size


func set_pin_anchor(local_top_left: Vector2) -> void:
	position = local_top_left
	size = PIN_SIZE
	if pin_btn:
		pin_btn.position = Vector2.ZERO
		pin_btn.size = PIN_SIZE
	if lock_badge:
		lock_badge.position = Vector2(PIN_SIZE.x - 8, -4)
	queue_redraw()


func _build_children() -> void:
	if pin_btn != null:
		return

	pin_btn = Button.new()
	pin_btn.name = "PinButton"
	pin_btn.text = ""
	pin_btn.focus_mode = Control.FOCUS_ALL
	pin_btn.custom_minimum_size = PIN_SIZE
	pin_btn.size = PIN_SIZE
	pin_btn.flat = true
	pin_btn.pressed.connect(_on_pin_pressed)
	# Transparent hit target; pin is drawn by parent
	var empty := StyleBoxEmpty.new()
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		pin_btn.add_theme_stylebox_override(key, empty)
	add_child(pin_btn)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
	name_label.add_theme_color_override(
		"font_color", UIThemeManager.get_text_primary_color()
	)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	if body_font:
		name_label.add_theme_font_override("font", body_font)
	add_child(name_label)

	lock_badge = Label.new()
	lock_badge.name = "LockBadge"
	lock_badge.text = "🔒"
	lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_badge.add_theme_font_size_override("font_size", 10)
	lock_badge.visible = false
	add_child(lock_badge)


func _draw() -> void:
	var cx := PIN_SIZE.x * 0.5
	var head_c := Vector2(cx, 10.0)
	var head_r := 8.5
	var tip := Vector2(cx, PIN_SIZE.y - 1.0)

	# Soft ground shadow
	draw_circle(Vector2(cx, PIN_SIZE.y - 2.0), 4.0, Color(0, 0, 0, 0.35))

	# Pulse ring for current location
	if _pulse_alpha > 0.01:
		draw_arc(
			head_c, head_r + 4.0, 0.0, TAU, 28,
			Color(_border_color.r, _border_color.g, _border_color.b, _pulse_alpha),
			2.0, true
		)

	# Pin body: rounded head + pointed tip
	var left := Vector2(cx - 7.0, 12.0)
	var right := Vector2(cx + 7.0, 12.0)
	var body := PackedVector2Array([
		Vector2(cx - head_r + 1.0, 10.0),
		left,
		tip,
		right,
		Vector2(cx + head_r - 1.0, 10.0),
	])
	draw_colored_polygon(body, _fill_color)
	draw_circle(head_c, head_r, _fill_color)

	# Outline
	draw_arc(head_c, head_r, PI * 0.15, PI * 1.85, 24, _border_color, 2.0, true)
	draw_line(left, tip, _border_color, 2.0)
	draw_line(right, tip, _border_color, 2.0)

	# Center gem / “you are here” pip
	draw_circle(head_c, 3.2, _gem_color)
	if marker_state == MarkerState.CURRENT:
		draw_circle(head_c, 1.4, Color(1.0, 0.95, 0.8, 1.0))


func _apply_state_visuals() -> void:
	if pin_btn == null:
		return

	var bronze := UIThemeManager.get_border_bronze_color()
	var gold := UIThemeManager.get_color("title_gold")
	var accent := UIThemeManager.get_accent_color()
	var text_c := UIThemeManager.get_text_primary_color()
	var tip := display_name
	_show_lock = false
	modulate = Color.WHITE
	_stop_pulse()
	_pulse_alpha = 0.0

	match marker_state:
		MarkerState.CURRENT:
			_fill_color = Color(0.28, 0.20, 0.08, 0.98)
			_border_color = gold
			_gem_color = gold.lightened(0.15)
			name_label.add_theme_color_override("font_color", gold)
			tip = "%s (you are here)" % display_name
			_start_pulse()
		MarkerState.SELECTED:
			_fill_color = Color(0.24, 0.16, 0.08, 0.98)
			_border_color = accent
			_gem_color = accent
			name_label.add_theme_color_override("font_color", accent)
			tip = "Selected: %s" % display_name
		MarkerState.LOCKED:
			_fill_color = Color(0.14, 0.10, 0.09, 0.92)
			_border_color = Color(bronze.r, bronze.g, bronze.b, 0.55)
			_gem_color = Color(0.55, 0.4, 0.35, 1.0)
			modulate = Color(0.85, 0.7, 0.68, 0.95)
			name_label.add_theme_color_override(
				"font_color", UIThemeManager.get_secondary_color()
			)
			_show_lock = true
			if lock_reason != "":
				tip = "%s - %s" % [display_name, lock_reason]
			else:
				tip = "%s - Locked" % display_name
		MarkerState.UNREACHABLE:
			_fill_color = Color(0.12, 0.11, 0.10, 0.88)
			_border_color = Color(bronze.r, bronze.g, bronze.b, 0.35)
			_gem_color = Color(0.4, 0.38, 0.35, 1.0)
			modulate = Color(0.6, 0.58, 0.55, 0.9)
			name_label.add_theme_color_override(
				"font_color", UIThemeManager.get_secondary_color()
			)
			tip = "%s - Not reachable from here" % display_name
		_:
			_fill_color = Color(0.16, 0.12, 0.08, 0.96)
			_border_color = Color(bronze.r, bronze.g, bronze.b, 0.65)
			_gem_color = Color(0.75, 0.62, 0.35, 1.0)
			name_label.add_theme_color_override("font_color", text_c)
			tip = display_name

	pin_btn.tooltip_text = tip
	if name_label:
		name_label.tooltip_text = tip
	if lock_badge:
		lock_badge.visible = _show_lock
	queue_redraw()


func _start_pulse() -> void:
	if GameSettings.get_reduced_motion():
		_pulse_alpha = 0.4
		queue_redraw()
		return
	_stop_pulse()
	_pulse_alpha = 0.5
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_method(_set_pulse_alpha, 0.5, 0.12, 0.7).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_method(_set_pulse_alpha, 0.12, 0.5, 0.7).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _set_pulse_alpha(a: float) -> void:
	_pulse_alpha = a
	queue_redraw()


func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


func _on_pin_pressed() -> void:
	emit_signal("marker_pressed", area_id)


func _exit_tree() -> void:
	_stop_pulse()


## Place pins at map positions, then assign non-overlapping labels.
static func layout_all(markers: Dictionary, layer_size: Vector2, get_pos: Callable) -> void:
	if layer_size.x < 8.0 or layer_size.y < 8.0:
		return
	var pin_size: Vector2 = PIN_SIZE
	var occupied: Array = []
	for area_id in markers:
		var marker: MapMarker = markers[area_id]
		var pos: Vector2 = get_pos.call(area_id)
		var half: Vector2 = pin_size * 0.5
		var pin_pos := Vector2(
			clampf(pos.x * layer_size.x - half.x, 0.0, maxf(0.0, layer_size.x - pin_size.x)),
			clampf(pos.y * layer_size.y - half.y, 0.0, maxf(0.0, layer_size.y - pin_size.y))
		)
		marker.set_pin_anchor(pin_pos)
		occupied.append(Rect2(pin_pos, pin_size).grow(4.0))

	for area_id in markers:
		var marker: MapMarker = markers[area_id]
		var label_size: Vector2 = marker.get_label_size()
		var pin_pos: Vector2 = marker.position
		var candidates: Array = [
			Vector2(pin_pos.x + pin_size.x * 0.5 - label_size.x * 0.5, pin_pos.y - label_size.y - 4.0),
			Vector2(pin_pos.x + pin_size.x + 4.0, pin_pos.y + pin_size.y * 0.5 - label_size.y * 0.5),
			Vector2(pin_pos.x + pin_size.x * 0.5 - label_size.x * 0.5, pin_pos.y + pin_size.y + 4.0),
			Vector2(pin_pos.x - label_size.x - 4.0, pin_pos.y + pin_size.y * 0.5 - label_size.y * 0.5),
			Vector2(pin_pos.x + pin_size.x + 4.0, pin_pos.y - label_size.y - 2.0),
			Vector2(pin_pos.x - label_size.x - 4.0, pin_pos.y - label_size.y - 2.0),
		]
		var chosen: Vector2 = candidates[0]
		var found := false
		for candidate in candidates:
			var c: Vector2 = candidate
			c.x = clampf(c.x, 0.0, maxf(0.0, layer_size.x - label_size.x))
			c.y = clampf(c.y, 0.0, maxf(0.0, layer_size.y - label_size.y))
			var rect := Rect2(c, label_size)
			var hits := false
			for other in occupied:
				if rect.intersects(other):
					hits = true
					break
			if not hits:
				chosen = c
				found = true
				break
		if not found:
			chosen.x = clampf(chosen.x, 0.0, maxf(0.0, layer_size.x - label_size.x))
			chosen.y = clampf(chosen.y, 0.0, maxf(0.0, layer_size.y - label_size.y))
		marker.place_label_at_local(chosen - pin_pos)
		occupied.append(Rect2(chosen, label_size).grow(2.0))
