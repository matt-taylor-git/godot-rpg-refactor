extends GutTest

# Comprehensive Phase 6 Integration Tests
# Tests quest progression, dialogue choices, and lore unlocks working together

func test_quest_acceptance_through_dialogue():
	# Clear state
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	
	# Start dialogue and accept quest
	var result = DialogueManager.start_dialogue("village_elder")
	assert_true(result)
	
	var options = DialogueManager.get_current_options()
	assert_gt(options.size(), 0)
	
	# Select option to ask about quests
	DialogueManager.select_option(0)
	
	# Select option to accept quest
	DialogueManager.select_option(0)
	
	# Verify quest was accepted
	assert_gt(QuestManager.get_active_quests().size(), 0)

func test_quest_completion_triggers_lore_unlock():
	# Clear state
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	CodexManager.unlocked_entries.clear()
	
	# Create and accept a quest
	var quest = QuestFactory.create_quest("kill_goblins", 1)
	QuestManager.accept_quest(quest)
	
	# Trigger enemy kill event
	CodexManager.on_enemy_killed("goblin")
	
	# Verify lore was unlocked
	assert_true(CodexManager.has_unlocked("goblin_history"))

func test_dialogue_option_tracking():
	# Start dialogue
	DialogueManager.start_dialogue("merchant")
	var initial_text = DialogueManager.get_current_text()
	
	# Verify text contains dialogue content
	assert_not_empty(initial_text)
	assert_true(initial_text.contains("shop") or initial_text.contains("trade"))

func test_multiple_dialogue_branches():
	# Test village elder dialogue tree
	DialogueManager.start_dialogue("village_elder")
	assert_true(DialogueManager.is_in_dialogue())
	
	var options = DialogueManager.get_current_options()
	assert_gt(options.size(), 1)
	
	# Try different branch
	DialogueManager.select_option(1)
	var new_text = DialogueManager.get_current_text()
	
	# Text should be different from initial greeting
	assert_not_empty(new_text)

func test_dialogue_quest_acceptance_flow():
	QuestManager.active_quests.clear()
	
	# Start with knight commander
	DialogueManager.start_dialogue("knight_commander")
	assert_true(DialogueManager.is_in_dialogue())
	
	# Get initial options
	var initial_options = DialogueManager.get_current_options()
	assert_gt(initial_options.size(), 0)
	
	# Select dark threat option
	DialogueManager.select_option(0)
	
	# Should have new options including quest acceptance
	var threat_options = DialogueManager.get_current_options()
	assert_gt(threat_options.size(), 0)
	
	# Accept the quest
	DialogueManager.select_option(0)
	
	# Verify quest was accepted
	assert_gt(QuestManager.get_active_quests().size(), 0)

func test_lore_discovery_from_combat():
	CodexManager.unlocked_entries.clear()
	
	# Trigger combat event
	CodexManager.on_enemy_killed("goblin")
	
	# Check that lore entry was unlocked
	var entry = CodexManager.get_entry("goblin_history")
	assert_not_empty(entry)
	assert_eq(entry.get("title"), "The Goblin Tribes")

func test_quest_system_full_cycle():
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	
	# Create quest
	var quest = QuestFactory.create_quest("collect_herbs", 1)
	assert_not_null(quest)
	assert_eq(quest.title, "Herbal Collection")
	
	# Accept quest
	QuestManager.accept_quest(quest)
	assert_true(quest in QuestManager.get_active_quests())
	
	# Progress quest
	for i in range(3):
		QuestManager.update_quest_progress(quest, 1)
	
	# Verify quest is completed
	assert_false(quest in QuestManager.get_active_quests())
	assert_true(quest in QuestManager.get_completed_quests())
	assert_true(quest.completed)

func test_dialogue_quest_lore_integration():
	# Clear all state
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	CodexManager.unlocked_entries.clear()
	
	# Accept quest through dialogue
	DialogueManager.start_dialogue("village_elder")
	DialogueManager.select_option(0)  # Ask about quests
	DialogueManager.select_option(0)  # Accept quest
	
	# Verify quest accepted
	var active = QuestManager.get_active_quests()
	assert_gt(active.size(), 0)
	
	# Complete the quest
	var quest = active[0]
	if quest.target_count > 0:
		QuestManager.update_quest_progress(quest, quest.target_count)
	
	# Verify quest completed
	assert_true(quest in QuestManager.get_completed_quests())

func test_codex_lore_categories():
	CodexManager.unlocked_entries.clear()
	
	# Unlock multiple entries
	CodexManager.unlock_entry("goblin_history")
	CodexManager.unlock_entry("eldridge_founding")
	CodexManager.unlock_entry("ancient_evil")
	
	# Verify categories
	var categories = CodexManager.get_all_categories()
	assert_gt(categories.size(), 0)
	
	# Get entries by category
	var creature_entries = CodexManager.get_entries_by_category("creatures")
	var history_entries = CodexManager.get_entries_by_category("history")
	
	assert_gt(creature_entries.size(), 0)
	assert_gt(history_entries.size(), 0)

func test_dialogue_invalid_npc_handling():
	var result = DialogueManager.start_dialogue("invalid_npc_123")
	assert_false(result)
	assert_false(DialogueManager.is_in_dialogue())

func test_quest_reward_scaling():
	var quest_level1 = QuestFactory.create_quest("kill_goblins", 1)
	var quest_level5 = QuestFactory.create_quest("kill_goblins", 5)
	
	assert_lt(quest_level1.reward_exp, quest_level5.reward_exp)
	assert_lt(quest_level1.reward_gold, quest_level5.reward_gold)

func test_dialogue_text_content():
	# Test each NPC has meaningful dialogue
	var npcs = ["village_elder", "merchant", "knight_commander"]
	
	for npc in npcs:
		DialogueManager.start_dialogue(npc)
		var text = DialogueManager.get_current_text()
		assert_not_empty(text, "NPC %s should have dialogue content" % npc)
		DialogueManager.end_dialogue()

func test_quest_manager_state_isolation():
	# Ensure quest states don't leak between tests
	var initial_active = QuestManager.get_active_quests().size()
	var initial_completed = QuestManager.get_completed_quests().size()
	
	var quest = QuestFactory.create_quest("explore_cave", 1)
	QuestManager.accept_quest(quest)
	
	assert_eq(QuestManager.get_active_quests().size(), initial_active + 1)
	
	# Clean up
	QuestManager.active_quests.clear()
