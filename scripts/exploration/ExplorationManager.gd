class_name ExplorationManager
extends Node

# ExplorationManager - Handles exploration areas, travel, and area data
# Manages area definitions, level-gating, and atmosphere parameters

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
		"description": "A safe town with shops and NPCs",
		"level_requirement": 1,
		"rest_ambush_chance": 0.0,
		"shader_params": {
			"color_primary": Color(0.08, 0.07, 0.05, 1),
			"color_accent": Color(0.20, 0.15, 0.08, 1),
			"ember_intensity": 0.04,
			"ember_color": Color(0.9, 0.6, 0.2, 1),
			"wave_intensity": 0.2,
		},
	},
	"forest": {
		"name": "Dark Forest",
		"type": "dangerous",
		"encounter_chance": 15.0,
		"monster_types": ["goblin", "slime", "wolf"],
		"connections": ["town", "mountain", "cave"],
		"description": "A dense forest with dangerous creatures",
		"level_requirement": 1,
		"rest_ambush_chance": 0.05,
		"shader_params": {
			"color_primary": Color(0.04, 0.06, 0.03, 1),
			"color_accent": Color(0.10, 0.15, 0.06, 1),
			"ember_intensity": 0.02,
			"ember_color": Color(0.4, 0.8, 0.3, 1),
			"wave_intensity": 0.35,
		},
	},
	"mountain": {
		"name": "Mountain Path",
		"type": "dangerous",
		"encounter_chance": 20.0,
		"monster_types": ["goblin", "orc", "skeleton"],
		"connections": ["town", "forest", "peak"],
		"description": "Steep mountain paths with fierce monsters",
		"level_requirement": 3,
		"rest_ambush_chance": 0.10,
		"shader_params": {
			"color_primary": Color(0.06, 0.05, 0.07, 1),
			"color_accent": Color(0.12, 0.10, 0.15, 1),
			"ember_intensity": 0.01,
			"ember_color": Color(0.6, 0.6, 0.8, 1),
			"wave_intensity": 0.4,
		},
	},
	"cave": {
		"name": "Dark Cave",
		"type": "dangerous",
		"encounter_chance": 25.0,
		"monster_types": ["skeleton", "spider", "bat"],
		"connections": ["forest"],
		"description": "A dark cave system with deadly creatures",
		"level_requirement": 5,
		"rest_ambush_chance": 0.15,
		"shader_params": {
			"color_primary": Color(0.03, 0.02, 0.04, 1),
			"color_accent": Color(0.08, 0.05, 0.10, 1),
			"ember_intensity": 0.08,
			"ember_color": Color(0.5, 0.3, 0.8, 1),
			"wave_intensity": 0.25,
		},
	},
	"peak": {
		"name": "Mountain Peak",
		"type": "dangerous",
		"encounter_chance": 30.0,
		"monster_types": ["orc", "troll", "dragon"],
		"connections": ["mountain"],
		"description": "The highest peak with legendary monsters",
		"level_requirement": 8,
		"rest_ambush_chance": 0.20,
		"shader_params": {
			"color_primary": Color(0.05, 0.04, 0.03, 1),
			"color_accent": Color(0.18, 0.10, 0.05, 1),
			"ember_intensity": 0.10,
			"ember_color": Color(1.0, 0.4, 0.1, 1),
			"wave_intensity": 0.5,
		},
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
	emit_signal("area_entered", area_data.name)

	match area_data.type:
		"safe":
			handle_safe_zone(area_data)
		"dangerous":
			handle_dangerous_zone(area_data)

func handle_safe_zone(area_data: Dictionary):
	print("Entered safe zone: ", area_data.name)
	for npc in area_data.npcs:
		emit_signal("safe_zone_entered", npc)
	check_quest_markers()

func handle_dangerous_zone(area_data: Dictionary):
	print("Entered dangerous zone: ", area_data.name)

func move_to_direction(direction: String) -> bool:
	var area_data = exploration_areas.get(current_area, {})
	var connections = area_data.get("connections", [])

	if direction in connections:
		enter_area(direction)
		return true
	print("Cannot move to ", direction, " from ", current_area)
	return false

func check_quest_markers():
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

func get_accessible_areas(player_level: int) -> Array:
	var accessible = []
	var current_connections = exploration_areas.get(current_area, {}).get("connections", [])
	for area_id in current_connections:
		var area_data = exploration_areas.get(area_id, {})
		var req_level = area_data.get("level_requirement", 1)
		accessible.append({
			"id": area_id,
			"name": area_data.get("name", area_id),
			"description": area_data.get("description", ""),
			"level_requirement": req_level,
			"accessible": player_level >= req_level,
			"type": area_data.get("type", "dangerous"),
		})
	return accessible

func get_area_shader_params(area_id: String) -> Dictionary:
	var area_data = exploration_areas.get(area_id, {})
	return area_data.get("shader_params", {})

func get_rest_ambush_chance(area_id: String) -> float:
	var area_data = exploration_areas.get(area_id, {})
	return area_data.get("rest_ambush_chance", 0.0)
