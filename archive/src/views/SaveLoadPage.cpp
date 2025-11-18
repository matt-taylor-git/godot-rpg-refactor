#include <QString>
#include <QDateTime>
#include "../persistence/SaveManager.h"
#include "SaveLoadPage.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QListWidget>
#include <QPushButton>
#include <QFrame>
#include <QMessageBox>
#include <QKeyEvent>
#include <vector>

SaveLoadPage::SaveLoadPage(QWidget *parent) : QWidget(parent)
{
    setupUi();
    refreshSaveSlots();
}

void SaveLoadPage::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    QLabel *title = new QLabel("Save & Load Game");
    title->setStyleSheet("font-size: 24px; font-weight: bold;");
    mainLayout->addWidget(title, 0, Qt::AlignCenter);

    QHBoxLayout *contentLayout = new QHBoxLayout();
    contentLayout->setSpacing(Theme::SPACING_LG);

    // Left side: Saves list
    QFrame *savesSection = new QFrame();
    QVBoxLayout *savesLayout = new QVBoxLayout(savesSection);
    m_savesList = new QListWidget();
    m_savesList->setMinimumHeight(400);
    savesLayout->addWidget(new QLabel("Save Slots"));
    savesLayout->addWidget(m_savesList);
    m_deleteButton = new QPushButton("Delete Slot");
    savesLayout->addWidget(m_deleteButton);
    contentLayout->addWidget(savesSection);

    // Right side: Actions
    QFrame *actionsSection = new QFrame();
    QVBoxLayout *actionsLayout = new QVBoxLayout(actionsSection);
    m_quickSaveButton = new QPushButton("Quick Save");
    m_quickLoadButton = new QPushButton("Quick Load");
    m_saveSelectedButton = new QPushButton("Save to Selected Slot");
    m_loadSelectedButton = new QPushButton("Load Selected Slot");
    m_backButton = new QPushButton("Back");
    actionsLayout->addWidget(new QLabel("Actions"));
    actionsLayout->addWidget(m_quickSaveButton);
    actionsLayout->addWidget(m_quickLoadButton);
    actionsLayout->addWidget(m_saveSelectedButton);
    actionsLayout->addWidget(m_loadSelectedButton);
    actionsLayout->addStretch();
    actionsLayout->addWidget(m_backButton);
    contentLayout->addWidget(actionsSection);

    mainLayout->addLayout(contentLayout);

    // Connect buttons
    connect(m_quickSaveButton, &QPushButton::clicked, this, &SaveLoadPage::onQuickSaveClicked);
    connect(m_quickLoadButton, &QPushButton::clicked, this, &SaveLoadPage::onQuickLoadClicked);
    connect(m_saveSelectedButton, &QPushButton::clicked, this, &SaveLoadPage::onSaveSelectedClicked);
    connect(m_loadSelectedButton, &QPushButton::clicked, this, &SaveLoadPage::onLoadSelectedClicked);
    connect(m_deleteButton, &QPushButton::clicked, this, &SaveLoadPage::onDeleteClicked);
    connect(m_backButton, &QPushButton::clicked, this, &SaveLoadPage::onBackClicked);
}

void SaveLoadPage::refreshSaveSlots()
{
    // Prevent multiple simultaneous refreshes
    if (m_isRefreshing) {
        return;
    }

    m_isRefreshing = true;
    setEnabled(false); // Disable all buttons during refresh

    m_savesList->clear();

    SaveManager saveManager;
    auto save_slots = saveManager.getSaveSlots();

    for (const SaveSlotInfo &slot : save_slots) {
        QString itemText;
        if (slot.exists) {
            itemText = QString("Slot %1: %2 (Level %3) - %4")
                .arg(slot.slotNumber)
                .arg(slot.characterName)
                .arg(slot.level)
                .arg(slot.saveTime.toString("yyyy-MM-dd hh:mm"));
        } else {
            itemText = QString("Slot %1: [Empty]").arg(slot.slotNumber);
        }

        QListWidgetItem *item = new QListWidgetItem(itemText);
        item->setData(Qt::UserRole, slot.slotNumber);
        m_savesList->addItem(item);
    }

    setEnabled(true);
    m_isRefreshing = false;
}

int SaveLoadPage::getSelectedSlotNumber() const
{
    QListWidgetItem *currentItem = m_savesList->currentItem();
    if (!currentItem) {
        return -1;
    }
    return currentItem->data(Qt::UserRole).toInt();
}

void SaveLoadPage::onQuickSaveClicked()
{
    emit quickSaveRequested();
}

void SaveLoadPage::onQuickLoadClicked()
{
    emit quickLoadRequested();
}

void SaveLoadPage::onSaveSelectedClicked()
{
    int slotNumber = getSelectedSlotNumber();
    if (slotNumber < 0) {
        QMessageBox::warning(this, "No Slot Selected", "Please select a save slot first.");
        return;
    }

    emit saveToSlotRequested(slotNumber);
}

void SaveLoadPage::onLoadSelectedClicked()
{
    int slotNumber = getSelectedSlotNumber();
    if (slotNumber < 0) {
        QMessageBox::warning(this, "No Slot Selected", "Please select a save slot first.");
        return;
    }

    // Check if slot has a save
    SaveManager saveManager;
    SaveSlotInfo info = saveManager.getSlotInfo(slotNumber);
    if (!info.exists) {
        QMessageBox::warning(this, "Empty Slot", "This save slot is empty.");
        return;
    }

    emit loadFromSlotRequested(slotNumber);
}

void SaveLoadPage::onDeleteClicked()
{
    int slotNumber = getSelectedSlotNumber();
    if (slotNumber < 0) {
        QMessageBox::warning(this, "No Slot Selected", "Please select a save slot first.");
        return;
    }

    // Check if slot has a save
    SaveManager saveManager;
    SaveSlotInfo info = saveManager.getSlotInfo(slotNumber);
    if (!info.exists) {
        QMessageBox::information(this, "Empty Slot", "This save slot is already empty.");
        return;
    }

    // Confirm deletion
    QMessageBox::StandardButton reply = QMessageBox::question(
        this,
        "Confirm Delete",
        QString("Are you sure you want to delete save slot %1 (%2)?").arg(slotNumber).arg(info.characterName),
        QMessageBox::Yes | QMessageBox::No
    );

    if (reply == QMessageBox::Yes) {
        emit deleteSlotRequested(slotNumber);
    }
}

void SaveLoadPage::onBackClicked()
{
    emit backRequested();
}

void SaveLoadPage::keyPressEvent(QKeyEvent *event)
{
    switch (event->key()) {
        case Qt::Key_Escape:
            emit backRequested();
            event->accept();
            break;
        case Qt::Key_Q:
            emit quickSaveRequested();
            event->accept();
            break;
        case Qt::Key_W:
            emit quickLoadRequested();
            event->accept();
            break;
        case Qt::Key_Up:
            if (m_savesList->currentRow() > 0) {
                m_savesList->setCurrentRow(m_savesList->currentRow() - 1);
            }
            event->accept();
            break;
        case Qt::Key_Down:
            if (m_savesList->currentRow() < m_savesList->count() - 1) {
                m_savesList->setCurrentRow(m_savesList->currentRow() + 1);
            }
            event->accept();
            break;
        case Qt::Key_Return:
        case Qt::Key_Enter:
            // Trigger save or load based on context (assume save for now, or check mode)
            emit saveToSlotRequested(m_savesList->currentRow() + 1);  // Slots are 1-based
            event->accept();
            break;
        // TODO: Add number keys 1-9 for direct slot selection
        default:
            QWidget::keyPressEvent(event);
            break;
    }
}