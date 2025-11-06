#ifndef SKILLSELECTIONDIALOG_H
#define SKILLSELECTIONDIALOG_H

#include <QDialog>
#include <QList>

class QListWidget;
class QListWidgetItem;
class QPushButton;
class QLabel;
class Skill;
class Player;

class SkillSelectionDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SkillSelectionDialog(Player *player, QWidget *parent = nullptr);
    Skill* getSelectedSkill() const;

private slots:
    void handleSkillSelected(QListWidgetItem *item);
    void handleUseSkill();

private:
    void setupUi();
    void populateSkills();

    Player *m_player;
    Skill *m_selectedSkill;

    QListWidget *m_skillList;
    QLabel *m_descriptionLabel;
    QLabel *m_manaCostLabel;
    QPushButton *m_useButton;
    QPushButton *m_cancelButton;
};

#endif // SKILLSELECTIONDIALOG_H
