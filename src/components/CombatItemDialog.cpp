#include "CombatItemDialog.h"
#include "../models/Player.h"
#include "../models/Item.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QListWidget>
#include <QLabel>
#include <QPushButton>
#include <QFont>

CombatItemDialog::CombatItemDialog(Player *player, QWidget *parent)
    : QDialog(parent), m_player(player), m_selectedItem(nullptr)
{
    setWindowTitle("Use Item");
    setMinimumWidth(400);
    setMinimumHeight(500);
    setupUi();
    populateItems();
}

void CombatItemDialog::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);

    QLabel *title = new QLabel("Choose an Item to Use");
    QFont titleFont;
    titleFont.setPointSize(16);
    titleFont.setBold(true);
    title->setFont(titleFont);
    mainLayout->addWidget(title);

    m_itemList = new QListWidget();
    m_itemList->setStyleSheet(QString(
        "QListWidget {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: 8px;"
        "    padding: 8px;"
        "}"
        "QListWidget::item {"
        "    padding: 8px;"
        "    border-radius: 4px;"
        "    margin: 2px;"
        "}"
        "QListWidget::item:selected {"
        "    background-color: %3;"
        "    color: %4;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name()));
    connect(m_itemList, &QListWidget::itemClicked, this, &CombatItemDialog::handleItemSelected);
    mainLayout->addWidget(m_itemList);

    // Description panel
    QLabel *descTitle = new QLabel("Item Details:");
    descTitle->setStyleSheet("font-weight: bold; margin-top: 10px;");
    mainLayout->addWidget(descTitle);

    m_descriptionLabel = new QLabel("Select an item to see its details");
    m_descriptionLabel->setWordWrap(true);
    m_descriptionLabel->setStyleSheet(QString("color: %1; padding: 8px;").arg(Theme::FOREGROUND.name()));
    mainLayout->addWidget(m_descriptionLabel);

    m_effectLabel = new QLabel("");
    m_effectLabel->setStyleSheet(QString("font-weight: bold; color: %1;").arg(Theme::ACCENT.name()));
    mainLayout->addWidget(m_effectLabel);

    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    m_cancelButton = new QPushButton("Cancel");
    m_cancelButton->setMinimumHeight(40);
    connect(m_cancelButton, &QPushButton::clicked, this, &QDialog::reject);

    m_useButton = new QPushButton("Use Item");
    m_useButton->setMinimumHeight(40);
    m_useButton->setEnabled(false);
    m_useButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    font-weight: bold;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:disabled { background-color: %4; color: %5; }"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::PRIMARY.lighter(110).name())
     .arg(Theme::MUTED.name())
     .arg(Theme::MUTED_FOREGROUND.name()));
    connect(m_useButton, &QPushButton::clicked, this, &CombatItemDialog::handleUseItem);

    buttonLayout->addWidget(m_cancelButton);
    buttonLayout->addWidget(m_useButton);
    mainLayout->addLayout(buttonLayout);
}

void CombatItemDialog::populateItems()
{
    if (!m_player) return;

    // Only show consumable items
    for (Item *item : m_player->inventory) {
        if (!item) continue;

        // Only show items that can be used in combat (consumables)
        if (item->itemType != "consumable") continue;

        QString itemText = QString("%1 - %2").arg(item->name).arg(item->description);

        QListWidgetItem *listItem = new QListWidgetItem(itemText);
        listItem->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(item)));
        m_itemList->addItem(listItem);
    }

    if (m_itemList->count() == 0) {
        QListWidgetItem *item = new QListWidgetItem("No usable items in inventory");
        item->setFlags(item->flags() & ~Qt::ItemIsEnabled & ~Qt::ItemIsSelectable);
        m_itemList->addItem(item);
    }
}

void CombatItemDialog::handleItemSelected(QListWidgetItem *listItem)
{
    if (!listItem) return;

    Item *item = static_cast<Item*>(listItem->data(Qt::UserRole).value<void*>());
    if (!item) return;

    m_selectedItem = item;

    m_descriptionLabel->setText(item->description);

    QString effectText;
    if (item->effect == "heal") {
        effectText = QString("Effect: Restores %1 HP").arg(item->power);
    } else if (item->effect == "restore_mana") {
        effectText = QString("Effect: Restores %1 MP").arg(item->power);
    } else {
        effectText = QString("Effect: %1 (Power: %2)").arg(item->effect).arg(item->power);
    }
    m_effectLabel->setText(effectText);

    m_useButton->setEnabled(true);
}

void CombatItemDialog::handleUseItem()
{
    if (m_selectedItem) {
        accept();
    }
}

Item* CombatItemDialog::getSelectedItem() const
{
    return m_selectedItem;
}
