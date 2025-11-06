#ifndef DIALOGUEFACTORY_H
#define DIALOGUEFACTORY_H

#include "models/DialogueData.h"
#include <QList>
#include <QString>

class DialogueFactory
{
public:
    // Get specific dialogue tree by ID
    static DialogueTree* createDialogue(const QString &dialogueId);

    // Get all dialogue trees
    static QList<DialogueTree*> getAllDialogues();

    // Get dialogue tree for a specific quest
    static DialogueTree* getDialogueForQuest(const QString &questId);

private:
    DialogueFactory() = delete;  // Prevent instantiation
};

#endif // DIALOGUEFACTORY_H
