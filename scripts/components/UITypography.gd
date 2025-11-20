extends Resource
class_name UITypography

# UITypography - Centralized typography definitions for consistent text styling
# Provides font sizes and spacing constants following design system guidelines

# Font Size Hierarchy (in pixels)
const FONT_SIZE_HEADING_LARGE = 24
const FONT_SIZE_HEADING_MEDIUM = 20
const FONT_SIZE_BODY_LARGE = 16
const FONT_SIZE_BODY_REGULAR = 14
const FONT_SIZE_CAPTION = 12

# Spacing Grid (8px base system, in pixels)
const SPACING_XS = 4   # Extra small
const SPACING_SM = 8   # Small
const SPACING_MD = 16  # Medium
const SPACING_LG = 24  # Large
const SPACING_XL = 32  # Extra large

# Font size getters for programmatic access
func get_heading_large_size() -> int:
	return FONT_SIZE_HEADING_LARGE

func get_heading_medium_size() -> int:
	return FONT_SIZE_HEADING_MEDIUM

func get_body_large_size() -> int:
	return FONT_SIZE_BODY_LARGE

func get_body_regular_size() -> int:
	return FONT_SIZE_BODY_REGULAR

func get_caption_size() -> int:
	return FONT_SIZE_CAPTION

# Spacing getters for programmatic access
func get_spacing_xs() -> int:
	return SPACING_XS

func get_spacing_sm() -> int:
	return SPACING_SM

func get_spacing_md() -> int:
	return SPACING_MD

func get_spacing_lg() -> int:
	return SPACING_LG

func get_spacing_xl() -> int:
	return SPACING_XL

# Utility functions for responsive scaling
func get_scaled_font_size(base_size: int, scale_factor: float) -> int:
	return int(base_size * scale_factor)

func get_minimum_readable_size() -> int:
	return FONT_SIZE_CAPTION  # 12pt minimum

# Validation functions
func is_valid_font_size(size: int) -> bool:
	var valid_sizes = [
		FONT_SIZE_HEADING_LARGE,
		FONT_SIZE_HEADING_MEDIUM,
		FONT_SIZE_BODY_LARGE,
		FONT_SIZE_BODY_REGULAR,
		FONT_SIZE_CAPTION
	]
	return valid_sizes.has(size)

func is_valid_spacing(spacing: int) -> bool:
	var valid_spacings = [
		SPACING_XS,
		SPACING_SM,
		SPACING_MD,
		SPACING_LG,
		SPACING_XL
	]
	return valid_spacings.has(spacing)

# Font hierarchy classification
func get_font_hierarchy_type(size: int) -> String:
	if size >= FONT_SIZE_HEADING_LARGE:
		return "heading_large"
	elif size >= FONT_SIZE_HEADING_MEDIUM:
		return "heading_medium"
	elif size >= FONT_SIZE_BODY_LARGE:
		return "body_large"
	elif size >= FONT_SIZE_BODY_REGULAR:
		return "body_regular"
	else:
		return "caption"

# Contrast ratio validation functions (AC-UI-008)
const WCAG_AA_MINIMUM_CONTRAST = 4.5

# Calculate relative luminance from RGB color
func _calculate_relative_luminance(color: Color) -> float:
	var r = color.r
	var g = color.g
	var b = color.b

	# Convert to linear RGB
	r = (r / 12.92) if r <= 0.03928 else pow((r + 0.055) / 1.055, 2.4)
	g = (g / 12.92) if g <= 0.03928 else pow((g + 0.055) / 1.055, 2.4)
	b = (b / 12.92) if b <= 0.03928 else pow((b + 0.055) / 1.055, 2.4)

	# Calculate luminance
	return 0.2126 * r + 0.7152 * g + 0.0722 * b

# Calculate contrast ratio between two colors
func calculate_contrast_ratio(foreground: Color, background: Color) -> float:
	var l1 = _calculate_relative_luminance(foreground)
	var l2 = _calculate_relative_luminance(background)

	# Ensure l1 is lighter than l2
	if l1 < l2:
		var temp = l1
		l1 = l2
		l2 = temp

	return (l1 + 0.05) / (l2 + 0.05)

# Check if contrast ratio meets WCAG AA standards
func is_wcag_aa_compliant(foreground: Color, background: Color) -> bool:
	var ratio = calculate_contrast_ratio(foreground, background)
	return ratio >= WCAG_AA_MINIMUM_CONTRAST

# Validate theme color combinations
func validate_theme_contrast(theme: Theme) -> Dictionary:
	var results = {
		"compliant": true,
		"violations": [],
		"total_checked": 0
	}

	# Check text colors against background
	var background_color = theme.get_color("background", "Panel")
	var text_colors = [
		theme.get_color("font_color", "Label"),
		theme.get_color("font_color", "Button"),
		theme.get_color("font_hover_color", "Button"),
		theme.get_color("font_pressed_color", "Button"),
		theme.get_color("font_disabled_color", "Button")
	]

	for text_color in text_colors:
		results.total_checked += 1
		if not is_wcag_aa_compliant(text_color, background_color):
			results.compliant = false
			results.violations.append({
				"foreground": text_color,
				"background": background_color,
				"ratio": calculate_contrast_ratio(text_color, background_color)
			})

	return results