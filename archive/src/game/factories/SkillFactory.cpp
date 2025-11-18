#include "SkillFactory.h"

QList<Skill*> SkillFactory::getSkillsForClass(const QString &characterClass)
{
    QList<Skill*> skills;

    if (characterClass == "Warrior" || characterClass == "warrior") {
        skills.append(new Skill("Power Strike", "physical", 25, 10, "A powerful melee attack"));
        skills.append(new Skill("Shield Bash", "physical", 15, 8, "Bash enemy with shield, chance to stun"));
        skills.append(new Skill("Whirlwind", "physical", 40, 20, "Attack dealing damage based on strength"));
        skills.append(new Skill("Battle Cry", "buff", 0, 15, "Increase attack power for 3 turns"));
    }
    else if (characterClass == "Mage" || characterClass == "mage") {
        skills.append(new Skill("Fireball", "magic", 30, 12, "Hurl a ball of fire at the enemy"));
        skills.append(new Skill("Ice Shard", "magic", 20, 10, "Sharp ice deals damage and may slow"));
        skills.append(new Skill("Lightning Bolt", "magic", 45, 25, "Powerful electric attack"));
        skills.append(new Skill("Mana Shield", "buff", 0, 20, "Absorb damage using mana"));
    }
    else if (characterClass == "Rogue" || characterClass == "rogue") {
        skills.append(new Skill("Backstab", "physical", 35, 12, "Critical strike from shadows"));
        skills.append(new Skill("Poison Blade", "physical", 18, 10, "Attack that poisons the target"));
        skills.append(new Skill("Shadow Step", "buff", 0, 15, "Increase evasion greatly"));
        skills.append(new Skill("Dual Strike", "physical", 28, 14, "Two quick attacks"));
    }
    else {
        // Default/Hero skills
        skills.append(new Skill("Strike", "physical", 20, 8, "A basic attack"));
        skills.append(new Skill("Focus", "buff", 0, 10, "Increase next attack damage"));
    }

    return skills;
}

Skill* SkillFactory::createSkill(const QString &name)
{
    // Warrior skills
    if (name == "Power Strike") return new Skill("Power Strike", "physical", 25, 10, "A powerful melee attack");
    if (name == "Shield Bash") return new Skill("Shield Bash", "physical", 15, 8, "Bash enemy with shield, chance to stun");
    if (name == "Whirlwind") return new Skill("Whirlwind", "physical", 40, 20, "Attack dealing damage based on strength");
    if (name == "Battle Cry") return new Skill("Battle Cry", "buff", 0, 15, "Increase attack power for 3 turns");

    // Mage skills
    if (name == "Fireball") return new Skill("Fireball", "magic", 30, 12, "Hurl a ball of fire at the enemy");
    if (name == "Ice Shard") return new Skill("Ice Shard", "magic", 20, 10, "Sharp ice deals damage and may slow");
    if (name == "Lightning Bolt") return new Skill("Lightning Bolt", "magic", 45, 25, "Powerful electric attack");
    if (name == "Mana Shield") return new Skill("Mana Shield", "buff", 0, 20, "Absorb damage using mana");

    // Rogue skills
    if (name == "Backstab") return new Skill("Backstab", "physical", 35, 12, "Critical strike from shadows");
    if (name == "Poison Blade") return new Skill("Poison Blade", "physical", 18, 10, "Attack that poisons the target");
    if (name == "Shadow Step") return new Skill("Shadow Step", "buff", 0, 15, "Increase evasion greatly");
    if (name == "Dual Strike") return new Skill("Dual Strike", "physical", 28, 14, "Two quick attacks");

    // Default skills
    if (name == "Strike") return new Skill("Strike", "physical", 20, 8, "A basic attack");
    if (name == "Focus") return new Skill("Focus", "buff", 0, 10, "Increase next attack damage");

    return nullptr;
}

QList<Skill*> SkillFactory::getStartingSkills(const QString &characterClass)
{
    QList<Skill*> startingSkills;

    if (characterClass == "Warrior" || characterClass == "warrior") {
        startingSkills.append(createSkill("Power Strike"));
        startingSkills.append(createSkill("Shield Bash"));
    }
    else if (characterClass == "Mage" || characterClass == "mage") {
        startingSkills.append(createSkill("Fireball"));
        startingSkills.append(createSkill("Ice Shard"));
    }
    else if (characterClass == "Rogue" || characterClass == "rogue") {
        startingSkills.append(createSkill("Backstab"));
        startingSkills.append(createSkill("Poison Blade"));
    }
    else {
        startingSkills.append(createSkill("Strike"));
    }

    return startingSkills;
}
