class_name CharacterPortraitContainer
extends Control

# CharacterPortraitContainer - Modern character portrait with status indicators
# Extends Control for flexible component usage (not full BaseUI scene)

# Signals
signal portrait_clicked(character_name: String)
signal health_percentage_changed(new_percentage: float)
signal status_effect_added(effect_type: String)
signal status_effect_removed(effect_type: String)

# Constants
const PORTRAIT_SIZE = Vector2(120, 120)  # AC-2.3.1: 120x120px sizing
const HEALTH_BAR_HEIGHT = 8  # Thin overlay bar
const STATUS_ICON_SIZE = 24
const MAX_STATUS_ICONS = 4  # Maximum icons to display
const UI_THEME = preload("res://resources/ui_theme.tres")

# Export properties
@export var character_name: String = "Unknown"
@export var portrait_texture: Texture2D:
	set(value):
		portrait_texture = value
		_update_portrait_display()

@export var health_percentage: float = 100.0:
	set(value):
		health_percentage = clamp(value, 0.0, 100.0)
		_update_health_bar()
		health_percentage_changed.emit(health_percentage)

@export var is_active: bool = false:
	set(value):
		is_active = value
		_update_active_state()

@export var show_health_bar: bool = true
@export var show_status_effects: bool = true
@export var respect_reduced_motion: bool = true

# Internal state
var active_tween: Tween = null
var status_effects: Dictionary = {}  # effect_type -> StatusEffectIcon
var reduced_motion_enabled: bool = false

# UI Components
@onready var portrait_panel: Panel = $PortraitPanel
@onready var portrait_image: TextureRect = $PortraitPanel/PortraitImage
@onready var health_bar: ProgressBar = $HealthBar
@onready var status_container: HBoxContainer = $StatusContainer

func _ready():
	# Set fixed size for portrait container
	custom_minimum_size = PORTRAIT_SIZE
	size = PORTRAIT_SIZE

	# Check reduced motion setting
	reduced_motion_enabled = _is_reduced_motion_enabled()

	# Setup UI components
	_setup_portrait_panel()
	_setup_health_bar()
	_setup_status_container()

	# Update initial state
	_update_portrait_display()
	_update_health_bar()
	_update_active_state()

	# Connect signals
	_connect_signals()

func _exit_tree():
	# Clean up active tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

func _setup_portrait_panel():
	# Setup modern border with drop shadow using theme
	if portrait_panel:
		# Apply theme styling
		_apply_portrait_theme()

		# Enable mouse interaction
		portrait_panel.mouse_filter = Control.MOUSE_FILTER_PASS

func _apply_portrait_theme():
	# Apply modern styling from ui_theme.tres
	var theme = self.theme
	if not theme:
		# Load default theme if none set
		theme = UI_THEME

	if portrait_panel:
		# Create modern stylebox with drop shadow
		var portrait_style = StyleBoxFlat.new()

		# Background
		portrait_style.bg_color = Color(0.15, 0.2, 0.25, 0.9)  # Semi-transparent dark

		# Border
		portrait_style.border_width_left = 2
		portrait_style.border_width_top = 2
		portrait_style.border_width_right = 2
		portrait_style.border_width_bottom = 2
		portrait_style.border_color = Color(0.4, 0.95, 0.84, 0.6)  # Accent color

		# Corner radius for modern look
		portrait_style.corner_radius_top_left = 8
		portrait_style.corner_radius_top_right = 8
		portrait_style.corner_radius_bottom_left = 8
		portrait_style.corner_radius_bottom_right = 8

		# Drop shadow
		portrait_style.shadow_color = Color(0, 0, 0, 0.3)
		portrait_style.shadow_size = 4
		portrait_style.shadow_offset = Vector2(2, 2)

		portrait_panel.add_theme_stylebox_override("panel", portrait_style)

