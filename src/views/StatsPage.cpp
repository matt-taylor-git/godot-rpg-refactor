#include "StatsPage.h"
#include "../models/Player.h"
#include "../theme/Theme.h"
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QProgressBar>
#include <QPushButton>
#include <QFrame>

StatsPage::StatsPage(QWidget *parent)
    : QWidget(parent), m_currentPlayer(nullptr)
{
    setupUi();
}

void StatsPage::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    QHBoxLayout *contentLayout = new QHBoxLayout();
    contentLayout->setSpacing(Theme::SPACING_LG);

    QWidget *charInfoCard = createCharacterInfoCard();
    contentLayout->addWidget(charInfoCard, 1);

    QWidget *statsAllocCard = createStatsAllocationCard();
    contentLayout->addWidget(statsAllocCard, 1);

    mainLayout->addLayout(contentLayout);
}

QWidget* StatsPage::createCharacterInfoCard()
{
    QFrame *card = new QFrame();
    QVBoxLayout *layout = new QVBoxLayout(card);

    QHBoxLayout *headerLayout = new QHBoxLayout();
    QLabel *title = new QLabel("Character Info");
    title->setStyleSheet("font-size: 18px; font-weight: bold;");
    m_levelBadge = new QLabel("Level 1");
    headerLayout->addWidget(title);
    headerLayout->addStretch();
    headerLayout->addWidget(m_levelBadge);
    layout->addLayout(headerLayout);

    m_charNameLabel = new QLabel("Hero");
    m_charNameLabel->setAlignment(Qt::AlignCenter);
    m_charNameLabel->setStyleSheet("font-size: 24px; font-weight: bold;");
    layout->addWidget(m_charNameLabel);

    m_expBar = new QProgressBar();
    m_healthBar = new QProgressBar();
    m_manaBar = new QProgressBar();
    layout->addWidget(new QLabel("Experience"));
    layout->addWidget(m_expBar);
    layout->addWidget(new QLabel("Health"));
    layout->addWidget(m_healthBar);
    layout->addWidget(new QLabel("Mana"));
    layout->addWidget(m_manaBar);

    m_goldLabel = new QLabel("Gold: 0");
    layout->addWidget(m_goldLabel);

    return card;
}

QWidget* StatsPage::createStatsAllocationCard()
{
    QFrame *card = new QFrame();
    QVBoxLayout *layout = new QVBoxLayout(card);

    QHBoxLayout *headerLayout = new QHBoxLayout();
    QLabel *title = new QLabel("Character Stats");
    title->setStyleSheet("font-size: 18px; font-weight: bold;");
    m_pointsBadge = new QLabel("0 Points Available");
    headerLayout->addWidget(title);
    headerLayout->addStretch();
    headerLayout->addWidget(m_pointsBadge);
    layout->addLayout(headerLayout);

    layout->addWidget(createStatRow("Strength", "Increases physical damage", m_strengthValue, m_strengthPlusButton));
    layout->addWidget(createStatRow("Defense", "Reduces damage taken", m_defenseValue, m_defensePlusButton));
    layout->addWidget(createStatRow("Magic", "Enhances spell power", m_magicValue, m_magicPlusButton));
    layout->addWidget(createStatRow("Speed", "Determines turn order", m_speedValue, m_speedPlusButton));

    // Connect stat upgrade buttons
    connect(m_strengthPlusButton, &QPushButton::clicked, this, &StatsPage::handleStrengthUpgrade);
    connect(m_defensePlusButton, &QPushButton::clicked, this, &StatsPage::handleDefenseUpgrade);
    connect(m_magicPlusButton, &QPushButton::clicked, this, &StatsPage::handleMagicUpgrade);
    connect(m_speedPlusButton, &QPushButton::clicked, this, &StatsPage::handleSpeedUpgrade);

    return card;
}

