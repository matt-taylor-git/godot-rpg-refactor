# AGENTS.md — AI Assistant Guide for Pyrpg-Godot

Guidance for coding agents working on this repository. Prefer this file over any
legacy `Claude.md` / Claude Code docs.

## Project Overview

**Pyrpg-Godot** is a turn-based RPG built with Godot, refactored from a Python
implementation.

| | |
|---|---|
| **Engine** | Godot 4.x (project tested on 4.6–4.7) |
| **Language** | GDScript |
| **Main scene** | `res://scenes/main.tscn` |
| **Architecture** | Scene-based UI + autoload singleton managers |
| **Testing** | GUT 9.7.1 (`addons/gut/`, Godot 4.7 branch) |
| **Linting** | gdtoolkit / `gdlint` (`.gdlintrc`) |

---

## Directory Structure

```
godot-rpg-refactor/
├── scripts/
│   ├── globals/         # Autoload managers (GameManager, QuestManager, …)
│   ├── models/          # Resource models (Player, Monster, Item, Skill, …)
│   ├── ui/              # Scene controller scripts
│   ├── utils/           # Factories, PortraitLookup, ItemLookup
│   ├── components/      # Reusable UI component scripts
│   └── exploration/
├── scenes/
│   ├── ui/              # Game screens / dialogs (.tscn)
│   └── components/
├── resources/           # ui_theme.tres, etc.
├── assets/              # Runtime art (items/, ui/icons/, sprites, fonts)
│   ├── items/           # Inventory item icons (promoted)
│   └── generated/       # Staging area for Imagine assets + manifest.json
├── tests/godot/         # GUT tests (test_*.gd)
├── docs/                # Architecture, style guide, backlog
├── .grok/skills/        # Grok skills (imagine-asset, web-export)
├── addons/gut/          # Unit testing framework
├── .gdlintrc
└── project.godot
```

**Rules**

- Scripts live under `scripts/`, never next to scenes under `scenes/` alone.
- Keep script/scene names paired (`MainMenu.gd` ↔ `main_menu.tscn`).
- Use `res://` paths for all game resources.

---

## Core Architecture

### Autoload managers

Always available by name (order is set in `project.godot`):

```gdscript
GameManager.new_game("PlayerName", "Warrior")
QuestManager.accept_quest(quest_id)
DialogueManager.show_dialogue(dialogue_data)
```

| Manager | Role |
|---------|------|
| `GameManager` | Combat, save/load, scenes, player state |
| `QuestManager` | Quests |
| `DialogueManager` | Dialogue |
| `StoryManager` | Story events |
| `CodexManager` | Codex / discoveries |
| `UIThemeManager` | Theme colors via `get_color("name")` |

### Patterns

1. **Resource models** — `class_name` types with `to_dict()` / `from_dict()`.
2. **Factories** — `MonsterFactory`, `ItemFactory`, `SkillFactory`, `QuestFactory`.
3. **Signals** — loose coupling; connect with `Callable(obj, "method")`.
4. **Texture lookups** — `PortraitLookup` (classes/monsters/NPCs), `ItemLookup` (items by `item_id`).

```gdscript
var monster = MonsterFactory.create_monster("goblin", player_level)
var item = ItemFactory.create_item("health_potion")
var icon = ItemLookup.get_item_texture(item)
var portrait = PortraitLookup.get_class_texture("Warrior")
```

### Scene changes

```gdscript
GameManager.change_scene("town_scene")  # → res://scenes/ui/town_scene.tscn
```

`MainScene.gd` listens to `GameManager.scene_changed` and loads the scene.

---

## Coding Conventions

### Class definition order (gdlint)

1. `class_name` (before `extends`)
2. `extends`
3. `signal` → `enum` → `const` → `@export` → public vars → `_private` → `@onready`
4. Functions (`_ready`, then custom)

### Style

- Prefer type hints (`var health: int = 100`).
- Prefix unused args with `_` (`_event`, `_delta`).
- No `else` / `elif` after bare `return` (`no-else-return`).
- Max line length **120**.
- Kill finished tweens: `tween.finished.connect(func(): tween.kill())`.
- Use `preload()` for compile-time resources; `load()` when avoiding circular deps.
- `UIButton`: read/write `button.button_text`, not `button.text` (cleared in `_ready`).
- Prefer `print()` over `push_warning()` in code under GUT (warnings fail tests).
- Keep touched scripts within the `gdlint` max-file-lines limit (currently 1000).
  Move reusable UI behavior into components instead of growing scene controllers.

