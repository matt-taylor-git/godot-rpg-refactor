#include "MainWindow.h"
#include "views/MainMenu.h"
#include "views/NewGameView.h"
#include "views/CharacterCustomizationPage.h"

#include "views/CombatPage.h"
#include "views/InventoryPage.h"
#include "views/MonsterStatsPage.h"
#include "views/SaveLoadPage.h"
#include "views/ShopPage.h"
#include "views/StatsPage.h"
#include "views/QuestLogPage.h"
#include "views/DialogueView.h"
#include "views/StoryEventDialog.h"
#include "views/LoreBookPage.h"
#include "models/DialogueData.h"
#include "game/Game.h"
#include "components/SkillSelectionDialog.h"
#include "components/CombatItemDialog.h"
#include "components/CombatResultDialog.h"
#include "components/QuestCompletionDialog.h"
#include "components/MenuOverlay.h"
#include "components/ParticleSystem.h"
#include "models/Player.h"
#include "models/Monster.h"
#include "models/Skill.h"
#include "models/Item.h"
#include "components/AnimationManager.h"
#include "theme/Theme.h"
#include <QStackedWidget>
#include <QWidget>
#include <QMessageBox>
#include <QKeyEvent>
#include <QResizeEvent>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_combatState(Idle)
{
    setWindowTitle("Pyrpg-Qt");
    resize(800, 600);

    stackedWidget = new QStackedWidget(this);
    setCentralWidget(stackedWidget);

    // Main Menu
    m_mainMenu = new MainMenu();
    connect(m_mainMenu, &MainMenu::newGameRequested, this, &MainWindow::handleMainMenuNewGame);
    connect(m_mainMenu, &MainMenu::loadGameRequested, this, &MainWindow::handleMainMenuLoadGame);
    connect(m_mainMenu, &MainMenu::exitRequested, this, &MainWindow::handleMainMenuExit);
    stackedWidget->addWidget(m_mainMenu);

    // New Game View
    m_newGameView = new NewGameView();
    connect(m_newGameView, &NewGameView::characterCreated, this, &MainWindow::handleCharacterCreation);
    stackedWidget->addWidget(m_newGameView);

    // Character Customization Page
    m_characterCustomizationPage = new CharacterCustomizationPage();
    stackedWidget->addWidget(m_characterCustomizationPage);

    // Combat Page (now serves as main game hub)
    m_combatPage = new CombatPage();
    connect(m_combatPage, &CombatPage::exploreClicked, this, &MainWindow::handleExploreClicked);
    connect(m_combatPage, &CombatPage::restClicked, this, &MainWindow::handleRestClicked);
    connect(m_combatPage, &CombatPage::attackClicked, this, &MainWindow::handleAttackClicked);
    connect(m_combatPage, &CombatPage::skillClicked, this, &MainWindow::handleSkillClicked);
    connect(m_combatPage, &CombatPage::itemClicked, this, &MainWindow::handleItemClicked);
    connect(m_combatPage, &CombatPage::statsClicked, this, &MainWindow::handleStatsClicked);
    connect(m_combatPage, &CombatPage::runClicked, this, &MainWindow::handleRunClicked);
    connect(m_combatPage, &CombatPage::menuClicked, this, &MainWindow::handleMenuButtonClicked);
    stackedWidget->addWidget(m_combatPage);

    // Inventory Page
    m_inventoryPage = new InventoryPage();
    connect(m_inventoryPage, &InventoryPage::backRequested, this, &MainWindow::handleInventoryBack);
    stackedWidget->addWidget(m_inventoryPage);

    // Monster Stats Page
    m_monsterStatsPage = new MonsterStatsPage();
    connect(m_monsterStatsPage, &MonsterStatsPage::backRequested, this, &MainWindow::handleMonsterStatsBack);
    stackedWidget->addWidget(m_monsterStatsPage);

    // Save Load Page
    m_saveLoadPage = new SaveLoadPage();
    connect(m_saveLoadPage, &SaveLoadPage::quickSaveRequested, this, &MainWindow::handleQuickSave);
    connect(m_saveLoadPage, &SaveLoadPage::quickLoadRequested, this, &MainWindow::handleQuickLoad);
    connect(m_saveLoadPage, &SaveLoadPage::saveToSlotRequested, this, &MainWindow::handleSaveToSlot);
    connect(m_saveLoadPage, &SaveLoadPage::loadFromSlotRequested, this, &MainWindow::handleLoadFromSlot);
    connect(m_saveLoadPage, &SaveLoadPage::deleteSlotRequested, this, &MainWindow::handleDeleteSlot);
    connect(m_saveLoadPage, &SaveLoadPage::backRequested, this, &MainWindow::handleSaveLoadBack);
    stackedWidget->addWidget(m_saveLoadPage);

    // Shop Page
    m_shopPage = new ShopPage();
    connect(m_shopPage, &ShopPage::leaveRequested, this, &MainWindow::handleShopLeave);
    connect(m_shopPage, &ShopPage::itemPurchased, this, &MainWindow::onItemPurchased);
    connect(m_shopPage, &ShopPage::itemSold, this, &MainWindow::onItemSold);
    connect(m_shopPage, &ShopPage::loreUnlockedFromPurchase, this, &MainWindow::handleLoreUnlockedFromPurchase);
    stackedWidget->addWidget(m_shopPage);

    // Stats Page
    m_statsPage = new StatsPage();
    connect(m_statsPage, &StatsPage::backRequested, this, &MainWindow::handleStatsBack);
    stackedWidget->addWidget(m_statsPage);

    // Quest Log Page
    m_questLogPage = new QuestLogPage();
    connect(m_questLogPage, &QuestLogPage::backRequested, this, &MainWindow::handleQuestLogBack);
    connect(m_questLogPage, &QuestLogPage::questAccepted, this, &MainWindow::handleQuestAccepted);
    stackedWidget->addWidget(m_questLogPage);

    // Dialogue View (Phase 3)
    m_dialogueView = new DialogueView(this);
    connect(m_dialogueView, &DialogueView::choiceSelected,
            this, &MainWindow::handleDialogueChoiceSelected);
    connect(m_dialogueView, &DialogueView::dialogueClosed,
            this, &MainWindow::handleDialogueEnded);
    stackedWidget->addWidget(m_dialogueView);

    // Lore Book Page (Phase 3)
    m_loreBookPage = new LoreBookPage();
    connect(m_loreBookPage, &LoreBookPage::backRequested,
            this, &MainWindow::handleLoreBookBack);
    stackedWidget->addWidget(m_loreBookPage);

    // Set the initial view
    stackedWidget->setCurrentWidget(m_mainMenu);

    // Initialize victory screen (lazy creation)
    m_victoryScreen = nullptr;

    m_game = new Game(this);  // Parent to MainWindow to prevent memory leak
    connect(m_game, &Game::combatEnded, this, &MainWindow::handleCombatEnded);

    // Connect boss and victory signals
    connect(m_game, &Game::bossEncountered, this, &MainWindow::handleBossEncountered);
    connect(m_game, &Game::bossPhaseChanged, this, &MainWindow::handleBossPhaseChanged);
    connect(m_game, &Game::finalBossDefeated, this, &MainWindow::handleFinalBossDefeated);
    connect(m_game, &Game::gameCompleted, this, &MainWindow::handleGameCompleted);

    // Menu Overlay (floating overlay, not in stacked widget)
    m_menuOverlay = new MenuOverlay(this);
    m_menuOverlay->setGeometry(0, 0, width(), height());
    connect(m_menuOverlay, &MenuOverlay::saveRequested, this, &MainWindow::handleQuickSave);
    connect(m_menuOverlay, &MenuOverlay::loadRequested, this, &MainWindow::handleQuickLoad);
    connect(m_menuOverlay, &MenuOverlay::saveToSlotRequested, this, &MainWindow::handleSaveToSlot);
    connect(m_menuOverlay, &MenuOverlay::loadFromSlotRequested, this, &MainWindow::handleLoadFromSlot);
    connect(m_menuOverlay, &MenuOverlay::deleteSlotRequested, this, &MainWindow::handleDeleteSlot);
    connect(m_menuOverlay, &MenuOverlay::quitRequested, this, &MainWindow::handleQuitClicked);
    m_menuOverlay->hide();

    m_animationManager = new AnimationManager(m_combatPage, this);
    connect(m_animationManager, &AnimationManager::animationFinished, this, &MainWindow::onAnimationFinished);
}

