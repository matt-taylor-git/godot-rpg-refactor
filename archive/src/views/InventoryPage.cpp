#include "InventoryPage.h"
#include "../models/Player.h"
#include "../models/Item.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QScrollArea>
#include <QGridLayout>
#include <QPushButton>
#include <QFrame>
#include <QMessageBox>
#include <QKeyEvent>

InventoryPage::InventoryPage(QWidget *parent)
: QWidget(parent), m_currentPlayer(nullptr), m_selectedIndex(0)
{
setupUi();
}

void InventoryPage::setupUi()
{
    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    // Left side: Inventory
    QVBoxLayout *inventoryLayout = new QVBoxLayout();

    QHBoxLayout *headerLayout = new QHBoxLayout();
    QLabel *title = new QLabel("Inventory");
    title->setStyleSheet("font-size: 18px; font-weight: bold;");
    m_goldLabel = new QLabel("Gold: 0");
    m_goldLabel->setStyleSheet("font-size: 16px; font-weight: bold; color: #e5c07b;");
    headerLayout->addWidget(title);
    headerLayout->addStretch();
    headerLayout->addWidget(m_goldLabel);
    inventoryLayout->addLayout(headerLayout);

    QScrollArea *scrollArea = new QScrollArea();
    scrollArea->setWidgetResizable(true);
    scrollArea->setStyleSheet(QString("QScrollArea { border: none; background-color: %1; }").arg(Theme::BACKGROUND.name()));
    QWidget *scrollContent = new QWidget();
    scrollContent->setStyleSheet(QString("background-color: %1;").arg(Theme::BACKGROUND.name()));
    m_inventoryGridLayout = new QGridLayout(scrollContent);
    m_inventoryGridLayout->setSpacing(Theme::SPACING_MD);
    scrollArea->setWidget(scrollContent);
    inventoryLayout->addWidget(scrollArea);

    mainLayout->addLayout(inventoryLayout, 3);

    // Right side: Equipment panel (placeholder, will be populated in updateInventory)
    m_equipmentPanel = new QFrame();
    m_equipmentPanel->setStyleSheet(QString(
        "QFrame { background-color: %1; border-radius: %2px; border: 2px solid %3; }"
    ).arg(Theme::CARD.name()).arg(Theme::BORDER_RADIUS_MD).arg(Theme::BORDER.name()));
    m_equipmentPanel->setMinimumWidth(250);
    mainLayout->addWidget(m_equipmentPanel, 1);
}

void InventoryPage::updateInventory(Player *player)
{
m_currentPlayer = player;
m_items.clear();
    m_itemCards.clear();
m_selectedIndex = 0;
    clearInventory();

    if (!player) return;

m_goldLabel->setText(QString("Gold: %1").arg(player->gold));

    // Populate inventory items
int row = 0, col = 0;
const int columns = 3;

for (Item *item : player->inventory) {
if (!item) continue;

m_items.append(item);
QWidget *itemCard = createItemCard(item);
m_itemCards.append(itemCard);
m_inventoryGridLayout->addWidget(itemCard, row, col);

    col++;
        if (col >= columns) {
            col = 0;
            row++;
        }
    }

    updateSelectionDisplay();

    if (player->inventory.isEmpty()) {
        QLabel *emptyLabel = new QLabel("Your inventory is empty.");
        emptyLabel->setAlignment(Qt::AlignCenter);
        emptyLabel->setStyleSheet(QString("color: %1; font-size: 14px;").arg(Theme::MUTED_FOREGROUND.name()));
        m_inventoryGridLayout->addWidget(emptyLabel, 0, 0, 1, columns);
    }

    // Update equipment panel
    QWidget *equipPanel = createEquipmentPanel(player);
    // Clear old equipment panel layout
    if (m_equipmentPanel->layout()) {
        QLayoutItem *item;
        while ((item = m_equipmentPanel->layout()->takeAt(0)) != nullptr) {
            delete item->widget();
            delete item;
        }
        delete m_equipmentPanel->layout();
    }
    QVBoxLayout *equipLayout = qobject_cast<QVBoxLayout*>(equipPanel->layout());
    if (equipLayout) {
        m_equipmentPanel->setLayout(equipLayout);
    }
}

void InventoryPage::updateSelectionDisplay()
{
    // TODO: Add visual selection indicator (border, highlight, etc.)
    // For now, just ensure index is valid
    if (m_selectedIndex < 0) m_selectedIndex = 0;
    if (m_selectedIndex >= m_items.size() && m_items.size() > 0) m_selectedIndex = m_items.size() - 1;
}

void InventoryPage::clearInventory()
{
    while (m_inventoryGridLayout->count() > 0) {
        QLayoutItem *item = m_inventoryGridLayout->takeAt(0);
        if (item->widget()) {
            delete item->widget();
        }
        delete item;
    }
}

