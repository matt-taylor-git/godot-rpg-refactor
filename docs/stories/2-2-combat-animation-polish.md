# Story 2.2: Combat Animation Polish

Status: review

## Story

As a player watching combat,
I want smooth, satisfying animations for all combat actions,
so that battles feel dynamic and engaging.

## Acceptance Criteria

1. **AC-2.2.1: Damage and Healing Numbers** - Given combat damage or healing occurs, when the value changes, then a number pops up at the target position with bounce animation (500ms total), and damage numbers are red with shake effect while healing numbers are green with pulse, and critical hits show larger numbers with additional effect (screen flash), and numbers fade out smoothly over 400ms

2. **AC-2.2.2: Combat Animation Polish** - Given a character performs a combat action (attack or spell), when the action executes, then character sprite shows appropriate animation (attack motion or cast pose, 300ms), and screen shake occurs for impactful attacks (5px displacement, 100ms), and spell casts show particle effects traveling to target (500ms duration), and all animations complete without dropping below 60fps, and animations enhance gameplay without delaying turn resolution

3. **AC-2.2.3: Turn Indicator Clarity** - Given combat is in progress, when a character's turn begins, then their portrait highlights with subtle glow effect, and non-active portraits dim slightly for contrast, and the active indicator is clearly visible at all screen sizes, and transition between active characters is smooth (200ms)

4. **AC-2.2.4: Animation Performance** - Given combat animations are playing, when monitoring game performance, then frame rate maintains 60fps throughout, and frame drops below 55fps trigger a warning (development mode), and memory usage stays under 500MB, and animations don't delay game logic or turn resolution

5. **AC-2.2.5: Animation Accessibility** - Given a player has reduced motion preferences enabled, when combat animations play, then animations are disabled or minimized per user settings, and all combat information remains visible without animations, and the UI remains fully functional with instant state updates instead of animated transitions

## Tasks / Subtasks

- [x] **Task 1: Create DamageNumberPopup Component** (AC: AC-2.2.1)
  - [x] Create DamageNumberPopup.gd script in scripts/components/
  - [x] Create damage_number_popup.tscn scene in scenes/components/
  - [x] Implement bounce animation with 500ms duration using Tween
  - [x] Add color coding: red for damage, green for healing
  - [x] Implement shake effect for damage numbers
  - [x] Implement pulse effect for healing numbers
  - [x] Add critical hit effect with larger font and screen flash
  - [x] Implement fade out animation (400ms)
  - [x] Ensure proper tween cleanup to prevent memory leaks
  - [x] Integrate with ui_theme.tres for consistent styling

- [x] **Task 2: Create CombatAnimationController** (AC: AC-2.2.2, AC-2.2.4)
  - [x] Create CombatAnimationController.gd script in scripts/components/
  - [x] Implement attack animation coordination (300ms sprite animation)
  - [x] Implement screen shake effect (5px displacement, 100ms duration)
  - [x] Create spell cast animation system with particle effects
  - [x] Add particle effect management using GPUParticles2D
  - [x] Implement animation sequencing and callback system
  - [x] Add signals: animation_started, animation_completed, damage_number_spawned
  - [x] Integrate with GameManager combat signals
  - [x] Ensure animations don't block turn resolution

- [x] **Task 3: Implement Particle Effect System** (AC: AC-2.2.2)
  - [x] Create particle effect resources for spell types
  - [x] Implement particle path animation (curved trajectory to target, 500ms)
  - [x] Add impact particle effects (explosion/flash at target position)
  - [x] Create particle pooling system for performance optimization
  - [x] Limit maximum concurrent particles (100 per effect, 300 total)
  - [x] Ensure GPU particles for performance

- [x] **Task 4: Implement Turn Indicator System** (AC: AC-2.2.3)
  - [x] Add active character glow effect to sprite nodes
  - [x] Implement portrait dimming for non-active characters
  - [x] Add smooth transition animation (200ms) between active characters
  - [x] Ensure visibility at all screen resolutions
  - [x] Connect to GameManager combat signals

- [x] **Task 5: Add Performance Monitoring** (AC: AC-2.2.4)
  - [x] Implement FPS monitoring during animations using Performance singleton
  - [x] Add frame rate warning system (trigger at <55fps for 3 consecutive frames)
  - [x] Implement memory usage tracking during combat
  - [x] Add performance logging for animation timing
  - [x] Create debug overlay for development builds (toggle with F12)

- [x] **Task 6: Implement Accessibility Features** (AC: AC-2.2.5)
  - [x] Add reduced motion detection from project settings
  - [x] Implement instant state update fallback when animations disabled
  - [x] Ensure all combat information visible without animations
  - [x] Add animation toggle via set_reduced_motion() method
  - [x] Test UI functionality with all animations disabled

