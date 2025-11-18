#ifndef DIALOGUEMANAGER_H
#define DIALOGUEMANAGER_H

#include "models/DialogueData.h"
#include "models/Player.h"
#include <QObject>
#include <QMap>
#include <QString>

class DialogueManager : public QObject
{
    Q_OBJECT

public:
    explicit DialogueManager(Player* player, QObject* parent = nullptr);
    ~DialogueManager();

    // Dialogue management
    void loadDialogues();
    void startDialogue(const QString &dialogueId);
    DialogueNode* getCurrentNode() const;
    void selectChoice(int choiceIndex);
    void advance();  // For linear dialogues with autoNextNodeId
    bool isDialogueActive() const;
    void endDialogue();

signals:
    void dialogueStarted(const QString &dialogueId, const QString &npcName);
    void dialogueNodeChanged(const QString &nodeId, const QString &speaker, const QString &text);
    void dialogueEnded();
    void effectTriggered(const QString &effectType, const QString &target, int value);

private:
    void applyEffect(const DialogueEffect &effect);

    Player* m_player;  // Reference, not owned
    QMap<QString, DialogueTree*> m_dialogueTrees;  // All dialogues, owned
    DialogueTree* m_currentTree;  // Current dialogue in progress
    DialogueNode* m_currentNode;  // Current node in tree
    QString m_currentDialogueId;  // For tracking and saving
};

#endif // DIALOGUEMANAGER_H
