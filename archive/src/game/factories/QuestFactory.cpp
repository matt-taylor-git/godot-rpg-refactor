#include "QuestFactory.h"

Quest* QuestFactory::createQuest(const QString &questId)
{
    // Quest 1: A Dark Omen (Level 1 - Introductory quest)
    if (questId == "main_quest_01") {
        Quest* quest = new Quest("main_quest_01", "A Dark Omen",
            "Strange shadows have been spotted near the village.", "available", 1);
        quest->longDescription = "Your first quest! The village elder needs your help. Shadow Wolves "
                                 "have been seen prowling near the village outskirts. This is a "
                                 "perfect opportunity to test your combat skills. Defeat 3 Shadow Wolves "
                                 "to protect the village and earn your first rewards.";
        quest->orderIndex = 1;

        // Objective: Kill 3 Shadow Wolves
        QuestObjective obj1;
        obj1.type = "kill_enemies";
        obj1.description = "Defeat 3 Shadow Wolves";
        obj1.targetId = "Shadow Wolf";
        obj1.required = 3;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Rewards
        quest->rewards.experience = 100;
        quest->rewards.gold = 50;
        quest->rewards.itemNames.append("Healing Potion");

        return quest;
    }

    // Quest 2: The Whispering Woods (Level 3)
    else if (questId == "main_quest_02") {
        Quest* quest = new Quest("main_quest_02", "The Whispering Woods",
            "Whispers echo from the dark forest. Investigate the source.", "locked", 3);
        quest->longDescription = "The elder warns of ancient whispers emanating from the deep woods. "
                                 "Grow stronger and venture into the forest to uncover the mystery.";
        quest->orderIndex = 2;
        quest->prerequisiteQuestIds.append("main_quest_01");

        // Objective 1: Reach level 5
        QuestObjective obj1;
        obj1.type = "reach_level";
        obj1.description = "Reach level 5";
        obj1.targetId = "";
        obj1.required = 5;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Objective 2: Collect Shadow Shards
        QuestObjective obj2;
        obj2.type = "collect_item";
        obj2.description = "Collect 3 Shadow Shards";
        obj2.targetId = "Shadow Shard";
        obj2.required = 3;
        obj2.current = 0;
        obj2.completed = false;
        quest->objectives.append(obj2);

        // Rewards
        quest->rewards.experience = 250;
        quest->rewards.gold = 100;
        quest->rewards.itemNames.append("Steel Sword");

        return quest;
    }

    // Quest 3: Shadows Deepen (Level 5 - Mini-boss)
    else if (questId == "main_quest_03") {
        Quest* quest = new Quest("main_quest_03", "Shadows Deepen",
            "A powerful shadow creature emerges from the depths.", "locked", 5);
        quest->longDescription = "The whispers have grown louder. A Shadow Lord has appeared, "
                                 "commanding the lesser shadow creatures. You must defeat this "
                                 "powerful foe to restore peace to the region.";
        quest->orderIndex = 3;
        quest->prerequisiteQuestIds.append("main_quest_02");

        // Objective: Defeat Shadow Lord
        QuestObjective obj1;
        obj1.type = "defeat_boss";
        obj1.description = "Defeat the Shadow Lord";
        obj1.targetId = "Shadow Lord";
        obj1.required = 1;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Rewards
        quest->rewards.experience = 500;
        quest->rewards.gold = 200;
        quest->rewards.itemNames.append("Shadow Cloak");
        quest->rewards.itemNames.append("Greater Healing Potion");

        return quest;
    }

    // Quest 4: The Scholar's Warning (Level 7)
    else if (questId == "main_quest_04") {
        Quest* quest = new Quest("main_quest_04", "The Scholar's Warning",
            "A traveling scholar brings dire news from the capital.", "locked", 7);
        quest->longDescription = "With the Shadow Lord defeated, a mysterious scholar arrives with "
                                 "ancient texts warning of a greater darkness. He needs your help "
                                 "recovering a lost tome.";
        quest->orderIndex = 4;
        quest->prerequisiteQuestIds.append("main_quest_03");

        // Objective: Collect Ancient Tome
        QuestObjective obj1;
        obj1.type = "collect_item";
        obj1.description = "Recover the Ancient Tome";
        obj1.targetId = "Ancient Tome";
        obj1.required = 1;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Rewards
        quest->rewards.experience = 350;
        quest->rewards.gold = 150;
        quest->rewards.itemNames.append("Mana Potion");

        return quest;
    }

    // Quest 5: Gathering Strength (Level 10)
    else if (questId == "main_quest_05") {
        Quest* quest = new Quest("main_quest_05", "Gathering Strength",
            "Prepare for the battles ahead by growing stronger.", "locked", 10);
        quest->longDescription = "The ancient texts speak of a final confrontation. You must grow "
                                 "stronger and obtain better equipment before facing the ultimate "
                                 "darkness that threatens the realm.";
        quest->orderIndex = 5;
        quest->prerequisiteQuestIds.append("main_quest_04");

        // Objective 1: Reach level 12
        QuestObjective obj1;
        obj1.type = "reach_level";
        obj1.description = "Reach level 12";
        obj1.targetId = "";
        obj1.required = 12;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Objective 2: Obtain rare equipment
        QuestObjective obj2;
        obj2.type = "collect_item";
        obj2.description = "Obtain a Legendary weapon";
        obj2.targetId = "Legendary Sword";
        obj2.required = 1;
        obj2.current = 0;
        obj2.completed = false;
        quest->objectives.append(obj2);

        // Rewards
        quest->rewards.experience = 750;
        quest->rewards.gold = 300;
        quest->rewards.itemNames.append("Dragon Scale Armor");

        return quest;
    }

    // Quest 6: The Final Darkness (Level 15)
    else if (questId == "main_quest_06") {
        Quest* quest = new Quest("main_quest_06", "The Final Darkness",
            "Confront the source of the shadow plague.", "locked", 15);
        quest->longDescription = "The time has come. The ancient evil that has been corrupting "
                                 "the land has been located. You must face the Dark Overlord and "
                                 "end this threat once and for all.";
        quest->orderIndex = 6;
        quest->prerequisiteQuestIds.append("main_quest_05");

        // Objective: Defeat Dark Overlord
        QuestObjective obj1;
        obj1.type = "defeat_boss";
        obj1.description = "Defeat the Dark Overlord";
        obj1.targetId = "Dark Overlord";
        obj1.required = 1;
        obj1.current = 0;
        obj1.completed = false;
        quest->objectives.append(obj1);

        // Rewards
        quest->rewards.experience = 1000;
        quest->rewards.gold = 500;
        quest->rewards.itemNames.append("Hero's Crown");
        quest->rewards.itemNames.append("Ultimate Healing Potion");

        return quest;
    }

    // Quest not found
    return nullptr;
}

