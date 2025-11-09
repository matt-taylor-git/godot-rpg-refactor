extends Node

# GameManager - Global game state and scene management
# Autoload singleton for managing overall game state

signal game_started
signal game_loaded
signal scene_changed(scene_name)

# Combat signals
signal combat_started(monster_name: String)
signal combat_ended(player_won: bool)
signal player_attacked(damage: int, is_critical: bool)
signal monster_attacked(damage: int)
signal player_leveled_up(new_level: int)
signal loot_dropped(item_name: String)

# Boss-specific signals
signal boss_phase_changed(phase: int, description: String)
signal boss_defeated()

var current_scene: String = ""
var game_data = {}

# Combat state
var current_monster: Monster = null
var in_combat: bool = false
var combat_log: String = ""
var game_start_time: float = 0.0

func _ready():
	print("GameManager initialized")
	game_start_time = Time.get_unix_time_from_system()

	# Connect to manager signals
	_connect_manager_signals()

	# Initialize basic game state
	game_data = {
		"player": null,
		"current_scene": "main_menu",
		"save_slots": {},
		"combat_state": {
			"current_monster": null,
			"in_combat": false,
			"combat_log": ""
		}
	}

func _connect_manager_signals():
	# Connect QuestManager signals
	QuestManager.connect("quest_accepted", Callable(StoryManager, "on_quest_started"))
	QuestManager.connect("quest_completed", Callable(StoryManager, "on_quest_completed"))
	QuestManager.connect("quest_completed", Callable(CodexManager, "on_quest_completed"))

	# Connect combat-related signals to managers
	connect("player_leveled_up", Callable(QuestManager, "on_level_up"))
	connect("player_leveled_up", Callable(CodexManager, "on_level_up"))

	# Connect enemy kill signals
	connect("combat_ended", Callable(_forward_combat_signals_to_managers))

func _forward_combat_signals_to_managers(player_won: bool):
	if current_monster:
		QuestManager.on_combat_end(current_monster.name)
		StoryManager.on_enemy_killed(current_monster.name)
		CodexManager.on_enemy_killed(current_monster.name)

func new_game(player_name: String, character_class: String = "Hero"):
	print("Starting new game for ", player_name, " as ", character_class)

	# Create player
	game_data.player = Player.new()
	game_data.player.name = player_name
	game_data.player.character_class = character_class

	# Set base stats based on class
	match character_class:
		"Hero":
			game_data.player.attack = 12
			game_data.player.defense = 6
			game_data.player.dexterity = 6
		"Warrior":
			game_data.player.attack = 15
			game_data.player.defense = 8
			game_data.player.dexterity = 4
		"Mage":
			game_data.player.attack = 8
			game_data.player.defense = 4
			game_data.player.dexterity = 5
		"Rogue":
			game_data.player.attack = 10
			game_data.player.defense = 5
			game_data.player.dexterity = 8
		_:
			game_data.player.attack = 10
			game_data.player.defense = 5
			game_data.player.dexterity = 5

	# Set health
	game_data.player.max_health = 100
	game_data.player.health = game_data.player.max_health

	# Give starting skills
	var starting_skills = SkillFactory.get_class_skills(character_class)
	for skill in starting_skills:
		game_data.player.skills.append(skill)

	# Reset combat state
	current_monster = null
	in_combat = false
	combat_log = ""

	# Reset game start time for playtime tracking
	game_start_time = Time.get_unix_time_from_system()

	game_data.current_scene = "exploration"
	game_data.exploration_state = {
	"steps_taken": 0,
	"encounter_chance": 2.0,
	"steps_since_last_encounter": 0
	}
	emit_signal("game_started")

	# Trigger initial story event
	StoryManager.on_game_started()

func start_new_game():
	print("Starting new game")
	game_data.player = null  # Will be set during character creation
	game_data.current_scene = "character_creation"
	emit_signal("game_started")

