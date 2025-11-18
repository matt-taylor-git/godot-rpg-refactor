#ifndef ITEMCARD_H
#define ITEMCARD_H

#include <QFrame>
#include <QPixmap>
#include <QMouseEvent>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMap>
#include "../../src/models/Item.h"

class QPushButton;
class QLabel;

class ItemCard : public QFrame
{
    Q_OBJECT

signals:
    void clicked(Item *item);
    void actionClicked(Item *item, const QString &action);

public:
    explicit ItemCard(Item *item, const QString &actionText = "Select", bool showPrice = false, QWidget *parent = nullptr);

private:
    void setupUi();
    void setupDragDrop();
    QString getStatsText() const;
    QString getTooltipText() const;
    QString getEffectDescription() const;
    QLabel *getItemIconLabel() const;
    QPixmap getWeaponPixmap(const QString &weaponName) const;

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dropEvent(QDropEvent *event) override;

private:
    Item *m_item;
    QString m_actionText;
    bool m_showPrice;
    QPushButton *m_actionBtn;
};

#endif // ITEMCARD_H
