# Engineering Backlog

This backlog collects cross-cutting or future action items that emerge from reviews and planning.

Routing guidance:

- Use this file for non-urgent optimizations, refactors, or follow-ups that span multiple stories/epics.
- Must-fix items to ship a story belong in that story's `Tasks / Subtasks`.
- Same-epic improvements may also be captured under the epic Tech Spec `Post-Review Follow-ups` section.

| Date | Story | Epic | Type | Severity | Owner | Status | Notes |
| ---- | ----- | ---- | ---- | -------- | ----- | ------ | ----- |
| 2025-11-13 | 1.2 | 1 | Bug | High | TBD | Open | Add assertions to load game tests to verify correct scene routing based on GameManager.in_combat [file: tests/godot/test_scene_transitions.gd] |
| 2025-11-13 | 1.2 | 1 | Bug | High | TBD | Open | Add assertions to combat outcome tests to verify transition to correct scenes [file: tests/godot/test_scene_transitions.gd] |
| 2025-11-13 | 1.2 | 1 | Bug | High | TBD | Open | Add verification that all scene changes use GameManager.change_scene() method [file: tests/godot/test_scene_transitions.gd] |
| 2025-11-13 | 1.2 | 1 | TechDebt | Med | TBD | Open | Replace assert_true(true) with meaningful assertions in all tests [file: tests/godot/test_scene_transitions.gd] |
| 2025-11-19 | 1.1 | 1 | Enhancement | High | TBD | Open | Replace regular Button nodes with UIButton component in all remaining UI scenes (AC-UI-003) [files: scenes/ui/quest_log_dialog.tscn, scenes/ui/shop_dialog.tscn, scenes/ui/world_map.tscn, scenes/ui/town_scene.tscn, scenes/ui/inventory_dialog.tscn, scenes/ui/exploration_scene.tscn, scenes/ui/victory_scene.tscn, scenes/ui/skills_dialog.tscn, scenes/ui/game_over_scene.tscn, scenes/ui/codex_dialog.tscn, scenes/ui/save_slot_dialog.tscn, scenes/ui/quest_completion_dialog.tscn, scenes/ui/base_ui.tscn] |
| 2025-11-19 | 1.1 | 1 | Bug | High | TBD | Open | Fix type mismatch in ui_button.tscn - change from type="Button" to type="Control" to match UIButton.gd script |
| 2025-11-19 | 1.1 | 1 | Enhancement | Med | TBD | Open | Create migration script to batch-update Button nodes to UIButton across all scenes |
| 2025-11-19 | 1.1 | 1 | Documentation | Low | TBD | Open | Document UIButton usage pattern for future UI development |
| 2025-11-20 | 2.1 | 2 | Bug | High | TBD | Open | Replace ProgressBar nodes with UIProgressBar in combat_scene.tscn (Task 8) [file: scenes/ui/combat_scene.tscn:78,97] |
| 2025-11-20 | 2.1 | 2 | Bug | High | TBD | Open | Update combat scene node types from ProgressBar to UIProgressBar [file: scenes/ui/combat_scene.tscn] |
| 2025-11-20 | 2.1 | 2 | TechDebt | Med | TBD | Open | Add UIProgressBar theme items to ui_theme.tres resource file [file: resources/ui_theme.tres] |
| 2025-11-20 | 2.1 | 2 | TechDebt | Med | TBD | Open | Move integration test files to tests/godot/ directory [file: test_progress_bar_simple.gd, test_combat_scene_integration.gd] |