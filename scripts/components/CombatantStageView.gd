class_name CombatantStageView
extends Control

# Frameless combatant figure with attached HUD (name, labeled HP/MP, status).

signal figure_ready

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const FIGURE_SIZE := Vector2(280, 280)
const BAR_MIN := Vector2(160, 22)
const SHADOW_PATH := "res://assets/ui/combat_contact_shadow.png"
const MIST_PATH := "res://assets/ui/combat_foot_mist.png"

@export var show_mana: bool = true
@export var is_player_side: bool = true

var reduced_motion: bool = false
var is_active: bool = false:
	set(value):
		is_active = value
		_update_active_visual()

@onready var figure: TextureRect = $FigureStack/Figure
@onready var contact_shadow: TextureRect = $FigureStack/ContactShadow
@onready var foot_mist: TextureRect = $FigureStack/FootMist
@onready var hud_plate: PanelContainer = $HudPlate
@onready var name_label: Label = $HudPlate/Hud/NameLabel
@onready var level_label: Label = $HudPlate/Hud/LevelLabel
@onready var hp_row: HBoxContainer = $HudPlate/Hud/HpRow
@onready var hp_label: Label = $HudPlate/Hud/HpRow/HpLabel
@onready var health_bar = $HudPlate/Hud/HpRow/HealthBar
@onready var hp_value: Label = $HudPlate/Hud/HpRow/HpValue
@onready var mp_row: HBoxContainer = $HudPlate/Hud/MpRow
@onready var mp_label: Label = $HudPlate/Hud/MpRow/MpLabel
@onready var mana_bar = $HudPlate/Hud/MpRow/ManaBar
@onready var mp_value: Label = $HudPlate/Hud/MpRow/MpValue
@onready var status_container: HBoxContainer = $HudPlate/Hud/StatusRow
@onready var intent_panel: PanelContainer = $IntentPanel
@onready var intent_label: Label = $IntentPanel/IntentMargin/IntentLabel


func _ready() -> void:
	custom_minimum_size = Vector2(300, 400)
	if figure:
		figure.custom_minimum_size = FIGURE_SIZE
		figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_ground_fx()
	_style_labels()
	_configure_bars()
	StageChrome.style_hud_plate(hud_plate)
	if intent_panel:
		intent_panel.visible = not is_player_side
		StageChrome.style_intent_chip(intent_panel)
	if mp_row:
		mp_row.visible = show_mana and is_player_side
	emit_signal("figure_ready")


func get_figure_node() -> CanvasItem:
	return figure


func set_figure_texture(tex: Texture2D) -> void:
	if figure:
		figure.texture = tex


func set_identity(char_name: String, level: int = 1, extra: String = "") -> void:
	if name_label:
		name_label.text = char_name
	if level_label:
		var text := "Lv. %d" % level
		if extra != "":
			text += "  " + extra
		level_label.text = text


func set_health(current: float, maximum: float, animate: bool = true) -> void:
	if health_bar == null:
		return
	health_bar.max_value = maximum
	if "enable_damage_trail" in health_bar:
		health_bar.enable_damage_trail = true
	if animate and health_bar.has_method("set_value_animated"):
		health_bar.set_value_animated(current, true)
	else:
		health_bar.value = current
	if hp_value:
		hp_value.text = "%d/%d" % [int(current), int(maximum)]


func set_mana(current: float, maximum: float, animate: bool = true) -> void:
	if mana_bar == null or mp_row == null:
		return
	if maximum <= 0:
		mp_row.visible = false
		return
	mp_row.visible = show_mana and is_player_side
	mana_bar.max_value = maximum
	if animate and mana_bar.has_method("set_value_animated"):
		mana_bar.set_value_animated(current, true)
	else:
		mana_bar.value = current
	if mp_value:
		mp_value.text = "%d/%d" % [int(current), int(maximum)]


func set_intent(text: String) -> void:
	if intent_panel == null or intent_label == null:
		return
	if is_player_side:
		intent_panel.visible = false
		return
	intent_label.text = text
	intent_panel.visible = text != ""


func clear_status_effects() -> void:
	if status_container == null:
		return
	for child in status_container.get_children():
		child.queue_free()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if health_bar and "respect_reduced_motion" in health_bar:
		health_bar.respect_reduced_motion = enabled
	if mana_bar and "respect_reduced_motion" in mana_bar:
		mana_bar.respect_reduced_motion = enabled


func _load_ground_fx() -> void:
	if contact_shadow:
		if ResourceLoader.exists(SHADOW_PATH):
			contact_shadow.texture = load(SHADOW_PATH)
			contact_shadow.visible = true
			# Kill residual magenta fringe from chroma
			contact_shadow.modulate = Color(0.12, 0.10, 0.08, 0.75)
		else:
			contact_shadow.visible = false
	if foot_mist:
		if ResourceLoader.exists(MIST_PATH):
			foot_mist.texture = load(MIST_PATH)
			foot_mist.visible = true
			foot_mist.modulate = Color(0.75, 0.8, 0.85, 0.32)
		else:
			foot_mist.visible = false


func _style_labels() -> void:
	var gold := UIThemeManager.get_color("title_gold")
	var body := UIThemeManager.get_text_primary_color()
	var cinzel := "res://assets/Cinzel-VariableFont_wght.ttf"
	var serif := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if name_label:
		if ResourceLoader.exists(cinzel):
			name_label.add_theme_font_override("font", load(cinzel))
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", gold)
		name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 2)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if level_label:
		if ResourceLoader.exists(serif):
			level_label.add_theme_font_override("font", load(serif))
		level_label.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		level_label.add_theme_color_override("font_color", UIThemeManager.get_color("secondary"))
		level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		level_label.add_theme_constant_override("shadow_offset_x", 1)
		level_label.add_theme_constant_override("shadow_offset_y", 1)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for lbl in [hp_label, mp_label, hp_value, mp_value, intent_label]:
		if lbl == null:
			continue
		if ResourceLoader.exists(serif):
			lbl.add_theme_font_override("font", load(serif))
		lbl.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		lbl.add_theme_color_override("font_color", body)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
	if hp_label:
		hp_label.text = "HP"
	if mp_label:
		mp_label.text = "MP"
	if intent_label:
		intent_label.add_theme_color_override("font_color", gold)
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _configure_bars() -> void:
	for bar in [health_bar, mana_bar]:
		if bar == null:
			continue
		bar.show_percentage = false
		if "show_value_text" in bar:
			bar.show_value_text = false
		if "connect_to_gamemanager" in bar:
			bar.connect_to_gamemanager = false
		if "enable_damage_trail" in bar:
			bar.enable_damage_trail = true
		bar.custom_minimum_size = BAR_MIN
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if mana_bar and "bar_kind" in mana_bar:
		mana_bar.bar_kind = "mana"


func _update_active_visual() -> void:
	if figure == null:
		return
	if is_active:
		figure.modulate = Color(1.15, 1.12, 1.0, 1.0)
	else:
		figure.modulate = Color(0.78, 0.76, 0.74, 1.0)
