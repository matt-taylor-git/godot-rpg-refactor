#ifndef COMBATITEMDIALOG_H
#define COMBATITEMDIALOG_H

#include <QDialog>
#include <QList>

class QListWidget;
class QListWidgetItem;
class QPushButton;
class QLabel;
class Item;
class Player;

class CombatItemDialog : public QDialog
{
    Q_OBJECT

public:
    explicit CombatItemDialog(Player *player, QWidget *parent = nullptr);
    Item* getSelectedItem() const;

private slots:
    void handleItemSelected(QListWidgetItem *item);
    void handleUseItem();

private:
    void setupUi();
    void populateItems();

    Player *m_player;
    Item *m_selectedItem;

    QListWidget *m_itemList;
    QLabel *m_descriptionLabel;
    QLabel *m_effectLabel;
    QPushButton *m_useButton;
    QPushButton *m_cancelButton;
};

#endif // COMBATITEMDIALOG_H
