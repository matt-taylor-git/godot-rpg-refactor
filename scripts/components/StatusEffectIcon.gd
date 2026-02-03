class_name StatusEffectIcon
extends Control

# StatusEffectIcon - 24x24px overlay icon for status effects on progress bars
# Provides visual indication of active effects with tooltips

@export var effect_type: String = "unknown":
	set(value):
		effect_type = value
		_update_icon()

@export var show_tooltip: bool = true

# Internal state
var icon_texture: TextureRect = null
var tooltip_panel: Panel = null
var tooltip_label: Label = null
var is_hovered: bool = false

func _ready():
	# Set fixed size for status effect icons
	custom_minimum_size = Vector2(24, 24)
	size = Vector2(24, 24)

	# Enable focus for keyboard accessibility
	focus_mode = FOCUS_ALL
	set_focus_neighbor(SIDE_BOTTOM, get_path())
	set_focus_neighbor(SIDE_TOP, get_path())

	# Create child nodes
	_create_child_nodes()

	# Update icon based on effect type
	_update_icon()

	# Connect mouse signals for tooltip
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	# Connect focus signals for keyboard accessibility
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	connect("focus_exited", Callable(self, "_on_focus_exited"))

func _create_child_nodes():
	# Create icon texture
	if not has_node("IconTexture"):
		icon_texture = TextureRect.new()
		icon_texture.name = "IconTexture"
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.size = Vector2(20, 20)  # Slightly smaller than container
		icon_texture.position = Vector2(2, 2)  # Center in 24x24 container
		add_child(icon_texture)

	# Create tooltip panel (initially hidden)
	if not has_node("TooltipPanel"):
		tooltip_panel = Panel.new()
		tooltip_panel.name = "TooltipPanel"
		tooltip_panel.visible = false
		add_child(tooltip_panel)

		# Create tooltip label
		tooltip_label = Label.new()
		tooltip_label.name = "TooltipLabel"
		tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tooltip_panel.add_child(tooltip_label)

func _update_icon():
	if not icon_texture:
		return

	# Load appropriate icon based on effect type
	var icon_path = _get_icon_path_for_effect(effect_type)
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
	else:
		# Fallback: create colored rectangle based on effect type
		_create_fallback_icon()

	# Update tooltip text
	if tooltip_label:
		tooltip_label.text = _get_tooltip_text_for_effect(effect_type)

func _get_icon_path_for_effect(effect_type: String) -> String:
	# Return icon path for effect type
	match effect_type:
		"poison":
			return "res://assets/ui/icons/status_poison.png"
		"buff":
			return "res://assets/ui/icons/status_buff.png"
		"debuff":
			return "res://assets/ui/icons/status_debuff.png"
		"burn":
			return "res://assets/ui/icons/status_burn.png"
		"freeze":
			return "res://assets/ui/icons/status_freeze.png"
		_:
			return "res://assets/ui/icons/status_unknown.png"

func _create_fallback_icon():
	# Create colored rectangle as fallback icon
	var icon_color = _get_color_for_effect(effect_type)
	var icon_image = Image.create(20, 20, false, Image.FORMAT_RGBA8)

	for x in range(20):
		for y in range(20):
			icon_image.set_pixel(x, y, icon_color)

	icon_texture.texture = ImageTexture.create_from_image(icon_image)

func _get_color_for_effect(effect_type: String) -> Color:
	# Return color for effect type (fallback when no icon available)
	match effect_type:
		"poison":
			return Color(0.2, 0.8, 0.2, 1.0)  # Green
		"buff":
			return Color(1.0, 0.9, 0.2, 1.0)   # Gold
		"debuff":
			return Color(0.8, 0.2, 0.2, 1.0)  # Red
		"burn":
			return Color(1.0, 0.4, 0.1, 1.0)   # Orange
		"freeze":
			return Color(0.4, 0.8, 1.0, 1.0)  # Light blue
		_:
			return Color(0.5, 0.5, 0.5, 1.0)   # Gray

func _get_tooltip_text_for_effect(effect_type: String) -> String:
	# Return tooltip text for effect type
	match effect_type:
		"poison":
			return "Poison: Taking damage over time"
		"buff":
			return "Buff: Enhanced abilities"
		"debuff":
			return "Debuff: Reduced effectiveness"
		"burn":
			return "Burn: Fire damage over time"
		"freeze":
			return "Freeze: Movement slowed"
		_:
			return "Unknown Effect"

func _on_mouse_entered():
	is_hovered = true
	if show_tooltip and tooltip_panel:
		_show_tooltip()

func _on_mouse_exited():
	is_hovered = false
	if tooltip_panel:
		tooltip_panel.visible = false

func _on_focus_entered():
	# Show tooltip when focused via keyboard
	_show_tooltip()

func _on_focus_exited():
	# Hide tooltip when focus lost
	if tooltip_panel:
		tooltip_panel.visible = false

func _show_tooltip():
	if not tooltip_panel or not tooltip_label:
		return

	# Get global mouse position for tooltip placement
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size

	# Calculate tooltip position (prefer above, fallback to below if near top)
	var tooltip_height = 30
	var tooltip_pos = mouse_pos + Vector2(-50, -tooltip_height - 5)  # Above mouse

	# Check if tooltip would go off-screen
	if tooltip_pos.y < 0:
		tooltip_pos = mouse_pos + Vector2(-50, 25)  # Below mouse instead

	# Keep tooltip within viewport bounds
	tooltip_pos.x = clamp(tooltip_pos.x, 5, viewport_size.x - 105)
	tooltip_pos.y = clamp(tooltip_pos.y, 5, viewport_size.y - tooltip_height - 5)

	tooltip_panel.global_position = tooltip_pos

	# Size tooltip to fit text
	var text_size = tooltip_label.get_minimum_size()
	tooltip_panel.size = Vector2(max(100, text_size.x + 10), text_size.y + 6)  # Minimum width
	tooltip_label.position = Vector2(5, 3)
	tooltip_label.size = text_size

	# Apply tooltip styling with high contrast (WCAG AA)
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)  # Dark background
	tooltip_style.border_width_left = 1
	tooltip_style.border_width_top = 1
	tooltip_style.border_width_right = 1
	tooltip_style.border_width_bottom = 1
	tooltip_style.border_color = Color(0.8, 0.8, 0.8, 1.0)  # Light border
	tooltip_style.corner_radius_top_left = 4
	tooltip_style.corner_radius_top_right = 4
	tooltip_style.corner_radius_bottom_right = 4
	tooltip_style.corner_radius_bottom_left = 4
	tooltip_style.shadow_color = Color(0, 0, 0, 0.5)
	tooltip_style.shadow_size = 2

	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)

	tooltip_panel.visible = true

func _get_minimum_size() -> Vector2:
	return Vector2(24, 24)  # Fixed size for status effect icons