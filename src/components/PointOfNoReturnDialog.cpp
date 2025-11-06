#include "PointOfNoReturnDialog.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QFont>

PointOfNoReturnDialog::PointOfNoReturnDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("⚠️ Point of No Return");
    setMinimumWidth(500);
    setMinimumHeight(350);
    setupUi();
}

void PointOfNoReturnDialog::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(Theme::SPACING_LG);
    mainLayout->setContentsMargins(Theme::SPACING_XL, Theme::SPACING_XL,
                                   Theme::SPACING_XL, Theme::SPACING_XL);

    // Warning icon/title
    QLabel *warningIcon = new QLabel("⚠️");
    QFont iconFont;
    iconFont.setPointSize(48);
    warningIcon->setFont(iconFont);
    warningIcon->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(warningIcon);

    // Warning title
    QLabel *titleLabel = new QLabel("POINT OF NO RETURN");
    QFont titleFont;
    titleFont.setPointSize(20);
    titleFont.setBold(true);
    titleLabel->setFont(titleFont);
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setStyleSheet(QString("color: %1; margin-bottom: 10px;")
                                  .arg(Theme::DESTRUCTIVE.name()));
    mainLayout->addWidget(titleLabel);

    // Warning message
    QLabel *messageLabel = new QLabel(
        "You are about to face the final boss.\n\n"
        "This is a climactic battle that will test everything you've learned.\n"
        "Make sure you are fully prepared before proceeding."
    );
    messageLabel->setWordWrap(true);
    messageLabel->setAlignment(Qt::AlignCenter);
    messageLabel->setStyleSheet(QString(
        "font-size: %1px; "
        "color: %2; "
        "background-color: %3; "
        "padding: %4px; "
        "border: 2px solid %5; "
        "border-radius: %6px;"
    ).arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::CARD.name())
     .arg(Theme::SPACING_LG)
     .arg(Theme::DESTRUCTIVE.name())
     .arg(Theme::BORDER_RADIUS_MD));
    mainLayout->addWidget(messageLabel);

    // Requirements section
    QLabel *requirementsLabel = new QLabel("✓ Requirements Met:\n• Level 20 or higher\n• All main quests completed");
    requirementsLabel->setStyleSheet(QString(
        "font-size: %1px; "
        "color: %2; "
        "background-color: %3; "
        "padding: %4px; "
        "border-radius: %5px;"
    ).arg(Theme::FONT_SIZE_SM)
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BACKGROUND.name())
     .arg(Theme::SPACING_MD)
     .arg(Theme::BORDER_RADIUS_SM));
    mainLayout->addWidget(requirementsLabel);

    // Preparation tips
    QLabel *tipsLabel = new QLabel("⚡ Preparation Tips:\n• Equip your best gear\n• Stock up on healing items\n• Ensure your skills are ready");
    tipsLabel->setStyleSheet(QString(
        "font-size: %1px; "
        "color: %2; "
        "padding: %3px;"
    ).arg(Theme::FONT_SIZE_SM)
     .arg(Theme::MUTED_FOREGROUND.name())
     .arg(Theme::SPACING_SM));
    mainLayout->addWidget(tipsLabel);

    // Add spacing
    mainLayout->addSpacing(Theme::SPACING_MD);

    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    buttonLayout->setSpacing(Theme::SPACING_MD);

    QPushButton *notYetButton = new QPushButton("Not Yet");
    notYetButton->setMinimumHeight(40);
    notYetButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: 2px solid %3;"
        "    border-radius: %4px;"
        "    padding: %5px %6px;"
        "    font-size: %7px;"
        "    font-weight: %8;"
        "}"
        "QPushButton:hover {"
        "    background-color: %9;"
        "}"
    ).arg(Theme::SECONDARY.name())
     .arg(Theme::SECONDARY_FOREGROUND.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::SPACING_LG)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_BOLD)
     .arg(Theme::MUTED.name()));
    connect(notYetButton, &QPushButton::clicked, this, &QDialog::reject);

    QPushButton *readyButton = new QPushButton("I'm Ready!");
    readyButton->setMinimumHeight(40);
    readyButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: none;"
        "    border-radius: %3px;"
        "    padding: %4px %5px;"
        "    font-size: %6px;"
        "    font-weight: %7;"
        "}"
        "QPushButton:hover {"
        "    background-color: %8;"
        "}"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::SPACING_LG)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_BOLD)
     .arg(Theme::DESTRUCTIVE.name()));
    connect(readyButton, &QPushButton::clicked, this, &QDialog::accept);

    buttonLayout->addWidget(notYetButton);
    buttonLayout->addWidget(readyButton);

    mainLayout->addLayout(buttonLayout);
}
