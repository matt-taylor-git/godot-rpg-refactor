extends Control

# CodexDialog - Displays unlocked lore entries organized by category

var categories: Array = []
var current_category: String = ""
var category_entry_buttons: Dictionary = {}
var selected_entry: Dictionary = {}

@onready var category_tabs = $DialogPanel/MarginContainer/VBoxContainer/CategoryTabs
@onready var entry_buttons = $DialogPanel/MarginContainer/VBoxContainer/Content/EntryList/EntryButtons
@onready var entry_title = $DialogPanel/MarginContainer/VBoxContainer/Content/EntryContent/VBoxContainer/EntryTitle
@onready var entry_text = $DialogPanel/MarginContainer/VBoxContainer/Content/EntryContent/VBoxContainer/EntryText
@onready var stats_label = $DialogPanel/MarginContainer/VBoxContainer/Stats
@onready var close_button = $DialogPanel/MarginContainer/VBoxContainer/TitleBar/CloseButton

func _ready():
	print("CodexDialog initialized")

	# Connect to CodexManager signals
	CodexManager.connect("lore_entry_unlocked", Callable(self, "_on_lore_entry_unlocked"))
	CodexManager.connect("codex_updated", Callable(self, "_on_codex_updated"))

	_setup_categories()
	_update_display()
	_setup_focus_navigation()

func _setup_focus_navigation():
	# Vertical chain: CategoryTabs -> entry buttons -> CloseButton
	category_tabs.set("focus_neighbor_bottom", entry_buttons.get_path())
	category_tabs.set("focus_neighbor_top", close_button.get_path())

	close_button.set("focus_neighbor_bottom", category_tabs.get_path())

	# Connect close button up to the last entry button or category tabs
	var buttons = entry_buttons.get_children()
	if buttons.size() > 0 and buttons[0] is Button:
		close_button.set("focus_neighbor_top", buttons[buttons.size() - 1].get_path())
	else:
		close_button.set("focus_neighbor_top", category_tabs.get_path())

	category_tabs.grab_focus()

func _setup_categories():
	# Get all unique categories from all lore entries
	var all_categories = []
	for entry_id in CodexManager.lore_entries:
		var category = CodexManager.lore_entries[entry_id].get("category", "")
		if category and category not in all_categories:
			all_categories.append(category)

	all_categories.sort()
	categories = all_categories

	# Setup category tabs
	category_tabs.clear_tabs()
	for i in range(categories.size()):
		category_tabs.add_tab(categories[i].capitalize())

	if categories.size() > 0:
		current_category = categories[0]
		category_tabs.current_tab = 0

func _update_display():
	_refresh_entry_list()
	_update_stats()

func _refresh_entry_list():
	# Clear previous buttons
	for button in entry_buttons.get_children():
		button.queue_free()
	category_entry_buttons.clear()

	# Get entries for current category
	var entries = CodexManager.get_entries_by_category(current_category)

	if entries.is_empty():
		var label = Label.new()
		label.text = "No entries in this category"
		entry_buttons.add_child(label)
		_clear_entry_display()
		return

	# Create buttons for each entry
	var buttons: Array[Button] = []
	for entry in entries:
		var button = Button.new()
		button.text = entry.get("title", "Unknown")
		button.custom_minimum_size = Vector2(0, 35)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(Callable(self, "_on_entry_selected").bind(entry))
		entry_buttons.add_child(button)
		category_entry_buttons[entry.get("id")] = button
		buttons.append(button)

	# Setup vertical focus chain among entry buttons
	for i in range(buttons.size()):
		var prev_idx = (i - 1 + buttons.size()) % buttons.size()
		var next_idx = (i + 1) % buttons.size()
		buttons[i].set("focus_neighbor_top", buttons[prev_idx].get_path())
		buttons[i].set("focus_neighbor_bottom", buttons[next_idx].get_path())

	# Connect first entry to category_tabs (top), last entry to close_button (bottom)
	if buttons.size() > 0:
		buttons[0].set("focus_neighbor_top", category_tabs.get_path())
		buttons[buttons.size() - 1].set("focus_neighbor_bottom", close_button.get_path())
		category_tabs.set("focus_neighbor_bottom", buttons[0].get_path())
		close_button.set("focus_neighbor_top", buttons[buttons.size() - 1].get_path())

func _on_entry_selected(entry: Dictionary):
	selected_entry = entry
	_display_entry(entry)

func _display_entry(entry: Dictionary):
	entry_title.text = entry.get("title", "Unknown")
	entry_text.text = entry.get("content", "No content available.")

func _clear_entry_display():
	entry_title.text = "Select an entry"
	entry_text.text = "No entry selected"
	selected_entry.clear()

func _update_stats():
	var total_entries = CodexManager.lore_entries.size()
	var unlocked_entries = CodexManager.get_unlocked_entries().size()
	stats_label.text = "Entries discovered: %d/%d" % [unlocked_entries, total_entries]

func _on_category_changed(tab_index: int):
	if tab_index >= 0 and tab_index < categories.size():
		current_category = categories[tab_index]
		_refresh_entry_list()

func _on_lore_entry_unlocked(_entry_id: String, entry_title: String):
	print("New lore unlocked: ", entry_title)
	_update_display()

func _on_codex_updated():
	_update_display()

func _on_close_pressed():
	queue_free()

func _exit_tree():
	# Disconnect signals
	if CodexManager.lore_entry_unlocked.is_connected(Callable(self, "_on_lore_entry_unlocked")):
		CodexManager.disconnect("lore_entry_unlocked", Callable(self, "_on_lore_entry_unlocked"))
	if CodexManager.codex_updated.is_connected(Callable(self, "_on_codex_updated")):
		CodexManager.disconnect("codex_updated", Callable(self, "_on_codex_updated"))
