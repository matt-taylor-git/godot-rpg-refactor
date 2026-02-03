extends Control

# CombatScene - Redesigned turn-based combat interface
# Integrates animation systems from Story 2.2

const SKILLS_DIALOG = preload("res://scenes/ui/skills_dialog.tscn")
const HERO_TEXTURE = preload("res://assets/Hero.png")
const GOBLIN_TEXTURE = preload("res://assets/goblin.png")

var skills_dialog_instance = null

# Animation Controllers - AC-2.2.2, AC-2.2.3
var animation_controller: CombatAnimationController = null
var turn_indicator: TurnIndicatorController = null
var performance_monitor: PerformanceMonitor = null

# Accessibility setting - AC-2.2.5
var reduced_motion: bool = false

@onready var player_portrait = $MainContainer/ArenaPanel/HBoxContainer/PlayerPortrait
@onready var monster_portrait = $MainContainer/ArenaPanel/HBoxContainer/MonsterPortrait

@onready var player_name_label = $MainContainer/InfoPanel/PlayerInfo/VBoxContainer/PlayerName
@onready var player_health_bar = $MainContainer/InfoPanel/PlayerInfo/VBoxContainer/PlayerHealthBar

@onready var monster_name_label = $MainContainer/InfoPanel/MonsterInfo/VBoxContainer/MonsterName
@onready var monster_health_bar = $MainContainer/InfoPanel/MonsterInfo/VBoxContainer/MonsterHealthBar

@onready var combat_log = $MainContainer/BottomPanel/CombatLogPanel/CombatLog

@onready var attack_button = $MainContainer/BottomPanel/ActionPanel/ActionButtons/AttackButton
@onready var skills_button = $MainContainer/BottomPanel/ActionPanel/ActionButtons/SkillsButton
@onready var items_button = $MainContainer/BottomPanel/ActionPanel/ActionButtons/ItemsButton
@onready var run_button = $MainContainer/BottomPanel/ActionPanel/ActionButtons/RunButton

func _ready():
	print("CombatScene ready")

	# Initialize animation systems
	_setup_animation_systems()

	# Connect to GameManager signals
	GameManager.connect("combat_started", Callable(self, "_on_combat_started"))
	GameManager.connect("player_attacked", Callable(self, "_on_player_attacked"))
	GameManager.connect("monster_attacked", Callable(self, "_on_monster_attacked"))
	GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	GameManager.connect("loot_dropped", Callable(self, "_on_loot_dropped"))
	GameManager.connect("player_leveled_up", Callable(self, "_on_player_leveled_up"))
	GameManager.connect("boss_phase_changed", Callable(self, "_on_boss_phase_changed"))
	GameManager.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	_update_ui()
	_setup_focus_navigation()

	# Start performance monitoring for combat
	if performance_monitor:
		performance_monitor.start_monitoring()

func _setup_animation_systems() -> void:
	# Check for reduced motion preference
	reduced_motion = ProjectSettings.get_setting("accessibility/reduced_motion", false)

	# Create CombatAnimationController - AC-2.2.1, AC-2.2.2
	animation_controller = CombatAnimationController.new()
	animation_controller.name = "CombatAnimationController"
	add_child(animation_controller)
	var player_image = player_portrait.get_node("PortraitPanel/PortraitImage")
	var monster_image = monster_portrait.get_node("PortraitPanel/PortraitImage")
	animation_controller.setup(player_image, monster_image, null, self)
	animation_controller.set_reduced_motion(reduced_motion)

	# Connect animation signals for logging/debugging
	animation_controller.animation_started.connect(_on_animation_started)
	animation_controller.animation_completed.connect(_on_animation_completed)
	animation_controller.damage_number_spawned.connect(_on_damage_number_spawned)

	# Create TurnIndicatorController - AC-2.2.3
	turn_indicator = TurnIndicatorController.new()
	turn_indicator.name = "TurnIndicatorController"
	add_child(turn_indicator)
	var p_image = player_portrait.get_node("PortraitPanel/PortraitImage")
	var m_image = monster_portrait.get_node("PortraitPanel/PortraitImage")
	turn_indicator.setup(p_image, m_image)
	turn_indicator.set_reduced_motion(reduced_motion)

	# Create PerformanceMonitor - AC-2.2.4
	performance_monitor = PerformanceMonitor.new()
	performance_monitor.name = "PerformanceMonitor"
	add_child(performance_monitor)

	# Connect performance signals
	performance_monitor.fps_warning.connect(_on_fps_warning)
	performance_monitor.memory_warning.connect(_on_memory_warning)

