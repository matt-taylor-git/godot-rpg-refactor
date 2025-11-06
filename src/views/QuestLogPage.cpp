#include "QuestLogPage.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QKeyEvent>

QuestLogPage::QuestLogPage(QWidget *parent)
    : QWidget(parent), m_questManager(nullptr), m_currentPlayer(nullptr), m_selectedQuest(nullptr)
{
    setupUi();
}

void QuestLogPage::setupUi()
{
    // Main horizontal layout (list | details)
    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG,
                                   Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    // LEFT SIDE: Quest list with title and buttons
    QVBoxLayout *listLayout = new QVBoxLayout();

    // Title
    m_titleLabel = new QLabel("Quest Log");
    m_titleLabel->setStyleSheet(QString(
        "font-size: %1px; font-weight: %2; color: %3;"
    ).arg(Theme::FONT_SIZE_XL)
     .arg(Theme::FONT_WEIGHT_BOLD)
     .arg(Theme::PRIMARY.name()));
    listLayout->addWidget(m_titleLabel);

    // Quest list widget
    m_questList = new QListWidget();
    m_questList->setStyleSheet(QString(
        "QListWidget {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: %3px;"
        "    color: %4;"
        "    padding: %5px;"
        "    font-size: %6px;"
        "}"
        "QListWidget::item {"
        "    padding: 8px;"
        "    border-radius: 4px;"
        "    margin: 2px 0px;"
        "}"
        "QListWidget::item:selected {"
        "    background-color: %7;"
        "    color: %8;"
        "}"
        "QListWidget::item:hover {"
        "    background-color: %9;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::SPACING_SM)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::MUTED.name()));

    connect(m_questList, &QListWidget::itemClicked, this, &QuestLogPage::handleQuestClicked);
    listLayout->addWidget(m_questList, 1);

    // Buttons layout
    QHBoxLayout *buttonsLayout = new QHBoxLayout();

    // Accept button (hidden by default)
    m_acceptButton = new QPushButton("Accept Quest (A)");
    m_acceptButton->setMinimumHeight(40);
    m_acceptButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: none;"
        "    border-radius: %3px;"
        "    padding: %4px;"
        "    font-size: %5px;"
        "    font-weight: %6;"
        "}"
        "QPushButton:hover {"
        "    background-color: %7;"
        "}"
        "QPushButton:pressed {"
        "    background-color: %8;"
        "}"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_MD)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_MEDIUM)
     .arg(Theme::ACCENT.name())
     .arg(Theme::DESTRUCTIVE.name()));
    m_acceptButton->setVisible(false);
    connect(m_acceptButton, &QPushButton::clicked, this, &QuestLogPage::handleAcceptQuest);
    buttonsLayout->addWidget(m_acceptButton);

    // Back button
    m_backButton = new QPushButton("Back (Esc)");
    m_backButton->setMinimumHeight(40);
    m_backButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: 2px solid %3;"
        "    border-radius: %4px;"
        "    padding: %5px;"
        "    font-size: %6px;"
        "    font-weight: %7;"
        "}"
        "QPushButton:hover {"
        "    background-color: %8;"
        "}"
    ).arg(Theme::SECONDARY.name())
     .arg(Theme::SECONDARY_FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_MD)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_MEDIUM)
     .arg(Theme::MUTED.name()));
    connect(m_backButton, &QPushButton::clicked, this, &QuestLogPage::handleBackClicked);
    buttonsLayout->addWidget(m_backButton);

    listLayout->addLayout(buttonsLayout);
    mainLayout->addLayout(listLayout, 1);  // Stretch factor 1

    // RIGHT SIDE: Quest details
    m_questDetails = new QTextEdit();
    m_questDetails->setReadOnly(true);
    m_questDetails->setStyleSheet(QString(
        "QTextEdit {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: %3px;"
        "    padding: %4px;"
        "    color: %5;"
        "    font-size: %6px;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::FONT_SIZE_MD));
    m_questDetails->setHtml("<p style='color: " + Theme::MUTED_FOREGROUND.name() + ";'>Select a quest to view details.</p>");

    mainLayout->addWidget(m_questDetails, 2);  // Stretch factor 2
}

void QuestLogPage::updateQuests(QuestManager* questManager, Player* player)
{
    m_questManager = questManager;
    m_currentPlayer = player;
    m_selectedQuest = nullptr;

    clearQuests();

    if (!m_questManager || !m_currentPlayer) {
        return;
    }

    // Add ACTIVE quests section
    QList<Quest*> activeQuests = m_questManager->getActiveQuests();
    if (!activeQuests.isEmpty()) {
        QListWidgetItem *header = new QListWidgetItem("=== ACTIVE QUESTS ===");
        header->setForeground(QBrush(Theme::ACCENT));
        header->setFlags(Qt::ItemIsEnabled);  // Not selectable
        m_questList->addItem(header);

        for (Quest* quest : activeQuests) {
            if (quest) {
                QString itemText = QString("%1  %2").arg(quest->title).arg(getStatusBadge(quest));
                QListWidgetItem *item = new QListWidgetItem(itemText);
                item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(quest)));
                m_questList->addItem(item);
            }
        }
    }

    // Add AVAILABLE quests section
    QList<Quest*> availableQuests = m_questManager->getAvailableQuests();
    if (!availableQuests.isEmpty()) {
        QListWidgetItem *header = new QListWidgetItem("=== AVAILABLE QUESTS ===");
        header->setForeground(QBrush(Theme::PRIMARY));
        header->setFlags(Qt::ItemIsEnabled);
        m_questList->addItem(header);

        for (Quest* quest : availableQuests) {
            if (quest) {
                QString itemText = QString("%1  %2").arg(quest->title).arg(getStatusBadge(quest));
                QListWidgetItem *item = new QListWidgetItem(itemText);
                item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(quest)));
                m_questList->addItem(item);
            }
        }
    }

    // Add COMPLETED quests section
    QList<Quest*> completedQuests = m_questManager->getCompletedQuests();
    if (!completedQuests.isEmpty()) {
        QListWidgetItem *header = new QListWidgetItem("=== COMPLETED QUESTS ===");
        header->setForeground(QBrush(Theme::MUTED_FOREGROUND));
        header->setFlags(Qt::ItemIsEnabled);
        m_questList->addItem(header);

        for (Quest* quest : completedQuests) {
            if (quest) {
                QString itemText = QString("%1  %2").arg(quest->title).arg(getStatusBadge(quest));
                QListWidgetItem *item = new QListWidgetItem(itemText);
                item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(quest)));
                item->setForeground(QBrush(Theme::MUTED_FOREGROUND));
                m_questList->addItem(item);
            }
        }
    }

    // Add LOCKED quests section (optional - shows future quests)
    QList<Quest*> lockedQuests = m_questManager->getLockedQuests();
    if (!lockedQuests.isEmpty()) {
        QListWidgetItem *header = new QListWidgetItem("=== LOCKED QUESTS ===");
        header->setForeground(QBrush(Theme::MUTED_FOREGROUND));
        header->setFlags(Qt::ItemIsEnabled);
        m_questList->addItem(header);

        for (Quest* quest : lockedQuests) {
            if (quest) {
                QString itemText = QString("??? %1").arg(quest->title);
                QListWidgetItem *item = new QListWidgetItem(itemText);
                item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(quest)));
                item->setForeground(QBrush(Theme::MUTED_FOREGROUND));
                m_questList->addItem(item);
            }
        }
    }
}

