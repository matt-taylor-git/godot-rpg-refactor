#ifndef ITEM_H
#define ITEM_H

#include <QString>
#include <QDataStream>

class Item
{
public:
    Item();
    Item(const QString &name, const QString &itemType, const QString &rarity = "common",
         const QString &slot = "", int attackBonus = 0, int defenseBonus = 0,
         const QString &effect = "", int power = 0, int value = 0, const QString &description = "",
         const QString &loreId = "");

    QString name;
    QString itemType;
    QString rarity;
    QString slot;
    int attackBonus;
    int defenseBonus;
    QString effect;
    int power;
    int value;
    QString description;
    QString loreId;  // Links to LoreEntry (e.g., "item_ancient_blade")

    friend QDataStream &operator<<(QDataStream &out, const Item &item);
    friend QDataStream &operator>>(QDataStream &in, Item &item);
};

#endif // ITEM_H
