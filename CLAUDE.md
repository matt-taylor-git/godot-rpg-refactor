# CLAUDE.md - AI Assistant Guide for Pyrpg-Godot

## Project Overview

**Pyrpg-Godot** is a turn-based RPG game built with Godot 4.5, refactored from a Python implementation. This document provides comprehensive guidance for AI assistants (like Claude) working on this codebase.

- **Engine**: Godot 4.5
- **Language**: GDScript
- **Project Type**: Turn-based RPG with exploration, combat, quests, and narrative systems
- **Main Scene**: `res://scenes/main.tscn`
- **Architecture**: Scene-based with autoload singleton managers

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
├── assets/              # Game assets (fonts, sprites, audio)
├── tests/               # GUT (Godot Unit Testing) test files
├── docs/                # Comprehensive project documentation
├── addons/              # Third-party plugins (GUT testing framework)
└── project.godot        # Godot project configuration
```

### Key Directories Explained

- **scripts/globals/**: Contains autoload singletons that manage global game state
  - `GameManager.gd`: Core game state, combat system, scene transitions
  - `QuestManager.gd`: Quest tracking and progression
  - `DialogueManager.gd`: Dialogue system
  - `StoryManager.gd`: Story progression and events
  - `CodexManager.gd`: In-game encyclopedia/codex

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

### 2. Resource-Based Models

All game entities extend Godot's `Resource` class for easy serialization:

```gdscript
extends Resource
class_name Player

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
extends Resource
class_name Player
# Now "Player" can be used as a type anywhere
```

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

This project uses **GUT (Godot Unit Testing)** framework located in `addons/gut/`.

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

Tests are located in `tests/godot/`. Use GUT's test runner through the Godot editor or command line.

### Key Test Files

- `test_scene_transitions.gd`: Tests scene navigation flow
- `test_navigation.gd`: Tests navigation logic

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

### Godot 4 Migration Notes

This project uses Godot 4.x syntax:
- Use `Callable(object, "method_name")` instead of old-style signal connections
- Use `@export` instead of `export`
- Use `@onready` instead of `onready`
- Use `PackedStringArray` instead of `PoolStringArray`
- Scene paths use `res://` protocol

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
5. Update this documentation when adding major features

---

**Last Updated**: 2025-11-18
**Godot Version**: 4.5
**Project Version**: 1.0
