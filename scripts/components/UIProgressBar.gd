extends ProgressBar
class_name UIProgressBar

# UIProgressBar - Enhanced progress bar with gradient fills, status effects, and animations
# Extends ProgressBar for full customization while maintaining progress bar behavior

# Preload StatusEffectIcon to avoid circular dependencies
const StatusEffectIcon = preload("res://scripts/components/StatusEffectIcon.gd")

# Signals
signal value_changed_animated(new_value: float, old_value: float)  # Animated value change
signal status_effect_added(effect_type: String)  # Status effect overlay added
signal status_effect_removed(effect_type: String)  # Status effect overlay removed

# Health percentage thresholds (AC-2.1.1)
const HEALTH_GREEN_THRESHOLD = 50.0   # 100-50%: Green
const HEALTH_YELLOW_THRESHOLD = 25.0  # 50-25%: Yellow
# 25-0%: Red

# Animation constants (AC-2.1.3)
const ANIMATION_DURATION = 0.3  # 300ms for smooth health transitions
const ANIMATION_EASE = Tween.EASE_OUT
const ANIMATION_TRANS = Tween.TRANS_QUAD

# Export properties
@export var show_value_text: bool = true  # Show current/maximum values
@export var animate_value_changes: bool = true  # Enable smooth value transitions
@export var enable_gradient_fill: bool = true  # Use gradient instead of solid color
@export var enable_status_effects: bool = true  # Allow status effect overlays
@export var responsive_scaling: bool = true  # Scale based on screen resolution
@export var connect_to_gamemanager: bool = true  # Auto-connect to GameManager signals
@export var colorblind_friendly: bool = false  # Use patterns/text instead of color-only indicators
@export var respect_reduced_motion: bool = true  # Disable animations if reduced motion is enabled

# Internal state
var active_tween: Tween = null
var current_gradient: Gradient = null
var status_effects: Dictionary = {}  # effect_type -> StatusEffectIcon
var original_modulate: Color = Color.WHITE
var target_value: float = 0.0
var gamemanager_connected: bool = false

# Performance monitoring
var animation_start_time: float = 0.0
var frame_count_during_animation: int = 0
var min_fps_during_animation: float = 60.0

# UI components
var value_label: Label = null
var gradient_texture: TextureRect = null
var status_container: Control = null

func _ready():
	# Store original modulate for animations
	original_modulate = modulate

	# Create child nodes
	_create_child_nodes()

	# Initialize gradient
	_setup_gradient()

	# Set initial value
	target_value = value

	# Apply theme
	_apply_theme()

	# Connect to GameManager if enabled
	if connect_to_gamemanager:
		_connect_to_gamemanager()

	# Update visual state
	_update_visual_state()

func _exit_tree():
	# Clean up active tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

func _create_child_nodes():
	# Create gradient texture for fill visualization
	if not has_node("GradientTexture"):
		gradient_texture = TextureRect.new()
		gradient_texture.name = "GradientTexture"
		gradient_texture.mouse_filter = MOUSE_FILTER_IGNORE
		gradient_texture.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(gradient_texture)
	else:
		gradient_texture = $GradientTexture

	# Create value label
	if not has_node("ValueLabel"):
		value_label = Label.new()
		value_label.name = "ValueLabel"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(value_label)
	else:
		value_label = $ValueLabel

	# Create status effect container
	if not has_node("StatusContainer"):
		status_container = Control.new()
		status_container.name = "StatusContainer"
		status_container.mouse_filter = MOUSE_FILTER_IGNORE
		status_container.size_flags_horizontal = SIZE_EXPAND_FILL
		status_container.size_flags_vertical = SIZE_EXPAND_FILL
		add_child(status_container)
	else:
		status_container = $StatusContainer

