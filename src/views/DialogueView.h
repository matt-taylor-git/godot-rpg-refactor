#ifndef DIALOGUEVIEW_H
#define DIALOGUEVIEW_H

#include <QDialog>
#include <QLabel>
#include <QTextEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QList>
#include <QKeyEvent>

class DialogueView : public QDialog
{
    Q_OBJECT

public:
    explicit DialogueView(QWidget *parent = nullptr);

    // Display dialogue node
    void displayNode(const QString &speaker, const QString &text, const QStringList &choiceTexts);
    void setChoiceEnabled(int index, bool enabled);

signals:
    void choiceSelected(int choiceIndex);
    void dialogueClosed();

protected:
    void keyPressEvent(QKeyEvent *event) override;

private:
    void setupUi();
    void clearChoices();

    QLabel *m_speakerLabel;
    QTextEdit *m_dialogueText;
    QVBoxLayout *m_choicesLayout;
    QList<QPushButton*> m_choiceButtons;
};

#endif // DIALOGUEVIEW_H
