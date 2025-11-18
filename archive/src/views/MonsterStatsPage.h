#ifndef MONSTERSTATSPAGE_H
#define MONSTERSTATSPAGE_H

#include <QWidget>

class QLabel;
class QVBoxLayout;

class MonsterStatsPage : public QWidget
{
    Q_OBJECT
public:
    explicit MonsterStatsPage(QWidget *parent = nullptr);

signals:
    void backRequested();

private:
    void setupUi();
    void createHeaderSection(QVBoxLayout *parentLayout);
    void createCombatStatsSection(QVBoxLayout *parentLayout);
    void createPhysicalTraitsSection(QVBoxLayout *parentLayout);
    void createElementalSection(QVBoxLayout *parentLayout);
    void createAbilitiesSection(QVBoxLayout *parentLayout);
    void createBehaviorSection(QVBoxLayout *parentLayout);
    void createMiscInfoSection(QVBoxLayout *parentLayout);
    QWidget* createStatSection(const QString &title);
    QLabel* createStatLabel(const QString &text);
    QLabel* createValueLabel(const QString &text);

    // Header
    QLabel *m_nameLabel;
    QLabel *m_levelLabel;
    QLabel *m_typeSizeLabel;

    // Combat Stats
    QLabel *m_healthLabel;
    QLabel *m_attackRangeLabel;
    QLabel *m_magicRangeLabel;
    QLabel *m_defenseLabel;
    QLabel *m_speedCritLabel;
    QLabel *m_armorLabel;
    QLabel *m_specialAttacksLabel;
    QLabel *m_combatStyleLabel;
    QLabel *m_rewardsLabel;
    QLabel *m_threatLabel;

    // Physical Traits
    QLabel *m_sizeLabel;
    QLabel *m_speedLabel;
    QLabel *m_movementLabel;
    QLabel *m_intelligenceLabel;
    QLabel *m_habitatLabel;

    // Elemental
    QLabel *m_elementalTypeLabel;
    QLabel *m_weaknessesLabel;
    QLabel *m_resistancesLabel;
    QLabel *m_immunitiesLabel;

    // Abilities
    QLabel *m_specialAbilitiesText;
    QLabel *m_passiveAbilitiesLabel;

    // Behavior
    QLabel *m_behaviorPatternsLabel;

    // Misc
    QLabel *m_descriptionLabel;
    QLabel *m_lootLabel;
};

#endif // MONSTERSTATSPAGE_H