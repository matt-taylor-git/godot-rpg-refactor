class_name BaseUI
extends Control

# BaseUI - Base class for all UI scenes
# Provides common functionality and responsive layout

signal back_pressed

# Typography system integration
const UITypographyClass = preload("res://scripts/components/UITypography.gd")

# Visual feedback system integration
const UIAnimationSystemClass = preload("res://scripts/components/UIAnimationSystem.gd")
const UISuccessFeedbackClass = preload("res://scripts/components/UISuccessFeedback.gd")
const UIErrorFeedbackClass = preload("res://scripts/components/UIErrorFeedback.gd")
const UILoadingIndicatorClass = preload("res://scripts/components/UILoadingIndicator.gd")

var typography = UITypographyClass.new()

# Feedback system instances
var animation_system: UIAnimationSystem = null
var success_feedback: UISuccessFeedback = null
var error_feedback: UIErrorFeedback = null
var loading_indicator: UILoadingIndicator = null

var ui_title: String = "UI Title"
var show_back_button: bool = true

@onready var title_label: Label = $Content/VBoxContainer/Header/Title
@onready var back_button: Button = $Content/VBoxContainer/Footer/BackButton
@onready var main_content: CenterContainer = $Content/VBoxContainer/MainContent

func _ready():
	# Initialize feedback systems
	_init_feedback_systems()
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
		var font_size = node.get("theme_override_font_sizes/font_size")
		var current_size = font_size if font_size else 14
		var scaled_size = int(current_size * scale)
		# Enforce minimum readable sizes per AC-UI-007
		var min_size = 12 if current_size <= 12 else 14  # 12pt for captions, 14pt for body
		node.set("theme_override_font_sizes/font_size", max(scaled_size, min_size))

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

# Typography helper methods
func apply_heading_large(label: Label):
	label.set("theme_override_font_sizes/font_size", typography.get_heading_large_size())

func apply_heading_medium(label: Label):
	label.set("theme_override_font_sizes/font_size", typography.get_heading_medium_size())

func apply_body_large(label: Label):
	label.set("theme_override_font_sizes/font_size", typography.get_body_large_size())

func apply_body_regular(label: Label):
	label.set("theme_override_font_sizes/font_size", typography.get_body_regular_size())

func apply_caption(label: Label):
	label.set("theme_override_font_sizes/font_size", typography.get_caption_size())

# Spacing helper methods
func get_spacing_xs() -> int:
	return typography.get_spacing_xs()

func get_spacing_sm() -> int:
	return typography.get_spacing_sm()

func get_spacing_md() -> int:
	return typography.get_spacing_md()

func get_spacing_lg() -> int:
	return typography.get_spacing_lg()

func get_spacing_xl() -> int:
	return typography.get_spacing_xl()

# Apply spacing to control margins
func apply_spacing_margin(control: Control, spacing: int):
	control.set("theme_override_constants/margin_left", spacing)
	control.set("theme_override_constants/margin_top", spacing)
	control.set("theme_override_constants/margin_right", spacing)
	control.set("theme_override_constants/margin_bottom", spacing)

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

# Visual feedback helper methods (AC-UI-009, AC-UI-011, AC-UI-012)

func _init_feedback_systems():
	"""Initialize visual feedback systems"""
	# Initialize animation system
	animation_system = UIAnimationSystemClass.new()
	add_child(animation_system)

	# Initialize success feedback
	success_feedback = UISuccessFeedbackClass.new()
	add_child(success_feedback)

	# Initialize error feedback
	error_feedback = UIErrorFeedbackClass.new()
	add_child(error_feedback)

	# Initialize loading indicator (not shown by default)
	loading_indicator = UILoadingIndicatorClass.new()
	loading_indicator.visible = false
	add_child(loading_indicator)

func show_success_feedback(message: String = "Success!"):
	"""
	Show success feedback with optional message
	- 500ms bounce/glow animation with green checkmark
	"""
	if success_feedback:
		success_feedback.show_feedback()
		print("Success: %s" % message)

func show_error_feedback(message: String = "Error occurred"):
	"""
	Show error feedback with message
	- 500ms shake/red flash animation with red icon
	- Persists until dismissed if needed
	"""
	if error_feedback:
		error_feedback.show_error(null, message)
		print("Error: %s" % message)

func show_loading(message: String = "Loading..."):
	"""
	Show loading indicator with threshold
	- Shows after 500ms delay
	- Animated spinner at 60fps
	"""
	if loading_indicator:
		loading_indicator.progress_text = message
		loading_indicator.start_loading()
		print("Loading: %s" % message)

func hide_loading():
	"""
	Hide loading indicator
	"""
	if loading_indicator:
		loading_indicator.stop_loading()
		print("Loading complete")

func update_loading_progress(progress: float, status: String = ""):
	"""
	Update loading progress (0.0 to 1.0)
	"""
	if loading_indicator:
		loading_indicator.update_progress(progress, status)

# Form validation helpers

func validate_form_field(field: Control, is_valid: bool, error_message: String = ""):
	"""
	Validate form field and show error feedback if invalid
	- Adds error icon to field
	- Shows error message
	"""
	if not is_valid and error_feedback:
		error_feedback.add_error_icon(field)
		if not error_message.is_empty():
			show_error_feedback(error_message)
	return is_valid

func clear_form_errors():
	"""
	Clear all form validation errors
	"""
	if error_feedback:
		error_feedback.dismiss_error()

# Feedback integration with GameManager signals

func connect_game_feedback():
	"""
	Connect to GameManager operation signals for automatic feedback
	"""
	GameManager.connect("operation_succeeded", Callable(self, "_on_operation_succeeded"))
	GameManager.connect("operation_failed", Callable(self, "_on_operation_failed"))

func _on_operation_succeeded(message: String):
	"""Handle GameManager success operations"""
	show_success_feedback(message)

func _on_operation_failed(message: String):
	"""Handle GameManager failure operations"""
	show_error_feedback(message)

# Menu transition animations

func animate_menu_transition(out_menu: Control, in_menu: Control):
	"""
	Animate smooth transition between menus
	- Fade out old menu
	- Fade in new menu
	"""
	if animation_system:
		# Fade out
		var fade_out = animation_system.fade_out(out_menu, 0.1)
		if fade_out:
			fade_out.finished.connect(func():
				out_menu.visible = false
				in_menu.modulate = Color(1, 1, 1, 0)
				in_menu.visible = true
				animation_system.fade_in(in_menu, 0.1)
			)
