# CLAUDE.md - AI Assistant Guide for Pyrpg-Godot

## Project Overview

**Pyrpg-Godot** is a turn-based RPG game built with Godot 4.6, refactored from a Python implementation. This document provides comprehensive guidance for AI assistants (like Claude) working on this codebase.

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Project Type**: Turn-based RPG with exploration, combat, quests, and narrative systems
- **Main Scene**: `res://scenes/main.tscn`
- **Architecture**: Scene-based with autoload singleton managers
- **Testing**: GUT 9.5.0 (Godot Unit Testing)
- **Linting**: gdtoolkit 4.5.0 (`gdlint`)

---

## Directory Structure

```
godot-rpg-refactor/
├── scripts/              # All GDScript files
│   ├── globals/         # Autoload singleton managers
│   ├── models/          # Data models (Player, Monster, Item, Skill, etc.)
│   ├── ui/              # UI scene controllers
│   ├── utils/           # Factory classes and utilities
│   ├── components/      # Reusable UI components
│   └── exploration/     # Exploration-specific logic
├── scenes/              # Godot scene files (.tscn)
│   ├── ui/             # UI scenes (menus, dialogs, game screens)
│   └── components/     # Reusable UI component scenes
├── resources/           # Game data and resource definitions
│   └── ui_theme.tres   # Centralized UI theme (colors, fonts, styles)
├── assets/              # Game assets (fonts, sprites, audio)
├── tests/               # GUT (Godot Unit Testing) test files
│   └── godot/          # All GUT test scripts (test_*.gd)
├── docs/                # Comprehensive project documentation
├── addons/              # Third-party plugins (GUT testing framework)
├── .gdlintrc            # GDScript linter configuration
└── project.godot        # Godot project configuration
```

### Key Directories Explained

