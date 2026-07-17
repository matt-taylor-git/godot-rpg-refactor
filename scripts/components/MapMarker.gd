class_name MapMarker
extends Control

# MapMarker - Teardrop pin with parchment name label and distinct location states

signal marker_pressed(area_id: String)

enum MarkerState {
	AVAILABLE,
	CURRENT,
	SELECTED,
	LOCKED,
}

const PIN_SIZE := Vector2(24, 32)
const LABEL_PAD := Vector2(8, 3)
const EDGE_PAD := 4.0

var area_id: String = ""
var display_name: String = ""
var marker_state: MarkerState = MarkerState.AVAILABLE
var lock_reason: String = ""
var body_font: Font = null

var pin_btn: Button
var name_label: Label
var label_bg: Panel
var _pulse_tween: Tween
var _fill_color: Color = Color(0.16, 0.12, 0.08, 0.96)
var _border_color: Color = Color(0.6, 0.45, 0.2, 0.7)
var _gem_color: Color = Color(0.75, 0.62, 0.35, 1.0)
var _pulse_alpha: float = 0.0
var _select_ring: bool = false
var _show_lock: bool = false
var _player_mark: bool = false


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
		return Vector2(display_name.length() * 7.5, 18.0) + LABEL_PAD * 2.0
	var text_size := font.get_string_size(
		display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	)
	return text_size + LABEL_PAD * 2.0


func place_label_at_local(local_pos: Vector2) -> void:
	if name_label == null or label_bg == null:
		return
	var label_size := get_label_size()
	label_bg.position = local_pos
	label_bg.size = label_size
	name_label.position = Vector2.ZERO
	name_label.size = label_size


func set_pin_anchor(local_top_left: Vector2) -> void:
	position = local_top_left
	size = PIN_SIZE
	pivot_offset = PIN_SIZE * 0.5
	if pin_btn:
		pin_btn.position = Vector2.ZERO
		pin_btn.size = PIN_SIZE
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
	pin_btn.mouse_entered.connect(_on_pin_hover.bind(true))
	pin_btn.mouse_exited.connect(_on_pin_hover.bind(false))
	pin_btn.focus_entered.connect(_on_pin_hover.bind(true))
	pin_btn.focus_exited.connect(_on_pin_hover.bind(false))
	var empty := StyleBoxEmpty.new()
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		pin_btn.add_theme_stylebox_override(key, empty)
	add_child(pin_btn)

	label_bg = Panel.new()
	label_bg.name = "LabelBg"
	label_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color(0.14, 0.11, 0.08, 0.88)
	parchment.border_color = Color(0.45, 0.35, 0.2, 0.55)
	parchment.set_border_width_all(1)
	parchment.set_corner_radius_all(2)
	parchment.set_content_margin_all(0)
	label_bg.add_theme_stylebox_override("panel", parchment)
	add_child(label_bg)

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
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.85))
	if body_font:
		name_label.add_theme_font_override("font", body_font)
	label_bg.add_child(name_label)


func _draw() -> void:
	var cx := PIN_SIZE.x * 0.5
	var head_c := Vector2(cx, 10.5)
	var head_r := 9.0
	var tip := Vector2(cx, PIN_SIZE.y - 1.0)

	draw_circle(Vector2(cx, PIN_SIZE.y - 2.0), 4.0, Color(0, 0, 0, 0.35))

	# Selection ring (inspected destination) — outer warm glow, no pulse
	if _select_ring:
		draw_arc(
			head_c, head_r + 5.0, 0.0, TAU, 32,
			Color(0.92, 0.72, 0.28, 0.95), 2.5, true
		)
		draw_arc(
			head_c, head_r + 7.0, 0.0, TAU, 32,
			Color(0.92, 0.72, 0.28, 0.35), 1.5, true
		)

	# Current-location pulse ring (ivory)
	if _pulse_alpha > 0.01:
		draw_arc(
			head_c, head_r + 4.5, 0.0, TAU, 28,
			Color(0.94, 0.88, 0.7, _pulse_alpha), 2.2, true
		)

	var left := Vector2(cx - 7.5, 12.5)
	var right := Vector2(cx + 7.5, 12.5)
	var body := PackedVector2Array([
		Vector2(cx - head_r + 1.0, 10.5),
		left,
		tip,
		right,
		Vector2(cx + head_r - 1.0, 10.5),
	])
	draw_colored_polygon(body, _fill_color)
	draw_circle(head_c, head_r, _fill_color)
	draw_arc(head_c, head_r, PI * 0.12, PI * 1.88, 24, _border_color, 2.0, true)
	draw_line(left, tip, _border_color, 2.0)
	draw_line(right, tip, _border_color, 2.0)

	if _show_lock:
		_draw_lock(head_c)
	elif _player_mark:
		# Player: gold body already; white center pip
		draw_circle(head_c, 4.0, Color(0.9, 0.78, 0.4, 1.0))
		draw_circle(head_c, 2.0, Color(0.99, 0.97, 0.92, 1.0))
	else:
		draw_circle(head_c, 3.2, _gem_color)


