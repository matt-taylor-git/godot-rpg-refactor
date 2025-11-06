#include "ShopPage.h"
#include "../models/Player.h"
#include "../models/Item.h"
#include "../game/factories/ItemFactory.h"
#include "../theme/Theme.h"
#include "../components/ItemSelectionOverlay.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QScrollArea>
#include <QGridLayout>
#include <QPushButton>
#include <QFrame>
#include <QMessageBox>
#include <QKeyEvent>

ShopPage::ShopPage(QWidget *parent)
: QWidget(parent), m_currentPlayer(nullptr), m_selectedIndex(0)
{
setupUi();
}

void ShopPage::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    QHBoxLayout *headerLayout = new QHBoxLayout();
    QLabel *title = new QLabel("Merchant Shop");
    title->setStyleSheet("font-size: 18px; font-weight: bold;");
    m_goldLabel = new QLabel("Gold: 0");
    m_goldLabel->setStyleSheet("font-size: 16px; font-weight: bold; color: #e5c07b;");
    headerLayout->addWidget(title);
    headerLayout->addStretch();
    headerLayout->addWidget(m_goldLabel);
    mainLayout->addLayout(headerLayout);

    QScrollArea *scrollArea = new QScrollArea();
    scrollArea->setWidgetResizable(true);
    scrollArea->setStyleSheet(QString("QScrollArea { border: none; background-color: %1; }").arg(Theme::BACKGROUND.name()));
    QWidget *scrollContent = new QWidget();
    scrollContent->setStyleSheet(QString("background-color: %1;").arg(Theme::BACKGROUND.name()));
    m_shopGridLayout = new QGridLayout(scrollContent);
    m_shopGridLayout->setSpacing(Theme::SPACING_MD);
    scrollArea->setWidget(scrollContent);
    mainLayout->addWidget(scrollArea);

    QHBoxLayout *buttonLayout = new QHBoxLayout();
    m_sellButton = new QPushButton("💰 Sell Items");
    m_sellButton->setMinimumHeight(40);
    m_leaveButton = new QPushButton("⬅️ Leave Shop");
    m_leaveButton->setMinimumHeight(40);
    connect(m_leaveButton, &QPushButton::clicked, this, &ShopPage::leaveRequested);
    connect(m_sellButton, &QPushButton::clicked, this, &ShopPage::handleSellClicked);
    buttonLayout->addStretch();
    buttonLayout->addWidget(m_sellButton);
    buttonLayout->addWidget(m_leaveButton);
    mainLayout->addLayout(buttonLayout);
}

void ShopPage::updateShop(Player *player)
{
m_currentPlayer = player;
m_shopItems.clear();
    m_itemCards.clear();
m_selectedIndex = 0;
    clearShop();

    if (!player) return;

m_goldLabel->setText(QString("Gold: %1").arg(player->gold));

// Get shop items from ItemFactory
QMap<QString, Item*> shopItemsMap = ItemFactory::getShopItems();

    // Populate shop grid
int row = 0, col = 0;
const int columns = 4;

for (Item *item : shopItemsMap.values()) {
if (!item) continue;

// Calculate price (base value * 1.5 for shop markup)
int price = static_cast<int>(item->value * 1.5);

m_shopItems.append(qMakePair(item, price));
QWidget *itemCard = createShopItemCard(item, price);
m_itemCards.append(itemCard);
m_shopGridLayout->addWidget(itemCard, row, col);

    col++;
        if (col >= columns) {
            col = 0;
            row++;
        }
    }

    updateSelectionDisplay();
}

void ShopPage::updateSelectionDisplay()
{
    // TODO: Add visual selection indicator (border, highlight, etc.)
    // For now, just ensure index is valid
    if (m_selectedIndex < 0) m_selectedIndex = 0;
    if (m_selectedIndex >= m_shopItems.size() && m_shopItems.size() > 0) m_selectedIndex = m_shopItems.size() - 1;
}

void ShopPage::clearShop()
{
    while (m_shopGridLayout->count() > 0) {
        QLayoutItem *item = m_shopGridLayout->takeAt(0);
        if (item->widget()) {
            delete item->widget();
        }
        delete item;
    }
}

