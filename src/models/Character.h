#ifndef CHARACTER_H
#define CHARACTER_H

#include <QString>
#include <QDataStream>

class Character
{
public:
    explicit Character(const QString &name, int level, int health, int maxHealth);
    virtual ~Character() = default;

    QString name;
    int level;
    int health;
    int maxHealth;

    bool isAlive() const;

    friend QDataStream &operator<<(QDataStream &out, const Character &c);
    friend QDataStream &operator>>(QDataStream &in, Character &c);
};

#endif // CHARACTER_H

