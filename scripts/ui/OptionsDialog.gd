extends Control

# OptionsDialog - Accessibility settings (audio volume deferred)

@onready var dialog_panel = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var reduced_motion_check: CheckBox = (
	$DialogPanel/MarginContainer/VBoxContainer/ReducedMotionCheck
)
@onready var apply_button = $DialogPanel/MarginContainer/VBoxContainer/ButtonRow/ApplyButton
@onready var close_button = $DialogPanel/MarginContainer/VBoxContainer/ButtonRow/CloseButton


func _ready() -> void:
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.FADE)
	if title_label:
		title_label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold")
		)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)

	# Use in-memory settings (do not reload from disk — would clobber runtime tour/session)
	if reduced_motion_check:
		reduced_motion_check.button_pressed = GameSettings.get_reduced_motion()
		reduced_motion_check.add_theme_color_override(
			"font_color", UIThemeManager.get_color("text_primary")
		)

	_setup_focus_navigation()


func _setup_focus_navigation() -> void:
	if reduced_motion_check and apply_button and close_button:
		reduced_motion_check.focus_neighbor_bottom = apply_button.get_path()
		apply_button.focus_neighbor_top = reduced_motion_check.get_path()
		apply_button.focus_neighbor_right = close_button.get_path()
		apply_button.focus_neighbor_left = close_button.get_path()
		close_button.focus_neighbor_top = reduced_motion_check.get_path()
		close_button.focus_neighbor_left = apply_button.get_path()
		close_button.focus_neighbor_right = apply_button.get_path()
	await get_tree().process_frame
	if reduced_motion_check:
		reduced_motion_check.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _on_apply_pressed() -> void:
	if reduced_motion_check:
		GameSettings.set_reduced_motion(reduced_motion_check.button_pressed)
	GameSettings.save_settings()
	UIToast.toast_on(self, "Settings saved", UIToast.Kind.SUCCESS, 1.5)
	_close()


func _on_close_pressed() -> void:
	_close()


func _close() -> void:
	UIDialogShell.play_close_and_free(self, dialog_panel)