void QuestLogPage::handleQuestClicked(QListWidgetItem *item)
{
    if (!item) return;

    // Get quest from item data
    Quest *quest = static_cast<Quest*>(item->data(Qt::UserRole).value<void*>());
    if (!quest) return;

    m_selectedQuest = quest;

    // Build HTML for details
    QString html;
    html += QString("<h2 style='color: %1;'>%2</h2>").arg(Theme::PRIMARY.name()).arg(quest->title);
    html += QString("<p style='margin-bottom: 10px;'><b>Status:</b> <span style='color: %1;'>%2</span></p>")
            .arg(quest->isActive() ? Theme::ACCENT.name() :
                 quest->isComplete() ? Theme::MUTED_FOREGROUND.name() : Theme::PRIMARY.name())
            .arg(quest->status.toUpper());

    // Description
    html += QString("<p style='margin-bottom: 15px;'>%1</p>").arg(quest->longDescription.isEmpty() ? quest->description : quest->longDescription);

    // Objectives
    html += QString("<h3 style='color: %1; margin-top: 15px;'>Objectives:</h3>").arg(Theme::ACCENT.name());
    html += "<ul style='margin-left: 20px;'>";
    for (const QuestObjective &obj : quest->objectives) {
        QString checkmark = obj.completed ? "✓" : "○";
        QString color = obj.completed ? Theme::ACCENT.name() : Theme::FOREGROUND.name();
        html += QString("<li style='color: %1; margin: 5px 0;'>%2 %3</li>")
                .arg(color)
                .arg(checkmark)
                .arg(getObjectiveText(obj));
    }
    html += "</ul>";

    // Rewards
    html += QString("<h3 style='color: %1; margin-top: 15px;'>Rewards:</h3>").arg(Theme::ACCENT.name());
    html += QString("<p style='margin-left: 20px;'>");
    if (quest->rewards.experience > 0) {
        html += QString("<b>XP:</b> %1<br>").arg(quest->rewards.experience);
    }
    if (quest->rewards.gold > 0) {
        html += QString("<b>Gold:</b> %1<br>").arg(quest->rewards.gold);
    }
    if (!quest->rewards.itemNames.isEmpty()) {
        html += QString("<b>Items:</b> %1<br>").arg(quest->rewards.itemNames.join(", "));
    }
    html += "</p>";

    // Prerequisites (if locked)
    if (quest->isLocked()) {
        html += QString("<h3 style='color: %1; margin-top: 15px;'>Requirements:</h3>").arg(Theme::DESTRUCTIVE.name());
        html += "<p style='margin-left: 20px;'>";
        if (quest->minimumLevel > 1) {
            html += QString("<b>Level:</b> %1<br>").arg(quest->minimumLevel);
        }
        if (!quest->prerequisiteQuestIds.isEmpty()) {
            html += QString("<b>Complete:</b> %1 quest(s)<br>").arg(quest->prerequisiteQuestIds.size());
        }
        html += "</p>";
    }

    m_questDetails->setHtml(html);

    // Show accept button if quest is available
    m_acceptButton->setVisible(quest->isAvailable());
}

