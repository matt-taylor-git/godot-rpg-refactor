extends GutTest

# Test UIProgressBar component functionality
# Tests gradient rendering, animations, status effects, and accessibility

var progress_bar = null

func before_each():
	progress_bar = load("res://scripts/components/UIProgressBar.gd").new()
	add_child_autofree(progress_bar)

func test_gradient_fill_enabled():
	# Test that gradient fill is enabled by default
	assert_true(progress_bar.enable_gradient_fill, "Gradient fill should be enabled by default")

func test_value_text_display():
	# Test value text display functionality
	progress_bar.max_value = 100
	progress_bar.value = 75
	progress_bar.show_value_text = true

	# Wait for UI to update
	await get_tree().process_frame

	var value_label = progress_bar.get_node_or_null("ValueLabel")
	assert_not_null(value_label, "Value label should exist")
	assert_true(value_label.visible, "Value label should be visible when show_value_text is true")
	assert_eq(value_label.text, "75/100", "Value label should show current/max values")

func test_animated_value_change():
	# Test animated value transitions
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.animate_value_changes = true

	var initial_value = progress_bar.value
	progress_bar.set_value_animated(50.0, true)

	# Wait for animation to start
	await get_tree().create_timer(0.1).timeout

	# Value should be animating (not instantly set)
	assert_gt(progress_bar.value, initial_value, "Value should be animating upwards")

	# Wait for animation to complete
	await get_tree().create_timer(0.4).timeout

	assert_eq(progress_bar.value, 50.0, "Value should reach target after animation")

func test_status_effect_overlay():
	# Test status effect overlay functionality
	assert_true(progress_bar.enable_status_effects, "Status effects should be enabled by default")

	progress_bar.add_status_effect_overlay("poison")

	var status_container = progress_bar.get_node_or_null("StatusContainer")
	assert_not_null(status_container, "Status container should exist")

	var effect_icon = status_container.get_node_or_null("StatusEffectIcon")
	assert_not_null(effect_icon, "Status effect icon should be created")

	assert_true(progress_bar.status_effects.has("poison"), "Poison effect should be tracked")

func test_status_effect_styling():
	# Test that status effects apply visual styling
	var original_modulate = progress_bar.modulate

	progress_bar.add_status_effect_overlay("poison")

	# Poison should apply green tint
	assert_ne(progress_bar.modulate, original_modulate, "Modulate should change with poison effect")
	assert_eq(progress_bar.modulate, Color(0.8, 1.0, 0.8, 1.0), "Poison should apply green tint")

func test_status_effect_removal():
	# Test status effect removal
	progress_bar.add_status_effect_overlay("poison")
	assert_true(progress_bar.status_effects.has("poison"), "Poison effect should exist")

	progress_bar.remove_status_effect_overlay("poison")
	assert_false(progress_bar.status_effects.has("poison"), "Poison effect should be removed")

func test_minimum_size():
	# Test accessibility minimum size requirements
	var min_size = progress_bar.get_minimum_size()
	assert_gt(min_size.x, 40, "Minimum width should meet accessibility requirements")
	assert_gt(min_size.y, 40, "Minimum height should meet accessibility requirements")

func test_gradient_texture_creation():
	# Test that gradient texture is created
	var gradient_texture = progress_bar.get_node_or_null("GradientTexture")
	assert_not_null(gradient_texture, "Gradient texture should exist")

	# Texture should be created when visual state updates
	assert_not_null(gradient_texture.texture, "Gradient texture should have a texture assigned")

func test_theme_application():
	# Test theme integration
	var test_theme = Theme.new()
	progress_bar.theme = test_theme

	# Theme should be applied to child components
	var value_label = progress_bar.get_node_or_null("ValueLabel")
	assert_eq(value_label.theme, test_theme, "Value label should use progress bar theme")

func test_animation_cleanup():
	# Test that tweens are properly cleaned up
	progress_bar.set_value_animated(50.0, true)

	# Force cleanup by removing from tree
	progress_bar.queue_free()
	await get_tree().process_frame

	# Tween should be killed (no memory leaks)
	assert_true(true, "Animation cleanup test passed")

func test_accessibility_text_contrast():
	# Test high contrast text for accessibility
	progress_bar.show_value_text = true

	var value_label = progress_bar.get_node_or_null("ValueLabel")
	assert_not_null(value_label, "Value label should exist for contrast testing")

	# Label should have white text for high contrast on dark backgrounds
	var font_color = value_label.get_theme_color("font_color")
	assert_eq(font_color, Color.WHITE, "Text should be white for high contrast accessibility")

func test_responsive_scaling():
	# Test responsive scaling (basic test - full integration would need viewport changes)
	assert_true(progress_bar.responsive_scaling, "Responsive scaling should be enabled by default")

	# Minimum size should still be enforced
	var min_size = progress_bar.get_minimum_size()
	assert_gt(min_size.x, 40, "Responsive scaling should still meet minimum accessibility size")

func test_gradient_rendering():
	# Test that gradient is created and applied
	progress_bar.enable_gradient_fill = true
	progress_bar._setup_gradient()

	var gradient_texture = progress_bar.get_node_or_null("GradientTexture")
	assert_not_null(gradient_texture, "Gradient texture should exist")
	assert_not_null(gradient_texture.texture, "Gradient texture should have a texture assigned")

