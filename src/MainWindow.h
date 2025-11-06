#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "models/StoryEvent.h"
#include "views/VictoryScreen.h"
#include "components/PointOfNoReturnDialog.h"

class QStackedWidget;
class Item;
class MainMenu;
class NewGameView;
class CharacterCustomizationPage;

class CombatPage;
class InventoryPage;
class MonsterStatsPage;
class SaveLoadPage;
class ShopPage;
class StatsPage;
class QuestLogPage;
class DialogueView;
class StoryEventDialog;
class LoreBookPage;
class Game;
class MenuOverlay;
class AnimationManager;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void handleCharacterCreation(const QString &name, const QString &characterClass);
    void handleExploreClicked();
    void handleRestClicked();
    void handleQuitClicked();
    void handleAttackClicked();
    void handleSkillClicked();
    void handleItemClicked();
    void handleStatsClicked();
    void handleRunClicked();
    void handleOpenInventory();
    void handleOpenShop();
    void handleOpenSaveLoad();
    void handleQuickSave();
    void handleQuickLoad();
    void handleSaveToFile(const QString &filePath);
    void handleLoadFromFile(const QString &filePath);
    void handleNewSave();
    void handleSaveToSlot(int slotNumber);
    void handleLoadFromSlot(int slotNumber);
    void handleDeleteSlot(int slotNumber);
    void handleMainMenuNewGame();
    void handleMainMenuLoadGame();
    void handleMainMenuExit();
    void handleInventoryBack();
    void handleShopLeave();
    void handleStatsBack();
    void handleMonsterStatsBack();
    void handleSaveLoadBack();
    void onItemPurchased(Item *item);
    void onItemSold(Item *item, int goldReceived);
    void handleOpenQuestLog();
    void handleQuestLogBack();
    void handleQuestAccepted(const QString &questId);
    void handleQuestCompleted(const QString &questId, int expReward, int goldReward);
    void handleCombatEnd(int oldLevel);
    void handleCombatEnded(bool playerWon);
    void handleMenuButtonClicked();
    void onAnimationFinished();

    // Narrative system handlers (Phase 3)
    void handleDialogueNodeChanged(const QString &nodeId, const QString &speaker, const QString &text);
    void handleDialogueChoiceSelected(int choiceIndex);
    void handleDialogueEnded();
    void handleDialogueEffectTriggered(const QString &effectType, const QString &target, int value);
    void handleStoryEventTriggered(const StoryEvent &event);
    void handleLoreUnlocked(const QString &entryId, const QString &title);
    void handleLoreUnlockedFromPurchase(const QString &loreId);
    void handleOpenLoreBook();
    void handleLoreBookBack();
    void handleOpenDialogue(const QString &dialogueId);

    // Final boss and victory handlers (Phase 4)
    void handleFinalBossRequest();
    void handleBossEncountered(const QString &bossName);
    void handleBossPhaseChanged(int newPhase);
    void handleFinalBossDefeated();
    void handleGameCompleted(int finalLevel, int playtime);
    void handleVictoryContinue();
    void handleVictoryMainMenu();

protected:
    void keyPressEvent(QKeyEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    enum CombatState { Idle, PlayerAttacking, PlayerDamage, MonsterTurn, CombatEnded };

    QStackedWidget *stackedWidget;
    MainMenu *m_mainMenu;
    NewGameView *m_newGameView;
    CharacterCustomizationPage *m_characterCustomizationPage;
    CombatPage *m_combatPage;
    InventoryPage *m_inventoryPage;
    MonsterStatsPage *m_monsterStatsPage;
    SaveLoadPage *m_saveLoadPage;
    ShopPage *m_shopPage;
    StatsPage *m_statsPage;
    QuestLogPage *m_questLogPage;
    DialogueView *m_dialogueView;
    LoreBookPage *m_loreBookPage;
    VictoryScreen *m_victoryScreen;
    Game *m_game;
    MenuOverlay *m_menuOverlay;
    AnimationManager *m_animationManager;
    CombatState m_combatState;
};

#endif // MAINWINDOW_H