func load_game(save_slot: int):
	print("Loading game from slot ", save_slot)
	var loaded_data = _load_from_file(save_slot)
	if loaded_data:
		game_data.player = Player.new()
		game_data.player.from_dict(loaded_data.player)
		game_data.current_scene = loaded_data.get("current_scene", "main_menu")
		game_data.exploration_state = loaded_data.get("exploration_state", {
			"steps_taken": 0,
			"encounter_chance": 2.0,
			"steps_since_last_encounter": 0
		})

		# Restore combat state
		var combat_state = loaded_data.get("combat_state", {})
		if combat_state.get("current_monster"):
			current_monster = Monster.new()
			current_monster.from_dict(combat_state.current_monster)
		else:
			current_monster = null

		in_combat = combat_state.get("in_combat", false)
		combat_log = combat_state.get("combat_log", "")

		game_start_time = loaded_data.get("game_start_time", Time.get_unix_time_from_system())

		emit_signal("game_loaded")
	else:
		print("Failed to load save slot ", save_slot)

func _load_from_file(save_slot: int) -> Variant:
	var save_path = "user://save_slot_%d.json" % save_slot
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				return json.data
			else:
				print("JSON parse error: ", json.get_error_message())
		else:
			print("Failed to open save file")
	else:
		print("Save file does not exist")
	return null

func save_game(save_slot: int):
	print("Saving game to slot ", save_slot)
	if game_data.player:
		game_data.save_slots[save_slot] = {
			"player": game_data.player.to_dict(),
			"current_scene": game_data.current_scene,
			"exploration_state": game_data.get("exploration_state", {}),
			"combat_state": {
				"current_monster": current_monster.to_dict() if current_monster else null,
				"in_combat": in_combat,
				"combat_log": combat_log
			},
			"game_start_time": game_start_time
		}
		_save_to_file(save_slot)
	else:
		print("No player data to save")

func _save_to_file(save_slot: int):
	var save_path = "user://save_slot_%d.json" % save_slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data.save_slots[save_slot])
		file.store_string(json_string)
		file.close()
		print("Game saved to ", save_path)
	else:
		print("Failed to save game")

func change_scene(scene_name: String):
	print("Changing scene to: ", scene_name)
	current_scene = scene_name
	emit_signal("scene_changed", scene_name)
	# TODO: Implement actual scene switching logic

func get_current_scene() -> String:
	return current_scene

func is_game_active() -> bool:
	return game_data.player != null

# Combat System
func start_combat():
	if not game_data.player:
		return "No player data"

	# Create a random monster based on player level
	current_monster = MonsterFactory.create_monster(
		MonsterFactory.get_random_monster_type(),
		game_data.player.level
	)

	in_combat = true
	combat_log = "Combat started! A " + current_monster.name + " (Level " + str(current_monster.level) + ") appears!"

	game_data.combat_state.current_monster = current_monster.to_dict()
	game_data.combat_state.in_combat = true
	game_data.combat_state.combat_log = combat_log

	emit_signal("combat_started", current_monster.name)

	# Change to combat scene if not already there
	if get_tree() and get_tree().current_scene and get_tree().current_scene.name != "CombatScene":
		get_tree().change_scene_to_file("res://scenes/ui/combat_scene.tscn")

	return combat_log

func start_boss_combat(level: int = 1) -> String:
	if not game_data.player:
		return "No player data"

	# Create the final boss
	current_monster = MonsterFactory.create_final_boss(level)

	in_combat = true
	combat_log = "Combat started! " + current_monster.get_phase_description() + "\n" + current_monster.name + " (Level " + str(current_monster.level) + ") appears!"

	game_data.combat_state.current_monster = current_monster.to_dict()
	game_data.combat_state.in_combat = true
	game_data.combat_state.combat_log = combat_log

	emit_signal("combat_started", current_monster.name)

	# Change to combat scene if not already there
	if get_tree() and get_tree().current_scene and get_tree().current_scene.name != "CombatScene":
		get_tree().change_scene_to_file("res://scenes/ui/combat_scene.tscn")

	return combat_log

func is_boss_combat() -> bool:
	return current_monster is FinalBoss

func get_boss_phase() -> int:
	if is_boss_combat():
		return current_monster.current_phase
	return -1

