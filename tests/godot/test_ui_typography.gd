extends GutTest

# TestUITypography - Unit tests for UITypography resource class
# Tests font hierarchy, spacing constants, and validation functions

var ui_typography_class = null
var typography = null

func before_each():
	if ui_typography_class == null:
		ui_typography_class = load("res://scripts/components/UITypography.gd")
	typography = ui_typography_class.new()

func after_each():
	typography = null

func test_font_size_constants():
	assert_eq(typography.FONT_SIZE_HEADING_LARGE, 24, "Heading large should be 24pt")
	assert_eq(typography.FONT_SIZE_HEADING_MEDIUM, 20, "Heading medium should be 20pt")
	assert_eq(typography.FONT_SIZE_BODY_LARGE, 16, "Body large should be 16pt")
	assert_eq(typography.FONT_SIZE_BODY_REGULAR, 14, "Body regular should be 14pt")
	assert_eq(typography.FONT_SIZE_CAPTION, 12, "Caption should be 12pt")

func test_spacing_constants():
	assert_eq(typography.SPACING_XS, 4, "Extra small spacing should be 4px")
	assert_eq(typography.SPACING_SM, 8, "Small spacing should be 8px")
	assert_eq(typography.SPACING_MD, 16, "Medium spacing should be 16px")
	assert_eq(typography.SPACING_LG, 24, "Large spacing should be 24px")
	assert_eq(typography.SPACING_XL, 32, "Extra large spacing should be 32px")

func test_font_size_getters():
	assert_eq(typography.get_heading_large_size(), 24, "get_heading_large_size should return 24")
	assert_eq(typography.get_heading_medium_size(), 20, "get_heading_medium_size should return 20")
	assert_eq(typography.get_body_large_size(), 16, "get_body_large_size should return 16")
	assert_eq(typography.get_body_regular_size(), 14, "get_body_regular_size should return 14")
	assert_eq(typography.get_caption_size(), 12, "get_caption_size should return 12")

func test_spacing_getters():
	assert_eq(typography.get_spacing_xs(), 4, "get_spacing_xs should return 4")
	assert_eq(typography.get_spacing_sm(), 8, "get_spacing_sm should return 8")
	assert_eq(typography.get_spacing_md(), 16, "get_spacing_md should return 16")
	assert_eq(typography.get_spacing_lg(), 24, "get_spacing_lg should return 24")
	assert_eq(typography.get_spacing_xl(), 32, "get_spacing_xl should return 32")

func test_scaled_font_size():
	assert_eq(typography.get_scaled_font_size(16, 1.0), 16, "No scaling should return original size")
	assert_eq(typography.get_scaled_font_size(16, 1.5), 24, "1.5x scaling of 16 should be 24")
	assert_eq(typography.get_scaled_font_size(20, 0.8), 16, "0.8x scaling of 20 should be 16")

func test_minimum_readable_size():
	assert_eq(typography.get_minimum_readable_size(), 12, "Minimum readable size should be 12pt")

func test_valid_font_size():
	assert_true(typography.is_valid_font_size(24), "24pt should be valid")
	assert_true(typography.is_valid_font_size(20), "20pt should be valid")
	assert_true(typography.is_valid_font_size(16), "16pt should be valid")
	assert_true(typography.is_valid_font_size(14), "14pt should be valid")
	assert_true(typography.is_valid_font_size(12), "12pt should be valid")
	assert_false(typography.is_valid_font_size(18), "18pt should not be valid")
	assert_false(typography.is_valid_font_size(10), "10pt should not be valid")

func test_valid_spacing():
	assert_true(typography.is_valid_spacing(4), "4px spacing should be valid")
	assert_true(typography.is_valid_spacing(8), "8px spacing should be valid")
	assert_true(typography.is_valid_spacing(16), "16px spacing should be valid")
	assert_true(typography.is_valid_spacing(24), "24px spacing should be valid")
	assert_true(typography.is_valid_spacing(32), "32px spacing should be valid")
	assert_false(typography.is_valid_spacing(6), "6px spacing should not be valid")
	assert_false(typography.is_valid_spacing(12), "12px spacing should not be valid")

func test_font_hierarchy_type():
	assert_eq(typography.get_font_hierarchy_type(24), "heading_large", "24pt should be heading_large")
	assert_eq(typography.get_font_hierarchy_type(22), "heading_medium", "22pt should be heading_medium")
	assert_eq(typography.get_font_hierarchy_type(20), "heading_medium", "20pt should be heading_medium")
	assert_eq(typography.get_font_hierarchy_type(18), "body_large", "18pt should be body_large")
	assert_eq(typography.get_font_hierarchy_type(16), "body_large", "16pt should be body_large")
	assert_eq(typography.get_font_hierarchy_type(15), "body_regular", "15pt should be body_regular")
	assert_eq(typography.get_font_hierarchy_type(14), "body_regular", "14pt should be body_regular")
	assert_eq(typography.get_font_hierarchy_type(12), "caption", "12pt should be caption")
	assert_eq(typography.get_font_hierarchy_type(10), "caption", "10pt should be caption")

func test_contrast_ratio_calculation():
	# Test black on white (should be high contrast)
	var black = Color(0, 0, 0)
	var white = Color(1, 1, 1)
	var ratio = typography.calculate_contrast_ratio(black, white)
	assert_gt(ratio, 20.0, "Black on white should have high contrast ratio")

	# Test white on black
	ratio = typography.calculate_contrast_ratio(white, black)
	assert_gt(ratio, 20.0, "White on black should have high contrast ratio")

	# Test same colors (should be 1.0)
	var gray = Color(0.5, 0.5, 0.5)
	ratio = typography.calculate_contrast_ratio(gray, gray)
	assert_eq(ratio, 1.0, "Same colors should have contrast ratio of 1.0")

func test_wcag_aa_compliance():
	var black = Color(0, 0, 0)
	var white = Color(1, 1, 1)
	var dark_gray = Color(0.3, 0.3, 0.3)
	var light_gray = Color(0.7, 0.7, 0.7)

	# High contrast should be compliant
	assert_true(typography.is_wcag_aa_compliant(black, white), "Black on white should be WCAG AA compliant")
	assert_true(typography.is_wcag_aa_compliant(white, black), "White on black should be WCAG AA compliant")

	# Low contrast should not be compliant
	assert_false(typography.is_wcag_aa_compliant(dark_gray, light_gray), "Dark gray on light gray should not be compliant")
	assert_false(typography.is_wcag_aa_compliant(light_gray, dark_gray), "Light gray on dark gray should not be compliant")

func test_responsive_scaling_integration():
	# Test that scaling maintains minimum sizes
	var base_size = 16  # body_large
	var small_scale = 0.5
	var scaled = typography.get_scaled_font_size(base_size, small_scale)
	assert_eq(scaled, 8, "16 * 0.5 = 8")

	# But in practice, with minimum enforcement in BaseUI, it would be max(8, 14) = 14
	# This test verifies the scaling function itself

func test_minimum_readable_size_enforcement():
	# Test the minimum size constant
	assert_eq(typography.get_minimum_readable_size(), 12, "Minimum readable size should be 12pt")

	# Test that scaling doesn't go below minimum in theory
	# (actual enforcement is in BaseUI)