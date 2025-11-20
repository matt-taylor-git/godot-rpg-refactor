# UIButton Component Usage Guide

## Overview

The `UIButton` component is a modern, accessible button implementation that provides consistent styling, animations, and interaction patterns across the entire game interface. It extends Godot's base `Button` class with enhanced features while maintaining full compatibility.

## Features

- **Modern Styling**: Hover effects, pressed states, and smooth transitions
- **Accessibility**: WCAG AA compliance with focus indicators and keyboard navigation
- **Theme Integration**: Centralized styling through `UIThemeManager`
- **Animation System**: Tween-based animations with performance optimization
- **State Management**: Four distinct visual states (Normal, Hover, Pressed, Disabled)

## Usage

### In Scene Files

Instead of using regular `Button` nodes, instantiate the `UIButton` component:

```gdscript
# In Godot scene files (.tscn)
[node name="MyButton" parent="Container" instance=ExtResource("ui_button")]
layout_mode = 2
text = "Click Me"
```

### In Code

```gdscript
# Create UIButton programmatically
var button = UIButton.new()
button.text = "My Button"
button.connect("pressed", Callable(self, "_on_button_pressed"))
add_child(button)

# Apply theme
button.apply_theme(my_theme)

# Set disabled state
button.disabled = true
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | Button label text |
| `disabled` | bool | Disable interaction |
| `theme_override` | Theme | Optional theme override |

## Signals

| Signal | Description |
|--------|-------------|
| `pressed` | Button clicked |
| `button_down` | Button pressed down |
| `button_up` | Button released |
| `mouse_entered` | Mouse hover started |
| `mouse_exited` | Mouse hover ended |
| `focus_entered` | Keyboard focus gained |
| `focus_exited` | Keyboard focus lost |
| `state_changed` | State transition occurred |
| `theme_changed` | Theme applied |

## Methods

| Method | Description |
|--------|-------------|
| `set_text(text: String)` | Set button text |
| `set_disabled(disabled: bool)` | Enable/disable button |
| `apply_theme(theme: Theme)` | Apply theme styling |
| `play_hover_animation()` | Trigger hover animation |
| `play_press_animation()` | Trigger press animation |

## Theme Integration

UIButton supports comprehensive theming through Godot's Theme system:

```gdscript
# Theme items (defined in ui_theme.tres)
UIButton/colors/font_color
UIButton/colors/font_hover_color
UIButton/colors/font_pressed_color
UIButton/colors/font_disabled_color
UIButton/colors/font_shadow_color

UIButton/styles/normal
UIButton/styles/hover
UIButton/styles/pressed
UIButton/styles/disabled
UIButton/styles/background
```

## Accessibility

- **Focus Indicators**: 3:1 contrast ratio focus rings
- **Keyboard Navigation**: Tab navigation with Space/Enter activation
- **Screen Reader Support**: Proper accessible names and roles
- **Touch Targets**: Minimum 44px size for mobile compatibility

## Animation Specifications

- **Hover Effect**: 200ms scale transition (1.0 → 1.05)
- **Press Effect**: 100ms scale transition (1.05 → 0.95)
- **Easing**: Tween.EASE_OUT with Tween.TRANS_QUAD
- **Performance**: <5% frame rate impact, automatic cleanup

## Migration from Regular Buttons

Replace regular Button nodes with UIButton instances:

```diff
- [node name="MyButton" type="Button" parent="Container"]
+ [node name="MyButton" parent="Container" instance=ExtResource("ui_button")]
  layout_mode = 2
  text = "Click Me"
```

## Best Practices

1. **Always use UIButton** instead of regular Button nodes for consistency
2. **Test accessibility** features with keyboard-only navigation
3. **Use theme variations** for special button types (primary, destructive)
4. **Avoid overriding animations** unless specifically required
5. **Ensure proper touch targets** for mobile platforms

## Troubleshooting

- **No hover effects**: Check theme has hover styles defined
- **Accessibility issues**: Verify focus indicators meet contrast requirements
- **Performance problems**: Ensure tween cleanup in _exit_tree()
- **Styling inconsistencies**: Check theme application order

## Future Enhancements

- Theme variations for different button types
- Custom animation configurations
- Enhanced accessibility features
- Performance optimizations for large button counts