QWidget* ShopPage::createShopItemCard(Item *item, int price)
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
    card->setMinimumSize(150, 140);
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

    // Price
    QLabel *priceLabel = new QLabel(QString("💰 %1 Gold").arg(price));
    priceLabel->setStyleSheet("font-size: 12px; font-weight: bold; color: #e5c07b;");
    layout->addWidget(priceLabel);

    layout->addStretch();

    // Buy button
    QPushButton *buyBtn = new QPushButton("Buy");
    buyBtn->setMinimumHeight(30);
    buyBtn->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    font-size: 11px;"
        "    border-radius: 4px;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:disabled { background-color: %4; color: %5; }"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::PRIMARY.lighter(110).name())
     .arg(Theme::MUTED.name())
     .arg(Theme::MUTED_FOREGROUND.name()));

    // Disable button if player can't afford
    if (m_currentPlayer && m_currentPlayer->gold < price) {
        buyBtn->setEnabled(false);
    }

    connect(buyBtn, &QPushButton::clicked, [this, item, price]() {
        handleBuyClicked(item, price);
    });
    layout->addWidget(buyBtn);

    return card;
}

void ShopPage::handleBuyClicked(Item *item, int price)
{
    if (!item || !m_currentPlayer) return;

    // Check if player has enough gold
    if (m_currentPlayer->gold < price) {
        QMessageBox::warning(this, "Not Enough Gold",
            QString("You need %1 gold to buy %2.").arg(price).arg(item->name));
        return;
    }

    // Create a copy of the item for the player
    Item *purchasedItem = new Item(*item);

    // Deduct gold and add item to inventory
    m_currentPlayer->gold -= price;
    m_currentPlayer->inventory.append(purchasedItem);

    // Unlock lore entry if item has associated lore (Phase 5)
    if (!purchasedItem->loreId.isEmpty()) {
        if (!m_currentPlayer->hasUnlockedLore(purchasedItem->loreId)) {
            m_currentPlayer->unlockLore(purchasedItem->loreId);
            emit loreUnlockedFromPurchase(purchasedItem->loreId);
        }
    }

    emit itemPurchased(purchasedItem);

    QMessageBox::information(this, "Purchase Successful",
        QString("You bought %1 for %2 gold!").arg(item->name).arg(price));

    // Refresh shop display
    updateShop(m_currentPlayer);
}

void ShopPage::handleSellClicked()
{
    if (!m_currentPlayer) return;

    // Check if player has items to sell
    if (m_currentPlayer->inventory.isEmpty()) {
        QMessageBox::information(this, "No Items",
            "You don't have any items to sell.");
        return;
    }

    // Create item selection dialog for selling
    ItemSelectionOverlay *sellDialog = new ItemSelectionOverlay(
        m_currentPlayer->inventory,
        "Select Item to Sell",
        "Sell",
        true,  // show price
        this
    );

    connect(sellDialog, &ItemSelectionOverlay::itemSelected,
            this, &ShopPage::onItemSelectedForSell);

    sellDialog->exec();
}

void ShopPage::onItemSelectedForSell(Item *item)
{
    if (!item || !m_currentPlayer) return;

    // Calculate sell price (typically half of item value)
    int sellPrice = item->value / 2;
    if (sellPrice <= 0) {
        QMessageBox::information(this, "Cannot Sell",
            QString("%1 cannot be sold.").arg(item->name));
        return;
    }

    // Remove item from inventory
    if (m_currentPlayer->inventory.removeOne(item)) {
        // Add gold to player
        m_currentPlayer->gold += sellPrice;

        // Emit signal
        emit itemSold(item, sellPrice);

        QMessageBox::information(this, "Item Sold",
            QString("You sold %1 for %2 gold!").arg(item->name).arg(sellPrice));

        // Refresh shop display
        updateShop(m_currentPlayer);

        // Clean up - delete the item
        delete item;
    } else {
        QMessageBox::warning(this, "Sell Failed",
            "Failed to remove item from inventory.");
    }
}

void ShopPage::keyPressEvent(QKeyEvent *event)
{
    switch (event->key()) {
        case Qt::Key_Escape:
            emit leaveRequested();
            event->accept();
            break;
        case Qt::Key_Up:
            if (m_selectedIndex >= 4) {  // Assuming 4 columns
                m_selectedIndex -= 4;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Down:
            if (m_selectedIndex + 4 < m_shopItems.size()) {
                m_selectedIndex += 4;
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
            if (m_selectedIndex + 1 < m_shopItems.size()) {
                m_selectedIndex++;
                updateSelectionDisplay();
            }
            event->accept();
            break;
        case Qt::Key_Return:
        case Qt::Key_Enter:
            if (m_selectedIndex >= 0 && m_selectedIndex < m_shopItems.size()) {
                auto [item, price] = m_shopItems[m_selectedIndex];
                handleBuyClicked(item, price);
            }
            event->accept();
            break;
        default:
            QWidget::keyPressEvent(event);
            break;
    }
}