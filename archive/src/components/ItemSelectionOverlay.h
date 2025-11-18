#ifndef ITEMSELECTIONOVERLAY_H
#define ITEMSELECTIONOVERLAY_H

#include <QDialog>
#include <QList>
#include "../../src/models/Item.h"

class QGridLayout;

class ItemSelectionOverlay : public QDialog
{
    Q_OBJECT

signals:
    void itemSelected(Item *item);

public:
    explicit ItemSelectionOverlay(const QList<Item*> &items, const QString &title = "Select Item", const QString &actionText = "Select", bool showPrice = false, QWidget *parent = nullptr);

private slots:
    void onItemSelected(Item *item, const QString &action);

private:
    void initUi();
    void refreshGrid();
    void clearGrid();

    QList<Item*> m_items;
    QString m_titleText;
    QString m_actionText;
    bool m_showPrice;
    QGridLayout *m_gridLayout;

protected:
    void showEvent(QShowEvent *event) override;
};

#endif // ITEMSELECTIONOVERLAY_H
