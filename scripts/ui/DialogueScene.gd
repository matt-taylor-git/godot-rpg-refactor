extends Control

# DialogueScene - Displays dialogue with NPC choices and handles dialogue progression

@onready var npc_name_label = $DialoguePanel/VBoxContainer/NPCNameLabel
@onready var dialogue_text = $DialoguePanel/VBoxContainer/DialogueText
@onready var choices_container = $DialoguePanel/VBoxContainer/ChoicesContainer
@onready var continue_hint = $DialoguePanel/VBoxContainer/ContinueHint

var current_npc: String = ""
var choice_buttons: Array = []
var is_waiting_for_choice: bool = false

func _ready():
	print("DialogueScene initialized")
	
	# Connect to DialogueManager signals
	DialogueManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
	DialogueManager.connect("dialogue_updated", Callable(self, "_on_dialogue_updated"))
	DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if is_waiting_for_choice and choice_buttons.size() > 0:
			get_tree().root.set_input_as_handled()
			# Select first choice on space
			_on_choice_selected(0)

func start_dialogue(npc_id: String):
	current_npc = npc_id
	DialogueManager.start_dialogue(npc_id)

func _on_dialogue_started(npc_name: String):
	print("Dialogue started with: ", npc_name)
	npc_name_label.text = npc_name
	is_waiting_for_choice = false

func _on_dialogue_updated(text: String, options: Array):
	dialogue_text.text = text
	_update_choices(options)
	
	if options.is_empty():
		# No choices - auto continue after a delay
		is_waiting_for_choice = false
		continue_hint.text = "Click to continue..."
		await get_tree().create_timer(1.5).timeout
		if not DialogueManager.is_in_dialogue():
			return
		DialogueManager.select_option(0)
	else:
		is_waiting_for_choice = true
		continue_hint.text = "Select a response or press Space..."

func _update_choices(options: Array):
	# Clear previous choice buttons
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()
	
	# Create new choice buttons
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		button.text = option.get("text", "Continue")
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(Callable(self, "_on_choice_selected").bind(i))
		choices_container.add_child(button)
		choice_buttons.append(button)

func _on_choice_selected(option_index: int):
	is_waiting_for_choice = false
	_clear_choices()
	DialogueManager.select_option(option_index)

func _on_dialogue_ended():
	print("Dialogue ended")
	is_waiting_for_choice = false
	_clear_choices()
	dialogue_text.text = ""
	npc_name_label.text = ""
	
	# Return to previous scene
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _clear_choices():
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()

func _exit_tree():
	# Disconnect signals
	if DialogueManager.dialogue_started.is_connected(Callable(self, "_on_dialogue_started")):
		DialogueManager.disconnect("dialogue_started", Callable(self, "_on_dialogue_started"))
	if DialogueManager.dialogue_updated.is_connected(Callable(self, "_on_dialogue_updated")):
		DialogueManager.disconnect("dialogue_updated", Callable(self, "_on_dialogue_updated"))
	if DialogueManager.dialogue_ended.is_connected(Callable(self, "_on_dialogue_ended")):
		DialogueManager.disconnect("dialogue_ended", Callable(self, "_on_dialogue_ended"))
