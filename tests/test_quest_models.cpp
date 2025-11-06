#include <QtTest>
#include "../src/models/Quest.h"
#include "../src/models/Player.h"
#include "../src/game/factories/QuestFactory.h"

class TestQuestModels : public QObject
{
    Q_OBJECT

private slots:
    void testQuestConstruction();
    void testQuestObjectiveProgress();
    void testQuestSerialization();
    void testQuestFactory();
    void testPlayerQuestIntegration();
};

void TestQuestModels::testQuestConstruction()
{
    Quest quest("quest_01", "Test Quest", "A test quest", "available", 1);

    QCOMPARE(quest.questId, QString("quest_01"));
    QCOMPARE(quest.title, QString("Test Quest"));
    QCOMPARE(quest.status, QString("available"));
    QCOMPARE(quest.minimumLevel, 1);
    QVERIFY(quest.isAvailable());
    QVERIFY(!quest.isActive());
    QVERIFY(!quest.isComplete());
}

void TestQuestModels::testQuestObjectiveProgress()
{
    Quest quest("quest_01", "Kill Quest");

    // Add objective
    QuestObjective obj;
    obj.type = "kill_enemies";
    obj.description = "Kill 5 enemies";
    obj.targetId = "goblin";
    obj.required = 5;
    obj.current = 0;
    obj.completed = false;
    quest.objectives.append(obj);

    QCOMPARE(quest.getTotalObjectives(), 1);
    QCOMPARE(quest.getProgress(), 0);

    // Update progress
    quest.updateObjective(0, 3);
    QCOMPARE(quest.objectives[0].current, 3);
    QVERIFY(!quest.objectives[0].completed);

    // Complete objective
    quest.updateObjective(0, 2);
    QCOMPARE(quest.objectives[0].current, 5);
    QVERIFY(quest.objectives[0].completed);
    QCOMPARE(quest.getProgress(), 1);
}

void TestQuestModels::testQuestSerialization()
{
    // Create quest with objectives and rewards
    Quest original("quest_01", "Test Quest");
    original.status = "active";
    original.minimumLevel = 5;

    QuestObjective obj;
    obj.type = "kill_enemies";
    obj.description = "Kill 3 enemies";
    obj.targetId = "goblin";
    obj.required = 3;
    obj.current = 2;
    obj.completed = false;
    original.objectives.append(obj);

    original.rewards.experience = 100;
    original.rewards.gold = 50;
    original.rewards.itemNames.append("Sword");

    // Serialize
    QByteArray buffer;
    QDataStream out(&buffer, QIODevice::WriteOnly);
    out << original;

    // Deserialize
    QDataStream in(&buffer, QIODevice::ReadOnly);
    Quest loaded;
    in >> loaded;

    // Verify
    QCOMPARE(loaded.questId, original.questId);
    QCOMPARE(loaded.title, original.title);
    QCOMPARE(loaded.status, original.status);
    QCOMPARE(loaded.minimumLevel, original.minimumLevel);
    QCOMPARE(loaded.objectives.size(), 1);
    QCOMPARE(loaded.objectives[0].type, obj.type);
    QCOMPARE(loaded.objectives[0].current, 2);
    QCOMPARE(loaded.rewards.experience, 100);
    QCOMPARE(loaded.rewards.gold, 50);
    QCOMPARE(loaded.rewards.itemNames.size(), 1);
}

void TestQuestModels::testQuestFactory()
{
    // Test creating specific quest
    Quest* quest1 = QuestFactory::createQuest("main_quest_01");
    QVERIFY(quest1 != nullptr);
    QCOMPARE(quest1->questId, QString("main_quest_01"));
    QCOMPARE(quest1->title, QString("A Dark Omen"));
    QVERIFY(!quest1->objectives.isEmpty());
    delete quest1;

    // Test getting all quests
    QList<Quest*> allQuests = QuestFactory::getAllMainQuests();
    QVERIFY(allQuests.size() >= 5);  // Should have at least 5 main quests
    qDeleteAll(allQuests);
}

void TestQuestModels::testPlayerQuestIntegration()
{
    Player player("Hero", "Warrior");

    // Add quest to player
    Quest* quest = new Quest("quest_01", "Test Quest");
    quest->status = "active";
    player.addQuest(quest);

    QCOMPARE(player.quests.size(), 1);

    // Get quest by ID
    Quest* found = player.getQuest("quest_01");
    QVERIFY(found != nullptr);
    QCOMPARE(found->questId, QString("quest_01"));

    // Get active quests
    QList<Quest*> activeQuests = player.getActiveQuests();
    QCOMPARE(activeQuests.size(), 1);

    // Complete quest
    quest->status = "completed";
    QList<Quest*> completedQuests = player.getCompletedQuests();
    QCOMPARE(completedQuests.size(), 1);

    activeQuests = player.getActiveQuests();
    QCOMPARE(activeQuests.size(), 0);
}

QTEST_MAIN(TestQuestModels)
#include "test_quest_models.moc"
