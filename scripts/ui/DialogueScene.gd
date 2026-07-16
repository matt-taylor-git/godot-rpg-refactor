extends Control

# DialogueScene - Typewriter dialogue with portraits and themed choices

const UI_BUTTON_SCENE = preload("res://scenes/components/ui_button.tscn")
const CHARS_PER_SECOND := 36.0

var current_npc: String = ""
var choice_buttons: Array = []
var is_waiting_for_choice: bool = false
var is_waiting_for_continue: bool = false
var full_text: String = ""
var typewriter_index: int = 0
var typewriter_active: bool = false
var typewriter_timer: float = 0.0
var pending_options: Array = []
var hint_tween: Tween = null
var panel_tween: Tween = null
var reduced_motion: bool = false

@onready var dialogue_panel = $DialoguePanel
@onready var portrait_image: TextureRect = $DialoguePanel/MarginContainer/HBoxContainer/PortraitPanel/PortraitImage
@onready var npc_name_label = $DialoguePanel/MarginContainer/HBoxContainer/TextColumn/NPCNameLabel
@onready var dialogue_text = $DialoguePanel/MarginContainer/HBoxContainer/TextColumn/DialogueText
@onready var choices_container = $DialoguePanel/MarginContainer/HBoxContainer/TextColumn/ChoicesContainer
@onready var continue_hint = $DialoguePanel/MarginContainer/HBoxContainer/TextColumn/ContinueHint


func _ready():
	print("DialogueScene initialized")
	reduced_motion = ProjectSettings.get_setting("accessibility/reduced_motion", false)

	if npc_name_label:
		npc_name_label.add_theme_color_override(
			"font_color", UIThemeManager.get_color("title_gold"))
		npc_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		npc_name_label.add_theme_constant_override("shadow_offset_x", 1)
		npc_name_label.add_theme_constant_override("shadow_offset_y", 1)

	DialogueManager.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
	DialogueManager.connect("dialogue_updated", Callable(self, "_on_dialogue_updated"))
	DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

	_animate_panel_in()


func _process(delta: float) -> void:
	if not typewriter_active:
		return
	typewriter_timer += delta
	var advance := int(typewriter_timer * CHARS_PER_SECOND)
	if advance <= 0:
		return
	typewriter_timer = 0.0
	typewriter_index = mini(typewriter_index + advance, full_text.length())
	dialogue_text.text = full_text.substr(0, typewriter_index)
	if typewriter_index >= full_text.length():
		_finish_typewriter()


func _input(event: InputEvent):
	var clicked: bool = false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		clicked = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	var space: bool = false
	if event is InputEventKey:
		var kb := event as InputEventKey
		space = kb.pressed and kb.keycode == KEY_SPACE
	var accept: bool = event.is_action_pressed("ui_accept")

	if not (clicked or space or accept):
		return

	if typewriter_active:
		get_viewport().set_input_as_handled()
		_skip_typewriter()
		return

	if is_waiting_for_continue:
		get_viewport().set_input_as_handled()
		is_waiting_for_continue = false
		if DialogueManager.is_in_dialogue():
			DialogueManager.select_option(0)
		return

	if is_waiting_for_choice and choice_buttons.size() > 0 and space:
		var focused = get_viewport().gui_get_focus_owner()
		if focused not in choice_buttons:
			get_viewport().set_input_as_handled()
			_on_choice_selected(0)


func start_dialogue(npc_id: String):
	current_npc = npc_id
	if portrait_image:
		portrait_image.texture = PortraitLookup.get_npc_texture(npc_id)
	DialogueManager.start_dialogue(npc_id)


