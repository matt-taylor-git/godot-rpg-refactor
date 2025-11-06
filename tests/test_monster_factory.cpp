#include <QTest>
#include <QObject>
#include "game/factories/MonsterFactory.h"
#include "game/factories/MonsterTypeRegistry.h"
#include "models/Monster.h"
#include "models/FinalBoss.h"

class TestMonsterFactory : public QObject
{
    Q_OBJECT

private slots:
    void testCreateShadowWolf();
    void testCreateShadowLord();
    void testCreateDarkOverlord();
    void testMonsterTypeValidation();
    void testBackwardCompatibility();
    void testCreateExistingMonsters();
    void testCreateFinalBossWithCustomName();
};

void TestMonsterFactory::testCreateShadowWolf()
{
    // Test creating Shadow Wolf monster
    Monster* shadowWolf = MonsterFactory::createMonster("Shadow Wolf", 5);
    QVERIFY(shadowWolf != nullptr);
    QVERIFY(shadowWolf->name == "Shadow Wolf");
    QVERIFY(shadowWolf->enemyType == "wolf");
    delete shadowWolf;

    // Test lowercase version
    Monster* shadowWolfLower = MonsterFactory::createMonster("shadow_wolf", 5);
    QVERIFY(shadowWolfLower != nullptr);
    QVERIFY(shadowWolfLower->name == "Shadow Wolf");
    delete shadowWolfLower;
}

void TestMonsterFactory::testCreateShadowLord()
{
    // Test creating Shadow Lord boss
    Monster* shadowLord = MonsterFactory::createBoss(10, "Shadow Lord");
    QVERIFY(shadowLord != nullptr);
    QVERIFY(shadowLord->name == "Shadow Lord");
    QVERIFY(shadowLord->enemyType == "boss");

    // Verify boss stats
    QVERIFY(shadowLord->health > 150);
    QVERIFY(shadowLord->attack > 15);
    QVERIFY(shadowLord->expReward > 100);

    delete shadowLord;

    // Test lowercase version
    Monster* shadowLordLower = MonsterFactory::createBoss(10, "shadow_lord");
    QVERIFY(shadowLordLower != nullptr);
    QVERIFY(shadowLordLower->name == "Shadow Lord");
    delete shadowLordLower;
}

void TestMonsterFactory::testCreateDarkOverlord()
{
    // Test creating Dark Overlord final boss
    FinalBoss* darkOverlord = MonsterFactory::createFinalBoss(15, "Dark Overlord");
    QVERIFY(darkOverlord != nullptr);
    QVERIFY(darkOverlord->name == "Dark Overlord");
    QVERIFY(darkOverlord->enemyType == "final_boss");

    // Verify final boss stats are higher than normal
    QVERIFY(darkOverlord->health > 500);
    QVERIFY(darkOverlord->attack > 30);

    delete darkOverlord;
}

void TestMonsterFactory::testMonsterTypeValidation()
{
    // Test valid monster types
    QVERIFY(MonsterFactory::isValidMonsterType("Shadow Wolf"));
    QVERIFY(MonsterFactory::isValidMonsterType("shadow_wolf"));
    QVERIFY(MonsterFactory::isValidMonsterType("Shadow Lord"));
    QVERIFY(MonsterFactory::isValidMonsterType("Dark Overlord"));

    // Test invalid monster types
    QVERIFY(!MonsterFactory::isValidMonsterType("Invalid Monster"));
    QVERIFY(!MonsterFactory::isValidMonsterType(""));

    // Test existing monsters are still valid
    QVERIFY(MonsterFactory::isValidMonsterType("Goblin"));
    QVERIFY(MonsterFactory::isValidMonsterType("Orc"));
    QVERIFY(MonsterFactory::isValidMonsterType("Wild Wolf"));

    // Test getting all valid types
    QStringList validTypes = MonsterFactory::getAllValidMonsterTypes();
    QVERIFY(validTypes.contains("shadow_wolf"));
    QVERIFY(validTypes.contains("shadow_lord"));
    QVERIFY(validTypes.contains("dark_overlord"));
    QVERIFY(!validTypes.isEmpty());
}