void MainWindow::handleCharacterCreation(const QString &name, const QString &characterClass)
{
    // Create new game and initialize all managers
    m_game->newGame(name, characterClass);

    // Connect QuestManager signals
    if (m_game->getQuestManager()) {
        connect(m_game->getQuestManager(), &QuestManager::questCompleted,
                this, &MainWindow::handleQuestCompleted, Qt::UniqueConnection);
    }

    // Connect narrative manager signals (Phase 3)
    if (m_game->getDialogueManager()) {
        connect(m_game->getDialogueManager(), &DialogueManager::dialogueNodeChanged,
                this, &MainWindow::handleDialogueNodeChanged, Qt::UniqueConnection);
        connect(m_game->getDialogueManager(), &DialogueManager::dialogueEnded,
                this, &MainWindow::handleDialogueEnded, Qt::UniqueConnection);
        connect(m_game->getDialogueManager(), &DialogueManager::effectTriggered,
                this, &MainWindow::handleDialogueEffectTriggered, Qt::UniqueConnection);
    }
    if (m_game->getStoryManager()) {
        connect(m_game->getStoryManager(), &StoryManager::eventTriggered,
                this, &MainWindow::handleStoryEventTriggered, Qt::UniqueConnection);
    }
    if (m_game->getCodexManager()) {
        connect(m_game->getCodexManager(), &CodexManager::loreUnlocked,
                this, &MainWindow::handleLoreUnlocked, Qt::UniqueConnection);
    }

    // NOW load quests after all UI connections are established
    // This ensures story event dialogs display properly when first quest is auto-accepted
    if (m_game->getQuestManager()) {
        m_game->getQuestManager()->loadQuests();
    }

    // Start in non-combat mode on the main game hub (CombatPage)
    m_combatPage->setCombatMode(false);
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleExploreClicked()
{
    m_game->startCombat();
    m_combatPage->setCombatMode(true);
    m_combatPage->setCombatActive(true);
    m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), "");
    // Already on CombatPage, just ensure it's visible
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleRestClicked()
{
    // Rest to restore health/mana
    Player *player = m_game->getPlayer();
    if (player) {
        player->health = player->maxHealth;
        player->mana = player->maxMana;
        QMessageBox::information(this, "Rest", "You rest and restore your health and mana!");
    }
}

