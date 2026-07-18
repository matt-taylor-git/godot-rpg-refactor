class_name FinalBoss
extends Monster

# FinalBoss - Enhanced Monster with multi-phase combat and special abilities

@export var max_phase: int = 3
var current_phase: int = 1
var phase_health_thresholds: Array = [100, 66, 33]  # Health percentages for phase transitions

var phase_descriptions: Array = [
	"Phase 1: The boss is aggressive and uses standard attacks.",
	"Phase 2: The boss becomes more dangerous and uses special abilities!",
	"Phase 3: The boss is desperate and uses powerful dark magic!"
]

func _init():
	super._init()
	current_phase = 1

func set_stats_for_level(level: int) -> void:
	name = "Final Boss"
	self.level = level
	max_health = 170 + (level * 10)
	health = max_health
	attack = 14 + level
	defense = 8 + level
	dexterity = 5 + level
	experience_reward = 100 + (level * 12)
	gold_reward = 50 + (level * 5)

func update_phase() -> void:
	var health_percent = int((float(health) / float(max_health)) * 100)

	var new_phase = 1
	if health_percent <= 66:
		new_phase = 2
	if health_percent <= 33:
		new_phase = 3

	if new_phase != current_phase:
		current_phase = new_phase


func check_phase_transition() -> bool:
	var previous_phase := current_phase
	update_phase()
	return current_phase != previous_phase

func get_phase_description() -> String:
	if current_phase >= 1 and current_phase <= phase_descriptions.size():
		return phase_descriptions[current_phase - 1]
	return "Unknown phase"

func get_ai_action() -> String:
	update_phase()
	var roll := randf()

	# Phase-based behavior
	match current_phase:
		1:
			# Phase 1: Standard attacks
			return "attack"
		2:
			if roll < 0.3:
				return "power_strike"
			return "attack"
		3:
			if roll < 0.3:
				return "dark_curse"
			if roll < 0.7:
				return "power_strike"
			return "attack"

	return "attack"

func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["current_phase"] = current_phase
	dict["max_phase"] = max_phase
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	current_phase = data.get("current_phase", 1)
	max_phase = data.get("max_phase", 3)