func _animate_panel_in() -> void:
	if not dialogue_panel:
		return
	if reduced_motion:
		dialogue_panel.modulate.a = 1.0
		return
	var start_y = dialogue_panel.position.y + 40.0
	var end_y = dialogue_panel.position.y
	dialogue_panel.modulate.a = 0.0
	dialogue_panel.position.y = start_y
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()
	panel_tween = create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.3)
	panel_tween.tween_property(dialogue_panel, "position:y", end_y, 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel_tween.finished.connect(func():
		if panel_tween:
			panel_tween.kill()
			panel_tween = null
	)


func _on_dialogue_started(npc_name: String):
	print("Dialogue started with: ", npc_name)
	# Prefer friendly display name; fall back to id
	var display := npc_name.replace("_", " ").capitalize()
	if npc_name_label:
		npc_name_label.text = display
	is_waiting_for_choice = false
	is_waiting_for_continue = false


func _on_dialogue_updated(text: String, options: Array):
	full_text = text
	pending_options = options
	_clear_choices()
	is_waiting_for_choice = false
	is_waiting_for_continue = false
	_stop_hint_pulse()

	if reduced_motion:
		dialogue_text.text = full_text
		_finish_typewriter()
	else:
		typewriter_index = 0
		typewriter_timer = 0.0
		dialogue_text.text = ""
		typewriter_active = true
		continue_hint.text = "Click or Space to skip..."
		continue_hint.visible = true


func _skip_typewriter() -> void:
	if not typewriter_active:
		return
	typewriter_index = full_text.length()
	dialogue_text.text = full_text
	_finish_typewriter()


func _finish_typewriter() -> void:
	typewriter_active = false
	dialogue_text.text = full_text

	if pending_options.is_empty():
		is_waiting_for_continue = true
		continue_hint.text = "Click or Space to continue..."
		continue_hint.visible = true
		_start_hint_pulse()
	else:
		is_waiting_for_choice = true
		continue_hint.text = "Select a response..."
		continue_hint.visible = true
		_update_choices(pending_options)
		_start_hint_pulse()


func _update_choices(options: Array):
	_clear_choices()

	for i in range(options.size()):
		var option = options[i]
		var button = UI_BUTTON_SCENE.instantiate()
		button.text = option.get("text", "Continue")
		button.custom_minimum_size = Vector2(0, 40)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(Callable(self, "_on_choice_selected").bind(i))
		if not reduced_motion:
			button.modulate.a = 0.0
		choices_container.add_child(button)
		choice_buttons.append(button)

	# Staggered fade-in
	if not reduced_motion:
		for i in range(choice_buttons.size()):
			var btn = choice_buttons[i]
			var tween = create_tween()
			tween.tween_interval(0.05 * i)
			tween.tween_property(btn, "modulate:a", 1.0, 0.2)
			tween.finished.connect(func(): tween.kill())

	for i in range(choice_buttons.size()):
		var prev_idx = (i - 1 + choice_buttons.size()) % choice_buttons.size()
		var next_idx = (i + 1) % choice_buttons.size()
		choice_buttons[i].set("focus_neighbor_top", choice_buttons[prev_idx].get_path())
		choice_buttons[i].set("focus_neighbor_bottom", choice_buttons[next_idx].get_path())

	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()


func _on_choice_selected(option_index: int):
	is_waiting_for_choice = false
	is_waiting_for_continue = false
	_stop_hint_pulse()
	_clear_choices()
	DialogueManager.select_option(option_index)


func _on_dialogue_ended():
	print("Dialogue ended")
	is_waiting_for_choice = false
	is_waiting_for_continue = false
	typewriter_active = false
	_stop_hint_pulse()
	_clear_choices()
	if dialogue_text:
		dialogue_text.text = ""
	if npc_name_label:
		npc_name_label.text = ""

	await get_tree().create_timer(0.35).timeout
	queue_free()


func _clear_choices():
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	choice_buttons.clear()


func _start_hint_pulse() -> void:
	_stop_hint_pulse()
	if reduced_motion or not continue_hint:
		return
	continue_hint.modulate.a = 1.0
	hint_tween = create_tween()
	hint_tween.set_loops()
	hint_tween.tween_property(continue_hint, "modulate:a", 0.35, 0.7)
	hint_tween.tween_property(continue_hint, "modulate:a", 1.0, 0.7)


func _stop_hint_pulse() -> void:
	if hint_tween and hint_tween.is_valid():
		hint_tween.kill()
	hint_tween = null
	if continue_hint:
		continue_hint.modulate.a = 1.0


func _exit_tree():
	_stop_hint_pulse()
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()
	if DialogueManager.dialogue_started.is_connected(Callable(self, "_on_dialogue_started")):
		DialogueManager.disconnect("dialogue_started", Callable(self, "_on_dialogue_started"))
	if DialogueManager.dialogue_updated.is_connected(Callable(self, "_on_dialogue_updated")):
		DialogueManager.disconnect("dialogue_updated", Callable(self, "_on_dialogue_updated"))
	if DialogueManager.dialogue_ended.is_connected(Callable(self, "_on_dialogue_ended")):
		DialogueManager.disconnect("dialogue_ended", Callable(self, "_on_dialogue_ended"))
