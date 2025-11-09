extends GutTest

# Test Dialogue System functionality

func test_dialogue_manager_initializes():
	assert_not_null(DialogueManager)
	assert_not_null(DialogueManager.dialogue_data)
	assert_true(DialogueManager.dialogue_data.size() > 0)

func test_dialogue_npc_exists():
	assert_true(DialogueManager.dialogue_data.has("village_elder"))
	assert_true(DialogueManager.dialogue_data.has("merchant"))
	assert_true(DialogueManager.dialogue_data.has("knight_commander"))

func test_start_dialogue():
	var result = DialogueManager.start_dialogue("village_elder")
	assert_true(result)
	assert_true(DialogueManager.is_in_dialogue())

func test_dialogue_content_loaded():
	DialogueManager.start_dialogue("village_elder")
	var current_text = DialogueManager.get_current_text()
	assert_not_empty(current_text)
	assert_true(current_text.contains("adventurer"))

func test_dialogue_options_available():
	DialogueManager.start_dialogue("village_elder")
	var options = DialogueManager.get_current_options()
	assert_gt(options.size(), 0)

func test_dialogue_option_selection():
	DialogueManager.start_dialogue("village_elder")
	var initial_text = DialogueManager.get_current_text()
	
	DialogueManager.select_option(0)  # Select first option
	var new_text = DialogueManager.get_current_text()
	
	# Text should change after selecting an option
	assert_not_equal(initial_text, new_text)

func test_dialogue_end():
	DialogueManager.start_dialogue("village_elder")
	assert_true(DialogueManager.is_in_dialogue())
	
	DialogueManager.end_dialogue()
	assert_false(DialogueManager.is_in_dialogue())

func test_dialogue_branching():
	DialogueManager.start_dialogue("village_elder")
	var initial_options = DialogueManager.get_current_options().size()
	
	# First branch - ask about quests
	DialogueManager.select_option(0)
	var quests_text = DialogueManager.get_current_text()
	assert_true(quests_text.contains("goblins"))
	
	# Second branch - go back to greeting
	DialogueManager.select_option(1)
	var greeting_text = DialogueManager.get_current_text()
	assert_true(greeting_text.contains("adventurer"))

func test_quest_acceptance_from_dialogue():
	var initial_quests = QuestManager.get_active_quests().size()
	
	DialogueManager.start_dialogue("village_elder")
	DialogueManager.select_option(0)  # Ask about quests
	DialogueManager.select_option(0)  # Accept quest
	
	var new_quests = QuestManager.get_active_quests().size()
	assert_eq(new_quests, initial_quests + 1)

func test_dialogue_invalid_npc():
	var result = DialogueManager.start_dialogue("nonexistent_npc")
	assert_false(result)
	assert_false(DialogueManager.is_in_dialogue())

func test_multiple_npc_dialogues():
	DialogueManager.start_dialogue("village_elder")
	var elder_text = DialogueManager.get_current_text()
	DialogueManager.end_dialogue()
	
	DialogueManager.start_dialogue("merchant")
	var merchant_text = DialogueManager.get_current_text()
	
	assert_not_equal(elder_text, merchant_text)
	assert_true(merchant_text.contains("shop"))

func test_knight_commander_dialogue_tree():
	DialogueManager.start_dialogue("knight_commander")
	assert_true(DialogueManager.get_current_text().contains("Aldric"))
	
	# Choose "Tell me about dark threat"
	DialogueManager.select_option(0)
	assert_true(DialogueManager.get_current_text().contains("darkness"))
	
	# Accept the quest
	DialogueManager.select_option(0)
	var active_quests = QuestManager.get_active_quests()
	assert_gt(active_quests.size(), 0)
