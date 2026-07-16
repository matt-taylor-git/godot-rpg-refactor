extends Control

# SaveSlotDialog - Dialog for selecting save slots to load

signal slot_selected(slot_number: int)
signal cancelled

@onready var dialog_panel = $DialogPanel
@onready var slot1_button = $DialogPanel/MarginContainer/VBoxContainer/SlotContainer/Slot1Button
@onready var slot2_button = $DialogPanel/MarginContainer/VBoxContainer/SlotContainer/Slot2Button
@onready var slot3_button = $DialogPanel/MarginContainer/VBoxContainer/SlotContainer/Slot3Button
@onready var cancel_button = $DialogPanel/MarginContainer/VBoxContainer/CancelButton

func _ready():
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.FADE)
	update_slot_info()
	_setup_focus_navigation()

func _setup_focus_navigation():
	# Vertical chain with wrapping: Slot1 -> Slot2 -> Slot3 -> Cancel
	slot1_button.set("focus_neighbor_bottom", slot2_button.get_path())
	slot1_button.set("focus_neighbor_top", cancel_button.get_path())

	slot2_button.set("focus_neighbor_top", slot1_button.get_path())
	slot2_button.set("focus_neighbor_bottom", slot3_button.get_path())

	slot3_button.set("focus_neighbor_top", slot2_button.get_path())
	slot3_button.set("focus_neighbor_bottom", cancel_button.get_path())

	cancel_button.set("focus_neighbor_top", slot3_button.get_path())
	cancel_button.set("focus_neighbor_bottom", slot1_button.get_path())

	# Grab focus after dialog fades in
	await get_tree().process_frame
	slot1_button.grab_focus()

func update_slot_info():
	# Check each save slot and update button text
	for slot in range(1, 4):
		var save_path = "user://save_slot_%d.json" % slot
		var button = get_slot_button(slot)

		if FileAccess.file_exists(save_path):
			# Load save data to get character info
			var file = FileAccess.open(save_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				var json = JSON.new()
				var error = json.parse(json_string)
				if error == OK and json.data.has("player"):
					var player_data = json.data.player
					var character_name = player_data.get("name", "Unknown")
					var character_class = player_data.get("character_class", "Unknown")
					var level = player_data.get("level", 1)
					button.text = "Slot %d: %s (%s, Level %d)" % [slot, character_name, character_class, level]
				else:
					button.text = "Slot %d: [Corrupted Save]" % slot
			else:
				button.text = "Slot %d: [Load Error]" % slot
		else:
			button.text = "Slot %d: [Empty]" % slot

func get_slot_button(slot_number: int) -> Button:
	match slot_number:
		1: return slot1_button
		2: return slot2_button
		3: return slot3_button
		_: return null

func _on_slot_selected(slot_number: int):
	emit_signal("slot_selected", slot_number)
	UIDialogShell.play_close_and_free(self, dialog_panel)

func _on_cancel_pressed():
	emit_signal("cancelled")
	UIDialogShell.play_close_and_free(self, dialog_panel)
