class_name UIButton
extends Button

# UIButton - Modern button component with hover effects, animations, and accessibility
# Uses Button's built-in stylebox rendering so icons display correctly above the background.

# Signals
signal state_changed(new_state: ButtonState, old_state: ButtonState)  # State transition
# Note: pressed, button_down, button_up signals inherited from Button class

# State enum for button states
enum ButtonState {
	NORMAL,
	HOVER,
	PRESSED,
	DISABLED
}

# Preload UIAnimationSystem for hover animations
const UIAnimationSystemClass = preload("res://scripts/components/UIAnimationSystem.gd")

var animation_system = UIAnimationSystemClass.new()

# Internal state
var current_state: ButtonState = ButtonState.NORMAL
var is_pressed: bool = false
var has_focus: bool = false
var is_hovered: bool = false

# Animation state
var active_tween: Tween = null
var original_scale: Vector2 = Vector2.ONE
var original_modulate: Color = Color.WHITE

# Store button text so external code can read it via button_text
var button_text: String = "":
	set(value):
		button_text = value
		self.text = value
	get:
		return button_text

func _ready():
	# Store the Button's text from the scene
	button_text = self.text

	# IMPORTANT: Set a reasonable minimum size to ensure button is clickable
	var text_size = Vector2.ZERO
	if not button_text.is_empty():
		var font = get_theme_font("font")
		var font_size = get_theme_font_size("font_size")
		if font and font_size > 0:
			text_size = font.get_string_size(
				button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
			)
		else:
			text_size = Vector2(button_text.length() * 10, 20)

	var min_size = Vector2(
		max(100, text_size.x + 40),
		max(44, text_size.y + 20)
	)
	custom_minimum_size = min_size

	# Connect to Button's built-in signals
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	connect("focus_exited", Callable(self, "_on_focus_exited"))
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))

	set_focus_mode(FOCUS_ALL)

	original_scale = scale
	original_modulate = modulate

	# Apply initial stylebox overrides for all states
	_apply_all_styleboxes()

	# Set font color
	var font_color = UIThemeManager.get_text_primary_color()
	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_hover_color", font_color)
	add_theme_color_override("font_pressed_color", font_color)
	add_theme_color_override("font_focus_color", font_color)
	add_theme_color_override(
		"font_disabled_color", UIThemeManager.get_color("disabled_text")
	)

func _exit_tree():
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

