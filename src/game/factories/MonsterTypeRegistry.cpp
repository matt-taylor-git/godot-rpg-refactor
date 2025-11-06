#include "MonsterTypeRegistry.h"

QMap<QString, MonsterTypeInfo> MonsterTypeRegistry::s_registry;
QMap<QString, QString> MonsterTypeRegistry::s_displayNameToType;
QMap<QString, QString> MonsterTypeRegistry::s_aliases;

void MonsterTypeRegistry::initializeRegistry()
{
    if (!s_registry.isEmpty()) return;  // Already initialized

    // Quest-relevant monsters (NEW)
    s_registry["shadow_wolf"] = {"Shadow Wolf", "shadow_wolf", "wolf", false, false};
    s_registry["shadow_lord"] = {"Shadow Lord", "shadow_lord", "boss", true, false};
    s_registry["dark_overlord"] = {"Dark Overlord", "dark_overlord", "final_boss", true, true};

    // Existing monsters (from MonsterFactory.cpp)
    s_registry["goblin"] = {"Goblin", "goblin", "goblin", false, false};
    s_registry["orc"] = {"Orc", "orc", "orc", false, false};
    s_registry["golem"] = {"Stone Golem", "golem", "golem", false, false};
    s_registry["skeleton"] = {"Skeleton Warrior", "skeleton", "skeleton", false, false};
    s_registry["bandit"] = {"Bandit", "bandit", "bandit", false, false};
    s_registry["wolf"] = {"Wild Wolf", "wolf", "wolf", false, false};
    s_registry["spider"] = {"Giant Spider", "spider", "spider", false, false};
    s_registry["slime"] = {"Slime", "slime", "slime", false, false};
    s_registry["orc_chieftain"] = {"Orc Chieftain", "orc_chieftain", "boss", true, false};
    s_registry["eternal_shadow"] = {"The Eternal Shadow", "eternal_shadow", "final_boss", true, true};

    // Build display name lookup
    for (auto it = s_registry.begin(); it != s_registry.end(); ++it) {
        s_displayNameToType[it.value().displayName] = it.key();
    }

    // Backward compatibility aliases
    s_aliases["Wild Wolf"] = "shadow_wolf";
    s_aliases["Shadow Wolf"] = "shadow_wolf";
    s_aliases["Orc Chieftain"] = "shadow_lord";  // Map old to new for backward compatibility
    s_aliases["Shadow Lord"] = "shadow_lord";
    s_aliases["The Eternal Shadow"] = "dark_overlord";
    s_aliases["Dark Overlord"] = "dark_overlord";
}

QList<MonsterTypeInfo> MonsterTypeRegistry::getAllMonsterTypes()
{
    initializeRegistry();
    return s_registry.values();
}

MonsterTypeInfo MonsterTypeRegistry::getMonsterTypeInfo(const QString &typeName)
{
    initializeRegistry();

    QString normalized = typeName.toLower();

    // Check direct type match
    if (s_registry.contains(normalized)) {
        return s_registry.value(normalized);
    }

    // Check alias match
    QString aliasType = s_aliases.value(typeName, QString());
    if (!aliasType.isEmpty()) {
        return s_registry.value(aliasType.toLower());
    }

    // Return empty struct if not found
    return MonsterTypeInfo();
}

bool MonsterTypeRegistry::isValidMonsterType(const QString &typeName)
{
    initializeRegistry();

    QString normalized = typeName.toLower();

    // Check direct type match
    if (s_registry.contains(normalized)) {
        return true;
    }

    // Check alias match
    if (s_aliases.contains(typeName)) {
        return true;
    }

    return false;
}

QStringList MonsterTypeRegistry::getAllValidTypeNames()
{
    initializeRegistry();
    return s_registry.keys();
}

QStringList MonsterTypeRegistry::getAliases(const QString &typeName)
{
    initializeRegistry();

    QStringList aliases;
    for (auto it = s_aliases.begin(); it != s_aliases.end(); ++it) {
        if (it.value() == typeName) {
            aliases.append(it.key());
        }
    }
    return aliases;
}

QString MonsterTypeRegistry::getTypeNameFromDisplayName(const QString &displayName)
{
    initializeRegistry();
    return s_displayNameToType.value(displayName, QString());
}
