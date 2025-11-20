extends GutTest

# UIButton Component Tests
# Tests state management, signals, animations, accessibility, and theming

var button: UIButton = null
var test_theme: Theme = null

func before_each():
	button = UIButton.new()
	add_child_autofree(button)

	# Create test theme
	test_theme = Theme.new()
	_setup_test_theme()

func after_each():
	button = null
	test_theme = null

func _setup_test_theme():
	# Create basic styleboxes for testing
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.5, 0.5, 0.5, 1)
	test_theme.set_stylebox("normal", "UIButton", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.6, 0.6, 0.6, 1)
	test_theme.set_stylebox("hover", "UIButton", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.4, 0.4, 0.4, 1)
	test_theme.set_stylebox("pressed", "UIButton", pressed_style)

	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	test_theme.set_stylebox("disabled", "UIButton", disabled_style)

	# Set colors
	test_theme.set_color("font_color", "UIButton", Color(1, 1, 1, 1))
	test_theme.set_color("font_hover_color", "UIButton", Color(0.9, 0.9, 0.9, 1))
	test_theme.set_color("font_pressed_color", "UIButton", Color(0.8, 0.8, 0.8, 1))
	test_theme.set_color("font_disabled_color", "UIButton", Color(0.6, 0.6, 0.6, 0.6))

func test_button_initialization():
	# Test that button initializes correctly
	assert_not_null(button, "Button should be created")
	assert_eq(button.text, "", "Button should start with empty text")
	assert_false(button.disabled, "Button should not be disabled by default")
	assert_eq(button.current_state, UIButton.ButtonState.NORMAL, "Button should start in NORMAL state")

func test_button_text_setting():
	# Test text property
	button.text = "Test Button"
	assert_eq(button.text, "Test Button", "Text should be set correctly")

	# Test accessibility updates
	assert_eq(button.accessible_name, "Test Button", "Accessibility name should match text")

func test_button_state_transitions():
	# Test state transitions
	assert_eq(button.current_state, UIButton.ButtonState.NORMAL)

	# Simulate hover
	button.is_hovered = true
	button._update_state()
	assert_eq(button.current_state, UIButton.ButtonState.HOVER)

	# Simulate press
	button.is_pressed = true
	button._update_state()
	assert_eq(button.current_state, UIButton.ButtonState.PRESSED)

	# Simulate disabled
	button.disabled = true
	button._update_state()
	assert_eq(button.current_state, UIButton.ButtonState.DISABLED)

func test_button_signals():
	# Test signal emissions
	var pressed_emitted = false
	var state_changed_emitted = false

	button.pressed.connect(func(): pressed_emitted = true)
	button.state_changed.connect(func(_old, _new): state_changed_emitted = true)

	# Simulate button press
	button._gui_input(_create_mouse_button_event(true))
	button._gui_input(_create_mouse_button_event(false))

	assert_true(pressed_emitted, "Pressed signal should be emitted")
	assert_true(state_changed_emitted, "State changed signal should be emitted")

func test_button_mouse_events():
	# Test mouse enter/exit
	var mouse_entered_emitted = false
	var mouse_exited_emitted = false

	button.mouse_entered.connect(func(): mouse_entered_emitted = true)
	button.mouse_exited.connect(func(): mouse_exited_emitted = true)

	# Simulate mouse events
	button._on_mouse_entered()
	assert_true(mouse_entered_emitted, "Mouse entered signal should be emitted")
	assert_true(button.is_hovered, "Button should be hovered")

	button._on_mouse_exited()
	assert_true(mouse_exited_emitted, "Mouse exited signal should be emitted")
	assert_false(button.is_hovered, "Button should not be hovered")

func test_button_keyboard_navigation():
	# Test keyboard focus and navigation
	var focus_entered_emitted = false
	var focus_exited_emitted = false
	var pressed_emitted = false

	button.focus_entered.connect(func(): focus_entered_emitted = true)
	button.focus_exited.connect(func(): focus_exited_emitted = true)
	button.pressed.connect(func(): pressed_emitted = true)

	# Simulate focus enter
	button._on_focus_entered()
	assert_true(focus_entered_emitted, "Focus entered signal should be emitted")
	assert_true(button.has_focus, "Button should have focus")

	# Simulate space key press
	var space_event = InputEventKey.new()
	space_event.keycode = KEY_SPACE
	space_event.pressed = true
	button._gui_input(space_event)

	assert_true(pressed_emitted, "Button should be pressed with space key")

	# Simulate focus exit
	button._on_focus_exited()
	assert_true(focus_exited_emitted, "Focus exited signal should be emitted")
	assert_false(button.has_focus, "Button should not have focus")

func test_button_theme_application():
	# Test theme application
	button.apply_theme(test_theme)

	# Verify theme was applied
	assert_eq(button.theme_override, test_theme, "Theme override should be set")

	# Test theme validation
	assert_true(button.validate_theme_consistency(), "Theme should be valid")

func test_button_theme_variations():
	# Test theme variations
	var primary_theme = button.get_theme_variation("primary")
	assert_not_null(primary_theme, "Primary theme variation should be created")

	var destructive_theme = button.get_theme_variation("destructive")
	assert_not_null(destructive_theme, "Destructive theme variation should be created")

func test_button_accessibility():
	# Test accessibility features
	button.text = "Accessible Button"
	assert_eq(button.accessible_name, "Accessible Button", "Accessible name should match text")
	# Note: UIButton extends Button which provides accessibility features

	# Test minimum size (WCAG touch targets)
	var min_size = button._get_minimum_size()
	assert_true(min_size.x >= 44, "Minimum width should meet WCAG touch target requirements")
	assert_true(min_size.y >= 44, "Minimum height should meet WCAG touch target requirements")

func test_button_disabled_state():
	# Test disabled state
	button.disabled = true
	assert_true(button.disabled, "Button should be disabled")

	# Test that interactions are blocked when disabled
	var pressed_emitted = false
	button.pressed.connect(func(): pressed_emitted = true)

	button._gui_input(_create_mouse_button_event(true))
	button._gui_input(_create_mouse_button_event(false))

	assert_false(pressed_emitted, "Disabled button should not emit pressed signal")

func test_button_animation_system():
	# Test animation methods exist and don't crash
	button.play_hover_animation()
	button.play_press_animation()

	# Test that tweens are created properly
	assert_not_null(button.active_tween, "Tween should be created for animations")

	# Wait for animation to complete
	await get_tree().create_timer(0.3).timeout

func test_button_minimum_size():
	# Test minimum size calculations
	var size = button._get_minimum_size()
	assert_true(size.x > 0, "Minimum width should be positive")
	assert_true(size.y > 0, "Minimum height should be positive")

	# Test with text
	button.text = "Long Button Text"
	var size_with_text = button._get_minimum_size()
	assert_true(size_with_text.x > size.x, "Size with text should be larger")

func _create_mouse_button_event(pressed: bool) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = button.global_position + button.size / 2
	return event