#ifndef STORYEVENT_H
#define STORYEVENT_H

#include <QString>
#include <QList>

// Story event/cutscene for narrative moments
struct StoryEvent {
    QString eventId;               // "intro_cutscene", "quest_01_complete"
    QString title;                 // "A Dark Omen"
    QString eventText;             // Multi-line narrative text
    QList<QString> imagePaths;     // Background images from resources
    QList<QString> prerequisites;  // Quest IDs or level requirements
    QString triggerType;           // "quest_start", "quest_complete", "level_reached", "manual"
    QString triggerId;             // Associated quest ID or level number
    bool viewed;                   // Player-specific state (tracked in Player)

    StoryEvent()
        : viewed(false)
    {}
};

#endif // STORYEVENT_H
