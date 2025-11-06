#include "CombatPage.h"
#include "../theme/Theme.h"
#include "../models/Player.h"
#include "../models/Monster.h"
#include "../components/ParticleSystem.h"
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QProgressBar>
#include <QPushButton>
#include <QTextEdit>
#include <QFrame>
#include <QFont>

CombatPage::CombatPage(QWidget *parent) : QWidget(parent), m_inCombat(false)
{
    setupUi();

    // Initialize particle system after UI is set up
    m_particleSystem = new ParticleSystem(this);
    m_particleSystem->setGeometry(rect());
    m_particleSystem->raise(); // Ensure particles appear on top
}

void CombatPage::setupUi()
{
    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    QWidget *arenaCard = createArenaCard();
    mainLayout->addWidget(arenaCard, 2);

    QWidget *logCard = createLogCard();
    mainLayout->addWidget(logCard, 1);

    // Start in non-combat mode
    setCombatMode(false);
}

QWidget* CombatPage::createArenaCard()
{
    QFrame *card = new QFrame();
    card->setStyleSheet(QString("background-color: %1; border-radius: %2px;").arg(Theme::CARD.name()).arg(Theme::BORDER_RADIUS_MD));
    m_cardLayout = new QVBoxLayout(card);

    QLabel *title = new QLabel("⚔️ Battle Arena");
    QFont titleFont;
    titleFont.setPointSize(18);
    titleFont.setBold(true);
    title->setFont(titleFont);
    title->setStyleSheet(QString("color: %1; margin-bottom: %2px;").arg(Theme::PRIMARY.name()).arg(Theme::SPACING_SM));
    m_cardLayout->addWidget(title);

    QFrame *spritesContainer = new QFrame();
    spritesContainer->setFrameShape(QFrame::Box);
    spritesContainer->setStyleSheet(QString(
        "QFrame { border: 2px solid %1; border-radius: %2px; background-color: %3; padding: %4px; }"
    ).arg(Theme::BORDER.name()).arg(Theme::BORDER_RADIUS_MD).arg(Theme::CARD.name()).arg(Theme::SPACING_MD));
    QHBoxLayout *spritesLayout = new QHBoxLayout(spritesContainer);
    spritesLayout->setSpacing(Theme::SPACING_MD);

    m_heroSpriteLabel = new QLabel("🛡️ HERO");
    m_heroSpriteLabel->setAlignment(Qt::AlignCenter);
    m_heroSpriteLabel->setMinimumSize(100, 100);
    m_enemySpriteLabel = new QLabel("👹 ENEMY");
    m_enemySpriteLabel->setAlignment(Qt::AlignCenter);
    m_enemySpriteLabel->setMinimumSize(100, 100);

    spritesLayout->addWidget(m_heroSpriteLabel);
    spritesLayout->addWidget(new QLabel("⚔️"));
    spritesLayout->addWidget(m_enemySpriteLabel);
    m_cardLayout->addWidget(spritesContainer);

    // Monster name/level display
    m_monsterNameLabel = new QLabel("Unknown Monster");
    m_monsterNameLabel->setAlignment(Qt::AlignCenter);
    m_monsterNameLabel->setStyleSheet(QString("font-size: 16px; font-weight: bold; color: %1;").arg(Theme::FOREGROUND.name()));
    m_cardLayout->addWidget(m_monsterNameLabel);

    // Hero stats
    m_cardLayout->addWidget(new QLabel("❤️ Hero Health"));
    m_heroHealthBar = new QProgressBar();
    m_heroHealthBar->setRange(0, 100);
    m_heroHealthBar->setValue(100);
    m_heroHealthBar->setTextVisible(true);
    m_heroHealthBar->setFormat("100 / 100 HP");
    m_heroHealthBar->setStyleSheet("QProgressBar { border: 2px solid grey; border-radius: 5px; text-align: center; } QProgressBar::chunk { background-color: #dc3545; }");
    m_cardLayout->addWidget(m_heroHealthBar);

    m_cardLayout->addWidget(new QLabel("💙 Hero Mana"));
    m_heroManaBar = new QProgressBar();
    m_heroManaBar->setRange(0, 100);
    m_heroManaBar->setValue(100);
    m_heroManaBar->setTextVisible(true);
    m_heroManaBar->setFormat("100 / 100 MP");
    m_heroManaBar->setStyleSheet("QProgressBar { border: 2px solid grey; border-radius: 5px; text-align: center; } QProgressBar::chunk { background-color: #3b82f6; }");
    m_cardLayout->addWidget(m_heroManaBar);

    // Enemy stats
    m_cardLayout->addWidget(new QLabel("💀 Enemy Health"));
    m_enemyHealthBar = new QProgressBar();
    m_enemyHealthBar->setRange(0, 100);
    m_enemyHealthBar->setValue(100);
    m_enemyHealthBar->setTextVisible(true);
    m_enemyHealthBar->setFormat("100 / 100 HP");
    m_enemyHealthBar->setStyleSheet("QProgressBar { border: 2px solid grey; border-radius: 5px; text-align: center; } QProgressBar::chunk { background-color: #ef4444; }");
    m_cardLayout->addWidget(m_enemyHealthBar);

    // Actions layout will be added in setCombatMode
    m_actionsLayout = nullptr;

    return card;
}

