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
signal player_turn_started
signal monster_turn_started
signal player_leveled_up(new_level: int)
signal loot_dropped(item_name: String)

# Boss-specific signals
signal boss_phase_changed(phase: int, description: String)
signal boss_defeated()

# Status effect signals
signal player_status_effect_added(effect_type: String, duration: int)
signal player_status_effect_removed(effect_type: String)
signal monster_status_effect_added(effect_type: String, duration: int)
signal monster_status_effect_removed(effect_type: String)

# Victory signal
signal game_victory()

# Operation feedback signals for UI animations (AC-UI-011)
signal operation_succeeded(message: String)  # Success feedback signal
signal operation_failed(message: String)  # Error feedback signal

# Old town/world_map screens absorbed into the unified exploration hub.
const SCENE_ALIASES := {
	"town_scene": "exploration_scene",
	"world_map": "exploration_scene",
}

var current_scene: String = ""
var game_data = {}

# Combat state
var current_monster: Monster = null
var in_combat: bool = false
var combat_log: String = ""
var pending_monster_intent: Dictionary = {}
var combat_reward_multiplier: float = 1.0
var combat_loot_chance: float = 0.25
var combat_area_id: String = "forest"
var game_start_time: float = 0.0

# Statistics tracking
var stats = {
	"enemies_defeated": 0,
	"deaths": 0,
	"gold_earned": 0,
	"quests_completed": 0
}

func _ready():
	print("GameManager initialized")
	game_start_time = Time.get_unix_time_from_system()

	# Load persisted accessibility settings early
	GameSettings.load_settings()

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
	if player_won and current_monster:
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

	# Set mana by class (full at start)
	game_data.player.max_mana = Player.get_base_max_mana_for_class(character_class)
	game_data.player.mana = game_data.player.max_mana
	game_data.player.gold = 100
	game_data.player.add_item(ItemFactory.create_item("health_potion"))

	# Give starting skills
	var starting_skills = SkillFactory.get_class_skills(character_class)
	for skill in starting_skills:
		game_data.player.skills.append(skill)

	# Reset combat state
	current_monster = null
	in_combat = false
	combat_log = ""

	# Reset statistics
	stats = {
		"enemies_defeated": 0,
		"deaths": 0,
		"gold_earned": 0,
		"quests_completed": 0
	}

	# Reset game start time for playtime tracking
	game_start_time = Time.get_unix_time_from_system()

	game_data.current_scene = "town"
	game_data.exploration_state = {
		"steps_taken": 0,
		"encounter_chance": 2.0,
		"steps_since_last_encounter": 0,
		"current_area_id": "town",
		"danger_level": 0.0
	}
	emit_signal("game_started")

	# Trigger initial story event
	StoryManager.on_game_started()

func start_new_game():
	print("Starting new game")
	game_data.player = null  # Will be set during character creation
	game_data.current_scene = "character_creation"
	emit_signal("game_started")

