extends Control

# GameMenuDialog - In-game pause menu overlay

const SAVE_SLOT_DIALOG = preload("res://scenes/ui/save_slot_dialog.tscn")

@onready var resume_button = $DialogPanel/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button = $DialogPanel/MarginContainer/VBoxContainer/SaveButton
@onready var quit_button = $DialogPanel/MarginContainer/VBoxContainer/QuitButton


func _ready():
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.finished.connect(func(): tween.kill())
	_setup_focus_navigation()


func _setup_focus_navigation():
	resume_button.set("focus_neighbor_bottom", save_button.get_path())
	resume_button.set("focus_neighbor_top", quit_button.get_path())

	save_button.set("focus_neighbor_top", resume_button.get_path())
	save_button.set("focus_neighbor_bottom", quit_button.get_path())

	quit_button.set("focus_neighbor_top", save_button.get_path())
	quit_button.set("focus_neighbor_bottom", resume_button.get_path())

	await get_tree().process_frame
	resume_button.grab_focus()


func _on_resume_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func(): tween.kill())
	await tween.finished
	queue_free()


func _on_save_pressed():
	var dialog = SAVE_SLOT_DIALOG.instantiate()
	add_child(dialog)
	dialog.connect("slot_selected", Callable(self, "_on_save_slot_selected"))
	dialog.tree_exited.connect(func(): save_button.grab_focus())


func _on_save_slot_selected(slot_number: int):
	GameManager.save_game(slot_number)


func _on_quit_pressed():
	GameManager.change_scene("main_menu")
