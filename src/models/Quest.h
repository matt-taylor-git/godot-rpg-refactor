#ifndef QUEST_H
#define QUEST_H

#include <QString>
#include <QList>
#include <QDataStream>

// Quest objective structure
struct QuestObjective {
    QString type;         // "kill_enemies", "reach_level", "collect_item", "defeat_boss"
    QString description;  // "Defeat 3 Shadow Wolves"
    QString targetId;     // "shadow_wolf" (monster name/item name)
    int required;         // Target count (e.g., 3)
    int current;          // Current progress (0-3)
    bool completed;       // True when current >= required

    QuestObjective()
        : required(0), current(0), completed(false) {}
};

// Quest rewards structure
struct QuestRewards {
    int experience;           // Experience points reward
    int gold;                 // Gold reward
    QList<QString> itemNames; // Item rewards (by name, created via ItemFactory)

    QuestRewards()
        : experience(0), gold(0) {}
};

// Main Quest class
class Quest
{
public:
    // Constructors
    Quest();
    Quest(const QString &id, const QString &title, const QString &description = "",
          const QString &status = "locked", int minLevel = 1);

    // Public members (camelCase naming)
    QString questId;              // Unique identifier (e.g., "main_quest_01")
    QString title;                // Display name (e.g., "A Dark Omen")
    QString description;          // Short description (1-2 sentences)
    QString longDescription;      // Full quest text
    QString status;               // "locked", "available", "active", "completed", "rewarded"
    int orderIndex;               // Display order
    int minimumLevel;             // Level prerequisite
    QList<QString> prerequisiteQuestIds;  // Required quests to unlock
    QList<QuestObjective> objectives;     // Quest objectives
    QuestRewards rewards;                 // Quest rewards

    // Helper methods
    bool isComplete() const;      // Returns true if status is "completed" or "rewarded"
    bool isActive() const;        // Returns true if status is "active"
    bool isAvailable() const;     // Returns true if status is "available"
    bool isLocked() const;        // Returns true if status is "locked"
    int getProgress() const;      // Returns count of completed objectives
    int getTotalObjectives() const; // Returns total objective count
    void updateObjective(int index, int progress);  // Update objective progress

    // Serialization operators (required for save/load)
    friend QDataStream &operator<<(QDataStream &out, const Quest &q);
    friend QDataStream &operator>>(QDataStream &in, Quest &q);
};

#endif // QUEST_H