func _on_animation_started(animation_id: String) -> void:
	if performance_monitor:
		performance_monitor.start_animation_timing(animation_id)

func _on_animation_completed(animation_id: String) -> void:
	if performance_monitor:
		performance_monitor.end_animation_timing(animation_id)

func _on_damage_number_spawned(_value: int, _position: Vector2) -> void:
	# Could add additional effects here if needed
	pass

func _on_fps_warning(fps: float) -> void:
	# Log warning in debug mode
	if OS.is_debug_build():
		print("[Performance] FPS Warning: %.1f fps" % fps)

func _on_memory_warning(memory_mb: float) -> void:
	if OS.is_debug_build():
		print("[Performance] Memory Warning: %.1f MB" % memory_mb)

# Set accessibility mode - AC-2.2.5
func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if animation_controller:
		animation_controller.set_reduced_motion(enabled)
	if turn_indicator:
		turn_indicator.set_reduced_motion(enabled)
	if player_portrait:
		player_portrait.respect_reduced_motion = enabled
	if monster_portrait:
		monster_portrait.respect_reduced_motion = enabled

func _update_ui():
	_update_player_ui()
	_update_monster_ui()

func _update_player_ui():
	var player = GameManager.get_player()
	if not player:
		return
	player_name_label.text = player.name
	player_health_bar.max_value = player.max_health
	# Use animated value change for smooth health transitions
	player_health_bar.set_value_animated(player.health, true)

	# Update player portrait
	if player_portrait:
		var health_pct = (float(player.health) / float(player.max_health)) * 100.0
		player_portrait.set_character_data(player.name, _get_player_portrait_texture(player), health_pct)

		# Update status effects from player
		_update_player_status_effects(player)

func _update_monster_ui():
	var monster = GameManager.get_current_monster()
	if not monster:
		monster_name_label.text = "No Monster"
		monster_health_bar.set_value_animated(0, true)
		if monster_portrait:
			monster_portrait.visible = false
		return

	var name_text = monster.name + " (Lv." + str(monster.level) + ")"
	if GameManager.is_boss_combat():
		name_text += " [Phase " + str(monster.current_phase) + "/4]"
	monster_name_label.text = name_text

	monster_health_bar.max_value = monster.max_health
	# Use animated value change for smooth health transitions
	monster_health_bar.set_value_animated(monster.health, true)

	# Update monster portrait
	if monster_portrait:
		monster_portrait.visible = true
		var health_pct = (float(monster.health) / float(monster.max_health)) * 100.0
		monster_portrait.set_character_data(name_text, _get_monster_portrait_texture(monster), health_pct)

		# Update status effects from monster
		_update_monster_status_effects(monster)

func _append_to_log(message: String):
	if combat_log:
		combat_log.text += "\n" + message
		combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func _on_combat_started(_monster_name_param: String):
	_update_ui()
	_append_to_log("[center]Combat begins![/center]")

	# Set player as active turn - AC-2.2.3
	if turn_indicator:
		turn_indicator.highlight_player()
	if player_portrait:
		player_portrait.is_active = true
	if monster_portrait:
		monster_portrait.is_active = false

func _on_player_attacked(_damage: int, _is_critical: bool):
	_append_to_log(GameManager.get_combat_log())
	_update_ui()

	# Animation controller handles damage numbers automatically via signal connection
	# Wait for animations before monster turn - AC-2.2.2
	if animation_controller and not reduced_motion:
		await animation_controller.wait_for_animations()

	if GameManager.in_combat:
		# Switch to monster turn indicator - AC-2.2.3
		if turn_indicator:
			turn_indicator.highlight_monster()
		if player_portrait:
			player_portrait.is_active = false
		if monster_portrait:
			monster_portrait.is_active = true

		await get_tree().create_timer(0.5).timeout # Reduced from 1.0 since we wait for animations
		var monster_attack_msg = GameManager.monster_attack()
		_append_to_log(monster_attack_msg)
		_update_ui()

		# Wait for monster attack animation
		if animation_controller and not reduced_motion:
			await animation_controller.wait_for_animations()

		# Return to player turn if combat continues - AC-2.2.3
		if GameManager.in_combat and turn_indicator:
			turn_indicator.highlight_player()
		if player_portrait:
			player_portrait.is_active = true
		if monster_portrait:
			monster_portrait.is_active = false

