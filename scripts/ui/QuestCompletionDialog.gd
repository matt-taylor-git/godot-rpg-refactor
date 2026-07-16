extends Control

# QuestCompletionDialog - Quest rewards with celebration particles

var quest = null

@onready var dialog_panel = $Panel
@onready var quest_title_label = $Panel/MarginContainer/VBoxContainer/QuestTitle
@onready var exp_reward_label = $Panel/MarginContainer/VBoxContainer/Rewards/ExpReward
@onready var gold_reward_label = $Panel/MarginContainer/VBoxContainer/Rewards/GoldReward
@onready var ok_button = $Panel/MarginContainer/VBoxContainer/OkButton


func _ready():
	print("QuestCompletionDialog initialized")
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.SCALE)
	if quest_title_label:
		quest_title_label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
	if quest:
		_setup_quest_display()
	_play_celebration()
	ok_button.grab_focus()


func set_quest(q) -> void:
	quest = q
	if is_node_ready():
		_setup_quest_display()


func _setup_quest_display():
	if not quest:
		return
	quest_title_label.text = quest.title
	exp_reward_label.text = "Experience: +%d" % quest.reward_exp
	gold_reward_label.text = "Gold: +%d" % quest.reward_gold


func _play_celebration() -> void:
	if UIDialogShell.is_reduced_motion():
		return
	var particles := CPUParticles2D.new()
	particles.name = "CelebrationBurst"
	particles.amount = 28
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.gravity = Vector2(0, 180)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = UIThemeManager.get_color("title_gold")
	# Center of dialog
	if dialog_panel:
		particles.position = dialog_panel.position + dialog_panel.size / 2.0
	else:
		particles.position = size / 2.0
	add_child(particles)
	particles.emitting = true
	var cleanup = create_tween()
	cleanup.tween_interval(1.0)
	cleanup.tween_callback(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func _on_ok_pressed():
	UIDialogShell.play_close_and_free(self, dialog_panel)