func _setup_gradient():
	# Create gradient for health bar visualization
	current_gradient = Gradient.new()

	if colorblind_friendly:
		# Colorblind-friendly: Use high contrast colors with clear distinctions
		# Blue (low), Orange (medium), Green (high) - better for colorblind users
		var low_color = _get_theme_color("health_low_cb")  # Colorblind-friendly low health
		if low_color == Color(0, 0, 0, 0):
			low_color = Color(0.2, 0.4, 0.8, 1.0)  # Blue

		var medium_color = _get_theme_color("health_medium_cb")  # Colorblind-friendly medium health
		if medium_color == Color(0, 0, 0, 0):
			medium_color = Color(0.9, 0.6, 0.1, 1.0)  # Orange

		var high_color = _get_theme_color("health_high_cb")  # Colorblind-friendly high health
		if high_color == Color(0, 0, 0, 0):
			high_color = Color(0.2, 0.8, 0.2, 1.0)  # Green

		# Set up color stops for health percentage ranges
		current_gradient.add_point(0.0, low_color)     # Blue (0-25%)
		current_gradient.add_point(0.25, low_color)    # Blue (0-25%)
		current_gradient.add_point(0.25, medium_color) # Orange (25-50%)
		current_gradient.add_point(0.5, medium_color)  # Orange (25-50%)
		current_gradient.add_point(0.5, high_color)    # Green (50-100%)
		current_gradient.add_point(1.0, high_color)    # Green (50-100%)
	else:
		# Standard colors: Red (low), Yellow (medium), Green (high)
		var red_color = _get_theme_color("health_low")  # 0-25%
		if red_color == Color(0, 0, 0, 0):
			red_color = Color(0.8, 0.2, 0.2, 1.0)

		var yellow_color = _get_theme_color("health_medium")  # 25-50%
		if yellow_color == Color(0, 0, 0, 0):
			yellow_color = Color(0.9, 0.6, 0.1, 1.0)

		var green_color = _get_theme_color("health_high")  # 50-100%
		if green_color == Color(0, 0, 0, 0):
			green_color = Color(0.2, 0.8, 0.2, 1.0)

		# Set up color stops for health percentage ranges
		current_gradient.add_point(0.0, red_color)     # Red (0-25%)
		current_gradient.add_point(0.25, red_color)    # Red (0-25%)
		current_gradient.add_point(0.25, yellow_color) # Yellow (25-50%)
		current_gradient.add_point(0.5, yellow_color)  # Yellow (25-50%)
		current_gradient.add_point(0.5, green_color)   # Green (50-100%)
		current_gradient.add_point(1.0, green_color)   # Green (50-100%)

func _update_visual_state():
	# Update gradient texture
	if enable_gradient_fill and gradient_texture and current_gradient:
		var gradient_image = Image.create(256, 1, false, Image.FORMAT_RGBA8)
		for x in range(256):
			var t = float(x) / 255.0
			gradient_image.set_pixel(x, 0, current_gradient.sample(t))

		var gradient_tex = ImageTexture.create_from_image(gradient_image)
		gradient_texture.texture = gradient_tex

		# Position and size gradient texture to match progress bar fill
		gradient_texture.position = Vector2(0, 0)
		gradient_texture.size = size

	# Update value label
	_update_value_label()

	# Update status effects
	_update_status_effects()

func _apply_theme():
	# Apply theme to child components
	var active_theme = self.theme
	if active_theme:
		if value_label:
			value_label.theme = active_theme
		if gradient_texture:
			gradient_texture.theme = active_theme

		# Apply UIProgressBar-specific theme properties
		_apply_progress_bar_theme(active_theme)

func _apply_progress_bar_theme(theme: Theme):
	# Apply theme constants for progress bar styling
	# Since ui_theme.tres has issues, we define theme programmatically

	# Define theme colors for health states
	if not theme.has_color("health_high", "UIProgressBar"):
		theme.set_color("health_high", "UIProgressBar", Color(0.2, 0.8, 0.2, 1.0))  # Green

	if not theme.has_color("health_medium", "UIProgressBar"):
		theme.set_color("health_medium", "UIProgressBar", Color(0.9, 0.6, 0.1, 1.0))  # Yellow

	if not theme.has_color("health_low", "UIProgressBar"):
		theme.set_color("health_low", "UIProgressBar", Color(0.8, 0.2, 0.2, 1.0))  # Red

	# Colorblind-friendly colors
	if not theme.has_color("health_high_cb", "UIProgressBar"):
		theme.set_color("health_high_cb", "UIProgressBar", Color(0.2, 0.8, 0.2, 1.0))  # Green

	if not theme.has_color("health_medium_cb", "UIProgressBar"):
		theme.set_color("health_medium_cb", "UIProgressBar", Color(0.9, 0.6, 0.1, 1.0))  # Orange

	if not theme.has_color("health_low_cb", "UIProgressBar"):
		theme.set_color("health_low_cb", "UIProgressBar", Color(0.2, 0.4, 0.8, 1.0))  # Blue

	# Font color for high contrast
	if not theme.has_color("font_color", "UIProgressBar"):
		theme.set_color("font_color", "UIProgressBar", Color.WHITE)

	# Define font sizes
	if not theme.has_font_size("font_size", "UIProgressBar"):
		theme.set_font_size("font_size", "UIProgressBar", 14)

	# Define styleboxes for different states (if needed)
	_create_theme_styleboxes(theme)

