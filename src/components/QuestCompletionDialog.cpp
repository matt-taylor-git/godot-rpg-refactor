#include "QuestCompletionDialog.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>

QuestCompletionDialog::QuestCompletionDialog(const QString &questTitle, int expGained,
                                             int goldGained, const QList<QString> &itemNames,
                                             QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("Quest Complete!");
    setModal(true);
    setMinimumWidth(400);
    setupUi(questTitle, expGained, goldGained, itemNames);
}

void QuestCompletionDialog::setupUi(const QString &title, int exp, int gold, const QList<QString> &items)
{
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setSpacing(Theme::SPACING_MD);
    layout->setContentsMargins(Theme::SPACING_XL, Theme::SPACING_XL,
                              Theme::SPACING_XL, Theme::SPACING_XL);

    // Apply dialog styling
    setStyleSheet(QString(
        "QDialog {"
        "    background-color: %1;"
        "    border: 2px solid %2;"
        "    border-radius: %3px;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD));

    // Celebration header
    QLabel *celebrationLabel = new QLabel("🎉 QUEST COMPLETE! 🎉");
    celebrationLabel->setAlignment(Qt::AlignCenter);
    celebrationLabel->setStyleSheet(QString(
        "font-size: %1px; font-weight: %2; color: %3; margin: 10px 0px;"
    ).arg(Theme::FONT_SIZE_XL)
     .arg(Theme::FONT_WEIGHT_BOLD)
     .arg(Theme::ACCENT.name()));
    layout->addWidget(celebrationLabel);

    // Quest title
    QLabel *titleLabel = new QLabel(title);
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setWordWrap(true);
    titleLabel->setStyleSheet(QString(
        "font-size: %1px; font-weight: %2; color: %3; margin-bottom: 15px;"
    ).arg(Theme::FONT_SIZE_LG)
     .arg(Theme::FONT_WEIGHT_SEMIBOLD)
     .arg(Theme::PRIMARY.name()));
    layout->addWidget(titleLabel);

    // Rewards section
    QLabel *rewardsHeader = new QLabel("Rewards Received:");
    rewardsHeader->setStyleSheet(QString(
        "font-size: %1px; font-weight: %2; color: %3; margin-top: 10px;"
    ).arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_SEMIBOLD)
     .arg(Theme::FOREGROUND.name()));
    layout->addWidget(rewardsHeader);

    // Experience reward
    if (exp > 0) {
        QLabel *expLabel = new QLabel(QString("• +%1 Experience").arg(exp));
        expLabel->setStyleSheet(QString(
            "font-size: %1px; color: %2; margin-left: 20px;"
        ).arg(Theme::FONT_SIZE_MD)
         .arg(Theme::ACCENT.name()));
        layout->addWidget(expLabel);
    }

    // Gold reward
    if (gold > 0) {
        QLabel *goldLabel = new QLabel(QString("• +%1 Gold").arg(gold));
        goldLabel->setStyleSheet(QString(
            "font-size: %1px; color: %2; margin-left: 20px;"
        ).arg(Theme::FONT_SIZE_MD)
         .arg(Theme::PRIMARY.name()));
        layout->addWidget(goldLabel);
    }

    // Item rewards
    if (!items.isEmpty()) {
        QLabel *itemsLabel = new QLabel(QString("• Items: %1").arg(items.join(", ")));
        itemsLabel->setWordWrap(true);
        itemsLabel->setStyleSheet(QString(
            "font-size: %1px; color: %2; margin-left: 20px;"
        ).arg(Theme::FONT_SIZE_MD)
         .arg(Theme::FOREGROUND.name()));
        layout->addWidget(itemsLabel);
    }

    // Spacer
    layout->addSpacing(20);

    // Continue button
    QPushButton *continueButton = new QPushButton("Continue");
    continueButton->setMinimumHeight(40);
    continueButton->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: none;"
        "    border-radius: %3px;"
        "    padding: %4px;"
        "    font-size: %5px;"
        "    font-weight: %6;"
        "}"
        "QPushButton:hover {"
        "    background-color: %7;"
        "}"
        "QPushButton:pressed {"
        "    background-color: %8;"
        "}"
    ).arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT_FOREGROUND.name())
     .arg(Theme::BORDER_RADIUS_SM)
     .arg(Theme::SPACING_MD)
     .arg(Theme::FONT_SIZE_MD)
     .arg(Theme::FONT_WEIGHT_MEDIUM)
     .arg(Theme::PRIMARY.name())
     .arg(Theme::DESTRUCTIVE.name()));

    connect(continueButton, &QPushButton::clicked, this, &QDialog::accept);
    layout->addWidget(continueButton);
}
