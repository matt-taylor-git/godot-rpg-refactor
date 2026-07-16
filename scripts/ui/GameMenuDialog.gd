extends Control

# GameMenuDialog - In-game pause menu overlay

const SAVE_SLOT_DIALOG = preload("res://scenes/ui/save_slot_dialog.tscn")
const OPTIONS_DIALOG = preload("res://scenes/ui/options_dialog.tscn")

@onready var dialog_panel = $DialogPanel
@onready var resume_button = $DialogPanel/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button = $DialogPanel/MarginContainer/VBoxContainer/SaveButton
@onready var options_button = $DialogPanel/MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button = $DialogPanel/MarginContainer/VBoxContainer/QuitButton


func _ready():
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.FADE)
	_setup_focus_navigation()


func _setup_focus_navigation():
	resume_button.set("focus_neighbor_bottom", save_button.get_path())
	resume_button.set("focus_neighbor_top", quit_button.get_path())

	save_button.set("focus_neighbor_top", resume_button.get_path())
	save_button.set("focus_neighbor_bottom", options_button.get_path())

	options_button.set("focus_neighbor_top", save_button.get_path())
	options_button.set("focus_neighbor_bottom", quit_button.get_path())

	quit_button.set("focus_neighbor_top", options_button.get_path())
	quit_button.set("focus_neighbor_bottom", resume_button.get_path())

	await get_tree().process_frame
	resume_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()


func _on_resume_pressed():
	UIDialogShell.play_close_and_free(self, dialog_panel)


func _on_save_pressed():
	var dialog = SAVE_SLOT_DIALOG.instantiate()
	add_child(dialog)
	dialog.connect("slot_selected", Callable(self, "_on_save_slot_selected"))
	dialog.tree_exited.connect(func(): save_button.grab_focus())


func _on_save_slot_selected(slot_number: int):
	GameManager.save_game(slot_number)
	UIToast.toast_on(self, "Game saved to slot %d" % slot_number, UIToast.Kind.SUCCESS, 1.8)


func _on_options_pressed():
	var dialog = OPTIONS_DIALOG.instantiate()
	add_child(dialog)
	dialog.tree_exited.connect(func(): options_button.grab_focus())


func _on_quit_pressed():
	GameManager.change_scene("main_menu")
