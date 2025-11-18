#ifndef PLAYER_H
#define PLAYER_H

#include "Character.h"
#include "Item.h"
#include "Skill.h"
#include "Quest.h"
#include <QList>
#include <QMap>
#include <QDataStream>

class Player : public Character
{
public:
    explicit Player(const QString &name, const QString &characterClass = "Hero");
    ~Player();  // Destructor to clean up dynamically allocated memory

    int mana;
    int maxMana;
    int strength;
    int dexterity;
    int intelligence;
    int vitality;

    QString characterClass;
    QList<Skill*> skills;
    QList<Quest*> quests;

    // Narrative tracking (Phase 3)
    QList<QString> viewedDialogueIds;      // Track completed unique dialogues
    QList<QString> viewedEventIds;         // Track viewed story events
    QList<QString> unlockedLoreEntries;    // Track discovered lore

    // Game completion tracking (Phase 4)
    bool hasDefeatedFinalBoss = false;
    QString gameCompletionTime = "";
    int finalGameLevel = 0;

    QMap<QString, Item*> equipment;
    QList<Item*> inventory;
    int gold;

    int experience;
    int experienceToLevel;
    int skillPoints;
    int statPoints;

    // Skill management
    void learnSkill(Skill* skill);
    bool hasSkill(const QString &skillName) const;
    Skill* getSkill(const QString &skillName) const;

    // Quest management
    void addQuest(Quest* quest);
    Quest* getQuest(const QString &questId) const;
    QList<Quest*> getActiveQuests() const;
    QList<Quest*> getCompletedQuests() const;

    // Narrative tracking (Phase 3)
    bool hasViewedDialogue(const QString &dialogueId) const;
    bool hasViewedEvent(const QString &eventId) const;
    bool hasUnlockedLore(const QString &entryId) const;
    QList<QString> getUnlockedLoreEntries() const;
    void markDialogueViewed(const QString &dialogueId);
    void markEventViewed(const QString &eventId);
    void unlockLore(const QString &entryId);

    // Item management
    bool equipItem(Item* item);
    bool unequipItem(const QString &slot);
    bool useItem(Item* item);

    // Stat management
    void gainExperience(int amount);
    void levelUp();
    int getTotalAttack() const;
    int getTotalDefense() const;

    friend QDataStream &operator<<(QDataStream &out, const Player &p);
    friend QDataStream &operator>>(QDataStream &in, Player &p);
};

#endif // PLAYER_H
