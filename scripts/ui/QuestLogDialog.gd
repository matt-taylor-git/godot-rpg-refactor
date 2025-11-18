extends PanelContainer

# QuestLogDialog - Redesigned for new layout

@onready var tab_bar = $VBoxContainer/MainContent/QuestListContainer/TabBar
@onready var quest_list = $VBoxContainer/MainContent/QuestListContainer/QuestList
@onready var quest_title = $VBoxContainer/MainContent/QuestDetailsContainer/QuestTitle
@onready var quest_description = $VBoxContainer/MainContent/QuestDetailsContainer/QuestDescription
@onready var quest_objectives = $VBoxContainer/MainContent/QuestDetailsContainer/QuestObjectives
@onready var quest_rewards = $VBoxContainer/MainContent/QuestDetailsContainer/QuestRewards

var current_tab = 0  # 0 = Active, 1 = Completed
var quests = []

func _ready():
    print("QuestLogDialog ready")
    QuestManager.connect("quest_accepted", Callable(self, "_on_quest_updated"))
    QuestManager.connect("quest_completed", Callable(self, "_on_quest_updated"))
    QuestManager.connect("quest_progress_updated", Callable(self, "_on_quest_updated"))
    _refresh_quest_list()
    _clear_quest_details()

func _on_tab_changed(tab_index: int):
    current_tab = tab_index
    _refresh_quest_list()
    _clear_quest_details()

func _refresh_quest_list():
    quest_list.clear()
    if current_tab == 0:
        quests = QuestManager.get_active_quests()
    else:
        quests = QuestManager.get_completed_quests()

    for quest in quests:
        quest_list.add_item(quest.title)

func _on_quest_selected(index: int):
    var selected_quest = quests[index]
    quest_title.text = selected_quest.title
    quest_description.text = selected_quest.description
    quest_objectives.text = "Objectives: %d/%d" % [selected_quest.current_count, selected_quest.target_count]
    quest_rewards.text = "Rewards: %d EXP, %d Gold" % [selected_quest.reward_exp, selected_quest.reward_gold]

func _clear_quest_details():
    quest_title.text = "Select a Quest"
    quest_description.text = ""
    quest_objectives.text = ""
    quest_rewards.text = ""

func _on_quest_updated(quest_title: String, current: int = 0, target: int = 0):
    _refresh_quest_list()
    _clear_quest_details()

func _on_close_pressed():
    queue_free()

func _exit_tree():
    QuestManager.disconnect("quest_accepted", Callable(self, "_on_quest_updated"))
    QuestManager.disconnect("quest_completed", Callable(self, "_on_quest_updated"))
    QuestManager.disconnect("quest_progress_updated", Callable(self, "_on_quest_updated"))