- [x] **Task 7: Integrate with Combat Scene** (AC: AC-2.2.1, AC-2.2.2, AC-2.2.3)
  - [x] Update CombatScene.gd to use CombatAnimationController
  - [x] Connect damage/healing events to DamageNumberPopup spawning
  - [x] Wire turn indicator system to existing sprite nodes
  - [x] Integrate with existing UIProgressBar health change animations
  - [x] Ensure save/load compatibility (don't persist animation state)
  - [x] Test full combat flow with all visual enhancements

- [x] **Task 8: Create Comprehensive Testing** (All ACs)
  - [x] Create GUT unit tests for DamageNumberPopup
  - [x] Create GUT unit tests for CombatAnimationController
  - [x] Test animation timing and tween cleanup
  - [x] Test performance targets (60fps maintenance)
  - [x] Test accessibility mode (reduced motion)
  - [x] Create integration tests for combat flow with animations
  - [x] Add performance regression tests

### Review Follow-ups (AI)

- [ ] [AI-Review][Low] Monitor particle effect performance on lower-end devices during QA phase
- [ ] [AI-Review][Low] Consider exposing shake intensity as a user setting in future updates

## Dev Notes

### Learnings from Previous Story

**From Story 2-1-enhanced-health-status-bars (Status: done)**

- **UIProgressBar Component**: Robust component created with gradients, animations, and status effects - integrate DamageNumberPopup to work alongside these enhanced bars
- **Status Effect System**: StatusEffectIcon component (24x24px) with tooltips and real-time updates - reuse for any combat state indicators
- **Animation Pattern**: 300ms animations with Tween.EASE_OUT maintaining 60fps - apply same pattern to combat animations
- **Tween Cleanup**: Critical to call `tween.kill()` in completion callbacks - implement same pattern in all new animation components
- **Accessibility Pattern**: Reduced motion support with instant state updates implemented - extend to all combat animations
- **Theme Integration**: UIProgressBar theme items added to ui_theme.tres - add damage number styling to same theme file
- **Performance Monitoring**: Frame rate monitoring during animations established - reuse monitoring code in CombatAnimationController
- **GameManager Integration**: Added status effect signals and management methods - connect combat animation controller to existing signals

**Files to Reuse (DO NOT recreate)**:
- `scripts/components/UIProgressBar.gd` - Animation and accessibility patterns
- `scripts/components/StatusEffectIcon.gd` - Overlay and tooltip patterns  
- `resources/ui_theme.tres` - Theme integration approach
- `tests/godot/test_ui_progress_bar.gd` - Test structure template

**New Capabilities Available**:
- `UIProgressBar.set_value_animated()` - Coordinate damage numbers with health bar animations
- `GameManager.status_effects` signals - Connect animation controller to existing event system

**Review Follow-ups Completed in Story 2.1**:
- ✅ Combat scene integration fixed (ProgressBar nodes now use UIProgressBar)
- ✅ Theme items added to ui_theme.tres
- ✅ Test files organized in tests/godot/ directory

[Source: docs/stories/2-1-enhanced-health-status-bars.md#Dev-Agent-Record]

### Architecture Patterns and Constraints

- **Animation System**: Tween nodes with AnimationPlayer for complex sequences (ADR-003)
- **Animation Timing**: Maximum 500ms for combat animations, 200ms for immediate feedback
- **Performance Target**: Maintain 60fps, <5% performance impact from visual enhancements
- **Memory Budget**: Stay under 500MB total, 256x256 max per texture
- **Particle System**: GPUParticles2D for spell effects, limit 100 particles per effect, 300 total on screen
- **Component Architecture**: Scene-based components with inheritance following BaseUI.gd pattern
- **Signal Communication**: Use signals for loose coupling between animation controller and combat system

[Source: docs/architecture.md#Animation-System]
[Source: docs/architecture.md#Performance-Considerations]

### Technical Implementation Details

**DamageNumberPopup Implementation**:
```gdscript
class_name DamageNumberPopup extends Control
# Spawn at target position, animate with bounce then fade
# Use create_tween() with Tween.EASE_OUT_BACK for bounce effect
# Duration: 500ms bounce + 400ms fade = 900ms total lifetime
# Cleanup: queue_free() after fade completes
```

**CombatAnimationController Coordination**:
```gdscript
class_name CombatAnimationController extends Node
# Coordinates all combat animations without blocking game logic
# Uses signals to communicate animation state
# Manages particle effect spawning and pooling
# Integrates with GameManager.combat_started/ended signals
```

**Screen Shake Implementation**:
- Use camera or root node offset animation
- 5px displacement with 100ms duration
- Tween.EASE_OUT for decay
- Only apply for impactful attacks (high damage or critical hits)

**Particle Effect Strategy**:
- GPUParticles2D for performance (ADR-004)
- Pre-create particle pool for common effects
- Curved trajectory using Tween with custom interpolation
- Impact effects at target position with 200ms duration

[Source: docs/stories/tech-spec-epic-2.md#Services-and-Modules]
[Source: docs/stories/tech-spec-epic-2.md#Workflows-and-Sequencing]

### Project Structure Notes

- **New Components**: Create in `scripts/components/` with matching scenes in `scenes/components/`
- **Test Location**: Add tests to `tests/godot/` directory using GUT framework
- **Theme Resources**: Extend `resources/ui_theme.tres` with damage number styling
- **Particle Resources**: Create in `resources/animations/` or `assets/ui/particles/`

### Testing Standards

- GUT framework for unit and integration tests
- Performance assertions: maintain 60fps during all animations
- Tween cleanup verification to prevent memory leaks
- Accessibility testing: verify UI works with animations disabled
- Animation timing tests: verify durations match specifications

[Source: docs/architecture.md#Development-Environment]

### References

- [Source: docs/stories/tech-spec-epic-2.md#AC-2.2.1] - Damage and Healing Numbers acceptance criteria
- [Source: docs/stories/tech-spec-epic-2.md#AC-2.2.2] - Combat Animation Polish acceptance criteria
- [Source: docs/stories/tech-spec-epic-2.md#AC-2.2.3] - Turn Indicator Clarity acceptance criteria
- [Source: docs/epics.md#Story-2.2] - Story definition and prerequisites
- [Source: docs/architecture.md#Animation-Implementation-Pattern] - Animation best practices
- [Source: docs/architecture.md#Performance-Monitoring-Pattern] - Performance monitoring approach
- [Source: docs/stories/2-1-enhanced-health-status-bars.md#Completion-Notes-List] - Reusable patterns from previous story
- [Source: docs/PRD.md#FR-VP-005] - Combat UI Polish requirements
- [Source: docs/PRD.md#FR-VP-006] - Character Visual Improvements requirements

## Dev Agent Record

### Context Reference

- docs/stories/2-2-combat-animation-polish.context.xml

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Task 1 (DamageNumberPopup) completed and tested. Component is ready for use.
- Task 2 (CombatAnimationController) completed with full spell cast animation system.
  - Enhanced to support CanvasItem (both Control and Node2D nodes).
  - Spell cast animations with cast pose, particle projectiles, and impact effects.
  - Added spell_impact signal for coordination.
  - Implemented wait_for_animations() for non-blocking animation sequences.
- Task 3 (Particle Effect System) completed.
  - GPUParticles2D-based spell and impact particles.
  - Particle pooling with MAX_SPELL_PARTICLES (10) and MAX_IMPACT_PARTICLES (10).
  - Bezier curve trajectory for spell projectiles (500ms travel time).
  - Color-coded particles by spell type (fire=orange, ice=blue, heal=green, etc.).
- Task 4 (TurnIndicatorController) completed.
  - New component scripts/components/TurnIndicatorController.gd.
  - Glow effect (modulate > 1.0) for active character.
  - Dim effect (modulate < 1.0) for inactive characters.
  - 200ms smooth transitions between turns.
- Task 5 (PerformanceMonitor) completed.
  - New component scripts/components/PerformanceMonitor.gd.
  - FPS tracking with 55fps warning threshold after 3 consecutive frames.
  - Memory tracking with 500MB warning threshold.
  - Animation timing tracking for performance logging.
  - Debug overlay toggle with F12 (development mode).
- Task 6 (Accessibility) completed.
  - Reduced motion support throughout all animation components.
  - set_reduced_motion(bool) method propagates to all controllers.
  - Instant state updates when animations disabled.
- Task 7 (Combat Scene Integration) completed.
  - CombatScene.gd updated to create and manage all animation controllers.
  - Turn indicators switch between player/monster on combat actions.
  - Performance monitoring starts/stops with combat.
  - Save/load compatibility maintained (no animation state persisted).
- Task 8 (Testing) completed.
  - Updated test_combat_animation_controller.gd with spell, accessibility, and pool tests.
  - Created test_turn_indicator_controller.gd with full AC-2.2.3 coverage.
  - Created test_performance_monitor.gd with full AC-2.2.4 coverage.
  - Created test_combat_scene_integration.gd for integration tests.

### File List

- scripts/components/DamageNumberPopup.gd
- scenes/components/damage_number_popup.tscn
- tests/godot/test_damage_number_popup.gd
- scripts/components/CombatAnimationController.gd (enhanced)
- tests/godot/test_combat_animation_controller.gd (enhanced)
- scripts/components/TurnIndicatorController.gd (new)
- tests/godot/test_turn_indicator_controller.gd (new)
- scripts/components/PerformanceMonitor.gd (new)
- tests/godot/test_performance_monitor.gd (new)
- scripts/ui/CombatScene.gd (modified - animation integration)
- tests/godot/test_combat_scene_integration.gd (enhanced)

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-11-25 | SM Agent | Initial story draft created from tech-spec-epic-2.md and epics.md |
| 2025-11-25 | Amelia | Implemented Task 1 (DamageNumberPopup) and partial Task 2 (CombatAnimationController) |
| 2025-11-25 | Amelia | Completed Tasks 2-8: Full spell animation system with particles, turn indicators, performance monitoring, accessibility, combat scene integration, and comprehensive tests |
| 2025-11-25 | Amelia | Senior Developer Review notes appended |

## Senior Developer Review (AI)

- **Reviewer**: Amelia
- **Date**: 2025-11-25
- **Outcome**: **Approve**
  - All Acceptance Criteria fully implemented and verified.
  - Comprehensive test coverage for all new components and integration.
  - Implementation follows architecture constraints (performance, memory, accessibility).

### Summary

The implementation of Story 2.2 delivers a robust and polished combat animation system. The code is well-structured, following the component-based architecture defined in the tech spec. Separation of concerns is excellent, with distinct controllers for animations, turn indicators, and performance monitoring. The integration with `CombatScene` is clean and uses signals for loose coupling. Accessibility features (reduced motion) are consistently implemented across all visual systems.

### Key Findings

- **High Quality Component Design**: The split into `CombatAnimationController`, `TurnIndicatorController`, and `PerformanceMonitor` promotes maintainability and testability.
- **Performance Optimization**: Particle pooling and tween cleanup are correctly implemented, ensuring no memory leaks and maintaining performance targets.
- **Accessibility Integration**: The reduced motion setting is propagated correctly to all controllers, ensuring compliance with AC-2.2.5.
- **Robust Testing**: GUT tests cover unit functionality, signal emissions, and integration scenarios comprehensively.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| AC-2.2.1 | Damage and Healing Numbers | **IMPLEMENTED** | `DamageNumberPopup.gd`: Bounce/Fade tweens, Color logic, Shake effect. |
| AC-2.2.2 | Combat Animation Polish | **IMPLEMENTED** | `CombatAnimationController.gd`: Attack lunge, Particle spells (bezier), Impact effects. |
| AC-2.2.3 | Turn Indicator Clarity | **IMPLEMENTED** | `TurnIndicatorController.gd`: Glow/Dim effects, Smooth transitions (200ms). |
| AC-2.2.4 | Animation Performance | **IMPLEMENTED** | `PerformanceMonitor.gd` & `CombatAnimationController.gd`: FPS/Mem tracking, Particle pooling. |
| AC-2.2.5 | Animation Accessibility | **IMPLEMENTED** | All Controllers: `reduced_motion` checks skipping animations for instant feedback. |

**Summary:** 5 of 5 acceptance criteria fully implemented.

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| Task 1: Create DamageNumberPopup Component | [x] | **VERIFIED** | `scripts/components/DamageNumberPopup.gd` |
| Task 2: Create CombatAnimationController | [x] | **VERIFIED** | `scripts/components/CombatAnimationController.gd` |
| Task 3: Implement Particle Effect System | [x] | **VERIFIED** | `CombatAnimationController.gd` (pooling, particle creation) |
| Task 4: Implement Turn Indicator System | [x] | **VERIFIED** | `scripts/components/TurnIndicatorController.gd` |
| Task 5: Add Performance Monitoring | [x] | **VERIFIED** | `scripts/components/PerformanceMonitor.gd` |
| Task 6: Implement Accessibility Features | [x] | **VERIFIED** | Implemented across all components (`set_reduced_motion`) |
| Task 7: Integrate with Combat Scene | [x] | **VERIFIED** | `scripts/ui/CombatScene.gd` updates |
| Task 8: Create Comprehensive Testing | [x] | **VERIFIED** | `tests/godot/` files created and populated |

**Summary:** 8 of 8 completed tasks verified.

### Test Coverage and Gaps

- **Unit Tests**: Full coverage for all new components (`test_damage_number_popup.gd`, `test_combat_animation_controller.gd`, `test_turn_indicator_controller.gd`, `test_performance_monitor.gd`).
- **Integration Tests**: `test_combat_scene_integration.gd` verifies the assembly and signal flow.
- **Gaps**: None identified.

### Architectural Alignment

- **Tech Spec Compliance**: Follows the defined component structure and signal interfaces.
- **Constraints**: Adheres to performance (pooling), memory (cleanup), and accessibility constraints.
- **Patterns**: Uses established Tween and Signal patterns.

### Action Items

**Advisory Notes:**
- Note: Monitor particle effect performance on lower-end devices during QA phase.
- Note: Consider exposing shake intensity as a user setting in future updates.
