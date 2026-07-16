class_name UIDialogShell
extends Object

# UIDialogShell - Shared modal chrome (dimmer + opaque panel) and open/close motion
# Apply from dialog _ready via apply_to(root, panel, anim_style)
# Note: static helpers only; not instantiated as a scene node.

enum AnimStyle { SLIDE, SCALE, FADE }

const OPEN_DURATION := 0.3
const CLOSE_DURATION := 0.2
const DIMMER_COLOR := Color(0.08, 0.07, 0.06, 0.78)
const PANEL_BG := Color(0.12, 0.10, 0.08, 0.97)


static func is_reduced_motion() -> bool:
	return ProjectSettings.get_setting("accessibility/reduced_motion", false)


static func create_panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	var bronze: Color = Color(0.60, 0.45, 0.20, 1.0)
	if UIThemeManager:
		bronze = UIThemeManager.get_border_bronze_color()
		var bg = UIThemeManager.get_background_color()
		style.bg_color = Color(bg.r, bg.g, bg.b, 0.97)
	style.border_color = bronze
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	return style


static func style_dimmer(dimmer: ColorRect) -> void:
	if dimmer == null:
		return
	dimmer.color = DIMMER_COLOR
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)


static func style_panel(panel: Control) -> void:
	if panel == null:
		return
	if panel is PanelContainer or panel is Panel:
		panel.add_theme_stylebox_override("panel", create_panel_stylebox())


## Ensure a full-rect dimmer exists as first child; style panel if found.
static func apply_to(root: Control, panel: Control = null, anim: AnimStyle = AnimStyle.FADE) -> void:
	if root == null:
		return
	var dimmer := _ensure_dimmer(root)
	style_dimmer(dimmer)
	var target_panel: Control = panel
	if target_panel == null:
		target_panel = root.get_node_or_null("DialogPanel") as Control
		if target_panel == null:
			target_panel = root.get_node_or_null("Panel") as Control
	style_panel(target_panel)
	play_open(root, target_panel if target_panel else root, anim)


static func _ensure_dimmer(root: Control) -> ColorRect:
	var existing := root.get_node_or_null("Background") as ColorRect
	if existing:
		return existing
	var dimmer := ColorRect.new()
	dimmer.name = "Background"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dimmer)
	root.move_child(dimmer, 0)
	return dimmer


static func play_open(root: Control, panel: Control, anim: AnimStyle = AnimStyle.FADE) -> void:
	if panel == null:
		return
	if is_reduced_motion():
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		return

	match anim:
		AnimStyle.SLIDE:
			var end_y: float = panel.position.y
			panel.modulate.a = 0.0
			panel.position.y = end_y + 32.0
			var tween := root.create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(panel, "modulate:a", 1.0, OPEN_DURATION)
			tween.tween_property(panel, "position:y", end_y, OPEN_DURATION)
			tween.finished.connect(func(): tween.kill())
		AnimStyle.SCALE:
			panel.pivot_offset = panel.size / 2.0 if panel.size.x > 0 else Vector2(150, 100)
			panel.modulate.a = 0.0
			panel.scale = Vector2(0.92, 0.92)
			var tween2 := root.create_tween()
			tween2.set_parallel(true)
			tween2.set_ease(Tween.EASE_OUT)
			tween2.set_trans(Tween.TRANS_BACK)
			tween2.tween_property(panel, "modulate:a", 1.0, OPEN_DURATION)
			tween2.tween_property(panel, "scale", Vector2.ONE, OPEN_DURATION)
			tween2.finished.connect(func(): tween2.kill())
		_:
			panel.modulate.a = 0.0
			var tween3 := root.create_tween()
			tween3.set_ease(Tween.EASE_OUT)
			tween3.tween_property(panel, "modulate:a", 1.0, OPEN_DURATION)
			tween3.finished.connect(func(): tween3.kill())


static func play_close_and_free(root: Control, panel: Control = null) -> void:
	if root == null:
		return
	var target: Control = panel
	if target == null:
		target = root.get_node_or_null("DialogPanel") as Control
		if target == null:
			target = root
	if is_reduced_motion():
		root.queue_free()
		return
	var tween := root.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, CLOSE_DURATION)
	tween.tween_callback(func(): root.queue_free())