func _create_theme_styleboxes(theme: Theme):
	# Create styleboxes for progress bar backgrounds, borders, etc.
	pass  # For now, using basic styling

func validate_theme_consistency() -> bool:
	# Validate that current theme application is consistent
	var active_theme = self.theme
	if not active_theme:
		return false

	# Check that all required theme colors exist
	var required_colors = ["health_high", "health_medium", "health_low", "font_color"]
	for color_name in required_colors:
		if not active_theme.has_color(color_name, "UIProgressBar"):
			return false

	return true

func apply_theme_override(theme: Theme) -> void:
	# Apply a theme override for special cases (e.g., boss fights, special events)
	self.theme = theme
	_apply_theme()
	_setup_gradient()  # Recreate gradient with new theme colors
	_update_visual_state()
	queue_redraw()

func reload_theme() -> void:
	# Reload theme and apply changes immediately
	_apply_theme()
	_setup_gradient()
	_update_visual_state()
	queue_redraw()

func _get_theme_color(color_name: String) -> Color:
	# Get color from theme with fallback
	if theme:
		return theme.get_color(color_name, "UIProgressBar")
	return Color(0, 0, 0, 0)  # Invalid color to indicate no theme color

func _get_responsive_font_size() -> int:
	# Calculate responsive font size based on screen resolution
	if not responsive_scaling:
		return 14  # Default font size

	var viewport_size = get_viewport_rect().size
	var scale_factor = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)  # Base resolution

	# Font size ranges from 10 (small screens) to 18 (large screens)
	var base_size = 14
	var scaled_size = int(base_size * scale_factor)
	return clamp(scaled_size, 10, 18)

func _get_responsive_bar_size() -> Vector2:
	# Calculate responsive bar dimensions
	if not responsive_scaling:
		return Vector2(200, 24)  # Default size

	var viewport_size = get_viewport_rect().size
	var scale_factor = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)

	# Base dimensions scaled responsively
	var base_width = 200
	var base_height = 24
	var scaled_width = base_width * scale_factor
	var scaled_height = base_height * scale_factor

	return Vector2(scaled_width, scaled_height)

func _connect_to_gamemanager() -> void:
	# Connect to GameManager status effect signals
	if gamemanager_connected:
		return

	if Engine.has_singleton("GameManager"):
		var gamemanager = Engine.get_singleton("GameManager")
		if gamemanager:
			# Connect to player status effect signals
			gamemanager.connect("player_status_effect_added", Callable(self, "_on_player_status_effect_added"))
			gamemanager.connect("player_status_effect_removed", Callable(self, "_on_player_status_effect_removed"))

			# Connect to monster status effect signals (for monster health bars)
			gamemanager.connect("monster_status_effect_added", Callable(self, "_on_monster_status_effect_added"))
			gamemanager.connect("monster_status_effect_removed", Callable(self, "_on_monster_status_effect_removed"))

			gamemanager_connected = true

func _on_player_status_effect_added(effect_type: String, duration: int) -> void:
	# Handle player status effect added (only if this is a player health bar)
	if name.to_lower().contains("player") or name.to_lower().contains("hero"):
		add_status_effect_overlay(effect_type)

func set_value_animated(new_value: float, animate: bool = true) -> void:
	# Set value with optional animation (AC-2.1.3)
	var old_value = value
	target_value = clamp(new_value, min_value, max_value)

	# Check for reduced motion accessibility setting
	var reduced_motion = _is_reduced_motion_enabled()
	var should_animate = animate and animate_value_changes and not (respect_reduced_motion and reduced_motion)

	if should_animate:
		_animate_value_change(target_value)
	else:
		value = target_value
		_update_visual_state()

	value_changed_animated.emit(target_value, old_value)

