extends Control

# QuestLogDialog - Active/Completed tabs with auto-select and objective checklist

var current_tab = 0  # 0 = Active, 1 = Completed
var quests = []

@onready var dialog_panel = $DialogPanel
@onready var tab_bar = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestListContainer/TabBar")
@onready var quest_list = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestListContainer/QuestList")
@onready var quest_title = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestDetailsContainer/VBoxContainer/QuestTitle")
@onready var quest_description = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestDetailsContainer/VBoxContainer/QuestDescription")
@onready var quest_objectives = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestDetailsContainer/VBoxContainer/QuestObjectives")
@onready var quest_rewards = get_node(
	"DialogPanel/MarginContainer/VBoxContainer/MainContent/QuestDetailsContainer/VBoxContainer/QuestRewards")
@onready var close_button = $DialogPanel/MarginContainer/VBoxContainer/CloseButton


func _ready():
	print("QuestLogDialog ready")
	UIDialogShell.apply_to(self, dialog_panel, UIDialogShell.AnimStyle.SCALE)
	QuestManager.connect("quest_accepted", Callable(self, "_on_quest_updated"))
	QuestManager.connect("quest_completed", Callable(self, "_on_quest_updated"))
	QuestManager.connect("quest_progress_updated", Callable(self, "_on_quest_updated"))
	if tab_bar and not tab_bar.tab_changed.is_connected(_on_tab_changed):
		tab_bar.tab_changed.connect(_on_tab_changed)
	if quest_list and not quest_list.item_selected.is_connected(_on_quest_selected):
		quest_list.item_selected.connect(_on_quest_selected)
	_refresh_quest_list()
	_setup_focus_navigation()


func _setup_focus_navigation():
	tab_bar.set("focus_neighbor_bottom", quest_list.get_path())
	tab_bar.set("focus_neighbor_top", close_button.get_path())
	quest_list.set("focus_neighbor_top", tab_bar.get_path())
	quest_list.set("focus_neighbor_bottom", close_button.get_path())
	close_button.set("focus_neighbor_top", quest_list.get_path())
	close_button.set("focus_neighbor_bottom", tab_bar.get_path())
	tab_bar.grab_focus()


func _on_tab_changed(tab_index: int):
	current_tab = tab_index
	_refresh_quest_list()


func _refresh_quest_list():
	quest_list.clear()
	if current_tab == 0:
		quests = QuestManager.get_active_quests()
	else:
		quests = QuestManager.get_completed_quests()

	for quest in quests:
		var row = "%s (%d/%d)" % [quest.title, quest.current_count, quest.target_count]
		if quest.completed or quest.is_completed():
			row = "✓ " + quest.title
		quest_list.add_item(row)

	if quests.size() > 0:
		quest_list.select(0)
		_on_quest_selected(0)
	else:
		_clear_quest_details()


func _on_quest_selected(index: int):
	if index < 0 or index >= quests.size():
		return
	var selected_quest = quests[index]
	quest_title.text = selected_quest.title
	quest_title.add_theme_color_override(
		"font_color", UIThemeManager.get_color("title_gold"))
	quest_description.text = selected_quest.description
	quest_objectives.text = _format_objectives(selected_quest)
	quest_rewards.text = "Rewards: %d EXP, %d Gold" % [
		selected_quest.reward_exp, selected_quest.reward_gold]


func _format_objectives(quest) -> String:
	var lines: PackedStringArray = []
	lines.append("Objectives:")
	var done = quest.current_count >= quest.target_count or quest.completed
	var mark = "✓" if done else "○"
	var progress = "%s %s (%d/%d)" % [
		mark, quest.description, quest.current_count, quest.target_count]
	lines.append(progress)
	if done:
		lines.append("✓ All objectives complete")
	return "\n".join(lines)


func _clear_quest_details():
	quest_title.text = "No quests"
	quest_description.text = "Accept a quest from the town quest giver."
	quest_objectives.text = ""
	quest_rewards.text = ""


func _on_quest_updated(_quest_title: String, _current: int = 0, _target: int = 0):
	_refresh_quest_list()


func _on_close_pressed():
	UIDialogShell.play_close_and_free(self, dialog_panel)


func _exit_tree():
	if QuestManager.quest_accepted.is_connected(Callable(self, "_on_quest_updated")):
		QuestManager.disconnect("quest_accepted", Callable(self, "_on_quest_updated"))
	if QuestManager.quest_completed.is_connected(Callable(self, "_on_quest_updated")):
		QuestManager.disconnect("quest_completed", Callable(self, "_on_quest_updated"))
	if QuestManager.quest_progress_updated.is_connected(Callable(self, "_on_quest_updated")):
		QuestManager.disconnect("quest_progress_updated", Callable(self, "_on_quest_updated"))
