#include "Item.h"

Item::Item()
    : name(""), itemType(""), rarity("common"), slot(""),
      attackBonus(0), defenseBonus(0), effect(""), power(0), value(0), description(""), loreId("")
{
}

Item::Item(const QString &name, const QString &itemType, const QString &rarity,
           const QString &slot, int attackBonus, int defenseBonus,
           const QString &effect, int power, int value, const QString &description,
           const QString &loreId)
    : name(name), itemType(itemType), rarity(rarity), slot(slot),
      attackBonus(attackBonus), defenseBonus(defenseBonus), effect(effect),
      power(power), value(value), description(description), loreId(loreId)
{
}

QDataStream &operator<<(QDataStream &out, const Item &item)
{
    out << quint32(2);  // Version 2: Added loreId field
    out << item.name << item.itemType << item.rarity << item.slot
        << item.attackBonus << item.defenseBonus << item.effect
        << item.power << item.value << item.description
        << item.loreId;  // NEW in version 2
    return out;
}

QDataStream &operator>>(QDataStream &in, Item &item)
{
    quint32 version;
    in >> version;

    in >> item.name >> item.itemType >> item.rarity >> item.slot
       >> item.attackBonus >> item.defenseBonus >> item.effect
       >> item.power >> item.value >> item.description;

    // CRITICAL: Backward compatibility for version 1 saves
    if (version >= 2) {
        in >> item.loreId;
    } else {
        item.loreId = "";  // Default for old saves (no crash)
    }

    return in;
}

