extends GutTest

# Mana / MP system: init, spend, potions, save migration


func test_new_game_mage_has_mana_pool():
	GameManager.new_game("TestMage", "Mage")
	var player = GameManager.get_player()
	assert_not_null(player, "Player should exist")
	assert_eq(player.max_mana, 50, "Mage max_mana should be 50")
	assert_eq(player.mana, 50, "Mage should start at full mana")


func test_new_game_classes_have_positive_mana():
	for char_class in ["Hero", "Warrior", "Mage", "Rogue"]:
		GameManager.new_game("Tester", char_class)
		var player = GameManager.get_player()
		assert_gt(player.max_mana, 0, "%s should have max_mana > 0" % char_class)
		assert_eq(player.mana, player.max_mana, "%s should start full mana" % char_class)


func test_skill_fails_without_mana():
	GameManager.new_game("TestMage", "Mage")
	var player = GameManager.get_player()
	player.mana = 0
	var skill = SkillFactory.create_skill("fireball")
	assert_false(skill.can_use(player), "Fireball should fail with 0 mana")
	var result = skill.use(player, null)
	assert_false(result.success, "use should fail when can_use fails")
	assert_eq(player.mana, 0, "Mana should stay 0 on failed use")


func test_skill_spends_mana_on_success():
	GameManager.new_game("TestMage", "Mage")
	var player = GameManager.get_player()
	player.level = 3  # Fireball requires level 3
	var monster = MonsterFactory.create_monster("goblin", 1)
	var skill = SkillFactory.create_skill("fireball")
	var cost = skill.mana_cost
	assert_gt(cost, 0, "Fireball should cost mana")
	player.mana = cost + 5
	assert_true(skill.can_use(player), "Should be usable with enough mana")
	var result = skill.use(player, monster)
	assert_true(result.success, "Skill should succeed")
	assert_eq(player.mana, 5, "Mana should decrease by mana_cost")


func test_mana_potion_restores_mana():
	GameManager.new_game("TestMage", "Mage")
	var player = GameManager.get_player()
	player.mana = 10
	var potion = ItemFactory.create_item("mana_potion")
	assert_eq(potion.effect, "restore_mana")
	assert_eq(potion.restore_percent, 0.40)
	assert_true(potion.use(player), "Potion use should succeed")
	assert_eq(player.mana, 30, "Should restore 40% max MP (10 + 20)")
	assert_eq(potion.quantity, 0, "Quantity should decrement")


func test_mana_potion_caps_at_max():
	GameManager.new_game("TestMage", "Mage")
	var player = GameManager.get_player()
	player.mana = player.max_mana - 5
	var potion = ItemFactory.create_item("mana_potion")
	potion.use(player)
	assert_eq(player.mana, player.max_mana, "Mana restore should cap at max_mana")


func test_health_potion_still_heals_hp():
	GameManager.new_game("Tester", "Hero")
	var player = GameManager.get_player()
	player.health = 20
	var potion = ItemFactory.create_item("health_potion")
	assert_true(potion.use(player))
	assert_eq(player.health, 55, "Health potion should restore 35% max HP")


func test_level_up_increases_max_mana():
	GameManager.new_game("Tester", "Hero")
	var player = GameManager.get_player()
	var start_max = player.max_mana
	player.mana = 1
	var exp_needed = player.get_exp_for_level(player.level + 1)
	player.add_experience(exp_needed)
	assert_eq(player.level, 2)
	assert_eq(player.max_mana, start_max + 5, "Level up should add 5 max mana")
	assert_eq(player.mana, player.max_mana, "Level up should refill mana")


func test_save_dict_roundtrip_preserves_mana():
	GameManager.new_game("Tester", "Mage")
	var player = GameManager.get_player()
	player.mana = 17
	var data = player.to_dict()
	var loaded = Player.new()
	loaded.from_dict(data)
	assert_eq(loaded.mana, 17)
	assert_eq(loaded.max_mana, 50)


func test_old_save_zero_mana_migrates():
	var loaded = Player.new()
	loaded.from_dict({
		"name": "OldSave",
		"character_class": "Mage",
		"level": 3,
		"mana": 0,
		"max_mana": 0,
		"health": 100,
		"max_health": 100,
	})
	assert_eq(loaded.max_mana, 50, "Old saves should get class base max_mana")
	assert_eq(loaded.mana, 50, "Migrated mana should fill to max")


func test_restore_and_spend_helpers():
	var player = Player.new()
	player.max_mana = 20
	player.mana = 5
	player.restore_mana(10)
	assert_eq(player.mana, 15)
	assert_true(player.spend_mana(7))
	assert_eq(player.mana, 8)
	assert_false(player.spend_mana(100))
	assert_eq(player.mana, 8, "Failed spend should not change mana")


func test_rogue_starting_skills_usable_at_level_1():
	GameManager.new_game("TestRogue", "Rogue")
	var player = GameManager.get_player()
	assert_eq(player.level, 1)
	assert_eq(player.skills.size(), 2)
	for i in range(player.skills.size()):
		var skill = player.skills[i]
		assert_true(skill.can_use(player), "%s should be usable at level 1" % skill.name)
		assert_true(GameManager.can_use_skill(i), "can_use_skill(%d) for %s" % [i, skill.name])


func test_skill_cooldown_blocks_then_ticks():
	GameManager.new_game("TestRogue", "Rogue")
	var player = GameManager.get_player()
	var skill = player.skills[0]
	var monster = MonsterFactory.create_monster("goblin", 1)
	assert_true(skill.use(player, monster).success)
	assert_gt(skill.current_cooldown, 0)
	assert_false(skill.can_use(player), "On cooldown should block use")
	GameManager.tick_skill_cooldowns()
	assert_eq(skill.current_cooldown, skill.cooldown - 1)


func test_stealth_buff_raises_defense():
	GameManager.new_game("TestRogue", "Rogue")
	var player = GameManager.get_player()
	var base_def = player.get_defense_power()
	var stealth = SkillFactory.create_skill("stealth")
	var result = stealth.use(player, null)
	assert_true(result.success)
	assert_true(player.has_status_effect("stealth"))
	assert_eq(player.get_defense_power(), base_def + 20)
