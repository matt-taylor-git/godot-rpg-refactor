# Epic Technical Specification: Combat Interface Enhancement

Date: 2025-11-19
Author: Matt
Epic ID: epic-2
Status: Draft

---

## Overview

Epic 2 focuses on transforming the combat experience in godot-rpg-refactor with modern visual polish while preserving the tactical turn-based gameplay that RPG fans love. Building on the Core UI Modernization from Epic 1, this epic delivers enhanced health and status bars, smooth combat animations, and polished character portraits that make battles more engaging and visually satisfying without compromising performance or gameplay mechanics.

This epic directly addresses functional requirements VP-005 (Combat UI Polish) and VP-006 (Character Visual Improvements) from the PRD, implementing modern styling, animations, and visual feedback systems that elevate the combat experience to match contemporary RPG standards while maintaining the nostalgic charm.

## Objectives and Scope

### In-Scope
- Modernizing health and mana bars with gradient styling and smooth animations
- Implementing visual feedback for combat actions including damage numbers and status effects
- Polishing character portraits with borders, status overlays, and highlighting
- Creating particle effects for abilities and combat actions
- Ensuring all combat UI elements meet accessibility standards (4.5:1 contrast ratio)
- Maintaining 60fps performance throughout all combat visual enhancements

### Out-of-Scope
- Changes to core combat mechanics or turn-based system logic
- New character classes, abilities, or combat features
- Sound effect design or audio implementation
- Multiplayer or networked combat functionality
- Complete combat UI redesign from scratch (building on existing combat_scene.tscn)

## System Architecture Alignment

**Architecture Components Referenced:**
- Animation System: Tween nodes for dynamic animations, AnimationPlayer for complex sequences
- Component Architecture: Scene-based components with inheritance following BaseUI.gd pattern
- Theming Strategy: Centralized ui_theme.tres for consistent styling and colors
- Performance Monitoring: Built-in Performance singleton for frame rate tracking

**Constraints Applied:**
- UI enhancements must work within existing GameManager combat system
- All components must follow Godot Control node patterns established in architecture
- Animations limited to 500ms duration maximum for responsive feel
- Memory usage must remain under 500MB (NFR from PRD)
- Component implementations must be compatible with save/load serialization

## Detailed Design

### Services and Modules

| Component | Responsibility | Owner | Inputs/Outputs |
|-----------|---------------|-------|----------------|
| UIProgressBar (Enhanced) | Modern health/mana bars with gradients and animations | Epic 2 Story 2.1 | Input: current_health, max_health, status_effects; Output: animated bar display |
| CombatAnimationController | Coordinates all combat animations and timing | Epic 2 Story 2.2 | Input: combat_action_type, damage_amount, targets; Output: animation sequence triggers |
| CharacterPortraitContainer | Character portrait display with status overlays | Epic 2 Story 2.3 | Input: character_data, is_active, status_effects; Output: rendered portrait with overlays |
| DamageNumberPopup | Floating damage/healing numbers with animations | Epic 2 Story 2.2 | Input: value, type (damage/heal), position; Output: animated popup display |
| StatusEffectIcon | Small icons representing buffs/debuffs | Epic 2 Story 2.1 | Input: effect_type, duration; Output: icon display with tooltip |

### Data Models and Contracts

#### UIProgressBar Component Schema
```gdscript
# Extends existing ProgressBar node
class_name UIProgressBar extends ProgressBar

# Enhanced properties for visual polish
@property colors:
- gradient_fill: Gradient (multiple color stops for modern look)
- background_color: Color (darker background for contrast)
- effect_tint: Color (overlays status effect colors)

@property animations:
- transition_duration: float (default: 0.3 seconds)
- animation_curve: Curve (easing for smooth transitions)

@property status:
- is_animated: bool (toggle animation on/off)
- effect_overlay: String (current status effect type)
```

