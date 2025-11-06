#ifndef SHOPPAGE_H
#define SHOPPAGE_H

#include <QWidget>

class QLabel;
class QKeyEvent;
class QGridLayout;
class QPushButton;
class Player;
class Item;

class ShopPage : public QWidget
{
    Q_OBJECT
public:
    explicit ShopPage(QWidget *parent = nullptr);

    void updateShop(Player *player);

signals:
    void leaveRequested();
    void itemPurchased(Item *item);
    void itemSold(Item *item, int goldReceived);
    void loreUnlockedFromPurchase(const QString &loreId);

protected:
    void keyPressEvent(QKeyEvent *event) override;

private:
    void setupUi();
    void clearShop();
    QWidget* createShopItemCard(Item *item, int price);
    void handleBuyClicked(Item *item, int price);
    void handleSellClicked();
    void onItemSelectedForSell(Item *item);
    void updateSelectionDisplay();

    QLabel *m_goldLabel;
    QGridLayout *m_shopGridLayout;
    QPushButton *m_sellButton;
    QPushButton *m_leaveButton;
    Player *m_currentPlayer;

    QList<QPair<Item*, int>> m_shopItems;  // item and price
    QList<QWidget*> m_itemCards;
    int m_selectedIndex;
};

#endif // SHOPPAGE_H