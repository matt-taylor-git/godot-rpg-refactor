# Project Overview

## Project Information

- **Name**: Pyrpg-Godot
- **Type**: Turn-based RPG Game
- **Engine**: Godot 4.5
- **Language**: GDScript
- **Architecture**: Scene-based with autoload singleton managers

## Executive Summary

This is a complete turn-based RPG game refactored from a Python implementation to Godot. The game features character creation, exploration, combat, quests, dialogue systems, and a comprehensive narrative experience.

## Technology Stack

- **Game Engine**: Godot 4.5
- **Scripting**: GDScript
- **UI Framework**: Godot Control nodes with custom components
- **State Management**: Autoload singleton pattern
- **Data Models**: Godot Resource system
- **Testing**: GUT (Godot Unit Testing) framework
- **Assets**: PNG sprites, TTF fonts, QSS stylesheets

## Architecture Type

Scene-based game architecture with global managers for state management. The project uses Godot's scene system for organizing different game screens and areas, with autoload singletons handling cross-scene logic and data persistence.

## Repository Structure

Monolith (single cohesive codebase) with organized directory structure:
- `scenes/`: Godot scene files (.tscn)
- `scripts/`: GDScript logic organized by functionality
- `assets/`: Game assets (sprites, fonts, UI elements)
- `docs/`: Generated documentation
- `tests/`: Test files using GUT framework

## Key Features

- Character creation with class selection (Warrior, Mage, Rogue)
- Turn-based combat system
- Exploration with random encounters
- Quest system with objectives and rewards
- Dialogue system for NPC interactions
- Inventory and equipment management
- Codex/encyclopedia for game lore
- Save/load functionality

## Development Status

The project appears to be feature-complete with a working game implementation. Documentation has been generated to support ongoing development and maintenance.</content>
<parameter name="filePath">docs/project-overview.md