func _setup_health_bar():
	# Setup health bar as overlay
	if health_bar:
		health_bar.custom_minimum_size = Vector2(PORTRAIT_SIZE.x - 8, HEALTH_BAR_HEIGHT)
		health_bar.size = Vector2(PORTRAIT_SIZE.x - 8, HEALTH_BAR_HEIGHT)

		# Position at bottom of portrait
		health_bar.position = Vector2(4, PORTRAIT_SIZE.y - HEALTH_BAR_HEIGHT - 4)

		# Configure health bar
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = health_percentage
		health_bar.show_percentage = false  # Just show bar, no text

		# Apply health bar theme colors
		_apply_health_bar_theme()

		health_bar.visible = show_health_bar

func _apply_health_bar_theme():
	# Apply health bar colors from theme
	var theme = self.theme
	if not theme:
		theme = UI_THEME

	if health_bar:
		# Create style for health bar fill
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = _get_health_color(health_percentage)
		fill_style.corner_radius_top_left = 2
		fill_style.corner_radius_top_right = 2
		fill_style.corner_radius_bottom_left = 2
		fill_style.corner_radius_bottom_right = 2

		health_bar.add_theme_stylebox_override("fill", fill_style)

		# Background style
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		bg_style.corner_radius_top_left = 2
		bg_style.corner_radius_top_right = 2
		bg_style.corner_radius_bottom_left = 2
		bg_style.corner_radius_bottom_right = 2

		health_bar.add_theme_stylebox_override("background", bg_style)

func _setup_status_container():
	# Setup status effect container
	if status_container:
		# Position in bottom-right corner
		var status_x = PORTRAIT_SIZE.x - (MAX_STATUS_ICONS * (STATUS_ICON_SIZE + 2)) - 4
		var status_y = PORTRAIT_SIZE.y - STATUS_ICON_SIZE - 4
		status_container.position = Vector2(status_x, status_y)
		status_container.custom_minimum_size = Vector2(MAX_STATUS_ICONS * (STATUS_ICON_SIZE + 2), STATUS_ICON_SIZE)
		status_container.size = Vector2(MAX_STATUS_ICONS * (STATUS_ICON_SIZE + 2), STATUS_ICON_SIZE)

		# Configure container
		status_container.add_theme_constant_override("separation", 2)
		status_container.visible = show_status_effects

func _connect_signals():
	# Connect portrait panel click
	if portrait_panel:
		portrait_panel.connect("gui_input", Callable(self, "_on_portrait_input"))

func _on_portrait_input(event: InputEvent):
	# Handle portrait click/touch
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		portrait_clicked.emit(character_name)

func _update_portrait_display():
	# Update portrait image
	if portrait_image and portrait_texture:
		portrait_image.texture = portrait_texture
		portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_image.size = PORTRAIT_SIZE - Vector2(4, 4)  # Account for border
		portrait_image.position = Vector2(2, 2)

func _update_health_bar():
	# Update health bar value and color
	if health_bar:
		health_bar.value = health_percentage

		# Update color based on health percentage
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style is StyleBoxFlat:
			fill_style.bg_color = _get_health_color(health_percentage)
			health_bar.add_theme_stylebox_override("fill", fill_style)

func _get_health_color(percentage: float) -> Color:
	# Get health color based on percentage using theme colors (AC-2.3.1)
	var theme = self.theme
	if not theme:
		theme = UI_THEME

	if percentage >= 50.0:
		# Use theme success color for healthy
		return theme.get_color("success", "Colors") if theme.has_color("success", "Colors") else Color(0.2, 0.8, 0.2, 1.0)
	if percentage >= 25.0:
		# Use theme accent color for warning
		return theme.get_color("accent", "Colors") if theme.has_color("accent", "Colors") else Color(0.9, 0.6, 0.1, 1.0)
	# Use theme danger color for critical
	return theme.get_color("danger", "Colors") if theme.has_color("danger", "Colors") else Color(0.8, 0.2, 0.2, 1.0)

