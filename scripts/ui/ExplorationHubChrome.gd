class_name ExplorationHubChrome
extends RefCounted
# Shared StyleBox helpers for the exploration hub (keeps ExplorationScene under max-file-lines).

const MAP_CTRL_SIZE := 42.0


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
	style.set_content_margin_all(2)
	if node is PanelContainer or node is Panel:
		node.add_theme_stylebox_override("panel", style)


static func style_primary_action(btn: Button, disable_reason: String) -> void:
	if btn == null:
		return
	var gold := UIThemeManager.get_color("title_gold")
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.32, 0.24, 0.10, 0.96).lerp(gold, 0.22)
	style.border_color = gold
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
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
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
	if btn.disabled and disable_reason != "":
		btn.tooltip_text = disable_reason
	else:
		btn.tooltip_text = ""


static func style_quiet_buttons(buttons: Array, body_font: Font, min_h: float, content_margin: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.07, 0.88)
	style.border_color = Color(0.55, 0.42, 0.22, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(content_margin)
	var hover := style.duplicate()
	hover.bg_color = Color(0.16, 0.13, 0.09, 0.94)
	hover.border_color = Color(0.55, 0.42, 0.22, 0.55)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.09, 0.07, 0.055, 0.95)
	for btn in buttons:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(0, min_h)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())


static func style_utility_buttons(buttons: Array, body_font: Font) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.88)
	style.border_color = Color(0.55, 0.42, 0.22, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	var hover := style.duplicate()
	hover.bg_color = Color(0.18, 0.14, 0.10, 0.94)
	hover.border_color = Color(0.55, 0.42, 0.22, 0.55)
	for btn in buttons:
		if btn == null:
			continue
		btn.disabled = false
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)


static func style_map_controls(
	zoom_out: Button, zoom_in: Button, recenter: Button, legend: Button, body_font: Font
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.90)
	style.border_color = Color(0.55, 0.42, 0.22, 0.40)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(2)
	var hover := style.duplicate()
	hover.bg_color = Color(0.18, 0.14, 0.10, 0.96)
	hover.border_color = Color(0.55, 0.42, 0.22, 0.65)
	var square := Vector2(MAP_CTRL_SIZE, MAP_CTRL_SIZE)
	for btn in [zoom_out, zoom_in, recenter]:
		if btn == null:
			continue
		btn.custom_minimum_size = square
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover)
		if body_font:
			btn.add_theme_font_override("font", body_font)
		btn.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_BODY_REGULAR)
		btn.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
	if recenter:
		_set_btn_text(recenter, "◎")
		recenter.tooltip_text = "Recenter map"
	if legend:
		legend.custom_minimum_size = Vector2(72, MAP_CTRL_SIZE)
		legend.add_theme_stylebox_override("normal", style)
		legend.add_theme_stylebox_override("hover", hover)
		legend.add_theme_stylebox_override("focus", hover)
		if body_font:
			legend.add_theme_font_override("font", body_font)
		legend.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		legend.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
		_set_btn_text(legend, "Legend")


static func _set_btn_text(btn: Button, label: String) -> void:
	if btn == null:
		return
	if btn.get("button_text") != null:
		btn.set("button_text", label)
	btn.text = label
