extends Control

# QuestLogDialog - Displays active and completed quests with progress tracking

@onready var tab_bar = $Background/VBoxContainer/TabBar
@onready var quest_list = $Background/VBoxContainer/QuestContent/ScrollContainer/QuestList
@onready var empty_label = $Background/VBoxContainer/QuestContent/EmptyLabel
@onready var close_button = $Background/VBoxContainer/TitleBar/CloseButton

var current_tab = 0  # 0 = Active, 1 = Completed
var quest_items = {}  # Store quest UI items for easy updates

func _ready():
	print("QuestLogDialog initialized")
	
	# Connect to QuestManager signals
	QuestManager.connect("quest_accepted", Callable(self, "_on_quest_accepted"))
	QuestManager.connect("quest_completed", Callable(self, "_on_quest_completed"))
	QuestManager.connect("quest_progress_updated", Callable(self, "_on_quest_progress_updated"))
	
	_refresh_quest_list()

func _on_tab_changed(tab_index: int):
	current_tab = tab_index
	_refresh_quest_list()

func _refresh_quest_list():
	# Clear existing list
	for child in quest_list.get_children():
		child.queue_free()
	quest_items.clear()
	
	var quests = []
	if current_tab == 0:
		quests = QuestManager.get_active_quests()
	else:
		quests = QuestManager.get_completed_quests()
	
	if quests.is_empty():
		empty_label.show()
		return
	
	empty_label.hide()
	
	for quest in quests:
		_add_quest_item(quest)

func _add_quest_item(quest) -> Control:
	var quest_item = _create_quest_item_ui(quest)
	quest_list.add_child(quest_item)
	quest_items[quest.title] = quest_item
	return quest_item

func _create_quest_item_ui(quest) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(500, 0)
	
	# Quest title and reward
	var title_box = HBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = quest.title
	title_label.add_theme_font_size_override("font_size", 14)
	title_box.add_child(title_label)
	title_box.add_spacer(false)
	
	var reward_label = Label.new()
	reward_label.text = "EXP: +%d | Gold: +%d" % [quest.reward_exp, quest.reward_gold]
	reward_label.add_theme_color_override("font_color", Color.YELLOW)
	title_box.add_child(reward_label)
	
	container.add_child(title_box)
	
	# Description
	var description_label = Label.new()
	description_label.text = quest.description
	description_label.custom_minimum_size = Vector2(480, 0)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(description_label)
	
	# Progress bar (only for active quests)
	if current_tab == 0:
		var progress_box = HBoxContainer.new()
		progress_box.custom_minimum_size = Vector2(0, 30)
		
		var progress_label = Label.new()
		progress_label.text = "Progress: %d/%d" % [quest.current_count, quest.target_count]
		progress_label.custom_minimum_size = Vector2(120, 0)
		progress_box.add_child(progress_label)
		
		var progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = max(quest.target_count, 1)
		progress_bar.value = quest.current_count
		progress_bar.custom_minimum_size = Vector2(300, 20)
		progress_box.add_child(progress_bar)
		
		container.add_child(progress_box)
		
		# Store progress bar for updates
		quest_items[quest.title] = {
			"container": container,
			"progress_bar": progress_bar,
			"progress_label": progress_label
		}
	
	# Separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _on_quest_accepted(quest_title: String):
	if current_tab == 0:  # Only refresh if on active quests tab
		_refresh_quest_list()
	print("Quest accepted: ", quest_title)

func _on_quest_completed(quest_title: String):
	_refresh_quest_list()  # Refresh both tabs
	print("Quest completed: ", quest_title)

func _on_quest_progress_updated(quest_title: String, current: int, target: int):
	if current_tab != 0:  # Only update if on active quests tab
		return
	
	if quest_title in quest_items:
		var item = quest_items[quest_title]
		if item is Dictionary and item.has("progress_bar"):
			item["progress_bar"].value = current
			item["progress_label"].text = "Progress: %d/%d" % [current, target]

func _on_close_pressed():
	queue_free()

func _exit_tree():
	# Disconnect signals when dialog is closed
	QuestManager.disconnect("quest_accepted", Callable(self, "_on_quest_accepted"))
	QuestManager.disconnect("quest_completed", Callable(self, "_on_quest_completed"))
	QuestManager.disconnect("quest_progress_updated", Callable(self, "_on_quest_progress_updated"))
