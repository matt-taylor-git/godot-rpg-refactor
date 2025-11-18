#include "SkillSelectionDialog.h"
#include "../models/Player.h"
#include "../models/Skill.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QListWidget>
#include <QLabel>
#include <QPushButton>
#include <QFont>

SkillSelectionDialog::SkillSelectionDialog(Player *player, QWidget *parent)
    : QDialog(parent), m_player(player), m_selectedSkill(nullptr)
{
    setWindowTitle("Select Skill");
    setMinimumWidth(400);
    setMinimumHeight(500);
    setupUi();
    populateSkills();
}

void SkillSelectionDialog::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);

    QLabel *title = new QLabel("Choose a Skill to Use");
    QFont titleFont;
    titleFont.setPointSize(16);
    titleFont.setBold(true);
    title->setFont(titleFont);
    mainLayout->addWidget(title);

    m_skillList = new QListWidget();
    m_skillList->setStyleSheet(QString(
        "QListWidget {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: 8px;"
        "    padding: 8px;"
        "}"
        "QListWidget::item {"
        "    padding: 8px;"
        "    border-radius: 4px;"
        "    margin: 2px;"
        "}"
        "QListWidget::item:selected {"
        "    background-color: %3;"
        "    color: %4;"
        "}"
        "QListWidget::item:disabled {"
        "    color: %5;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::MUTED_FOREGROUND.name()));
    connect(m_skillList, &QListWidget::itemClicked, this, &SkillSelectionDialog::handleSkillSelected);
    mainLayout->addWidget(m_skillList);

    // Description panel
    QLabel *descTitle = new QLabel("Skill Description:");
    descTitle->setStyleSheet("font-weight: bold; margin-top: 10px;");
    mainLayout->addWidget(descTitle);

    m_descriptionLabel = new QLabel("Select a skill to see its description");
    m_descriptionLabel->setWordWrap(true);
    m_descriptionLabel->setStyleSheet(QString("color: %1; padding: 8px;").arg(Theme::FOREGROUND.name()));
    mainLayout->addWidget(m_descriptionLabel);

    m_manaCostLabel = new QLabel("");
    m_manaCostLabel->setStyleSheet(QString("font-weight: bold; color: %1;").arg(Theme::ACCENT.name()));
    mainLayout->addWidget(m_manaCostLabel);

    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    m_cancelButton = new QPushButton("Cancel");
    m_cancelButton->setMinimumHeight(40);
    connect(m_cancelButton, &QPushButton::clicked, this, &QDialog::reject);

    m_useButton = new QPushButton("Use Skill");
    m_useButton->setMinimumHeight(40);
    m_useButton->setEnabled(false);
    m_useButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    font-weight: bold;"
        "}"
        "QPushButton:hover { background-color: %3; }"
        "QPushButton:disabled { background-color: %4; color: %5; }"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::PRIMARY.lighter(110).name())
     .arg(Theme::MUTED.name())
     .arg(Theme::MUTED_FOREGROUND.name()));
    connect(m_useButton, &QPushButton::clicked, this, &SkillSelectionDialog::handleUseSkill);

    buttonLayout->addWidget(m_cancelButton);
    buttonLayout->addWidget(m_useButton);
    mainLayout->addLayout(buttonLayout);
}

void SkillSelectionDialog::populateSkills()
{
    if (!m_player) return;

    for (Skill *skill : m_player->skills) {
        if (!skill) continue;

        bool canAfford = m_player->mana >= skill->manaCost;
        QString skillText = QString("%1 (Cost: %2 MP)").arg(skill->name).arg(skill->manaCost);

        if (!canAfford) {
            skillText += " - Not enough mana";
        }

        QListWidgetItem *item = new QListWidgetItem(skillText);
        item->setData(Qt::UserRole, QVariant::fromValue(static_cast<void*>(skill)));

        if (!canAfford) {
            item->setFlags(item->flags() & ~Qt::ItemIsEnabled);
        }

        m_skillList->addItem(item);
    }

    if (m_player->skills.isEmpty()) {
        QListWidgetItem *item = new QListWidgetItem("No skills available");
        item->setFlags(item->flags() & ~Qt::ItemIsEnabled & ~Qt::ItemIsSelectable);
        m_skillList->addItem(item);
    }
}

void SkillSelectionDialog::handleSkillSelected(QListWidgetItem *item)
{
    if (!item) return;

    Skill *skill = static_cast<Skill*>(item->data(Qt::UserRole).value<void*>());
    if (!skill) return;

    m_selectedSkill = skill;

    m_descriptionLabel->setText(skill->description);
    m_manaCostLabel->setText(QString("Mana Cost: %1 MP | Damage: %2 | Type: %3")
                                  .arg(skill->manaCost)
                                  .arg(skill->damage)
                                  .arg(skill->skillType));

    bool canAfford = m_player && m_player->mana >= skill->manaCost;
    m_useButton->setEnabled(canAfford);
}

void SkillSelectionDialog::handleUseSkill()
{
    if (m_selectedSkill) {
        accept();
    }
}

Skill* SkillSelectionDialog::getSelectedSkill() const
{
    return m_selectedSkill;
}