#### CharacterPortraitContainer Schema
```gdscript
# Scene-based component
@onready var portrait_sprite = $PortraitSprite
@onready var health_bar = $HealthBarOverlay
@onready var status_effects = $StatusEffectsContainer
@onready var highlight_effect = $HighlightGlow

# Properties
var character_data: CharacterResource
var is_active: bool = false
var status_effect_icons: Array[StatusEffectIcon]

# Methods
func update_portrait(data: CharacterResource) -> void
func add_status_effect(effect_type: String, icon_path: String) -> void
func set_active(active: bool) -> void
```

#### CombatAnimationController Event Contract
```gdscript
# Signals for animation coordination
signal animation_started(animation_id: String)
signal animation_completed(animation_id: String)
signal damage_number_spawned(value: int, position: Vector2)

# Methods for triggering animations
func play_attack_animation(attacker_position: Vector2, target_position: Vector2) -> void
func play_spell_animation(spell_type: String, target_positions: Array[Vector2]) -> void
func animate_health_change(old_value: int, new_value: int, bar_node: UIProgressBar) -> void
```

### APIs and Interfaces

#### GameManager Combat State APIs (Existing Integration Points)
```gdscript
# Called by combat_scene.gd to update combat state
GameManager.start_combat() -> void
GameManager.end_combat(player_won: bool) -> void
GameManager.get_current_monster() -> Monster

# Health/mana updates (enhanced for visual polish)
GameManager.player_take_damage(amount: int) -> void  # Triggers damage animation
GameManager.player_heal(amount: int) -> void  # Triggers heal animation

# Combat signals (UI subscribes to these)
signal player_health_changed(new_health: int, max_health: int)
signal monster_health_changed(new_health: int, max_health: int)
signal player_turn_started()
signal monster_turn_started()
```

#### UI Component Interface (New for Epic 2)
```gdscript
# Enhanced UIProgressBar interface
func set_value_animated(new_value: float, animate: bool = true) -> void
func add_status_effect_overlay(effect_type: String) -> void
func remove_status_effect_overlay(effect_type: String) -> void

# CharacterPortraitContainer interface
func setup(character: CharacterResource) -> void
func update_health_percentage(percent: float) -> void
func show_active_indicator() -> void
func hide_active_indicator() -> void

# CombatAnimationController interface
func coordinate_attack_sequence(attacker, target, damage) -> void
func coordinate_spell_cast(caster, spell, targets) -> void
```

### Workflows and Sequencing

#### Combat Turn Sequence with Visual Enhancements

**Workflow: Player Attack with Visual Polish**

1. **Turn Start**
   - GameManager emits "player_turn_started" signal
   - Combat scene highlights active character portrait (glow effect)
   - UI buttons enable with hover effects

2. **Player Action Selection**
   - Player hovers over attack button → hover animation (0.2s scale up)
   - Player clicks attack → button press animation (0.1s scale down)
   - Combat scene shows target selection cursor

3. **Attack Animation Sequence** (Total: ~1.2 seconds)
   - Character portrait animates attack motion (0.3s sprite animation)
   - Screen shake effect for impact (0.1s, 5px displacement)
   - Damage number pops up at target position with bounce (0.5s)
   - Target's health bar animates smoothly to new value (0.3s)
   - Status effect icons update if applicable

4. **Monster Turn**
   - GameManager emits "monster_turn_started" signal
   - Active indicator switches to monster portrait
   - Monster attack sequence follows similar animation pattern

5. **Combat End**
   - Victory/defeat animations play (0.5s fade transitions)
   - UI returns to exploration with smooth scene transition

**Workflow: Spell Cast with Particle Effects**

1. **Spell Selection**
   - Player selects spell from ability bar (hover animations on ability icons)
   - Mana cost displayed with color coding (sufficient: blue, insufficient: red)

2. **Cast Animation** (Total: ~1.5 seconds)
   - Caster character glows with charging effect (0.3s buildup)
   - Particle system spawns at caster position (GPUParticles2D)
   - Particles travel to target(s) following curved path (0.5s)
   - Impact effect at target position (explosion particles, screen flash)
   - Damage/healing numbers pop up with scale and fade
   - Health bars animate to reflect spell effect

