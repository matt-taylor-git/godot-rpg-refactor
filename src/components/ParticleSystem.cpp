#include "ParticleSystem.h"
#include <QEasingCurve>
#include <QDebug>
#include <cmath>
#include <random>
#include <QFontMetrics>
#include <QGraphicsOpacityEffect>

// Thread-safe random number generator
namespace {
    std::random_device rd;
    std::mt19937 gen(rd());

    int randomInt(int min, int max) {
        std::uniform_int_distribution<> dis(min, max);
        return dis(gen);
    }
}

// --- Particle Implementation ---

Particle::Particle(QWidget *parent, const QString &particleType, const QString &color)
    : QLabel(parent),
      m_opacityEffect(new QGraphicsOpacityEffect(this))
{
    // The parent is passed from ParticleSystem::createBurst
    setParent(parent);
    setAttribute(Qt::WA_TranslucentBackground);
    setFixedSize(ParticleConstants::PARTICLE_SIZE, ParticleConstants::PARTICLE_SIZE);
    setGraphicsEffect(m_opacityEffect); // Apply the opacity effect

    QString text;
    if (particleType == "star") text = "⭐";
    else if (particleType == "spark") text = "✨";
    else if (particleType == "coin") text = "💰";
    else if (particleType == "heart") text = "💚";
    else text = "•";

    setText(text);
    setStyleSheet(QString("color: %1; font-size: 12px; font-weight: bold;").arg(color));
    show();
}

Particle::~Particle()
{
    // Animations are managed by Qt's parent-child ownership and will be
    // deleted automatically. We don't need to manually delete them here.
    // Just clear the list to avoid dangling pointers.
    m_animations.clear();
}

void Particle::animate(const QPoint &startPos, const QPoint &endPos, int duration)
{
    move(startPos);

    // Position animation (no parent set - managed by m_animations list)
    QPropertyAnimation *anim = new QPropertyAnimation(this, "pos");
    anim->setStartValue(startPos);

    // Add some randomness to end position
    QPoint variance(randomInt(-ParticleConstants::POSITION_VARIANCE, ParticleConstants::POSITION_VARIANCE),
                    randomInt(-ParticleConstants::POSITION_VARIANCE, ParticleConstants::POSITION_VARIANCE));
    anim->setEndValue(endPos + variance);

    anim->setDuration(duration);
    anim->setEasingCurve(QEasingCurve::OutExpo);

    // Fade out animation (no parent set - managed by m_animations list)
    QPropertyAnimation *fadeAnim = new QPropertyAnimation(m_opacityEffect, "opacity");
    fadeAnim->setStartValue(1.0);
    fadeAnim->setEndValue(0.0);
    fadeAnim->setDuration(static_cast<int>(duration * ParticleConstants::FADE_DURATION_RATIO));
    fadeAnim->setEasingCurve(QEasingCurve::InQuad);

    // Connect to delete the particle when fade is finished
    connect(fadeAnim, &QPropertyAnimation::finished, this, &Particle::deleteLater);

    anim->start();
    fadeAnim->start();

    m_animations.append(anim);
    m_animations.append(fadeAnim);
}

// --- ParticleSystem Implementation ---

ParticleSystem::ParticleSystem(QWidget *parent)
    : QWidget(parent),
      m_activeParticleCount(0),
      m_emitSignalWhenComplete(false)
{
    // The particle system should be transparent and cover the area where effects happen
    setAttribute(Qt::WA_TranslucentBackground);
    // Allow mouse events to pass through to underlying widgets (like buttons)
    setAttribute(Qt::WA_TransparentForMouseEvents);
    // We rely on the parent to set the geometry.
}

void ParticleSystem::createBurst(const QPoint &centerPos, int particleCount, const QString &particleType, const QString &color, bool emitSignal)
{
    // Input validation
    if (particleCount <= 0) {
        qWarning() << "ParticleSystem::createBurst: particleCount must be positive, got" << particleCount;
        return;
    }

    if (particleCount > ParticleConstants::MAX_PARTICLES_PER_BURST) {
        qWarning() << "ParticleSystem::createBurst: particleCount" << particleCount
                   << "exceeds maximum" << ParticleConstants::MAX_PARTICLES_PER_BURST
                   << ", clamping to maximum";
        particleCount = ParticleConstants::MAX_PARTICLES_PER_BURST;
    }

    if (emitSignal) {
        m_emitSignalWhenComplete = true;
    }

    for (int i = 0; i < particleCount; ++i) {
        Particle *particle = new Particle(this, particleType, color);

        // Track when particles are destroyed
        connect(particle, &QObject::destroyed, this, &ParticleSystem::onParticleDestroyed);
        m_activeParticleCount++;

        // Calculate position in circle
        double angle = (static_cast<double>(i) / particleCount) * 2 * M_PI;
        int radius = randomInt(ParticleConstants::MIN_RADIUS, ParticleConstants::MAX_RADIUS);
        int endX = centerPos.x() + static_cast<int>(std::cos(angle) * radius);
        int endY = centerPos.y() + static_cast<int>(std::sin(angle) * radius);

        QPoint startPos = centerPos - QPoint(ParticleConstants::PARTICLE_HALF_SIZE, ParticleConstants::PARTICLE_HALF_SIZE);
        QPoint endPos(endX, endY);

        int duration = randomInt(ParticleConstants::MIN_DURATION_MS, ParticleConstants::MAX_DURATION_MS);
        particle->animate(startPos, endPos, duration);
        m_particles.append(particle);
    }
}

void ParticleSystem::onParticleDestroyed()
{
    m_activeParticleCount--;

    // When all particles are destroyed, clean up and emit signal if needed
    if (m_activeParticleCount == 0) {
        m_particles.clear();
        if (m_emitSignalWhenComplete) {
            m_emitSignalWhenComplete = false;
            emit animationFinished();
        }
    }
}

void ParticleSystem::victoryExplosion(const QPoint &centerPos)
{
    // First burst doesn't emit signal
    createBurst(centerPos, 8, "star", "#e5c07b", false);
    // Second burst will emit signal when all particles from both bursts are done
    QTimer::singleShot(ParticleConstants::VICTORY_SECOND_BURST_DELAY_MS, [this, centerPos] {
        createBurst(centerPos, 6, "spark", "#98c379", true);
    });
}

void ParticleSystem::healingBurst(const QPoint &centerPos)
{
    createBurst(centerPos, 10, "heart", "#27ae60");
}

void ParticleSystem::levelUpBurst(const QPoint &centerPos)
{
    createBurst(centerPos, 15, "star", "#c678dd");
}

void ParticleSystem::goldRewardBurst(const QPoint &centerPos)
{
    createBurst(centerPos, 8, "coin", "#e5c07b");
}


