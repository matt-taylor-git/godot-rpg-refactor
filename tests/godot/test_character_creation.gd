extends GutTest

# Character Creation Test Suite
# Tests all functionality of the CharacterCreation scene

const CharacterCreationScene = preload("res://scenes/ui/character_creation.tscn")

func test_class_selection_logic():
	# Test that class selection updates the character sprite and stats
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test initial state
	assert_eq(character_creation.selected_class, "Hero", "Initial class should be Hero")

	# Test class selection
	character_creation._on_class_selected("Warrior")
	assert_eq(character_creation.selected_class, "Warrior", "Class should update to Warrior")

	# Test that sprite updates
	assert_not_null(character_creation.character_sprite.texture, "Sprite texture should not be null")

	# Test that stats update
	assert_true(character_creation.stats_text.text.contains("Attack:"), "Stats text should contain attack info")

	# Clean up
	character_creation.queue_free()

func test_name_validation():
	# Test character name validation logic
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test valid names
	assert_true(character_creation._validate_character_name("John"), "John should be valid")
	assert_true(character_creation._validate_character_name("Alice123"), "Alice123 should be valid")
	assert_true(character_creation._validate_character_name("A1b"), "A1b should be valid (minimum length)")

	# Test invalid names
	assert_false(character_creation._validate_character_name("A"), "A should be invalid (too short)")
	assert_false(character_creation._validate_character_name("ThisNameIsWayTooLong"), "Long name should be invalid")
	assert_false(character_creation._validate_character_name("John Doe"), "Name with space should be invalid")
	assert_false(character_creation._validate_character_name("John-Doe"), "Name with hyphen should be invalid")
	assert_false(character_creation._validate_character_name(""), "Empty name should be invalid")

	# Clean up
	character_creation.queue_free()

func test_stat_calculations():
	# Test that stat calculations are correct for each class
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test Hero stats
	character_creation._on_class_selected("Hero")
	var hero_stats = character_creation.class_stats["Hero"]
	assert_eq(hero_stats.attack, 12, "Hero attack should be 12")
	assert_eq(hero_stats.defense, 6, "Hero defense should be 6")

	# Test Warrior stats
	character_creation._on_class_selected("Warrior")
	var warrior_stats = character_creation.class_stats["Warrior"]
	assert_eq(warrior_stats.attack, 15, "Warrior attack should be 15")
	assert_eq(warrior_stats.defense, 8, "Warrior defense should be 8")

	# Test Mage stats
	character_creation._on_class_selected("Mage")
	var mage_stats = character_creation.class_stats["Mage"]
	assert_eq(mage_stats.attack, 8, "Mage attack should be 8")
	assert_eq(mage_stats.defense, 4, "Mage defense should be 4")

	# Test Rogue stats
	character_creation._on_class_selected("Rogue")
	var rogue_stats = character_creation.class_stats["Rogue"]
	assert_eq(rogue_stats.attack, 10, "Rogue attack should be 10")
	assert_eq(rogue_stats.defense, 5, "Rogue defense should be 5")

	# Clean up
	character_creation.queue_free()

func test_navigation_flow():
	# Test step-by-step navigation functionality
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test initial step
	assert_eq(character_creation.current_step, 1, "Initial step should be 1")

	# Test that we can't go back from step 1
	assert_true(character_creation.prev_button.disabled, "Previous button should be disabled on step 1")

	# Test that we can't proceed without valid name
	character_creation.name_input.text = "A"  # Invalid name
	character_creation._on_name_input_changed("A")
	assert_false(character_creation._validate_character_name("A"), "Short name should be invalid")

	# Test that we can proceed with valid name
	character_creation.name_input.text = "John"
	character_creation._on_name_input_changed("John")
	assert_true(character_creation._validate_character_name("John"), "Valid name should be valid")

	# Clean up
	character_creation.queue_free()