QWidget* InventoryPage::createItemCard(Item *item)
{
    QFrame *card = new QFrame();
    card->setStyleSheet(QString(
        "QFrame {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: 8px;"
        "    padding: 8px;"
        "}"
        "QFrame:hover {"
        "    border-color: %3;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::PRIMARY.name()));
    card->setMinimumSize(150, 120);
    card->setCursor(Qt::PointingHandCursor);

    QVBoxLayout *layout = new QVBoxLayout(card);

    // Item name
    QLabel *nameLabel = new QLabel(item->name);
    nameLabel->setStyleSheet("font-weight: bold; font-size: 13px;");
    nameLabel->setWordWrap(true);
    layout->addWidget(nameLabel);

    // Item type
    QLabel *typeLabel = new QLabel(item->itemType);
    typeLabel->setStyleSheet(QString("color: %1; font-size: 11px;").arg(Theme::MUTED_FOREGROUND.name()));
    layout->addWidget(typeLabel);

    // Stats
    QString statsText;
    if (item->attackBonus > 0) statsText += QString("+%1 ATK ").arg(item->attackBonus);
    if (item->defenseBonus > 0) statsText += QString("+%1 DEF ").arg(item->defenseBonus);
    if (item->power > 0 && item->itemType == "consumable") statsText += QString("Restores %1").arg(item->power);

    if (!statsText.isEmpty()) {
        QLabel *statsLabel = new QLabel(statsText);
        statsLabel->setStyleSheet(QString("color: %1; font-size: 10px;").arg(Theme::ACCENT.name()));
        statsLabel->setWordWrap(true);
        layout->addWidget(statsLabel);
    }

    layout->addStretch();

    // Action button
    QPushButton *actionBtn = new QPushButton(item->itemType == "consumable" ? "Use" : "Equip");
    actionBtn->setMinimumHeight(30);
    actionBtn->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    font-size: 11px;"
        "    border-radius: 4px;"
        "}"
        "QPushButton:hover { background-color: %3; }"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::PRIMARY.lighter(110).name()));
    connect(actionBtn, &QPushButton::clicked, [this, item]() {
        handleItemClicked(item);
    });
    layout->addWidget(actionBtn);

    return card;
}

QWidget* InventoryPage::createEquipmentPanel(Player *player)
{
    QWidget *panel = new QWidget();
    QVBoxLayout *layout = new QVBoxLayout(panel);
    layout->setSpacing(Theme::SPACING_MD);

    QLabel *title = new QLabel("Equipment");
    title->setStyleSheet("font-size: 16px; font-weight: bold;");
    layout->addWidget(title);

    // Weapon slot
    QFrame *weaponFrame = new QFrame();
    weaponFrame->setStyleSheet(QString("background-color: %1; border-radius: 6px; padding: 10px;").arg(Theme::MUTED.name()));
    QVBoxLayout *weaponLayout = new QVBoxLayout(weaponFrame);
    weaponLayout->addWidget(new QLabel("⚔️ Weapon"));
    m_weaponSlot = new QLabel(player->equipment["weapon"] ? player->equipment["weapon"]->name : "Empty");
    m_weaponSlot->setStyleSheet("font-size: 12px;");
    m_weaponSlot->setWordWrap(true);
    weaponLayout->addWidget(m_weaponSlot);
    layout->addWidget(weaponFrame);

    // Armor slot
    QFrame *armorFrame = new QFrame();
    armorFrame->setStyleSheet(QString("background-color: %1; border-radius: 6px; padding: 10px;").arg(Theme::MUTED.name()));
    QVBoxLayout *armorLayout = new QVBoxLayout(armorFrame);
    armorLayout->addWidget(new QLabel("🛡️ Armor"));
    m_armorSlot = new QLabel(player->equipment["armor"] ? player->equipment["armor"]->name : "Empty");
    m_armorSlot->setStyleSheet("font-size: 12px;");
    m_armorSlot->setWordWrap(true);
    armorLayout->addWidget(m_armorSlot);
    layout->addWidget(armorFrame);

    // Accessory slot
    QFrame *accessoryFrame = new QFrame();
    accessoryFrame->setStyleSheet(QString("background-color: %1; border-radius: 6px; padding: 10px;").arg(Theme::MUTED.name()));
    QVBoxLayout *accessoryLayout = new QVBoxLayout(accessoryFrame);
    accessoryLayout->addWidget(new QLabel("💍 Accessory"));
    m_accessorySlot = new QLabel(player->equipment["accessory"] ? player->equipment["accessory"]->name : "Empty");
    m_accessorySlot->setStyleSheet("font-size: 12px;");
    m_accessorySlot->setWordWrap(true);
    accessoryLayout->addWidget(m_accessorySlot);
    layout->addWidget(accessoryFrame);

    layout->addStretch();

    return panel;
}

void InventoryPage::handleItemClicked(Item *item)
{
    if (!item || !m_currentPlayer) return;

    if (item->itemType == "consumable") {
        // Use consumable
        QString itemName = item->name;  // Save name before deletion
        if (m_currentPlayer->useItem(item)) {
            emit itemUsed(item);
            updateInventory(m_currentPlayer); // Refresh display
            QMessageBox::information(this, "Item Used", QString("Used %1!").arg(itemName));
            delete item;  // Caller must delete item after use to prevent memory leak
        }
    } else if (item->itemType == "weapon" || item->itemType == "armor" || item->itemType == "accessory") {
        // Equip item
        if (m_currentPlayer->equipItem(item)) {
            emit itemEquipped(item);
            updateInventory(m_currentPlayer); // Refresh display
            QMessageBox::information(this, "Item Equipped", QString("Equipped %1!").arg(item->name));
        }
    }
}

void InventoryPage::keyPressEvent(QKeyEvent *event)
{
    switch (event->key()) {
        case Qt::Key_Escape:
            emit backRequested();
            event->accept();
            break;
        case Qt::Key_Up:
            if (m_selectedIndex >= 3) {  // Assuming 3 columns
                m_selectedIndex -= 3;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Down:
            if (m_selectedIndex + 3 < m_items.size()) {
                m_selectedIndex += 3;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Left:
            if (m_selectedIndex > 0) {
                m_selectedIndex--;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Right:
            if (m_selectedIndex + 1 < m_items.size()) {
                m_selectedIndex++;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Return:
        case Qt::Key_Enter:
            if (m_selectedIndex >= 0 && m_selectedIndex < m_items.size()) {
                handleItemClicked(m_items[m_selectedIndex]);
            }
            event->accept();
            break;
        default:
            QWidget::keyPressEvent(event);
            break;
    }
}