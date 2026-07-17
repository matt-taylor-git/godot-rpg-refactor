extends GutTest

# Tests shipped GameManager scene aliases and ExplorationManager travel/hub helpers.

const LOAD_TEST_SLOT := 97
const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")


func test_scene_aliases_resolve_to_exploration_hub():
	assert_eq(
		GameManager.resolve_scene_name("town_scene"),
		"exploration_scene",
		"town_scene must alias to exploration hub"
	)
	assert_eq(
		GameManager.resolve_scene_name("world_map"),
		"exploration_scene",
		"world_map must alias to exploration hub"
	)
	assert_eq(
		GameManager.resolve_scene_name("exploration_scene"),
		"exploration_scene",
		"exploration_scene should pass through"
	)
	assert_eq(
		GameManager.resolve_scene_name("combat_scene"),
		"combat_scene",
		"unrelated scenes must not be aliased"
	)


func test_hub_scene_file_exists():
	assert_true(
		ResourceLoader.exists("res://scenes/ui/exploration_scene.tscn"),
		"exploration hub scene must exist"
	)


func test_travel_status_same_area_blocked():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	var status = mgr.get_travel_status("town", "town", 10)
	assert_false(status.can_travel, "cannot travel to current area")
	assert_eq(status.reason, "same_area")


func test_travel_status_connected_and_level_ok():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	# town connects to forest at level 1
	var status = mgr.get_travel_status("town", "forest", 1)
	assert_true(status.can_travel, "town -> forest at level 1 should work")
	assert_true(status.connected)
	assert_true(status.level_met)


func test_travel_status_level_gate_blocks_peak():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	# mountain connects to peak requiring level 8
	var status = mgr.get_travel_status("mountain", "peak", 3)
	assert_false(status.can_travel, "peak requires level 8")
	assert_true(status.connected, "peak is connected from mountain")
	assert_false(status.level_met)
	assert_eq(status.req_level, 8)
	assert_eq(status.reason, "level")


func test_travel_status_not_connected():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	# town is not directly connected to peak
	var status = mgr.get_travel_status("town", "peak", 99)
	assert_false(status.can_travel)
	assert_false(status.connected)
	assert_eq(status.reason, "not_connected")


func test_travel_status_peak_allowed_at_level_8():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	var status = mgr.get_travel_status("mountain", "peak", 8)
	assert_true(status.can_travel)


func test_explore_and_shop_visibility_helpers():
	assert_false(ExplorationManager.is_explore_enabled("town"))
	assert_true(ExplorationManager.is_explore_enabled("forest"))
	assert_true(ExplorationManager.is_shop_visible("town"))
	assert_false(ExplorationManager.is_shop_visible("forest"))


func test_area_data_has_map_pos_and_image_paths():
	var mgr = ExplorationManager.new()
	add_child_autofree(mgr)
	for area_id in ["town", "forest", "mountain", "cave", "peak"]:
		var info = mgr.get_area_info(area_id)
		assert_true(info.has("map_pos"), "%s needs map_pos" % area_id)
		assert_true(info.has("image"), "%s needs image path" % area_id)
		var img: String = info.image
		assert_true(img.begins_with("res://assets/locations/"), "%s image path" % area_id)
		assert_true(ResourceLoader.exists(img) or FileAccess.file_exists(img),
			"location art should exist for %s: %s" % [area_id, img])


func test_world_map_texture_path_exists():
	assert_true(
		ResourceLoader.exists(ExplorationManager.WORLD_MAP_TEXTURE)
		or FileAccess.file_exists(ExplorationManager.WORLD_MAP_TEXTURE),
		"world map texture must exist at %s" % ExplorationManager.WORLD_MAP_TEXTURE
	)


func test_fullbody_class_textures_exist():
	for class_name_key in ["Warrior", "Mage", "Rogue", "Hero"]:
		var tex = PortraitLookup.get_class_texture(class_name_key)
		assert_not_null(tex, "full-body texture for %s" % class_name_key)