3. **Cooldown Visualization**
   - Spell icon shows cooldown overlay (grayed out + timer)
   - Cooldown overlay animates with radial wipe effect
   - Icon returns to normal when cooldown completes

## Non-Functional Requirements

### Performance

**NFR-PERF-001: Frame Rate Maintenance**
- **Target:** Maintain 60fps during all combat animations
- **Constraint:** Visual enhancements limited to <5% performance impact
- **Measurement:** Godot Performance singleton monitoring
- **Implementation:** GPU-accelerated particles, optimized tweens, texture atlasing

**NFR-PERF-002: Animation Timing**
- **Target:** All combat animations complete within 500ms
- **Smooth Transitions:** Health bar animations use 300ms duration with easing
- **Particle Limits:** Maximum 100 particles per effect, 300 total on screen
- **Memory:** Animation resources cached, particle systems pooled and reused

**NFR-PERF-003: Memory Budget**
- **Total Memory:** Stay under 500MB during combat scenes
- **Texture Memory:** UI textures compressed with ETC2, max 256x256 per texture
- **Particle Memory:** GPU particles reuse buffers, CPU particles limited to critical effects only

### Security

**NFR-SEC-001: Save File Integrity**
- **Requirement:** Visual UI state doesn't corrupt save files
- **Implementation:** Save only game state, not UI animation states
- **Validation:** Save files validated before loading, graceful degradation if load fails

**NFR-SEC-002: Asset Integrity**
- **Requirement:** UI assets loaded from trusted sources only
- **Implementation:** All assets in res:// project directory, no external loading
- **Validation:** Texture loading wrapped in error handlers

### Reliability/Availability

**NFR-REL-001: Animation Reliability**
- **Requirement:** Animations complete successfully or fail gracefully
- **Implementation:** try-catch blocks around all animation code, fallback to instant state updates
- **Error Recovery:** Failed animations log error but don't crash game, UI shows current state

**NFR-REL-002: State Consistency**
- **Requirement:** Visual state matches game logic state
- **Implementation:** Animation completion callbacks update UI, GameManager signals validate state
- **Consistency Check:** Health bars, status effects, active indicators sync with GameManager

**NFR-REL-003: Accessibility Degradation**
- **Requirement:** UI remains functional if animations disabled
- **Implementation:** Toggle for reduced motion, instant state updates when animations off
- **Accessibility:** All information available without animations

### Observability

**NFR-OBS-001: Performance Monitoring**
- **Logging:** FPS logged every frame, memory usage logged every second
- **Alerts:** Console warning if FPS drops below 55 for 3 consecutive frames
- **Metrics:** Frame time, draw calls, particle count, texture memory tracked

**NFR-OBS-002: Animation Debugging**
- **Development Mode:** Debug overlay showing active animations, particle counts
- **Logging:** Animation start/complete logged with timing information
- **Profiling:** Animation performance impact measured per animation type

**NFR-OBS-003: Error Tracking**
- **Errors:** All animation/texture load errors logged with stack traces
- **Warnings:** Performance warnings logged (excessive particles, long animations)
- **Debug Info:** Component state dumps available on error

## Dependencies and Integrations

### Internal Dependencies

```json
{
  "dependencies": [
    {
      "component": "Epic 1 - Core UI Modernization",
      "required_by": ["Story 2.1", "Story 2.2", "Story 2.3"],
      "reason": "Requires modern button system, typography, color scheme, and visual feedback system"
    },
    {
      "component": "GameManager.gd",
      "required_by": ["All stories"],
      "reason": "Integration with existing combat system and state management"
    },
    {
      "component": "combat_scene.tscn",
      "required_by": ["All stories"],
      "reason": "Enhancing existing combat UI, not rebuilding from scratch"
    },
    {
      "component": "ui_theme.tres",
      "required_by": ["All stories"],
      "reason": "Centralized theming for consistent styling"
    }
  ]
}
```

### External Dependencies