func _on_monster_attacked(_damage: int):
	_append_to_log(GameManager.get_combat_log())
	_update_ui()
	# Animation controller handles damage numbers automatically

func _on_combat_ended(player_won: bool):
	# Stop performance monitoring
	if performance_monitor:
		performance_monitor.stop_monitoring()

	var message = ""
	if player_won:
		message = "[color=green]Victory! You defeated the monster![/color]"
		if GameManager.is_boss_combat():
			_append_to_log(message)
			if is_inside_tree():
				await get_tree().create_timer(2.0).timeout
			GameManager.trigger_victory()
			GameManager.change_scene("victory_scene")
		else:
			_append_to_log(message)
			if is_inside_tree():
				await get_tree().create_timer(2.0).timeout
			_change_to_exploration()
	else:
		message = "[color=red]Defeat! You were defeated...[/color]"
		_append_to_log(message)
		if is_inside_tree():
			await get_tree().create_timer(2.0).timeout
		GameManager.change_scene("game_over_scene")

func _on_loot_dropped(item_name: String):
	_append_to_log("[color=yellow]You found: " + item_name + "[/color]")

func _on_player_leveled_up(new_level: int):
	_append_to_log("[color=blue]Level up! You are now level " + str(new_level) + "![/color]")
	_update_ui()

func _on_boss_phase_changed(_phase: int, description: String):
	_append_to_log("[color=red]" + description + "[/color]")
	_update_ui()

func _on_boss_defeated():
	_append_to_log("[color=gold]THE DARK OVERLORD HAS BEEN DEFEATED![/color]")

func _setup_focus_navigation():
	# 2x2 grid: Attack | Skills
	#            Items  | Run
	# Row 1
	attack_button.set("focus_neighbor_right", skills_button.get_path())
	attack_button.set("focus_neighbor_left", skills_button.get_path())
	attack_button.set("focus_neighbor_bottom", items_button.get_path())
	attack_button.set("focus_neighbor_top", items_button.get_path())

	skills_button.set("focus_neighbor_left", attack_button.get_path())
	skills_button.set("focus_neighbor_right", attack_button.get_path())
	skills_button.set("focus_neighbor_bottom", run_button.get_path())
	skills_button.set("focus_neighbor_top", run_button.get_path())

	# Row 2
	items_button.set("focus_neighbor_right", run_button.get_path())
	items_button.set("focus_neighbor_left", run_button.get_path())
	items_button.set("focus_neighbor_top", attack_button.get_path())
	items_button.set("focus_neighbor_bottom", attack_button.get_path())

	run_button.set("focus_neighbor_left", items_button.get_path())
	run_button.set("focus_neighbor_right", items_button.get_path())
	run_button.set("focus_neighbor_top", skills_button.get_path())
	run_button.set("focus_neighbor_bottom", skills_button.get_path())

	attack_button.grab_focus()

func _on_attack_pressed():
	if not GameManager.in_combat: return
	var result = GameManager.player_attack()
	_append_to_log(result)
	_update_ui()

func _on_skills_pressed():
	if not GameManager.in_combat or not GameManager.get_player(): return
	var player = GameManager.get_player()
	if player.skills.size() == 0:
		_append_to_log("You have no skills to use!")
		return
	if skills_dialog_instance == null:
		skills_dialog_instance = SKILLS_DIALOG.instantiate()
		add_child(skills_dialog_instance)
		skills_dialog_instance.connect("skill_selected", Callable(self, "_on_skill_selected"))
		skills_dialog_instance.connect("cancelled", Callable(self, "_on_skills_cancelled"))
		skills_dialog_instance.tree_exited.connect(func(): attack_button.grab_focus())

