#ifndef MONSTERTYPEREGISTRY_H
#define MONSTERTYPEREGISTRY_H

#include <QString>
#include <QStringList>
#include <QMap>

struct MonsterTypeInfo {
    QString displayName;      // "Shadow Wolf" - name shown in combat
    QString factoryKey;       // "shadow_wolf" - input to MonsterFactory
    QString enemyType;        // "wolf", "boss", "final_boss" - category
    bool isBoss;             // true for boss monsters
    bool isFinalBoss;        // true for final boss only
};

class MonsterTypeRegistry
{
public:
    // Access all registered monster types
    static QList<MonsterTypeInfo> getAllMonsterTypes();

    // Get specific monster type info
    static MonsterTypeInfo getMonsterTypeInfo(const QString &typeName);

    // Check if monster type exists (case-insensitive)
    static bool isValidMonsterType(const QString &typeName);

    // Get all valid type names for factory input
    static QStringList getAllValidTypeNames();

    // Backward compatibility: Get aliases for old monster names
    static QStringList getAliases(const QString &typeName);

    // Find type by display name (for quest matching)
    static QString getTypeNameFromDisplayName(const QString &displayName);

private:
    static void initializeRegistry();

    // Registry data - populated once on first access
    static QMap<QString, MonsterTypeInfo> s_registry;
    static QMap<QString, QString> s_displayNameToType;  // "Shadow Wolf" -> "shadow_wolf"
    static QMap<QString, QString> s_aliases;            // "Wild Wolf" -> "shadow_wolf"
};

#endif // MONSTERTYPEREGISTRY_H
