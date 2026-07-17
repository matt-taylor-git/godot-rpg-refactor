class_name CombatTurnBanner
extends Control

# Top-center turn / round indicator — large intro then compact chip.

signal state_changed(state: String)

enum State { YOUR_TURN, ENEMY_TURN, VICTORY, DEFEAT }

const INTRO_DURATION := 0.28
const INTRO_HOLD := 0.6
const COMPACT_DURATION := 0.22

var reduced_motion: bool = false
var current_state: State = State.YOUR_TURN
var round_number: int = 1
var _is_compact: bool = false
var _tween: Tween = null

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var round_label: Label = $Panel/Margin/VBox/RoundLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel()
	_apply_typography()
	refresh_text()
	_set_compact_visual(true)


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled


func set_round(round_n: int) -> void:
	round_number = maxi(1, round_n)
	refresh_text()


func set_state(state: State, animate: bool = true) -> void:
	current_state = state
	refresh_text()
	emit_signal("state_changed", _state_key())
	if animate and not reduced_motion:
		play_intro()
	else:
		_set_compact_visual(true)


func play_intro() -> void:
	if reduced_motion:
		_set_compact_visual(true)
		return
	_kill_tween()
	_set_compact_visual(false)
	modulate.a = 0.0
	scale = Vector2(1.08, 1.08)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, INTRO_DURATION * 0.5)
	_tween.tween_property(self, "scale", Vector2.ONE, INTRO_DURATION).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(INTRO_HOLD)
	_tween.chain().tween_callback(func(): _animate_to_compact())


func refresh_text() -> void:
	if _is_compact:
		if title_label:
			title_label.text = _compact_text()
			title_label.add_theme_color_override("font_color", _color_for_state())
		if round_label:
			round_label.visible = false
	else:
		if title_label:
			title_label.text = _title_for_state()
			title_label.add_theme_color_override("font_color", _color_for_state())
		if round_label:
			round_label.visible = true
			round_label.text = "ROUND %d" % round_number


func _compact_text() -> String:
	match current_state:
		State.YOUR_TURN:
			return "Round %d · Your turn" % round_number
		State.ENEMY_TURN:
			return "Round %d · Enemy turn" % round_number
		State.VICTORY:
			return "Victory"
		State.DEFEAT:
			return "Defeat"
		_:
			return "Round %d" % round_number


func _title_for_state() -> String:
	match current_state:
		State.YOUR_TURN:
			return "YOUR TURN"
		State.ENEMY_TURN:
			return "ENEMY TURN"
		State.VICTORY:
			return "VICTORY"
		State.DEFEAT:
			return "DEFEAT"
		_:
			return "COMBAT"


func _color_for_state() -> Color:
	match current_state:
		State.YOUR_TURN:
			return UIThemeManager.get_color("title_gold")
		State.ENEMY_TURN:
			return UIThemeManager.get_color("danger").lightened(0.15)
		State.VICTORY:
			return UIThemeManager.get_color("success")
		State.DEFEAT:
			return UIThemeManager.get_color("danger")
		_:
			return UIThemeManager.get_text_primary_color()


func _state_key() -> String:
	match current_state:
		State.YOUR_TURN:
			return "your_turn"
		State.ENEMY_TURN:
			return "enemy_turn"
		State.VICTORY:
			return "victory"
		State.DEFEAT:
			return "defeat"
		_:
			return "unknown"


func _style_panel() -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.88)
	style.border_color = Color(0.75, 0.55, 0.25, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)


func _apply_typography() -> void:
	var cinzel_path := "res://assets/Cinzel-VariableFont_wght.ttf"
	var serif_path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
	if title_label and ResourceLoader.exists(cinzel_path):
		title_label.add_theme_font_override("font", load(cinzel_path))
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
		title_label.add_theme_constant_override("shadow_offset_x", 1)
		title_label.add_theme_constant_override("shadow_offset_y", 1)
	if round_label and ResourceLoader.exists(serif_path):
		round_label.add_theme_font_override("font", load(serif_path))
		round_label.add_theme_font_size_override("font_size", UITypography.FONT_SIZE_CAPTION)
		round_label.add_theme_color_override("font_color", UIThemeManager.get_color("secondary"))


func _set_compact_visual(compact: bool) -> void:
	_is_compact = compact
	if title_label:
		if compact:
			title_label.add_theme_font_size_override("font_size", 13)
			var serif_path := "res://assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf"
			if ResourceLoader.exists(serif_path):
				title_label.add_theme_font_override("font", load(serif_path))
		else:
			title_label.add_theme_font_size_override("font_size", 22)
			var cinzel_path := "res://assets/Cinzel-VariableFont_wght.ttf"
			if ResourceLoader.exists(cinzel_path):
				title_label.add_theme_font_override("font", load(cinzel_path))
	if panel:
		custom_minimum_size = Vector2(200, 32) if compact else Vector2(280, 64)
		if compact:
			offset_left = -100.0
			offset_right = 100.0
			offset_bottom = offset_top + 32.0
		else:
			offset_left = -140.0
			offset_right = 140.0
			offset_bottom = offset_top + 64.0
	refresh_text()
	modulate.a = 1.0
	scale = Vector2.ONE


func _animate_to_compact() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.9, 0.9), COMPACT_DURATION)
	_tween.tween_callback(func():
		_set_compact_visual(true)
		scale = Vector2.ONE
	)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _exit_tree() -> void:
	_kill_tween()