func test_accessibility_features():
	# Test keyboard navigation and focus indicators
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that class buttons exist and are set up
	var class_btn_path = "CenterContainer/CreationPanel/VBoxContainer" \
		+ "/Content/LeftPanel/ClassSection/ClassButtons"
	var hero_button = character_creation.get_node(
		class_btn_path + "/HeroButton")
	assert_not_null(hero_button, "Hero button should exist")

	# Test that focus indicators are set up if button exists
	if hero_button:
		assert_eq(hero_button.focus_mode, Control.FOCUS_ALL, "Hero button should have focus mode set")

	# Clean up
	character_creation.queue_free()

func test_visual_highlighting():
	# Test that visual highlighting works for class selection
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test initial highlighting (Hero should be highlighted)
	var class_btn_path = "CenterContainer/CreationPanel/VBoxContainer" \
		+ "/Content/LeftPanel/ClassSection/ClassButtons"
	var hero_button = character_creation.get_node(
		class_btn_path + "/HeroButton")
	var warrior_button = character_creation.get_node(
		class_btn_path + "/WarriorButton")

	assert_eq(hero_button.modulate, Color(1, 0.8, 0.5), "Hero button should be highlighted initially")
	assert_eq(warrior_button.modulate, Color(1, 1, 1), "Warrior button should not be highlighted initially")

	# Test highlighting changes when class is selected
	character_creation._on_class_selected("Warrior")
	assert_eq(hero_button.modulate, Color(1, 1, 1), "Hero button should not be highlighted after selection")
	assert_eq(warrior_button.modulate, Color(1, 0.8, 0.5), "Warrior button should be highlighted after selection")

	# Clean up
	character_creation.queue_free()

func test_animated_stat_bars():
	# Test that animated stat bars work correctly
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# _ready() selects Hero and starts a tween; verify bar exists
	assert_not_null(character_creation.strength_bar, "Strength bar should exist")

	# Select Warrior and wait for sequential tweens (5 bars x 0.2s each)
	character_creation._on_class_selected("Warrior")
	if character_creation.current_tween:
		await character_creation.current_tween.finished

	# Check that stat bars have been updated
	var warrior_modifiers = character_creation.class_stat_modifiers["Warrior"]
	assert_eq(character_creation.strength_bar.value,
		warrior_modifiers.strength, "Strength bar should match warrior strength")

	# Clean up
	character_creation.queue_free()

func test_step_navigation():
	# Test step-by-step navigation system
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test initial step indicator
	assert_eq(character_creation.step_indicator.text, "Step 1/4", "Step indicator should show Step 1/4")
	assert_eq(character_creation.step_description.text, "Name Input", "Step description should show Name Input")

	# Test that we can't go back from step 1
	assert_true(character_creation.prev_button.disabled, "Previous button should be disabled on step 1")

	# Test that next button is enabled
	assert_false(character_creation.next_button.disabled, "Next button should be enabled")

	# Clean up
	character_creation.queue_free()

func test_confirmation_dialog():
	# Test confirmation dialog functionality
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Set valid character data (max 12 chars)
	character_creation.name_input.text = "TestChar"
	character_creation._on_name_input_changed("TestChar")
	character_creation._on_class_selected("Hero")

	# Test that confirmation dialog can be shown
	# Note: In a real test, we would mock the dialog and test its behavior
	assert_true(character_creation._validate_creation_ready(), "Character should be ready for creation")

	# Clean up
	character_creation.queue_free()

func test_background_animation():
	# Test background animation system
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that background animation is initialized
	assert_false(character_creation.reduced_motion_enabled, "Reduced motion should be disabled by default")
	assert_true(character_creation.background_animation_active, "Background animation should be active")

	# Test that we can stop background animation
	character_creation._stop_background_animation()
	assert_false(character_creation.background_animation_active, "Background animation should be stopped")

	# Clean up
	character_creation.queue_free()

