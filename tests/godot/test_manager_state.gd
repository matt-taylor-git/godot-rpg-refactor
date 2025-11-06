extends GutTest

func test_quest_manager_initial_state():
	# Test that QuestManager starts with no active quests
	assert_eq(QuestManager.get_active_quests().size(), 0, "Should start with no active quests")
	assert_eq(QuestManager.get_completed_quests().size(), 0, "Should start with no completed quests")

func test_story_manager_initial_state():
	# Test StoryManager initial state
	assert_false(StoryManager.is_game_started(), "Game should not be started initially")

func test_codex_manager_initial_state():
	# Test CodexManager starts with no lore discovered
	assert_eq(CodexManager.get_discovered_lore().size(), 0, "Should start with no lore discovered")

func test_quest_progression():
	# Test quest acceptance and completion using QuestFactory
	var test_quest = QuestFactory.create_quest("kill_goblins", 1)

	QuestManager.accept_quest(test_quest)

	assert_eq(QuestManager.get_active_quests().size(), 1, "Should have one active quest")
	assert_true(test_quest in QuestManager.get_active_quests(), "Should have the test quest")

	# Simulate quest progress
	for i in range(5):  # Kill 5 goblins
		QuestManager.on_enemy_killed("Goblin")

	assert_true(test_quest.is_completed(), "Quest should be completed")

	QuestManager.complete_quest(test_quest)

	assert_eq(QuestManager.get_active_quests().size(), 0, "Should have no active quests after completion")
	assert_eq(QuestManager.get_completed_quests().size(), 1, "Should have one completed quest")

func test_codex_lore_discovery():
	var test_lore = {
		"id": "ancient_ruins",
		"title": "Ancient Ruins",
		"content": "These ruins hold secrets of the old world...",
		"unlock_condition": "visit_ruins"
	}

	# Initially not discovered
	assert_false(CodexManager.is_lore_discovered(test_lore["id"]), "Lore should not be discovered initially")

	# Discover lore
	CodexManager.discover_lore(test_lore["id"], test_lore)

	assert_true(CodexManager.is_lore_discovered(test_lore["id"]), "Lore should be discovered")
	assert_eq(CodexManager.get_discovered_lore().size(), 1, "Should have one discovered lore entry")

func test_story_events():
	# Test story event triggering
	assert_false(StoryManager.is_game_started(), "Game should not be started")

	StoryManager.on_game_started()

	assert_true(StoryManager.is_game_started(), "Game should be started after on_game_started")

	# Test enemy kill tracking
	StoryManager.on_enemy_killed("Goblin")
	# This should trigger some story progression - exact behavior depends on implementation

func test_manager_interactions():
	# Test that managers interact correctly - start a new game
	GameManager.new_game("TestHero")

	assert_true(StoryManager.is_game_started(), "StoryManager should know game started")

	# Start combat and defeat monster - should trigger quest and story updates
	GameManager.start_combat()
	var monster = GameManager.get_current_monster()

	# Manually defeat the monster
	monster.health = 0
	GameManager._check_combat_end()

	# QuestManager and StoryManager should be notified
	# (Exact behavior depends on implementation)
