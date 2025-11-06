#include "CharacterCustomizationPage.h"
#include "../components/CharacterPreviewWidget.h"
#include "../components/CustomizationSection.h"
#include "../components/ValidationLabel.h"
#include "../theme/Theme.h"
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLineEdit>
#include <QPushButton>

CharacterCustomizationPage::CharacterCustomizationPage(QWidget *parent) : QWidget(parent)
{
    setupUi();
}

void CharacterCustomizationPage::setupUi()
{
    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_LG);

    // Left side: Preview
    m_previewWidget = new CharacterPreviewWidget();
    mainLayout->addWidget(m_previewWidget);

    // Right side: Options
    QVBoxLayout *optionsLayout = new QVBoxLayout();
    optionsLayout->setSpacing(Theme::SPACING_MD);

    // Name section
    m_nameInput = new QLineEdit("Hero");
    m_nameInput->setStyleSheet(QString(
        "QLineEdit {"
        "    font-size: 14px;"
        "    padding: 8px;"
        "    border: 1px solid %1;"
        "    border-radius: 4px;"
        "    background-color: %2;"
        "    color: %3;"
        "}"
        "QLineEdit:focus {"
        "    border-color: %4;"
        "}"
    ).arg(Theme::BORDER.name()).arg(Theme::CARD.name()).arg(Theme::FOREGROUND.name()).arg(Theme::PRIMARY.name()));
    optionsLayout->addWidget(m_nameInput);

    m_nameValidation = new ValidationLabel();
    optionsLayout->addWidget(m_nameValidation);

    // Appearance section
    m_appearanceSection = new CustomizationSection("Appearance");
    m_appearanceSection->addOption("Hair Color", "hair_color", {{"Black", "black"}, {"Brown", "brown"}, {"Blonde", "blonde"}, {"Red", "red"}});
    m_appearanceSection->addOption("Hair Style", "hair_style", {{"Short", "short"}, {"Long", "long"}, {"Medium", "medium"}});
    m_appearanceSection->addOption("Skin Tone", "skin_tone", {{"Pale", "pale"}, {"Fair", "fair"}, {"Medium", "medium"}, {"Tan", "tan"}});
    m_appearanceSection->addOption("Eye Color", "eye_color", {{"Brown", "brown"}, {"Blue", "blue"}, {"Green", "green"}});
    optionsLayout->addWidget(m_appearanceSection);

    // Cosmetic section
    m_cosmeticSection = new CustomizationSection("Cosmetics");
    m_cosmeticSection->addOption("Headgear", "headgear", {{"None", "none"}, {"Cap", "cap"}});
    m_cosmeticSection->addOption("Accessory", "accessory", {{"None", "none"}, {"Scarf", "scarf"}});
    optionsLayout->addWidget(m_cosmeticSection);

    // Action buttons
    QHBoxLayout *actionsLayout = new QHBoxLayout();
    actionsLayout->setSpacing(Theme::SPACING_MD);

    m_saveButton = new QPushButton("💾 Save");
    m_loadButton = new QPushButton("📁 Load");
    m_resetButton = new QPushButton("🔄 Reset");

    actionsLayout->addWidget(m_saveButton);
    actionsLayout->addWidget(m_loadButton);
    actionsLayout->addWidget(m_resetButton);
    optionsLayout->addLayout(actionsLayout);

    optionsLayout->addStretch();
    mainLayout->addLayout(optionsLayout);
}