class_name CombatActionCard
extends Button

# Structured combat dock card: icon + title + subtitle cluster.

signal card_pressed

enum Kind { PRIMARY, SECONDARY, DANGER }

const StageChrome = preload("res://scripts/ui/CombatStageChrome.gd")

@export var kind: Kind = Kind.SECONDARY

var _icon_rect: TextureRect
var _title_label: Label
var _sub_label: Label
var _vbox: VBoxContainer
var _built: bool = false


func _ready() -> void:
	_build_if_needed()
	_apply_kind_style()
	# Re-apply next frame so theme overrides win over any late Button defaults.
	call_deferred("_apply_kind_style")
	if not pressed.is_connected(_on_card_pressed_internal):
		pressed.connect(_on_card_pressed_internal)


func _on_card_pressed_internal() -> void:
	card_pressed.emit()


func setup(
	title: String,
	subtitle: String,
	card_kind: Kind = Kind.SECONDARY,
	icon_tex: Texture2D = null
) -> void:
	kind = card_kind
	_build_if_needed()
	set_title(title)
	set_subtitle(subtitle)
	set_icon_texture(icon_tex)
	_apply_kind_style()


func set_title(title: String) -> void:
	_build_if_needed()
	if _title_label:
		_title_label.text = title
	# Keep Button text empty so only labels show (avoid double draw).
	text = ""
	if get("button_text") != null:
		set("button_text", "")


func set_subtitle(subtitle: String) -> void:
	_build_if_needed()
	if _sub_label:
		_sub_label.text = subtitle
		_sub_label.visible = subtitle != ""


func set_icon_texture(tex: Texture2D) -> void:
	_build_if_needed()
	if _icon_rect == null:
		return
	_icon_rect.texture = tex
	_icon_rect.visible = tex != null


func set_card_disabled(disabled_flag: bool) -> void:
	disabled = disabled_flag
	modulate = Color(1, 1, 1, 0.55) if disabled_flag else Color.WHITE


func _build_if_needed() -> void:
	if _built:
		return
	_built = true
	# flat=true skips stylebox backgrounds — keep false so card plates render.
	flat = false
	focus_mode = Control.FOCUS_ALL
	clip_text = false
	custom_minimum_size = Vector2(180, 88)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Clear default icon so Button doesn't draw left-aligned sword away from title.
	icon = null
	expand_icon = false
	text = ""
	# Ensure theme doesn't override our StyleBoxFlat plates
	theme = null

	_vbox = VBoxContainer.new()
	_vbox.name = "CardContent"
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_vbox)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.custom_minimum_size = Vector2(28, 28)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.visible = false
	_vbox.add_child(_icon_rect)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_title_label)

	_sub_label = Label.new()
	_sub_label.name = "Subtitle"
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_sub_label)


func _apply_kind_style() -> void:
	match kind:
		Kind.PRIMARY:
			StageChrome.style_action_card_primary(self, _title_label, _sub_label)
		Kind.DANGER:
			StageChrome.style_action_card_danger(self, _title_label, _sub_label)
		_:
			StageChrome.style_action_card_secondary(self, _title_label, _sub_label)