func _draw_lock(center: Vector2) -> void:
	var shackle := Color(0.92, 0.78, 0.45, 1.0)
	var body_c := Color(0.75, 0.55, 0.22, 1.0)
	# Shackle
	draw_arc(center + Vector2(0, -2.5), 3.2, PI, TAU, 12, shackle, 1.6, true)
	# Body
	var rect := Rect2(center.x - 4.0, center.y - 1.0, 8.0, 6.5)
	draw_rect(rect, body_c, true)
	draw_rect(rect, shackle, false, 1.0)
	# Keyhole
	draw_circle(center + Vector2(0, 1.5), 1.0, Color(0.12, 0.09, 0.06, 1.0))


func _apply_state_visuals() -> void:
	if pin_btn == null:
		return

	var bronze := UIThemeManager.get_border_bronze_color()
	var gold := UIThemeManager.get_color("title_gold")
	var text_c := UIThemeManager.get_text_primary_color()
	var tip := display_name
	_show_lock = false
	_select_ring = false
	_player_mark = false
	modulate = Color.WHITE
	_stop_pulse()
	_pulse_alpha = 0.0

	match marker_state:
		MarkerState.CURRENT:
			# Gold pin, ivory ring, white center — matches parchment palette
			_fill_color = Color(0.28, 0.20, 0.10, 0.98)
			_border_color = Color(0.92, 0.86, 0.68, 1.0)
			_gem_color = Color(0.98, 0.96, 0.9, 1.0)
			_player_mark = true
			name_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.72, 1.0))
			tip = "%s — You are here" % display_name
			_start_pulse()
		MarkerState.SELECTED:
			_fill_color = Color(0.26, 0.18, 0.08, 0.98)
			_border_color = gold
			_gem_color = gold
			_select_ring = true
			name_label.add_theme_color_override("font_color", gold)
			tip = "%s — Selected" % display_name
		MarkerState.LOCKED:
			_fill_color = Color(0.12, 0.10, 0.09, 0.94)
			_border_color = Color(bronze.r, bronze.g, bronze.b, 0.5)
			_gem_color = Color(0.55, 0.42, 0.28, 1.0)
			_show_lock = true
			modulate = Color(0.82, 0.75, 0.7, 0.95)
			name_label.add_theme_color_override(
				"font_color", UIThemeManager.get_text_primary_color().darkened(0.15)
			)
			if lock_reason != "":
				tip = "%s — Locked: %s" % [display_name, lock_reason]
			else:
				tip = "%s — Locked" % display_name
		_:
			_fill_color = Color(0.16, 0.12, 0.08, 0.96)
			_border_color = Color(bronze.r, bronze.g, bronze.b, 0.7)
			_gem_color = Color(0.78, 0.64, 0.36, 1.0)
			name_label.add_theme_color_override("font_color", text_c)
			tip = "%s — Available" % display_name

	pin_btn.tooltip_text = tip
	if label_bg:
		label_bg.tooltip_text = tip
	queue_redraw()


