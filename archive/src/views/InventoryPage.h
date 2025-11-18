#ifndef INVENTORYPAGE_H
#define INVENTORYPAGE_H

#include <QWidget>

class QLabel;
class QKeyEvent;
class QGridLayout;
class QPushButton;
class QFrame;
class Player;
class Item;

class InventoryPage : public QWidget
{
    Q_OBJECT
public:
    explicit InventoryPage(QWidget *parent = nullptr);
    void updateInventory(Player *player);

signals:
    void backRequested();
    void itemEquipped(Item *item);
    void itemUsed(Item *item);

protected:
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void handleItemClicked(Item *item);

private:
    void setupUi();
    void clearInventory();
    QWidget* createItemCard(Item *item);
    QWidget* createEquipmentPanel(Player *player);
    void updateSelectionDisplay();

    Player *m_currentPlayer;
    QLabel *m_goldLabel;
    QGridLayout *m_inventoryGridLayout;
    QFrame *m_equipmentPanel;
    QLabel *m_weaponSlot;
    QLabel *m_armorSlot;
    QLabel *m_accessorySlot;

    QList<Item*> m_items;
    QList<QWidget*> m_itemCards;
    int m_selectedIndex;
};

#endif // INVENTORYPAGE_H