class_name CombatStageChrome
extends RefCounted
# Shared StyleBox helpers for the combat stage (mirrors ExplorationHubChrome).

const ACTION_MIN_SIZE := Vector2(170, 76)
const ACTION_ICON_MAX := 28


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
	style.bg_color = Color(0.09, 0.07, 0.055, 0.88)
	style.border_color = Color(0.55, 0.42, 0.22, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_primary_action(btn: Button) -> void:
	if btn == null:
		return
	var gold := UIThemeManager.get_color("title_gold")
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.32, 0.24, 0.10, 0.96).lerp(gold, 0.22)
	style.border_color = gold
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.38, 0.28, 0.12, 0.98).lerp(gold, 0.28)
	hover.border_color = gold.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.22, 0.16, 0.07, 1.0).lerp(gold, 0.12)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.12, 0.10, 0.08, 0.55)
	disabled.border_color = UIThemeManager.get_secondary_color()
	disabled.border_color.a = 0.35
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
	btn.add_theme_constant_override("icon_max_width", ACTION_ICON_MAX)
	_apply_display_font(btn, UITypography.FONT_SIZE_BODY_LARGE)


static func style_secondary_action(btn: Button) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.07, 0.90)
	style.border_color = Color(0.55, 0.42, 0.22, 0.40)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.16, 0.13, 0.09, 0.95)
	hover.border_color = Color(0.55, 0.42, 0.22, 0.60)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.09, 0.07, 0.055, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.10, 0.09, 0.08, 0.50)
	disabled.border_color = Color(0.40, 0.35, 0.28, 0.30)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
	btn.add_theme_constant_override("icon_max_width", ACTION_ICON_MAX)
	_apply_body_font(btn, UITypography.FONT_SIZE_CAPTION)


static func style_danger_action(btn: Button) -> void:
	if btn == null:
		return
	var danger := UIThemeManager.get_color("danger")
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.07, 0.92)
	style.border_color = Color(danger.r, danger.g, danger.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.20, 0.10, 0.09, 0.96)
	hover.border_color = Color(danger.r, danger.g, danger.b, 0.75)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.10, 0.06, 0.05, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.10, 0.09, 0.08, 0.50)
	disabled.border_color = Color(0.40, 0.30, 0.28, 0.30)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.custom_minimum_size = ACTION_MIN_SIZE
	btn.add_theme_color_override("font_color", danger.lightened(0.15))
	btn.add_theme_constant_override("icon_max_width", ACTION_ICON_MAX)
	_apply_body_font(btn, UITypography.FONT_SIZE_CAPTION)


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
	_apply_body_font(btn, UITypography.FONT_SIZE_CAPTION)


static func _apply_display_font(btn: Button, size: int) -> void:
	var path := "res://assets/Cinzel-VariableFont_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", size)


static func _apply_body_font(btn: Button, size: int) -> void:
	var path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if ResourceLoader.exists(path):
		var font: Font = load(path)
		if font:
			btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", size)


static func set_button_label(btn: Button, label: String) -> void:
	if btn == null:
		return
	if btn.get("button_text") != null:
		btn.set("button_text", label)
	btn.text = label