### UI layout (1280×720, 16:9)

- Base viewport is **1280×720** (16:9). Stretch mode remains `canvas_items` / `expand`.
- Main gameplay hub is `exploration_scene`. `town_scene` and `world_map` alias to it.
- Hub columns ≈ **260px / flexible / 340px** (character HUD · map · location + actions).
- Visual reading order: **map → selected location → primary action → character condition**.
- Left HUD is **content-sized** (no full-height empty panel). Map fills center; no
  duplicate location footer under the map.
- Right column: location card → one gold **primary CTA** → muted secondaries →
  narrative → compact utility bar (Inventory / Quests / Menu).
- Map markers: `scripts/components/MapMarker.gd` (teardrop pins + collision-aware labels).
- VBox children need `size_flags_vertical = 3` (EXPAND_FILL) only when they should grow.
- Hide unused controls as the **last** step of `_ready()`.
- In `.tscn`, `parent=` is from scene root; nested nodes need full parent paths.

---

## Theme & Visual Style

Central theme: `resources/ui_theme.tres` via `UIThemeManager`.
Full reference: `docs/style-guide.md`.

### Color tokens

| Purpose | Token | Approx |
|---------|-------|--------|
| Background | `background` | warm charcoal |
| Text | `text_primary` | parchment off-white |
| Buttons | `primary_action` | deep bronze-brown |
| Borders | `border_bronze` | bronze |
| Titles / focus | `accent` / `title_gold` | gold |
| Success / danger | `success` / `danger` | green / red |

Dark fantasy: **no pure white/black**, warm umber/charcoal surfaces, ~2px corners.

### Typography (Cinzel + Source Serif 4)

| Role | Face | Path |
|------|------|------|
| Display / headings / primary CTA | **Cinzel** | `assets/Cinzel-VariableFont_wght.ttf` |
| Body, stats, narrative, captions, marker labels | **Source Serif 4** | `assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf` |

- License: SIL OFL — keep `assets/fonts/OFL-SourceSerif4.txt` with the font.
- Sizes (see `UITypography`): H1 28 / H2 24 / H3 20 / body 14–16 / caption 12.
- Prefer Source Serif 4 for 12–14px UI on dark backgrounds; Cinzel for titles and
  emphasis only. Avoid long all-caps body copy.
- Do **not** use `assets/fonts/default_font.ttf` for new UI body text.
- Google Fonts (OFL) may be fetched into `assets/fonts/` for companions; ship files
  on disk (no runtime CDN webfonts).
- Sibling HUD labels (for example HP / MP / XP) must use the same font face, size,
  weight, and color unless the design intentionally distinguishes one of them.
- When sibling labels receive runtime typography in a controller, register every new
  label in that same typography pass or give it an explicit matching theme override.
  Do not rely on default theme inheritance when neighboring controls are overridden.

### Borders, chrome, and hierarchy

- **Bright gold** borders/motion only for: selected map markers, focused controls,
  primary CTAs, important state changes.
- **Quiet panels** (map, HUD card, narrative): 0–1px muted bronze or soft separators.
- **Framed panels** (location card): fuller bronze edge OK.
- Secondary / utility buttons: smaller height, caption type, muted borders — never
  equal weight to the primary action.
- Micro-motion: ~150–200ms; respect `GameSettings.get_reduced_motion()`.

When editing `ui_theme.tres`, **do not** put inline comments on color lines.

---

## Asset Generation (Grok Imagine)

**Do not use Gemini, Claude generate-asset, or `generate_asset.py`.**

All new game art goes through the project skill:

```
.grok/skills/imagine-asset/
├── SKILL.md              # Full agent workflow
├── style-reference.md    # Art direction + prompt templates
├── asset-types.json      # Sizes, framing, promote dirs
└── scripts/
    └── process_asset.py  # Resize, chroma-key, promote, manifest
```

Slash / invoke: **`/imagine-asset`**. Also load the global **`imagine`** skill for
prompt craft around `image_gen` / `image_edit`.

### Supported types

| Type | Size | Output staging | Promote default |
|------|------|----------------|-----------------|
| `item` | 256×256 | `assets/generated/items/` | `assets/items/<id>.png` |
| `monster` | 512×512 | `assets/generated/monsters/` | `assets/` (name as needed) |
| `ui` | 256×256 | `assets/generated/ui/` | `assets/ui/` |

### End-to-end workflow

