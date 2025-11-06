#include "Player.h"
#include <algorithm>
#include <QDebug>

Player::Player(const QString &name, const QString &characterClass)
    : Character(name, 1, 100, 100), // Base stats for a new player
      characterClass(characterClass),
      mana(50),
      maxMana(50),
      strength(12),
      dexterity(10),
      intelligence(8),
      vitality(10),
      gold(100),
      experience(0),
      experienceToLevel(100),
      skillPoints(0),
      statPoints(0)
{
    // Adjust stats based on class
    if (characterClass == "Warrior" || characterClass == "warrior") {
        strength = 16;
        vitality = 14;
        intelligence = 6;
        maxHealth = 120;
        health = 120;
    }
    else if (characterClass == "Mage" || characterClass == "mage") {
        intelligence = 16;
        strength = 8;
        dexterity = 8;
        maxMana = 80;
        mana = 80;
    }
    else if (characterClass == "Rogue" || characterClass == "rogue") {
        dexterity = 16;
        strength = 12;
        vitality = 8;
        maxHealth = 90;
        health = 90;
    }

    // Initialize equipment with nullptrs
    equipment["weapon"] = nullptr;
    equipment["armor"] = nullptr;
    equipment["accessory"] = nullptr;
}

Player::~Player()
{
    // Clean up dynamically allocated memory to prevent memory leaks
    qDeleteAll(skills);
    skills.clear();

    qDeleteAll(quests);
    quests.clear();

    qDeleteAll(inventory);
    inventory.clear();

    qDeleteAll(equipment.values());
    equipment.clear();
}

QDataStream &operator<<(QDataStream &out, const Player &p)
{
    // Version 5: Added game completion tracking
    out << quint32(5);

    // Serialize base class
    out << static_cast<const Character&>(p);
    // Serialize Player members
    out << p.characterClass;
    out << p.mana << p.maxMana << p.strength << p.dexterity << p.intelligence << p.vitality;
    out << p.gold << p.experience << p.experienceToLevel << p.skillPoints << p.statPoints;

    // Serialize equipment: only non-null items
    QMap<QString, Item> eq;
    for (auto it = p.equipment.begin(); it != p.equipment.end(); ++it) {
        if (it.value() != nullptr) {
            eq[it.key()] = *it.value();
        }
    }
    out << eq;

    // Serialize inventory
    QList<Item> inv;
    for (Item* item : p.inventory) {
        if (item != nullptr) {
            inv.append(*item);
        }
    }
    out << inv;

    // Serialize skills
    QList<Skill> skillList;
    for (Skill* skill : p.skills) {
        if (skill != nullptr) {
            skillList.append(*skill);
        }
    }
    out << skillList;

    // Serialize quests (version 3+)
    QList<Quest> questList;
    for (Quest* quest : p.quests) {
        if (quest != nullptr) {
            questList.append(*quest);
        }
    }
    out << questList;

    // Serialize narrative tracking (version 4+)
    out << p.viewedDialogueIds;
    out << p.viewedEventIds;
    out << p.unlockedLoreEntries;

    // Serialize game completion tracking (version 5+)
    out << p.hasDefeatedFinalBoss;
    out << p.gameCompletionTime;
    out << p.finalGameLevel;

    return out;
}

QDataStream &operator>>(QDataStream &in, Player &p)
{
    // Read version number
    quint32 version = 1;
    quint32 possibleVersion;
    in >> possibleVersion;

    // Check if this is a version number or old format data
    // Version numbers will be small (1, 2, 3...), old Character data will be large
    if (possibleVersion <= 100) {
        version = possibleVersion;
    } else {
        // This is old format (version 1) without version number
        // possibleVersion is actually the first field of Character
        // We need to handle this as legacy data
        version = 1;
        // Note: In a real implementation, we'd need to carefully handle this
        // For now, we'll assume all saves are version 2
        qWarning() << "Attempting to load legacy save format - may not work correctly";
    }

    // Deserialize base class
    in >> static_cast<Character&>(p);

    // Deserialize Player members based on version
    if (version >= 2) {
        in >> p.characterClass;
    }
    in >> p.mana >> p.maxMana >> p.strength >> p.dexterity >> p.intelligence >> p.vitality;
    in >> p.gold >> p.experience >> p.experienceToLevel >> p.skillPoints >> p.statPoints;

    // Deserialize equipment
    QMap<QString, Item> eq;
    in >> eq;
    for (auto it = eq.begin(); it != eq.end(); ++it) {
        p.equipment[it.key()] = new Item(it.value());
    }
    // Ensure slots are initialized if not present
    if (!p.equipment.contains("weapon")) p.equipment["weapon"] = nullptr;
    if (!p.equipment.contains("armor")) p.equipment["armor"] = nullptr;
    if (!p.equipment.contains("accessory")) p.equipment["accessory"] = nullptr;

    // Deserialize inventory
    QList<Item> inv;
    in >> inv;
    for (const Item &item : inv) {
        p.inventory.append(new Item(item));
    }

    // Deserialize skills
    QList<Skill> skillList;
    in >> skillList;
    for (const Skill &skill : skillList) {
        p.skills.append(new Skill(skill));
    }

    // Deserialize quests (version 3+)
    if (version >= 3) {
        QList<Quest> questList;
        in >> questList;
        for (const Quest &quest : questList) {
            p.quests.append(new Quest(quest));
        }
    }
    // For version < 3, p.quests remains empty (default constructed)

    // Deserialize narrative tracking (version 4+)
    if (version >= 4) {
        in >> p.viewedDialogueIds;
        in >> p.viewedEventIds;
        in >> p.unlockedLoreEntries;
    }
    // For version < 4, narrative lists remain empty (default constructed)

    // Deserialize game completion tracking (version 5+)
    if (version >= 5) {
        in >> p.hasDefeatedFinalBoss;
        in >> p.gameCompletionTime;
        in >> p.finalGameLevel;
    } else {
        // Default values for old saves
        p.hasDefeatedFinalBoss = false;
        p.gameCompletionTime = "";
        p.finalGameLevel = 0;
    }

    return in;
}

