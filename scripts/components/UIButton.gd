extends Button
class_name UIButton

# UIButton - Modern button component with hover effects, animations, and accessibility
# Extends Control for full customization while maintaining button-like behavior

# State enum for button states
enum ButtonState {
	NORMAL,
	HOVER,
	PRESSED,
	DISABLED
}

# Signals
signal state_changed(new_state: ButtonState, old_state: ButtonState)  # State transition
# Note: pressed, button_down, button_up signals inherited from Button class

# Use Button's built-in properties: text, disabled, theme_override

# Internal state
var current_state: ButtonState = ButtonState.NORMAL
var is_pressed: bool = false
var has_focus: bool = false
var is_hovered: bool = false

# Animation state
var active_tween: Tween = null
var original_scale: Vector2 = Vector2.ONE
var original_modulate: Color = Color.WHITE

# UI components
var label: Label = null
var background: Panel = null
var focus_indicator: Panel = null

func _ready():
	# Create child nodes if they don't exist
	_create_child_nodes()

	# Connect to Button's built-in signals
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	connect("focus_exited", Callable(self, "_on_focus_exited"))
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))

	# Set up input handling
	set_focus_mode(FOCUS_ALL)

	# Store original transform values for animations
	original_scale = scale
	original_modulate = modulate

	# Initialize - use Button's built-in text property
	_update_label()
	_apply_theme()
	_update_state()

func _exit_tree():
	# Clean up active tween when node is removed
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

func _create_child_nodes():
	# Create background panel
	if not has_node("Background"):
		background = Panel.new()
		background.name = "Background"
		background.mouse_filter = MOUSE_FILTER_IGNORE  # Don't block mouse input
		add_child(background)
	else:
		background = $Background as Panel
		background.mouse_filter = MOUSE_FILTER_IGNORE

	# Create label
	if not has_node("Label"):
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = MOUSE_FILTER_IGNORE  # Don't block mouse input
		add_child(label)
	else:
		label = $Label as Label
		label.mouse_filter = MOUSE_FILTER_IGNORE

	# Create focus indicator (accessibility)
	if not has_node("FocusIndicator"):
		focus_indicator = Panel.new()
		focus_indicator.name = "FocusIndicator"
		focus_indicator.visible = false
		focus_indicator.mouse_filter = MOUSE_FILTER_IGNORE  # Don't block mouse input
		add_child(focus_indicator)
	else:
		focus_indicator = $FocusIndicator as Panel
		focus_indicator.mouse_filter = MOUSE_FILTER_IGNORE

func _update_label():
	if label:
		label.text = self.text  # Use Button's text property
		label.visible = not self.text.is_empty()

func _apply_theme():
	# Apply theme to child components
	var active_theme = self.theme  # Button uses 'theme' property
	if active_theme:
		if label:
			label.theme = active_theme
		if background:
			background.theme = active_theme

func _update_state():
	# Determine new state based on current conditions
	var new_state = ButtonState.NORMAL

	if self.disabled:  # Use Button's disabled property
		new_state = ButtonState.DISABLED
	elif is_pressed:
		new_state = ButtonState.PRESSED
	elif is_hovered or has_focus:
		new_state = ButtonState.HOVER

	# Emit state change signal if state actually changed
	if new_state != current_state:
		var old_state = current_state
		current_state = new_state
		state_changed.emit(new_state, old_state)

		# Animate state transition
		_animate_state_transition(old_state, new_state)

	# Update visual appearance (without animation for instant updates)
	_update_visual_state()

func _update_visual_state():
	# Update visual appearance based on current state using theme overrides
	var active_theme = self.theme  # Button uses 'theme' property

	if not active_theme:
		# Fallback to basic modulation if no theme
		_apply_fallback_styling()
		return

	# Apply theme-based styling
	_apply_theme_styling(active_theme)

