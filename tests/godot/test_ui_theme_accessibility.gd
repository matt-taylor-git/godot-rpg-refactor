extends GutTest

# GUT Test suite for UI theme accessibility validation
# Automates acceptance criterion AC-UI-014: Color Contrast Accessibility
# Tests all text/background color combinations to ensure minimum 4.5:1 contrast ratio (WCAG AA)

func before_all():
	# Ensure UIThemeManager is available
	assert_has_singleton("UIThemeManager", "UIThemeManager singleton should be registered.")

func test_contrast_ratio_calculation():
	var black = Color.BLACK
	var white = Color.WHITE
	# The contrast between black and white should be 21.
	var ratio = UIThemeManager.get_contrast_ratio(black, white)
	assert_almost_eq(ratio, 21.0, 0.1, "Contrast ratio between black and white should be ~21.")

func test_theme_color_accessibility():
	# This test validates that the primary text color has sufficient contrast
	# against the main background color, as per WCAG AA standards (4.5:1).

	var text_color = UIThemeManager.get_text_primary_color()
	var bg_color = UIThemeManager.get_background_color()

	var ratio = UIThemeManager.get_contrast_ratio(text_color, bg_color)

	var is_accessible = UIThemeManager.validate_contrast_aa(text_color, bg_color)

	assert_true(is_accessible, "Primary text on background should meet WCAG AA contrast ratio of 4.5:1. Ratio is: " + str(ratio))

func test_button_color_accessibility():
	# Validates that the button's text color has sufficient contrast against its background.
	var button_text_color = UIThemeManager.get_text_primary_color()
	var button_bg_color = UIThemeManager.get_primary_action_color()

	var ratio = UIThemeManager.get_contrast_ratio(button_text_color, button_bg_color)
	var is_accessible = UIThemeManager.validate_contrast_aa(button_text_color, button_bg_color)

	assert_true(is_accessible, "Button text on button background should meet WCAG AA contrast ratio of 4.5:1. Ratio is: " + str(ratio))

func test_all_defined_colors_load():
	# A simple test to ensure all our defined colors can be retrieved without error.
	var color_names = [
		"background",
		"text_primary",
		"primary_action",
		"secondary",
		"accent",
		"success",
		"danger"
	]

	for color_name in color_names:
		var color = UIThemeManager.get_color(color_name)
		assert_ne(color, Color.MAGENTA, "Color '%s' should be defined in the theme." % color_name)

func test_accent_vs_background_contrast():
	var bg = UIThemeManager.get_background_color()
	var accent = UIThemeManager.get_accent_color()
	var ratio = UIThemeManager.get_contrast_ratio(accent, bg)

	assert_true(UIThemeManager.validate_contrast_aa(accent, bg),
		"Accent color on background should meet WCAG AA (ratio: %s)" % ratio)
	assert_gte(ratio, 4.5,
		"Accent color contrast ratio should be >= 4.5:1, got %s" % ratio)

func test_secondary_vs_background_contrast():
	var bg = UIThemeManager.get_background_color()
	var secondary = UIThemeManager.get_secondary_color()
	var ratio = UIThemeManager.get_contrast_ratio(secondary, bg)

	assert_true(UIThemeManager.validate_contrast_aa(secondary, bg),
		"Secondary color on background should meet WCAG AA (ratio: %s)" % ratio)
	assert_gte(ratio, 4.5,
		"Secondary color contrast ratio should be >= 4.5:1, got %s" % ratio)

func test_success_vs_background_contrast():
	var bg = UIThemeManager.get_background_color()
	var success = UIThemeManager.get_success_color()
	var ratio = UIThemeManager.get_contrast_ratio(success, bg)

	assert_true(UIThemeManager.validate_contrast_aa(success, bg),
		"Success color on background should meet WCAG AA (ratio: %s)" % ratio)
	assert_gte(ratio, 4.5,
		"Success color contrast ratio should be >= 4.5:1, got %s" % ratio)

