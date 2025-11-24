extends Node

# UIThemeManager.gd
# Autoload singleton to manage and provide global access to the game's UI theme.

const THEME_PATH = "res://resources/ui_theme.tres"
var theme: Theme

func _ready():
    theme = load(THEME_PATH)
    if not theme:
        printerr("UIThemeManager: Failed to load theme at %s" % THEME_PATH)

# --- Color Getters ---

func get_color(name: String) -> Color:
    if not theme:
        return Color.MAGENTA # Error color
    return theme.get_color(name, "Default")

func get_background_color() -> Color:
    return get_color("background")

func get_text_primary_color() -> Color:
    return get_color("text_primary")

func get_primary_action_color() -> Color:
    return get_color("primary_action")

func get_secondary_color() -> Color:
    return get_color("secondary")

func get_accent_color() -> Color:
    return get_color("accent")

func get_success_color() -> Color:
    return get_color("success")

func get_danger_color() -> Color:
    return get_color("danger")

# --- Accessibility ---

# Calculates the relative luminance of a color.
# Formula from WCAG 2.0: https://www.w3.org/TR/WCAG20/#relativeluminancedef
func _get_relative_luminance(color: Color) -> float:
    var r = color.r
    var g = color.g
    var b = color.b

    var r_lin = 0.0
    if r <= 0.03928:
        r_lin = r / 12.92
    else:
        r_lin = pow((r + 0.055) / 1.055, 2.4)

    var g_lin = 0.0
    if g <= 0.03928:
        g_lin = g / 12.92
    else:
        g_lin = pow((g + 0.055) / 1.055, 2.4)

    var b_lin = 0.0
    if b <= 0.03928:
        b_lin = b / 12.92
    else:
        b_lin = pow((b + 0.055) / 1.055, 2.4)

    return 0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin

# Calculates the contrast ratio between two colors.
# Returns a value from 1 to 21.
func get_contrast_ratio(fg_color: Color, bg_color: Color) -> float:
    var l1 = _get_relative_luminance(fg_color)
    var l2 = _get_relative_luminance(bg_color)

    if l1 > l2:
        return (l1 + 0.05) / (l2 + 0.05)
    else:
        return (l2 + 0.05) / (l1 + 0.05)

# Validates if a color combination meets WCAG AA standards (4.5:1).
func validate_contrast_aa(fg_color: Color, bg_color: Color) -> bool:
    return get_contrast_ratio(fg_color, bg_color) >= 4.5
