extends GutTest

# Visual polish: skills, equip ATK, rarity, dialog shell, button hover hooks


func test_class_skills_have_real_names():
	for class_key in ["Warrior", "Mage", "Rogue", "Hero"]:
		var skills = SkillFactory.get_class_skills(class_key)
		assert_gt(skills.size(), 0, "%s should have skills" % class_key)
		for skill in skills:
			assert_ne(
				skill.name,
				"Unknown Skill",
				"%s skill list must not contain Unknown Skill (got skill type gap)" % class_key
			)
			assert_false(skill.name.is_empty(), "Skill name should not be empty")


func test_equip_attack_not_double_counted():
	var player = Player.new()
	player.attack = 10
	player.defense = 5
	var sword = ItemFactory.create_item("sword")
	assert_eq(sword.attack_bonus, 5, "Iron Sword attack_bonus should be 5")
	var base = player.attack
	assert_true(player.equip_item(sword, "weapon"), "equip should succeed")
	# Base attack must stay unchanged (bonuses only via get_attack_power)
	assert_eq(player.attack, base, "equip must not mutate base attack")
	assert_eq(
		player.get_attack_power(),
		base + sword.attack_bonus,
		"get_attack_power should be base + weapon bonus once"
	)
	# Unequip restores
	var removed = player.unequip_item("weapon")
	assert_not_null(removed, "should return unequipped item")
	assert_eq(player.get_attack_power(), base, "power after unequip is base only")


func test_item_rarity_border_colors():
	var common = ItemFactory.create_item("sword")
	assert_eq(common.rarity, Item.Rarity.COMMON)
	var uncommon = ItemFactory.create_item("health_potion")
	assert_eq(uncommon.rarity, Item.Rarity.UNCOMMON)
	var c_color = common.get_rarity_border_color()
	var u_color = uncommon.get_rarity_border_color()
	assert_ne(c_color, u_color, "common and uncommon borders should differ")
	assert_eq(
		Item.rarity_border_color(Item.Rarity.LEGENDARY),
		Color(0.85, 0.70, 0.35, 1.0),
		"legendary uses gold"
	)


func test_ui_dialog_shell_panel_style_opaque():
	var style = UIDialogShell.create_panel_stylebox()
	assert_not_null(style)
	assert_gte(style.bg_color.a, 0.9, "panel background should be opaque enough")
	assert_eq(style.get_border_width(SIDE_LEFT), 2)


func test_ui_dialog_shell_reduced_motion_open_leaves_visible():
	var root = Control.new()
	add_child_autofree(root)
	var panel = PanelContainer.new()
	panel.name = "DialogPanel"
	root.add_child(panel)
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	UIDialogShell.play_open(root, panel, UIDialogShell.AnimStyle.SLIDE)
	assert_eq(panel.modulate.a, 1.0, "reduced motion must not leave panel invisible")
	assert_eq(panel.scale, Vector2.ONE)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)


func test_ui_button_hover_triggers_without_error():
	var button = UIButton.new()
	button.text = "HoverMe"
	add_child_autofree(button)
	await get_tree().process_frame
	button._on_mouse_entered()
	assert_true(button.is_hovered)
	button._on_button_down()
	assert_true(button.is_pressed)
	button._on_button_up()
	button._on_mouse_exited()
	assert_false(button.is_hovered)


func test_animation_system_accent_is_theme_gold():
	var anim = UIAnimationSystem.new()
	add_child_autofree(anim)
	await get_tree().process_frame
	var theme_accent = UIThemeManager.get_accent_color()
	assert_eq(
		anim.accent_color,
		theme_accent,
		"UIAnimationSystem accent should match theme gold, not teal"
	)


func test_world_map_background_is_themed_not_shader_washed():
	var scene: PackedScene = load("res://scenes/ui/world_map.tscn")
	assert_not_null(scene, "world_map.tscn should load")
	var map = scene.instantiate()
	add_child_autofree(map)
	await get_tree().process_frame
	var bg = map.get_node_or_null("Background")
	assert_not_null(bg, "Background node required")
	assert_null(bg.material, "world map must not use washout shader material")
	var style = bg.get_theme_stylebox("panel")
	assert_not_null(style, "Background should have panel stylebox after _ready")
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		assert_lt(flat.bg_color.r, 0.28, "bg red channel should be dark charcoal, not mid-gray")
		assert_lt(flat.bg_color.g, 0.26, "bg green channel should be dark charcoal")
		assert_lt(flat.bg_color.b, 0.24, "bg blue channel should be dark charcoal")
		assert_eq(flat.bg_color.a, 1.0)


func test_game_over_background_is_themed_not_shader_washed():
	var scene: PackedScene = load("res://scenes/ui/game_over_scene.tscn")
	assert_not_null(scene, "game_over_scene.tscn should load")
	var go = scene.instantiate()
	add_child_autofree(go)
	await get_tree().process_frame
	var bg = go.get_node_or_null("Background")
	assert_not_null(bg, "Background node required")
	assert_null(bg.material, "game over must not use washout shader material")
	var style = bg.get_theme_stylebox("panel")
	assert_not_null(style, "Background should have panel stylebox after _ready")
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		assert_lt(flat.bg_color.r, 0.28, "defeat bg should be dark charcoal")
		assert_lt(flat.bg_color.g, 0.24, "defeat bg green low for cool/red undertone")
		assert_lt(flat.bg_color.b, 0.24, "defeat bg should be dark")
		assert_eq(
			flat.border_color,
			UIThemeManager.get_danger_color(),
			"game over should use danger border"
		)
