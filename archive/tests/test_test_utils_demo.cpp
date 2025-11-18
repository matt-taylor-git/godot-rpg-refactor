#include <QTest>
#include <QSignalSpy>
#include "TestBase.h"

class TestTestUtilsDemo : public TestBase
{
    Q_OBJECT

private slots:
    void testPlayerBuilder();
    void testMonsterBuilder();
    void testMockSaveManager();
    void testSignalTester();
    void testTestFixtures();
};

void TestTestUtilsDemo::testPlayerBuilder()
{
    // Test fluent builder pattern for Player
    Player* player = PlayerBuilder()
        .withName("TestHero")
        .withClass("Warrior")
        .withLevel(5)
        .withGold(500)
        .withHealth(100)
        .build();

    QCOMPARE(player->name, QString("TestHero"));
    QCOMPARE(player->characterClass, QString("Warrior"));
    QCOMPARE(player->level, 5);
    QCOMPARE(player->gold, 500);
    QCOMPARE(player->health, 100);
}

void TestTestUtilsDemo::testMonsterBuilder()
{
    // Test fluent builder pattern for Monster
    Monster* monster = MonsterBuilder()
        .withName("TestDragon")
        .withLevel(10)
        .withHealth(200)
        .withAttack(30)
        .withDefense(15)
        .withExpReward(100)
        .withGoldReward(200)
        .build();

    QCOMPARE(monster->name, QString("TestDragon"));
    QCOMPARE(monster->level, 10);
    QCOMPARE(monster->health, 200);
    QCOMPARE(monster->attack, 30);
    QCOMPARE(monster->defense, 15);
    QCOMPARE(monster->expReward, 100);
    QCOMPARE(monster->goldReward, 200);
}

void TestTestUtilsDemo::testMockSaveManager()
{
    // Test mock SaveManager
    MockSaveManager* mock = createMockSaveManager();

    // Configure mock behavior
    mock->setSaveShouldSucceed(true);
    mock->setLoadShouldSucceed(false);

    // Test save operation
    Player* player = createBasicWarrior();
    bool saveResult = mock->saveGame(player, "test.save");
    QVERIFY(saveResult);
    QCOMPARE(mock->getSaveCallCount(), 1);

    // Test load operation (should fail as configured)
    Player* loadedPlayer = mock->loadGame("test.save");
    QVERIFY(loadedPlayer == nullptr);
    QCOMPARE(mock->getLoadCallCount(), 1);
}

void TestTestUtilsDemo::testSignalTester()
{
    // Test signal testing utilities
    MockSignalEmitter* emitter = createMockSignalEmitter();
    SignalTester* tester = createSignalTester(emitter, SIGNAL(combatEnded(bool)));

    // Emit signal
    emitter->emitCombatEnded(true);

    // Verify signal was emitted
    QCOMPARE(tester->signalCount(), 1);
    QCOMPARE(tester->lastSignalArguments().at(0).toBool(), true);
}

void TestTestUtilsDemo::testTestFixtures()
{
    // Test predefined fixtures
    Player* warrior = createBasicWarrior();
    QCOMPARE(warrior->characterClass, QString("Warrior"));
    QCOMPARE(warrior->level, 1);

    Monster* goblin = createWeakGoblin();
    QCOMPARE(goblin->name, QString("Weak Goblin"));
    QVERIFY(goblin->health <= 50);

    // Test scenario setup
    Game* game = createTestGame();
    TestFixtures::setupVictoryScenario(game);

    // Verify the setup worked
    QVERIFY(game->getPlayer() != nullptr);
    QVERIFY(game->getCurrentMonster() != nullptr);
    QVERIFY(game->isInCombat());
}

QTEST_MAIN(TestTestUtilsDemo)
#include "test_test_utils_demo.moc"
