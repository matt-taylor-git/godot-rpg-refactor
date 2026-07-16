extends Control

# SkillsDialog - Dialog for selecting skills during combat

signal skill_selected(skill_index: int)
signal cancelled

@onready var dialog_panel = $DialogPanel
@onready var skills_container = $DialogPanel/MarginContainer/VBoxContainer/SkillsContainer
@onready var cancel_button = $DialogPanel/MarginContainer/VBoxContainer/CancelButton


func _ready():
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.FADE)
	_populate_skills()


func _populate_skills():
	for child in skills_container.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	var buttons: Array[Button] = []
	for i in range(player.skills.size()):
		var skill = player.skills[i]
		var button = Button.new()
		var cost = skill.mana_cost
		if cost > 0:
			button.text = "%s (%d MP)" % [skill.name, cost]
		else:
			button.text = skill.name
		var tip = skill.description if skill.description else ""
		var reason = ""
		if skill.has_method("get_unusable_reason"):
			reason = skill.get_unusable_reason(player)
		if reason:
			if tip:
				tip += "\n"
			tip += reason
		button.tooltip_text = tip
		button.disabled = not GameManager.can_use_skill(i)
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(0, 40)
		if button.disabled:
			button.modulate = Color(1, 1, 1, 0.45)
		button.connect("pressed", Callable(self, "_on_skill_pressed").bind(i))
		skills_container.add_child(button)
		buttons.append(button)

	buttons.append(cancel_button)

	for i in range(buttons.size()):
		var prev_idx = (i - 1 + buttons.size()) % buttons.size()
		var next_idx = (i + 1) % buttons.size()
		buttons[i].set("focus_neighbor_top", buttons[prev_idx].get_path())
		buttons[i].set("focus_neighbor_bottom", buttons[next_idx].get_path())

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
	UIDialogShell.play_close_and_free(self, dialog_panel)


func _on_cancel_pressed():
	emit_signal("cancelled")
	UIDialogShell.play_close_and_free(self, dialog_panel)
