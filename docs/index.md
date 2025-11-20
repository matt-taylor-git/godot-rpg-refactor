# Project Documentation Index

## Project Overview

- **Type:** Monolith
- **Primary Language:** GDScript
- **Architecture:** Scene-based game
- **Project:** godot-rpg-refactor
- **Description:** Turn-based RPG game refactored to Godot

## Quick Reference

- **Tech Stack:** Godot 4.5, GDScript
- **Entry Point:** main.tscn
- **Architecture Pattern:** Scene-based with autoload managers
- **UI Components:** 17 scenes, 3 reusable components
- **Assets:** 42 files (39 PNG sprites, 2 fonts, 1 stylesheet)

## Generated Documentation

- [Project Overview](./project-overview.md)
- [Architecture](./architecture.md)
- [Component Inventory](./component-inventory.md)
- [Asset Inventory](./asset-inventory.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)

## Existing Documentation

- [Backlog](./backlog.md) - Feature backlog and TODO items
- [CLAUDE.md](./../CLAUDE.md) - AI assistant guide for the project

## Getting Started

1. Install Godot 4.5 from godotengine.org
2. Clone or download this repository
3. Open Godot and import project.godot
4. Press F5 to run the game
5. See development-guide.md for detailed development setup

## Key Architecture Components

- **Global Managers**: GameManager, QuestManager, DialogueManager, StoryManager, CodexManager
- **UI System**: Scene-based with reusable components (UIButton, UIPanel, UIProgressBar)
- **Data Models**: Resource-based classes for Player, Monster, Item, Skill
- **Factory Pattern**: MonsterFactory, ItemFactory, SkillFactory, QuestFactory

## Development Resources

- **Testing**: GUT framework in addons/gut/
- **Version Control**: Git with .gitignore configured for Godot
- **Documentation**: This index serves as the primary entry point for AI-assisted development</content>
<parameter name="filePath">docs/index.md