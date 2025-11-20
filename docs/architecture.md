# Architecture

## Executive Summary

This architecture document guides the visual polish enhancement of godot-rpg-refactor, a turn-based RPG game built with Godot 4.5. The project focuses on modernizing the user interface while preserving the nostalgic RPG charm, ensuring all visual improvements maintain 60fps performance and meet accessibility standards.

## Project Initialization

This is a brownfield enhancement project. The existing Godot 4.5 codebase with established architecture (scene-based UI, autoload managers, GDScript) will be enhanced with visual polish features. No starter template is needed as the foundation already exists.

## Decision Summary

| Category | Decision | Version | Affects Epics | Rationale |
| -------- | -------- | ------- | ------------- | --------- |

UI Framework Approach | Godot Control Nodes with Custom Themes | Godot 4.5 | Epic 1,2,3,4 | Modern UI components using Godot's native Control system with custom theme resources for consistent styling
Theming Strategy | Centralized Theme Resources | Godot 4.5 | Epic 1,2,3,4 | Single theme file managing all UI styling, colors, fonts, and spacing for consistency
Animation System | Tween Nodes with AnimationPlayer | Godot 4.5 | Epic 1,2,3 | Tween for dynamic animations, AnimationPlayer for predefined sequences, ensuring smooth 60fps performance
Asset Management | TextureAtlas with Compression | Godot 4.5 | Epic 5 | Combine UI sprites into atlases, use ETC2 compression for mobile compatibility, lazy loading for performance
Performance Monitoring | Built-in Profiler + Custom FPS Display | Godot 4.5 | Epic 5 | Godot's Performance singleton for metrics, custom debug overlay for real-time monitoring
Component Architecture | Scene-based Components with Inheritance | Godot 4.5 | Epic 1,2,3,4 | Reusable UI components as scenes with script inheritance, following existing BaseUI.gd pattern

## Project Structure

```
godot-rpg-refactor/
├── scripts/
│   ├── components/          # Enhanced UI components (UIButton, UIProgressBar)
│   ├── ui/                  # Updated UI scene controllers
│   └── utils/               # UI utilities and factories
├── scenes/
│   ├── components/          # Reusable UI component scenes
│   └── ui/                  # Main UI screens (enhanced)
├── resources/
│   ├── themes/             # UI theme resources (.tres files)
│   ├── animations/         # UI animation resources (.tres files)
│   └── ui_theme.tres       # Main UI theme (enhanced)
├── assets/
│   ├── ui/                 # UI-specific assets
│   │   ├── buttons/        # Button sprites and textures
│   │   ├── backgrounds/    # UI background images
│   │   └── icons/          # UI icons and symbols
│   └── fonts/              # UI fonts (enhanced set)
└── tests/
    └── godot/
        ├── test_ui_*       # UI component tests
```

## Epic to Architecture Mapping

| Epic | Architectural Components | Key Decisions |
|------|------------------------|---------------|
| Epic 1: Core UI Modernization | UIButton.gd, UIProgressBar.gd, ui_theme.tres | UI Framework Approach, Theming Strategy, Component Architecture |
| Epic 2: Combat Interface Enhancement | Combat scene controllers, health bar components, animation resources | Animation System, Component Architecture, Theming Strategy |
| Epic 3: Menu System Redesign | Main menu, character creation, settings scenes | UI Framework Approach, Theming Strategy, Component Architecture |
| Epic 4: Inventory & Equipment Visuals | Inventory scene, equipment comparison components | Component Architecture, Animation System, Theming Strategy |
| Epic 5: Performance Optimization & Polish | Performance monitoring utilities, asset optimization | Asset Management, Performance Monitoring, Animation System |

## Technology Stack Details

### Core Technologies

**Game Engine:** Godot 4.5 - Scene-based architecture, GDScript, autoload managers
**Scripting:** GDScript - Primary language for UI logic and game systems
**UI Framework:** Godot Control Nodes - Native UI components with custom theming
**Animation:** Tween + AnimationPlayer - Dynamic and predefined animations
**Assets:** PNG textures, TTF fonts, compressed with ETC2 for mobile compatibility
**Testing:** GUT framework - Unit testing for UI components and logic
**Version Control:** Git - Following existing repository structure

### Integration Points

**UI-GameManager:** UI scenes connect to GameManager autoload for state changes and scene transitions
**UI-QuestManager:** Quest UI components integrate with QuestManager for quest tracking and rewards
**UI-DialogueManager:** Dialogue UI connects to DialogueManager for conversation flows
**UI-CombatSystem:** Combat UI integrates with GameManager's combat logic and state
**Component Inheritance:** All UI components extend BaseUI.gd for common functionality

## Novel Pattern Designs

This project does not require novel architectural patterns. All UI enhancements follow established Godot patterns for component-based UI development with theme-based styling and animation systems. The visual polish builds upon the existing scene-based architecture without introducing new interaction paradigms.

## Implementation Patterns

These patterns ensure consistent implementation across all AI agents:

### UI Component Creation Pattern
- Create component scene in `scenes/components/`
- Attach script in `scripts/components/` with matching name
- Extend `Control` node type for UI components
- Use `@onready` for node references
- Implement `_ready()` for initialization, `_process()` only if needed for animations

### Theme Application Pattern
- All theming through `ui_theme.tres` resource
- Use theme overrides only for component-specific styling
- Colors defined as theme constants, not hardcoded
- Font sizes follow 8px grid system (14pt, 18pt, 24pt, etc.)

### Animation Implementation Pattern
- Simple transitions: `Tween` nodes with `create_tween()`
- Complex sequences: `AnimationPlayer` with keyframe animations
- Always call `tween.kill()` in completion callbacks to prevent memory leaks
- Animation durations: 200ms for immediate feedback, 500ms for state changes