func _start_pulse() -> void:
	if GameSettings.get_reduced_motion():
		_pulse_alpha = 0.45
		queue_redraw()
		return
	_stop_pulse()
	_pulse_alpha = 0.55
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_method(_set_pulse_alpha, 0.55, 0.15, 0.75).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_method(_set_pulse_alpha, 0.15, 0.55, 0.75).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _set_pulse_alpha(a: float) -> void:
	_pulse_alpha = a
	queue_redraw()


func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


func _on_pin_hover(active: bool) -> void:
	if GameSettings.get_reduced_motion():
		scale = Vector2.ONE
		return
	var target := Vector2(1.08, 1.08) if active else Vector2.ONE
	var tw := create_tween()
	tw.tween_property(self, "scale", target, 0.12).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func(): tw.kill())


func _on_pin_pressed() -> void:
	emit_signal("marker_pressed", area_id)
	if not GameSettings.get_reduced_motion():
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(0.94, 0.94), 0.06)
		tw.tween_property(self, "scale", Vector2.ONE, 0.1)
		tw.finished.connect(func(): tw.kill())


func _exit_tree() -> void:
	_stop_pulse()


## Place pins so the tip sits on map_pos; labels avoid pins and map edges.
static func layout_all(markers: Dictionary, layer_size: Vector2, get_pos: Callable) -> void:
	if layer_size.x < 8.0 or layer_size.y < 8.0:
		return
	var pin_size: Vector2 = PIN_SIZE
	var occupied: Array = []
	for area_id in markers:
		var marker: MapMarker = markers[area_id]
		var pos: Vector2 = get_pos.call(area_id)
		# Tip of pin targets map_pos
		var pin_pos := Vector2(
			pos.x * layer_size.x - pin_size.x * 0.5,
			pos.y * layer_size.y - pin_size.y + 2.0
		)
		pin_pos.x = clampf(pin_pos.x, EDGE_PAD, maxf(EDGE_PAD, layer_size.x - pin_size.x - EDGE_PAD))
		pin_pos.y = clampf(pin_pos.y, EDGE_PAD, maxf(EDGE_PAD, layer_size.y - pin_size.y - EDGE_PAD))
		marker.set_pin_anchor(pin_pos)
		occupied.append(Rect2(pin_pos, pin_size).grow(5.0))

	for area_id in markers:
		var marker: MapMarker = markers[area_id]
		var label_size: Vector2 = marker.get_label_size()
		var pin_pos: Vector2 = marker.position
		var candidates: Array = [
			Vector2(pin_pos.x + pin_size.x * 0.5 - label_size.x * 0.5, pin_pos.y - label_size.y - 5.0),
			Vector2(pin_pos.x + pin_size.x + 5.0, pin_pos.y + 2.0),
			Vector2(pin_pos.x - label_size.x - 5.0, pin_pos.y + 2.0),
			Vector2(pin_pos.x + pin_size.x * 0.5 - label_size.x * 0.5, pin_pos.y + pin_size.y + 4.0),
			Vector2(pin_pos.x + pin_size.x + 5.0, pin_pos.y - label_size.y - 2.0),
			Vector2(pin_pos.x - label_size.x - 5.0, pin_pos.y - label_size.y - 2.0),
		]
		var chosen: Vector2 = candidates[0]
		var found := false
		for candidate in candidates:
			var c: Vector2 = candidate
			c.x = clampf(c.x, EDGE_PAD, maxf(EDGE_PAD, layer_size.x - label_size.x - EDGE_PAD))
			c.y = clampf(c.y, EDGE_PAD, maxf(EDGE_PAD, layer_size.y - label_size.y - EDGE_PAD))
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
			chosen.x = clampf(chosen.x, EDGE_PAD, maxf(EDGE_PAD, layer_size.x - label_size.x - EDGE_PAD))
			chosen.y = clampf(chosen.y, EDGE_PAD, maxf(EDGE_PAD, layer_size.y - label_size.y - EDGE_PAD))
		marker.place_label_at_local(chosen - pin_pos)
		occupied.append(Rect2(chosen, label_size).grow(2.0))
