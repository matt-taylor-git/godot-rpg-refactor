#ifndef QUESTFACTORY_H
#define QUESTFACTORY_H

#include "../../models/Quest.h"
#include "../../models/Player.h"
#include <QString>
#include <QList>

class QuestFactory
{
public:
    // Create a specific quest by ID
    static Quest* createQuest(const QString &questId);

    // Get all main story quests
    static QList<Quest*> getAllMainQuests();

    // Get quests available for a player (based on level and prerequisites)
    static QList<Quest*> getAvailableQuests(Player* player);

private:
    // Helper to check if prerequisites are met
    static bool checkPrerequisites(const Quest* quest, Player* player);
};

#endif // QUESTFACTORY_H
