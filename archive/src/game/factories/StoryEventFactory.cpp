#include "StoryEventFactory.h"
#include <QMap>

StoryEvent* StoryEventFactory::createEvent(const QString &eventId)
{
    // Static cache to prevent memory leaks
    static QMap<QString, StoryEvent*> cache;

    if (cache.isEmpty()) {
        // ================================================================
        // EVENT 1: Game Introduction
        // ================================================================
        StoryEvent* intro = new StoryEvent();
        intro->eventId = "intro_cutscene";
        intro->title = "A Dark Omen";
        intro->eventText = R"(The sun sets over the village of Thornhaven, casting long shadows across the cobblestone streets.

For generations, your people have lived in peace with the forest.

But now, something stirs in the darkness.

The wolves howl with unnatural fury. The trees whisper warnings.

Your adventure begins...)";
        intro->triggerType = "manual";
        intro->viewed = false;

        cache["intro_cutscene"] = intro;

        // ================================================================
        // EVENT 2: Quest System Tutorial
        // ================================================================
        StoryEvent* questTutorial = new StoryEvent();
        questTutorial->eventId = "quest_system_intro";
        questTutorial->title = "Understanding Quests";
        questTutorial->eventText = R"(Welcome to the world of quests!

QUESTS are missions that guide your adventure. Each quest has:
• A description explaining the task
• Objectives that track your progress (shown with ✓ when complete)
• Rewards like experience, gold, and items

HOW TO VIEW YOUR QUESTS:
Open the Quest Log (press Q or click the Quests button) anytime.
You'll see your Active, Available, and Completed quests here.

YOUR FIRST QUEST: "A Dark Omen"
The village needs your help! Your objective is to defeat Shadow Wolves.
Fight enemies by exploring or engaging in combat. Quest progress updates automatically.

Complete quests to gain rewards and unlock new adventures!

Press "Got it!" to begin your journey.)";
        questTutorial->triggerType = "quest_start";
        questTutorial->triggerId = "main_quest_01";
        questTutorial->viewed = false;

        cache["quest_system_intro"] = questTutorial;

        // ================================================================
        // EVENT 3: Quest 01 Start
        // ================================================================
        StoryEvent* quest01Start = new StoryEvent();
        quest01Start->eventId = "quest_01_start";
        quest01Start->title = "The Elder's Plea";
        quest01Start->eventText = R"(The Village Elder's weathered face shows deep concern.

"The Shadow Wolves grow bolder with each passing night," he says, his voice grave.

"Already, three families have abandoned their homes near the forest's edge.
If this continues, the village itself will be lost."

You accept the burden. The Whispering Woods await.)";
        quest01Start->triggerType = "quest_start";
        quest01Start->triggerId = "main_quest_01";
        quest01Start->viewed = false;

        cache["quest_01_start"] = quest01Start;

        // ================================================================
        // EVENT 3: Quest 01 Complete
        // ================================================================
        StoryEvent* quest01Complete = new StoryEvent();
        quest01Complete->eventId = "quest_01_complete";
        quest01Complete->title = "Victory's Light";
        quest01Complete->eventText = R"(The last Shadow Wolf falls, its dark essence dispersing into the night air.

An eerie silence settles over the Whispering Woods.

As you return to Thornhaven, you notice the villagers emerging from their homes,
drawn by the sudden peace.

The Elder meets you at the village gate, relief flooding his features.

"The howling has stopped," he says, wonder in his voice. "You've done it, hero."

But in the distance, deeper in the forest, darker shadows still lurk...

This is only the beginning.)";
        quest01Complete->triggerType = "quest_complete";
        quest01Complete->triggerId = "main_quest_01";
        quest01Complete->viewed = false;

        cache["quest_01_complete"] = quest01Complete;

        // ================================================================
        // EVENT 4: Level Milestone
        // ================================================================
        StoryEvent* level5 = new StoryEvent();
        level5->eventId = "level_5_reached";
        level5->title = "Growing Power";
        level5->eventText = R"(You feel a surge of energy coursing through your body.

Your training has paid off. Your skills have sharpened.

You are no longer a novice - you are becoming a true hero.

The challenges ahead will be greater, but so too is your strength.)";
        level5->triggerType = "level_reached";
        level5->triggerId = "5";
        level5->viewed = false;

        cache["level_5_reached"] = level5;

        // ================================================================
        // EVENT 5: Boss Intro (future content)
        // ================================================================
        StoryEvent* bossIntro = new StoryEvent();
        bossIntro->eventId = "boss_intro";
        bossIntro->title = "The Shadow Lord";
        bossIntro->eventText = R"(Deep within the corrupted heart of the forest, you finally confront the source of the darkness.

A massive figure emerges from the shadows, eyes burning with malevolent fire.

"So," it growls, "another fool comes to challenge me."

"The wolves were but my children. Now face the master of shadows himself!"

The final battle begins...)";
        bossIntro->triggerType = "manual";
        bossIntro->viewed = false;

        cache["boss_intro"] = bossIntro;
    }

    return cache.value(eventId, nullptr);
}

QList<StoryEvent*> StoryEventFactory::getAllEvents()
{
    static QList<StoryEvent*> allEvents;

    if (allEvents.isEmpty()) {
        allEvents.append(createEvent("intro_cutscene"));
        allEvents.append(createEvent("quest_system_intro"));
        allEvents.append(createEvent("quest_01_start"));
        allEvents.append(createEvent("quest_01_complete"));
        allEvents.append(createEvent("level_5_reached"));
        allEvents.append(createEvent("boss_intro"));
    }

    return allEvents;
}

QList<StoryEvent*> StoryEventFactory::getEventsForQuest(const QString &questId)
{
    QList<StoryEvent*> questEvents;

    if (questId == "main_quest_01") {
        questEvents.append(createEvent("quest_01_start"));
        questEvents.append(createEvent("quest_01_complete"));
    }

    return questEvents;
}