func player_attack() -> String:
	if not in_combat or not current_monster or not game_data.player:
		return "Not in combat"

	var is_critical = _roll_critical(game_data.player.dexterity)
	var base_damage = game_data.player.get_attack_power()
	var damage = _calculate_damage(base_damage, game_data.player.level, current_monster.defense, is_critical)

	current_monster.take_damage(damage)

	var attack_msg = ""
	if is_critical:
		attack_msg = "**CRITICAL HIT!** You strike for " + str(damage) + " damage!"
	else:
		attack_msg = "You attack for " + str(damage) + " damage!"

	# Check for boss phase transition
	if is_boss_combat() and current_monster.health > 0:
		if current_monster.check_phase_transition():
			var new_phase = current_monster.current_phase
			var phase_desc = current_monster.get_phase_description()
			attack_msg += "\n[color=red]" + current_monster.name + " has transitioned to Phase " + str(new_phase) + "! " + phase_desc + "[/color]"
			emit_signal("boss_phase_changed", new_phase, phase_desc)

	if current_monster.health <= 0:
		current_monster.health = 0
		attack_msg += " " + current_monster.name + " defeated!"
		_give_combat_rewards()
		if is_boss_combat():
			emit_signal("boss_defeated")

	combat_log = attack_msg
	game_data.combat_state.combat_log = combat_log

	emit_signal("player_attacked", damage, is_critical)

	_check_combat_end()
	return combat_log

func player_use_skill(skill_index: int) -> String:
	if not in_combat or not game_data.player:
		return "Not in combat"

	if skill_index < 0 or skill_index >= game_data.player.skills.size():
		return "Invalid skill"

	var skill = game_data.player.skills[skill_index]
	if not skill.can_use(game_data.player):
		return "Cannot use skill"

	var result = skill.use(game_data.player, current_monster)
	if not result.success:
		return "Skill failed"

	var skill_msg = ""
	match skill.effect_type:
		"damage":
			skill_msg = skill.name + " deals " + str(result.damage) + " damage!"
			if current_monster.health <= 0:
				current_monster.health = 0
				skill_msg += " " + current_monster.name + " defeated!"
				_give_combat_rewards()
		"heal":
			skill_msg = skill.name + " restores " + str(result.healing) + " HP!"

	combat_log = skill_msg
	game_data.combat_state.combat_log = combat_log

	_check_combat_end()
	return combat_log

func monster_attack() -> String:
	if not in_combat or not current_monster or not game_data.player:
		return "Not in combat"

	var attack_msg = ""
	var total_damage = 0

	# Handle boss abilities
	if is_boss_combat():
		var boss = current_monster as FinalBoss
		var action = boss.get_ai_action()
		
		match action:
			"power_strike":
				var damage = _calculate_damage(int(boss.attack * 1.5), boss.level, game_data.player.get_defense_power())
				game_data.player.take_damage(damage)
				total_damage = damage
				attack_msg = "[color=orange]" + boss.name + " uses Power Strike for " + str(damage) + " damage![/color]"
			
			"dark_curse":
				attack_msg = "[color=purple]" + boss.name + " casts Dark Curse! Your attack power is reduced![/color]"
				# TODO: Implement status effect system
			
			"whirlwind":
				var damage1 = _calculate_damage(int(boss.attack * 0.8), boss.level, game_data.player.get_defense_power())
				var damage2 = _calculate_damage(int(boss.attack * 0.8), boss.level, game_data.player.get_defense_power())
				total_damage = damage1 + damage2
				game_data.player.take_damage(total_damage)
				attack_msg = "[color=orange]" + boss.name + " uses Whirlwind! " + str(damage1) + " + " + str(damage2) + " damage![/color]"
			
			"last_stand":
				attack_msg = "[color=yellow]" + boss.name + " takes a defensive stance![/color]"
				# TODO: Implement defense boost
			
			"realm_collapse":
				var damage = _calculate_damage(int(boss.attack * 2.0), boss.level, game_data.player.get_defense_power())
				game_data.player.take_damage(damage)
				total_damage = damage
				attack_msg = "[color=red]" + boss.name + " unleashes Realm Collapse for " + str(damage) + " massive damage![/color]"
			
			_:  # Regular attack
				var damage = _calculate_damage(current_monster.attack, current_monster.level, game_data.player.get_defense_power())
				game_data.player.take_damage(damage)
				total_damage = damage
				attack_msg = current_monster.name + " attacks for " + str(damage) + " damage!"
	else:
		# Regular monster attack
		var damage = _calculate_damage(current_monster.attack, current_monster.level, game_data.player.get_defense_power())
		game_data.player.take_damage(damage)
		total_damage = damage
		attack_msg = current_monster.name + " attacks for " + str(damage) + " damage!"

	if game_data.player.health <= 0:
		attack_msg += " You are defeated!"

	combat_log = attack_msg
	game_data.combat_state.combat_log = combat_log

	emit_signal("monster_attacked", total_damage)

	_check_combat_end()
	return combat_log

