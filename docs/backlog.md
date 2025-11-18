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