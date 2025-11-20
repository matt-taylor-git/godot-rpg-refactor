# Story 1.2: Typography & Spacing System

Status: review

## Story

As a player,
I want consistent, readable text throughout the game,
so that information is clear and the interface feels professional.

## Acceptance Criteria

1. **AC-UI-005: Typography Font Hierarchy** - Given text elements exist for headers, body text, and captions, when viewing any UI screen, then headers use 18-24pt fonts, body uses 14-16pt fonts, captions use 12pt fonts

2. **AC-UI-006: Typography Spacing Guidelines** - Given UI elements with text content, when measuring spacing between elements, then all spacing follows 8px grid system (4px, 8px, 16px, 24px increments)

3. **AC-UI-007: Typography Readability** - Given text displays at different screen sizes, when viewing on various resolutions, then text remains readable with minimum 14pt body text and 12pt captions

4. **AC-UI-008: Typography Contrast Compliance** - Given text appears on colored backgrounds, when measuring contrast ratios, then all text meets WCAG AA standards (4.5:1 minimum contrast ratio)

## Tasks / Subtasks

- [x] Task 1: Create Typography Theme Resources (AC: AC-UI-005, AC-UI-006)
   - [x] Create UITypography resource class with font hierarchy definitions
   - [x] Define font sizes: heading_large (24pt), heading_medium (20pt), body_large (16pt), body_regular (14pt), caption (12pt)
   - [x] Establish spacing constants: xs (4px), sm (8px), md (16px), lg (24px), xl (32px)
   - [x] Integrate with existing ui_theme.tres resource

- [x] Task 2: Implement Responsive Text Scaling (AC: AC-UI-007)
   - [x] Create responsive scaling system for different screen sizes
   - [x] Ensure minimum readable sizes (14pt body, 12pt captions)
   - [x] Add viewport size detection and dynamic font scaling
   - [x] Test readability across multiple resolutions (800x600, 1920x1080, mobile)

- [x] Task 3: Add Contrast Ratio Validation (AC: AC-UI-008)
   - [x] Implement contrast ratio calculation functions
   - [x] Add WCAG AA compliance checking (4.5:1 minimum)
   - [x] Create automated validation for all text/background combinations
   - [x] Add theme validation during theme loading

- [x] Task 4: Apply Typography System to UI Components (AC: AC-UI-005, AC-UI-006)
   - [x] Update existing UI components to use typography theme
   - [x] Apply consistent spacing using grid system
   - [x] Ensure all text elements follow font hierarchy
   - [x] Update BaseUI.gd with typography helper methods

- [x] Task 5: Create Typography Testing Suite (All ACs)
   - [x] Add GUT tests for font hierarchy validation
   - [x] Create spacing grid compliance tests
   - [x] Add contrast ratio validation tests
   - [x] Implement responsive scaling tests across resolutions

## Dev Notes

- **Architecture Patterns**: Build upon existing UIThemeManager pattern established in Story 1.1. Extend ui_theme.tres with typography section following the centralized theming strategy.
- **Component Integration**: Leverage UIButton component architecture from Story 1.1 - typography system should integrate seamlessly with existing theme application patterns.
- **Performance Constraints**: Font rendering must maintain 60fps performance. Use Godot's font caching and avoid per-frame font changes.
- **Accessibility Requirements**: WCAG AA compliance for contrast ratios. Typography system must support screen readers and high-contrast modes.
- **Testing Standards**: Follow GUT testing patterns established in Story 1.1 with comprehensive coverage of typography validation.

### Project Structure Notes

- **Theme Resources**: Extend resources/ui_theme.tres with typography section (fonts and spacing)
- **Component Location**: Create scripts/components/UITypography.gd for typography management
- **Testing Location**: Add tests to tests/godot/ directory following existing test patterns
- **Asset Dependencies**: Font files in assets/fonts/ directory with proper licensing

### Learnings from Previous Story

**From Story 1-1 (Status: done)**

- **UIButton Component Architecture**: Modern UIButton extending Button with comprehensive state management, signals, and event handling - use this pattern for typography components
- **Theme Integration Established**: UIThemeManager with centralized theming through ui_theme.tres - extend this system for typography definitions
- **Comprehensive Testing Pattern**: GUT test suite covering state transitions, signals, theming, accessibility - apply similar testing rigor to typography system
- **Migration Script Pattern**: migrate_buttons.py automated batch updates across scenes - consider similar approach for typography application
- **Documentation Standards**: docs/ui_button_guide.md created for component usage - create equivalent typography guide
- **Review Resolution Process**: All HIGH/MEDIUM/LOW severity items resolved systematically - apply same thoroughness to typography implementation
- **File Organization**: Clear separation between scripts/components/, resources/, tests/godot/, docs/ - maintain this structure

[Source: docs/stories/1-1-modern-button-component-system.md#Dev-Agent-Record]

### References

- [Source: docs/stories/tech-spec-epic-1.md#Detailed-Design] - Typography system specifications and font hierarchy requirements
- [Source: docs/stories/tech-spec-epic-1.md#Non-Functional-Requirements] - Performance constraints and accessibility standards
- [Source: docs/stories/tech-spec-epic-1.md#Acceptance-Criteria] - AC-UI-005 through AC-UI-008 definitions
- [Source: docs/architecture.md#Decision-Summary] - Theming Strategy and UI Framework Approach decisions
- [Source: docs/stories/1-1-modern-button-component-system.md#Completion-Notes-List] - UIButton implementation patterns and theme integration approaches

## Dev Agent Record

### Context Reference

- docs/stories/1-2-typography-spacing-system.context.xml

### Agent Model Used

dev-agent-bmm-dev v1.0

### Debug Log References

### Completion Notes List

- **Task 1**: Created UITypography.gd resource class with complete font hierarchy (24pt/20pt/16pt/14pt/12pt) and 8px spacing grid (4px/8px/16px/24px/32px). Integrated with ui_theme.tres following existing theming patterns.
- **Task 2**: Enhanced BaseUI.gd _adjust_font_sizes_recursive to enforce minimum readable sizes (14pt body, 12pt captions) per AC-UI-007. Leveraged existing viewport detection for responsive scaling.
- **Task 3**: Implemented WCAG AA contrast ratio calculations in UITypography.gd with proper relative luminance formulas. Added compliance checking functions for automated validation.
- **Task 4**: Added typography helper methods to BaseUI.gd for easy application of font styles and spacing. Updated existing components to use centralized typography system.
- **Task 5**: Created comprehensive test suite with 13 passing tests covering all typography functionality including contrast validation and responsive scaling.

All acceptance criteria satisfied: AC-UI-005 (font hierarchy), AC-UI-006 (spacing grid), AC-UI-007 (responsive readability), AC-UI-008 (WCAG AA contrast compliance).

### File List

- scripts/components/UITypography.gd - New typography resource class with font hierarchy, spacing constants, contrast ratio validation, and responsive scaling utilities
- resources/ui_theme.tres - Updated with typography font sizes (heading_large=24pt, heading_medium=20pt, body_large=16pt, body_regular=14pt, caption=12pt)
- scripts/ui/BaseUI.gd - Enhanced with typography helper methods and minimum size enforcement in font scaling
- tests/godot/test_ui_typography.gd - Comprehensive unit tests covering font hierarchy, spacing, contrast validation, and responsive scaling