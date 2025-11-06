#include "CustomizationSection.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QComboBox>

CustomizationSection::CustomizationSection(const QString &title, QWidget *parent)
    : QGroupBox(title, parent)
{
    m_sectionLayout = new QVBoxLayout(this);
    m_sectionLayout->setSpacing(Theme::SPACING_MD);
    setStyleSheet(QString(
        "QGroupBox {"
        "    font-weight: bold;"
        "    border: 2px solid %1;"
        "    border-radius: 8px;"
        "    margin-top: 8px;"
        "    padding: 8px;"
        "    color: %2;"
        "}"
        "QGroupBox::title {"
        "    subcontrol-origin: margin;"
        "    left: 8px;"
        "    padding: 0 4px 0 4px;"
        "    color: #dc3545;"
        "}"
    ).arg(Theme::BORDER.name()).arg(Theme::FOREGROUND.name()));
}

void CustomizationSection::addOption(const QString &labelText, const QString &optionKey, const QList<QPair<QString, QString>> &options)
{
    QHBoxLayout *optionLayout = new QHBoxLayout();

    QLabel *label = new QLabel(labelText);
    label->setStyleSheet(QString("color: %1; font-size: 14px;").arg(Theme::FOREGROUND.name()));
    optionLayout->addWidget(label);

    QComboBox *combo = new QComboBox();
    combo->setStyleSheet(QString(
        "QComboBox {"
        "    background-color: %1;"
        "    border: 1px solid %2;"
        "    border-radius: 4px;"
        "    padding: 4px;"
        "    color: %3;"
        "    font-size: 12px;"
        "}"
        "QComboBox::drop-down {"
        "    border: none;"
        "}"
        "QComboBox::down-arrow {"
        "    image: none;"
        "    border-left: 4px solid transparent;"
        "    border-right: 4px solid transparent;"
        "    border-top: 4px solid %3;"
        "    margin-right: 8px;"
        "}"
    ).arg(Theme::CARD.name()).arg(Theme::BORDER.name()).arg(Theme::FOREGROUND.name()));

    for (const auto &option : options) {
        combo->addItem(option.first, option.second);
    }

    optionLayout->addWidget(combo);
    m_sectionLayout->addLayout(optionLayout);
}
