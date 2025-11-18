#include "Monster.h"

Monster::Monster(const QString &name, int level, const QString &enemyType)
    : Character(name, level, 50 + (level * 15), 50 + (level * 15)), // Base stats for a monster
      enemyType(enemyType),
      attack(8 + (level * 2)),
      defense(3 + (level * 1.5)),
      magicAttack(5 + (level * 1.5)),
      expReward(level * 25),
      goldReward(level * 5)
{
}