func _animate_value_change(target_val: float):
	# Kill any existing tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Start performance monitoring
	_start_performance_monitoring()

	# Create new tween for value animation
	active_tween = create_tween()
	active_tween.set_ease(ANIMATION_EASE)
	active_tween.set_trans(ANIMATION_TRANS)

	# Animate value
	active_tween.tween_property(self, "value", target_val, ANIMATION_DURATION)

	# Update visuals during animation
	active_tween.tween_callback(_update_visual_state)

	# Clean up tween when finished
	active_tween.finished.connect(func():
		_end_performance_monitoring()
		active_tween = null
		_update_visual_state()
	)

func _start_performance_monitoring():
	# Start monitoring frame rate during animation
	animation_start_time = Time.get_ticks_msec() / 1000.0
	frame_count_during_animation = 0
	min_fps_during_animation = 60.0

func _end_performance_monitoring():
	# End performance monitoring and log results
	var end_time = Time.get_ticks_msec() / 1000.0
	var duration = end_time - animation_start_time
	var avg_fps = frame_count_during_animation / duration if duration > 0 else 60.0

	# Log performance data for debugging
	print("UIProgressBar animation completed: Duration=%.3fs, Min FPS=%.1f, Avg FPS=%.1f" % [
		duration, min_fps_during_animation, avg_fps
	])

	# Assert performance requirements (AC-2.1.3)
	assert(duration <= ANIMATION_DURATION + 0.1, "Animation should complete within %fs" % ANIMATION_DURATION)
	assert(min_fps_during_animation >= 50.0, "Animation should maintain at least 50fps")

func _process(delta):
	# Monitor frame rate during animations
	if active_tween and active_tween.is_valid():
		frame_count_during_animation += 1
		var current_fps = 1.0 / delta
		min_fps_during_animation = min(min_fps_during_animation, current_fps)

func _update_status_effects():
	# Update positioning of status effect overlays
	if status_container:
		var container_size = status_container.size
		var effect_count = status_effects.size()
		var effect_spacing = 24 + 4  # 24px icon + 4px spacing

		var start_x = container_size.x - (effect_count * effect_spacing)
		var y_pos = (container_size.y - 24) / 2  # Center vertically

		var index = 0
		for effect_icon in status_effects.values():
			if effect_icon:
				effect_icon.position = Vector2(start_x + (index * effect_spacing), y_pos)
				index += 1

func add_status_effect_overlay(effect_type: String) -> void:
	# Add status effect overlay (AC-2.1.2)
	if not enable_status_effects or not status_container:
		return

	if status_effects.has(effect_type):
		return  # Already exists

	# Create status effect icon
	var effect_icon = StatusEffectIcon.new()
	effect_icon.effect_type = effect_type
	status_container.add_child(effect_icon)

	status_effects[effect_type] = effect_icon
	status_effect_added.emit(effect_type)

	_update_status_effects()
	_apply_status_effect_styling(effect_type)

func remove_status_effect_overlay(effect_type: String) -> void:
	# Remove status effect overlay
	if status_effects.has(effect_type):
		var effect_icon = status_effects[effect_type]
		if effect_icon:
			status_container.remove_child(effect_icon)
			effect_icon.queue_free()

		status_effects.erase(effect_type)
		status_effect_removed.emit(effect_type)

		_update_status_effects()
		_remove_status_effect_styling(effect_type)

func _update_value_label():
	if value_label and show_value_text:
		var current_val = int(value)
		var max_val = int(max_value)
		var percentage = (value / max_value) * 100

		var status_text = ""
		if colorblind_friendly:
			# Add text indicators for colorblind accessibility
			if percentage >= 50:
				status_text = " (Good)"
			elif percentage >= 25:
				status_text = " (Caution)"
			else:
				status_text = " (Critical)"

		value_label.text = "%d/%d%s" % [current_val, max_val, status_text]
		value_label.visible = true

		# Apply theme-based font color with high contrast fallback
		var font_color = _get_theme_color("font_color")
		if font_color == Color(0, 0, 0, 0):  # No theme color set
			font_color = Color.WHITE  # High contrast fallback
		value_label.add_theme_color_override("font_color", font_color)

		# Apply responsive font sizing
		var font_size = _get_responsive_font_size()
		value_label.add_theme_font_size_override("font_size", font_size)
	else:
		if value_label:
			value_label.visible = false