void CombatPage::updateCombatState(Player *player, Monster *monster, const QString &log)
{
    if (player) {
        m_heroHealthBar->setMaximum(player->maxHealth);
        m_heroHealthBar->setValue(player->health);
        m_heroHealthBar->setFormat(QString("%1 / %2 HP").arg(player->health).arg(player->maxHealth));

        m_heroManaBar->setMaximum(player->maxMana);
        m_heroManaBar->setValue(player->mana);
        m_heroManaBar->setFormat(QString("%1 / %2 MP").arg(player->mana).arg(player->maxMana));

        // Try to load character sprite
        QString spritePath = QString(":/assets/%1.png").arg(player->characterClass.toLower());
        QPixmap sprite(spritePath);
        if (!sprite.isNull()) {
            m_heroSpriteLabel->setPixmap(sprite.scaled(100, 100, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        }
    }
    if (monster) {
        m_enemyHealthBar->setMaximum(monster->maxHealth);
        m_enemyHealthBar->setValue(monster->health);
        m_enemyHealthBar->setFormat(QString("%1 / %2 HP").arg(monster->health).arg(monster->maxHealth));

        // Update monster name and level
        m_monsterNameLabel->setText(QString("%1 (Level %2)").arg(monster->name).arg(monster->level));

        // Try to load monster sprite based on enemyType
        QString spritePath = QString(":/assets/%1.png").arg(monster->enemyType);
        QPixmap sprite(spritePath);
        if (!sprite.isNull()) {
            m_enemySpriteLabel->setPixmap(sprite.scaled(100, 100, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        }
    }
    if (!log.isEmpty()) {
        m_battleLog->append(log);
    }
}

void CombatPage::setCombatActive(bool active)
{
    if (m_inCombat && m_actionsLayout) {
        // Find and enable/disable combat buttons in the current layout
        for (int i = 0; i < m_actionsLayout->count(); ++i) {
            QLayoutItem *item = m_actionsLayout->itemAt(i);
            if (item && item->widget()) {
                QPushButton *button = qobject_cast<QPushButton*>(item->widget());
                if (button) {
                    button->setEnabled(active);
                }
            }
        }
    }
}

QWidget* CombatPage::createLogCard()
{
    QFrame *card = new QFrame();
    card->setStyleSheet(QString("background-color: %1; border-radius: %2px;").arg(Theme::CARD.name()).arg(Theme::BORDER_RADIUS_MD));
    QVBoxLayout *layout = new QVBoxLayout(card);

    QLabel *title = new QLabel("📜 Battle Log");
    QFont titleFont;
    titleFont.setPointSize(18);
    titleFont.setBold(true);
    title->setFont(titleFont);
    title->setStyleSheet(QString("color: %1; margin-bottom: %2px;").arg(Theme::PRIMARY.name()).arg(Theme::SPACING_SM));
    layout->addWidget(title);

    m_battleLog = new QTextEdit();
    m_battleLog->setReadOnly(true);
    m_battleLog->setText("A wild enemy appears!\nPrepare for battle!");
    layout->addWidget(m_battleLog);

    return card;
}

QLayout* CombatPage::createCombatActionsLayout()
{
    QGridLayout *actionsLayout = new QGridLayout();
    actionsLayout->setSpacing(Theme::SPACING_SM);

    QPushButton *attackButton = new QPushButton("⚔️ Attack");
    connect(attackButton, &QPushButton::clicked, this, &CombatPage::attackClicked);
    QPushButton *skillButton = new QPushButton("✨ Use Skill");
    connect(skillButton, &QPushButton::clicked, this, &CombatPage::skillClicked);
    QPushButton *itemButton = new QPushButton("🧪 Use Item");
    connect(itemButton, &QPushButton::clicked, this, &CombatPage::itemClicked);
    QPushButton *statsButton = new QPushButton("📖 View Stats");
    connect(statsButton, &QPushButton::clicked, this, &CombatPage::statsClicked);
    QPushButton *runButton = new QPushButton("🏃 Run");
    connect(runButton, &QPushButton::clicked, this, &CombatPage::runClicked);

    actionsLayout->addWidget(attackButton, 0, 0);
    actionsLayout->addWidget(skillButton, 0, 1);
    actionsLayout->addWidget(itemButton, 1, 0);
    actionsLayout->addWidget(statsButton, 1, 1);
    actionsLayout->addWidget(runButton, 2, 0, 1, 2);

    return actionsLayout;
}

QLayout* CombatPage::createNonCombatActionsLayout()
{
    QVBoxLayout *actionsLayout = new QVBoxLayout();
    actionsLayout->setSpacing(Theme::SPACING_MD);

    QLabel *title = new QLabel("Choose your next action");
    QFont titleFont;
    titleFont.setPointSize(16);
    titleFont.setBold(true);
    title->setFont(titleFont);
    title->setStyleSheet(QString("color: %1; margin-bottom: %2px;").arg(Theme::PRIMARY.name()).arg(Theme::SPACING_SM));
    title->setAlignment(Qt::AlignCenter);
    actionsLayout->addWidget(title);

    QLabel *shortcutsHint = new QLabel("Keyboard shortcuts: I (Inventory), S (Shop), L (Save/Load)");
    shortcutsHint->setStyleSheet(QString("color: %1; font-size: 12px;").arg(Theme::MUTED_FOREGROUND.name()));
    shortcutsHint->setAlignment(Qt::AlignCenter);
    actionsLayout->addWidget(shortcutsHint);

    QPushButton *exploreButton = new QPushButton("🏞️ Explore");
    exploreButton->setMinimumHeight(60);
    exploreButton->setStyleSheet(QString(
        "QPushButton { background-color: %1; color: %2; border-radius: 8px; padding: 10px; font-size: 16px; font-weight: bold; }"
        "QPushButton:hover { background-color: %3; }"
    ).arg(Theme::PRIMARY.name()).arg(Theme::PRIMARY_FOREGROUND.name()).arg(Theme::PRIMARY.darker(110).name()));
    connect(exploreButton, &QPushButton::clicked, this, &CombatPage::exploreClicked);

    QPushButton *restButton = new QPushButton("😴 Rest");
    restButton->setMinimumHeight(60);
    restButton->setStyleSheet(QString(
        "QPushButton { background-color: %1; color: %2; border-radius: 8px; padding: 10px; font-size: 16px; font-weight: bold; }"
        "QPushButton:hover { background-color: %3; }"
    ).arg(Theme::SECONDARY.name()).arg(Theme::FOREGROUND.name()).arg(Theme::SECONDARY.darker(110).name()));
    connect(restButton, &QPushButton::clicked, this, &CombatPage::restClicked);

    QPushButton *menuButton = new QPushButton("📋 Menu");
    menuButton->setMinimumHeight(60);
    menuButton->setStyleSheet(QString(
        "QPushButton { background-color: %1; color: %2; border-radius: 8px; padding: 10px; font-size: 16px; font-weight: bold; }"
        "QPushButton:hover { background-color: %3; }"
    ).arg(Theme::ACCENT.name()).arg(Theme::ACCENT_FOREGROUND.name()).arg(Theme::ACCENT.darker(110).name()));
    connect(menuButton, &QPushButton::clicked, this, &CombatPage::menuClicked);

    actionsLayout->addWidget(exploreButton);
    actionsLayout->addWidget(restButton);
    actionsLayout->addWidget(menuButton);
    actionsLayout->addStretch();

    return actionsLayout;
}

void CombatPage::setCombatMode(bool inCombat)
{
    if (m_inCombat == inCombat && m_actionsLayout != nullptr) return;

    m_inCombat = inCombat;

    // Clear all items from the card layout (except the fixed ones)
    // We need to be careful to only remove the dynamic actions layout
    if (m_actionsLayout) {
        // Find and remove the actions layout from the card layout
        for (int i = m_cardLayout->count() - 1; i >= 0; --i) {
            QLayoutItem *item = m_cardLayout->itemAt(i);
            if (item && item->layout() == m_actionsLayout) {
                m_cardLayout->removeItem(item);
                // Don't delete the item yet, we need to clean up the layout first
                break;
            }
        }

        // Clear and delete the old layout
        QLayoutItem *childItem;
        while ((childItem = m_actionsLayout->takeAt(0)) != nullptr) {
            if (childItem->widget()) {
                delete childItem->widget();
            }
            delete childItem;
        }
        delete m_actionsLayout;
        m_actionsLayout = nullptr;
    }

    // Create new actions based on mode
    if (inCombat) {
        m_actionsLayout = createCombatActionsLayout();
        m_heroSpriteLabel->show();
        m_heroManaBar->show();
        m_enemySpriteLabel->show();
        m_monsterNameLabel->show();
        m_enemyHealthBar->show();
        m_battleLog->setText("A wild enemy appears!\nPrepare for battle!");
    } else {
        m_actionsLayout = createNonCombatActionsLayout();
        m_heroSpriteLabel->hide();
        m_heroManaBar->hide();
        m_enemySpriteLabel->hide();
        m_monsterNameLabel->hide();
        m_enemyHealthBar->hide();
        m_battleLog->setText("Welcome to the Realm of Legends!\nWhat would you like to do?");
    }

    // Add the new layout to the card
    m_cardLayout->addLayout(m_actionsLayout);

    // Force the widget to update its layout
    m_cardLayout->update();
    update();
}

    

QLabel* CombatPage::getHeroSpriteLabel()
{
    return m_heroSpriteLabel;
}

    

QLabel* CombatPage::getEnemySpriteLabel()
{
    return m_enemySpriteLabel;
}

ParticleSystem* CombatPage::getParticleSystem()
{
    return m_particleSystem;
}

void CombatPage::addLogEntry(const QString &message, const QString &type)
{
    // Simple implementation - just append to the battle log
    // The type parameter is optional and could be used for color-coding in the future
    if (m_battleLog) {
        m_battleLog->append(message);
    }
}