### Asset Loading Pattern
- UI textures loaded as `CompressedTexture2D` resources
- Use `TextureAtlas` for sprite sheets to reduce draw calls
- Lazy load large assets, preload critical UI elements
- Asset paths use `res://` protocol consistently

### Error Handling Pattern
- UI operations wrapped in try-catch blocks
- Errors logged but don't crash the game
- Visual feedback for error states (red tinting, disabled appearance)
- Graceful degradation - UI continues functioning even with failures

### Performance Monitoring Pattern
- Use `Performance.get_monitor()` for frame rate and memory tracking
- Custom debug overlay for development builds only
- Performance assertions in tests (maintain 60fps target)
- Memory monitoring to stay under 500MB limit

## Consistency Rules

### Naming Conventions

**UI Components:** PascalCase with "UI" prefix (UIButton, UIProgressBar)
**Theme Resources:** snake_case with "_theme" suffix (ui_theme.tres, button_theme.tres)
**Animation Resources:** snake_case with "_anim" suffix (button_hover_anim.tres)
**Asset Folders:** lowercase with underscores (ui_assets/, font_assets/)

### Code Organization

**UI Components:** scripts/components/ with matching scene files in scenes/components/
**Theme Files:** resources/themes/ for .tres files
**Animation Files:** resources/animations/ for .tres files
**Asset Organization:** assets/ui/ subfolders by type (buttons/, backgrounds/, icons/)

### Error Handling

UI components use try-catch blocks with graceful degradation. Failed operations log errors using Godot's print() or custom logger but don't crash the game. Visual feedback (error colors, disabled states) informs users of issues without breaking gameplay.

### Logging Strategy

Development: Godot's print() statements for UI operations and errors. Production: Custom logger class filtering by severity (DEBUG, INFO, WARN, ERROR). Performance metrics logged continuously. UI state changes logged at DEBUG level for debugging.

## Data Architecture

UI enhancements work with existing data models:
- **Player:** Extended with UI preference settings (theme choices, accessibility options)
- **Item/Skill:** Enhanced with visual metadata (icons, colors, animation references)
- **UI State:** New models for menu states, animation preferences, and visual settings

All models extend `Resource` class for Godot serialization compatibility.

## API Contracts

**UI-GameManager Interface:**
- `change_scene(scene_name: String)` - Scene transitions
- `start_combat()` / `end_combat()` - Combat state management
- `get_player_stats()` - Player data access

**UI-Component Interface:**
- `show()` / `hide()` - Visibility control
- `set_theme(theme: Theme)` - Dynamic theming
- `animate_transition(type: String)` - Animation triggers

**Signal-based Communication:**
- `ui_action_completed(action: String)` - UI operation feedback
- `theme_changed(new_theme: Theme)` - Theme updates
- `performance_warning(metric: String, value: float)` - Performance alerts

## Security Architecture

**Data Integrity:** Save file validation to prevent corruption from UI state changes
**Input Validation:** Sanitize user inputs in character creation and settings
**Resource Access:** Safe loading of theme and asset resources
**No Network Security:** Single-player game with no online features

## Performance Considerations

**Frame Rate Target:** Maintain 60fps gameplay performance
**Memory Budget:** Stay under 500MB total memory usage
**Asset Optimization:** Texture compression, atlas usage, lazy loading
**Animation Performance:** GPU-accelerated animations, limit concurrent tweens
**UI Batching:** Minimize draw calls through texture atlases and node grouping
**Performance Monitoring:** Built-in profiling with custom debug overlay

## Deployment Architecture

**Export Templates:** Godot 4.5 export for multiple platforms (Windows, macOS, Linux, mobile)
**Asset Optimization:** Platform-specific texture compression (ETC2 for mobile, BC7 for desktop)
**Build Configuration:** Separate debug/release builds with performance monitoring in debug
**Distribution:** Steam, itch.io, or direct download depending on target platform

## Development Environment

### Prerequisites

**Godot 4.5:** Game engine with GDScript support
**Git:** Version control system
**GUT Testing Framework:** Already included in addons/
**Image Editor:** For creating UI assets (GIMP, Photoshop, or Aseprite)
**Font Editor:** For font customization if needed

### Setup Commands

```bash
git clone <repository-url>
cd godot-rpg-refactor
# Open project.godot in Godot 4.5
# Run project to verify existing functionality
# Begin visual polish implementation following epic breakdown
```

## Architecture Decision Records (ADRs)

**ADR-001: UI Framework Choice**
- **Decision:** Use Godot's native Control nodes with custom themes
- **Rationale:** Maintains compatibility with existing codebase, leverages Godot's built-in UI system
- **Consequences:** No external UI libraries needed, consistent with Godot ecosystem

**ADR-002: Centralized Theming**
- **Decision:** Single ui_theme.tres file for all UI styling
- **Rationale:** Ensures consistency across all UI components, easy to maintain and update
- **Consequences:** Theme changes affect entire UI, requires careful planning

**ADR-003: Animation Strategy**
- **Decision:** Tween for dynamic animations, AnimationPlayer for complex sequences
- **Rationale:** Balances flexibility with performance, follows Godot best practices
- **Consequences:** Consistent animation timing, memory-efficient approach

**ADR-004: Asset Optimization**
- **Decision:** TextureAtlas with platform-specific compression
- **Rationale:** Reduces draw calls, optimizes for mobile performance
- **Consequences:** Requires asset preprocessing, platform-specific builds needed

**ADR-005: Component Inheritance**
- **Decision:** All UI components extend BaseUI.gd
- **Rationale:** Common functionality shared, consistent behavior across components
- **Consequences:** Changes to BaseUI affect all components, requires careful testing

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2025-11-19_
_For: Matt_</content>
<parameter name="filePath">docs/architecture.md