```json
{
  "dependencies": [
    {
      "name": "Godot 4.5 Engine",
      "version": "4.5+",
      "purpose": "Tween animations, GPUParticles2D, UI Control nodes, Performance monitoring"
    }
  ],
  "assets": [
    {
      "name": "UI Status Effect Icons",
      "type": "Texture2D",
      "specs": "24x24px PNG, optimized for small size",
      "quantity": 10 (poison, burn, freeze, buff, debuff, etc.)
    },
    {
      "name": "Particle Effect Textures",
      "type": "Texture2D",
      "specs": "64x64px PNG with alpha channel",
      "quantity": 5 (sparkle, explosion, smoke, glow, magic)
    }
  ]
}
```

### Integration Points

| Integration | Description | Contract/API |
|-------------|-------------|--------------|
| GameManager Combat Signals | UI subscribes to combat state changes | `signal player_health_changed()`<br>`signal monster_health_changed()`<br>`signal combat_started/ended()` |
| Combat Scene Coordination | Combat scene instantiates and manages UI components | `func _on_player_turn_started()`<br>`func _animate_attack()` |
| Theme System | All UI components use centralized theme | `Theme ui_theme.tres` with color/font constants |
| Resource Loader | Loading particle textures and effect sprites | `ResourceLoader.load_threaded_request()` |

## Acceptance Criteria (Authoritative)

### AC-2.1.1: Health and Mana Bar Modernization
**Given** a character is in combat with health/mana values
**When** I view the combat screen
**Then** bars display with gradient fills (not solid colors)
**And** transitions between values are smooth (300ms with easing)
**And** bars change color based on percentage (green 100-50%, yellow 50-25%, red 25-0%)
**And** current/maximum values are clearly displayed as text
**And** the implementation meets WCAG AA contrast standards (4.5:1 minimum)

### AC-2.1.2: Status Effect Visualization
**Given** a character has active status effects (poison, buff, etc.)
**When** I view their health bar
**Then** status effects appear as small overlay icons (24x24px)
**And** health bar tint changes appropriately (green tint for poison, gold glow for buff)
**And** hovering over status icon shows tooltip with effect name and duration
**And** effects update in real-time as they are applied/removed

### AC-2.2.1: Damage and Healing Numbers
**Given** combat damage or healing occurs
**When** the value changes
**Then** a number pops up at the target position with bounce animation (500ms total)
**And** damage numbers are red with shake effect, healing numbers are green with pulse
**And** critical hits show larger numbers with additional effect (screen flash)
**And** numbers fade out smoothly over 400ms

### AC-2.2.2: Combat Animation Polish
**Given** a character performs a combat action (attack or spell)
**When** the action executes
**Then** character sprite shows appropriate animation (attack motion or cast pose, 300ms)
**And** screen shake occurs for impactful attacks (5px displacement, 100ms)
**And** spell casts show particle effects traveling to target (500ms duration)
**And** all animations complete without dropping below 60fps
**And** animations enhance gameplay without delaying turn resolution

### AC-2.2.3: Turn Indicator Clarity
**Given** combat is in progress
**When** a character's turn begins
**Then** their portrait highlights with subtle glow effect
**And** non-active portraits dim slightly for contrast
**And** the active indicator is clearly visible at all screen sizes
**And** transition between active characters is smooth (200ms)

### AC-2.3.1: Character Portrait Modernization
**Given** characters are displayed in combat
**When** I view the combat interface
**Then** portraits have modern borders with drop shadows
**And** health percentage is displayed as small bar overlay on portrait
**And** status effect icons appear on portrait (bottom corner stacking)
**And** active character portrait has subtle glow/pulse effect
**And** portraits scale consistently to 120x120px

### AC-2.3.2: Portrait Information Hierarchy
**Given** I need to quickly assess combat state
**When** I glance at character portraits
**Then** I can immediately identify: character identity, current health %, active status effects, whose turn it is
**And** the visual hierarchy guides my attention appropriately
**And** critical information (low health, dangerous effects) is emphasized

