extends Control

# SkillsDialog - Dialog for selecting skills during combat

signal skill_selected(skill_index: int)
signal cancelled

@onready var skills_container = $DialogPanel/VBoxContainer/SkillsContainer

func _ready():
	_populate_skills()

func _populate_skills():
	# Clear existing buttons
	for child in skills_container.get_children():
		child.queue_free()

	var player = GameManager.get_player()
	if not player:
		return

	for i in range(player.skills.size()):
		var skill = player.skills[i]
		var button = Button.new()
		button.text = skill.name + " (" + str(skill.mana_cost) + " MP)"
		button.disabled = not GameManager.can_use_skill(i)
		button.connect("pressed", Callable(self, "_on_skill_pressed").bind(i))
		skills_container.add_child(button)

func _on_skill_pressed(skill_index: int):
	emit_signal("skill_selected", skill_index)
	queue_free()

func _on_cancel_pressed():
	emit_signal("cancelled")
	queue_free()
