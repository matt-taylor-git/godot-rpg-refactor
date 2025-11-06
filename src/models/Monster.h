#ifndef MONSTER_H
#define MONSTER_H

#include "Character.h"
#include <QString>

class Monster : public Character
{
public:
    Monster(const QString &name, int level, const QString &enemyType = "normal");

    QString enemyType;
    int attack;
    int defense;
    int magicAttack;
    int expReward;
    int goldReward;
};

#endif // MONSTER_H