func _apply_fallback_styling():
	# Basic fallback styling when no theme is available
	match current_state:
		ButtonState.NORMAL:
			modulate = Color(1, 1, 1, 1)
			if background:
				background.modulate = Color(0.8, 0.8, 0.8, 1)
		ButtonState.HOVER:
			modulate = Color(1.05, 1.05, 1.05, 1)
			if background:
				background.modulate = Color(0.9, 0.9, 0.9, 1)
		ButtonState.PRESSED:
			modulate = Color(0.95, 0.95, 0.95, 1)
			if background:
				background.modulate = Color(0.7, 0.7, 0.7, 1)
		ButtonState.DISABLED:
			modulate = Color(0.6, 0.6, 0.6, 0.5)
			if background:
				background.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _apply_theme_styling(theme: Theme):
	# Apply comprehensive theme-based styling for each state

	# Background styling
	if background:
		var bg_stylebox = _get_state_stylebox(theme, "UIButton", "background")
		if bg_stylebox:
			background.add_theme_stylebox_override("panel", bg_stylebox)

	# Label styling
	if label:
		var font_color = _get_state_color(theme, "UIButton", "font_color")
		if font_color:
			label.add_theme_color_override("font_color", font_color)

		var shadow_color = _get_state_color(theme, "UIButton", "font_shadow_color")
		if shadow_color:
			label.add_theme_color_override("font_shadow_color", shadow_color)

	# Self styling (for borders, shadows, etc.)
	var self_stylebox = _get_state_stylebox(theme, "UIButton", "normal")
	if self_stylebox:
		add_theme_stylebox_override("panel", self_stylebox)

	# State-specific effects
	match current_state:
		ButtonState.NORMAL:
			modulate = Color(1, 1, 1, 1)
		ButtonState.HOVER:
			# Subtle highlight effect
			modulate = Color(1.1, 1.1, 1.1, 1)
			var hover_stylebox = _get_state_stylebox(theme, "UIButton", "hover")
			if hover_stylebox and background:
				background.add_theme_stylebox_override("panel", hover_stylebox)
		ButtonState.PRESSED:
			# Pressed down effect
			modulate = Color(0.95, 0.95, 0.95, 1)
			var pressed_stylebox = _get_state_stylebox(theme, "UIButton", "pressed")
			if pressed_stylebox and background:
				background.add_theme_stylebox_override("panel", pressed_stylebox)
		ButtonState.DISABLED:
			# Disabled appearance
			modulate = Color(0.6, 0.6, 0.6, 0.7)
			var disabled_stylebox = _get_state_stylebox(theme, "UIButton", "disabled")
			if disabled_stylebox and background:
				background.add_theme_stylebox_override("panel", disabled_stylebox)

			# Disabled text color
			if label:
				var disabled_color = _get_state_color(theme, "UIButton", "font_disabled_color")
				if disabled_color:
					label.add_theme_color_override("font_color", disabled_color)

func _get_state_stylebox(theme: Theme, type_name: String, stylebox_name: String) -> StyleBox:
	# Get stylebox for specific state, fallback to normal if not found
	return theme.get_stylebox(stylebox_name, type_name)

func _get_state_color(theme: Theme, type_name: String, color_name: String) -> Color:
	# Get color for specific state
	return theme.get_color(color_name, type_name)

func _on_mouse_entered():
	if not self.disabled:  # Use Button's disabled property
		is_hovered = true
		_update_state()

func _on_mouse_exited():
	if not self.disabled:  # Use Button's disabled property
		is_hovered = false
		_update_state()

func _on_focus_entered():
	has_focus = true
	_update_focus_indicator()
	_update_state()

func _on_focus_exited():
	has_focus = false
	_update_focus_indicator()
	_update_state()

func _on_button_down():
	if not self.disabled:
		is_pressed = true
		_update_state()

func _on_button_up():
	if not self.disabled:
		is_pressed = false
		_update_state()

func _update_focus_indicator():
	# Show/hide focus indicator based on focus state and accessibility needs
	if focus_indicator:
		focus_indicator.visible = has_focus and not self.disabled  # Use Button's disabled property

		# Apply focus styling with 3:1 contrast ratio (WCAG AA)
		if has_focus:
			var focus_stylebox = _create_focus_stylebox()
			focus_indicator.add_theme_stylebox_override("panel", focus_stylebox)

func _create_focus_stylebox() -> StyleBoxFlat:
	# Create focus indicator with high contrast (3:1 ratio)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 0)  # Transparent background
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.4, 0.95, 0.84, 1)  # High contrast cyan
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.corner_radius_bottom_left = 6
	return stylebox

# Public methods - Note: Don't override Button's set_text/set_disabled methods

func apply_theme(theme: Theme) -> void:
	self.theme = theme  # Button uses 'theme' property
	_apply_theme()
	_update_visual_state()
	queue_redraw()
	# Note: Button doesn't have theme_changed signal, removed emit