1. **Prompt** — natural prose (2–5 sentences), subject first. Include style
   (stylized cartoon, bold outlines, cell-shaded, hand-painted, dark fantasy),
   framing from `asset-types.json`, solid magenta background (`#FF00FF`), warm
   upper-left lighting. No long negative-keyword dumps. No text on the art.
   Do not paint magenta/pink on the subject.

2. **Generate**
   - First of a set: `image_gen` with matching `aspect_ratio` (`1:1` for items).
   - Siblings: `image_edit` with the approved first image as `image` reference;
     describe only what changes.

3. **Process** (project root):

```bash
python .grok/skills/imagine-asset/scripts/process_asset.py \
  --source "<path from image_gen or image_edit>" \
  --type item \
  --id sword \
  --description "sturdy iron longsword" \
  --source-tool image_gen
```

- Writes `assets/generated/<subdir>/item_<id>_001.png` (counter increments).
- Updates `assets/generated/manifest.json`.
- **Auto-samples corner pixels** for chroma key (Imagine often ignores pure
  `#FF00FF` and paints a flat rose/magenta plate). Override with `--chroma RRGGBB`.
  Raise `--tolerance` (default 55) if fringes remain.

4. **Review** — open the processed PNG; re-edit if silhouette fails at small size.

5. **Promote**:

```bash
python .grok/skills/imagine-asset/scripts/process_asset.py \
  --promote \
  --type item \
  --id sword
```

Default: `assets/items/sword.png`. Godot creates `.import` on next open/import.

6. **Wire into game** (required for the art to appear):

| Asset kind | Data ID | Lookup map | Factory / usage |
|------------|---------|------------|-----------------|
| Item icon | `Item.item_id` | `ItemLookup.ITEM_TEXTURES` | `ItemFactory.create_item("id")` |
| Class portrait | class name | `PortraitLookup.CLASS_TEXTURES` | character creation / inventory |
| Monster | name key | `PortraitLookup.MONSTER_TEXTURES` | `MonsterFactory` |
| NPC | npc id | `PortraitLookup.NPC_TEXTURES` | dialogue |

Example for a new item:

1. Generate + promote `assets/items/dagger.png`.
2. Add `"dagger": "res://assets/items/dagger.png"` to `ItemLookup.ITEM_TEXTURES`.
3. Add a `"dagger":` branch in `ItemFactory.create_item()` setting `item.item_id = "dagger"`.
4. Optionally extend tests in `tests/godot/test_item_lookup.gd`.

### Batch consistency (inventory sets)

```
image_gen → sword (style lock)
process_asset.py → assets/generated/items/item_sword_001.png
image_edit (reference sword) → shield, potions, …
process each → review → promote all
update ItemLookup
```

### Current item icons

| `item_id` | Path |
|-----------|------|
| `sword` | `assets/items/sword.png` |
| `shield` | `assets/items/shield.png` |
| `health_potion` | `assets/items/health_potion.png` |
| `mana_potion` | `assets/items/mana_potion.png` |
| `gold_coin` | `assets/items/gold_coin.png` |
| `unknown` | `assets/items/unknown.png` (fallback) |

Items store a stable **`item_id`** (not texture paths) in saves. Display names may
change (e.g. `"Level 3 Iron Sword"`); icons still resolve via `item_id`.

### Prerequisites

- Grok Imagine tools: `image_gen`, `image_edit`
- Python 3 + Pillow: `pip install Pillow`
- Run commands from the **repository root**

### Asset pitfalls

- Staging (`assets/generated/`) is for review; **promote** before relying on paths in code.
- Missing map entry → `ItemLookup` / `PortraitLookup` falls back to default (or null).
- Old saves without `item_id` → empty id → unknown/default icon.
- Prefer transparent cutouts for combat sprites (`*_t.png` where present).
- Do not commit session-only Imagine paths; always copy via `process_asset.py`.

---

## Combat (summary)

```gdscript
GameManager.start_combat()
GameManager.start_boss_combat(player_level)
# turns: player_attack() / player_use_skill(i) → monster_attack()
# end: is_combat_over() → end_combat()
```

Key signals: `combat_started`, `combat_ended`, `player_leveled_up`, `boss_phase_changed`, `boss_defeated`.

---

## Save / Load

```gdscript
GameManager.save_game(slot_number)  # user://save_slot_N.json
GameManager.load_game(slot_number)
```

Models serialize with `to_dict()` / `from_dict()`. Include new fields (e.g. `item_id`)
with safe defaults for old saves.