func _create_stylebox(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = border_color
	stylebox.corner_radius_top_left = 2
	stylebox.corner_radius_top_right = 2
	stylebox.corner_radius_bottom_right = 2
	stylebox.corner_radius_bottom_left = 2
	stylebox.content_margin_left = 4.0
	stylebox.content_margin_right = 4.0
	stylebox.content_margin_top = 4.0
	stylebox.content_margin_bottom = 4.0
	return stylebox

func _apply_all_styleboxes():
	# Apply styleboxes to Button's built-in theme overrides.
	# Button draws: stylebox -> icon -> text, so icon is always visible.
	var normal_border = UIThemeManager.get_border_bronze_color()
	normal_border.a = 0.4
	var hover_border = UIThemeManager.get_accent_color()
	hover_border.a = 0.7
	var pressed_border = UIThemeManager.get_accent_color()
	pressed_border.a = 0.9
	var disabled_border = UIThemeManager.get_secondary_color()
	disabled_border.a = 0.3

	add_theme_stylebox_override(
		"normal", _create_stylebox(Color(0.12, 0.10, 0.08, 0.85), normal_border)
	)
	add_theme_stylebox_override(
		"hover", _create_stylebox(Color(0.16, 0.13, 0.10, 0.9), hover_border)
	)
	add_theme_stylebox_override(
		"pressed", _create_stylebox(Color(0.08, 0.07, 0.05, 1.0), pressed_border)
	)
	add_theme_stylebox_override(
		"disabled", _create_stylebox(Color(0.10, 0.09, 0.07, 0.5), disabled_border)
	)
	# Focus uses accent border with transparent bg
	var focus_box = _create_stylebox(Color.TRANSPARENT, UIThemeManager.get_accent_color())
	add_theme_stylebox_override("focus", focus_box)

func _on_mouse_entered():
	if not self.disabled:
		is_hovered = true

func _on_mouse_exited():
	if not self.disabled:
		is_hovered = false
		play_unhover_animation()

func _on_focus_entered():
	has_focus = true

func _on_focus_exited():
	has_focus = false

func _on_button_down():
	if not self.disabled:
		is_pressed = true

func _on_button_up():
	if not self.disabled:
		is_pressed = false

# Public methods

func apply_theme(new_theme: Theme) -> void:
	self.theme = new_theme
	_apply_all_styleboxes()
	queue_redraw()

func apply_global_theme(_new_theme: Theme) -> void:
	if not self.theme:
		_apply_all_styleboxes()
		queue_redraw()

func get_theme_variation(variation_name: String) -> Theme:
	# Return theme variation for special cases (e.g., "primary", "destructive")
	# This now uses colors from UIThemeManager
	var variation_theme = Theme.new()

	match variation_name:
		"primary":
			# Primary button styling (using success color)
			var primary_bg = StyleBoxFlat.new()
			primary_bg.bg_color = UIThemeManager.get_success_color()
			variation_theme.set_stylebox("normal", "UIButton", primary_bg)

			var primary_hover = StyleBoxFlat.new()
			primary_hover.bg_color = UIThemeManager.get_success_color().lightened(0.1)
			variation_theme.set_stylebox("hover", "UIButton", primary_hover)

		"destructive":
			# Destructive action styling (using danger color)
			var destructive_bg = StyleBoxFlat.new()
			destructive_bg.bg_color = UIThemeManager.get_danger_color()
			variation_theme.set_stylebox("normal", "UIButton", destructive_bg)

			var destructive_hover = StyleBoxFlat.new()
			destructive_hover.bg_color = UIThemeManager.get_danger_color().lightened(0.1)
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
	# Play hover animation using UIAnimationSystem (100ms, scale 1.05x, color highlight)
	animation_system.play_button_hover_animation(self)

	# Additional color highlight animation if accent color is available
	if theme and theme.has_color("accent_color", "UIButton"):
		var accent = theme.get_color("accent_color", "UIButton")
		animation_system.animate_property(self, "modulate", modulate, accent * 1.2, 0.1)

func play_unhover_animation() -> void:
	# Play unhover animation using UIAnimationSystem (100ms, return to normal)
	animation_system.play_button_unhover_animation(self)

	# Return to normal color
	animation_system.animate_property(self, "modulate", modulate, Color.WHITE, 0.1)

func play_press_animation() -> void:
	# Play press animation (scale down slightly)
	_animate_scale(Vector2(1.05, 1.05), Vector2(0.95, 0.95), 0.1)

func _animate_state_transition(old_state: ButtonState, new_state: ButtonState):
	# Handle specific state transition animations using UIAnimationSystem
	match [old_state, new_state]:
		[ButtonState.NORMAL, ButtonState.HOVER]:
			play_hover_animation()
		[ButtonState.HOVER, ButtonState.NORMAL]:
			animation_system.animate_property(self, "scale", scale, Vector2.ONE, 0.1)
		[ButtonState.HOVER, ButtonState.PRESSED]:
			play_press_animation()
		[ButtonState.PRESSED, ButtonState.HOVER]:
			animation_system.animate_property(self, "scale", scale, Vector2(1.05, 1.05), 0.1)
		[ButtonState.PRESSED, ButtonState.NORMAL]:
			animation_system.animate_property(self, "scale", scale, Vector2.ONE, 0.1)

func _animate_scale(_from_scale: Vector2, to_scale: Vector2, duration: float):
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

func _animate_color(_from_color: Color, to_color: Color, duration: float):
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

	if not button_text.is_empty():
		var font = get_theme_font("font")
		var font_size = get_theme_font_size("font_size")
		if font and font_size > 0:
			var text_size = font.get_string_size(
				button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
			)
			min_size.x = max(min_size.x, text_size.x + 20)
			min_size.y = max(min_size.y, text_size.y + 10)

	return min_size