void QuestLogPage::handleAcceptQuest()
{
    if (!m_selectedQuest || !m_questManager) return;

    if (m_selectedQuest->isAvailable()) {
        emit questAccepted(m_selectedQuest->questId);
        // Refresh the quest list
        updateQuests(m_questManager, m_currentPlayer);
    }
}

void QuestLogPage::handleBackClicked()
{
    emit backRequested();
}

void QuestLogPage::clearQuests()
{
    m_questList->clear();
    m_questDetails->setHtml("<p style='color: " + Theme::MUTED_FOREGROUND.name() + ";'>Select a quest to view details.</p>");
    m_acceptButton->setVisible(false);
    m_selectedQuest = nullptr;
}

QString QuestLogPage::getStatusBadge(const Quest* quest) const
{
    if (!quest) return "";

    if (quest->isActive()) {
        return QString("[%1/%2]").arg(quest->getProgress()).arg(quest->getTotalObjectives());
    } else if (quest->isComplete()) {
        return "[✓]";
    } else if (quest->isAvailable()) {
        return "[!]";
    } else {
        return "[🔒]";
    }
}

QString QuestLogPage::getObjectiveText(const QuestObjective &obj) const
{
    QString text = obj.description;

    // Add progress if not completed
    if (!obj.completed && obj.required > 0) {
        text += QString(" (%1/%2)").arg(obj.current).arg(obj.required);
    }

    return text;
}

void QuestLogPage::keyPressEvent(QKeyEvent *event)
{
    switch (event->key()) {
        case Qt::Key_Escape:
            emit backRequested();
            break;
        case Qt::Key_A:
            if (m_acceptButton->isVisible()) {
                handleAcceptQuest();
            }
            break;
        case Qt::Key_1:
        case Qt::Key_2:
        case Qt::Key_3:
        case Qt::Key_4:
        case Qt::Key_5:
        case Qt::Key_6:
        case Qt::Key_7:
        case Qt::Key_8:
        case Qt::Key_9: {
            int index = event->key() - Qt::Key_1;  // 0-8
            if (index < m_questList->count()) {
                QListWidgetItem *item = m_questList->item(index);
                if (item && item->flags() & Qt::ItemIsSelectable) {
                    m_questList->setCurrentItem(item);
                    handleQuestClicked(item);
                }
            }
            break;
        }
        default:
            QWidget::keyPressEvent(event);
    }
}
