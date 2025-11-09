# Final Boss Implementation Plan

## Overview
Implement a multi-phase final boss encounter with special abilities and mechanics distinct from regular monsters.

## Architecture

### 1. FinalBoss Model (extends Monster)
- **File**: `scripts/models/FinalBoss.gd`
- **Key Properties**:
  - `current_phase: int` - Current phase (1-4)
  - `phase_data: Array[Dictionary]` - Phase-specific stats and abilities
  - `phase_transitions: Array[int]` - Health percentages that trigger phase changes
  - `special_abilities: Array[String]` - Boss-specific moves
  - `phase_duration: int` - Turns in current phase

**Phase System**:
- Phase 1 (100-76% health): Normal attacks, lower damage
- Phase 2 (75-51% health): Increased attack power, introduces special ability
- Phase 3 (50-26% health): Dual attacks per turn, increased special ability frequency
- Phase 4 (25-0% health): Desperation mode - high damage, frequent abilities

### 2. Boss Abilities
Each phase unlocks different abilities:

**Phase 1 Abilities**:
- Power Strike: 1.5x damage attack

**Phase 2 Abilities** (in addition to Phase 1):
- Dark Curse: Reduces player attack power by 30% for 3 turns

**Phase 3 Abilities** (in addition to previous):
- Whirlwind: Attacks twice per turn

**Phase 4 Abilities** (in addition to previous):
- Last Stand: Increases defense by 50% until next player turn
- Realm Collapse: High damage attack to entire party (scales with phase)

### 3. Modified GameManager
- `start_boss_combat()` - Initiate final boss fight
- `is_boss_combat()` - Check if current combat is boss fight
- `get_boss_phase()` - Get current boss phase
- Handle phase transitions in combat loop

### 4. Modified CombatScene
- Enhanced visual feedback for boss phases
- Display current phase on UI
- Show boss ability names when used
- Phase transition animations/messages

### 5. Integration Points

**ExplorationScene**: 
- Add boss encounter trigger (probably high-level only)
- Or story-gated after certain conditions

**Victory Sequence**:
- Special handling if boss was defeated
- Unlock victory scene
- Trigger game completion

## Implementation Steps

1. Create `FinalBoss.gd` model with phase system
2. Extend `MonsterFactory.create_final_boss()` static method
3. Add `start_boss_combat()` to GameManager
4. Add phase transition logic in `player_attack()` and `monster_attack()`
5. Update CombatScene to display phase information
6. Add ability selection logic to boss AI
7. Create tests for phase transitions and abilities
8. Integrate with victory sequence

## Testing Strategy

- Unit tests for phase transitions
- Combat flow with multi-phase boss
- Ability triggering and effects
- Victory detection when boss defeated
- Save/load with boss combat state

## Success Criteria

✓ Boss has 4 phases with distinct mechanics
✓ Abilities trigger correctly based on phase
✓ Phase transitions happen at correct health thresholds
✓ Boss is significantly harder than regular monsters
✓ Combat UI shows phase information
✓ Defeating boss triggers victory sequence
✓ Boss combat can be saved/loaded