void MainWindow::handleQuitClicked()
{
    // Add confirmation dialog to prevent accidental exits
    QMessageBox::StandardButton reply = QMessageBox::question(
        this,
        "Quit Game",
        "Are you sure you want to quit? Any unsaved progress will be lost.",
        QMessageBox::Yes | QMessageBox::No
    );

    if (reply == QMessageBox::Yes) {
        close();
    }
}

void MainWindow::handleAttackClicked()
{
    m_combatState = PlayerAttacking;
    m_combatPage->setCombatActive(false);
    m_animationManager->playPlayerAttackAnimation();
}

void MainWindow::handleSkillClicked()
{
    // Open skill selection dialog
    SkillSelectionDialog dialog(m_game->getPlayer(), this);
    if (dialog.exec() == QDialog::Accepted) {
        Skill *selectedSkill = dialog.getSelectedSkill();
        if (selectedSkill) {
            int oldLevel = m_game->getPlayer()->level;
            QString log = m_game->playerUseSkill(selectedSkill);
            m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), log);

            if (m_game->isCombatOver()) {
                handleCombatEnd(oldLevel);
            } else {
                // Monster turn
                QString monsterLog = m_game->monsterAttack();
                m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), monsterLog);

                if (m_game->isCombatOver()) {
                    handleCombatEnd(oldLevel);
                }
            }
        }
    }
}

