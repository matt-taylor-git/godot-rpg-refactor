#include "Quest.h"

// Default constructor
Quest::Quest()
    : orderIndex(0), minimumLevel(1), status("locked")
{
}

// Parameterized constructor with defaults
Quest::Quest(const QString &id, const QString &title, const QString &description,
             const QString &status, int minLevel)
    : questId(id), title(title), description(description), status(status),
      orderIndex(0), minimumLevel(minLevel)
{
}

// Helper methods
bool Quest::isComplete() const
{
    return status == "completed" || status == "rewarded";
}

bool Quest::isActive() const
{
    return status == "active";
}

bool Quest::isAvailable() const
{
    return status == "available";
}

bool Quest::isLocked() const
{
    return status == "locked";
}

int Quest::getProgress() const
{
    int completedCount = 0;
    for (const QuestObjective &obj : objectives) {
        if (obj.completed) {
            completedCount++;
        }
    }
    return completedCount;
}

int Quest::getTotalObjectives() const
{
    return objectives.size();
}

void Quest::updateObjective(int index, int progress)
{
    if (index < 0 || index >= objectives.size()) {
        return;
    }

    QuestObjective &obj = objectives[index];
    if (obj.completed) {
        return; // Already completed, no need to update
    }

    obj.current += progress;
    if (obj.current >= obj.required) {
        obj.current = obj.required; // Cap at required
        obj.completed = true;
    }
}

// Serialization operators (CRITICAL: Order must match exactly)
QDataStream &operator<<(QDataStream &out, const Quest &q)
{
    // Write all primitive members first
    out << q.questId << q.title << q.description << q.longDescription
        << q.status << q.orderIndex << q.minimumLevel;

    // Write prerequisite list (QList<QString> auto-serializes)
    out << q.prerequisiteQuestIds;

    // Serialize objectives manually (QList of structs)
    out << quint32(q.objectives.size());
    for (const QuestObjective &obj : q.objectives) {
        out << obj.type << obj.description << obj.targetId
            << obj.required << obj.current << obj.completed;
    }

    // Serialize rewards
    out << q.rewards.experience << q.rewards.gold << q.rewards.itemNames;

    return out;
}

QDataStream &operator>>(QDataStream &in, Quest &q)
{
    // Read in EXACT same order as operator<<
    in >> q.questId >> q.title >> q.description >> q.longDescription
       >> q.status >> q.orderIndex >> q.minimumLevel;

    // Read prerequisite list
    in >> q.prerequisiteQuestIds;

    // Deserialize objectives
    quint32 objCount;
    in >> objCount;
    q.objectives.clear();
    for (quint32 i = 0; i < objCount; ++i) {
        QuestObjective obj;
        in >> obj.type >> obj.description >> obj.targetId
           >> obj.required >> obj.current >> obj.completed;
        q.objectives.append(obj);
    }

    // Deserialize rewards
    in >> q.rewards.experience >> q.rewards.gold >> q.rewards.itemNames;

    return in;
}
