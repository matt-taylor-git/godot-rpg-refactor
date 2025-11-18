#include "DialogueManager.h"
#include "factories/DialogueFactory.h"
#include "factories/ItemFactory.h"
#include <QDebug>

DialogueManager::DialogueManager(Player* player, QObject* parent)
    : QObject(parent)
    , m_player(player)
    , m_currentTree(nullptr)
    , m_currentNode(nullptr)
{
}

DialogueManager::~DialogueManager()
{
    // Dialogue trees are managed by factory static cache, don't delete them here
    m_dialogueTrees.clear();
}

void DialogueManager::loadDialogues()
{
    QList<DialogueTree*> dialogues = DialogueFactory::getAllDialogues();
    for (DialogueTree* tree : dialogues) {
        if (tree) {
            m_dialogueTrees[tree->id] = tree;
        }
    }
    qDebug() << "Loaded" << m_dialogueTrees.size() << "dialogue trees";
}

void DialogueManager::startDialogue(const QString &dialogueId)
{
    // Check if already viewed (for unique dialogues)
    // Note: For repeatable dialogues, skip this check or add a 'repeatable' flag
    if (m_player->hasViewedDialogue(dialogueId)) {
        qDebug() << "Dialogue already viewed:" << dialogueId;
        // For now, allow replay - comment out return to enable replaying
        // return;
    }

    m_currentTree = m_dialogueTrees.value(dialogueId, nullptr);
    if (!m_currentTree) {
        qWarning() << "Dialogue tree not found:" << dialogueId;
        return;
    }

    m_currentNode = m_currentTree->getStartNode();
    if (!m_currentNode) {
        qWarning() << "Start node not found in dialogue:" << dialogueId;
        return;
    }

    m_currentDialogueId = dialogueId;

    emit dialogueStarted(dialogueId, m_currentTree->npcName);
    emit dialogueNodeChanged(m_currentNode->id, m_currentNode->speaker, m_currentNode->text);
}

DialogueNode* DialogueManager::getCurrentNode() const
{
    return m_currentNode;
}

void DialogueManager::selectChoice(int choiceIndex)
{
    if (!m_currentNode) {
        qWarning() << "No active dialogue node";
        return;
    }

    if (choiceIndex < 0 || choiceIndex >= m_currentNode->choices.size()) {
        qWarning() << "Invalid choice index:" << choiceIndex;
        return;
    }

    const DialogueChoice &choice = m_currentNode->choices[choiceIndex];

    // Check requirements
    if (choice.requiresLevel && m_player->level < choice.requiredLevel) {
        qDebug() << "Choice requires level" << choice.requiredLevel << "but player is" << m_player->level;
        return;  // Don't allow selection
    }

    // Apply effects
    for (const DialogueEffect &effect : choice.effects) {
        applyEffect(effect);
    }

    // Navigate to next node
    if (choice.targetNodeId.isEmpty() || m_currentNode->endsDialogue) {
        endDialogue();
        return;
    }

    m_currentNode = m_currentTree->getNode(choice.targetNodeId);
    if (m_currentNode) {
        emit dialogueNodeChanged(m_currentNode->id, m_currentNode->speaker, m_currentNode->text);

        // Check if new node ends dialogue
        if (m_currentNode->endsDialogue && m_currentNode->choices.size() == 1 &&
            m_currentNode->choices[0].targetNodeId.isEmpty()) {
            // Auto-end after showing final message if only one "OK" style choice
            // Let UI handle the final choice click to end
        }
    } else {
        qWarning() << "Target node not found:" << choice.targetNodeId;
        endDialogue();
    }
}

void DialogueManager::advance()
{
    if (!m_currentNode || m_currentNode->autoNextNodeId.isEmpty()) {
        return;
    }

    m_currentNode = m_currentTree->getNode(m_currentNode->autoNextNodeId);
    if (m_currentNode) {
        emit dialogueNodeChanged(m_currentNode->id, m_currentNode->speaker, m_currentNode->text);
    } else {
        endDialogue();
    }
}

bool DialogueManager::isDialogueActive() const
{
    return m_currentTree != nullptr && m_currentNode != nullptr;
}

void DialogueManager::endDialogue()
{
    if (!m_currentDialogueId.isEmpty()) {
        m_player->markDialogueViewed(m_currentDialogueId);
    }

    m_currentTree = nullptr;
    m_currentNode = nullptr;
    m_currentDialogueId = "";

    emit dialogueEnded();
}

void DialogueManager::applyEffect(const DialogueEffect &effect)
{
    if (effect.type == "UnlockQuest") {
        emit effectTriggered("UnlockQuest", effect.target, 0);
    } else if (effect.type == "GiveGold") {
        m_player->gold += effect.value;
        emit effectTriggered("GiveGold", "", effect.value);
    } else if (effect.type == "GiveXP") {
        m_player->gainExperience(effect.value);
        emit effectTriggered("GiveXP", "", effect.value);
    } else if (effect.type == "GiveItem") {
        // Create item via ItemFactory
        Item* item = ItemFactory::createItem(effect.target);
        if (item) {
            m_player->inventory.append(item);
            // Unlock lore entry if item has associated lore (Phase 5)
            if (!item->loreId.isEmpty()) {
                if (!m_player->hasUnlockedLore(item->loreId)) {
                    m_player->unlockLore(item->loreId);
                    // Signal will be caught by CodexManager via Game connections
                }
            }
            emit effectTriggered("GiveItem", effect.target, 1);
        }
    } else if (effect.type == "AdvanceQuest") {
        emit effectTriggered("AdvanceQuest", effect.target, effect.value);
    }
}
