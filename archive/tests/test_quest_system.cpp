#include <QtTest>
#include "../src/game/QuestManager.h"
#include "../src/game/factories/MonsterFactory.h"
#include "../src/models/Player.h"
#include "../src/models/Quest.h"

class TestQuestSystem : public QObject
{
    Q_OBJECT

private slots:
    void testQuestManagerCreation();
    void testQuestAcceptance();
    void testQuestProgression();
    void testQuestCompletion();
    void testCombatEventHandling();
    void testLevelUpEventHandling();
    void testQuest1ShadowWolfCompletion();
    void testQuest3ShadowLordCompletion();
    void testQuest6DarkOverlordCompletion();
};

void TestQuestSystem::testQuestManagerCreation()
{
    Player player("Hero", "Warrior");
    QuestManager manager(&player);

    manager.loadQuests();

    // Should have loaded quest definitions
    QList<Quest*> available = manager.getAvailableQuests();
    QList<Quest*> locked = manager.getLockedQuests();

    QVERIFY(available.size() > 0 || locked.size() > 0);
}

void TestQuestSystem::testQuestAcceptance()
{
    Player player("Hero", "Warrior");
    QuestManager manager(&player);
    manager.loadQuests();

    // Find an available quest
    QList<Quest*> available = manager.getAvailableQuests();
    if (available.isEmpty()) {
        QSKIP("No available quests to test");
    }

    QString questId = available.first()->questId;

    // Accept quest
    bool accepted = manager.acceptQuest(questId);
    QVERIFY(accepted);

    // Verify it's now active
    QList<Quest*> activeQuests = manager.getActiveQuests();
    bool found = false;
    for (Quest* q : activeQuests) {
        if (q && q->questId == questId) {
            found = true;
            QCOMPARE(q->status, QString("active"));
            break;
        }
    }
    QVERIFY(found);
}

void TestQuestSystem::testQuestProgression()
{
    Player player("Hero", "Warrior");
    QuestManager manager(&player);

    // Create a simple quest and add it to the player
    Quest* quest = new Quest("test_quest", "Test");
    quest->status = "active";

    QuestObjective obj;
    obj.type = "kill_enemies";
    obj.targetId = "Goblin";
    obj.required = 3;
    obj.current = 0;
    obj.completed = false;
    quest->objectives.append(obj);

    player.addQuest(quest);

    // Get the quest from player to verify
    Quest* playerQuest = player.getQuest("test_quest");
    QVERIFY(playerQuest != nullptr);

    // Directly update the player's quest (QuestManager methods require quest to be in manager's map)
    playerQuest->updateObjective(0, 1);
    QCOMPARE(playerQuest->objectives[0].current, 1);
    QVERIFY(!playerQuest->objectives[0].completed);

    playerQuest->updateObjective(0, 2);
    QCOMPARE(playerQuest->objectives[0].current, 3);
    QVERIFY(playerQuest->objectives[0].completed);
}

void TestQuestSystem::testQuestCompletion()
{
    Player player("Hero", "Warrior");
    player.level = 1;  // Ensure player meets requirements
    QuestManager manager(&player);
    manager.loadQuests();  // Load quest definitions

    // Accept the first available quest
    QList<Quest*> available = manager.getAvailableQuests();
    if (available.isEmpty()) {
        QSKIP("No quests available for completion test");
    }

    QString questId = available.first()->questId;
    manager.acceptQuest(questId);

    Quest* playerQuest = player.getQuest(questId);
    QVERIFY(playerQuest != nullptr);

    int initialExp = player.experience;
    int initialGold = player.gold;

    // Complete all objectives manually
    for (int i = 0; i < playerQuest->objectives.size(); ++i) {
        playerQuest->objectives[i].current = playerQuest->objectives[i].required;
        playerQuest->objectives[i].completed = true;
    }

    // Complete quest via manager
    QSignalSpy spy(&manager, &QuestManager::questCompleted);
    manager.completeQuest(questId);

    // Verify completion signal
    QCOMPARE(spy.count(), 1);

    // Verify rewards given (should have increased)
    QVERIFY(player.experience > initialExp);
    QVERIFY(player.gold > initialGold);

    // Verify status changed
    QCOMPARE(playerQuest->status, QString("completed"));
}

void TestQuestSystem::testCombatEventHandling()
{
    Player player("Hero", "Warrior");
    player.level = 1;
    QuestManager manager(&player);
    manager.loadQuests();

    // Accept the first main quest which has Shadow Wolf objective
    manager.acceptQuest("main_quest_01");

    Quest* playerQuest = player.getQuest("main_quest_01");
    QVERIFY(playerQuest != nullptr);

    int initialCurrent = playerQuest->objectives[0].current;

    // Simulate combat end
    manager.onCombatEnd("Shadow Wolf");
    QCOMPARE(playerQuest->objectives[0].current, initialCurrent + 1);

    manager.onCombatEnd("Shadow Wolf");
    QCOMPARE(playerQuest->objectives[0].current, initialCurrent + 2);

    manager.onCombatEnd("Shadow Wolf");
    QCOMPARE(playerQuest->objectives[0].current, initialCurrent + 3);
}

