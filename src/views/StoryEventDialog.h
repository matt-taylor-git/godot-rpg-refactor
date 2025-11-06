#ifndef STORYEVENTDIALOG_H
#define STORYEVENTDIALOG_H

#include <QDialog>
#include <QLabel>
#include <QTextEdit>
#include <QPushButton>
#include <QCheckBox>
#include "../models/StoryEvent.h"
#include <QKeyEvent>
#include <QDateTime>
#include <QSettings>

class StoryEventDialog : public QDialog
{
    Q_OBJECT

public:
    explicit StoryEventDialog(const StoryEvent &event, QWidget *parent = nullptr);

protected:
    void keyPressEvent(QKeyEvent *event) override;

private:
    void setupUi(const StoryEvent &event);

    qint64 m_eventStartTime;
    QCheckBox *m_dontShowAgainCheckbox;
};

#endif // STORYEVENTDIALOG_H
