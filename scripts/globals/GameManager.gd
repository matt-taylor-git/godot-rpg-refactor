extends Node

# GameManager - Global game state and scene management
# Autoload singleton for managing overall game state

signal game_started
signal game_loaded
signal scene_changed(scene_name)

var current_scene: String = ""
var game_data = {}

func _ready():
	print("GameManager initialized")
	# Initialize basic game state
	game_data = {
		"player": null,
		"current_scene": "main_menu",
		"save_slots": {}
	}

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
			"current_scene": game_data.current_scene
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