void MainWindow::handleItemClicked()
{
    // Open combat item dialog
    CombatItemDialog dialog(m_game->getPlayer(), this);
    if (dialog.exec() == QDialog::Accepted) {
        Item *selectedItem = dialog.getSelectedItem();
        if (selectedItem) {
            QString log = m_game->playerUseItem(selectedItem);
            m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), log);

            // Trigger particle effects based on item type
            if (m_combatPage && m_combatPage->getParticleSystem()) {
                QLabel* heroSprite = m_combatPage->getHeroSpriteLabel();
                if (heroSprite) {
                    QPoint heroPos = heroSprite->geometry().center();

                    if (selectedItem->effect == "heal") {
                        // Healing particle burst
                        m_combatPage->getParticleSystem()->healingBurst(heroPos);
                    } else if (selectedItem->effect == "restore_mana") {
                        // Mana restoration particle burst (blue)
                        m_combatPage->getParticleSystem()->createBurst(heroPos, 10, "spark", "#3498db", false);
                    }
                }
            }

            // Item use doesn't end player's turn, no monster attack
        }
    }
}

void MainWindow::handleStatsClicked()
{
    // Show player stats, not monster stats
    m_statsPage->updateStats(m_game->getPlayer());
    stackedWidget->setCurrentWidget(m_statsPage);
}

void MainWindow::handleOpenInventory()
{
    if (m_game && m_game->getPlayer()) {
        m_inventoryPage->updateInventory(m_game->getPlayer());
        stackedWidget->setCurrentWidget(m_inventoryPage);
        m_inventoryPage->setFocus();
    }
}

void MainWindow::handleOpenShop()
{
    if (m_game && m_game->getPlayer()) {
        m_shopPage->updateShop(m_game->getPlayer());
        stackedWidget->setCurrentWidget(m_shopPage);
        m_shopPage->setFocus();
    }
}

void MainWindow::handleOpenSaveLoad()
{
    m_saveLoadPage->refreshSaveSlots();
    stackedWidget->setCurrentWidget(m_saveLoadPage);
    m_saveLoadPage->setFocus();
}

