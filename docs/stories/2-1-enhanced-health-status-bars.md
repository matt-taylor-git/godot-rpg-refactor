# Story 2.1: Enhanced Health & Status Bars

Status: ready-for-dev

## Story

As a player in combat,
I want modern, informative health and mana bars,
so that I can quickly assess character status during battles.

## Acceptance Criteria

1. **AC-2.1.1: Health and Mana Bar Modernization** - Given a character is in combat with health/mana values, when I view the combat screen, then bars display with gradient fills (not solid colors), and transitions between values are smooth (300ms with easing), and bars change color based on percentage (green 100-50%, yellow 50-25%, red 25-0%), and current/maximum values are clearly displayed as text, and the implementation meets WCAG AA contrast standards (4.5:1 minimum)

2. **AC-2.1.2: Status Effect Visualization** - Given a character has active status effects (poison, buff, etc.), when I view their health bar, then status effects appear as small overlay icons (24x24px), and health bar tint changes appropriately (green tint for poison, gold glow for buff), and hovering over status icon shows tooltip with effect name and duration, and effects update in real-time as they are applied/removed

3. **AC-2.1.3: Bar Animation Performance** - Given health or mana values change during combat, when the values animate, then the animation completes within 300ms, and the animation maintains 60fps performance, and the tween properly cleans up after completion to prevent memory leaks

4. **AC-2.1.4: Accessibility Compliance** - Given I have visual impairments or use assistive technology, when I view health/mana bars, then all text meets 4.5:1 contrast ratio minimum, and color is not the only indicator of status (icons + text, not just color), and the reduced motion setting (if enabled) disables animations, and UI remains fully functional with animations turned off

5. **AC-2.1.5: Responsive Scaling** - Given the game runs at different resolutions, when I view health/mana bars at various screen sizes, then bars scale appropriately maintaining readability, and text remains legible at all resolutions, and bar dimensions adjust based on screen size, and mobile touch targets meet minimum 44px requirement

## Tasks / Subtasks

- [ ] **Task 1: Create UIProgressBar Component Class** (AC: AC-2.1.1, AC-2.1.3, AC-2.1.5)
  - [ ] Create UIProgressBar.gd script extending ProgressBar node
  - [ ] Add gradient fill properties with multiple color stops
  - [ ] Implement smooth value transitions using Tween (300ms duration, Tween.EASE_OUT)
  - [ ] Add color change logic based on percentage thresholds (green/yellow/red)
  - [ ] Implement current/maximum value text display
  - [ ] Add responsive scaling support for different resolutions
  - [ ] Integrate with existing theme system (ui_theme.tres)

- [ ] **Task 2: Implement Status Effect Overlay System** (AC: AC-2.1.2)
  - [ ] Create StatusEffectIcon component (24x24px)
  - [ ] Add status effect overlay properties to UIProgressBar
  - [ ] Implement tint/glow effects for different status types
  - [ ] Create tooltip system for status effect information
  - [ ] Add real-time effect application/removal handling
  - [ ] Integrate with GameManager for effect state synchronization

- [ ] **Task 3: Add Color-Coded Status Indicators** (AC: AC-2.1.1)
  - [ ] Define color thresholds (green: 100-50%, yellow: 50-25%, red: 25-0%)
  - [ ] Implement dynamic gradient color changes
  - [ ] Add smooth color transition animations
  - [ ] Ensure WCAG AA contrast compliance for all color states
  - [ ] Test colorblind-friendly alternatives

- [ ] **Task 4: Implement Accessibility Features** (AC: AC-2.1.4)
  - [ ] Ensure 4.5:1 contrast ratio for all text elements
  - [ ] Add text labels in addition to color coding
  - [ ] Integrate with reduced motion settings
  - [ ] Add screen reader support for status information
  - [ ] Implement keyboard navigation for status effect tooltips

- [ ] **Task 5: Create Theme Integration** (AC: AC-2.1.1, AC-2.1.5)
  - [ ] Define theme constants for bar styling (gradient stops, colors, fonts)
  - [ ] Add theme properties to ui_theme.tres
  - [ ] Implement theme override capability for special cases
  - [ ] Ensure consistent application across combat UI
  - [ ] Validate theme changes apply immediately

- [ ] **Task 6: Add Animation Performance Optimization** (AC: AC-2.1.3)
  - [ ] Implement Tween cleanup in completion callbacks (tween.kill())
  - [ ] Add frame rate monitoring during animations
  - [ ] Optimize gradient rendering for 60fps performance
  - [ ] Implement animation batching for multiple simultaneous changes
  - [ ] Add performance assertions in tests

- [ ] **Task 7: Create Comprehensive Testing** (All ACs)
  - [ ] Create GUT unit tests for UIProgressBar component
  - [ ] Test gradient rendering and color transitions
  - [ ] Add tests for status effect overlay system
  - [ ] Test animation timing and tween cleanup
  - [ ] Create accessibility compliance tests
  - [ ] Add performance tests maintaining 60fps
  - [ ] Test responsive scaling at different resolutions

