extends Node

# QuestManager - Manages quest tracking and progression
# Autoload singleton for quest system

signal quest_accepted(quest_title: String)
signal quest_completed(quest_title: String)
signal quest_progress_updated(quest_title: String, current: int, target: int)

var active_quests: Array = []
var completed_quests: Array = []

func _ready():
	print("QuestManager initialized")

func accept_quest(quest) -> void:
	if quest in active_quests:
		return  # Already accepted

	active_quests.append(quest)
	emit_signal("quest_accepted", quest.title)
	print("Accepted quest: ", quest.title)

func complete_quest(quest) -> void:
	if quest not in active_quests:
		return

	# Give rewards
	if GameManager.game_data.player:
		GameManager.game_data.player.add_experience(quest.reward_exp)
		GameManager.game_data.player.gold += quest.reward_gold

	# Move to completed
	active_quests.erase(quest)
	completed_quests.append(quest)
	quest.completed = true

	emit_signal("quest_completed", quest.title)
	print("Completed quest: ", quest.title)

func update_quest_progress(quest, amount: int = 1) -> void:
	if quest not in active_quests:
		return

	quest.update_progress(amount)
	emit_signal("quest_progress_updated", quest.title, quest.current_count, quest.target_count)

	# Auto-complete if target reached
	if quest.is_completed():
		complete_quest(quest)

func get_active_quests() -> Array:
	return active_quests

func get_completed_quests() -> Array:
	return completed_quests

func has_active_quests() -> bool:
	return active_quests.size() > 0

# Event handlers for different quest types
func on_enemy_killed(enemy_name: String) -> void:
	for quest in active_quests:
		if quest.type == "kill":
			if enemy_name.to_lower().contains("goblin") and quest.title.contains("Goblin"):
				update_quest_progress(quest)

func on_item_collected(item_name: String) -> void:
	for quest in active_quests:
		if quest.type == "collect":
			if item_name.to_lower().contains("herb") and quest.title.contains("Herbal"):
				update_quest_progress(quest)

func on_level_up(new_level: int) -> void:
	# Could trigger level-based quests or milestones
	pass

func on_combat_end(enemy_name: String) -> void:
	on_enemy_killed(enemy_name)

# Save/Load functionality
func save_quests() -> Dictionary:
	var active_data = []
	for quest in active_quests:
		active_data.append({
			"title": quest.title,
			"description": quest.description,
			"type": quest.type,
			"target_count": quest.target_count,
			"current_count": quest.current_count,
			"reward_exp": quest.reward_exp,
			"reward_gold": quest.reward_gold,
			"completed": quest.completed
		})

	var completed_data = []
	for quest in completed_quests:
		completed_data.append({
			"title": quest.title,
			"description": quest.description,
			"type": quest.type,
			"target_count": quest.target_count,
			"current_count": quest.current_count,
			"reward_exp": quest.reward_exp,
			"reward_gold": quest.reward_gold,
			"completed": quest.completed
		})

	return {
		"active": active_data,
		"completed": completed_data
	}

func load_quests(data: Dictionary) -> void:
	active_quests.clear()
	completed_quests.clear()

	# Load active quests
	if data.has("active"):
		for quest_data in data.active:
			var quest = QuestFactory.Quest.new()
			quest.title = quest_data.get("title", "")
			quest.description = quest_data.get("description", "")
			quest.type = quest_data.get("type", "")
			quest.target_count = quest_data.get("target_count", 0)
			quest.current_count = quest_data.get("current_count", 0)
			quest.reward_exp = quest_data.get("reward_exp", 0)
			quest.reward_gold = quest_data.get("reward_gold", 0)
			quest.completed = quest_data.get("completed", false)
			active_quests.append(quest)

	# Load completed quests
	if data.has("completed"):
		for quest_data in data.completed:
			var quest = QuestFactory.Quest.new()
			quest.title = quest_data.get("title", "")
			quest.description = quest_data.get("description", "")
			quest.type = quest_data.get("type", "")
			quest.target_count = quest_data.get("target_count", 0)
			quest.current_count = quest_data.get("current_count", 0)
			quest.reward_exp = quest_data.get("reward_exp", 0)
			quest.reward_gold = quest_data.get("reward_gold", 0)
			quest.completed = quest_data.get("completed", true)
			completed_quests.append(quest)
