#ifndef STORYEVENTFACTORY_H
#define STORYEVENTFACTORY_H

#include "models/StoryEvent.h"
#include <QList>
#include <QString>

class StoryEventFactory
{
public:
    // Get specific story event by ID
    static StoryEvent* createEvent(const QString &eventId);

    // Get all story events
    static QList<StoryEvent*> getAllEvents();

    // Get events for a specific quest
    static QList<StoryEvent*> getEventsForQuest(const QString &questId);

private:
    StoryEventFactory() = delete;  // Prevent instantiation
};

#endif // STORYEVENTFACTORY_H
