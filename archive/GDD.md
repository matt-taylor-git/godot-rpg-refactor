# godot-rpg-refactor - Game Design Document

**Author:** Matt
**Game Type:** rpg
**Target Platform(s):** Desktop with plans to also support mobile in the future.

---

## Executive Summary

### Core Concept

It's a simple 2D RPG game where the character encounters monsters and interacts with quests. The battle details are shown to the user in a text battle log. Once the character has leveled up, completed the quests, and defeated the final boss, they win the game.

### Target Audience

All ages, casual, 30 minute play session.

### Unique Selling Points (USPs)

The mix of modern and vintage.

---

## Goals and Context

### Project Goals

Improve the game flow and make it more visually appealing.

### Background and Rationale

The motivation is to combine modern and nostalgic. Take a clean, high res UI, and mix it with vintage game play.

---

## Core Gameplay

### Game Pillars

Tight controls + challenging combat + rewarding exploration.

### Core Gameplay Loop

Exploring, fighting monsters, finishing quests, upgrading equipment, leveling up, getting new skills.

### Win/Loss Conditions

*   **Win:** The player reaches level 20, completes all quests, and defeats the final boss.
*   **Loss:** The player is killed by a monster.

---

## Game Mechanics

### Primary Mechanics

*   Turn-based combat
*   Dialogue choices
*   Quests
*   Inventory and Shop
*   Leveling
*   Skills

### Controls and Input

Keyboard/mouse.

---

## RPG Specific Elements

### Character System

*   **Character attributes:**
    *   **Stats:** `attack`, `defense`, `dexterity`, `health`, `max_health`, `mana`, and `max_mana`.
    *   **Classes/roles:** Hero, Warrior, Mage, Rogue.
    *   **Leveling system:** Experience-based leveling. On level up, `max_health` increases by 10, `attack` by 2, `defense` by 1, and `dexterity` by 1. Health is fully restored.
    *   **Skill trees:** No skill tree. Skills are learned based on level and class requirements.

### Inventory and Equipment

*   **Equipment system:**
    *   **Item types:** `WEAPON`, `ARMOR`, `ACCESSORY`, `CONSUMABLE`, `MISC`.
    *   **Rarity tiers:** No rarity system.
    *   **Item stats and modifiers:** Items can provide bonuses to `attack`, `defense`, and `health`.
    *   **Inventory management:** Fixed 20-slot inventory.

### Quest System

*   **Quest structure:**
    *   **Main story quests:** The system supports different quest types (`kill`, `collect`, `exploration`, `misc`) that can be used to create a main story.
    *   **Side quests:** The system can generate random quests that can function as side quests.
    *   **Quest tracking:** `QuestManager.gd` tracks active and completed quests.
    *   **Branching questlines:** The `StoryManager.gd` can unlock new quests based on the completion of others, allowing for branching questlines.
    *   **Quest rewards:** Quests provide experience and gold as rewards.

### World and Exploration

*   **World design:**
    *   **Map structure:** Scene-based exploration with distinct, named areas.
    *   **Towns and safe zones:** No explicit towns, but safe areas with NPCs like a "Traveling Merchant" exist.
    *   **Dungeons and combat zones:** Exploration areas serve as combat zones with random encounters.
    *   **Fast travel system:** No fast travel system is implemented.
    *   **Points of interest:** Defined by lore and quest objectives.

### NPC and Dialogue

*   **NPC interaction:**
    *   **Dialogue trees:** Branching dialogue system with nodes, text, and player choices.
    *   **Relationship/reputation system:** No relationship or reputation system is implemented.
    *   **Companion system:** No companion system is implemented.
    *   **Merchant NPCs:** A "Traveling Merchant" NPC with a shop is included.

### Combat System

*   **Combat mechanics:**
    *   **Combat style:** Turn-based combat.
    *   **Ability system:** Players can use skills to deal damage, heal, or apply buffs/debuffs.
    *   **Magic/skill system:** A variety of physical and magic-based skills are defined.
    *   **Status effects:** The system supports status effects like "buff" and "debuff".
    *   **Party composition:** Single player character (no party system).