func _update_active_state():
	# Update active state visual feedback (AC-2.3.1, AC-2.3.2)
	if is_active:
		_start_active_glow()
	else:
		_stop_active_glow()

func _start_active_glow():
	# Start subtle glow/pulse effect for active character
	if reduced_motion_enabled and respect_reduced_motion:
		# Static glow for reduced motion
		if portrait_panel:
			portrait_panel.modulate = Color(1.1, 1.1, 1.0, 1.0)
		return

	# Kill existing tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Create pulse animation
	active_tween = create_tween()
	active_tween.set_loops()
	active_tween.set_ease(Tween.EASE_IN_OUT)
	active_tween.set_trans(Tween.TRANS_SINE)

	# Subtle pulse effect
	var normal_modulate = Color.WHITE
	var glow_modulate = Color(1.15, 1.15, 1.05, 1.0)  # Subtle yellow-white glow

	active_tween.tween_property(portrait_panel, "modulate", glow_modulate, 1.0)
	active_tween.tween_property(portrait_panel, "modulate", normal_modulate, 1.0)

func _stop_active_glow():
	# Stop active glow effect
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

	if portrait_panel:
		portrait_panel.modulate = Color.WHITE

func add_status_effect(effect_type: String) -> void:
	# Add status effect icon (AC-2.3.1)
	if not show_status_effects or status_effects.has(effect_type):
		return

	# Create status effect icon
	var status_icon = StatusEffectIcon.new()
	status_icon.effect_type = effect_type
	status_icon.custom_minimum_size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	status_icon.size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)

	status_container.add_child(status_icon)
	status_effects[effect_type] = status_icon

	status_effect_added.emit(effect_type)

	# Update container visibility
	status_container.visible = show_status_effects and status_effects.size() > 0

func remove_status_effect(effect_type: String) -> void:
	# Remove status effect icon
	if not status_effects.has(effect_type):
		return

	var status_icon = status_effects[effect_type]
	if status_icon:
		status_container.remove_child(status_icon)
		status_icon.queue_free()

	status_effects.erase(effect_type)
	status_effect_removed.emit(effect_type)

	# Update container visibility
	status_container.visible = show_status_effects and status_effects.size() > 0

func clear_status_effects() -> void:
	# Remove all status effects
	var effects_to_remove = status_effects.keys()
	for effect_type in effects_to_remove:
		remove_status_effect(effect_type)

func set_character_data(name: String, texture: Texture2D, health_pct: float):
	# Set all character data at once
	character_name = name
	portrait_texture = texture
	health_percentage = health_pct

func _is_reduced_motion_enabled() -> bool:
	# Check for reduced motion accessibility setting
	return ProjectSettings.get_setting("accessibility/reduced_motion", false)

func _get_minimum_size() -> Vector2:
	# Ensure minimum size constraints
	return PORTRAIT_SIZE

# Accessibility methods (AC-2.4.1)

func get_character_name() -> String:
	return character_name

func get_health_status_text() -> String:
	# Get descriptive health status for screen readers
	if health_percentage >= 75.0:
		return "Healthy"
	if health_percentage >= 50.0:
		return "Injured"
	if health_percentage >= 25.0:
		return "Badly injured"
	return "Critical"

func get_status_effects_text() -> String:
	# Get status effects description for screen readers
	if status_effects.is_empty():
		return "No status effects"

	var effect_names = []
	for effect_type in status_effects.keys():
		effect_names.append(effect_type.capitalize())

	return "Status effects: " + ", ".join(effect_names)

func _get_tooltip_text() -> String:
	# Get comprehensive tooltip text
	var lines = []
	lines.append(character_name)
	lines.append("Health: %s (%.0f%%)" % [get_health_status_text(), health_percentage])

	if not status_effects.is_empty():
		lines.append(get_status_effects_text())

	if is_active:
		lines.append("Active Turn")

	return "\n".join(lines)