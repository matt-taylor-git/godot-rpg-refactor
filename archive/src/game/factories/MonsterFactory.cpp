#include "MonsterFactory.h"
#include "MonsterTypeRegistry.h"
#include <QRandomGenerator>
#include <QStringList>

Monster* MonsterFactory::createMonster(const QString &monsterType, int playerLevel)
{
    int level = playerLevel + QRandomGenerator::global()->bounded(-1, 2); // ±1 level variation
    if (level < 1) level = 1;

    if (monsterType == "Goblin" || monsterType == "goblin") {
        Monster* m = new Monster("Goblin", level, "goblin");
        m->health = 40 + (level * 10);
        m->maxHealth = m->health;
        m->attack = 6 + (level * 2);
        m->defense = 2 + level;
        m->expReward = level * 20;
        m->goldReward = level * 8;
        return m;
    }
    else if (monsterType == "Orc" || monsterType == "orc") {
        Monster* m = new Monster("Orc", level, "orc");
        m->health = 60 + (level * 15);
        m->maxHealth = m->health;
        m->attack = 10 + (level * 3);
        m->defense = 5 + (level * 2);
        m->expReward = level * 30;
        m->goldReward = level * 12;
        return m;
    }
    else if (monsterType == "Golem" || monsterType == "golem") {
        Monster* m = new Monster("Stone Golem", level, "golem");
        m->health = 80 + (level * 20);
        m->maxHealth = m->health;
        m->attack = 8 + (level * 2);
        m->defense = 10 + (level * 3);
        m->expReward = level * 35;
        m->goldReward = level * 10;
        return m;
    }
    else if (monsterType == "Skeleton") {
        Monster* m = new Monster("Skeleton Warrior", level, "skeleton");
        m->health = 50 + (level * 12);
        m->maxHealth = m->health;
        m->attack = 8 + (level * 2);
        m->defense = 3 + level;
        m->expReward = level * 25;
        m->goldReward = level * 15;
        return m;
    }
    else if (monsterType == "Bandit") {
        Monster* m = new Monster("Bandit", level, "bandit");
        m->health = 45 + (level * 11);
        m->maxHealth = m->health;
        m->attack = 9 + (level * 2);
        m->defense = 4 + level;
        m->expReward = level * 22;
        m->goldReward = level * 20; // Bandits drop more gold
        return m;
    }
    else if (monsterType == "Wolf") {
        Monster* m = new Monster("Wild Wolf", level, "wolf");
        m->health = 35 + (level * 9);
        m->maxHealth = m->health;
        m->attack = 7 + (level * 2);
        m->defense = 2 + level;
        m->expReward = level * 18;
        m->goldReward = level * 5;
        return m;
    }
    else if (monsterType == "Spider") {
        Monster* m = new Monster("Giant Spider", level, "spider");
        m->health = 30 + (level * 8);
        m->maxHealth = m->health;
        m->attack = 6 + (level * 2);
        m->defense = 1 + level;
        m->magicAttack = 4 + level;
        m->expReward = level * 20;
        m->goldReward = level * 6;
        return m;
    }
    else if (monsterType == "Slime") {
        Monster* m = new Monster("Slime", level, "slime");
        m->health = 25 + (level * 10);
        m->maxHealth = m->health;
        m->attack = 4 + level;
        m->defense = 8 + (level * 2); // High defense, low attack
        m->expReward = level * 15;
        m->goldReward = level * 4;
        return m;
    }
    else if (monsterType == "Shadow Wolf" || monsterType == "shadow_wolf") {
        Monster* m = new Monster("Shadow Wolf", level, "wolf");
        m->health = 35 + (level * 9);
        m->maxHealth = m->health;
        m->attack = 7 + (level * 2);
        m->defense = 2 + level;
        m->expReward = level * 18;
        m->goldReward = level * 5;
        return m;
    }

    // Default fallback
    return new Monster("Unknown Beast", level, "unknown");
}

Monster* MonsterFactory::createRandomMonster(int playerLevel)
{
    QStringList commonMonsters = {"Goblin", "Wolf", "Slime", "Spider"};
    QStringList uncommonMonsters = {"Bandit", "Skeleton", "Orc"};
    QStringList rareMonsters = {"Golem"};

    int roll = QRandomGenerator::global()->bounded(100);

    QString monsterType;
    if (roll < 60) {
        // 60% common
        monsterType = commonMonsters.at(QRandomGenerator::global()->bounded(commonMonsters.size()));
    }
    else if (roll < 90) {
        // 30% uncommon
        monsterType = uncommonMonsters.at(QRandomGenerator::global()->bounded(uncommonMonsters.size()));
    }
    else {
        // 10% rare
        monsterType = rareMonsters.at(QRandomGenerator::global()->bounded(rareMonsters.size()));
    }

    return createMonster(monsterType, playerLevel);
}

Monster* MonsterFactory::createBoss(int playerLevel, const QString &bossType)
{
    int bossLevel = playerLevel + 2;

    // Support quest-specific boss
    if (bossType == "Shadow Lord" || bossType == "shadow_lord") {
        Monster* boss = new Monster("Shadow Lord", bossLevel, "boss");
        boss->health = 150 + (bossLevel * 30);
        boss->maxHealth = boss->health;
        boss->attack = 15 + (bossLevel * 4);
        boss->defense = 10 + (bossLevel * 3);
        boss->magicAttack = 8 + (bossLevel * 2);
        boss->expReward = bossLevel * 100;
        boss->goldReward = bossLevel * 50;
        return boss;
    }

    // Default to existing behavior
    Monster* boss = new Monster("Orc Chieftain", bossLevel, "boss");
    boss->health = 150 + (bossLevel * 30);
    boss->maxHealth = boss->health;
    boss->attack = 15 + (bossLevel * 4);
    boss->defense = 10 + (bossLevel * 3);
    boss->magicAttack = 8 + (bossLevel * 2);
    boss->expReward = bossLevel * 100;
    boss->goldReward = bossLevel * 50;
    return boss;
}

FinalBoss* MonsterFactory::createFinalBoss(int playerLevel, const QString &bossType)
{
    QString finalBossName = "The Eternal Shadow";
    if (!bossType.isEmpty()) {
        finalBossName = bossType;
    }
    return new FinalBoss(playerLevel, finalBossName);
}

// Validation implementation
bool MonsterFactory::isValidMonsterType(const QString &monsterType)
{
    return MonsterTypeRegistry::isValidMonsterType(monsterType);
}

QStringList MonsterFactory::getAllValidMonsterTypes()
{
    return MonsterTypeRegistry::getAllValidTypeNames();
}