---

## Progression and Balance

### Player Progression

Player progression is a combination of:
*   **Leveling Up:** Gaining experience to increase core stats (`max_health`, `attack`, `defense`, `dexterity`).
*   **Skill Unlocking:** Gaining new skills at certain level milestones.
*   **Equipment Upgrades:** Finding or buying better gear for stat bonuses.
*   **Narrative Advancement:** Completing quests to unlock new content and advance the story.

### Difficulty Curve

A mix of steady and player-controlled.

### Economy and Resources

The player earns gold by defeating monsters, which can be used to purchase items in the shop.

---

## Level Design Framework

### Level Types

*   **Exploration Areas:** Handcrafted scenes like forests and caves for exploration and random encounters.
*   **Safe Zones:** Areas with non-hostile NPCs, such as a merchant.
*   **Boss Arenas:** A dedicated, scripted final boss encounter.

### Level Progression

Level progression is primarily a **linear sequence** driven by quest completion. Players unlock new areas and advance the story by completing quests in a set order.

---

## Art and Audio Direction

### Art Style

*   **Visual Aesthetic:** Dark, elegant, and immersive, using texture-based UI elements with a fantasy theme.
*   **Color Palette:** A dark, low-contrast base with vibrant, selective highlights (dark teal/green, gold/bronze, and vibrant cyan/teal).
*   **Inspirations/References:** The provided sample image and the "Cinzel" font.

### Audio and Music

*   **Music Style/Genre:** Medieval fantasy music.
*   **Sound Effect Tone:** Sounds appropriate for a medieval setting (e.g., sword clashes, magic spells, monster growls).
*   **Importance:** Audio is important for creating an immersive medieval fantasy atmosphere.

---

## Technical Specifications

### Performance Requirements

*   **Target Frame Rate:** 60 FPS
*   **Resolution:** 1920x1080 (Full HD)
*   **Acceptable Load Times:** Under 5 seconds for initial load, under 2 seconds for scene transitions.
*   **Mobile Battery Considerations:** (To be determined when mobile support is implemented)

### Platform-Specific Details

None at this time.

### Asset Requirements

*   **Art Assets:**
    *   **UI:** 9-slice frames for panels and slots; transparent icons for items and equipment.
    *   **Sprites:** Sprites for player classes and all monster types.
    *   **Typography:** "Cinzel" font for all UI text.
*   **Audio Assets:**
    *   **Music:** Medieval-style tracks for exploration and combat.
    *   **Sound Effects (SFX):** Combat, UI, and environmental sounds.

---

## Development Epics

### Epic Structure

1.  **Core Gameplay Loop:** Covers exploration, combat, quests, and character progression.
2.  **UI/UX Overhaul:** Focuses on implementing the new art style, including the texture-based UI, "Cinzel" font, and glow effects.
3.  **Content Creation:** Involves designing quests, monsters, items, and skills.
4.  **Mobile Platform Support:** Addresses the future goal of porting the game to mobile devices.

---

## Success Metrics

### Technical Metrics

*   **Frame Rate:** Maintain a consistent 60 FPS.
*   **Load Times:** Under 5 seconds for initial load, under 2 seconds for scene transitions.
*   **Crash Rate:** Aim for a crash-free experience.
*   **Memory Usage:** Monitor and optimize for efficient performance.

### Gameplay Metrics

*   **Player Completion Rate:** Track how many players complete the main questline.
*   **Session Length:** Monitor the average play session length.
*   **Difficulty Pain Points:** Identify areas where players are struggling.
*   **Feature Engagement:** Track the usage of different skills, items, and features.

---

## Out of Scope

*   Multiplayer
*   Procedural Generation
*   Complex branching narratives

---

## Assumptions and Dependencies

*   **Technical Assumptions:**
    *   The game will be developed using the Godot engine.
    *   The initial target platform is desktop.
*   **Team Capabilities:**
    *   The project will be developed by a single developer.
*   **Third-Party Dependencies:**
    *   The "Cinzel" font from Google Fonts will be used.
