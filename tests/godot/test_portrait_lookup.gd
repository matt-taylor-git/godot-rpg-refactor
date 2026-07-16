extends GutTest

# Tests for PortraitLookup texture resolution


func test_class_textures_resolve():
	for class_name_key in ["Hero", "Warrior", "Mage", "Rogue"]:
		var tex = PortraitLookup.get_class_texture(class_name_key)
		assert_not_null(tex, "Class texture should resolve for " + class_name_key)


func test_unknown_class_falls_back():
	var tex = PortraitLookup.get_class_texture("UnknownClass")
	assert_not_null(tex, "Unknown class should fall back to default player texture")


func test_monster_textures_resolve():
	for monster in ["goblin", "orc", "slime", "final boss"]:
		var tex = PortraitLookup.get_monster_texture(monster)
		assert_not_null(tex, "Monster texture should resolve for " + monster)


func test_npc_textures_resolve():
	var tex = PortraitLookup.get_npc_texture("quest_giver")
	assert_not_null(tex, "Quest giver NPC texture should resolve")


func test_player_texture_from_object():
	var player = Player.new()
	player.character_class = "Mage"
	var tex = PortraitLookup.get_player_texture(player)
	assert_not_null(tex, "Player texture should resolve from character_class")