func _apply_status_effect_styling(effect_type: String):
	# Apply visual styling based on status effect (AC-2.1.2)
	match effect_type:
		"poison":
			# Green tint with subtle glow for poison
			_start_glow_effect(Color(0.4, 0.8, 0.4, 0.3), 2.0)
			modulate = Color(0.9, 1.0, 0.9, 1.0)
		"buff":
			# Gold glow effect for buff
			_start_glow_effect(Color(1.0, 0.9, 0.4, 0.4), 1.5)
			modulate = Color(1.0, 1.0, 0.9, 1.0)
		"debuff":
			# Red tint with glow for debuff
			_start_glow_effect(Color(0.8, 0.3, 0.3, 0.3), 2.0)
			modulate = Color(1.0, 0.9, 0.9, 1.0)
		"burn":
			# Orange glow for burn
			_start_glow_effect(Color(1.0, 0.6, 0.2, 0.4), 1.8)
			modulate = Color(1.0, 0.95, 0.8, 1.0)
		"freeze":
			# Blue tint for freeze
			_start_glow_effect(Color(0.4, 0.8, 1.0, 0.3), 2.5)
			modulate = Color(0.9, 0.95, 1.0, 1.0)

func _remove_status_effect_styling(effect_type: String):
	# Remove visual styling when effect is removed
	_stop_glow_effect()
	modulate = original_modulate

func _start_glow_effect(glow_color: Color, intensity: float):
	# Create a subtle glow effect using modulate animation
	if _is_reduced_motion_enabled() and respect_reduced_motion:
		# Skip animation for reduced motion
		modulate = original_modulate + glow_color * intensity * 0.5  # Static glow
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_loops()  # Loop indefinitely
	active_tween.set_ease(Tween.EASE_IN_OUT)
	active_tween.set_trans(Tween.TRANS_SINE)

	# Create pulsing glow effect
	var base_modulate = modulate
	var glow_modulate = base_modulate + glow_color * intensity

	active_tween.tween_property(self, "modulate", glow_modulate, 0.8)
	active_tween.tween_property(self, "modulate", base_modulate, 0.8)

func _stop_glow_effect():
	# Stop glow effect and return to normal modulate
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

	modulate = original_modulate

func _is_reduced_motion_enabled() -> bool:
	# Check for reduced motion accessibility setting
	# This could be a project setting or OS-level preference
	# For now, check a project setting
	return ProjectSettings.get_setting("accessibility/reduced_motion", false)

func _on_player_status_effect_removed(effect_type: String) -> void:
	# Handle player status effect removed
	if name.to_lower().contains("player") or name.to_lower().contains("hero"):
		remove_status_effect_overlay(effect_type)

func _on_monster_status_effect_added(effect_type: String, duration: int) -> void:
	# Handle monster status effect added (only if this is a monster health bar)
	if name.to_lower().contains("monster") or name.to_lower().contains("enemy"):
		add_status_effect_overlay(effect_type)

func _on_monster_status_effect_removed(effect_type: String) -> void:
	# Handle monster status effect removed
	if name.to_lower().contains("monster") or name.to_lower().contains("enemy"):
		remove_status_effect_overlay(effect_type)

func _get_minimum_size() -> Vector2:
	# Ensure minimum touch target size (44px minimum for accessibility)
	var min_size = Vector2(44, 44)

	# Account for value label if visible
	if value_label and show_value_text:
		var label_size = value_label.get_minimum_size()
		min_size.x = max(min_size.x, label_size.x + 20)
		min_size.y = max(min_size.y, label_size.y + 10)

	# Apply responsive scaling minimums
	if responsive_scaling:
		var responsive_size = _get_responsive_bar_size()
		min_size.x = max(min_size.x, responsive_size.x)
		min_size.y = max(min_size.y, responsive_size.y)

	return min_size
