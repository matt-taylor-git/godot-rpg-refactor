#include "StoryEventDialog.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QFont>
#include <QPushButton>
#include <QSettings>
#include <QCoreApplication>

StoryEventDialog::StoryEventDialog(const StoryEvent &event, QWidget *parent)
    : QDialog(parent)
    , m_dontShowAgainCheckbox(nullptr)
{
    setModal(true);
    setWindowFlags(Qt::Dialog | Qt::FramelessWindowHint);
    setMinimumSize(700, 500);
    m_eventStartTime = QDateTime::currentMSecsSinceEpoch();
    setupUi(event);
}

void StoryEventDialog::setupUi(const StoryEvent &event)
{
    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_XL, Theme::SPACING_XL, Theme::SPACING_XL, Theme::SPACING_XL);
    mainLayout->setSpacing(Theme::SPACING_LG);

    // Title label
    QLabel *titleLabel = new QLabel(event.title, this);
    QFont titleFont;
    titleFont.setPixelSize(Theme::FONT_SIZE_XXXL);
    titleFont.setBold(true);
    titleLabel->setFont(titleFont);
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setStyleSheet(QString("color: %1; padding: %2px;")
                             .arg(Theme::PRIMARY.name())
                             .arg(Theme::SPACING_MD));
    mainLayout->addWidget(titleLabel);

    mainLayout->addSpacing(Theme::SPACING_LG);

    // Event text
    QTextEdit *eventText = new QTextEdit(this);
    eventText->setReadOnly(true);
    eventText->setPlainText(event.eventText);
    eventText->setAlignment(Qt::AlignCenter);
    QFont textFont;
    textFont.setPixelSize(Theme::FONT_SIZE_LG);
    // Normal weight is default, no need to set
    eventText->setFont(textFont);
    eventText->setStyleSheet(QString(
        "QTextEdit {"
        "    background-color: transparent;"
        "    color: %1;"
        "    border: none;"
        "    padding: %2px;"
        "}"
    ).arg(Theme::FOREGROUND.name())
     .arg(Theme::SPACING_MD));
    mainLayout->addWidget(eventText, 1);

    mainLayout->addSpacing(Theme::SPACING_LG);

    // "Don't show again" checkbox for tutorial events
    if (event.eventId == "quest_system_intro") {
        QSettings settings;
        QString settingsKey = "dismissed_events/" + event.eventId;
        bool alreadyDismissed = settings.value(settingsKey, false).toBool();

        if (!alreadyDismissed) {
            m_dontShowAgainCheckbox = new QCheckBox("Don't show this again", this);
            m_dontShowAgainCheckbox->setFont(textFont);
            m_dontShowAgainCheckbox->setStyleSheet(QString(
                "QCheckBox {"
                "    color: %1;"
                "    spacing: %2px;"
                "}"
                "QCheckBox::indicator {"
                "    width: %3px;"
                "    height: %3px;"
                "}"
            ).arg(Theme::FOREGROUND.name())
             .arg(Theme::SPACING_SM)
             .arg(Theme::SPACING_LG));

            mainLayout->addWidget(m_dontShowAgainCheckbox, 0, Qt::AlignCenter);
            mainLayout->addSpacing(Theme::SPACING_LG);
        }
    }

    // Continue button
    QPushButton *continueBtn = new QPushButton("Got it! (ESC)", this);
    continueBtn->setMinimumHeight(50);
    continueBtn->setMaximumWidth(300);
    QFont btnFont;
    btnFont.setPixelSize(Theme::FONT_SIZE_LG);
    btnFont.setBold(true);
    continueBtn->setFont(btnFont);
    continueBtn->setCursor(Qt::PointingHandCursor);

    continueBtn->setStyleSheet(QString(
        "QPushButton {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: %3px solid %4;"
        "    border-radius: %5px;"
        "    padding: %6px;"
        "}"
        "QPushButton:hover {"
        "    background-color: %7;"
        "    border-color: %8;"
        "}"
        "QPushButton:pressed {"
        "    background-color: %9;"
        "}"
    ).arg(Theme::PRIMARY.name())
     .arg(Theme::PRIMARY_FOREGROUND.name())
     .arg(Theme::BORDER_WIDTH_MEDIUM)
     .arg(Theme::PRIMARY.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD)
     .arg(Theme::ACCENT.name())
     .arg(Theme::ACCENT.name())
     .arg(Theme::SECONDARY.name()));

    connect(continueBtn, &QPushButton::clicked, [this, &event]() {
        // Save "don't show again" preference if checkbox exists
        if (m_dontShowAgainCheckbox && m_dontShowAgainCheckbox->isChecked()) {
            QSettings settings;
            QString settingsKey = "dismissed_events/" + event.eventId;
            settings.setValue(settingsKey, true);
        }
        accept();
    });

    QHBoxLayout *buttonLayout = new QHBoxLayout();
    buttonLayout->addStretch();
    buttonLayout->addWidget(continueBtn);
    buttonLayout->addStretch();
    mainLayout->addLayout(buttonLayout);

    // Apply dark theme with semi-transparent overlay
    setStyleSheet(QString(
        "QDialog {"
        "    background-color: %1;"
        "    border: %2px solid %3;"
        "    border-radius: %4px;"
        "}"
    ).arg(Theme::BACKGROUND.name())
     .arg(Theme::BORDER_WIDTH_THICK)
     .arg(Theme::ACCENT.name())
     .arg(Theme::BORDER_RADIUS_LG));
}

void StoryEventDialog::keyPressEvent(QKeyEvent *event)
{
    // Prevent accidental skip within first second
    qint64 elapsed = QDateTime::currentMSecsSinceEpoch() - m_eventStartTime;
    if (elapsed < 1000) {
        return;
    }

    if (event->key() == Qt::Key_Escape || event->key() == Qt::Key_Return || event->key() == Qt::Key_Space) {
        // Save "don't show again" preference if checkbox exists
        if (m_dontShowAgainCheckbox && m_dontShowAgainCheckbox->isChecked()) {
            QSettings settings;
            QString settingsKey = "dismissed_events/quest_system_intro";
            settings.setValue(settingsKey, true);
        }
        accept();
        return;
    }

    QDialog::keyPressEvent(event);
}