void TestQuestSystem::testLevelUpEventHandling()
{
    Player player("Hero", "Warrior");
    player.level = 3;  // Start at level 3
    QuestManager manager(&player);
    manager.loadQuests();

    // Accept quest with level objective (main_quest_02 requires reaching level 5)
    bool accepted = manager.acceptQuest("main_quest_02");
    if (!accepted) {
        QSKIP("Quest 2 not available");
    }

    Quest* playerQuest = player.getQuest("main_quest_02");
    QVERIFY(playerQuest != nullptr);

    // Find the level objective
    int levelObjIndex = -1;
    for (int i = 0; i < playerQuest->objectives.size(); ++i) {
        if (playerQuest->objectives[i].type == "reach_level") {
            levelObjIndex = i;
            break;
        }
    }

    if (levelObjIndex < 0) {
        QSKIP("Quest doesn't have level objective");
    }

    // Simulate level up
    player.level = 5;
    manager.onLevelUp(5);

    QVERIFY(playerQuest->objectives[levelObjIndex].completed);
    QCOMPARE(playerQuest->objectives[levelObjIndex].current, 5);
}

QTEST_MAIN(TestQuestSystem)
#include "test_quest_system.moc"

void TestQuestSystem::testQuest1ShadowWolfCompletion()
{
    // Test Quest 1 "A Dark Omen" - defeat 3 Shadow Wolves
    Player player("Hero", "Warrior");
    player.level = 1;
    QuestManager manager(&player);
    manager.loadQuests();

    // Accept Quest 1
    manager.acceptQuest("main_quest_01");

    Quest* playerQuest = player.getQuest("main_quest_01");
    QVERIFY(playerQuest != nullptr);

    // Verify the objective is to kill Shadow Wolves
    QVERIFY(playerQuest->objectives[0].targetId == "Shadow Wolf");
    QVERIFY(playerQuest->objectives[0].required == 3);

    // Create Shadow Wolf using MonsterFactory and simulate combat
    Monster* shadowWolf = MonsterFactory::createMonster("Shadow Wolf", 1);
    QVERIFY(shadowWolf != nullptr);
    QVERIFY(shadowWolf->name == "Shadow Wolf");

    // Simulate defeating 3 Shadow Wolves
    for (int i = 0; i < 3; i++) {
        manager.onCombatEnd(shadowWolf->name);
    }

    // Verify quest completed
    QVERIFY(playerQuest->objectives[0].completed);
    delete shadowWolf;
}

void TestQuestSystem::testQuest3ShadowLordCompletion()
{
    // Test Quest 3 "Shadows Deepen" - defeat Shadow Lord
    Player player("Hero", "Warrior");
    player.level = 5;  // Quest 3 requires level 5
    QuestManager manager(&player);
    manager.loadQuests();

    // Complete Quest 2 to unlock Quest 3
    Quest* quest2 = manager.getQuestById("main_quest_02");
    if (quest2) {
        quest2->status = "completed";
    }

    // Accept Quest 3
    bool accepted = manager.acceptQuest("main_quest_03");
    if (!accepted) {
        QSKIP("Quest 3 not available - prerequisites not met");
    }

    Quest* playerQuest = player.getQuest("main_quest_03");
    QVERIFY(playerQuest != nullptr);

    // Verify the objective is to defeat Shadow Lord
    QVERIFY(playerQuest->objectives[0].targetId == "Shadow Lord");

    // Create Shadow Lord using MonsterFactory
    Monster* shadowLord = MonsterFactory::createBoss(5, "Shadow Lord");
    QVERIFY(shadowLord != nullptr);
    QVERIFY(shadowLord->name == "Shadow Lord");
    QVERIFY(shadowLord->enemyType == "boss");

    // Simulate defeating Shadow Lord
    manager.onCombatEnd(shadowLord->name);

    // Verify quest completed
    QVERIFY(playerQuest->objectives[0].completed);
    delete shadowLord;
}

void TestQuestSystem::testQuest6DarkOverlordCompletion()
{
    // Test Quest 6 "The Final Darkness" - defeat Dark Overlord
    Player player("Hero", "Warrior");
    player.level = 15;  // Quest 6 requires level 15
    QuestManager manager(&player);
    manager.loadQuests();

    // Complete all prerequisite quests to unlock Quest 6
    QStringList prereqs = {"main_quest_01", "main_quest_02", "main_quest_03", "main_quest_04", "main_quest_05"};
    for (const QString& questId : prereqs) {
        Quest* quest = manager.getQuestById(questId);
        if (quest) {
            quest->status = "completed";
        }
    }

    // Accept Quest 6
    bool accepted = manager.acceptQuest("main_quest_06");
    if (!accepted) {
        QSKIP("Quest 6 not available - prerequisites not met");
    }

    Quest* playerQuest = player.getQuest("main_quest_06");
    QVERIFY(playerQuest != nullptr);

    // Verify the objective is to defeat Dark Overlord
    QVERIFY(playerQuest->objectives[0].targetId == "Dark Overlord");

    // Create Dark Overlord using MonsterFactory
    FinalBoss* darkOverlord = MonsterFactory::createFinalBoss(15, "Dark Overlord");
    QVERIFY(darkOverlord != nullptr);
    QVERIFY(darkOverlord->name == "Dark Overlord");
    QVERIFY(darkOverlord->enemyType == "final_boss");

    // Simulate defeating Dark Overlord
    manager.onCombatEnd(darkOverlord->name);

    // Verify quest completed
    QVERIFY(playerQuest->objectives[0].completed);
    delete darkOverlord;
}