void MainWindow::handleCombatEnd(int oldLevel)
{
    // Legacy method - combat is already ended by the signal handler
    // This method is kept for backward compatibility but should be removed
    m_combatPage->setCombatMode(false);
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleCombatEnded(bool playerWon)
{
    // Defensive null check for combat page
    if (!m_combatPage) {
        return;
    }

    // Disable combat buttons since combat has ended
    m_combatPage->setCombatActive(false);

    // Trigger particle effects for victory or defeat
    if (m_combatPage->getParticleSystem()) {
        QPoint centerPos = m_combatPage->rect().center();
        if (playerWon) {
            // Victory explosion effect
            m_combatPage->getParticleSystem()->victoryExplosion(centerPos);
        } else {
            // Defeat effect (red particles)
            m_combatPage->getParticleSystem()->createBurst(centerPos, 12, "spark", "#8b0000", false);
        }
    }

    // For now, don't check leveling - rewards are already given
    bool leveledUp = false;

    // Show combat result dialog
    if (playerWon) {
        Monster *monster = m_game->getCurrentMonster();
        CombatResultDialog resultDialog(
            true,
            monster ? monster->expReward : 0,
            monster ? monster->goldReward : 0,
            "",  // Loot message will be in combat log
            leveledUp,
            this
        );
        resultDialog.exec();
    } else {
        // Defeat
        CombatResultDialog resultDialog(false, 0, 0, "", false, this);
        resultDialog.exec();
    }

    // Return to non-combat mode on the main game hub
    m_combatPage->setCombatMode(false);
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleRunClicked()
{
    m_combatPage->setCombatMode(false);
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleQuickSave()
{
    // For quick save, use a default file path, e.g., quicksave.dat
    QString filePath = "quicksave.dat";
    if (m_game->saveGame(filePath)) {
        // Optionally show success message
    }
}

void MainWindow::handleQuickLoad()
{
    QString filePath = "quicksave.dat";
    if (m_game->loadGame(filePath)) {
        m_combatPage->setCombatMode(false);
        stackedWidget->setCurrentWidget(m_combatPage);
    }
}

void MainWindow::handleSaveToFile(const QString &filePath)
{
    if (m_game->saveGame(filePath)) {
        // Optionally show success message
    }
}

void MainWindow::handleLoadFromFile(const QString &filePath)
{
    if (m_game->loadGame(filePath)) {
        // Connect QuestManager signals after loading
        if (m_game->getQuestManager()) {
            connect(m_game->getQuestManager(), &QuestManager::questCompleted,
                    this, &MainWindow::handleQuestCompleted, Qt::UniqueConnection);
        }

        // Connect narrative manager signals (Phase 3)
        if (m_game->getDialogueManager()) {
            connect(m_game->getDialogueManager(), &DialogueManager::dialogueNodeChanged,
                    this, &MainWindow::handleDialogueNodeChanged, Qt::UniqueConnection);
            connect(m_game->getDialogueManager(), &DialogueManager::dialogueEnded,
                    this, &MainWindow::handleDialogueEnded, Qt::UniqueConnection);
            connect(m_game->getDialogueManager(), &DialogueManager::effectTriggered,
                    this, &MainWindow::handleDialogueEffectTriggered, Qt::UniqueConnection);
        }
        if (m_game->getStoryManager()) {
            connect(m_game->getStoryManager(), &StoryManager::eventTriggered,
                    this, &MainWindow::handleStoryEventTriggered, Qt::UniqueConnection);
        }
        if (m_game->getCodexManager()) {
            connect(m_game->getCodexManager(), &CodexManager::loreUnlocked,
                    this, &MainWindow::handleLoreUnlocked, Qt::UniqueConnection);
        }

        // Load quests after all connections are established
        if (m_game->getQuestManager()) {
            m_game->getQuestManager()->loadQuests();
        }

        m_combatPage->setCombatMode(false);
        stackedWidget->setCurrentWidget(m_combatPage);
    }
}

void MainWindow::handleNewSave()
{
    stackedWidget->setCurrentWidget(m_newGameView);
}

void MainWindow::handleSaveToSlot(int slotNumber)
{
    if (m_game->saveToSlot(slotNumber)) {
        m_saveLoadPage->refreshSaveSlots();
        QMessageBox::information(this, "Success", "Game saved successfully!");
    } else {
        QMessageBox::warning(this, "Save Failed", "Failed to save game to slot " + QString::number(slotNumber));
    }
}

void MainWindow::handleLoadFromSlot(int slotNumber)
{
    if (m_game->loadFromSlot(slotNumber)) {
        // Connect QuestManager signals after loading
        if (m_game->getQuestManager()) {
            connect(m_game->getQuestManager(), &QuestManager::questCompleted,
                    this, &MainWindow::handleQuestCompleted, Qt::UniqueConnection);
        }

        // Connect narrative manager signals (Phase 3)
        if (m_game->getDialogueManager()) {
            connect(m_game->getDialogueManager(), &DialogueManager::dialogueNodeChanged,
                    this, &MainWindow::handleDialogueNodeChanged, Qt::UniqueConnection);
            connect(m_game->getDialogueManager(), &DialogueManager::dialogueEnded,
                    this, &MainWindow::handleDialogueEnded, Qt::UniqueConnection);
            connect(m_game->getDialogueManager(), &DialogueManager::effectTriggered,
                    this, &MainWindow::handleDialogueEffectTriggered, Qt::UniqueConnection);
        }
        if (m_game->getStoryManager()) {
            connect(m_game->getStoryManager(), &StoryManager::eventTriggered,
                    this, &MainWindow::handleStoryEventTriggered, Qt::UniqueConnection);
        }
        if (m_game->getCodexManager()) {
            connect(m_game->getCodexManager(), &CodexManager::loreUnlocked,
                    this, &MainWindow::handleLoreUnlocked, Qt::UniqueConnection);
        }

        // Load quests after all connections are established
        if (m_game->getQuestManager()) {
            m_game->getQuestManager()->loadQuests();
        }

        m_combatPage->setCombatMode(false);
        stackedWidget->setCurrentWidget(m_combatPage);
    } else {
        QMessageBox::warning(this, "Load Failed", "Failed to load game from slot " + QString::number(slotNumber));
    }
}

void MainWindow::handleDeleteSlot(int slotNumber)
{
    if (m_game->deleteSlot(slotNumber)) {
        m_saveLoadPage->refreshSaveSlots();
        QMessageBox::information(this, "Success", "Save slot deleted successfully!");
    } else {
        QMessageBox::warning(this, "Delete Failed", "Failed to delete save slot " + QString::number(slotNumber));
    }
}

void MainWindow::handleMainMenuNewGame()
{
    stackedWidget->setCurrentWidget(m_newGameView);
}

void MainWindow::handleMainMenuLoadGame()
{
    m_saveLoadPage->refreshSaveSlots();
    stackedWidget->setCurrentWidget(m_saveLoadPage);
}

void MainWindow::handleMainMenuExit()
{
    close();
}

void MainWindow::handleInventoryBack()
{
    // Back to combat page, preserving combat state
    bool inCombat = (m_game->getCurrentMonster() != nullptr && !m_game->isCombatOver());
    m_combatPage->setCombatMode(inCombat);
    if (inCombat) {
        m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), "");
    }
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleShopLeave()
{
    m_combatPage->setCombatMode(false);
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleStatsBack()
{
    // Back to combat page, preserving combat state
    bool inCombat = (m_game->getCurrentMonster() != nullptr && !m_game->isCombatOver());
    m_combatPage->setCombatMode(inCombat);
    if (inCombat) {
        m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), "");
    }
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleMonsterStatsBack()
{
    // Back to combat page, preserving combat state
    bool inCombat = (m_game->getCurrentMonster() != nullptr && !m_game->isCombatOver());
    m_combatPage->setCombatMode(inCombat);
    if (inCombat) {
        m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), "");
    }
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleSaveLoadBack()
{
    stackedWidget->setCurrentWidget(m_mainMenu);
}

void MainWindow::handleMenuButtonClicked()
{
    // Show menu overlay from CombatPage (only when player exists)
    // Add defensive checks to ensure we're in an appropriate state
    if (!m_game || !m_game->getPlayer() || !m_menuOverlay) {
        return;
    }

    // Verify we're on the correct widget (CombatPage) before showing menu
    QWidget *currentWidget = stackedWidget->currentWidget();
    if (!currentWidget || currentWidget != m_combatPage) {
        return;
    }

    m_menuOverlay->updateContent(m_game->getPlayer());
    m_menuOverlay->showOverlay();
}

void MainWindow::keyPressEvent(QKeyEvent *event)
{
    QWidget *currentWidget = stackedWidget->currentWidget();

    // Only handle ESC if we're on the adventure page or combat page (in-game)
    if (event->key() == Qt::Key_Escape && m_menuOverlay) {

        // Check if menu overlay is visible
        if (m_menuOverlay->isVisible()) {
            m_menuOverlay->hideOverlay();
            event->accept();
            return;
        }

        // Show menu if we're in-game (on combat page) and player exists
        if (currentWidget == m_combatPage && m_game && m_game->getPlayer()) {
            m_menuOverlay->updateContent(m_game->getPlayer());
            m_menuOverlay->showOverlay();
            event->accept();
            return;
        }
    }

    // Handle global shortcuts only when on combat page and not in combat
    if (currentWidget == m_combatPage && m_game && m_game->getPlayer() && !m_game->isInCombat()) {
        switch (event->key()) {
            case Qt::Key_I:
                handleOpenInventory();
                event->accept();
                return;
            case Qt::Key_S:
                handleOpenShop();
                event->accept();
                return;
            case Qt::Key_O:
                handleOpenSaveLoad();
                event->accept();
                return;
            case Qt::Key_Q:
                handleOpenQuestLog();
                event->accept();
                return;
            case Qt::Key_L:
                handleOpenLoreBook();
                event->accept();
                return;
            case Qt::Key_D:
                // Test dialogue (replace with context-sensitive triggering later)
                handleOpenDialogue("elder_intro");
                event->accept();
                return;
        }
    }

    QMainWindow::keyPressEvent(event);
}

void MainWindow::resizeEvent(QResizeEvent *event)
{
    QMainWindow::resizeEvent(event);

    // Keep menu overlay sized to match the window
    if (m_menuOverlay) {
        m_menuOverlay->setGeometry(0, 0, width(), height());
    }
}

void MainWindow::onAnimationFinished()
{
    Player* player = m_game->getPlayer();
    if (!player) return;  // Guard clause to prevent null pointer dereference

    int oldLevel = player->level;

    switch (m_combatState) {
        case PlayerAttacking: {
            QString log = m_game->playerAttack();
            m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), log);

            if (m_game->isCombatOver()) {
                m_combatState = CombatEnded;
                handleCombatEnd(oldLevel);
            } else {
                m_combatState = PlayerDamage;
                m_animationManager->playDamageAnimation(m_combatPage->getEnemySpriteLabel());
            }
            break;
        }
        case PlayerDamage: {
            // Now it's the monster's turn
            m_combatState = MonsterTurn;
            QString monsterLog = m_game->monsterAttack();
            m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), monsterLog);

            if (m_game->isCombatOver()) {
                m_combatState = CombatEnded;
                handleCombatEnd(oldLevel);
            } else {
                m_combatState = Idle;
                m_combatPage->setCombatActive(true);
            }
            break;
        }
        default:
            break;
    }
}