func test_hub_scene_has_expected_structure():
	var scene: PackedScene = load("res://scenes/ui/exploration_scene.tscn")
	assert_not_null(scene)
	var hub = scene.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame

	assert_not_null(
		hub.get_node_or_null("Hub/LeftColumn/HudPanel/LeftMargin/LeftVBox/CharacterPortrait")
	)
	assert_not_null(
		hub.get_node_or_null("Hub/LeftColumn/HudPanel/LeftMargin/LeftVBox/NameLevelRow/NameBanner")
	)
	assert_not_null(hub.get_node_or_null("Hub/LeftColumn/HudPanel/LeftMargin/LeftVBox/HpBar"))
	assert_not_null(hub.get_node_or_null("Hub/LeftColumn/HudPanel/LeftMargin/LeftVBox/StatusChip"))
	assert_not_null(hub.get_node_or_null("Hub/CenterColumn/MapPanel/MapInner/MarkersLayer"))
	assert_null(hub.get_node_or_null("Hub/CenterColumn/MapFooter"))
	assert_not_null(
		hub.get_node_or_null(
			"Hub/RightColumn/LocationCard/LocationCardMargin/LocationCardVBox/LocationArt"
		)
	)
	assert_not_null(
		hub.get_node_or_null(
			"Hub/RightColumn/LocationCard/LocationCardMargin/LocationCardVBox/LocationName"
		)
	)
	assert_not_null(
		hub.get_node_or_null(
			"Hub/RightColumn/LocationCard/LocationCardMargin/LocationCardVBox/LocationDescription"
		)
	)
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/PrimaryAction"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/SecondaryActions/ExploreButton"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/SecondaryActions/TravelButton"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/SecondaryActions/ShopButton"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/NarrativePanel/NarrativeLog"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/ContextActions"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/UtilityBar/InventoryButton"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/UtilityBar/QuestLogButton"))
	assert_not_null(hub.get_node_or_null("Hub/RightColumn/UtilityBar/MenuButton"))
	# No quest list UI on hub
	assert_null(hub.get_node_or_null("QuestList"))
	assert_null(hub.get_node_or_null("Hub/QuestList"))

	# Column proportions for hierarchy redesign
	var left_col: Control = hub.get_node("Hub/LeftColumn")
	var right_col: Control = hub.get_node("Hub/RightColumn")
	assert_eq(int(left_col.custom_minimum_size.x), 260, "left column ~260px")
	assert_eq(int(right_col.custom_minimum_size.x), 340, "right column ~340px")


func test_load_game_returns_true_on_success():
	GameManager.new_game("LoadHero", "Warrior")
	GameManager.in_combat = false
	assert_true(GameManager.save_game(LOAD_TEST_SLOT), "save must succeed for load test")

	GameManager.game_data.player = null
	GameManager.in_combat = false
	var ok = GameManager.load_game(LOAD_TEST_SLOT)
	assert_true(ok, "load_game must return true when save file loads")
	assert_not_null(GameManager.get_player(), "player restored after load")
	assert_eq(GameManager.get_player().name, "LoadHero")


func test_load_game_returns_false_on_missing_slot():
	var ok = GameManager.load_game(98)
	assert_false(ok, "missing slot must return false")


func test_main_menu_load_routes_to_hub_when_not_in_combat():
	# Real MainMenu success branch: load_game truthy → change_scene(exploration_scene)
	GameManager.new_game("HubLoad", "Mage")
	GameManager.in_combat = false
	assert_true(GameManager.save_game(LOAD_TEST_SLOT), "need a real save file")

	GameManager.game_data.player = null
	GameManager.in_combat = false
	GameManager.current_scene = "main_menu"

	var menu = MainMenuScene.instantiate()
	add_child_autofree(menu)
	await get_tree().process_frame

	menu._on_save_slot_selected(LOAD_TEST_SLOT)
	# change_scene is async when SceneTransition is present
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	assert_not_null(GameManager.get_player(), "load must restore player")
	assert_eq(
		GameManager.current_scene,
		"exploration_scene",
		"MainMenu load success must land on exploration hub"
	)
	assert_false(GameManager.in_combat)


func test_main_menu_load_routes_to_combat_when_in_combat():
	GameManager.new_game("CombatLoad", "Warrior")
	GameManager.in_combat = true
	GameManager.current_monster = MonsterFactory.create_monster("goblin", 1)
	assert_true(GameManager.save_game(LOAD_TEST_SLOT), "save mid-combat")

	GameManager.game_data.player = null
	GameManager.in_combat = false
	GameManager.current_monster = null
	GameManager.current_scene = "main_menu"

	var menu = MainMenuScene.instantiate()
	add_child_autofree(menu)
	await get_tree().process_frame

	menu._on_save_slot_selected(LOAD_TEST_SLOT)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	assert_true(GameManager.in_combat, "combat flag restored from save")
	assert_eq(
		GameManager.current_scene,
		"combat_scene",
		"MainMenu load in combat must open combat_scene"
	)