func apply_global_theme(theme: Theme) -> void:
	# Apply global theme without overriding local theme
	if not self.theme:  # Button uses 'theme' property
		_apply_theme_styling(theme)
		_update_visual_state()
		queue_redraw()

func get_theme_variation(variation_name: String) -> Theme:
	# Return theme variation for special cases (e.g., "primary", "destructive")
	# This can be extended by UIThemeManager
	var variation_theme = Theme.new()

	match variation_name:
		"primary":
			# Primary button styling
			var primary_bg = StyleBoxFlat.new()
			primary_bg.bg_color = Color(0.4, 0.95, 0.84, 0.8)  # Accent color
			variation_theme.set_stylebox("normal", "UIButton", primary_bg)

			var primary_hover = StyleBoxFlat.new()
			primary_hover.bg_color = Color(0.5, 0.98, 0.9, 0.9)
			variation_theme.set_stylebox("hover", "UIButton", primary_hover)

		"destructive":
			# Destructive action styling
			var destructive_bg = StyleBoxFlat.new()
			destructive_bg.bg_color = Color(0.8, 0.3, 0.3, 0.8)  # Red
			variation_theme.set_stylebox("normal", "UIButton", destructive_bg)

			var destructive_hover = StyleBoxFlat.new()
			destructive_hover.bg_color = Color(0.9, 0.4, 0.4, 0.9)
			variation_theme.set_stylebox("hover", "UIButton", destructive_hover)

	return variation_theme

func validate_theme_consistency() -> bool:
	# Validate that current theme application is consistent
	# This can be called by UIThemeManager for validation
	var active_theme = self.theme  # Button uses 'theme' property
	if not active_theme:
		return false

	# Check that all required theme items exist
	var required_styles = ["normal", "hover", "pressed", "disabled"]
	for style_name in required_styles:
		if not active_theme.has_stylebox(style_name, "UIButton"):
			return false

	return true

func play_hover_animation() -> void:
	# Play hover animation (scale up slightly)
	_animate_scale(Vector2.ONE, Vector2(1.05, 1.05), 0.2)

func play_press_animation() -> void:
	# Play press animation (scale down slightly)
	_animate_scale(Vector2(1.05, 1.05), Vector2(0.95, 0.95), 0.1)

func _animate_state_transition(old_state: ButtonState, new_state: ButtonState):
	# Handle specific state transition animations
	match [old_state, new_state]:
		[ButtonState.NORMAL, ButtonState.HOVER]:
			play_hover_animation()
		[ButtonState.HOVER, ButtonState.NORMAL]:
			_animate_scale(Vector2(1.05, 1.05), Vector2.ONE, 0.2)
		[ButtonState.HOVER, ButtonState.PRESSED]:
			play_press_animation()
		[ButtonState.PRESSED, ButtonState.HOVER]:
			_animate_scale(Vector2(0.95, 0.95), Vector2(1.05, 1.05), 0.1)
		[ButtonState.PRESSED, ButtonState.NORMAL]:
			_animate_scale(Vector2(0.95, 0.95), Vector2.ONE, 0.1)

func _animate_scale(from_scale: Vector2, to_scale: Vector2, duration: float):
	# Kill any existing tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Create new tween for scale animation
	active_tween = create_tween()
	active_tween.set_ease(Tween.EASE_OUT)
	active_tween.set_trans(Tween.TRANS_QUAD)

	# Animate scale
	active_tween.tween_property(self, "scale", to_scale, duration)

	# Clean up tween when finished
	active_tween.finished.connect(func(): active_tween = null)

func _animate_color(from_color: Color, to_color: Color, duration: float):
	# Kill any existing tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Create new tween for color animation
	active_tween = create_tween()
	active_tween.set_ease(Tween.EASE_OUT)
	active_tween.set_trans(Tween.TRANS_QUAD)

	# Animate modulate color
	active_tween.tween_property(self, "modulate", to_color, duration)

	# Clean up tween when finished
	active_tween.finished.connect(func(): active_tween = null)

# Accessibility methods removed - Button provides basic accessibility through BaseButton

# Override Control methods for proper sizing
func _get_minimum_size() -> Vector2:
	var min_size = Vector2(44, 44)  # WCAG minimum touch target

	if label and not self.text.is_empty():  # Use Button's text property
		var label_size = label.get_minimum_size()
		min_size.x = max(min_size.x, label_size.x + 20)  # Add padding
		min_size.y = max(min_size.y, label_size.y + 10)

	return min_size