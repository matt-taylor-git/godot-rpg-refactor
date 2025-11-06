#ifndef QUESTCOMPLETIONDIALOG_H
#define QUESTCOMPLETIONDIALOG_H

#include <QDialog>
#include <QList>
#include <QString>

class QuestCompletionDialog : public QDialog
{
    Q_OBJECT

public:
    explicit QuestCompletionDialog(const QString &questTitle, int expGained,
                                   int goldGained, const QList<QString> &itemNames,
                                   QWidget *parent = nullptr);

private:
    void setupUi(const QString &title, int exp, int gold, const QList<QString> &items);
};

#endif // QUESTCOMPLETIONDIALOG_H
