extends GutTest

# Test Quest System functionality

func test_quest_creation():
	var quest = QuestFactory.create_quest("kill_goblins", 1)
	assert_eq(quest.title, "Goblin Extermination")
	assert_eq(quest.type, "kill")
	assert_eq(quest.target_count, 5)
	assert_false(quest.completed)

func test_quest_acceptance():
	var quest = QuestFactory.create_quest("collect_herbs", 1)
	var initial_count = QuestManager.get_active_quests().size()
	
	QuestManager.accept_quest(quest)
	
	assert_eq(QuestManager.get_active_quests().size(), initial_count + 1)
	assert_true(quest in QuestManager.get_active_quests())

func test_quest_progress_tracking():
	var quest = QuestFactory.create_quest("kill_goblins", 1)
	QuestManager.accept_quest(quest)
	
	assert_eq(quest.current_count, 0)
	QuestManager.update_quest_progress(quest, 1)
	assert_eq(quest.current_count, 1)
	
	QuestManager.update_quest_progress(quest, 2)
	assert_eq(quest.current_count, 3)

func test_quest_completion():
	var quest = QuestFactory.create_quest("explore_cave", 1)
	QuestManager.accept_quest(quest)
	
	assert_eq(QuestManager.get_completed_quests().size(), 0)
	assert_true(quest in QuestManager.get_active_quests())
	
	QuestManager.update_quest_progress(quest, 1)  # Completes since target is 1
	
	assert_false(quest in QuestManager.get_active_quests())
	assert_true(quest in QuestManager.get_completed_quests())
	assert_true(quest.completed)

func test_random_quest_generation():
	var quest1 = QuestFactory.get_random_quest(1)
	var quest2 = QuestFactory.get_random_quest(1)
	
	assert_not_null(quest1)
	assert_not_null(quest2)
	assert_true(quest1.reward_exp > 0)
	assert_true(quest2.reward_exp > 0)

func test_quest_rewards_scale_with_level():
	var quest_level1 = QuestFactory.create_quest("kill_goblins", 1)
	var quest_level5 = QuestFactory.create_quest("kill_goblins", 5)
	
	assert_gt(quest_level5.reward_exp, quest_level1.reward_exp)
	assert_gt(quest_level5.reward_gold, quest_level1.reward_gold)

func test_multiple_active_quests():
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	
	var quest1 = QuestFactory.create_quest("kill_goblins", 1)
	var quest2 = QuestFactory.create_quest("collect_herbs", 1)
	var quest3 = QuestFactory.create_quest("explore_cave", 1)
	
	QuestManager.accept_quest(quest1)
	QuestManager.accept_quest(quest2)
	QuestManager.accept_quest(quest3)
	
	assert_eq(QuestManager.get_active_quests().size(), 3)
	assert_true(quest1 in QuestManager.get_active_quests())
	assert_true(quest2 in QuestManager.get_active_quests())
	assert_true(quest3 in QuestManager.get_active_quests())

func test_quest_completion_prevents_duplicates():
	var quest = QuestFactory.create_quest("kill_goblins", 1)
	QuestManager.accept_quest(quest)
	QuestManager.accept_quest(quest)  # Try to accept again
	
	# Should still only be one
	assert_eq(QuestManager.get_active_quests().count(quest), 1)

func test_quest_list_filtering():
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	
	var quest1 = QuestFactory.create_quest("kill_goblins", 1)
	var quest2 = QuestFactory.create_quest("collect_herbs", 1)
	
	QuestManager.accept_quest(quest1)
	QuestManager.accept_quest(quest2)
	QuestManager.update_quest_progress(quest1, 5)  # Complete quest1
	
	var active = QuestManager.get_active_quests()
	var completed = QuestManager.get_completed_quests()
	
	assert_eq(active.size(), 1)
	assert_eq(completed.size(), 1)
	assert_true(quest2 in active)
	assert_true(quest1 in completed)
