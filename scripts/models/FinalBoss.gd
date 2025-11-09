extends Monster
class_name FinalBoss

# FinalBoss - Multi-phase final boss with special abilities

var current_phase: int = 1
var max_phases: int = 4
var phase_transitions: Array = [0.75, 0.50, 0.25]  # Health % thresholds for phase transitions
var phase_data: Array = []
var special_abilities: Array = []
var turns_in_phase: int = 0

func _init():
	super._init()
	
	# Initialize phase data
	_initialize_phase_data()
	_initialize_special_abilities()

func _initialize_phase_data() -> void:
	# Phase 1: Normal attacks
	phase_data.append({
		"attack_multiplier": 1.0,
		"defense_bonus": 0,
		"attacks_per_turn": 1,
		"ability_chance": 0.2,
		"description": "Preparing for battle..."
	})
	
	# Phase 2: Stronger attacks, introduces abilities
	phase_data.append({
		"attack_multiplier": 1.3,
		"defense_bonus": 0,
		"attacks_per_turn": 1,
		"ability_chance": 0.35,
		"description": "Growing stronger..."
	})
	
	# Phase 3: Dual attacks, frequent abilities
	phase_data.append({
		"attack_multiplier": 1.6,
		"defense_bonus": 5,
		"attacks_per_turn": 2,
		"ability_chance": 0.5,
		"description": "Unleashing true power!"
	})
	
	# Phase 4: Desperation mode
	phase_data.append({
		"attack_multiplier": 2.0,
		"defense_bonus": 10,
		"attacks_per_turn": 2,
		"ability_chance": 0.7,
		"description": "FINAL FORM!"
	})

func _initialize_special_abilities() -> void:
	special_abilities = [
		"power_strike",      # Phase 1+
		"dark_curse",        # Phase 2+
		"whirlwind",         # Phase 3+
		"last_stand",        # Phase 4+
		"realm_collapse"     # Phase 4+
	]

func set_stats_for_level(level: int) -> void:
	"""Override to set boss-level stats"""
	name = "Dark Overlord"
	self.level = level
	
	# Boss should be significantly stronger than normal monsters
	var level_multiplier = 1.5
	
	max_health = int((100 + (level * 15)) * level_multiplier)
	health = max_health
	attack = int((15 + (level * 2)) * level_multiplier)
	defense = int((8 + (level * 1.5)) * level_multiplier)
	dexterity = int((5 + level) * level_multiplier)
	
	experience_reward = int((200 + (level * 50)) * level_multiplier)
	gold_reward = int((150 + (level * 30)) * level_multiplier)
	
	ai_behavior = "boss"

func get_current_phase_data() -> Dictionary:
	if current_phase > 0 and current_phase <= max_phases:
		return phase_data[current_phase - 1]
	return phase_data[0]

func get_phase_description() -> String:
	return get_current_phase_data().get("description", "")

func check_phase_transition() -> bool:
	"""Check if boss should transition to next phase"""
	if current_phase >= max_phases:
		return false
	
	var health_ratio = float(health) / float(max_health)
	var transition_threshold = phase_transitions[current_phase - 1]
	
	if health_ratio <= transition_threshold:
		current_phase += 1
		turns_in_phase = 0
		return true
	
	return false

func get_ability_for_phase() -> String:
	"""Get a random special ability available in current phase"""
	var available_abilities = []
	
	match current_phase:
		1:
			available_abilities = ["power_strike"]
		2:
			available_abilities = ["power_strike", "dark_curse"]
		3:
			available_abilities = ["power_strike", "dark_curse", "whirlwind"]
		4:
			available_abilities = special_abilities
	
	if available_abilities.is_empty():
		return "attack"
	
	return available_abilities[randi() % available_abilities.size()]

func get_ai_action() -> String:
	"""Override AI logic for boss behavior"""
	turns_in_phase += 1
	
	var phase_data_current = get_current_phase_data()
	var ability_chance = phase_data_current.get("ability_chance", 0.2)
	
	# Occasionally use special abilities
	if randf() < ability_chance:
		return get_ability_for_phase()
	
	return "attack"

func calculate_attack_damage(attacker_attack: int, defender_defense: int) -> int:
	"""Calculate damage with phase multiplier"""
	var phase_data_current = get_current_phase_data()
	var multiplier = phase_data_current.get("attack_multiplier", 1.0)
	
	# Base damage calculation
	var base_damage = (attacker_attack * 2) - defender_defense
	var variance = randi_range(-2, 5)
	var damage = maxi(1, int((base_damage + variance) * multiplier))
	
	return damage

func to_dict() -> Dictionary:
	var base_dict = super.to_dict()
	base_dict["current_phase"] = current_phase
	base_dict["turns_in_phase"] = turns_in_phase
	base_dict["is_final_boss"] = true
	return base_dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	current_phase = data.get("current_phase", 1)
	turns_in_phase = data.get("turns_in_phase", 0)
