extends Control

# BaseUI - Base class for all UI scenes
# Provides common functionality and responsive layout

signal back_pressed

@onready var title_label: Label = $Content/VBoxContainer/Header/Title
@onready var back_button: Button = $Content/VBoxContainer/Footer/BackButton
@onready var main_content: CenterContainer = $Content/VBoxContainer/MainContent

var ui_title: String = "UI Title"
var show_back_button: bool = true

func _ready():
	_update_ui()
	_connect_signals()
	_setup_responsive_layout()

func set_title(new_title: String):
	ui_title = new_title
	if title_label:
		title_label.text = ui_title

func set_back_button_visible(visible: bool):
	show_back_button = visible
	if back_button:
		back_button.visible = visible

func add_main_content(node: Node):
	if main_content and main_content.get_child_count() == 0:
		main_content.add_child(node)

func clear_main_content():
	if main_content:
		for child in main_content.get_children():
			child.queue_free()

func _update_ui():
	if title_label:
		title_label.text = ui_title
	if back_button:
		back_button.visible = show_back_button

func _connect_signals():
	if back_button:
		back_button.connect("pressed", Callable(self, "_on_back_pressed"))

func _setup_responsive_layout():
	# Adjust layout for different screen sizes
	var viewport_size = get_viewport_rect().size

	# Scale margins based on screen size
	var margin_scale = min(viewport_size.x / 800.0, viewport_size.y / 600.0)
	margin_scale = clamp(margin_scale, 0.5, 1.5)

	var margin_container = $Content
	if margin_container:
		margin_container.set("theme_override_constants/margin_left", int(20 * margin_scale))
		margin_container.set("theme_override_constants/margin_top", int(20 * margin_scale))
		margin_container.set("theme_override_constants/margin_right", int(20 * margin_scale))
		margin_container.set("theme_override_constants/margin_bottom", int(20 * margin_scale))

	# Adjust font sizes for different screen sizes
	var font_scale = margin_scale
	_adjust_font_sizes_recursive(self, font_scale)

	# Handle different aspect ratios
	var aspect_ratio = viewport_size.x / viewport_size.y
	if aspect_ratio > 1.6:  # Wide screen
		_adjust_for_wide_screen()
	elif aspect_ratio < 1.3:  # Tall screen
		_adjust_for_tall_screen()

func _adjust_font_sizes_recursive(node: Node, scale: float):
	if node is Label or node is Button:
		var current_size = node.get("theme_override_font_sizes/font_size") if node.get("theme_override_font_sizes/font_size") else 14
		node.set("theme_override_font_sizes/font_size", int(current_size * scale))

	for child in node.get_children():
		_adjust_font_sizes_recursive(child, scale)

func _adjust_for_wide_screen():
	# For wide screens, we can use more horizontal space
	var header = $Content/VBoxContainer/Header
	if header:
		header.alignment = BoxContainer.ALIGNMENT_BEGIN

func _adjust_for_tall_screen():
	# For tall screens, we might want to adjust spacing
	var container = $Content/VBoxContainer
	if container:
		container.set("theme_override_constants/separation", 30)

func _on_back_pressed():
	emit_signal("back_pressed")
	# Default behavior: go back to main menu
	# Child classes can override this or connect to the signal
	_change_scene("main_menu")

func _change_scene(scene_name: String):
	GameManager.change_scene(scene_name)

# Utility functions for common UI operations
func show_error_message(message: String):
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = message
	error_dialog.theme = theme
	add_child(error_dialog)
	error_dialog.popup_centered()

func show_confirmation_dialog(message: String, callback: Callable):
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Confirm"
	confirm_dialog.dialog_text = message
	confirm_dialog.theme = theme
	confirm_dialog.connect("confirmed", callback)
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func create_button(text: String, callback: Callable = Callable()) -> Button:
	var button = Button.new()
	button.text = text
	button.theme = theme
	if callback.is_valid():
		button.connect("pressed", callback)
	return button

func create_label(text: String, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.theme = theme
	return label

func create_progress_bar() -> ProgressBar:
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = true
	progress_bar.theme = theme
	return progress_bar

# Virtual methods for child classes to override
func _on_enter_scene():
	# Called when entering this scene
	pass

func _on_exit_scene():
	# Called when exiting this scene
	pass