### AC-2.4.1: Accessibility Compliance
**Given** I have visual impairments or use assistive technology
**When** I interact with combat UI
**Then** all text meets 4.5:1 contrast ratio minimum
**And** color is not the only indicator of status (icons + text, not just color)
**And** animations can be disabled via settings (reduced motion option)
**And** UI remains fully functional with animations turned off
**And** focus indicators are visible for keyboard navigation

### AC-2.5.1: Performance Requirements
**Given** combat animations are playing
**When** I monitor game performance
**Then** frame rate maintains 60fps throughout
**And** frame drops below 55fps trigger a warning (development mode)
**And** memory usage stays under 500MB
**And** animations don't delay game logic or turn resolution

## Traceability Mapping

| Acceptance Criterion | PRD Reference | Component/API | Test Coverage |
|---------------------|---------------|---------------|---------------|
| AC-2.1.1 | FR-VP-005 | UIProgressBar.set_value_animated() | Unit: tween verification + animation timing |
| AC-2.1.2 | FR-VP-005 | UIProgressBar.add_status_effect_overlay() | Unit: status effect display + tooltip |
| AC-2.2.1 | FR-VP-005 | DamageNumberPopup.animate() | Unit: animation completion + timing |
| AC-2.2.2 | FR-VP-006 | CombatAnimationController.coordinate_attack_sequence() | Integration: end-to-end animation flow |
| AC-2.2.3 | FR-VP-005 | CharacterPortraitContainer.set_active() | Unit: visual state changes |
| AC-2.3.1 | FR-VP-006 | CharacterPortraitContainer.setup() | Unit: portrait rendering + overlays |
| AC-2.3.2 | FR-VP-006 | Full combat UI assembly | Integration: visual hierarchy validation |
| AC-2.4.1 | NFR-ACC-001, NFR-ACC-002 | Theme settings + reduced motion toggle | Manual: accessibility testing |
| AC-2.5.1 | NFR-PERF-001, NFR-PERF-002 | Performance monitoring + animation systems | Integration: performance regression tests |

**PRD to Epic Coverage:**
- ✅ FR-VP-005: Combat UI Polish → Fully covered by AC-2.1.x, AC-2.2.x, AC-2.2.3
- ✅ FR-VP-006: Character Visual Improvements → Fully covered by AC-2.3.x
- ✅ NFR-PERF-001, NFR-PERF-002: Performance → Covered by AC-2.5.1
- ✅ NFR-ACC-001, NFR-ACC-002: Accessibility → Covered by AC-2.4.1

## Risks, Assumptions, Open Questions

### Risks

**RISK-001: Performance Impact on Mobile**
- **Risk:** GPU particles and multiple concurrent tweens may impact mobile performance
- **Severity:** Medium
- **Mitigation:** Limit particle counts, use simplified effects on mobile builds, implement quality settings
- **Action:** Add performance testing on target mobile devices in Story 5.1

**RISK-002: Animation Desync from Game Logic**
- **Risk:** Visual animations may not perfectly sync with underlying combat state
- **Severity:** Medium
- **Mitigation:** Use callback signals to ensure state updates happen after animations complete<br>Validate health bar values match GameManager after each animation
- **Action:** Implement validation checks in CombatAnimationController

**RISK-003: Accessibility vs Visual Polish Conflict**
- **Risk:** Heavy visual effects may reduce accessibility compliance
- **Severity:** Low
- **Mitigation:** Always maintain 4.5:1 contrast, offer reduced motion option, never rely only on color
- **Action:** Manual accessibility testing at end of each story

**RISK-004: Particle Effect Performance**
- **Risk:** GPUParticles2D may cause frame drops with many concurrent effects
- **Severity:** Medium
- **Mitigation:** Pool particle systems, limit concurrent effects, use simpler CPU particles when possible
- **Action:** Performance testing in Story 5.2

### Assumptions

**ASSUMPTION-001: Epic 1 Completion**
- **Assumption:** Core UI Modernization (Epic 1) will be complete before Epic 2 implementation
- **Validation:** Sprint planning ensures proper sequencing
- **If False:** Delay Epic 2 until Epic 1 complete, or implement minimum required Epic 1 features

