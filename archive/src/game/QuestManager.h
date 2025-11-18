#ifndef QUESTMANAGER_H
#define QUESTMANAGER_H

#include "../models/Quest.h"
#include "../models/Player.h"
#include <QObject>
#include <QMap>
#include <QString>
#include <QDebug>

class QuestManager : public QObject
{
    Q_OBJECT

public:
    explicit QuestManager(Player* player, QObject *parent = nullptr);
    ~QuestManager();

    // Quest management
    void loadQuests();
    bool acceptQuest(const QString &questId);
    void updateQuestProgress(const QString &questId, int objIndex, int progress);
    void completeQuest(const QString &questId);
    Quest* getQuestById(const QString &questId) const;

    // Event handlers for automatic quest updates
    void onCombatEnd(const QString &enemyName);
    void onLevelUp(int newLevel);
    void onItemCollected(const QString &itemName);

    // Quest queries
    QList<Quest*> getActiveQuests() const;
    QList<Quest*> getAvailableQuests() const;
    QList<Quest*> getCompletedQuests() const;
    QList<Quest*> getLockedQuests() const;

signals:
    // Signals for UI updates
    void questAvailable(const QString &questId);
    void questAccepted(const QString &questId);
    void questProgressed(const QString &questId, int objectiveIndex);
    void questCompleted(const QString &questId, int expReward, int goldReward);

private:
    Player* m_player;                   // Reference to player (not owned)
    QList<Quest*> m_allQuests;          // All quest definitions (owned)
    QMap<QString, Quest*> m_questMap;   // Quick lookup map

    // Helper methods
    void checkQuestUnlocks();
    bool checkObjectivesComplete(Quest* quest);
    void giveQuestRewards(Quest* quest);
};

#endif // QUESTMANAGER_H
