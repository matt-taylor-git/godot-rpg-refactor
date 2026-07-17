class_name CombatantStageView
extends Control

# Frameless combatant figure with attached HUD (name, labeled HP/MP, status).

signal figure_ready

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const FIGURE_SIZE := Vector2(280, 280)
const BAR_MIN := Vector2(160, 22)
## Soft contact shadow: ~60% of figure width, blue-black, 25–35% opacity.
const SHADOW_WIDTH_RATIO := 0.60
const SHADOW_OPACITY := 0.30
const SHADOW_HEIGHT_PX := 28
const LOW_HP_FRAC := 0.25

# Cool environmental grade (shared treatment for all combatants)
const GRADE_ACTIVE := Color(0.96, 0.97, 1.05, 1.0)
const GRADE_IDLE := Color(0.82, 0.84, 0.90, 1.0)
const GRADE_ENEMY_DESAT := Color(0.88, 0.90, 0.96, 1.0)

@export var show_mana: bool = true
@export var is_player_side: bool = true

var reduced_motion: bool = false
var is_active: bool = false:
	set(value):
		is_active = value
		_update_active_visual()
var _hp_pulse_tween: Tween = null
var _low_hp: bool = false
var _intent_icon: TextureRect = null
var _hp_warn_icon: Label = null
var _soft_shadow_tex: Texture2D = null

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
@onready var intent_panel: PanelContainer = $FigureStack/IntentPanel
@onready var intent_label: Label = $FigureStack/IntentPanel/IntentMargin/IntentLabel


func _ready() -> void:
	custom_minimum_size = Vector2(300, 400)
	if figure:
		figure.custom_minimum_size = FIGURE_SIZE
		figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_soft_shadow()
	_setup_foot_fog()
	_setup_intent_icon()
	_setup_hp_warn_icon()
	_style_labels()
	_configure_bars()
	StageChrome.style_hud_plate(hud_plate)
	if intent_panel:
		intent_panel.visible = not is_player_side
		StageChrome.style_intent_chip(intent_panel)
	if mp_row:
		mp_row.visible = show_mana and is_player_side
	_update_active_visual()
	emit_signal("figure_ready")


func get_figure_node() -> CanvasItem:
	return figure


func set_figure_texture(tex: Texture2D) -> void:
	if figure:
		figure.texture = tex
		call_deferred("_layout_shadow_under_feet")


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
	_update_low_hp_cues(current, maximum)


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


func set_intent(text: String, show_attack_icon: bool = true) -> void:
	if intent_panel == null or intent_label == null:
		return
	if is_player_side:
		intent_panel.visible = false
		return
	intent_label.text = text
	intent_panel.visible = text != ""
	if _intent_icon:
		_intent_icon.visible = show_attack_icon and text != ""


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
	if enabled and _hp_pulse_tween and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
		_hp_pulse_tween = null
		if health_bar:
			health_bar.modulate = Color.WHITE


func _setup_soft_shadow() -> void:
	if contact_shadow == null:
		return
	if _soft_shadow_tex == null:
		_soft_shadow_tex = _make_soft_ellipse_texture(128, 48)
	contact_shadow.texture = _soft_shadow_tex
	contact_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	contact_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	contact_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Blue-black tint, 25–35% opacity
	contact_shadow.modulate = Color(0.08, 0.10, 0.16, SHADOW_OPACITY)
	contact_shadow.visible = true
	_layout_shadow_under_feet()


func _layout_shadow_under_feet() -> void:
	if contact_shadow == null or figure == null:
		return
	var fig_w: float = FIGURE_SIZE.x
	var shadow_w: float = fig_w * SHADOW_WIDTH_RATIO
	var shadow_h: float = float(SHADOW_HEIGHT_PX)
	# Anchored under feet (bottom center of figure stack)
	contact_shadow.anchor_left = 0.5
	contact_shadow.anchor_right = 0.5
	contact_shadow.anchor_top = 1.0
	contact_shadow.anchor_bottom = 1.0
	contact_shadow.offset_left = -shadow_w * 0.5
	contact_shadow.offset_right = shadow_w * 0.5
	contact_shadow.offset_top = -shadow_h * 0.55
	contact_shadow.offset_bottom = shadow_h * 0.45
	contact_shadow.z_index = -1


func _setup_foot_fog() -> void:
	# Soft procedural fog band — shared cool grade, not chroma-keyed PNGs
	if foot_mist == null:
		return
	if _soft_shadow_tex == null:
		_soft_shadow_tex = _make_soft_ellipse_texture(128, 48)
	foot_mist.texture = _soft_shadow_tex
	foot_mist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot_mist.stretch_mode = TextureRect.STRETCH_SCALE
	foot_mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot_mist.modulate = Color(0.55, 0.62, 0.72, 0.18)
	foot_mist.anchor_left = 0.5
	foot_mist.anchor_right = 0.5
	foot_mist.anchor_top = 1.0
	foot_mist.anchor_bottom = 1.0
	var fog_w: float = FIGURE_SIZE.x * 0.85
	foot_mist.offset_left = -fog_w * 0.5
	foot_mist.offset_right = fog_w * 0.5
	foot_mist.offset_top = -42.0
	foot_mist.offset_bottom = 6.0
	foot_mist.z_index = 1
	foot_mist.visible = true


