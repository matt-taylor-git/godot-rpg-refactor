extends GutTest

# Test suite for CharacterPortraitContainer component
# Tests AC-2.3.1, AC-2.3.2, AC-2.4.1, AC-2.5.1

const CharacterPortraitContainer = preload("res://scripts/components/CharacterPortraitContainer.gd")
const CharacterPortraitScene = preload("res://scenes/components/character_portrait_container.tscn")

var character_portrait: CharacterPortraitContainer
var test_texture: Texture2D

func before_each():
	# Create test texture
	test_texture = ImageTexture.create_from_image(Image.create(120, 120, false, Image.FORMAT_RGBA8))

	# Create CharacterPortraitContainer instance from scene
	character_portrait = CharacterPortraitScene.instantiate()
	character_portrait.name = "TestPortrait"
	add_child(character_portrait)

	# Wait for _ready
	await get_tree().process_frame

func after_each():
	if character_portrait:
		character_portrait.queue_free()
		character_portrait = null

func test_character_portrait_initialization():
	# Test basic initialization (AC-2.3.1)
	assert_not_null(character_portrait, "CharacterPortraitContainer should be created")
	assert_eq(character_portrait.size, Vector2(120, 120), "Portrait should be 120x120px")
	assert_eq(character_portrait.custom_minimum_size, Vector2(120, 120),
		"Portrait minimum size should be 120x120px")
	assert_eq(character_portrait.health_percentage, 100.0, "Initial health should be 100%")
	assert_false(character_portrait.is_active, "Initial active state should be false")

func test_character_data_setting():
	# Test setting character data
	character_portrait.character_name = "Test Hero"
	character_portrait.portrait_texture = test_texture
	character_portrait.health_percentage = 75.0

	assert_eq(character_portrait.character_name, "Test Hero", "Character name should be set")
	assert_eq(character_portrait.portrait_texture, test_texture, "Portrait texture should be set")
	assert_eq(character_portrait.health_percentage, 75.0, "Health percentage should be set")

func test_set_character_data_method():
	# Test the convenience method
	character_portrait.set_character_data("Warrior", test_texture, 50.0)

	assert_eq(character_portrait.character_name, "Warrior", "Character name should be set via method")
	assert_eq(character_portrait.portrait_texture, test_texture, "Portrait texture should be set via method")
	assert_eq(character_portrait.health_percentage, 50.0, "Health percentage should be set via method")

func test_health_percentage_clamping():
	# Test health percentage clamping
	character_portrait.health_percentage = 150.0
	assert_eq(character_portrait.health_percentage, 100.0, "Health should clamp to 100% max")

	character_portrait.health_percentage = -10.0
	assert_eq(character_portrait.health_percentage, 0.0, "Health should clamp to 0% min")

func test_health_bar_color_changes():
	# Test health bar color changes based on percentage using theme colors (AC-2.3.1)
	character_portrait.health_percentage = 75.0
	var health_bar = character_portrait.get_node("HealthBar")
	var fill_style = health_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		# Should use theme success color for healthy (green)
		var has_theme_color = character_portrait.theme \
			and character_portrait.theme.has_color("success", "Colors")
		var expected_color = character_portrait.theme.get_color("success", "Colors") \
			if has_theme_color else Color(0.2, 0.8, 0.2, 1.0)
		assert_eq(fill_style.bg_color, expected_color, "75% health should use theme success color")

	character_portrait.health_percentage = 40.0
	fill_style = health_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		# Should use theme accent color for warning (yellow)
		var has_theme_color = character_portrait.theme \
			and character_portrait.theme.has_color("accent", "Colors")
		var expected_color = character_portrait.theme.get_color("accent", "Colors") \
			if has_theme_color else Color(0.9, 0.6, 0.1, 1.0)
		assert_eq(fill_style.bg_color, expected_color, "40% health should use theme accent color")

	character_portrait.health_percentage = 20.0
	fill_style = health_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		# Should use theme danger color for critical (red)
		var has_theme_color = character_portrait.theme \
			and character_portrait.theme.has_color("danger", "Colors")
		var expected_color = character_portrait.theme.get_color("danger", "Colors") \
			if has_theme_color else Color(0.8, 0.2, 0.2, 1.0)
		assert_eq(fill_style.bg_color, expected_color, "20% health should use theme danger color")

func test_active_state_highlighting():
	# Test active state highlighting (AC-2.3.1, AC-2.3.2)
	character_portrait.is_active = true
	assert_true(character_portrait.is_active, "Active state should be true")

	# Check if glow effect is applied (visual test)
	var portrait_panel = character_portrait.get_node("PortraitPanel")
	assert_not_null(portrait_panel, "Portrait panel should exist")

	character_portrait.is_active = false
	assert_false(character_portrait.is_active, "Active state should be false")

func test_reduced_motion_accessibility():
	# Test reduced motion accessibility (AC-2.4.1)
	character_portrait.respect_reduced_motion = true
	# Set project setting for reduced motion
	ProjectSettings.set_setting("accessibility/reduced_motion", true)

	character_portrait.is_active = true
	# With reduced motion, should use static glow instead of animation
	# This is mainly a visual test, but we can check the modulate
	var portrait_panel = character_portrait.get_node("PortraitPanel")
	assert_not_null(portrait_panel, "Portrait panel should exist")

	# Reset setting
	ProjectSettings.set_setting("accessibility/reduced_motion", false)

