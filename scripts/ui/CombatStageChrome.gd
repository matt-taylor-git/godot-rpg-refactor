class_name CombatStageChrome
extends RefCounted
# Shared StyleBox helpers for the combat stage (mirrors ExplorationHubChrome).

const ACTION_MIN_SIZE := Vector2(180, 80)
const TITLE_SIZE_PRIMARY := 24
const TITLE_SIZE_SECONDARY := 20
const SUBTITLE_SIZE := 12


static func style_floating_panel(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.93)
	style.border_color = Color(0.55, 0.42, 0.22, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.set_content_margin_all(6)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_quiet_strip(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.78)
	style.border_color = Color(0.55, 0.42, 0.22, 0.28)
	style.border_width_bottom = 1
	style.border_width_top = 0
	style.border_width_left = 0
	style.border_width_right = 0
	style.set_corner_radius_all(2)
	style.set_content_margin_all(6)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_borderless_dock(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.set_content_margin_all(0)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_hud_plate(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.78)
	style.border_color = Color(0.55, 0.42, 0.22, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.set_content_margin_all(10)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_status_plate(node: Control, active: bool = false, danger: bool = false) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.86)
	style.border_color = Color(0.55, 0.42, 0.22, 0.34)
	if active:
		style.border_color = Color(0.78, 0.60, 0.28, 0.78)
	if danger:
		style.bg_color = Color(0.10, 0.045, 0.04, 0.90)
		style.border_color = Color(0.76, 0.24, 0.20, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	style.set_content_margin_all(4)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_history_overlay(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.035, 0.97)
	style.border_color = Color(0.66, 0.49, 0.24, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.set_content_margin_all(6)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_action_card_primary(btn: Button, title: Label, sub: Label) -> void:
	if btn == null:
		return
	var gold := UIThemeManager.get_color("title_gold")
	var cream := UIThemeManager.get_text_primary_color()
	# Deeper bronze so cream text reads
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.16, 0.08, 0.98).lerp(gold, 0.12)
	style.border_color = gold
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.28, 0.20, 0.09, 0.99).lerp(gold, 0.18)
	hover.border_color = gold.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.16, 0.12, 0.06, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.12, 0.10, 0.08, 0.55)
	disabled.border_color = UIThemeManager.get_secondary_color()
	disabled.border_color.a = 0.35
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	_style_card_labels(title, sub, cream, TITLE_SIZE_PRIMARY, true)


static func style_action_card_secondary(btn: Button, title: Label, sub: Label) -> void:
	if btn == null:
		return
	var cream := UIThemeManager.get_text_primary_color()
	var style := StyleBoxFlat.new()
	# Opaque umber plate so cards read as enabled tiles, not ghost text
	style.bg_color = Color(0.16, 0.13, 0.09, 1.0)
	style.border_color = Color(0.72, 0.55, 0.30, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.22, 0.17, 0.11, 1.0)
	hover.border_color = Color(0.85, 0.65, 0.35, 0.95)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.12, 0.10, 0.07, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.10, 0.09, 0.08, 0.55)
	disabled.border_color = Color(0.40, 0.35, 0.28, 0.30)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	_style_card_labels(title, sub, cream, TITLE_SIZE_SECONDARY, true)


static func style_action_card_danger(btn: Button, title: Label, sub: Label) -> void:
	if btn == null:
		return
	var danger := UIThemeManager.get_color("danger")
	var title_col := danger.lightened(0.35)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.10, 0.09, 1.0)
	style.border_color = Color(danger.r, danger.g, danger.b, 0.80)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.22, 0.11, 0.10, 0.98)
	hover.border_color = Color(danger.r, danger.g, danger.b, 0.88)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.12, 0.07, 0.06, 0.98)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.10, 0.09, 0.08, 0.50)
	disabled.border_color = Color(0.40, 0.30, 0.28, 0.30)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	_style_card_labels(title, sub, title_col, TITLE_SIZE_SECONDARY, false)


static func style_intent_chip(node: Control) -> void:
	if node == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.07, 0.92)
	style.border_color = Color(0.75, 0.55, 0.25, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_log_toggle(btn: Button) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.07, 0.0)
	style.border_color = Color(0.55, 0.42, 0.22, 0.0)
	style.set_border_width_all(0)
	style.set_content_margin_all(2)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_color_override("font_color", UIThemeManager.get_color("secondary"))
	_apply_body_font_to_control(btn, UITypography.FONT_SIZE_CAPTION)


# Legacy single-line button helpers (skills list, back buttons)
static func style_primary_action(btn: Button) -> void:
	style_action_card_primary(btn, null, null)
	if btn:
		btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
		_apply_display_font(btn, TITLE_SIZE_PRIMARY)


static func style_secondary_action(btn: Button) -> void:
	style_action_card_secondary(btn, null, null)
	if btn:
		btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
		_apply_body_font_to_control(btn, TITLE_SIZE_SECONDARY)


static func style_danger_action(btn: Button) -> void:
	style_action_card_danger(btn, null, null)
	if btn:
		var danger := UIThemeManager.get_color("danger").lightened(0.35)
		btn.add_theme_color_override("font_color", danger)
		_apply_body_font_to_control(btn, TITLE_SIZE_SECONDARY)


static func set_button_label(btn: Button, label: String) -> void:
	if btn == null:
		return
	if btn.get("button_text") != null:
		btn.set("button_text", label)
	btn.text = label


static func _style_card_labels(
	title: Label, sub: Label, title_color: Color, title_size: int, use_display_title: bool
) -> void:
	if title:
		if use_display_title:
			_apply_display_font_to_label(title, title_size)
		else:
			_apply_body_font_to_label(title, title_size)
		title.add_theme_color_override("font_color", title_color)
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		title.add_theme_constant_override("shadow_offset_x", 1)
		title.add_theme_constant_override("shadow_offset_y", 1)
	if sub:
		_apply_body_font_to_label(sub, SUBTITLE_SIZE)
		sub.add_theme_color_override(
			"font_color", UIThemeManager.get_text_primary_color().darkened(0.08)
		)
		sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
		sub.add_theme_constant_override("shadow_offset_x", 1)
		sub.add_theme_constant_override("shadow_offset_y", 1)


static func _apply_display_font(btn: Button, size: int) -> void:
	var path := "res://assets/Cinzel-VariableFont_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", size)


static func _apply_body_font_to_control(ctrl: Control, size: int) -> void:
	var path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			ctrl.add_theme_font_override("font", font)
	ctrl.add_theme_font_size_override("font_size", size)


static func _apply_display_font_to_label(label: Label, size: int) -> void:
	var path := "res://assets/Cinzel-VariableFont_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)


static func _apply_body_font_to_label(label: Label, size: int) -> void:
	var path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