**ASSUMPTION-002: Existing Combat System Stability**
- **Assumption:** GameManager combat system is stable and won't undergo major refactoring
- **Validation:** Architecture document confirms stable API
- **If False:** Requires architecture review and epic story updates

**ASSUMPTION-003: Asset Availability**
- **Assumption:** Status effect icons and particle textures will be available or created
- **Validation:** Asset requirements listed in Dependencies section<br>Artist requested to create needed assets
- **If False:** Use placeholder icons, defer story implementation

**ASSUMPTION-004: Save/Load Compatibility**
- **Assumption:** Visual polish features don't require changes to save file format
- **Validation:** UI state not persisted, game state remains unchanged
- **If False:** Consult Architecture workflow for data model updates

### Open Questions

**QUESTION-001: Mobile Platform Support**
- **Question:** Do we need to support mobile platforms with these visual enhancements?
- **Impact:** Affects performance budgets, particle limits, touch input handling
- **Answer Needed From:** Product owner (Matt)
- **Action:** Document decision in architecture decisions

**QUESTION-002: Animation Speed Preferences**
- **Question:** Should players be able to adjust animation speed in settings?
- **Impact:** Adds complexity to animation system, requires additional UI settings
- **Answer Needed From:** UX designer or Product owner
- **Action:** If yes, add settings menu story to Epic 3

**QUESTION-003: Advanced Visual Effects**
- **Question:** Should we implement screen shake, flash effects, or other advanced VFX?
- **Impact:** May require additional asset creation, performance testing
- **Answer Needed From:** Visual design team
- **Action:** Decide scope within Story 2.2 (currently includes shake and flash)

**QUESTION-004: Critical Hit Frequency**
- **Question:** How often should critical hits occur to balance visual impact vs performance?
- **Impact:** Affects how often large special effects play
- **Answer Needed From:** Game designer
- **Action:** Current assumption: 5-10% critical hit rate (adjust based on design)

## Test Strategy Summary

### Test Levels

**Unit Tests (GUT Framework)**
- UIProgressBar: Tween verification, animation timing, gradient rendering
- DamageNumberPopup: Animation completion, positioning, text styling
- CharacterPortraitContainer: Overlay positioning, status effect management
- CombatAnimationController: Sequence coordination, callback triggering

**Integration Tests**
- End-to-end combat turn flow with all animations
- Health bar sync with GameManager state changes
- Performance during complex multi-target spell effects
- Theme changes affecting all combat UI components

**Manual Testing**
- Visual inspection of all animations across screens (1080p, 4K)
- Accessibility testing with screen readers and keyboard navigation
- Mobile device testing (if mobile support confirmed)
- User acceptance testing for animation timing and feel

### Test Coverage Goals

| Component | Unit Test Coverage | Integration Test Coverage | Manual Validation |
|-----------|-------------------|---------------------------|-------------------|
| UIProgressBar | 90%+ (all public methods) | Yes (GameManager integration) | Yes (visual inspection) |
| DamageNumberPopup | 90%+ (animation paths) | Yes (end-to-end combat) | Yes (timing feel) |
| CharacterPortraitContainer | 85%+ (overlay logic) | Yes (multiple portraits) | Yes (visual hierarchy) |
| CombatAnimationController | 80%+ (sequence logic) | Yes (complex scenarios) | Yes (performance) |

### Test Environments

- **Development:** Full debug mode with performance overlay visible
- **QA:** Release builds with performance assertions enabled
- **Target Platforms:** Windows 10/11, macOS (Apple Silicon), Linux (Ubuntu)
- **Performance Testing:** Target devices + minimum spec hardware

### Success Criteria

- All unit tests pass (90%+ coverage threshold)
- Integration tests maintain 60fps throughout
- Manual test passes with no critical visual bugs
- Accessibility testing: WCAG AA compliance verified
- Performance testing: <5% frame drops, <500MB memory usage

---

_This technical specification provides comprehensive guidance for implementing Epic 2: Combat Interface Enhancement, ensuring modern visual polish while maintaining gameplay integrity and performance standards._

_Updated as of: 2025-11-19_