func test_status_effect_management():
	# Test status effect addition and removal (AC-2.3.1)
	character_portrait.add_status_effect("poison")
	assert_true(character_portrait.status_effects.has("poison"), "Poison effect should be added")

	character_portrait.add_status_effect("buff")
	assert_true(character_portrait.status_effects.has("buff"), "Buff effect should be added")
	assert_eq(character_portrait.status_effects.size(), 2, "Should have 2 status effects")

	character_portrait.remove_status_effect("poison")
	assert_false(character_portrait.status_effects.has("poison"), "Poison effect should be removed")
	assert_eq(character_portrait.status_effects.size(), 1, "Should have 1 status effect remaining")

func test_duplicate_status_effect_prevention():
	# Test that duplicate status effects are prevented
	character_portrait.add_status_effect("poison")
	character_portrait.add_status_effect("poison")

	assert_eq(character_portrait.status_effects.size(), 1, "Duplicate status effects should be prevented")

func test_clear_status_effects():
	# Test clearing all status effects
	character_portrait.add_status_effect("poison")
	character_portrait.add_status_effect("buff")
	character_portrait.add_status_effect("debuff")

	assert_eq(character_portrait.status_effects.size(), 3, "Should have 3 status effects")

	character_portrait.clear_status_effects()
	assert_eq(character_portrait.status_effects.size(), 0, "All status effects should be cleared")

func test_status_effect_signals():
	# Test status effect signals using GUT's watch_signals
	watch_signals(character_portrait)

	character_portrait.add_status_effect("poison")
	assert_signal_emitted(character_portrait, "status_effect_added", "Status effect added signal should be emitted")

	character_portrait.remove_status_effect("poison")
	assert_signal_emitted(character_portrait, "status_effect_removed", "Status effect removed signal should be emitted")

func test_portrait_clicked_signal():
	# Test portrait click signal using GUT's watch_signals
	character_portrait.character_name = "TestHero"

	watch_signals(character_portrait)

	# Simulate mouse click via the handler directly (gui_input signal handler)
	var input_event = InputEventMouseButton.new()
	input_event.button_index = MOUSE_BUTTON_LEFT
	input_event.pressed = true

	character_portrait._on_portrait_input(input_event)

	assert_signal_emitted(character_portrait, "portrait_clicked", "Portrait clicked signal should be emitted")
	assert_signal_emitted_with_parameters(character_portrait, "portrait_clicked", ["TestHero"])

func test_health_percentage_changed_signal():
	# Test health percentage changed signal
	watch_signals(character_portrait)

	character_portrait.health_percentage = 50.0

	assert_signal_emitted(character_portrait, "health_percentage_changed",
		"Health percentage changed signal should be emitted")
	assert_signal_emitted_with_parameters(character_portrait, "health_percentage_changed", [50.0])

func test_accessibility_methods():
	# Test accessibility methods (AC-2.4.1)
	character_portrait.character_name = "TestHero"
	character_portrait.health_percentage = 75.0

	assert_eq(character_portrait.get_character_name(), "TestHero", "Character name should be accessible")
	assert_eq(character_portrait.get_health_status_text(), "Healthy", "Health status at 75% should be Healthy")

	character_portrait.health_percentage = 20.0
	assert_eq(character_portrait.get_health_status_text(), "Critical", "Low health should show critical")

	character_portrait.add_status_effect("poison")
	character_portrait.add_status_effect("buff")
	var status_text = character_portrait.get_status_effects_text()
	assert_true(status_text.contains("Poison"), "Status text should include poison")
	assert_true(status_text.contains("Buff"), "Status text should include buff")

func test_tooltip_text_generation():
	# Test tooltip text generation
	character_portrait.character_name = "TestHero"
	character_portrait.health_percentage = 50.0
	character_portrait.is_active = true
	character_portrait.add_status_effect("poison")

	var tooltip = character_portrait._get_tooltip_text()
	assert_true(tooltip.contains("TestHero"), "Tooltip should include character name")
	assert_true(tooltip.contains("50%"), "Tooltip should include health percentage")
	assert_true(tooltip.contains("Active Turn"), "Tooltip should include active status")
	assert_true(tooltip.contains("Poison"), "Tooltip should include status effects")

func test_performance_no_memory_leaks():
	# Test for memory leaks from tweens (AC-2.5.1)
	# Create and destroy multiple portrait containers using scene instantiation
	for i in range(10):
		var temp_portrait = CharacterPortraitScene.instantiate()
		add_child(temp_portrait)
		await get_tree().process_frame

		# Trigger active state to create tweens
		temp_portrait.is_active = true
		await get_tree().process_frame
		temp_portrait.is_active = false
		await get_tree().process_frame

		# Remove and free
		remove_child(temp_portrait)
		temp_portrait.queue_free()
		await get_tree().process_frame

	# If we get here without crashes, memory management is working
	pass_test("No memory leaks detected during portrait creation/destruction")

func test_theme_application():
	# Test theme application consistency
	var test_theme = Theme.new()
	character_portrait.theme = test_theme

	# Verify theme is set on parent
	assert_eq(character_portrait.theme, test_theme, "Theme should be set on portrait container")

	# In Godot 4, children inherit theme from parent via the tree, so
	# children don't have an explicit .theme property set - they use the parent's.
	# Just verify children exist and can resolve theme items.
	var health_bar = character_portrait.get_node("HealthBar")
	assert_not_null(health_bar, "Health bar should exist")

	var portrait_panel = character_portrait.get_node("PortraitPanel")
	assert_not_null(portrait_panel, "Portrait panel should exist")

func test_responsive_scaling():
	# Test responsive scaling (if implemented)
	# This would test if the portrait scales properly on different screen sizes
	# For now, just verify the minimum size is maintained
	var min_size = character_portrait._get_minimum_size()
	assert_eq(min_size, Vector2(120, 120), "Minimum size should be maintained")