#ifndef DIALOGUEDATA_H
#define DIALOGUEDATA_H

#include <QString>
#include <QList>
#include <QMap>
#include <QDataStream>

// Effect applied when a dialogue choice is selected
struct DialogueEffect {
    QString type;      // "AdvanceQuest", "GiveItem", "GiveGold", "GiveXP", "UnlockQuest"
    QString target;    // Quest ID, item name, etc.
    int value;         // Amount for gold/XP

    DialogueEffect() : value(0) {}
};

// Player response option in dialogue
struct DialogueChoice {
    QString text;                      // "What's happening?"
    QString targetNodeId;              // "explain_situation" (next node ID)
    QList<DialogueEffect> effects;    // Effects applied when chosen
    bool requiresLevel;                // false by default
    int requiredLevel;                 // 0 by default

    DialogueChoice() : requiresLevel(false), requiredLevel(0) {}
};

// Single node in dialogue tree
struct DialogueNode {
    QString id;                        // "greeting"
    QString speaker;                   // "Village Elder"
    QString text;                      // "Greetings, brave adventurer..."
    QList<DialogueChoice> choices;    // Player response options
    QString autoNextNodeId;            // For linear dialogues (empty if branching)
    bool endsDialogue;                 // true to end conversation

    DialogueNode() : endsDialogue(false) {}
};

// Complete dialogue tree with all nodes
class DialogueTree {
public:
    QString id;                        // "elder_intro"
    QString npcName;                   // "Village Elder"
    QString startNodeId;               // "greeting"
    QMap<QString, DialogueNode> nodes; // All nodes in tree

    DialogueTree() {}

    // Get node by ID (returns nullptr if not found)
    DialogueNode* getNode(const QString &nodeId);

    // Get start node
    DialogueNode* getStartNode();

    // Serialization operators
    friend QDataStream &operator<<(QDataStream &out, const DialogueTree &tree);
    friend QDataStream &operator>>(QDataStream &in, DialogueTree &tree);
};

// Serialization for nested structs (declarations)
QDataStream &operator<<(QDataStream &out, const DialogueEffect &effect);
QDataStream &operator>>(QDataStream &in, DialogueEffect &effect);
QDataStream &operator<<(QDataStream &out, const DialogueChoice &choice);
QDataStream &operator>>(QDataStream &in, DialogueChoice &choice);
QDataStream &operator<<(QDataStream &out, const DialogueNode &node);
QDataStream &operator>>(QDataStream &in, DialogueNode &node);

#endif // DIALOGUEDATA_H
