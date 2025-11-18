#ifndef PARTICLESYSTEM_H
#define PARTICLESYSTEM_H

#include <QWidget>
#include <QLabel>
#include <QPropertyAnimation>
#include <QPoint>
#include <QList>
#include <QTimer>
#include <QObject>
#include <QGraphicsOpacityEffect> // Added for fading

// Particle animation constants
namespace ParticleConstants {
    constexpr int ATTACK_IMPACT_DELAY_MS = 300;
    constexpr int COMBAT_RESULT_DELAY_MS = 200;
    constexpr int LEVEL_UP_DELAY_MS = 500;
    constexpr int PARTICLE_SIZE = 16;
    constexpr int MIN_DURATION_MS = 800;
    constexpr int MAX_DURATION_MS = 1200;
    constexpr int MIN_RADIUS = 30;
    constexpr int MAX_RADIUS = 80;
    constexpr int POSITION_VARIANCE = 10;
    constexpr int PARTICLE_HALF_SIZE = PARTICLE_SIZE / 2;
    constexpr double FADE_DURATION_RATIO = 0.7;
    constexpr int VICTORY_SECOND_BURST_DELAY_MS = 200;
    constexpr int TEXT_FLOAT_DISTANCE = 30;
    constexpr int TEXT_ANIMATION_DURATION_MS = 2000;
    constexpr int TEXT_VERTICAL_OFFSET = 50;
    constexpr int MAX_PARTICLES_PER_BURST = 100;
}

// --- Particle Class ---
class Particle : public QLabel
{
    Q_OBJECT
    // Removed Q_PROPERTY for pos and windowOpacity, relying on QWidget::pos and QGraphicsOpacityEffect

public:
    explicit Particle(QWidget *parent = nullptr, const QString &particleType = "star", const QString &color = "#dc3545");
    ~Particle() override;

    void animate(const QPoint &startPos, const QPoint &endPos, int duration = 1000);

private:
    QList<QPropertyAnimation*> m_animations;
    QGraphicsOpacityEffect *m_opacityEffect; // New member for fading
};

// --- ParticleSystem Class ---
class ParticleSystem : public QWidget
{
    Q_OBJECT

signals:
    void animationFinished();

public:
    explicit ParticleSystem(QWidget *parent = nullptr);

    void createBurst(const QPoint &centerPos, int particleCount = 12, const QString &particleType = "star", const QString &color = "#dc3545", bool emitSignal = true);
    void victoryExplosion(const QPoint &centerPos);
    void healingBurst(const QPoint &centerPos);
    void levelUpBurst(const QPoint &centerPos);
    void goldRewardBurst(const QPoint &centerPos);

private slots:
    void onParticleDestroyed();

private:
    QList<Particle*> m_particles;
    int m_activeParticleCount;
    bool m_emitSignalWhenComplete;
};



#endif // PARTICLESYSTEM_H
