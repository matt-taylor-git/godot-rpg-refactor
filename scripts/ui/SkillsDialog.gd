extends Control

# SkillsDialog - Dialog for selecting skills during combat

signal skill_selected(skill_index: int)
signal cancelled

@onready var skills_container = $DialogPanel/MarginContainer/VBoxContainer/SkillsContainer
@onready var cancel_button = $DialogPanel/MarginContainer/VBoxContainer/CancelButton

func _ready():
	_populate_skills()

func _populate_skills():
	# Clear existing buttons
	for child in skills_container.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	var buttons: Array[Button] = []
	for i in range(player.skills.size()):
		var skill = player.skills[i]
		var button = Button.new()
		button.text = skill.name + " (" + str(skill.mana_cost) + " MP)"
		button.disabled = not GameManager.can_use_skill(i)
		button.focus_mode = Control.FOCUS_ALL
		button.connect("pressed", Callable(self, "_on_skill_pressed").bind(i))
		skills_container.add_child(button)
		buttons.append(button)

	# Add cancel button to the chain
	buttons.append(cancel_button)

	# Setup vertical focus chain with wrapping
	for i in range(buttons.size()):
		var prev_idx = (i - 1 + buttons.size()) % buttons.size()
		var next_idx = (i + 1) % buttons.size()
		buttons[i].set("focus_neighbor_top", buttons[prev_idx].get_path())
		buttons[i].set("focus_neighbor_bottom", buttons[next_idx].get_path())

	# Grab focus on first non-disabled skill button, or cancel if all disabled
	var focused = false
	for button in buttons:
		if not button.disabled:
			button.grab_focus()
			focused = true
			break
	if not focused:
		cancel_button.grab_focus()

func _on_skill_pressed(skill_index: int):
	emit_signal("skill_selected", skill_index)
	queue_free()

func _on_cancel_pressed():
	emit_signal("cancelled")
	queue_free()