func _make_soft_ellipse_texture(width: int, height: int) -> Texture2D:
	# Radial soft ellipse: denser center, smooth falloff (blur-like).
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (width - 1) * 0.5
	var cy := (height - 1) * 0.5
	var rx := maxf(1.0, width * 0.5)
	var ry := maxf(1.0, height * 0.5)
	for y in range(height):
		for x in range(width):
			var nx: float = (x - cx) / rx
			var ny: float = (y - cy) / ry
			var d: float = sqrt(nx * nx + ny * ny)
			var a: float = 0.0
			if d < 1.0:
				var t: float = 1.0 - d
				a = t * t * (3.0 - 2.0 * t)
				a = pow(a, 1.35)
			if a > 0.004:
				img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _setup_intent_icon() -> void:
	if intent_panel == null or is_player_side:
		return
	var margin = intent_panel.get_node_or_null("IntentMargin")
	if margin == null:
		return
	# Rebuild intent row as icon + label
	var existing = margin.get_node_or_null("IntentLabel")
	var row := HBoxContainer.new()
	row.name = "IntentRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	_intent_icon = TextureRect.new()
	_intent_icon.name = "IntentIcon"
	_intent_icon.custom_minimum_size = Vector2(16, 16)
	_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/icon_sword.png"):
		_intent_icon.texture = load("res://assets/icon_sword.png")
	row.add_child(_intent_icon)
	if existing:
		margin.remove_child(existing)
		row.add_child(existing)
		intent_label = existing
	else:
		var lbl := Label.new()
		lbl.name = "IntentLabel"
		row.add_child(lbl)
		intent_label = lbl
	# Clear other children
	for c in margin.get_children():
		margin.remove_child(c)
		c.queue_free()
	margin.add_child(row)


func _setup_hp_warn_icon() -> void:
	if hp_row == null:
		return
	_hp_warn_icon = Label.new()
	_hp_warn_icon.name = "HpWarn"
	_hp_warn_icon.text = "!"
	_hp_warn_icon.visible = false
	_hp_warn_icon.add_theme_font_size_override("font_size", 14)
	_hp_warn_icon.add_theme_color_override("font_color", UIThemeManager.get_color("danger"))
	_hp_warn_icon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hp_warn_icon.add_theme_constant_override("shadow_offset_x", 1)
	_hp_warn_icon.add_theme_constant_override("shadow_offset_y", 1)
	_hp_warn_icon.tooltip_text = "Low health"
	hp_row.add_child(_hp_warn_icon)
	# Place after hp_value if present
	if hp_value:
		hp_row.move_child(_hp_warn_icon, hp_value.get_index() + 1)


func _update_low_hp_cues(current: float, maximum: float) -> void:
	var frac := 1.0
	if maximum > 0.0:
		frac = current / maximum
	_low_hp = frac <= LOW_HP_FRAC and current > 0.0
	if _hp_warn_icon:
		_hp_warn_icon.visible = _low_hp
	if hud_plate and _low_hp:
		# Subtle damaged frame
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.04, 0.04, 0.82)
		style.border_color = Color(0.75, 0.25, 0.22, 0.65)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.shadow_color = Color(0.4, 0.05, 0.05, 0.35)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 2)
		style.set_content_margin_all(10)
		hud_plate.add_theme_stylebox_override("panel", style)
	elif hud_plate:
		StageChrome.style_hud_plate(hud_plate)
	_start_or_stop_hp_pulse()


func _start_or_stop_hp_pulse() -> void:
	if health_bar == null:
		return
	if _hp_pulse_tween and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
		_hp_pulse_tween = null
	health_bar.modulate = Color.WHITE
	if not _low_hp or reduced_motion:
		return
	_hp_pulse_tween = create_tween()
	_hp_pulse_tween.set_loops()
	_hp_pulse_tween.tween_property(health_bar, "modulate", Color(1.25, 0.85, 0.85, 1.0), 0.55)
	_hp_pulse_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.55)


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
	# Shared cool environmental grade; enemies slightly desaturated for harmony
	if is_player_side:
		figure.modulate = GRADE_ACTIVE if is_active else GRADE_IDLE
	else:
		var base := GRADE_ENEMY_DESAT
		if is_active:
			figure.modulate = base.lightened(0.08)
		else:
			figure.modulate = base.darkened(0.06)


func _exit_tree() -> void:
	if _hp_pulse_tween and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