void MainWindow::handleOpenQuestLog()
{
    if (m_game->getPlayer() && m_game->getQuestManager()) {
        m_questLogPage->updateQuests(m_game->getQuestManager(), m_game->getPlayer());
        stackedWidget->setCurrentWidget(m_questLogPage);
    }
}

void MainWindow::handleQuestLogBack()
{
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleQuestAccepted(const QString &questId)
{
    if (m_game->getQuestManager()) {
        m_game->getQuestManager()->acceptQuest(questId);
        // Refresh the quest log to show updated status
        m_questLogPage->updateQuests(m_game->getQuestManager(), m_game->getPlayer());
    }
}

void MainWindow::handleQuestCompleted(const QString &questId, int expReward, int goldReward)
{
    // Get quest details
    Quest* quest = nullptr;
    if (m_game->getQuestManager()) {
        quest = m_game->getQuestManager()->getQuestById(questId);
    }

    if (quest) {
        // Show completion dialog
        QuestCompletionDialog dialog(quest->title, expReward, goldReward, quest->rewards.itemNames, this);
        dialog.exec();

        // Update the combat page display to reflect new stats
        if (m_game->getPlayer()) {
            m_combatPage->updateCombatState(m_game->getPlayer(), m_game->getCurrentMonster(), "");
        }
    }
}

// Phase 3: Narrative system handlers

void MainWindow::handleDialogueNodeChanged(const QString &nodeId, const QString &speaker, const QString &text)
{
    DialogueNode* node = m_game->getDialogueManager()->getCurrentNode();
    if (!node) return;

    // Build choice texts
    QStringList choiceTexts;
    for (const DialogueChoice &choice : node->choices) {
        choiceTexts.append(choice.text);
    }

    // Display dialogue
    m_dialogueView->displayNode(speaker, text, choiceTexts);

    // Check requirements and disable invalid choices
    for (int i = 0; i < node->choices.size(); ++i) {
        const DialogueChoice &choice = node->choices[i];
        bool enabled = true;

        if (choice.requiresLevel && m_game->getPlayer()->level < choice.requiredLevel) {
            enabled = false;
        }

        m_dialogueView->setChoiceEnabled(i, enabled);
    }

    // Switch to dialogue view
    stackedWidget->setCurrentWidget(m_dialogueView);
}

void MainWindow::handleDialogueChoiceSelected(int choiceIndex)
{
    m_game->getDialogueManager()->selectChoice(choiceIndex);
}

void MainWindow::handleDialogueEnded()
{
    // Return to combat page (main hub)
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleDialogueEffectTriggered(const QString &effectType, const QString &target, int value)
{
    // Log dialogue effects to combat log
    if (effectType == "GiveGold") {
        m_combatPage->addLogEntry(QString("Received %1 gold!").arg(value), "success");
    } else if (effectType == "GiveXP") {
        m_combatPage->addLogEntry(QString("Gained %1 experience!").arg(value), "success");
    } else if (effectType == "GiveItem") {
        m_combatPage->addLogEntry(QString("Received item: %1!").arg(target), "success");
    } else if (effectType == "UnlockQuest") {
        m_combatPage->addLogEntry(QString("New quest available!"), "quest");
    }
}

void MainWindow::handleStoryEventTriggered(const StoryEvent &event)
{
    qDebug() << "MainWindow::handleStoryEventTriggered() called with event:" << event.eventId;
    qDebug() << "Event title:" << event.title;
    // Show modal story event dialog
    StoryEventDialog dialog(event, this);
    qDebug() << "About to show dialog (this will block)...";
    dialog.exec();  // Blocks until player dismisses
    qDebug() << "Dialog closed";
}

void MainWindow::handleLoreUnlocked(const QString &entryId, const QString &title)
{
    // Show notification in combat log with PRIMARY color highlighting (Phase 5)
    QString message = QString("<span style='color:%1'>New Codex Entry:</span> %2")
        .arg(Theme::PRIMARY.name())
        .arg(title);
    m_combatPage->addLogEntry(message, "lore");
}

void MainWindow::handleLoreUnlockedFromPurchase(const QString &loreId)
{
    // Get lore entry and display notification (Phase 5)
    if (!m_game || !m_game->getCodexManager()) return;

    LoreEntry* entry = m_game->getCodexManager()->getEntry(loreId);
    if (entry) {
        handleLoreUnlocked(loreId, entry->title);
    }
}

void MainWindow::onItemPurchased(Item *item)
{
    // Update inventory if open
    if (stackedWidget->currentWidget() == m_inventoryPage) {
        m_inventoryPage->updateInventory(m_game->getPlayer());
    }
}

void MainWindow::onItemSold(Item *item, int goldReceived)
{
    // Update inventory if open
    if (stackedWidget->currentWidget() == m_inventoryPage) {
        m_inventoryPage->updateInventory(m_game->getPlayer());
    }
}

void MainWindow::handleOpenLoreBook()
{
    if (!m_game || !m_game->getCodexManager()) return;

    m_loreBookPage->updateLore(m_game->getCodexManager());
    stackedWidget->setCurrentWidget(m_loreBookPage);
}

void MainWindow::handleLoreBookBack()
{
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleOpenDialogue(const QString &dialogueId)
{
    if (!m_game || !m_game->getDialogueManager()) return;

    m_game->getDialogueManager()->startDialogue(dialogueId);
}

// Final Boss and Victory Handlers (Phase 4)
void MainWindow::handleFinalBossRequest()
{
    if (!m_game) return;

    // Check if player can access final boss
    if (!m_game->canAccessFinalBoss()) {
        // Show error dialog
        return;
    }

    // Show Point of No Return dialog
    PointOfNoReturnDialog dialog(this);
    if (dialog.exec() == QDialog::Accepted) {
        // Player accepted - start final boss combat
        m_game->startFinalBossCombat();
        stackedWidget->setCurrentWidget(m_combatPage);
    }
}

void MainWindow::handleBossEncountered(const QString &bossName)
{
    // Disable run button in CombatPage
    // Show dramatic message in combat log
    qDebug() << "Boss encountered:" << bossName;
}

void MainWindow::handleBossPhaseChanged(int newPhase)
{
    // Show phase transition message in CombatPage
    // Update UI with phase indicator
    qDebug() << "Boss phase changed to:" << newPhase;
}

void MainWindow::handleFinalBossDefeated()
{
    // Trigger victory cutscene
    // VictoryScreen will be shown in handleGameCompleted
    qDebug() << "Final boss defeated!";
}

void MainWindow::handleGameCompleted(int finalLevel, int playtime)
{
    if (!m_game || !m_game->getPlayer()) return;

    // Collect statistics
    Player* player = m_game->getPlayer();
    int kills = 0;  // Would need to track this
    int deaths = 0; // Would need to track this
    int gold = player->gold;
    int quests = player->getCompletedQuests().size();

    // Create and show victory screen
    if (!m_victoryScreen) {
        m_victoryScreen = new VictoryScreen(finalLevel, playtime, kills, deaths, gold, quests, this);
        connect(m_victoryScreen, &VictoryScreen::continuePlaying, this, &MainWindow::handleVictoryContinue);
        connect(m_victoryScreen, &VictoryScreen::returnToMainMenu, this, &MainWindow::handleVictoryMainMenu);
    }

    m_victoryScreen->exec();
}

void MainWindow::handleVictoryContinue()
{
    // Return to game world - player can continue exploring
    stackedWidget->setCurrentWidget(m_combatPage);
}

void MainWindow::handleVictoryMainMenu()
{
    // Return to main menu
    stackedWidget->setCurrentWidget(m_mainMenu);
}

MainWindow::~MainWindow()
{
}
