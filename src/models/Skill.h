#ifndef SKILL_H
#define SKILL_H

#include <QString>
#include <QDataStream>

class Skill
{
public:
    Skill(const QString &name = "", const QString &skillType = "", int damage = 0, int manaCost = 0, const QString &description = "");

    QString name;
    QString skillType;
    int damage;
    int manaCost;
    QString description;

    friend QDataStream &operator<<(QDataStream &out, const Skill &s);
    friend QDataStream &operator>>(QDataStream &in, Skill &s);
};

#endif // SKILL_H