- [ ] **Task 8: Integrate with Combat Scene** (AC: AC-2.1.1, AC-2.1.2)
  - [ ] Replace existing ProgressBar nodes with UIProgressBar in combat_scene.tscn
  - [ ] Connect UIProgressBar to GameManager health change signals
  - [ ] Update combat_scene.gd to use new component interfaces
  - [ ] Test combat flow with all visual enhancements
  - [ ] Validate save/load compatibility

## Dev Notes

### Learnings from Previous Story (Story 1.1 - Modern Button Component System)

**From Story 1.1 (Status: done)**

- **New Service Created**: UIButton component extending Button with comprehensive state management - pattern can be adapted for UIProgressBar
- **Architectural Pattern**: Component-based architecture with theme integration is working well - UIProgressBar should follow the same pattern
- **Animation System**: Tween-based animations with 200ms duration established - UIProgressBar should use 300ms for smoother health transitions
- **Accessibility Pattern**: WCAG AA compliance with 3:1 contrast ratios implemented - extend to 4.5:1 for health bar text as required
- **Theme Integration**: Centralized theming through ui_theme.tres is functional - add UIProgressBar-specific theme items
- **Testing Pattern**: GUT test suite structure established - follow same patterns for UIProgressBar tests
- **Performance Considerations**: Tween cleanup with tween.kill() is critical to prevent memory leaks - ensure UIProgressBar implements same pattern
- **Type Safety**: Extending the correct Godot node type (Button vs Control) is important - UIProgressBar should extend ProgressBar for proper inheritance

[Source: docs/stories/1-1-modern-button-component-system.md#Dev-Agent-Record]

### Architecture Patterns and Constraints

- **UI Framework**: Godot Control Nodes with Custom Themes - UIProgressBar extends ProgressBar node
- **Theming Strategy**: Centralized ui_theme.tres with theme constants for colors, gradients, and fonts
- **Animation System**: Tween nodes with 300ms duration for health bar animations (slightly longer than button 200ms for smooth health transitions)
- **Component Architecture**: Scene-based components following UIButton pattern from Story 1.1
- **Performance Monitoring**: Performance singleton for frame rate tracking during animations
- **Accessibility**: WCAG AA compliance (4.5:1 contrast for text, 3:1 for UI elements)

[Source: docs/architecture.md#Decision-Summary]

### Reuse from Previous Story

**Components to Reuse** (DO NOT recreate):
- Animation system pattern from UIButton (Tween with cleanup)
- Theme integration approach from UIButton (ui_theme.tres integration)
- Accessibility compliance patterns (contrast ratios, keyboard navigation)
- Testing patterns from test_ui_button.gd (GUT framework structure)
- Signal emission patterns for state changes

**Files to Reference**:
- `scripts/components/UIButton.gd` - Component architecture pattern
- `ui_theme.tres` - Theme integration example
- `tests/godot/test_ui_button.gd` - Test structure template

### Project Structure Notes

- **Component Location**: Create `scripts/components/UIProgressBar.gd` following UIButton pattern
- **Theme Resources**: Extend `resources/ui_theme.tres` with progress bar theme items
- **Testing Location**: Add tests to `tests/godot/` directory using GUT framework
- **Asset Dependencies**: Status effect icons in `assets/ui/icons/` directory

### Technical Implementation Details

**ProgressBar Extension Pattern**:
```gdscript
class_name UIProgressBar extends ProgressBar
# Enhance existing ProgressBar with gradient fills, animations, status effects
```

**Gradient Implementation**:
- Use Godot's Gradient resource for multi-color bar fills
- Support horizontal and vertical gradient orientations
- Dynamic gradient colors based on health percentage

**Status Effect System**:
- StatusEffectIcon as separate component (24x24px Control nodes)
- Effect overlay with color tinting (modulate property)
- Tooltips with effect name and duration

**Animation Parameters**:
- Duration: 300ms (longer than UIButton's 200ms for health transitions)
- Easing: Tween.EASE_OUT
- Always call tween.kill() in completion callback

**Performance Targets**:
- Maintain 60fps during all combat animations
- <5% frame rate impact from visual enhancements
- Memory usage <500MB

[Source: docs/stories/tech-spec-epic-2.md#Services-and-Modules]

### References

- [Source: docs/stories/tech-spec-epic-2.md#UIProgressBar-Component-Schema] - UIProgressBar interface specification
- [Source: docs/stories/tech-spec-epic-2.md#Acceptance-Criteria] - AC-2.1.1 and AC-2.1.2 definitions
- [Source: docs/architecture.md#Epic-to-Architecture-Mapping] - Epic 2 component architecture
- [Source: docs/stories/tech-spec-epic-2.md#Non-Functional-Requirements] - Performance and accessibility requirements (NFR-PERF-001, NFR-ACC-001, NFR-ACC-002)
- [Source: docs/stories/1-1-modern-button-component-system.md#Completion-Notes-List] - Reusable patterns and services from previous story

## Dev Agent Record

### Context Reference

- docs/stories/2-1-enhanced-health-status-bars.context.xml (will be created by story-context workflow)

### Agent Model Used

sm-agent-bmm-sm v1.0 (for story drafting)

### Debug Log References

### Completion Notes List

### File List

