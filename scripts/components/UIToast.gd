class_name UIToast
extends CanvasLayer

# UIToast - Floating banner for loot, level-up, save, and combat moments
# Visual only — audio hooks intentionally left for a future pass

enum Kind { INFO, SUCCESS, DANGER, LOOT, LEVEL_UP }

const DEFAULT_DURATION := 2.2
const FADE_DURATION := 0.25

var _panel: PanelContainer = null
var _label: Label = null
var _queue: Array = []  # Array of {text, kind, duration}
var _showing: bool = false
var _active_tween: Tween = null


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -220.0
	_panel.offset_right = 220.0
	_panel.offset_top = 24.0
	_panel.offset_bottom = 72.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	margin.add_child(_label)

	_apply_kind_style(Kind.INFO)


func show_toast(text: String, kind: Kind = Kind.INFO, duration: float = DEFAULT_DURATION) -> void:
	_queue.append({"text": text, "kind": kind, "duration": duration})
	if not _showing:
		_process_queue()


func show_info(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_toast(text, Kind.INFO, duration)


func show_success(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_toast(text, Kind.SUCCESS, duration)


func show_danger(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_toast(text, Kind.DANGER, duration)


func show_loot(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_toast(text, Kind.LOOT, duration)


func show_level_up(text: String, duration: float = DEFAULT_DURATION) -> void:
	show_toast(text, Kind.LEVEL_UP, duration)


func _process_queue() -> void:
	if _queue.is_empty():
		_showing = false
		visible = false
		return

	_showing = true
	visible = true
	var item: Dictionary = _queue.pop_front()
	_label.text = str(item.get("text", ""))
	_apply_kind_style(item.get("kind", Kind.INFO) as Kind)

	var reduce_motion: bool = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false
	)
	var duration: float = float(item.get("duration", DEFAULT_DURATION))

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_panel.modulate.a = 0.0
	if reduce_motion:
		_panel.modulate.a = 1.0
		await get_tree().create_timer(duration).timeout
		_panel.modulate.a = 0.0
		_process_queue()
		return

	_active_tween = create_tween()
	_active_tween.tween_property(_panel, "modulate:a", 1.0, FADE_DURATION)
	_active_tween.tween_interval(duration)
	_active_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	await _active_tween.finished
	if _active_tween:
		_active_tween.kill()
		_active_tween = null
	_process_queue()


func _apply_kind_style(kind: Kind) -> void:
	var bg := Color(0.08, 0.07, 0.06, 0.92)
	var border := UIThemeManager.get_color("border_bronze")
	var text_color := UIThemeManager.get_color("text_primary")

	match kind:
		Kind.SUCCESS:
			border = UIThemeManager.get_color("success")
			text_color = UIThemeManager.get_color("success")
		Kind.DANGER:
			border = UIThemeManager.get_color("danger")
			text_color = UIThemeManager.get_color("danger")
		Kind.LOOT:
			border = UIThemeManager.get_color("accent")
			text_color = UIThemeManager.get_color("title_gold")
		Kind.LEVEL_UP:
			border = UIThemeManager.get_color("title_gold")
			text_color = UIThemeManager.get_color("title_gold")
		_:
			pass

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	_panel.add_theme_stylebox_override("panel", style)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)


# Helper to show a toast on any node without requiring a scene instance
static func toast_on(host: Node, text: String, kind: Kind = Kind.INFO, duration: float = DEFAULT_DURATION) -> void:
	if host == null or not is_instance_valid(host):
		return
	var existing = host.get_tree().root.get_node_or_null("UIToastHost")
	if existing and existing is UIToast:
		(existing as UIToast).show_toast(text, kind, duration)
		return

	var toast := UIToast.new()
	toast.name = "UIToastHost"
	host.get_tree().root.add_child(toast)
	toast.show_toast(text, kind, duration)
