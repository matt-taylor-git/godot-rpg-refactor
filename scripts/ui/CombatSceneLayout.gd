class_name CombatSceneLayout
extends RefCounted

# Presentation-only helpers kept outside CombatScene so the scene controller stays focused on combat flow.

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const SERIF_PATH := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"


static func background_path(area_id: String) -> String:
	var known := {
		"forest": "res://assets/combat/forest.png",
		"mountain": "res://assets/combat/mountain.png",
		"cave": "res://assets/combat/cave.png",
		"peak": "res://assets/combat/peak.png",
		"town": "res://assets/combat/forest.png",
	}
	return str(known.get(area_id, "res://assets/combat/forest.png"))


static func style_chrome(scene) -> void:
	StageChrome.style_quiet_strip(scene.event_strip)
	StageChrome.style_borderless_dock(scene.action_dock)
	StageChrome.style_history_overlay(scene.combat_log_panel)
	StageChrome.style_intent_chip(scene.enemy_intent_panel)
	StageChrome.style_log_toggle(scene.history_toggle)
	StageChrome.set_button_label(scene.history_toggle, "History ▾")
	scene.history_toggle.custom_minimum_size = Vector2(84, 28)
	if ResourceLoader.exists(SERIF_PATH):
		var serif: Font = load(SERIF_PATH)
		scene.event_label.add_theme_font_override("normal_font", serif)
		scene.enemy_intent_label.add_theme_font_override("font", serif)
	scene.event_label.add_theme_font_size_override(
		"normal_font_size", UITypography.FONT_SIZE_BODY_REGULAR
	)
	scene.event_label.add_theme_color_override(
		"default_color", UIThemeManager.get_text_primary_color()
	)
	scene.event_label.bbcode_enabled = true
	scene.event_label.scroll_active = false
	scene.event_label.fit_content = false
	scene.enemy_intent_label.add_theme_font_size_override(
		"font_size", UITypography.FONT_SIZE_CAPTION
	)
	scene.enemy_intent_label.add_theme_color_override(
		"font_color", UIThemeManager.get_color("title_gold")
	)


static func apply_responsive(scene, compact: bool, dock_height: float, action_height: float) -> void:
	scene.dock_layer.custom_minimum_size.y = dock_height
	scene.status_rail.custom_minimum_size.y = 64.0 if compact else 68.0
	scene.action_dock.custom_minimum_size.y = action_height + 8.0
	scene.action_pages.custom_minimum_size.y = action_height
	scene.root_actions.add_theme_constant_override("separation", 8 if compact else 14)
	for button in [scene.attack_button, scene.skills_button, scene.items_button, scene.run_button]:
		button.custom_minimum_size.y = action_height
	scene.player_stage.set_compact_layout(compact)
	scene.monster_stage.set_compact_layout(compact)
	scene.player_status.set_compact_layout(compact)
	scene.monster_status.set_compact_layout(compact)
	scene.turn_banner.offset_left = -110.0 if compact else -125.0
	scene.turn_banner.offset_right = 110.0 if compact else 125.0
	scene.turn_banner.offset_bottom = 44.0 if compact else 48.0
	var history_bottom := -(dock_height + 12.0)
	scene.combat_log_panel.offset_bottom = history_bottom
	scene.combat_log_panel.offset_top = history_bottom - 162.0