func is_combat_over() -> bool:
	return not in_combat

func get_combat_result() -> String:
	if not game_data.player or not current_monster:
		return "unknown"

	if game_data.player.health <= 0:
		return "defeat"
	elif current_monster.health <= 0:
		return "victory"
	else:
		return "ongoing"

func end_combat():
	if not in_combat:
		return

	in_combat = false
	var player_won = current_monster and current_monster.health <= 0 and game_data.player and game_data.player.health > 0

	game_data.combat_state.in_combat = false

	emit_signal("combat_ended", player_won)

# Private combat helper methods
func _calculate_damage(base_damage: int, attacker_level: int, defender_defense: int, is_critical: bool = false) -> int:
	# Base formula: damage = baseDamage * levelMultiplier - defense
	var level_multiplier = 1.0 + (attacker_level * 0.1)
	if level_multiplier > 10.0:
		level_multiplier = 10.0

	var calculated_damage = int(base_damage * level_multiplier) - defender_defense

	# Apply critical multiplier
	if is_critical:
		calculated_damage = int(calculated_damage * 1.75)

	# Minimum damage is 1
	if calculated_damage < 1:
		calculated_damage = 1

	# Add variance (±10%)
	var variance = randi_range(-int(calculated_damage * 0.1), int(calculated_damage * 0.1))
	calculated_damage += variance

	return max(calculated_damage, 1)

func _roll_critical(dexterity: int) -> bool:
	# Base crit chance: 5% + (dexterity * 0.5%)
	var crit_chance = 5 + (dexterity / 2)
	if crit_chance > 50:
		crit_chance = 50

	var roll = randi() % 100
	return roll < crit_chance

func _give_combat_rewards():
	if not game_data.player or not current_monster:
		return

	# Track level before giving experience
	var old_level = game_data.player.level

	# Give experience
	var exp_gained = current_monster.experience_reward
	game_data.player.add_experience(exp_gained)

	# Check for level up
	if game_data.player.level > old_level:
		emit_signal("player_leveled_up", game_data.player.level)

	# Give gold
	var gold_gained = current_monster.gold_reward
	game_data.player.gold += gold_gained

	# Random loot drop (30% chance)
	if randf() < 0.3:
		var loot = ItemFactory.create_random_item(current_monster.level)
		if loot and game_data.player.add_item(loot):
			combat_log += "\nFound loot: " + loot.name + "!"
			emit_signal("loot_dropped", loot.name)

	combat_log += "\nGained " + str(exp_gained) + " EXP and " + str(gold_gained) + " gold!"

func _check_combat_end():
	if not in_combat:
		return

	var player_won = current_monster and current_monster.health <= 0
	var player_lost = game_data.player and game_data.player.health <= 0

	if player_won or player_lost:
		end_combat()

# Utility methods
func get_player() -> Player:
	return game_data.player

func get_current_monster() -> Monster:
	return current_monster

func get_combat_log() -> String:
	return combat_log

func get_playtime_minutes() -> int:
	var current_time = Time.get_unix_time_from_system()
	var seconds = current_time - game_start_time
	return int(seconds / 60)

func get_exploration_state() -> Dictionary:
	return game_data.get("exploration_state", {})

func set_exploration_state(state: Dictionary):
	game_data.exploration_state = state

func can_use_skill(skill_index: int) -> bool:
	if not game_data.player or skill_index < 0 or skill_index >= game_data.player.skills.size():
		return false
	return game_data.player.skills[skill_index].can_use(game_data.player)

func tick_skill_cooldowns():
	if game_data.player:
		for skill in game_data.player.skills:
			skill.tick_cooldown()