void TestMonsterFactory::testBackwardCompatibility()
{
    // Test that old monster names still create monsters
    Monster* wildWolf = MonsterFactory::createMonster("Wolf", 5);
    QVERIFY(wildWolf != nullptr);
    QVERIFY(wildWolf->name == "Wild Wolf");
    delete wildWolf;

    // Test orc chieftain boss
    Monster* orcChieftain = MonsterFactory::createBoss(10);
    QVERIFY(orcChieftain != nullptr);
    QVERIFY(orcChieftain->name == "Orc Chieftain");
    delete orcChieftain;

    // Test eternal shadow final boss (default)
    FinalBoss* eternalShadow = MonsterFactory::createFinalBoss(15);
    QVERIFY(eternalShadow != nullptr);
    QVERIFY(eternalShadow->name == "The Eternal Shadow");
    delete eternalShadow;

    // Test eternal shadow final boss (explicit)
    FinalBoss* eternalShadowExplicit = MonsterFactory::createFinalBoss(15, "The Eternal Shadow");
    QVERIFY(eternalShadowExplicit != nullptr);
    QVERIFY(eternalShadowExplicit->name == "The Eternal Shadow");
    delete eternalShadowExplicit;
}

void TestMonsterFactory::testCreateExistingMonsters()
{
    // Ensure existing monsters still work correctly
    Monster* goblin = MonsterFactory::createMonster("Goblin", 5);
    QVERIFY(goblin != nullptr);
    QVERIFY(goblin->name == "Goblin");
    delete goblin;

    Monster* orc = MonsterFactory::createMonster("Orc", 5);
    QVERIFY(orc != nullptr);
    QVERIFY(orc->name == "Orc");
    delete orc;

    Monster* golem = MonsterFactory::createMonster("Golem", 5);
    QVERIFY(golem != nullptr);
    QVERIFY(golem->name == "Stone Golem");
    delete golem;

    Monster* skeleton = MonsterFactory::createMonster("Skeleton", 5);
    QVERIFY(skeleton != nullptr);
    QVERIFY(skeleton->name == "Skeleton Warrior");
    delete skeleton;

    Monster* bandit = MonsterFactory::createMonster("Bandit", 5);
    QVERIFY(bandit != nullptr);
    QVERIFY(bandit->name == "Bandit");
    delete bandit;

    Monster* spider = MonsterFactory::createMonster("Spider", 5);
    QVERIFY(spider != nullptr);
    QVERIFY(spider->name == "Giant Spider");
    delete spider;

    Monster* slime = MonsterFactory::createMonster("Slime", 5);
    QVERIFY(slime != nullptr);
    QVERIFY(slime->name == "Slime");
    delete slime;
}

void TestMonsterFactory::testCreateFinalBossWithCustomName()
{
    // Test default final boss
    FinalBoss* defaultBoss = MonsterFactory::createFinalBoss(15);
    QVERIFY(defaultBoss != nullptr);
    QVERIFY(defaultBoss->name == "The Eternal Shadow");
    delete defaultBoss;

    // Test custom named final boss
    FinalBoss* customBoss = MonsterFactory::createFinalBoss(15, "Custom Boss Name");
    QVERIFY(customBoss != nullptr);
    QVERIFY(customBoss->name == "Custom Boss Name");
    delete customBoss;

    // Test quest-specific final boss name
    FinalBoss* questBoss = MonsterFactory::createFinalBoss(15, "Dark Overlord");
    QVERIFY(questBoss != nullptr);
    QVERIFY(questBoss->name == "Dark Overlord");
    delete questBoss;
}

QTEST_MAIN(TestMonsterFactory)
#include "test_monster_factory.moc"