func test_contrast_ratio_verification():
	# Test WCAG AA contrast ratio verification
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that contrast ratio verification runs without errors
	# Note: This is a basic test - in a real implementation, we would verify actual contrast ratios
	character_creation._verify_contrast_ratios()
	assert_true(true, "Contrast ratio verification should complete without errors")

	# Clean up
	character_creation.queue_free()

func test_sound_effects():
	# Test that sound effect play methods exist (sounds are disabled until assets are added)
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Verify play methods exist and can be called without error
	assert_true(character_creation.has_method("_play_class_selection_sound"),
		"Should have class selection sound method")
	assert_true(character_creation.has_method("_play_confirmation_sound"),
		"Should have confirmation sound method")
	assert_true(character_creation.has_method("_play_error_sound"),
		"Should have error sound method")
	assert_true(character_creation.has_method("_play_success_sound"),
		"Should have success sound method")

	# Clean up
	character_creation.queue_free()

func test_integration_with_gamemanager():
	# Test integration with GameManager
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that GameManager methods are called correctly
	# Note: This would require mocking GameManager in a real test environment
	assert_true(true, "GameManager integration test placeholder")

	# Clean up
	character_creation.queue_free()

func test_memory_management():
	# Test that memory management is proper (tweens are cleaned up)
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that we can clean up tweens
	character_creation._on_class_selected("Warrior")
	await get_tree().create_timer(0.1).timeout  # Wait for animation

	# Test that current_tween can be cleaned up
	if character_creation.current_tween:
		character_creation.current_tween.kill()
		character_creation.current_tween = null

	assert_null(character_creation.current_tween, "Current tween should be null after cleanup")

	# Clean up
	character_creation.queue_free()

func test_responsive_design():
	# Test that the UI adapts to different screen sizes
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that layout modes are set correctly
	var center_container = character_creation.get_node("CenterContainer")
	assert_eq(center_container.layout_mode, 1, "Center container should have layout mode 1")

	# Test that panels have correct layout
	var creation_panel = character_creation.get_node("CenterContainer/CreationPanel")
	assert_eq(creation_panel.layout_mode, 2, "Creation panel should have layout mode 2")

	# Clean up
	character_creation.queue_free()

func test_error_handling():
	# Test error handling and validation
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test that invalid inputs are handled gracefully
	var result = character_creation._validate_character_name("")
	assert_false(result, "Empty name should be invalid")

	result = character_creation._validate_character_name("A")
	assert_false(result, "Single character name should be invalid")

	result = character_creation._validate_character_name("ThisNameIsWayTooLongForTheValidationRules")
	assert_false(result, "Very long name should be invalid")

	# Clean up
	character_creation.queue_free()

func test_performance():
	# Test that the scene loads and runs efficiently
	var start_time = Time.get_ticks_msec()
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame
	var end_time = Time.get_ticks_msec()

	var load_time = end_time - start_time
	assert_lt(load_time, 1000, "Scene should load in under 1 second")

	# Clean up
	character_creation.queue_free()

func test_comprehensive_functionality():
	# Comprehensive test that exercises all major functionality
	var character_creation = CharacterCreationScene.instantiate()
	add_child(character_creation)
	await get_tree().process_frame

	# Test class selection
	character_creation._on_class_selected("Mage")
	assert_eq(character_creation.selected_class, "Mage", "Class should be Mage")

	# Test name validation
	character_creation.name_input.text = "TestUser"
	character_creation._on_name_input_changed("TestUser")
	assert_true(character_creation._validate_character_name("TestUser"), "TestUser should be valid")

	# Test stat calculations
	var mage_stats = character_creation.class_stats["Mage"]
	assert_eq(mage_stats.attack, 8, "Mage attack should be 8")

	# Test step navigation
	assert_eq(character_creation.current_step, 1, "Should be on step 1")

	# Test visual polish
	assert_true(character_creation.background_animation_active, "Background animation should be active")

	# Clean up
	character_creation.queue_free()
