extends GutTest

const MainMenuScript = preload("res://scripts/ui/MainMenu.gd")
const CharacterCreationScript = preload("res://scripts/ui/CharacterCreation.gd")
const CombatSceneScript = preload("res://scripts/ui/CombatScene.gd")
const ExplorationSceneScript = preload("res://scripts/ui/ExplorationScene.gd")

func test_main_menu_new_game_flow():
	var main_menu = MainMenuScript.new()
	main_menu._on_new_game_pressed()
	assert_eq(GameManager.current_scene, "character_creation", "Should change to character creation scene")

func test_character_creation_start_game_flow():
	var char_creation = CharacterCreationScript.new()
	char_creation.character_name = "Test"
	char_creation.selected_class = "Hero"
	char_creation._on_start_game_pressed()
	assert_eq(GameManager.current_scene, "exploration_scene", "Should change to exploration scene")

func test_load_game_in_combat_flow():
	gut.get_stubber().stub(GameManager, "load_game").to_return(true)
	GameManager.in_combat = true
	var main_menu = MainMenuScript.new()
	main_menu._on_save_slot_selected(1)
	assert_eq(GameManager.current_scene, "combat_scene", "Should route to combat scene when in combat")

func test_load_game_not_in_combat_flow():
	gut.get_stubber().stub(GameManager, "load_game").to_return(true)
	GameManager.in_combat = false
	var main_menu = MainMenuScript.new()
	main_menu._on_save_slot_selected(1)
	assert_eq(GameManager.current_scene, "town_scene", "Should route to town scene when not in combat")

func test_combat_victory_non_boss_flow():
	var combat_scene = CombatSceneScript.new()
	combat_scene._on_combat_ended(true)
	assert_eq(GameManager.current_scene, "exploration_scene", "Should change to exploration scene after non-boss victory")

func test_combat_defeat_flow():
	var combat_scene = CombatSceneScript.new()
	combat_scene._on_combat_ended(false)
	assert_eq(GameManager.current_scene, "game_over_scene", "Should change to game over scene after defeat")

func test_exploration_menu_flow():
	var exploration_scene = ExplorationSceneScript.new()
	exploration_scene._on_menu_pressed()
	assert_eq(GameManager.current_scene, "main_menu", "Should change to main menu from exploration")

func test_game_manager_change_scene_error_handling():
	# Test error handling for invalid scene names
	var original_scene = GameManager.current_scene
	GameManager.change_scene("invalid_scene_name")
	assert_eq(GameManager.current_scene, original_scene, "Should not change scene for invalid name")