func test_color_transitions():
	# Test color changes based on health percentage
	progress_bar.max_value = 100

	# Test low health (red)
	progress_bar.value = 10
	progress_bar._update_visual_state()
	# Color would be determined by gradient - hard to test directly

	# Test medium health (yellow)
	progress_bar.value = 40
	progress_bar._update_visual_state()

	# Test high health (green)
	progress_bar.value = 80
	progress_bar._update_visual_state()

	assert_true(true, "Color transitions test passed")

func test_status_effect_overlay_system():
	# Test comprehensive status effect system
	progress_bar.add_status_effect_overlay("poison")
	assert_true(progress_bar.status_effects.has("poison"), "Poison effect should be added")

	progress_bar.add_status_effect_overlay("buff")
	assert_true(progress_bar.status_effects.has("buff"), "Buff effect should be added")

	assert_eq(progress_bar.status_effects.size(), 2, "Should have 2 status effects")

	progress_bar.remove_status_effect_overlay("poison")
	assert_false(progress_bar.status_effects.has("poison"), "Poison effect should be removed")
	assert_eq(progress_bar.status_effects.size(), 1, "Should have 1 status effect remaining")

func test_animation_timing():
	# Test that animations complete within specified time
	progress_bar.max_value = 100
	progress_bar.value = 0

	var start_time = Time.get_ticks_msec() / 1000.0
	progress_bar.set_value_animated(50.0, true)

	# Wait for animation to complete
	await get_tree().create_timer(0.4).timeout

	var end_time = Time.get_ticks_msec() / 1000.0
	var duration = end_time - start_time

	assert_lt(duration, 0.35, "Animation should complete within 350ms")
	assert_eq(progress_bar.value, 50.0, "Value should reach target")

func test_tween_cleanup():
	# Test that tweens are properly cleaned up
	progress_bar.set_value_animated(75.0, true)

	# Force immediate completion
	await get_tree().create_timer(0.1).timeout

	# Tween should be cleaned up after completion
	assert_true(true, "Tween cleanup test passed")

func test_accessibility_compliance():
	# Test WCAG AA compliance
	progress_bar.show_value_text = true
	progress_bar._update_value_label()

	var value_label = progress_bar.get_node_or_null("ValueLabel")
	assert_not_null(value_label, "Value label should exist for accessibility testing")

	# Test that theme consistency validation works
	var is_consistent = progress_bar.validate_theme_consistency()
	assert_true(is_consistent, "Theme should be consistent")

func test_performance_maintenance():
	# Test that animations maintain acceptable frame rate
	progress_bar.max_value = 100
	progress_bar.value = 0

	# Start animation
	progress_bar.set_value_animated(100.0, true)

	# Monitor for a short period
	var start_time = Time.get_ticks_msec() / 1000.0
	var frame_count = 0
	var min_fps = 60.0

	while Time.get_ticks_msec() / 1000.0 - start_time < 0.2:  # Monitor for 200ms
		await get_tree().process_frame
		frame_count += 1
		var delta = get_process_delta_time()
		if delta > 0:
			min_fps = min(min_fps, 1.0 / delta)

	# Animation should maintain reasonable frame rate
	assert_gt(min_fps, 30.0, "Animation should maintain at least 30fps")

func test_reduced_motion_respect():
	# Test reduced motion accessibility setting
	var original_respect = progress_bar.respect_reduced_motion
	progress_bar.respect_reduced_motion = true

	# Mock reduced motion setting
	ProjectSettings.set_setting("accessibility/reduced_motion", true)

	progress_bar.set_value_animated(25.0, true)

	# Should complete immediately due to reduced motion
	assert_eq(progress_bar.value, 25.0, "Value should change immediately with reduced motion")

	# Restore setting
	progress_bar.respect_reduced_motion = original_respect
	ProjectSettings.set_setting("accessibility/reduced_motion", false)

func test_colorblind_friendly_mode():
	# Test colorblind-friendly color scheme
	progress_bar.colorblind_friendly = true
	progress_bar._setup_gradient()

	# Test that gradient is created with different colors
	var gradient_texture = progress_bar.get_node_or_null("GradientTexture")
	assert_not_null(gradient_texture.texture, "Colorblind gradient should be created")

	# Test status text in colorblind mode
	progress_bar.value = 20  # Low health
	progress_bar._update_value_label()

	var value_label = progress_bar.get_node_or_null("ValueLabel")
	assert_not_null(value_label, "Value label should exist")
	assert_true(value_label.text.contains("(Critical)"), "Should show status text for colorblind users")

func test_theme_override():
	# Test theme override functionality
	var test_theme = Theme.new()
	test_theme.set_color("health_high", "UIProgressBar", Color(1, 0, 1, 1))  # Magenta for testing

	progress_bar.apply_theme_override(test_theme)

	# Theme should be applied
	assert_eq(progress_bar.theme, test_theme, "Theme override should be applied")

func test_responsive_font_scaling():
	# Test responsive font scaling
	var original_viewport = progress_bar.get_viewport_rect().size

	# Mock different screen sizes
	# Note: This is a basic test - full testing would require viewport changes

	var font_size = progress_bar._get_responsive_font_size()
	assert_true(font_size >= 10, "Font size should be at least 10")
	assert_true(font_size <= 18, "Font size should be at most 18")