func _on_items_pressed():
	if not GameManager.in_combat: return
	_append_to_log("Items not implemented yet")

func _on_run_pressed():
	if not GameManager.in_combat: return
	if randf() < 0.5:
		GameManager.end_combat()
		_append_to_log("You successfully ran away!")
		await get_tree().create_timer(1.0).timeout
		_change_to_exploration()
	else:
		_append_to_log("Failed to run away!")
		await get_tree().create_timer(1.0).timeout
		var monster_attack_msg = GameManager.monster_attack()
		_append_to_log(monster_attack_msg)
		_update_ui()

func _change_to_exploration():
	GameManager.change_scene("exploration_scene")

func _on_skill_selected(skill_index: int):
	# Get skill info for animation
	var player = GameManager.get_player()
	var skill_name = ""
	if player and skill_index >= 0 and skill_index < player.skills.size():
		skill_name = player.skills[skill_index].name

	# Play spell cast animation before using skill - AC-2.2.2
	if animation_controller and not reduced_motion and skill_name != "":
		var p_img = player_portrait.get_node("PortraitPanel/PortraitImage")
		var m_img = monster_portrait.get_node("PortraitPanel/PortraitImage")
		await animation_controller.play_spell_cast(p_img, m_img, skill_name)

	var result = GameManager.player_use_skill(skill_index)
	_append_to_log(result)
	_update_ui()
	skills_dialog_instance = null

	# Handle monster turn after skill
	if GameManager.in_combat:
		if turn_indicator:
			turn_indicator.highlight_monster()
		if player_portrait:
			player_portrait.is_active = false
		if monster_portrait:
			monster_portrait.is_active = true

		await get_tree().create_timer(0.5).timeout
		var monster_attack_msg = GameManager.monster_attack()
		_append_to_log(monster_attack_msg)
		_update_ui()

		if animation_controller and not reduced_motion:
			await animation_controller.wait_for_animations()

		if GameManager.in_combat and turn_indicator:
			turn_indicator.highlight_player()
		if player_portrait:
			player_portrait.is_active = true
		if monster_portrait:
			monster_portrait.is_active = false

func _on_skills_cancelled():
	skills_dialog_instance = null

func _get_player_portrait_texture(player) -> Texture2D:
	# Get portrait texture based on player class
	match player.character_class:
		"Warrior":
			return load("res://assets/warrior.png")
		"Mage":
			return load("res://assets/mage.png")
		"Rogue":
			return load("res://assets/rogue.png")
		"Hero":
			return HERO_TEXTURE
		_:
			return HERO_TEXTURE  # Default fallback

func _get_monster_portrait_texture(monster) -> Texture2D:
	# Get portrait texture based on monster type using dictionary lookup
	var monster_textures := {
		"goblin": "res://assets/goblin.png",
		"orc": "res://assets/orc.png",
		"skeleton": "res://assets/skeleton.png",
		"slime": "res://assets/slime.png",
		"spider": "res://assets/spider.png",
		"wolf": "res://assets/wolf.png",
		"golem": "res://assets/golem.png",
		"bandit": "res://assets/bandit.png",
		"boss": "res://assets/boss.png",
		"final boss": "res://assets/final_boss.png",
	}
	var key = monster.name.to_lower()
	if monster_textures.has(key):
		return load(monster_textures[key])
	return GOBLIN_TEXTURE  # Default fallback

func _update_player_status_effects(_player):
	# Update player status effects on portrait
	if not player_portrait:
		return

	# Clear existing status effects
	player_portrait.clear_status_effects()

	# Add current status effects (if player has status effects system)
	# This would need to be implemented in Player class
	# For now, we'll skip as status effects aren't fully implemented yet

func _update_monster_status_effects(_monster):
	# Update monster status effects on portrait
	if not monster_portrait:
		return

	# Clear existing status effects
	monster_portrait.clear_status_effects()

	# Add current status effects (if monster has status effects system)
	# This would need to be implemented in Monster class
	# For now, we'll skip as status effects aren't fully implemented yet

func _exit_tree() -> void:
	# Cleanup animation systems
	if performance_monitor:
		performance_monitor.stop_monitoring()