- **scripts/globals/**: Contains autoload singletons that manage global game state
  - `GameManager.gd`: Core game state, combat system, scene transitions
  - `QuestManager.gd`: Quest tracking and progression
  - `DialogueManager.gd`: Dialogue system
  - `StoryManager.gd`: Story progression and events
  - `CodexManager.gd`: In-game encyclopedia/codex
  - `UIThemeManager.gd`: Centralized theme color access (wraps `resources/ui_theme.tres`)

- **scripts/models/**: Data model classes extending `Resource`
  - `Player.gd`: Player character with stats, inventory, equipment
  - `Monster.gd`: Enemy entities
  - `FinalBoss.gd`: Special boss with phases
  - `Item.gd`: Items and equipment
  - `Skill.gd`: Special abilities

- **scripts/utils/**: Factory pattern implementations
  - `MonsterFactory.gd`: Creates monster instances
  - `ItemFactory.gd`: Creates item instances
  - `SkillFactory.gd`: Creates skill instances
  - `QuestFactory.gd`: Creates quest instances

---

## Core Architecture Patterns

### 1. Autoload Singleton Pattern

The game uses Godot's autoload feature for global managers. These are always available via their names:

```gdscript
GameManager.new_game("PlayerName", "Warrior")
QuestManager.accept_quest(quest_id)
DialogueManager.show_dialogue(dialogue_data)
```

**Key Managers**:
- **GameManager**: Combat, save/load, scene management, player state
- **QuestManager**: Quest tracking, completion, rewards
- **DialogueManager**: Dialogue trees and interactions
- **StoryManager**: Story events and progression
- **CodexManager**: Knowledge base and discoveries
- **UIThemeManager**: Theme color lookups via `get_color("color_name")`

### 2. Resource-Based Models

All game entities extend Godot's `Resource` class for easy serialization:

```gdscript
class_name Player
extends Resource

# Use to_dict() and from_dict() for serialization
func to_dict() -> Dictionary:
    return {"name": name, "level": level, ...}

func from_dict(data: Dictionary) -> void:
    name = data.get("name", "")
    level = data.get("level", 1)
```

### 3. Factory Pattern

Factories create game entities with appropriate stats based on type and level:

```gdscript
# Static factory methods
var monster = MonsterFactory.create_monster("goblin", player_level)
var item = ItemFactory.create_item("health_potion")
var skill = SkillFactory.create_skill("fireball")
```

### 4. Signal-Driven Communication

Managers communicate via signals to maintain loose coupling:

```gdscript
# GameManager emits signals
signal combat_started(monster_name: String)
signal player_leveled_up(new_level: int)
signal boss_defeated()

# Other managers connect to these signals
GameManager.connect("player_leveled_up", Callable(QuestManager, "on_level_up"))
```

### 5. Scene-Based UI

Each game screen is a separate scene with its own controller script:
- `MainMenu.gd` → `main_menu.tscn`
- `CombatScene.gd` → `combat_scene.tscn`
- `ExplorationScene.gd` → `exploration_scene.tscn`

---

## Key Coding Conventions

### Node References

Use `@onready` for node references to ensure nodes exist:

```gdscript
@onready var health_bar = $HealthBar
@onready var attack_button = $AttackButton
```

### Resource Loading

Use `preload()` for compile-time loading of resources:

```gdscript
const COMBAT_SCENE = preload("res://scenes/ui/combat_scene.tscn")
const SaveSlotDialog = preload("res://scenes/ui/save_slot_dialog.tscn")
```

Use `load()` for runtime/dynamic loading:

```gdscript
var FinalBossClass = load("res://scripts/models/FinalBoss.gd")
var boss = FinalBossClass.new()
```

### Class Names

Use `class_name` for classes that need to be referenced elsewhere:

```gdscript
class_name Player
extends Resource
# Now "Player" can be used as a type anywhere
```

**Important**: `class_name` must come BEFORE `extends` per gdlint's `class-definitions-order` rule.

### Signal Connections

Use `Callable()` for signal connections in Godot 4:

```gdscript
button.connect("pressed", Callable(self, "_on_button_pressed"))
GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))
```

### Typed Variables

Use type hints for better code clarity and IDE support:

```gdscript
var health: int = 100
var player: Player = null
func get_damage(base: int) -> int:
    return base * 2
```

### GDScript Class Definition Order

The project follows gdlint's `class-definitions-order` rule. Members within a `.gd` file must appear in this order:

1. `class_name`
2. `extends`
3. `signal` declarations
4. `enum` definitions
5. `const` constants
6. `@export` variables
7. Public variables
8. Private variables (`_prefixed`)
9. `@onready` variables
10. Functions (`_ready`, `_process`, etc., then custom)

### Unused Function Arguments

Prefix unused function arguments with `_` to satisfy the `unused-argument` lint rule:

```gdscript
func _on_button_pressed(_event):
    do_something()
```

---

## Combat System

The combat system is managed by `GameManager.gd` and uses a turn-based approach:

### Starting Combat

```gdscript
# Random encounter
GameManager.start_combat()

# Boss fight
GameManager.start_boss_combat(player_level)
```

### Combat Flow

1. **Player Turn**: Call `player_attack()` or `player_use_skill(skill_index)`
2. **Monster Turn**: Call `monster_attack()`
3. **Check End**: `is_combat_over()` returns true when someone is defeated
4. **End Combat**: `end_combat()` cleans up and emits `combat_ended` signal

### Combat Signals

```gdscript
combat_started(monster_name: String)
combat_ended(player_won: bool)
player_attacked(damage: int, is_critical: bool)
monster_attacked(damage: int)
player_leveled_up(new_level: int)
boss_phase_changed(phase: int, description: String)
boss_defeated()
```

---

## Save/Load System

### Saving

```gdscript
GameManager.save_game(slot_number)  # Saves to user://save_slot_N.json
```

Saves include:
- Player data (stats, inventory, equipment, skills)
- Current scene
- Combat state (if in combat)
- Exploration state
- Game start time (for playtime tracking)

### Loading

```gdscript
GameManager.load_game(slot_number)  # Returns true on success
```

### Serialization Pattern

All models implement `to_dict()` and `from_dict()`:

```gdscript
# Saving
var save_data = player.to_dict()

# Loading
var player = Player.new()
player.from_dict(loaded_data)
```

---

## Scene Management

### Changing Scenes

```gdscript
GameManager.change_scene("town_scene")  # Changes to res://scenes/ui/town_scene.tscn
```

Scene names map to files in `scenes/ui/`:
- `"main_menu"` → `main_menu.tscn`
- `"character_creation"` → `character_creation.tscn`
- `"town_scene"` → `town_scene.tscn`
- `"exploration_scene"` → `exploration_scene.tscn`
- `"combat_scene"` → `combat_scene.tscn`

### Scene Transitions

The `MainScene.gd` (attached to `main.tscn`) listens to `GameManager.scene_changed` signal and handles actual scene loading.

---

## Testing

This project uses **GUT 9.5.0 (Godot Unit Testing)** framework located in `addons/gut/`.

### Test Structure

```gdscript
extends GutTest

func test_player_takes_damage():
    var player = Player.new()
    player.health = 100
    player.take_damage(30)
    assert_eq(player.health, 70, "Player should have 70 health")

func test_monster_creation():
    var monster = MonsterFactory.create_monster("goblin", 5)
    assert_eq(monster.name, "Goblin", "Monster should be a Goblin")
    assert_eq(monster.level, 5, "Monster should be level 5")
```

### Running Tests

Tests are located in `tests/godot/`. Run the full suite from the command line:

```bash
# Run all tests
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/godot/ -glog=1

# Run a single test file
godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/godot/test_ui_button.gd -glog=1
```

**Note**: The GUT `gut_loader.gd` emits a harmless `SCRIPT ERROR: Trying to assign value of type 'Nil' to a variable of type 'bool'` on startup. This is a known GUT 9.5.0 / Godot 4.6 compatibility issue and does not affect test execution.

### Test Files

| Test File | Tests | What It Covers |
|-----------|-------|----------------|
| `test_character_creation.gd` | 10 | Character creation UI and flow |
| `test_character_portrait_container.gd` | 18 | Portrait component, status effects, signals |
| `test_combat_scene_integration.gd` | 10 | Combat scene setup, portraits, UI elements |
| `test_main_menu.gd` | 10 | Main menu buttons, focus, animations |
| `test_scene_transitions.gd` | 3 | Scene navigation and GameManager state |
| `test_ui_animation.gd` | 17 | Animation system, loading indicators, feedback |
| `test_ui_button.gd` | 12 | UIButton component states, signals, themes |
| `test_ui_progress_bar.gd` | 14 | Progress bar values, animations, accessibility |
| `test_ui_theme_accessibility.gd` | 14 | WCAG contrast ratios, theme color validation |
| `test_navigation.gd` | 20 | Navigation logic |

### Testing Gotchas

1. **Headless mode FPS**: When running `--headless`, FPS is very low (1-13 fps). Performance tests should use generous thresholds (e.g., >= 1.0 fps, not 30+ fps).

2. **`push_warning()` in tested code**: GUT captures `push_warning()` calls as "Unexpected Errors" and fails the test. Use `print()` instead when you need diagnostic output in code that will be tested.

3. **`await obj.ready` hangs**: When `_ready()` fires synchronously during `add_child()`, the `ready` signal has already been emitted. Awaiting it will hang forever. Use `await get_tree().process_frame` instead.

4. **UIButton text property**: `UIButton` clears `self.text` in `_ready()` and stores the display text in `button_text`. Always read/write `button.button_text`, not `button.text`.

5. **Theme inheritance**: In Godot 4, child nodes inherit themes from parents automatically. `child.theme` returns `null` because the child uses the parent's theme. Check `child.get_theme_color()` to verify inheritance works.

6. **Signal testing**: Use GUT's `watch_signals()` and `assert_signal_emitted()` rather than manual lambda tracking. Calling a signal handler directly (e.g., `_on_mouse_entered()`) does NOT emit the corresponding signal.

7. **Timing-sensitive tests**: Use `assert_almost_eq()` with generous epsilon values for timing assertions. Headless mode timing varies significantly.

---

## GDScript Linting

The project uses **gdtoolkit 4.5.0** for GDScript linting. Configuration is in `.gdlintrc`.

### Running the Linter

```bash
# Lint all game scripts
gdlint scripts/

# Lint test files
gdlint tests/

# Lint a specific file
gdlint scripts/ui/MainMenu.gd
```

### Configuration (`.gdlintrc`)

```
max-line-length: 120
max-public-methods: 50
max-returns: 10
```

### Key Lint Rules

- **`class-definitions-order`**: class_name before extends, constants before vars, etc. (see Class Definition Order above)
- **`max-line-length`**: 120 characters max. Break long lines with backslash continuation or extract variables.
- **`unused-argument`**: Prefix unused args with `_` (e.g., `_event`, `_delta`)
- **`no-else-return` / `no-elif-return`**: Don't use `else`/`elif` after a `return` statement; use early returns instead.
- **`duplicated-load`**: Extract repeated `load()` / `preload()` calls into class-level constants.
- **`trailing-whitespace`**: No trailing whitespace on any line.

### Installing gdtoolkit

```bash
pip install gdtoolkit
```

---

## UI Theme System

The game uses a centralized theme defined in `resources/ui_theme.tres` and managed by the `UIThemeManager` autoload singleton.

### Theme Colors

Colors are stored in the theme resource under the `Global` type prefix:

```
Global/colors/background = Color(0.08, 0.07, 0.06, 1)
Global/colors/text_primary = Color(0.95, 0.92, 0.85, 1)
Global/colors/primary_action = Color(0.35, 0.25, 0.10, 1)
Global/colors/secondary = Color(0.58, 0.55, 0.50, 1)
Global/colors/accent = Color(0.85, 0.70, 0.35, 1)
Global/colors/success = Color(0.45, 0.75, 0.45, 1)
Global/colors/danger = Color(0.85, 0.35, 0.30, 1)
Global/colors/border_bronze = Color(0.60, 0.45, 0.20, 1)
Global/colors/title_gold = Color(0.85, 0.70, 0.35, 1)
```

### Accessing Theme Colors

```gdscript
# Via UIThemeManager singleton
var bg_color = UIThemeManager.get_color("background")
var text_color = UIThemeManager.get_color("text_primary")
var bronze = UIThemeManager.get_border_bronze_color()
var gold = UIThemeManager.get_title_gold_color()

# Direct theme access (e.g., in tests)
var theme = load("res://resources/ui_theme.tres")
var color = theme.get_color("background", "Global")
```

### WCAG Accessibility

Theme colors are validated against **WCAG AA** contrast requirements (4.5:1 ratio for normal text). The `test_ui_theme_accessibility.gd` test file verifies all color pairings meet minimum contrast ratios. Disabled/inactive UI elements are exempt from AA requirements (3:1 minimum per WCAG).

### Theme Gotcha

When editing `ui_theme.tres`, do NOT add inline comments on color lines. The Godot theme parser may fail to load colors that have comments appended.

---

## Visual Style Guide

The game follows a **dark fantasy RPG aesthetic** with warm amber/bronze tones. See `docs/style-guide.md` for the complete visual reference.

### Quick Color Reference
| Purpose | Color Token | Value |
|---------|-------------|-------|
| Background | `background` | Color(0.08, 0.07, 0.06) |
| Text | `text_primary` | Color(0.95, 0.92, 0.85) |
| Buttons | `primary_action` | Color(0.35, 0.25, 0.10) |
| Borders | `border_bronze` | Color(0.60, 0.45, 0.20) |
| Titles/Focus | `accent` | Color(0.85, 0.70, 0.35) |
| Success | `success` | Color(0.45, 0.75, 0.45) |
| Danger | `danger` | Color(0.85, 0.35, 0.30) |

### Design Principles
1. **Never use pure white or black** - use warm off-whites and deep charcoals
2. **Bronze borders everywhere** - panels, buttons, dividers
3. **Gold for emphasis** - titles, focus states, important highlights
4. **Subtle textures** - grain overlays, no flat solid colors
5. **Medieval sharpness** - 2px corner radius, not rounded
6. **Warm lighting feel** - like candlelight or firelight

### Applying the Theme
```gdscript
# Get colors via UIThemeManager
var bg = UIThemeManager.get_background_color()
var gold = UIThemeManager.get_color("accent")
var bronze = UIThemeManager.get_color("border_bronze")

# Apply gold title with shadow
label.add_theme_color_override("font_color", UIThemeManager.get_color("title_gold"))
label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
label.add_theme_constant_override("shadow_offset_x", 2)
label.add_theme_constant_override("shadow_offset_y", 2)
```

---

## Web Export & Browser Testing

The game can be exported to web (HTML5/WASM) and served locally for browser-based testing, including automated testing with `agent-browser`.

### Prerequisites

- **Godot CLI**: `godot.windows.opt.tools.64.exe` is on the user PATH (from `D:\Steam2TB\steamapps\common\Godot Engine`)
- **Python 3**: Required for the local HTTP server
- **Export preset**: "Web" preset is configured in `export_presets.cfg`, outputting to `webexport/rpg.html`

### Quick Start

```powershell
# Full pipeline: export game + start server
.\Export-AndServe.ps1

# Serve an existing build (skip export)
.\Export-AndServe.ps1 -SkipExport

# Export only (no server)
.\Export-AndServe.ps1 -ExportOnly

# Custom port
.\Export-AndServe.ps1 -Port 9090
```

### Testing URL

Once the server is running, the game is available at:
```
http://localhost:8060/rpg.html
```

Use `agent-browser` to navigate to this URL for automated browser testing.

### Server Details (`serve_web.py`)

The Python server (`serve_web.py`) handles Godot-specific requirements:
- Correct MIME types for `.wasm` and `.pck` files (overrides Windows registry defaults)
- `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers
- No-cache headers to avoid stale builds during development
- Prints `SERVER_READY http://localhost:8060/rpg.html` when ready

```bash
# Direct usage (if you only need the server)
python serve_web.py --port 8060 --dir webexport
```

### Game Viewport

The web export renders at **800x600** pixels.

---

## Character Classes

The game supports multiple character classes with different stat distributions:

- **Hero**: Balanced stats (attack: 12, defense: 6, dexterity: 6)
- **Warrior**: High attack/defense (attack: 15, defense: 8, dexterity: 4)
- **Mage**: Low defense, magic-focused (attack: 8, defense: 4, dexterity: 5)
- **Rogue**: High dexterity (attack: 10, defense: 5, dexterity: 8)

Classes are set during character creation and affect:
- Starting stats
- Starting skills (via `SkillFactory.get_class_skills(class_name)`)
- Stat growth on level up

---

## Animation Conventions

UI animations use Godot's `Tween` system:

```gdscript
func _animate_menu_in():
    var tween = create_tween()
    tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
    tween.parallel().tween_property(title_label, "position:y", target_y, 0.5)
    tween.finished.connect(func(): tween.kill())
```

**Important**: Always call `tween.kill()` in the finished callback to prevent memory leaks.

---

## Common Development Tasks

### Adding a New Monster Type

1. Edit `MonsterFactory.gd`
2. Add a new case in `create_monster()`:
```gdscript
"dragon":
    monster.name = "Dragon"
    monster.max_health = 200 + (level * 15)
    monster.attack = 25 + level
    # ... set other stats
```
3. Add to `get_random_monster_type()` array

### Adding a New Item

1. Edit `ItemFactory.gd`
2. Add item creation logic:
```gdscript
"super_potion":
    item.name = "Super Potion"
    item.description = "Restores 100 HP"
    item.item_type = "consumable"
    item.heal_amount = 100
```

### Adding a New Skill

1. Edit `SkillFactory.gd`
2. Define skill properties:
```gdscript
"lightning_bolt":
    skill.name = "Lightning Bolt"
    skill.effect_type = "damage"
    skill.power = 50
    skill.mana_cost = 30
    skill.cooldown_max = 3
```

### Adding a New UI Scene

1. Create scene in `scenes/ui/new_scene.tscn`
2. Create controller script in `scripts/ui/NewScene.gd`
3. Extend `Control` or appropriate UI node
4. Add scene transition logic in relevant buttons/events
5. Update `GameManager.change_scene()` if needed

### UI Layout Best Practices (800x600 Viewport)

**VBoxContainer children must opt into expanding.** In a VBoxContainer, children only get their minimum height unless they have `size_flags_vertical = 3` (EXPAND_FILL). The main content area between a header and footer should always have this flag, otherwise all three elements stack at minimum height and space is wasted.

```
# In .tscn: make Content fill space between Title and Footer
[node name="Content" type="HBoxContainer" parent="..."]
size_flags_vertical = 3
```

**Hide unused elements at the END of `_ready()`.** If `_ready()` hides UI elements but then calls initialization functions that re-show them, the hiding is undone. Always place visibility overrides as the last step in `_ready()` so no subsequent init code can undo them.

```gdscript
func _ready():
    _setup_everything()
    _initialize_systems()
    # LAST: hide elements that aren't needed
    if unused_button:
        unused_button.visible = false
```

**Space budget for 800x600.** With PanelContainer padding (~8px each side) and a 22px font:
- Available content area: ~768px W x ~568px H
- Title (~35px) + separators (~20px) + Footer (~44px) + padding (~16px) = ~115px fixed overhead
- ~485px remains for the main content area
- Footer with 2 buttons (~340px) fits easily; 6+ buttons (~700px+) overflows

**Don't mix visible and hidden elements in a shared container.** If a container (e.g., Footer HBoxContainer) has both always-visible buttons and conditionally-hidden buttons, the hidden buttons still affect layout calculations unless `visible = false`. Ensure hidden buttons are actually set to invisible, not just disabled.

**PanelContainer children that should grow need EXPAND_FILL.** A PanelContainer child (like StatsSection) takes its minimum height by default. If it contains many elements (labels + progress bars), set `size_flags_vertical = 3` so it can grow/shrink with available space instead of overflowing.

### Adding a New Quest

1. Use `QuestFactory.gd` to define quest data
2. Register quest in `QuestManager.gd`
3. Add quest triggers in `StoryManager.gd` or scene scripts
4. Implement quest completion logic

---

## Important Notes for AI Assistants

### File Organization

- **NEVER** put scripts directly in `scenes/`. Scripts go in `scripts/` subdirectories
- Scene files (.tscn) stay in `scenes/`
- Keep related script and scene names consistent (e.g., `MainMenu.gd` → `main_menu.tscn`)

### Godot 4.6 Syntax

This project uses Godot 4.6 syntax:
- Use `Callable(object, "method_name")` instead of old-style signal connections
- Use `@export` instead of `export`
- Use `@onready` instead of `onready`
- Use `PackedStringArray` instead of `PoolStringArray`
- Scene paths use `res://` protocol
- `class_name` must come before `extends` (enforced by gdlint)

### Signal Connections

Always connect manager signals during `_ready()` to ensure proper initialization order. GameManager's `_connect_manager_signals()` shows the pattern.

### Avoid Circular Dependencies

Use late binding (`load()`) when necessary to avoid circular references:
```gdscript
var FinalBossClass = load("res://scripts/models/FinalBoss.gd")
```

### Combat State Management

Always check `GameManager.in_combat` before starting combat operations. The combat state is persisted in save files.

### Error Handling

Check file existence before scene changes:
```gdscript
if not FileAccess.file_exists(scene_path):
    print("Error: Scene file not found: ", scene_path)
    return
```

### Resource Cleanup

- Kill tweens when finished: `tween.finished.connect(func(): tween.kill())`
- Free instantiated scenes when done: `dialog.queue_free()`
- Use `await` for async operations

---

## Statistics Tracking

GameManager tracks gameplay statistics:

```gdscript
stats = {
    "enemies_defeated": 0,
    "deaths": 0,
    "gold_earned": 0,
    "quests_completed": 0
}
```

Access via:
- `GameManager.get_enemies_defeated()`
- `GameManager.get_deaths()`
- `GameManager.get_gold_earned()`
- `GameManager.get_quests_completed()`

---

## Boss Combat

Boss fights use `FinalBoss.gd` which extends `Monster.gd` with phase mechanics:

```gdscript
# Check if current combat is a boss fight
if GameManager.is_boss_combat():
    var phase = GameManager.get_boss_phase()
```

Boss has multiple phases that trigger at HP thresholds. Phase changes emit `boss_phase_changed` signal.

---

## Playtime Tracking

Game tracks playtime from `game_start_time`:

```gdscript
var playtime_minutes = GameManager.get_playtime_minutes()
```

Playtime is saved/loaded with game state.

---

## Exploration System

Exploration uses a step-based encounter system:

```gdscript
var exploration_state = {
    "steps_taken": 0,
    "encounter_chance": 2.0,
    "steps_since_last_encounter": 0
}

GameManager.set_exploration_state(state)
var current_state = GameManager.get_exploration_state()
```

---

## Inventory System

Player has 20-slot inventory:

```gdscript
player.add_item(item)        # Returns false if inventory full
player.remove_item(index)    # Returns removed item or null
```

Equipment slots:
- `weapon`
- `armor`
- `accessory`

```gdscript
player.equip_item(item, "weapon")
player.unequip_item("armor")
```

---

## Documentation References

For more detailed information, see:

- `docs/architecture.md` - Architecture overview
- `docs/development-guide.md` - Setup and build instructions
- `docs/component-inventory.md` - Component catalog
- `docs/source-tree-analysis.md` - Detailed directory structure
- `docs/tech-spec.md` - Technical specifications

---

## Git Workflow

- **Main branch**: `main` (stable releases)
- **Feature branches**: Use `claude/feature-name-<session-id>` pattern
- Always push to designated feature branch
- Create pull requests for code review

---

## Common Gotchas

1. **Autoload Order**: Managers are loaded in the order specified in `project.godot`. Be mindful of initialization dependencies.

2. **Null Checks**: Always null-check `GameManager.game_data.player` before accessing player data.

3. **Scene References**: Use `res://` paths for all resource references.

4. **Signal Timing**: Some signals emit during `_ready()`. Connect early or use `await get_tree().process_frame`.

5. **Combat State**: When loading a game mid-combat, restore `current_monster` from saved combat state.

6. **Type Safety**: Use type hints to catch errors early, especially with Resource objects.

7. **Skill Cooldowns**: Call `GameManager.tick_skill_cooldowns()` after each combat turn.

8. **UIButton text**: `UIButton` clears `self.text` in `_ready()`. Use `button.button_text` to get/set the displayed text.

9. **Theme colors require type prefix**: Colors in `ui_theme.tres` use `Global/colors/name` format. Access via `theme.get_color("name", "Global")` or `UIThemeManager.get_color("name")`.

10. **`push_warning()` breaks GUT tests**: GUT captures warnings as "Unexpected Errors". Use `print()` for diagnostics in code under test.

11. **Lint before committing**: Run `gdlint scripts/ tests/` to catch style issues. The project maintains zero lint errors.

12. **`_ready()` ordering matters for visibility**: If `_ready()` hides elements early but later calls functions that set `visible = true`, the hiding is undone. Always hide unused UI elements as the last step in `_ready()`.

13. **VBoxContainer children don't expand by default**: Children of a VBoxContainer only get their minimum size unless `size_flags_vertical = 3` (EXPAND_FILL) is set. Forgetting this causes content areas to collapse and waste vertical space.

14. **Footer button overflow at 800x600**: The viewport is only 800px wide (~768px after padding). Each UIButton has ~100-240px minimum width. More than 3-4 buttons in a footer HBoxContainer will overflow horizontally. Hide unused buttons rather than keeping them visible but disabled.

15. **TSCN parent paths must be full paths from the scene root.** In `.tscn` files, the `parent` attribute is resolved relative to the scene's root node. `parent="LeftPanel"` means a direct child of the root named `LeftPanel`. If `LeftPanel` is nested (e.g., under `MainContainer`), the path must be `parent="MainContainer/LeftPanel"`. When hand-editing `.tscn` or moving nodes under a new container, update ALL descendant `parent=` and `[connection] from=` paths. Compare against a known-working scene file (e.g., `character_creation.tscn`, `shop_dialog.tscn`) to verify.

16. **`popup_centered()` only exists on Window-derived nodes.** `Control`, `PanelContainer`, etc. don't have `popup_centered()`. For full-screen overlays, use full-rect anchors (`anchors_preset = 15`). For centered dialogs, use `anchors_preset = 8` (CENTER) or set anchors to 0.5 with size offsets.

17. **Visual consistency**: Follow `docs/style-guide.md` for colors and styling. Never use cyan, bright purple, or pure white - use the warm amber/bronze palette. All borders should be bronze, all titles gold.

---

## Performance Considerations

- Use object pooling for frequently created/destroyed objects (items, effects)
- Cache node references with `@onready` rather than searching each frame
- Use signals instead of polling for state changes
- Preload frequently used scenes/resources

---

## Future Enhancement Areas

Areas documented in backlog (`docs/backlog.md`):
- Status effect system (buffs/debuffs)
- More character classes
- Expanded skill trees
- Multiplayer support
- Advanced AI for boss fights
- Achievement system

---

## Getting Help

When working on this codebase:

1. Check existing documentation in `docs/`
2. Search for similar implementations in the codebase
3. Follow established patterns (factories, signals, serialization)
4. Add tests for new features
5. Run `gdlint` on modified files before committing
6. Verify tests pass: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/godot/ -glog=1`
7. Update this documentation when adding major features

---

**Last Updated**: 2026-02-03
**Godot Version**: 4.6
**GUT Version**: 9.5.0
**gdtoolkit Version**: 4.5.0
**Project Version**: 1.0
