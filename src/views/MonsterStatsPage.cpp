#include "MonsterStatsPage.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QFrame>
#include <QGroupBox>
#include <QScrollArea>
#include <QPushButton>

MonsterStatsPage::MonsterStatsPage(QWidget *parent) : QWidget(parent)
{
    setupUi();
}

void MonsterStatsPage::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_MD);

    createHeaderSection(mainLayout);

    QScrollArea *scrollArea = new QScrollArea();
    scrollArea->setWidgetResizable(true);
    QWidget *contentWidget = new QWidget();
    QVBoxLayout *contentLayout = new QVBoxLayout(contentWidget);
    contentLayout->setSpacing(Theme::SPACING_MD);

    createCombatStatsSection(contentLayout);
    createPhysicalTraitsSection(contentLayout);
    createElementalSection(contentLayout);
    createAbilitiesSection(contentLayout);
    createBehaviorSection(contentLayout);
    createMiscInfoSection(contentLayout);

    scrollArea->setWidget(contentWidget);
    mainLayout->addWidget(scrollArea);
}

void MonsterStatsPage::createHeaderSection(QVBoxLayout *parentLayout)
{
    QFrame *headerCard = new QFrame();
    QHBoxLayout *headerLayout = new QHBoxLayout(headerCard);
    headerLayout->setSpacing(Theme::SPACING_LG);

    QLabel *imageLabel = new QLabel("👹");
    imageLabel->setAlignment(Qt::AlignCenter);
    imageLabel->setFixedSize(100, 100);
    imageLabel->setStyleSheet("font-size: 48px;");
    headerLayout->addWidget(imageLabel);

    QVBoxLayout *infoLayout = new QVBoxLayout();
    m_nameLabel = new QLabel("Monster Name");
    m_nameLabel->setStyleSheet("font-size: 20px; font-weight: bold;");
    infoLayout->addWidget(m_nameLabel);

    m_levelLabel = new QLabel("Level 1 - Rarity");
    infoLayout->addWidget(m_levelLabel);

    m_typeSizeLabel = new QLabel("Type - Size Category");
    infoLayout->addWidget(m_typeSizeLabel);

    headerLayout->addLayout(infoLayout);
    parentLayout->addWidget(headerCard);
}

void MonsterStatsPage::createCombatStatsSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("⚔️ Combat Statistics");
    QGridLayout *grid = new QGridLayout(section);

    grid->addWidget(createStatLabel("Health:"), 0, 0);
    m_healthLabel = createValueLabel(R"(???/???)");
    grid->addWidget(m_healthLabel, 0, 1);

    parentLayout->addWidget(section);
}

void MonsterStatsPage::createPhysicalTraitsSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("🏋️ Physical Traits");
    parentLayout->addWidget(section);
}

void MonsterStatsPage::createElementalSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("🔮 Elemental Properties");
    parentLayout->addWidget(section);
}

void MonsterStatsPage::createAbilitiesSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("✨ Abilities & Skills");
    parentLayout->addWidget(section);
}

void MonsterStatsPage::createBehaviorSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("🧠 Behavior Patterns");
    parentLayout->addWidget(section);
}

void MonsterStatsPage::createMiscInfoSection(QVBoxLayout *parentLayout)
{
    QWidget *section = createStatSection("📚 Additional Information");
    parentLayout->addWidget(section);
}

QWidget* MonsterStatsPage::createStatSection(const QString &title)
{
    QGroupBox *section = new QGroupBox(title);
    section->setStyleSheet(QString(
        "QGroupBox { font-weight: bold; border: 2px solid %1; border-radius: 8px; margin-top: 8px; padding-top: 8px; }"
        "QGroupBox::title { subcontrol-origin: margin; left: 8px; padding: 0 8px 0 8px; }"
    ).arg(Theme::BORDER.name()));
    return section;
}

QLabel* MonsterStatsPage::createStatLabel(const QString &text)
{
    QLabel *label = new QLabel(text);
    label->setStyleSheet("font-weight: bold;");
    return label;
}

QLabel* MonsterStatsPage::createValueLabel(const QString &text)
{
    return new QLabel(text);
}
