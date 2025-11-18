# Epic Technical Specification: Core Gameplay Loop

Date: 2025-11-12
Author: Matt
Epic ID: 1
Status: Draft

---

## Overview

This epic covers the core gameplay loop of the turn-based RPG, including exploration, combat, quests, character progression, and inventory management. The goal is to implement the fundamental systems that make the game playable, focusing on turn-based combat mechanics, quest tracking, and character development.

## Objectives and Scope

### In Scope
- Turn-based combat system with skills and status effects
- Scene-based exploration with random encounters
- Quest system with multiple quest types (kill, collect, exploration, misc)
- Character progression with leveling and skill unlocking
- Inventory and shop system with item management
- NPC interactions and dialogue

### Out of Scope
- UI/UX overhaul (covered in Epic 2)
- Content creation (monsters, items, quests - Epic 3)
- Mobile platform support (Epic 4)
- Multiplayer features
- Procedural generation

## System Architecture Alignment

This epic aligns with the scene-based architecture using Godot's autoload system for global state management. Key components include:
- GameManager autoload for core game state
- QuestManager for quest tracking
- DialogueManager for NPC interactions
- Autoload-based state persistence
- Signal-based communication between scenes

## Detailed Design

### Services and Modules

| Module | Responsibility | Inputs/Outputs | Owner |
|--------|---------------|----------------|-------|
| GameManager | Core game state, scene transitions | Current scene, game settings | Global autoload |
| QuestManager | Quest tracking and completion | Quest data, player actions | Global autoload |
| DialogueManager | NPC dialogue and choices | Dialogue trees, player choices | Global autoload |
| CombatSystem | Turn-based combat logic | Player/enemy stats, skills | Scene component |
| InventorySystem | Item management and equipment | Items, equipment slots | Scene component |
| ExplorationSystem | Scene transitions and encounters | Player position, encounter triggers | Scene component |

### Data Models and Contracts

#### Character Model
```gdscript
class Character:
    var name: String
    var level: int
    var experience: int
    var stats: Dictionary = {
        "attack": 0,
        "defense": 0,
        "dexterity": 0,
        "health": 0,
        "max_health": 0,
        "mana": 0,
        "max_mana": 0
    }
    var skills: Array
    var equipment: Dictionary
```

#### Quest Model
```gdscript
class Quest:
    var id: String
    var title: String
    var description: String
    var type: String  # kill, collect, exploration, misc
    var objectives: Array
    var rewards: Dictionary
    var status: String  # not_started, in_progress, completed
```

### APIs and Interfaces

#### QuestManager API
- `start_quest(quest_id: String)` → bool
- `complete_objective(quest_id: String, objective_id: String)` → void
- `get_active_quests()` → Array
- `check_quest_completion(quest_id: String)` → bool

#### CombatSystem API
- `initialize_combat(player: Character, enemy: Character)` → void
- `execute_turn(attacker: Character, skill: Skill, target: Character)` → CombatResult
- `check_combat_end()` → CombatOutcome

### Workflows and Sequencing

#### Combat Flow
1. Player enters combat scene
2. CombatSystem.initialize_combat() called
3. Turn loop:
   - Player selects action/skill
   - CombatSystem.execute_turn() processes action
   - Enemy AI selects and executes action
   - Check for combat end conditions
4. Combat ends with victory/defeat
5. Rewards applied, scene transition

#### Quest Flow
1. Player interacts with quest giver
2. QuestManager.start_quest() called
3. Objectives tracked during gameplay
4. QuestManager.complete_objective() called on completion
5. Rewards granted when all objectives met

## Non-Functional Requirements

### Performance
- Combat calculations complete within 100ms per turn
- Scene transitions under 2 seconds
- 60 FPS maintained during gameplay
- Memory usage under 500MB

### Security
- No external data transmission
- Local save file integrity
- Input validation for all player actions

### Reliability/Availability
- Game saves automatically every 5 minutes
- Corrupted save files detected and recovered
- Graceful error handling for invalid states

### Observability
- Combat logs written to console
- Quest progress tracked in QuestManager
- Performance metrics logged
- Error messages displayed to player

## Dependencies and Integrations

- Godot 4.5 engine
- GDScript runtime
- Godot's built-in file system for saves
- Godot's scene system for navigation
- Autoload system for global state

## Acceptance Criteria (Authoritative)

1. Player can move between scenes and trigger random encounters
2. Turn-based combat executes with proper damage calculations
3. Skills can be used in combat with correct effects
4. Quests can be started, tracked, and completed
5. Character levels up with stat increases
6. Inventory holds up to 20 items with equipment functionality
7. Shop interface allows purchasing items
8. NPC dialogue displays with choice options
9. Game saves and loads correctly
10. Combat log displays battle information

## Traceability Mapping

| AC # | Spec Section | Components/APIs | Test Idea |
|------|-------------|----------------|-----------|
| 1 | ExplorationSystem | Scene transitions | Test scene loading and encounter triggers |
| 2 | CombatSystem API | execute_turn method | Unit test damage calculations |
| 3 | CombatSystem | Skill execution | Test skill effects on targets |
| 4 | QuestManager API | complete_objective | Integration test quest completion |
| 5 | Character model | Leveling logic | Test stat increases on level up |
| 6 | InventorySystem | Item storage | Test item limits and equipment |
| 7 | Shop interface | Item purchasing | UI test shop interactions |
| 8 | DialogueManager | Dialogue display | Test dialogue tree navigation |
| 9 | Save system | File I/O | Test save/load data integrity |
| 10 | Combat log | UI display | Test log updates during combat |

## Risks, Assumptions, Open Questions

**Assumptions:**
- Godot's autoload system provides sufficient global state management
- Scene-based navigation meets exploration needs
- GDScript performance adequate for combat calculations

**Risks:**
- Complex quest logic may require additional state tracking
- Combat balance may need iteration based on playtesting
- Save file corruption could lose player progress

**Open Questions:**
- How to handle complex quest branching?
- What combat animations are needed?
- How to balance difficulty scaling?

## Test Strategy Summary

- Unit tests for core systems (CombatSystem, QuestManager)
- Integration tests for scene transitions and quest flows
- UI tests for inventory and shop interfaces
- Playtesting for combat balance and quest clarity
- Save/load testing for data persistence
- Performance testing for frame rate and memory usage

---

Generated by BMad Epic Tech Context Workflow
