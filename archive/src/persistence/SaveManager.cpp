#include "SaveManager.h"
#include "../models/Player.h"
#include "../game/factories/ItemFactory.h"
#include <QFile>
#include <QDataStream>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <vector>

SaveManager::SaveManager()
{
}

bool SaveManager::saveGame(Player *player, const QString &filePath)
{
    if (!player) {
        qWarning() << "Cannot save game: player is null";
        return false;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Could not open file for writing:" << filePath;
        return false;
    }

    QDataStream out(&file);
    out.setVersion(QDataStream::Qt_6_0);

    // Write metadata header for quick loading
    out << QString("PYRPG_SAVE");  // Magic identifier
    out << quint32(2);  // Save file format version
    out << player->name;  // Character name
    out << player->level;  // Character level
    out << QDateTime::currentDateTime();  // Save time

    // Write full player data
    out << *player;

    file.close();
    return true;
}

Player* SaveManager::loadGame(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open file for reading:" << filePath;
        return nullptr;
    }

    QDataStream in(&file);
    in.setVersion(QDataStream::Qt_6_0);

    // Read and validate metadata header
    QString magic;
    in >> magic;
    if (magic != "PYRPG_SAVE") {
        qWarning() << "Invalid save file format (missing magic header):" << filePath;
        file.close();
        return nullptr;
    }

    quint32 saveVersion;
    in >> saveVersion;
    if (saveVersion > 2) {
        qWarning() << "Unsupported save file version:" << saveVersion;
        file.close();
        return nullptr;
    }

    // Skip metadata (we've already validated the header)
    QString metaName;
    int metaLevel;
    QDateTime metaTime;
    in >> metaName >> metaLevel >> metaTime;

    // Load full player data
    Player *player = new Player(""); // Create a dummy player
    in >> *player;

    file.close();
    return player;
}

QString SaveManager::getSavesDirectory() const
{
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dataDir.isEmpty()) {
        qWarning() << "Could not determine AppDataLocation, using fallback";
        // Fallback to a safe location
        dataDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.pyrpg";
    }
    return dataDir + "/saves";
}

bool SaveManager::ensureSavesDirectoryExists() const
{
    QDir dir;
    QString savesPath = getSavesDirectory();
    if (!dir.exists(savesPath)) {
        return dir.mkpath(savesPath);
    }
    return true;
}

QString SaveManager::getSlotFilePath(int slotNumber) const
{
    return getSavesDirectory() + QString("/save_slot_%1.dat").arg(slotNumber);
}

SaveSlotInfo SaveManager::getSlotInfo(int slotNumber) const
{
    SaveSlotInfo info;
    info.slotNumber = slotNumber;
    info.filePath = getSlotFilePath(slotNumber);
    info.exists = false;

    QFileInfo fileInfo(info.filePath);
    if (!fileInfo.exists()) {
        return info;
    }

    info.exists = true;
    info.saveTime = fileInfo.lastModified();

    // Read only the metadata header for performance
    QFile file(info.filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open file for reading metadata:" << info.filePath;
        return info;
    }

    QDataStream in(&file);
    in.setVersion(QDataStream::Qt_6_0);

    // Read and validate magic header
    QString magic;
    in >> magic;
    if (magic != "PYRPG_SAVE") {
        qWarning() << "Invalid save file format:" << info.filePath;
        file.close();
        return info;
    }

    // Read metadata
    quint32 saveVersion;
    in >> saveVersion;
    in >> info.characterName;
    in >> info.level;
    in >> info.saveTime;

    file.close();
    return info;
}

std::vector<SaveSlotInfo> SaveManager::getSaveSlots() const
{
    std::vector<SaveSlotInfo> slot_list {};
    for (int i = 1; i <= MAX_SAVE_SLOTS; ++i) {
        slot_list.push_back(getSlotInfo(i));
    }
    return slot_list;
}

bool SaveManager::saveToSlot(Player *player, int slotNumber)
{
    if (slotNumber < 1 || slotNumber > MAX_SAVE_SLOTS) {
        qWarning() << "Invalid slot number:" << slotNumber;
        return false;
    }

    if (!ensureSavesDirectoryExists()) {
        qWarning() << "Failed to create saves directory";
        return false;
    }

    QString filePath = getSlotFilePath(slotNumber);
    return saveGame(player, filePath);
}

Player* SaveManager::loadFromSlot(int slotNumber)
{
    if (slotNumber < 1 || slotNumber > MAX_SAVE_SLOTS) {
        qWarning() << "Invalid slot number:" << slotNumber;
        return nullptr;
    }

    QString filePath = getSlotFilePath(slotNumber);
    return loadGame(filePath);
}

bool SaveManager::deleteSaveSlot(int slotNumber)
{
    if (slotNumber < 1 || slotNumber > MAX_SAVE_SLOTS) {
        qWarning() << "Invalid slot number:" << slotNumber;
        return false;
    }

    QString filePath = getSlotFilePath(slotNumber);
    QFile file(filePath);

    if (!file.exists()) {
        return true; // Already deleted
    }

    return file.remove();
}
