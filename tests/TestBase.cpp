#include "TestBase.h"
#include <QDebug>

// Include model headers
#include "models/Item.h"
#include "models/Skill.h"

// Include test utilities
#include "TestUtils.h"

Player* TestBase::createTestPlayer(const QString& name,
                                 const QString& characterClass,
                                 int level,
                                 int gold)
{
    Player* player = new Player(name, characterClass);
    player->level = level;
    player->gold = gold;
    player->health = player->maxHealth; // Ensure full health

    addToCleanup(player);
    return player;
}

Monster* TestBase::createTestMonster(const QString& name,
                                   int level,
                                   int health)
{
    Monster* monster = new Monster(name, level);
    monster->health = health;
    monster->maxHealth = health;

    addToCleanup(monster);
    return monster;
}

Game* TestBase::createTestGame(const QString& playerName,
                              const QString& characterClass)
{
    Game* game = new Game(nullptr);
    game->newGame(playerName, characterClass);

    addToCleanup(game);
    return game;
}

Item* TestBase::createTestItem(const QString& itemName)
{
    Item* item = ItemFactory::createItem(itemName);
    if (item) {
        addToCleanup(item);
    }
    return item;
}

void TestBase::addToCleanup(void* obj)
{
    if (obj && !testObjects.contains(obj)) {
        testObjects.append(obj);
    }
}

void TestBase::cleanupTestObjects()
{
    for (void* obj : testObjects) {
        delete obj;
    }
    testObjects.clear();
}

void TestBase::cleanup()
{
    cleanupTestObjects();
}

// Enhanced test object creation using builders
Player* TestBase::createPlayerUsing(PlayerBuilder builder)
{
    Player* player = builder.build();
    addToCleanup(player);
    return player;
}

Monster* TestBase::createMonsterUsing(MonsterBuilder builder)
{
    Monster* monster = builder.build();
    addToCleanup(monster);
    return monster;
}

// Convenience methods using test fixtures
Player* TestBase::createBasicWarrior()
{
    Player* player = TestFixtures::createBasicWarrior();
    addToCleanup(player);
    return player;
}

Player* TestBase::createHighLevelWarrior()
{
    Player* player = TestFixtures::createHighLevelWarrior();
    addToCleanup(player);
    return player;
}

Player* TestBase::createLowHealthWarrior()
{
    Player* player = TestFixtures::createLowHealthWarrior();
    addToCleanup(player);
    return player;
}

Monster* TestBase::createWeakGoblin()
{
    Monster* monster = TestFixtures::createWeakGoblin();
    addToCleanup(monster);
    return monster;
}

Monster* TestBase::createStrongOrc()
{
    Monster* monster = TestFixtures::createStrongOrc();
    addToCleanup(monster);
    return monster;
}

Monster* TestBase::createBossMonster()
{
    Monster* monster = TestFixtures::createBossMonster();
    addToCleanup(monster);
    return monster;
}

// Mock creation
MockSaveManager* TestBase::createMockSaveManager()
{
    MockSaveManager* mock = new MockSaveManager();
    addToCleanup(mock);
    return mock;
}

MockSignalEmitter* TestBase::createMockSignalEmitter()
{
    MockSignalEmitter* emitter = new MockSignalEmitter();
    addToCleanup(emitter);
    return emitter;
}

// Signal testing
SignalTester* TestBase::createSignalTester(QObject* sender, const char* signal)
{
    SignalTester* tester = new SignalTester(sender, signal);
    addToCleanup(tester);
    return tester;
}
