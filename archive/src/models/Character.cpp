#include "Character.h"

Character::Character(const QString &name, int level, int health, int maxHealth)
    : name(name), level(level), health(health), maxHealth(maxHealth)
{
}

bool Character::isAlive() const
{
    return health > 0;
}

QDataStream &operator<<(QDataStream &out, const Character &c)
{
    out << c.name << c.level << c.health << c.maxHealth;
    return out;
}

QDataStream &operator>>(QDataStream &in, Character &c)
{
    in >> c.name >> c.level >> c.health >> c.maxHealth;
    return in;
}
