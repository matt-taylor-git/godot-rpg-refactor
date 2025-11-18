# Epic 1: Core Gameplay Loop

## Description
Covers exploration, combat, quests, and character progression.

## Stories

### Story 1.1: Implement Exploration System
As a player, I want to explore the game world so that I can discover quests and enemies.

**Acceptance Criteria:**
- Scene-based exploration with distinct areas
- Random encounters with monsters
- Safe zones with NPCs like Traveling Merchant
- Points of interest for quest objectives

### Story 1.2: Implement Turn-based Combat System
As a player, I want to engage in turn-based combat so that I can battle monsters and progress.

**Acceptance Criteria:**
- Turn-based combat mechanics
- Player and enemy turns
- Skill usage (physical and magic)
- Status effects (buff/debuff)
- Win/loss conditions

### Story 1.3: Implement Quest System
As a player, I want to accept and complete quests so that I can advance the story and gain rewards.

**Acceptance Criteria:**
- Quest types: kill, collect, exploration, misc
- Quest tracking in QuestManager
- Experience and gold rewards
- Quest completion detection

### Story 1.4: Implement Character Progression
As a player, I want to level up and improve my character so that I can become stronger.

**Acceptance Criteria:**
- Experience-based leveling
- Stat increases on level up (health, attack, defense, dexterity)
- Skill unlocking based on level and class
- Class system (Hero, Warrior, Mage, Rogue)

### Story 1.5: Implement Inventory and Shop System
As a player, I want to manage my inventory and purchase items so that I can equip better gear.

**Acceptance Criteria:**
- 20-slot inventory system
- Item types: WEAPON, ARMOR, ACCESSORY, CONSUMABLE, MISC
- Shop interface with Traveling Merchant
- Equipment bonuses to stats