func load_game(save_slot: int) -> bool:
	print("Loading game from slot ", save_slot)
	var loaded_data = _load_from_file(save_slot)
	if loaded_data:
		game_data.player = Player.new()
		game_data.player.from_dict(loaded_data.player)
		game_data.current_scene = loaded_data.get("current_scene", "town")
		game_data.exploration_state = loaded_data.get("exploration_state", {
			"steps_taken": 0,
			"encounter_chance": 2.0,
			"steps_since_last_encounter": 0,
			"current_area_id": "town",
			"danger_level": 0.0
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
		combat_reward_multiplier = combat_state.get("reward_multiplier", 1.0)
		combat_loot_chance = combat_state.get("loot_chance", 0.25)
		combat_area_id = combat_state.get("area_id", "forest")
		pending_monster_intent = combat_state.get("pending_intent", {})

		game_start_time = loaded_data.get("game_start_time", Time.get_unix_time_from_system())

		emit_signal("game_loaded")
		emit_signal("operation_succeeded", "Game loaded successfully!")  # AC-UI-011
		return true

	print("Failed to load save slot ", save_slot)
	emit_signal("operation_failed", "Failed to load game")  # AC-UI-012
	return false

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
			print("JSON parse error: ", json.get_error_message())
		else:
			print("Failed to open save file")
	else:
		print("Save file does not exist")
	return null

func save_game(save_slot: int) -> bool:
	print("Saving game to slot ", save_slot)
	if game_data.player:
		game_data.save_slots[save_slot] = {
			"player": game_data.player.to_dict(),
			"current_scene": game_data.current_scene,
			"exploration_state": game_data.get("exploration_state", {}),
			"combat_state": {
				"current_monster": current_monster.to_dict() if current_monster else null,
				"in_combat": in_combat,
				"combat_log": combat_log,
				"reward_multiplier": combat_reward_multiplier,
				"loot_chance": combat_loot_chance,
				"area_id": combat_area_id,
				"pending_intent": pending_monster_intent,
			},
			"game_start_time": game_start_time
		}
		return _save_to_file(save_slot)

	print("No player data to save")
	emit_signal("operation_failed", "Failed to save game")
	return false


func _save_to_file(save_slot: int) -> bool:
	var save_path = "user://save_slot_%d.json" % save_slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data.save_slots[save_slot])
		file.store_string(json_string)
		file.close()
		print("Game saved to ", save_path)
		emit_signal("operation_succeeded", "Game saved successfully!")  # AC-UI-011
		return true

	print("Failed to save game")
	emit_signal("operation_failed", "Failed to save game")  # AC-UI-012
	return false

func resolve_scene_name(scene_name: String) -> String:
	return SCENE_ALIASES.get(scene_name, scene_name)


func change_scene(scene_name: String):
	print("Changing scene to: ", scene_name)
	# Force town area when callers still request the old town hub.
	if scene_name == "town_scene":
		var state = get_exploration_state().duplicate(true)
		if state.is_empty():
			state = {}
		state["current_area_id"] = "town"
		set_exploration_state(state)

	var resolved = resolve_scene_name(scene_name)
	var scene_path = "res://scenes/ui/" + resolved + ".tscn"
	if not ResourceLoader.exists(scene_path):
		print("Error: Scene file not found: ", scene_path)
		return
	current_scene = resolved
	game_data.current_scene = resolved

	# Fade via SceneTransition autoload when available
	print("Loading scene: ", scene_path)
	if SceneTransition:
		await SceneTransition.change_scene(scene_path)
		print("Scene changed successfully to: ", resolved)
		emit_signal("scene_changed", resolved)
	else:
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			print("Error changing scene: ", error)
		else:
			print("Scene changed successfully to: ", resolved)
			emit_signal("scene_changed", resolved)

func get_current_scene() -> String:
	return current_scene

func is_game_active() -> bool:
	return game_data.player != null


func _set_combat_reward_context(
	reward_multiplier: float = 1.0,
	loot_chance: float = 0.25,
	area_id: String = "",
) -> void:
	combat_reward_multiplier = maxf(1.0, reward_multiplier)
	combat_loot_chance = clampf(loot_chance, 0.0, 1.0)
	if area_id != "":
		combat_area_id = area_id
		return
	var exploration_state: Dictionary = get_exploration_state()
	combat_area_id = str(exploration_state.get("current_area_id", "forest"))


# Combat System
func start_combat():
	if not game_data.player:
		return "No player data"

	# Create a random monster based on player level
	current_monster = MonsterFactory.create_monster(
		MonsterFactory.get_random_monster_type(),
		game_data.player.level
	)
	_set_combat_reward_context()

	in_combat = true
	_reset_skill_cooldowns()
	combat_log = "Combat started! A " + current_monster.name + " (Level " + str(current_monster.level) + ") appears!"
	refresh_monster_intent()

	game_data.combat_state.current_monster = current_monster.to_dict()
	game_data.combat_state.in_combat = true
	game_data.combat_state.combat_log = combat_log

	emit_signal("combat_started", current_monster.name)

	# Change to combat scene if not already there
	if get_tree() and get_tree().current_scene and get_tree().current_scene.name != "CombatScene":
		await change_scene("combat_scene")

	return combat_log

func start_combat_with_type(
	monster_type: String,
	monster_level: int = -1,
	reward_multiplier: float = 1.0,
	loot_chance: float = 0.25,
	area_id: String = "",
	monster_rank: String = "medium",
):
	if not game_data.player:
		return "No player data"

	var resolved_level: int = game_data.player.level if monster_level < 1 else monster_level
	current_monster = MonsterFactory.create_monster(monster_type, resolved_level)
	MonsterFactory.apply_encounter_rank(current_monster, monster_rank)
	_set_combat_reward_context(reward_multiplier, loot_chance, area_id)

	in_combat = true
	_reset_skill_cooldowns()
	combat_log = "Combat started! A " + current_monster.name \
		+ " (Level " + str(current_monster.level) + ") appears!"
	refresh_monster_intent()

	game_data.combat_state.current_monster = current_monster.to_dict()
	game_data.combat_state.in_combat = true
	game_data.combat_state.combat_log = combat_log

	emit_signal("combat_started", current_monster.name)

	if get_tree() and get_tree().current_scene \
		and get_tree().current_scene.name != "CombatScene":
		await change_scene("combat_scene")

	return combat_log


func start_combat_from_event(event: Dictionary, fallback_area: String = "forest"):
	return await start_combat_with_type(
		str(event.get("monster_type", "goblin")),
		int(event.get("monster_level", -1)),
		float(event.get("reward_multiplier", 1.0)),
		float(event.get("loot_chance", 0.25)),
		str(event.get("area_id", fallback_area)),
		str(event.get("monster_rank", "medium")),
	)

func start_boss_combat(level: int = -1) -> String:
	if not game_data.player:
		return "No player data"

	# Create the final boss
	var requested_level: int = game_data.player.level if level < 1 else level
	current_monster = MonsterFactory.create_final_boss(requested_level)
	_set_combat_reward_context(1.0, 0.0, "peak")

	in_combat = true
	_reset_skill_cooldowns()
	combat_log = "Combat started! " + current_monster.get_phase_description() \
		+ "\n" + current_monster.name + " (Level " \
		+ str(current_monster.level) + ") appears!"
	refresh_monster_intent()

	game_data.combat_state.current_monster = current_monster.to_dict()
	game_data.combat_state.in_combat = true
	game_data.combat_state.combat_log = combat_log

	emit_signal("combat_started", current_monster.name)

	# Change to combat scene if not already there
	if get_tree() and get_tree().current_scene and get_tree().current_scene.name != "CombatScene":
		await change_scene("combat_scene")

	return combat_log

func is_boss_combat() -> bool:
	return current_monster != null and current_monster is FinalBoss


func can_access_final_boss() -> bool:
	return game_data.player != null and game_data.player.level >= 8

func get_boss_phase() -> int:
	if is_boss_combat():
		return current_monster.current_phase
	return -1


func get_monster_intent() -> Dictionary:
	return pending_monster_intent.duplicate()


func refresh_monster_intent() -> Dictionary:
	pending_monster_intent = {}
	if not current_monster or not game_data.player:
		return pending_monster_intent

	var action_id := "attack"
	if current_monster.has_method("get_ai_action"):
		action_id = current_monster.get_ai_action()

	var label := _intent_label_for(action_id, current_monster.name)
	var atk_mult := _intent_attack_multiplier(action_id)
	var dmg_range := CombatRules.estimate_range(
		current_monster.attack,
		game_data.player.get_defense_power(),
		atk_mult,
	)
	if action_id == "defend" or action_id == "last_stand" or action_id == "dark_curse":
		dmg_range = {"min": 0, "max": 0}

	pending_monster_intent = {
		"id": action_id,
		"label": label,
		"min": dmg_range.min,
		"max": dmg_range.max,
	}
	return pending_monster_intent.duplicate()


func estimate_damage_range(
	base_damage: int,
	_attacker_level: int,
	defender_defense: int,
	action_multiplier: float = 1.0,
) -> Dictionary:
	return CombatRules.estimate_range(base_damage, defender_defense, action_multiplier)


func _intent_label_for(action_id: String, monster_name: String) -> String:
	var label := "Strike"
	match action_id:
		"defend", "last_stand":
			label = "Defending"
		"power_strike":
			label = "Power Strike"
		"dark_curse":
			label = "Dark Curse"
		"whirlwind":
			label = "Whirlwind"
		"realm_collapse":
			label = "Realm Collapse"
		"attack":
			var lower := monster_name.to_lower()
			if "wolf" in lower:
				label = "Bite"
			elif "spider" in lower:
				label = "Venom Strike"
			elif "slime" in lower:
				# Sword-wielding slime art reads as a slash, not a body slam
				label = "Slash"
			elif "dragon" in lower:
				label = "Claw"
			else:
				label = "Strike"
		_:
			label = "Strike"
	return label


func _intent_attack_multiplier(action_id: String) -> float:
	match action_id:
		"power_strike":
			return 1.35
		"whirlwind":
			return 1.6
		"realm_collapse":
			return 2.0
		"defend", "last_stand", "dark_curse":
			return 0.0
		_:
			return 1.0


func player_use_consumable(inventory_index: int) -> String:
	if not in_combat or not game_data.player:
		return "Not in combat"
	if inventory_index < 0 or inventory_index >= game_data.player.inventory.size():
		return "Invalid item"
	var item = game_data.player.inventory[inventory_index]
	if item == null or not item.is_consumable():
		return "That item cannot be used in combat."
	var item_name: String = item.name
	var used: bool = item.use(game_data.player)
	if not used:
		return "Could not use %s." % item_name
	if item.quantity <= 0:
		game_data.player.remove_item(inventory_index)
	tick_player_action_status_effects()
	combat_log = "You use %s." % item_name
	game_data.combat_state.combat_log = combat_log
	return combat_log

func player_attack() -> String:
	if not in_combat or not current_monster or not game_data.player:
		return "Not in combat"

	var is_critical = _roll_critical(game_data.player.dexterity)
	var base_damage = game_data.player.get_attack_power()
	var action_multiplier: float = game_data.player.get_outgoing_damage_multiplier()
	var damage := CombatRules.roll_damage(
		base_damage, current_monster.defense, action_multiplier, is_critical)

	current_monster.take_damage(damage)
	tick_player_action_status_effects()

	var attack_msg = ""
	var pname: String = game_data.player.name if game_data.player else "You"
	if is_critical:
		attack_msg = "Critical hit! %s strikes %s for %d damage." % [pname, current_monster.name, damage]
	else:
		attack_msg = "%s strikes %s for %d damage." % [pname, current_monster.name, damage]

	# Check for boss phase transition
	if is_boss_combat() and current_monster.health > 0:
		if current_monster.check_phase_transition():
			var new_phase = current_monster.current_phase
			var phase_desc = current_monster.get_phase_description()
			attack_msg += "\n[color=red]" + current_monster.name \
				+ " has transitioned to Phase " + str(new_phase) \
				+ "! " + phase_desc + "[/color]"
			emit_signal("boss_phase_changed", new_phase, phase_desc)

	if current_monster.health <= 0:
		current_monster.health = 0
		attack_msg += " " + current_monster.name + " defeated!"
		attack_msg += _give_combat_rewards()
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
	tick_player_action_status_effects()

	var skill_msg = ""
	match skill.effect_type:
		"damage":
			skill_msg = skill.name + " deals " + str(result.damage) + " damage!"
			if is_boss_combat() and current_monster.health > 0:
				if current_monster.check_phase_transition():
					var phase: int = current_monster.current_phase
					var description: String = current_monster.get_phase_description()
					skill_msg += "\n%s enters Phase %d! %s" % [
						current_monster.name, phase, description]
					emit_signal("boss_phase_changed", phase, description)
			if current_monster.health <= 0:
				current_monster.health = 0
				skill_msg += " " + current_monster.name + " defeated!"
				skill_msg += _give_combat_rewards()
				if is_boss_combat():
					emit_signal("boss_defeated")
		"heal":
			skill_msg = skill.name + " restores " + str(result.healing) + " HP!"
		"buff":
			skill_msg = skill.name + " — you gain a defensive stance!"
			if game_data.player.has_status_effect("stealth"):
				emit_signal("player_status_effect_added", "stealth",
					game_data.player.get_status_effect_duration("stealth"))
		_:
			skill_msg = skill.name + " activated!"

	combat_log = skill_msg
	game_data.combat_state.combat_log = combat_log

	_check_combat_end()
	return combat_log

func monster_attack() -> String:
	if not in_combat or not current_monster or not game_data.player:
		return "Not in combat"

	if pending_monster_intent.is_empty():
		refresh_monster_intent()
	var action := str(pending_monster_intent.get("id", "attack"))
	pending_monster_intent = {}
	var attack_msg := ""
	var total_damage := 0
	var player_defense: int = game_data.player.get_defense_power()

	match action:
		"dark_curse":
			game_data.player.add_status_effect(
				"weakened",
				2,
				{"damage_multiplier": 0.8, "tick_mode": "player_action"},
			)
			emit_signal("player_status_effect_added", "weakened", 2)
			attack_msg = "[color=purple]%s casts Dark Curse! " \
				+ "Your damage is reduced by 20%% for two actions.[/color]"
			attack_msg = attack_msg % current_monster.name
		"defend", "last_stand":
			attack_msg = "[color=yellow]%s takes a defensive stance![/color]" \
				% current_monster.name
		"whirlwind":
			var first_hit := CombatRules.roll_damage(
				current_monster.attack, player_defense, 0.8)
			var second_hit := CombatRules.roll_damage(
				current_monster.attack, player_defense, 0.8)
			total_damage = first_hit + second_hit
			game_data.player.take_damage(total_damage)
			attack_msg = "[color=orange]%s uses Whirlwind! %d + %d damage![/color]" \
				% [current_monster.name, first_hit, second_hit]
		_:
			var multiplier := _intent_attack_multiplier(action)
			total_damage = CombatRules.roll_damage(
				current_monster.attack, player_defense, multiplier)
			game_data.player.take_damage(total_damage)
			if action == "power_strike":
				attack_msg = "[color=orange]%s uses Power Strike for %d damage![/color]" \
					% [current_monster.name, total_damage]
			elif action == "realm_collapse":
				attack_msg = "[color=red]%s unleashes Realm Collapse for %d damage![/color]" \
					% [current_monster.name, total_damage]
			else:
				attack_msg = "%s attacks for %d damage!" % [current_monster.name, total_damage]

	if game_data.player.health <= 0:
		attack_msg += " You are defeated!"
		stats["deaths"] += 1

	# End of full turn: tick skill cooldowns and status effect durations
	tick_skill_cooldowns()
	tick_combat_status_effects()

	combat_log = attack_msg
	game_data.combat_state.combat_log = combat_log

	emit_signal("monster_attacked", total_damage)

	_check_combat_end()
	if in_combat:
		refresh_monster_intent()
	return combat_log

func is_combat_over() -> bool:
	return not in_combat

func get_combat_result() -> String:
	if not game_data.player or not current_monster:
		return "unknown"

	if game_data.player.health <= 0:
		return "defeat"
	if current_monster.health <= 0:
		return "victory"
	return "ongoing"

func end_combat():
	if not in_combat:
		return

	in_combat = false
	pending_monster_intent = {}
	var player_won = current_monster and current_monster.health <= 0 and game_data.player and game_data.player.health > 0

	game_data.combat_state.in_combat = false

	emit_signal("combat_ended", player_won)

# Private combat helper methods
func _calculate_damage(
	base_damage: int,
	_attacker_level: int,
	defender_defense: int,
	is_critical: bool = false,
) -> int:
	return CombatRules.roll_damage(base_damage, defender_defense, 1.0, is_critical)

	# Add variance (±10%)

func _roll_critical(dexterity: int) -> bool:
	# Base crit chance: 5% + (dexterity * 0.5%)
	var crit_chance = 5 + (dexterity / 2)
	if crit_chance > 50:
		crit_chance = 50

	var roll = randi() % 100
	return roll < crit_chance

func _give_combat_rewards() -> String:
	if not game_data.player or not current_monster:
		return ""

	# Track level before giving experience
	var old_level = game_data.player.level

	# Give experience
	var exp_gained := roundi(
		float(current_monster.experience_reward) * combat_reward_multiplier)
	game_data.player.add_experience(exp_gained)

	# Check for level up
	if game_data.player.level > old_level:
		emit_signal("player_leveled_up", game_data.player.level)

	# Give gold
	var gold_gained := roundi(float(current_monster.gold_reward) * combat_reward_multiplier)
	game_data.player.gold += gold_gained

	# Track statistics
	stats["enemies_defeated"] += 1
	stats["gold_earned"] += gold_gained

	var reward_message := ""
	if randf() < combat_loot_chance:
		var loot = ItemFactory.create_random_item_for_area(combat_area_id)
		if loot and game_data.player.add_item(loot):
			reward_message += "\nFound loot: " + loot.name + "!"
			emit_signal("loot_dropped", loot.name)

	reward_message += "\nGained " + str(exp_gained) + " EXP and " \
		+ str(gold_gained) + " gold!"
	return reward_message


func tick_player_action_status_effects() -> void:
	if not game_data.player:
		return
	var expired_effects: Array = game_data.player.tick_player_action_status_effects()
	for effect_type in expired_effects:
		emit_signal("player_status_effect_removed", effect_type)


func resolve_defeat() -> Dictionary:
	if not game_data.player:
		return {"gold_lost": 0, "return_scene": "exploration_scene"}
	var player: Player = game_data.player
	var gold_lost := mini(50, floori(float(player.gold) * 0.10))
	player.gold = maxi(0, player.gold - gold_lost)
	player.health = player.max_health
	player.mana = player.max_mana
	player.status_effects.clear()
	_reset_skill_cooldowns()
	pending_monster_intent = {}
	in_combat = false
	current_monster = null
	game_data.combat_state = {
		"current_monster": null,
		"in_combat": false,
		"combat_log": "",
	}
	var exploration_state: Dictionary = get_exploration_state().duplicate(true)
	exploration_state["current_area_id"] = "town"
	exploration_state["danger_level"] = 0.0
	exploration_state["steps_since_last_encounter"] = 0
	set_exploration_state(exploration_state)
	return {"gold_lost": gold_lost, "return_scene": "exploration_scene"}

func _check_combat_end():
	if not in_combat:
		return

	var player_won = current_monster and current_monster.health <= 0
	var player_lost = game_data.player and game_data.player.health <= 0

	if player_won or player_lost:
		end_combat()

func go_to_town():
	change_scene("town_scene")  # aliases to exploration hub at town


func go_to_exploration():
	change_scene("exploration_scene")

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
			if skill:
				skill.tick_cooldown()

func _reset_skill_cooldowns() -> void:
	if not game_data.player:
		return
	for skill in game_data.player.skills:
		if skill:
			skill.current_cooldown = 0

# Statistics getters
func get_enemies_defeated() -> int:
	return stats["enemies_defeated"]

func get_deaths() -> int:
	return stats["deaths"]

func get_gold_earned() -> int:
	return stats["gold_earned"]

func get_quests_completed() -> int:
	return stats["quests_completed"]

func set_quests_completed(count: int) -> void:
	stats["quests_completed"] = count

# Status effect management
func add_player_status_effect(effect_type: String, duration: int, effect_data: Dictionary = {}) -> void:
	if game_data.player:
		game_data.player.add_status_effect(effect_type, duration, effect_data)
		emit_signal("player_status_effect_added", effect_type, duration)

func remove_player_status_effect(effect_type: String) -> void:
	if game_data.player:
		game_data.player.remove_status_effect(effect_type)
		emit_signal("player_status_effect_removed", effect_type)

func add_monster_status_effect(effect_type: String, duration: int, effect_data: Dictionary = {}) -> void:
	if current_monster:
		current_monster.add_status_effect(effect_type, duration, effect_data)
		emit_signal("monster_status_effect_added", effect_type, duration)

func remove_monster_status_effect(effect_type: String) -> void:
	if current_monster:
		current_monster.remove_status_effect(effect_type)
		emit_signal("monster_status_effect_removed", effect_type)

func tick_combat_status_effects() -> void:
	# Process status effects for both player and monster at end of combat turn
	if game_data.player:
		var expired_player_effects = game_data.player.tick_status_effects()
		for effect_type in expired_player_effects:
			emit_signal("player_status_effect_removed", effect_type)

	if current_monster:
		var expired_monster_effects = current_monster.tick_status_effects()
		for effect_type in expired_monster_effects:
			emit_signal("monster_status_effect_removed", effect_type)

func trigger_victory() -> void:
	emit_signal("game_victory")
