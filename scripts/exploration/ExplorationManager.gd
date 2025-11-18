extends Node

# ExplorationManager - Handles exploration mechanics, random encounters, and area transitions
# Manages the exploration state and coordinates with GameManager

signal area_entered(area_name: String)
signal encounter_triggered(monster_type: String)
signal safe_zone_entered(npc_type: String)
signal quest_marker_found(quest_id: String)

var current_area: String = "town"
var exploration_areas = {
	"town": {
		"name": "Town",
		"type": "safe",
		"npcs": ["traveling_merchant"],
		"connections": ["forest", "mountain"],
		"description": "A safe town with shops and NPCs"
	},
	"forest": {
		"name": "Dark Forest",
		"type": "dangerous",
		"encounter_chance": 15.0,  # 15% chance per step
		"monster_types": ["goblin", "slime", "wolf"],
		"connections": ["town", "mountain", "cave"],
		"description": "A dense forest with dangerous creatures"
	},
	"mountain": {
		"name": "Mountain Path",
		"type": "dangerous",
		"encounter_chance": 20.0,  # 20% chance per step
		"monster_types": ["goblin", "orc", "skeleton"],
		"connections": ["town", "forest", "peak"],
		"description": "Steep mountain paths with fierce monsters"
	},
	"cave": {
		"name": "Dark Cave",
		"type": "dangerous",
		"encounter_chance": 25.0,  # 25% chance per step
		"monster_types": ["skeleton", "spider", "bat"],
		"connections": ["forest"],
		"description": "A dark cave system with deadly creatures"
	},
	"peak": {
		"name": "Mountain Peak",
		"type": "dangerous",
		"encounter_chance": 30.0,  # 30% chance per step
		"monster_types": ["orc", "troll", "dragon"],
		"connections": ["mountain"],
		"description": "The highest peak with legendary monsters"
	}
}

func _ready():
	print("ExplorationManager initialized")
	connect_signals()

func connect_signals():
	GameManager.connect("scene_changed", Callable(self, "_on_scene_changed"))

func _on_scene_changed(scene_name: String):
	if scene_name in exploration_areas:
		enter_area(scene_name)

func enter_area(area_name: String):
	if not area_name in exploration_areas:
		print("Unknown area: ", area_name)
		return

	current_area = area_name
	var area_data = exploration_areas[area_name]

	print("Entered area: ", area_data.name)

	# Emit signal for UI updates
	emit_signal("area_entered", area_data.name)

	# Handle area type
	match area_data.type:
		"safe":
			handle_safe_zone(area_data)
		"dangerous":
			handle_dangerous_zone(area_data)

func handle_safe_zone(area_data: Dictionary):
	print("Entered safe zone: ", area_data.name)

	# Spawn NPCs
	for npc in area_data.npcs:
		emit_signal("safe_zone_entered", npc)

	# Check for quest markers
	check_quest_markers()

func handle_dangerous_zone(area_data: Dictionary):
	print("Entered dangerous zone: ", area_data.name)
	# Dangerous zones have random encounters
	# Encounter logic is handled by movement

func move_to_direction(direction: String) -> bool:
	var area_data = exploration_areas.get(current_area, {})
	var connections = area_data.get("connections", [])

	if direction in connections:
		enter_area(direction)
		return true
	else:
		print("Cannot move to ", direction, " from ", current_area)
		return false

func take_exploration_step():
	if not GameManager.is_game_active():
		return

	var exploration_state = GameManager.get_exploration_state()
	exploration_state.steps_taken += 1
	exploration_state.steps_since_last_encounter += 1

	var area_data = exploration_areas.get(current_area, {})
	if area_data.type == "dangerous":
		var encounter_chance = area_data.get("encounter_chance", 10.0)
		var adjusted_chance = encounter_chance * (1.0 - (exploration_state.steps_since_last_encounter * 0.01))  # Reduce chance after encounters

		if randf() * 100 < adjusted_chance:
			trigger_random_encounter(area_data)
			exploration_state.steps_since_last_encounter = 0

	GameManager.set_exploration_state(exploration_state)

func trigger_random_encounter(area_data: Dictionary):
	var monster_types = area_data.get("monster_types", ["goblin"])
	var random_type = monster_types[randi() % monster_types.size()]

	print("Random encounter: ", random_type)
	emit_signal("encounter_triggered", random_type)

	# Start combat
	GameManager.start_combat()

func check_quest_markers():
	# Check active quests for exploration objectives
	var active_quests = QuestManager.get_active_quests()

	for quest in active_quests:
		if quest.type == "exploration" and quest.target_area == current_area:
			emit_signal("quest_marker_found", quest.id)

func get_current_area_info() -> Dictionary:
	return exploration_areas.get(current_area, {})

func get_available_directions() -> Array:
	var area_data = exploration_areas.get(current_area, {})
	return area_data.get("connections", [])

func is_safe_zone() -> bool:
	var area_data = exploration_areas.get(current_area, {})
	return area_data.get("type", "") == "safe"

func get_area_description() -> String:
	var area_data = exploration_areas.get(current_area, {})
	return area_data.get("description", "Unknown area")