---

## Testing

```bash
# Prefer full Godot path if `godot` is not on PATH (Windows Steam install example):
# "D:\Steam2TB\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"

godot --headless --path . --script addons/gut/gut_cmdln.gd -gdir=res://tests/godot/ -glog=1 -gexit
godot --headless --path . --script addons/gut/gut_cmdln.gd -gtest=res://tests/godot/test_item_lookup.gd -glog=1 -gexit
```

### Screenshot tour (scene gallery)

Repeatable UI capture after visual changes — wipes and regenerates `screenshots/latest/`:

```powershell
.\tools\Run-ScreenshotTour.ps1
.\tools\Run-ScreenshotTour.ps1 -Archive
```

Steps live in `scripts/tools/ScreenshotTour.gd` (`TOUR`). Output is gitignored.

After adding new scripts/assets, run once with `--import` if GUT ignores a new file.

A successful screenshot tour only proves that captures were produced. After every
visual UI change, open and inspect each affected PNG at full size or with a tight
crop. Compare sibling typography, alignment, spacing, clipping, contrast, and visual
hierarchy before reporting the change complete.

Add regression assertions for style parity between related controls (font size,
theme variation, minimum size, visibility, and similar properties), not only for
node existence or text content.

**Gotchas**

- Headless FPS is low — use generous performance thresholds.
- Do not `await obj.ready` after `add_child` if `_ready` already ran; use `await get_tree().process_frame`.
- Theme inheritance: child `.theme` may be `null`; check `get_theme_color()`.
- Cumulative progress bars may have a non-zero `min_value`; normalize fill and
  accessibility percentages over `(value - min_value) / (max_value - min_value)`.
- Prefer GUT `watch_signals()` / `assert_signal_emitted()`.

---

## Linting

```bash
gdlint scripts/
gdlint tests/
gdlint scripts/utils/ItemLookup.gd
```

Keep zero lint errors on touched files before finishing work.

---

## Web export

```powershell
.\Export-AndServe.ps1              # export + serve
.\Export-AndServe.ps1 -SkipExport  # serve existing build
```

Game URL: `http://localhost:8060/rpg.html` (1280×720). Skill: `web-export`.

---

## Character classes

| Class | Focus |
|-------|--------|
| Hero | Balanced |
| Warrior | Attack / defense |
| Mage | Magic-oriented |
| Rogue | Dexterity |

Set at character creation; skills via `SkillFactory.get_class_skills(class_name)`.

---

## Common tasks

### New item (data + icon)

1. `/imagine-asset item "…"` → process → promote to `assets/items/<id>.png`
2. `ItemFactory.create_item` branch + `item.item_id`
3. `ItemLookup.ITEM_TEXTURES` entry
4. Tests + `gdlint`

### New monster type

1. `MonsterFactory` stats + optional Imagine `monster` art
2. `PortraitLookup.MONSTER_TEXTURES` path
3. Include in random encounter lists if needed

### New UI scene

1. `scenes/ui/….tscn` + `scripts/ui/….gd`
2. Register in `GameManager.change_scene` if navigable by name
3. Theme colors from `UIThemeManager`; style guide compliance

---

## Documentation map

| Doc | Content |
|-----|---------|
| `docs/architecture.md` | Architecture |
| `docs/development-guide.md` | Setup / build |
| `docs/style-guide.md` | Visual style |
| `docs/component-inventory.md` | UI components |
| `docs/backlog.md` | Backlog |
| `docs/asset-inventory.md` | Asset list (may lag; prefer code + `assets/`) |

---

## Git

- Default branch: `main`
- Prefer feature branches; open PRs for review
- Do not commit secrets (`.env`, API keys)

---

## Critical gotchas

1. Null-check `GameManager.game_data.player` before use.
2. Connect manager signals early (`_ready` / init).
3. Combat: respect `GameManager.in_combat`; restore monster from save mid-combat.
4. Skill cooldowns: `GameManager.tick_skill_cooldowns()` after turns.
5. Inventory UI is icon-primary (tooltips hold names); equipment slots use icon + label.
6. Shop sell list maps through inventory indices (holes in bag); do not use list index as inventory index directly.

---

**Last updated**: 2026-07-17  
**Typography**: Cinzel + Source Serif 4 · **Asset pipeline**: Grok Imagine + `.grok/skills/imagine-asset`  
**GUT**: 9.7.1 · **gdtoolkit**: 4.5.0
