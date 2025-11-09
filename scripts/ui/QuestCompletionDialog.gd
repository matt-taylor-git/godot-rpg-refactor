extends Control

# QuestCompletionDialog - Shows when a quest is completed with rewards

@onready var quest_title_label = $Panel/VBoxContainer/QuestTitle
@onready var exp_reward_label = $Panel/VBoxContainer/Rewards/ExpReward
@onready var gold_reward_label = $Panel/VBoxContainer/Rewards/GoldReward
@onready var ok_button = $Panel/VBoxContainer/OkButton

var quest = null

func _ready():
	print("QuestCompletionDialog initialized")
	if quest:
		_setup_quest_display()

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

func _on_ok_pressed():
	queue_free()