QList<Quest*> QuestFactory::getAllMainQuests()
{
    QList<Quest*> quests;

    // Create all main story quests
    quests.append(createQuest("main_quest_01"));
    quests.append(createQuest("main_quest_02"));
    quests.append(createQuest("main_quest_03"));
    quests.append(createQuest("main_quest_04"));
    quests.append(createQuest("main_quest_05"));
    quests.append(createQuest("main_quest_06"));

    return quests;
}

QList<Quest*> QuestFactory::getAvailableQuests(Player* player)
{
    if (!player) {
        return QList<Quest*>();
    }

    QList<Quest*> available;
    QList<Quest*> allQuests = getAllMainQuests();

    for (Quest* quest : allQuests) {
        // Check if player meets level requirement
        if (player->level >= quest->minimumLevel) {
            // Check if prerequisites are met
            if (checkPrerequisites(quest, player)) {
                available.append(quest);
            } else {
                delete quest; // Clean up if not available
            }
        } else {
            delete quest; // Clean up if level requirement not met
        }
    }

    return available;
}

bool QuestFactory::checkPrerequisites(const Quest* quest, Player* player)
{
    if (!quest || !player) {
        return false;
    }

    // If no prerequisites, quest is available
    if (quest->prerequisiteQuestIds.isEmpty()) {
        return true;
    }

    // Check if all prerequisite quests are completed
    for (const QString &prereqId : quest->prerequisiteQuestIds) {
        Quest* prereqQuest = player->getQuest(prereqId);
        if (!prereqQuest || !prereqQuest->isComplete()) {
            return false;
        }
    }

    return true;
}