void Player::learnSkill(Skill* skill)
{
    if (skill && !hasSkill(skill->name)) {
        skills.append(skill);
    }
}

bool Player::hasSkill(const QString &skillName) const
{
    for (const Skill* skill : skills) {
        if (skill && skill->name == skillName) {
            return true;
        }
    }
    return false;
}

Skill* Player::getSkill(const QString &skillName) const
{
    for (Skill* skill : skills) {
        if (skill && skill->name == skillName) {
            return skill;
        }
    }
    return nullptr;
}

bool Player::equipItem(Item* item)
{
    if (!item || item->slot.isEmpty()) {
        return false;
    }

    // Unequip current item in slot if exists
    if (equipment.contains(item->slot) && equipment[item->slot] != nullptr) {
        inventory.append(equipment[item->slot]);
    }

    // Equip new item
    equipment[item->slot] = item;

    // Remove from inventory if present
    inventory.removeOne(item);

    return true;
}

bool Player::unequipItem(const QString &slot)
{
    if (!equipment.contains(slot) || equipment[slot] == nullptr) {
        return false;
    }

    inventory.append(equipment[slot]);
    equipment[slot] = nullptr;
    return true;
}

bool Player::useItem(Item* item)
{
    if (!item) return false;

    if (item->effect == "heal") {
        health = std::min(health + item->power, maxHealth);
        inventory.removeOne(item);
        // Note: Caller is responsible for deleting the item to avoid use-after-free
        return true;
    }
    else if (item->effect == "restore_mana") {
        mana = std::min(mana + item->power, maxMana);
        inventory.removeOne(item);
        // Note: Caller is responsible for deleting the item to avoid use-after-free
        return true;
    }

    return false;
}

void Player::gainExperience(int amount)
{
    experience += amount;
    while (experience >= experienceToLevel) {
        levelUp();
    }
}

void Player::levelUp()
{
    level++;
    experience -= experienceToLevel;
    experienceToLevel = static_cast<int>(experienceToLevel * 1.5);

    // Stat increases
    maxHealth += 10 + (vitality * 2);
    health = maxHealth;
    maxMana += 5 + intelligence;
    mana = maxMana;
    strength += 2;
    dexterity += 2;
    intelligence += 2;
    vitality += 2;

    statPoints += 3;
    skillPoints += 1;
}

int Player::getTotalAttack() const
{
    int attack = strength;
    if (equipment.contains("weapon") && equipment["weapon"]) {
        attack += equipment["weapon"]->attackBonus;
    }
    if (equipment.contains("accessory") && equipment["accessory"]) {
        attack += equipment["accessory"]->attackBonus;
    }
    return attack;
}

int Player::getTotalDefense() const
{
    int defense = vitality / 2;
    if (equipment.contains("armor") && equipment["armor"]) {
        defense += equipment["armor"]->defenseBonus;
    }
    if (equipment.contains("accessory") && equipment["accessory"]) {
        defense += equipment["accessory"]->defenseBonus;
    }
    return defense;
}

// Quest management methods
void Player::addQuest(Quest* quest)
{
    if (quest) {
        quests.append(quest);
    }
}

Quest* Player::getQuest(const QString &questId) const
{
    for (Quest* quest : quests) {
        if (quest && quest->questId == questId) {
            return quest;
        }
    }
    return nullptr;
}

QList<Quest*> Player::getActiveQuests() const
{
    QList<Quest*> activeQuests;
    for (Quest* quest : quests) {
        if (quest && quest->isActive()) {
            activeQuests.append(quest);
        }
    }
    return activeQuests;
}

QList<Quest*> Player::getCompletedQuests() const
{
    QList<Quest*> completedQuests;
    for (Quest* quest : quests) {
        if (quest && quest->isComplete()) {
            completedQuests.append(quest);
        }
    }
    return completedQuests;
}

// Narrative tracking methods (Phase 3)
bool Player::hasViewedDialogue(const QString &dialogueId) const
{
    return viewedDialogueIds.contains(dialogueId);
}

bool Player::hasViewedEvent(const QString &eventId) const
{
    return viewedEventIds.contains(eventId);
}

bool Player::hasUnlockedLore(const QString &entryId) const
{
    return unlockedLoreEntries.contains(entryId);
}

QList<QString> Player::getUnlockedLoreEntries() const
{
    return unlockedLoreEntries;
}

void Player::markDialogueViewed(const QString &dialogueId)
{
    if (!viewedDialogueIds.contains(dialogueId)) {
        viewedDialogueIds.append(dialogueId);
    }
}

void Player::markEventViewed(const QString &eventId)
{
    if (!viewedEventIds.contains(eventId)) {
        viewedEventIds.append(eventId);
    }
}

void Player::unlockLore(const QString &entryId)
{
    if (!unlockedLoreEntries.contains(entryId)) {
        unlockedLoreEntries.append(entryId);
    }
}