QWidget* StatsPage::createStatRow(const QString &name, const QString &description, QLabel* &valueLabel, QPushButton* &plusButton)
{
    QWidget *rowWidget = new QWidget();
    QGridLayout *rowLayout = new QGridLayout(rowWidget);

    QLabel *nameLabel = new QLabel(name);
    nameLabel->setStyleSheet("font-weight: bold;");
    QLabel *descLabel = new QLabel(description);

    valueLabel = new QLabel("0");
    valueLabel->setStyleSheet("font-size: 20px; font-weight: bold;");

    plusButton = new QPushButton("+");

    rowLayout->addWidget(nameLabel, 0, 0);
    rowLayout->addWidget(valueLabel, 0, 1, 2, 1, Qt::AlignRight);
    rowLayout->addWidget(plusButton, 0, 2, 2, 1, Qt::AlignRight);
    rowLayout->addWidget(descLabel, 1, 0);

    return rowWidget;
}

void StatsPage::updateStats(Player *player)
{
    if (!player) return;

    m_currentPlayer = player;

    m_levelBadge->setText(QString("Level %1").arg(player->level));
    m_charNameLabel->setText(player->name);

    int expPercent = (player->experienceToLevel > 0) ? (static_cast<int>((static_cast<double>(player->experience) / player->experienceToLevel) * 100)) : 0;
    m_expBar->setValue(expPercent);
    m_expBar->setFormat(QString("%1 / %2 XP").arg(player->experience).arg(player->experienceToLevel));

    int healthPercent = (player->maxHealth > 0) ? (static_cast<int>((static_cast<double>(player->health) / player->maxHealth) * 100)) : 0;
    m_healthBar->setValue(healthPercent);
    m_healthBar->setFormat(QString("%1 / %2 HP").arg(player->health).arg(player->maxHealth));

    int manaPercent = (player->maxMana > 0) ? (static_cast<int>((static_cast<double>(player->mana) / player->maxMana) * 100)) : 0;
    m_manaBar->setValue(manaPercent);
    m_manaBar->setFormat(QString("%1 / %2 MP").arg(player->mana).arg(player->maxMana));

    m_goldLabel->setText(QString("Gold: %1").arg(player->gold));

    m_pointsBadge->setText(QString("%1 Points Available").arg(player->statPoints));

    m_strengthValue->setText(QString::number(player->strength));
    m_defenseValue->setText(QString::number(player->vitality)); // Defense is vitality
    m_magicValue->setText(QString::number(player->intelligence));
    m_speedValue->setText(QString::number(player->dexterity));

    bool canUpgrade = player->statPoints > 0;
    m_strengthPlusButton->setEnabled(canUpgrade);
    m_defensePlusButton->setEnabled(canUpgrade);
    m_magicPlusButton->setEnabled(canUpgrade);
    m_speedPlusButton->setEnabled(canUpgrade);
}

void StatsPage::handleStrengthUpgrade()
{
    if (!m_currentPlayer || m_currentPlayer->statPoints <= 0) return;

    m_currentPlayer->strength += 1;
    m_currentPlayer->statPoints -= 1;
    updateStats(m_currentPlayer);
}

void StatsPage::handleDefenseUpgrade()
{
    if (!m_currentPlayer || m_currentPlayer->statPoints <= 0) return;

    m_currentPlayer->vitality += 1;
    m_currentPlayer->statPoints -= 1;

    // Recalculate max health based on vitality
    m_currentPlayer->maxHealth = 50 + (m_currentPlayer->vitality * 10);

    updateStats(m_currentPlayer);
}

void StatsPage::handleMagicUpgrade()
{
    if (!m_currentPlayer || m_currentPlayer->statPoints <= 0) return;

    m_currentPlayer->intelligence += 1;
    m_currentPlayer->statPoints -= 1;

    // Recalculate max mana based on intelligence
    m_currentPlayer->maxMana = 30 + (m_currentPlayer->intelligence * 10);

    updateStats(m_currentPlayer);
}

void StatsPage::handleSpeedUpgrade()
{
    if (!m_currentPlayer || m_currentPlayer->statPoints <= 0) return;

    m_currentPlayer->dexterity += 1;
    m_currentPlayer->statPoints -= 1;
    updateStats(m_currentPlayer);
}
