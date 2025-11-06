#include "Skill.h"

Skill::Skill(const QString &name, const QString &skillType, int damage, int manaCost, const QString &description)
    : name(name), skillType(skillType), damage(damage), manaCost(manaCost), description(description)
{
}

QDataStream &operator<<(QDataStream &out, const Skill &s)
{
    out << s.name << s.skillType << s.damage << s.manaCost << s.description;
    return out;
}

QDataStream &operator>>(QDataStream &in, Skill &s)
{
    in >> s.name >> s.skillType >> s.damage >> s.manaCost >> s.description;
    return in;
}
