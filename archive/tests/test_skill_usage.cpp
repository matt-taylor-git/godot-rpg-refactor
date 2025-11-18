#include <QTest>
#include <QSignalSpy>
#include "TestBase.h"
#include "../src/game/factories/SkillFactory.h"
#include "../src/components/SkillSelectionDialog.h"

class TestSkillUsage : public TestBase
{
    Q_OBJECT

private slots:
    void testSkillUsage();
    void testSkillUsageWithFinalBoss();
};

void TestSkillUsage::testSkillUsage()
{
    Game* game = createTestGame("TestHero");

    // Start combat to set up a monster
    game->startCombat();

    Monster* monster = game->getCurrentMonster();
    QVERIFY(monster != nullptr);

    // Test using the first skill
    Player* player = game->getPlayer();
    QVERIFY(!player->skills.isEmpty());

    Skill* skill = player->skills.first();
    QVERIFY(skill != nullptr);

    // Ensure player has enough mana
    player->mana = skill->manaCost + 10;
    int originalMana = player->mana;
    int originalMonsterHealth = monster->health;

    // Use the skill
    QString result = game->playerUseSkill(skill);
    QVERIFY(!result.isEmpty());

    // Check that mana was deducted
    QCOMPARE(player->mana, originalMana - skill->manaCost);

    // Check that monster took damage (assuming physical or magic skill)
    if (skill->skillType == "physical" || skill->skillType == "magic") {
        QVERIFY(monster->health < originalMonsterHealth);
    }
}

void TestSkillUsage::testSkillUsageWithFinalBoss()
{
    Game* game = createTestGame("TestHero");
    game->getPlayer()->level = 25; // High level to access final boss

    // Start final boss combat
    game->startFinalBossCombat();

    Monster* monster = game->getCurrentMonster();
    QVERIFY(monster != nullptr);

    // Test using the first skill
    Player* player = game->getPlayer();
    QVERIFY(!player->skills.isEmpty());

    Skill* skill = player->skills.first();
    QVERIFY(skill != nullptr);

    // Ensure player has enough mana
    player->mana = skill->manaCost + 10;
    int originalMana = player->mana;
    int originalMonsterHealth = monster->health;

    // Use the skill
    QString result = game->playerUseSkill(skill);
    QVERIFY(!result.isEmpty());

    // Check that mana was deducted
    QCOMPARE(player->mana, originalMana - skill->manaCost);

    // Check that monster took damage (assuming physical or magic skill)
    if (skill->skillType == "physical" || skill->skillType == "magic") {
        QVERIFY(monster->health < originalMonsterHealth);
    }
}

QTEST_MAIN(TestSkillUsage)
#include "test_skill_usage.moc"
