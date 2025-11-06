#include "DialogueData.h"
#include <QDebug>

// DialogueTree methods
DialogueNode* DialogueTree::getNode(const QString &nodeId)
{
    if (nodes.contains(nodeId)) {
        return &nodes[nodeId];
    }
    return nullptr;
}

DialogueNode* DialogueTree::getStartNode()
{
    return getNode(startNodeId);
}

// Serialization for DialogueEffect
QDataStream &operator<<(QDataStream &out, const DialogueEffect &effect)
{
    out.setVersion(QDataStream::Qt_6_0);
    out << effect.type << effect.target << effect.value;
    return out;
}

QDataStream &operator>>(QDataStream &in, DialogueEffect &effect)
{
    in.setVersion(QDataStream::Qt_6_0);
    in >> effect.type >> effect.target >> effect.value;
    return in;
}

// Serialization for DialogueChoice
QDataStream &operator<<(QDataStream &out, const DialogueChoice &choice)
{
    out.setVersion(QDataStream::Qt_6_0);
    out << choice.text << choice.targetNodeId << choice.requiresLevel << choice.requiredLevel;

    // Serialize effects
    out << quint32(choice.effects.size());
    for (const DialogueEffect &effect : choice.effects) {
        out << effect;
    }

    return out;
}

QDataStream &operator>>(QDataStream &in, DialogueChoice &choice)
{
    in.setVersion(QDataStream::Qt_6_0);
    in >> choice.text >> choice.targetNodeId >> choice.requiresLevel >> choice.requiredLevel;

    // Deserialize effects
    quint32 effectCount;
    in >> effectCount;
    choice.effects.clear();
    for (quint32 i = 0; i < effectCount; ++i) {
        DialogueEffect effect;
        in >> effect;
        choice.effects.append(effect);
    }

    return in;
}

// Serialization for DialogueNode
QDataStream &operator<<(QDataStream &out, const DialogueNode &node)
{
    out.setVersion(QDataStream::Qt_6_0);
    out << node.id << node.speaker << node.text << node.autoNextNodeId << node.endsDialogue;

    // Serialize choices
    out << quint32(node.choices.size());
    for (const DialogueChoice &choice : node.choices) {
        out << choice;
    }

    return out;
}

QDataStream &operator>>(QDataStream &in, DialogueNode &node)
{
    in.setVersion(QDataStream::Qt_6_0);
    in >> node.id >> node.speaker >> node.text >> node.autoNextNodeId >> node.endsDialogue;

    // Deserialize choices
    quint32 choiceCount;
    in >> choiceCount;
    node.choices.clear();
    for (quint32 i = 0; i < choiceCount; ++i) {
        DialogueChoice choice;
        in >> choice;
        node.choices.append(choice);
    }

    return in;
}

// Serialization for DialogueTree
QDataStream &operator<<(QDataStream &out, const DialogueTree &tree)
{
    out.setVersion(QDataStream::Qt_6_0);
    out << tree.id << tree.npcName << tree.startNodeId;

    // Serialize nodes map
    out << quint32(tree.nodes.size());
    for (const DialogueNode &node : tree.nodes) {
        out << node;
    }

    return out;
}

QDataStream &operator>>(QDataStream &in, DialogueTree &tree)
{
    in.setVersion(QDataStream::Qt_6_0);
    in >> tree.id >> tree.npcName >> tree.startNodeId;

    // Deserialize nodes map
    quint32 nodeCount;
    in >> nodeCount;
    tree.nodes.clear();

    for (quint32 i = 0; i < nodeCount; ++i) {
        DialogueNode node;
        in >> node;
        tree.nodes[node.id] = node;
    }

    return in;
}
