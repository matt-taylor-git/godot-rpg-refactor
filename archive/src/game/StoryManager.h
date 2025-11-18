#ifndef STORYMANAGER_H
#define STORYMANAGER_H

#include "models/StoryEvent.h"
#include "models/Player.h"
#include <QObject>
#include <QList>
#include <QMap>
#include <QString>

class StoryManager : public QObject
{
    Q_OBJECT

public:
    explicit StoryManager(Player* player, QObject* parent = nullptr);
    ~StoryManager();

    // Event management
    void loadEvents();
    void checkEventTriggers();
    void triggerEvent(const QString &eventId);

    // Event handlers (connected to quest/game signals)
    void onQuestStarted(const QString &questId);
    void onQuestCompleted(const QString &questId);
    void onLevelReached(int level);

signals:
    void eventTriggered(const StoryEvent &event);

private:
    Player* m_player;  // Reference, not owned
    QList<StoryEvent*> m_allEvents;  // All events, owned by factory
    QMap<QString, StoryEvent*> m_eventMap;  // Quick lookup
};

#endif // STORYMANAGER_H
