#ifndef SKILLFACTORY_H
#define SKILLFACTORY_H

#include "models/Skill.h"
#include <QList>
#include <QString>

class SkillFactory
{
public:
    static QList<Skill*> getSkillsForClass(const QString &characterClass);
    static Skill* createSkill(const QString &name);
    static QList<Skill*> getStartingSkills(const QString &characterClass);
};

#endif // SKILLFACTORY_H
