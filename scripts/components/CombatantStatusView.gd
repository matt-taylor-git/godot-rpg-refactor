class_name CombatantStatusView
extends PanelContainer

# Compact combatant identity and vitals for the fixed bottom status rail.

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")
const LOW_HP_FRAC := 0.25

@export var is_player_side: bool = true
@export var show_mana: bool = true

var reduced_motion: bool = false
var is_active: bool = false
var _low_hp: bool = false
var _compact: bool = false
var _pulse_tween: Tween = null

@onready var name_label: Label = $Margin/Vitals/HeaderRow/NameLabel
@onready var level_label: Label = $Margin/Vitals/HeaderRow/LevelLabel
@onready var status_container: HBoxContainer = $Margin/Vitals/HeaderRow/StatusRow
@onready var hp_row: HBoxContainer = $Margin/Vitals/HpRow
@onready var hp_label: Label = $Margin/Vitals/HpRow/HpLabel
@onready var health_bar: UIProgressBar = $Margin/Vitals/HpRow/HealthBar
@onready var hp_value: Label = $Margin/Vitals/HpRow/HpValue
@onready var hp_warning: Label = $Margin/Vitals/HpRow/HpWarning
@onready var mp_row: HBoxContainer = $Margin/Vitals/MpRow
@onready var mp_label: Label = $Margin/Vitals/MpRow/MpLabel
@onready var mana_bar: UIProgressBar = $Margin/Vitals/MpRow/ManaBar
@onready var mp_value: Label = $Margin/Vitals/MpRow/MpValue


func _ready() -> void:
	_configure_bars()
	_style_labels()
	mp_row.visible = show_mana and is_player_side
	_refresh_style()


func set_identity(combatant_name: String, level: int = 1, extra: String = "") -> void:
	name_label.text = combatant_name.to_upper()
	level_label.text = "Lv. %d" % level
	if not extra.is_empty():
		level_label.text += "  %s" % extra


func set_health(current: float, maximum: float, animate: bool = true) -> void:
	var safe_max := maxf(1.0, maximum)
	health_bar.max_value = safe_max
	if animate:
		health_bar.set_value_animated(current, true)
	else:
		health_bar.value = current
	hp_value.text = "%d/%d" % [int(current), int(maximum)]
	_low_hp = current > 0.0 and current / safe_max <= LOW_HP_FRAC
	hp_warning.visible = _low_hp
	_refresh_style()
	_refresh_low_hp_pulse()


func set_mana(current: float, maximum: float, animate: bool = true) -> void:
	if maximum <= 0.0:
		mp_row.visible = false
		return
	mp_row.visible = show_mana and is_player_side
	mana_bar.max_value = maximum
	if animate:
		mana_bar.set_value_animated(current, true)
	else:
		mana_bar.value = current
	mp_value.text = "%d/%d" % [int(current), int(maximum)]


func set_active(active: bool) -> void:
	is_active = active
	_refresh_style()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	health_bar.respect_reduced_motion = enabled
	mana_bar.respect_reduced_motion = enabled
	_refresh_low_hp_pulse()


func set_compact_layout(enabled: bool) -> void:
	_compact = enabled
	custom_minimum_size.y = 64.0 if enabled else 68.0
	name_label.add_theme_font_size_override("font_size", 14 if enabled else 16)
	level_label.add_theme_font_size_override("font_size", 11 if enabled else 12)
	for label in [hp_label, mp_label, hp_value, mp_value, hp_warning]:
		label.add_theme_font_size_override("font_size", 11 if enabled else 12)


func clear_status_effects() -> void:
	for child in status_container.get_children():
		child.queue_free()


func add_status_effect(effect_type: String, duration: int = 0) -> void:
	var badge := Label.new()
	badge.text = effect_type.left(1).to_upper()
	badge.tooltip_text = effect_type.capitalize()
	if duration > 0:
		badge.tooltip_text += " (%d turns)" % duration
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", UIThemeManager.get_color("accent"))
	status_container.add_child(badge)


func _configure_bars() -> void:
	for bar in [health_bar, mana_bar]:
		bar.compact_noninteractive = true
		bar.responsive_scaling = false
		bar.connect_to_gamemanager = false
		bar.show_value_text = false
		bar.enable_damage_trail = true
		bar.custom_minimum_size = Vector2(92, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mana_bar.bar_kind = "mana"


func _style_labels() -> void:
	var display_path := "res://assets/Cinzel-VariableFont_wght.ttf"
	var body_path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if ResourceLoader.exists(display_path):
		name_label.add_theme_font_override("font", load(display_path))
	if ResourceLoader.exists(body_path):
		var body_font: Font = load(body_path)
		for label in [level_label, hp_label, mp_label, hp_value, mp_value, hp_warning]:
			label.add_theme_font_override("font", body_font)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", UIThemeManager.get_color("title_gold"))
	level_label.add_theme_color_override("font_color", UIThemeManager.get_color("secondary"))
	for label in [level_label, hp_label, mp_label, hp_value, mp_value]:
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", UIThemeManager.get_text_primary_color())
	hp_warning.add_theme_font_size_override("font_size", 12)
	hp_warning.add_theme_color_override("font_color", UIThemeManager.get_color("danger"))


func _refresh_style() -> void:
	StageChrome.style_status_plate(self, is_active, _low_hp)


func _refresh_low_hp_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	health_bar.modulate = Color.WHITE
	if not _low_hp or reduced_motion:
		return
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(health_bar, "modulate", Color(1.24, 0.82, 0.82, 1.0), 0.55)
	_pulse_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.55)


func _exit_tree() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
