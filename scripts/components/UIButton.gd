extends Button

# UIButton - Enhanced button with additional functionality

@export var button_type: String = "normal"  # normal, primary, destructive
@export var auto_focus: bool = false

func _ready():
	_update_button_style()
	if auto_focus:
		grab_focus()

func _update_button_style():
	match button_type:
		"primary":
			add_theme_stylebox_override("normal", theme.get_stylebox("primary", "Button"))
		"destructive":
			# For destructive actions, we could add a red style
			pass
		"normal":
			# Use default theme styling
			pass

func set_button_type(new_type: String):
	button_type = new_type
	_update_button_style()

# Enhanced focus behavior
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
