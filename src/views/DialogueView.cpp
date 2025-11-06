#include "DialogueView.h"
#include "../theme/Theme.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFont>

DialogueView::DialogueView(QWidget *parent)
    : QDialog(parent)
{
    setupUi();
}

void DialogueView::setupUi()
{
    setWindowTitle("Dialogue");
    setModal(true);
    setMinimumSize(600, 400);

    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG, Theme::SPACING_LG);
    mainLayout->setSpacing(Theme::SPACING_MD);

    // Speaker label
    m_speakerLabel = new QLabel(this);
    QFont speakerFont;
    speakerFont.setPixelSize(Theme::FONT_SIZE_XL);
    speakerFont.setBold(true);
    m_speakerLabel->setFont(speakerFont);
    m_speakerLabel->setStyleSheet(QString("color: %1; padding: %2px;")
                                  .arg(Theme::ACCENT.name())
                                  .arg(Theme::SPACING_SM));
    mainLayout->addWidget(m_speakerLabel);

    // Dialogue text area
    m_dialogueText = new QTextEdit(this);
    m_dialogueText->setReadOnly(true);
    m_dialogueText->setMinimumHeight(150);
    QFont textFont;
    textFont.setPixelSize(Theme::FONT_SIZE_MD);
    m_dialogueText->setFont(textFont);
    m_dialogueText->setStyleSheet(QString(
        "QTextEdit {"
        "    background-color: %1;"
        "    color: %2;"
        "    border: %3px solid %4;"
        "    border-radius: %5px;"
        "    padding: %6px;"
        "}"
    ).arg(Theme::CARD.name())
     .arg(Theme::FOREGROUND.name())
     .arg(Theme::BORDER_WIDTH_MEDIUM)
     .arg(Theme::BORDER.name())
     .arg(Theme::BORDER_RADIUS_MD)
     .arg(Theme::SPACING_MD));
    mainLayout->addWidget(m_dialogueText);

    // Choices container
    QWidget *choicesContainer = new QWidget(this);
    m_choicesLayout = new QVBoxLayout(choicesContainer);
    m_choicesLayout->setSpacing(Theme::SPACING_SM);
    m_choicesLayout->setContentsMargins(0, 0, 0, 0);
    mainLayout->addWidget(choicesContainer);

    mainLayout->addStretch();

    // Apply dark theme to dialog
    setStyleSheet(QString(
        "QDialog {"
        "    background-color: %1;"
        "}"
    ).arg(Theme::BACKGROUND.name()));
}

void DialogueView::displayNode(const QString &speaker, const QString &text, const QStringList &choiceTexts)
{
    m_speakerLabel->setText(speaker);
    m_dialogueText->setText(text);

    // Clear previous choices
    clearChoices();

    // Create choice buttons
    for (int i = 0; i < choiceTexts.size(); ++i) {
        QPushButton *btn = new QPushButton(QString("[%1] %2").arg(i + 1).arg(choiceTexts[i]), this);
        btn->setMinimumHeight(50);
        btn->setCursor(Qt::PointingHandCursor);

        QFont btnFont;
        btnFont.setPixelSize(Theme::FONT_SIZE_MD);
        btn->setFont(btnFont);

        btn->setStyleSheet(QString(
            "QPushButton {"
            "    background-color: %1;"
            "    color: %2;"
            "    border: %3px solid %4;"
            "    border-radius: %5px;"
            "    padding: %6px;"
            "    text-align: left;"
            "    padding-left: %7px;"
            "}"
            "QPushButton:hover {"
            "    background-color: %8;"
            "    border-color: %9;"
            "}"
            "QPushButton:pressed {"
            "    background-color: %10;"
            "}"
            "QPushButton:disabled {"
            "    background-color: %11;"
            "    color: %12;"
            "    border-color: %13;"
            "}"
        ).arg(Theme::CARD.name())
         .arg(Theme::FOREGROUND.name())
         .arg(Theme::BORDER_WIDTH_MEDIUM)
         .arg(Theme::BORDER.name())
         .arg(Theme::BORDER_RADIUS_SM)
         .arg(Theme::SPACING_MD)
         .arg(Theme::SPACING_LG)
         .arg(Theme::SECONDARY.name())
         .arg(Theme::ACCENT.name())
         .arg(Theme::MUTED.name())
         .arg(Theme::MUTED.name())
         .arg(Theme::MUTED_FOREGROUND.name())
         .arg(Theme::MUTED.name()));

        connect(btn, &QPushButton::clicked, this, [this, i]() {
            emit choiceSelected(i);
        });

        m_choiceButtons.append(btn);
        m_choicesLayout->addWidget(btn);
    }
}

void DialogueView::setChoiceEnabled(int index, bool enabled)
{
    if (index >= 0 && index < m_choiceButtons.size()) {
        m_choiceButtons[index]->setEnabled(enabled);
        if (!enabled) {
            m_choiceButtons[index]->setToolTip("Requirements not met");
        }
    }
}

void DialogueView::clearChoices()
{
    for (QPushButton *btn : m_choiceButtons) {
        delete btn;
    }
    m_choiceButtons.clear();
}

void DialogueView::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Escape) {
        emit dialogueClosed();
        reject();
        return;
    }

    // Number keys 1-9 select choices
    if (event->key() >= Qt::Key_1 && event->key() <= Qt::Key_9) {
        int index = event->key() - Qt::Key_1;
        if (index < m_choiceButtons.size() && m_choiceButtons[index]->isEnabled()) {
            emit choiceSelected(index);
        }
        return;
    }

    QDialog::keyPressEvent(event);
}