func test_danger_vs_background_contrast():
	var bg = UIThemeManager.get_background_color()
	var danger = UIThemeManager.get_danger_color()
	var ratio = UIThemeManager.get_contrast_ratio(danger, bg)

	assert_true(UIThemeManager.validate_contrast_aa(danger, bg),
		"Danger color on background should meet WCAG AA (ratio: %s)" % ratio)
	assert_gte(ratio, 4.5,
		"Danger color contrast ratio should be >= 4.5:1, got %s" % ratio)

func test_text_vs_success_button_contrast():
	var text = UIThemeManager.get_text_primary_color()
	var success = UIThemeManager.get_success_color()

	# Lighten success slightly to simulate button hover state
	var success_hover = success.lightened(0.2)
	var ratio = UIThemeManager.get_contrast_ratio(text, success_hover)
	var is_accessible = UIThemeManager.validate_contrast_aa(text, success_hover)

	assert_true(is_accessible,
		"Text on success/green buttons should meet WCAG AA (ratio: %s)" % ratio)

func test_text_vs_danger_button_contrast():
	var text = UIThemeManager.get_text_primary_color()
	var danger = UIThemeManager.get_danger_color()

	# Lighten danger slightly to simulate button hover state
	var danger_hover = danger.lightened(0.2)
	var ratio = UIThemeManager.get_contrast_ratio(text, danger_hover)
	var is_accessible = UIThemeManager.validate_contrast_aa(text, danger_hover)

	assert_true(is_accessible,
		"Text on danger/red buttons should meet WCAG AA (ratio: %s)" % ratio)

func test_disabled_text_contrast():
	var bg = UIThemeManager.get_background_color()
	var disabled = UIThemeManager.get_color("disabled_text")
	var ratio = UIThemeManager.get_contrast_ratio(disabled, bg)

	assert_true(UIThemeManager.validate_contrast_aa(disabled, bg),
		"Disabled text should meet WCAG AA (ratio: %s)" % ratio)

func test_all_color_pairs_meet_contrast_minimum():
	# Comprehensive test: iterate through all color combinations
	var colors = {
		"background": UIThemeManager.get_background_color(),
		"text_primary": UIThemeManager.get_text_primary_color(),
		"primary_action": UIThemeManager.get_primary_action_color(),
		"secondary": UIThemeManager.get_secondary_color(),
		"accent": UIThemeManager.get_accent_color(),
		"success": UIThemeManager.get_success_color(),
		"danger": UIThemeManager.get_danger_color()
	}

	var text_colors = ["text_primary"]
	var background_colors = ["background", "primary_action", "secondary", "accent", "success", "danger"]

	for text_name in text_colors:
		var text_color = colors[text_name]
		for bg_name in background_colors:
			var bg_color = colors[bg_name]

			var ratio = UIThemeManager.get_contrast_ratio(text_color, bg_color)
			var meets_aa = UIThemeManager.validate_contrast_aa(text_color, bg_color)

			assert_true(meets_aa,
				"%s on %s : contrast ratio %.2f should meet WCAG AA 4.5:1 minimum" % [text_name, bg_name, ratio])

func test_contrast_ratio_calculation_accuracy():
	# Test known contrast ratio pairs
	var black = Color.BLACK
	var white = Color.WHITE
	var ratio = UIThemeManager.get_contrast_ratio(white, black)

	# White on black has maximum contrast (21:1)
	assert_eq(ratio, 21.0,
		"White on black should have 21:1 contrast ratio, got %s" % ratio)

	# Test black on white (should be same ratio)
	var ratio2 = UIThemeManager.get_contrast_ratio(black, white)
	assert_eq(ratio2, 21.0,
		"Black on white should have 21:1 contrast ratio, got %s" % ratio2)

func test_same_color_has_minimum_contrast():
	# Same color has 1:1 contrast (minimum)
	var color = UIThemeManager.get_background_color()
	var ratio = UIThemeManager.get_contrast_ratio(color, color)

	assert_eq(ratio, 1.0,
		"Same color should have 1:1 contrast ratio, got %s" % ratio)


