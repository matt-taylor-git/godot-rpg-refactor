#ifndef SAVEMANAGER_H
#define SAVEMANAGER_H

#include <QString>
#include <QList>
#include <QDateTime>
#include <vector>

class Player;

struct SaveSlotInfo {
    int slotNumber;
QString filePath;
QString characterName;
int level;
QDateTime saveTime;
bool exists;
};

class SaveManager
{
public:
    SaveManager();
    bool saveGame(Player *player, const QString &filePath);
    Player* loadGame(const QString &filePath);

    // Save slot management
    std::vector<SaveSlotInfo> getSaveSlots() const;
    bool saveToSlot(Player *player, int slotNumber);
    Player* loadFromSlot(int slotNumber);
    bool deleteSaveSlot(int slotNumber);
    QString getSlotFilePath(int slotNumber) const;
    SaveSlotInfo getSlotInfo(int slotNumber) const;

private:
    static const int MAX_SAVE_SLOTS = 10;
    QString getSavesDirectory() const;
    bool ensureSavesDirectoryExists() const;
};

#endif // SAVEMANAGER_H
