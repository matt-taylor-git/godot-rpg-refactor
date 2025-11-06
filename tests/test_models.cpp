#include <QTest>
#include <QSignalSpy>
#include "TestBase.h"

class TestModels : public TestBase
{
    Q_OBJECT

private slots:
    void testPlayerCreation();
    void testMonsterCreation();
    void testItemFactory();
    void testCombatVictory();
    void testCombatDefeat();
};

void TestModels::testPlayerCreation()
{
    Player player("Hero");
    QCOMPARE(player.name, QString("Hero"));
    QCOMPARE(player.level, 1);
    QCOMPARE(player.health, 100);
    QCOMPARE(player.gold, 100);
}

void TestModels::testMonsterCreation()
{
    Monster monster("Goblin", 5);
    QCOMPARE(monster.name, QString("Goblin"));
    QCOMPARE(monster.level, 5);
    QVERIFY(monster.health > 50);
}

void TestModels::testItemFactory()
{
    QMap<QString, Item*> shopItems = ItemFactory::getShopItems();
    QVERIFY(shopItems.contains("Health Potion"));
    QCOMPARE(shopItems["Health Potion"]->value, 25);
    qDeleteAll(shopItems);
}

void TestModels::testCombatVictory()
{
    Game* game = createTestGame("TestHero");

    // Create a weak monster for easy victory
    Monster* weakMonster = createTestMonster("Weakling", 1, 1); // Very low health
    weakMonster->expReward = 10;
    weakMonster->goldReward = 10;

    // Manually set up combat (normally done by startCombat)
    game->player->health = 100;
    game->currentMonster = weakMonster;
    game->combatActive = true;

    QSignalSpy spy(game, &Game::combatEnded);

    // Attack should kill the monster
    QString result = game->playerAttack();

    QVERIFY(result.contains("defeated"));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.at(0).at(0).toBool(), true); // playerWon should be true
    QVERIFY(!game->combatActive);
    QCOMPARE(game->player->experience, 10);
    QCOMPARE(game->player->gold, 110); // Started with 100 + 10 reward
}

void TestModels::testCombatDefeat()
{
    Game* game = createTestGame("TestHero");

    // Create a monster that will kill the player
    Monster* strongMonster = createTestMonster("Boss", 10, 100);
    strongMonster->attack = 200; // Very high damage

    // Manually set up combat
    game->player->health = 1; // Player almost dead
    game->currentMonster = strongMonster;
    game->combatActive = true;

    QSignalSpy spy(game, &Game::combatEnded);

    // Monster attack should kill the player
    QString result = game->monsterAttack();

    QVERIFY(result.contains("defeated"));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.at(0).at(0).toBool(), false); // playerWon should be false
    QVERIFY(!game->combatActive);
    QCOMPARE(game->player->health, 0);
}

QTEST_MAIN(TestModels)
#include "test_models.moc"
