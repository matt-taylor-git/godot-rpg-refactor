extends Node

# DialogueManager - Handles conversation trees and NPC dialogue
# Autoload singleton for dialogue system

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_updated(text: String, options: Array)

var dialogue_data: Dictionary = {}
var current_dialogue: Dictionary = {}
var current_options: Array = []

func _ready():
	print("DialogueManager initialized")
	load_dialogues()

func load_dialogues() -> void:
	# For now, create some sample dialogue data
	# In a real implementation, this would load from JSON files
	dialogue_data = {
		"village_elder": {
			"greeting": {
				"text": "Welcome, brave adventurer! What brings you to our village?",
				"options": [
					{"text": "I'm looking for quests.", "next": "quests"},
					{"text": "Tell me about this place.", "next": "about_village"},
					{"text": "Goodbye.", "action": "end"}
				]
			},
			"quests": {
				"text": "Ah, a hero in need of purpose! We have goblins troubling our farmers to the east.",
				"options": [
					{"text": "I'll help with the goblins.", "action": "accept_quest", "quest_type": "kill_goblins"},
					{"text": "That's too dangerous for me.", "next": "greeting"},
					{"text": "Goodbye.", "action": "end"}
				]
			},
			"about_village": {
				"text": "This is Eldridge Village, founded by our ancestors generations ago. We've lived in peace, until recently...",
				"options": [
					{"text": "What happened recently?", "next": "recent_events"},
					{"text": "Back to main topic.", "next": "greeting"}
				]
			},
			"recent_events": {
				"text": "Dark creatures have been appearing in the forests. Some say it's the work of an ancient evil awakening.",
				"options": [
					{"text": "I must investigate this.", "action": "accept_quest", "quest_type": "explore_cave"},
					{"text": "That's concerning.", "next": "greeting"}
				]
			}
		},
		"merchant": {
			"greeting": {
				"text": "Welcome to my shop! I have potions, weapons, and all manner of adventuring supplies.",
				"options": [
					{"text": "Show me your potions.", "action": "show_shop", "category": "potions"},
					{"text": "Show me weapons.", "action": "show_shop", "category": "weapons"},
					{"text": "Goodbye.", "action": "end"}
				]
			}
		},
		"knight_commander": {
			"greeting": {
				"text": "Hail, brave adventurer! I am Sir Aldric, Commander of the Royal Guard.",
				"options": [
					{"text": "Tell me about the dark threat.", "next": "dark_threat"},
					{"text": "I seek a worthy challenge.", "next": "challenge"},
					{"text": "Farewell.", "action": "end"}
				]
			},
			"dark_threat": {
				"text": "A great darkness has been stirring in the ancient crypt beneath the castle. We fear an ancient evil awakens.",
				"options": [
					{"text": "I will stop this evil.", "action": "accept_quest", "quest_type": "explore_cave"},
					{"text": "That is beyond my abilities.", "next": "greeting"},
					{"text": "Farewell.", "action": "end"}
				]
			},
			"challenge": {
				"text": "Hmmm, a warrior of spirit! Perhaps you are ready for the trials ahead.",
				"options": [
					{"text": "What trials?", "next": "dark_threat"},
					{"text": "Farewell.", "action": "end"}
				]
			}
		}
	}

func start_dialogue(npc_id: String) -> bool:
	if not dialogue_data.has(npc_id):
		return false

	current_dialogue = dialogue_data[npc_id]
	show_dialogue("greeting")
	emit_signal("dialogue_started", npc_id)
	return true

func show_dialogue(dialogue_key: String) -> void:
	if not current_dialogue.has(dialogue_key):
		end_dialogue()
		return

	var dialogue_entry = current_dialogue[dialogue_key]
	var text = dialogue_entry.get("text", "")
	var options = dialogue_entry.get("options", [])

	current_options = options
	emit_signal("dialogue_updated", text, options)

func select_option(option_index: int) -> void:
	if option_index < 0 or option_index >= current_options.size():
		return

	var option = current_options[option_index]

	if option.has("action"):
		handle_action(option.action, option)
	elif option.has("next"):
		show_dialogue(option.next)
	else:
		end_dialogue()

func handle_action(action: String, option_data: Dictionary) -> void:
	match action:
		"end":
			end_dialogue()
		"accept_quest":
			if option_data.has("quest_type"):
				var quest = QuestFactory.create_quest(option_data.quest_type, GameManager.get_player().level)
				QuestManager.accept_quest(quest)
				# Look for a quest_accepted dialogue node, otherwise end
				if current_dialogue.has("quest_accepted"):
					show_dialogue("quest_accepted")
				else:
					end_dialogue()
		"show_shop":
			# This would trigger shop UI
			end_dialogue()
		_:
			# Unknown action, continue
			end_dialogue()

func end_dialogue() -> void:
	current_dialogue.clear()
	current_options.clear()
	emit_signal("dialogue_ended")

func get_current_text() -> String:
	return current_dialogue.get("text", "")

func get_current_options() -> Array:
	return current_options

func is_in_dialogue() -> bool:
	return not current_dialogue.is_empty()
