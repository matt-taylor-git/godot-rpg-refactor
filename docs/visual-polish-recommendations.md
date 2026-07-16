# Visual Polish Recommendations

**Date:** 2026-07-16  
**Source:** Screenshot tour (`screenshots/latest/`, 18 screens, 0 failures) + code review  
**Style guide:** `docs/style-guide.md` (dark fantasy: Cinzel, bronze borders, gold accents, parchment text)  
**Tour archive:** `screenshots/runs/20260716_133804/`

This document is the audit deliverable. It prioritizes fixes so polish can ship in focused PRs rather than one mega-change.

---

## Executive summary — top 10

| # | Fix | Severity | Effort | Impact |
|---|-----|----------|--------|--------|
| 1 | **Shared modal shell** — solid dimmer + opaque panel on all dialogs | P0 | M | Stops town bleed-through on shop/quest/skills/codex/game menu |
| 2 | **Dialog enter/exit animations** — slide/scale/fade gated by reduced motion | P1 | M | Menus never hard-pop |
| 3 | **Wire UIButton hover/press animations** | P1 | S | Methods exist but mouse enter only sets a flag |
| 4 | **Shop: unaffordable dimming + stat compare + no text clip** | P1 | M | Core economy UX |
| 5 | **Inventory: equipped glow + rarity borders + empty-state copy** | P1 | M | Clear item state |
| 6 | **Quest log: objective checklist + auto-select first quest** | P1 | M | Empty detail pane on open |
| 7 | **Quest complete: confetti/sparks + gold punch** | P1 | S | Celebration moment |
| 8 | **Dialogue: ▼ continue arrow** (typewriter already solid) | P1 | S | Clear “ready for input” cue |
| 9 | **Combat / world map / end screens themed backgrounds** | P1 | M | Ends flat-gray “prototype” look |
| 10 | **Content bugs:** Warrior `charge` → Unknown Skill; equip double-counts ATK | P0 | S | Correctness + polish |

Also completed as audit infrastructure:

- Main menu now respects reduced motion (buttons no longer invisible in tour).
- Tour seeds inventory, equipment, quests, codex; captures dialogue + quest complete.

---

## Scorecard by screen

Scoring: **0** missing · **1** partial · **2** solid  
Categories: Style · Motion · Feedback · Layout · States · Juice

| Screen | Style | Motion | Feedback | Layout | States | Juice | Notes |
|--------|:-----:|:------:|:--------:|:------:|:------:|:-----:|-------|
| main_menu | 2 | 2 | 1 | 2 | 2 | 1 | Strong art + buttons; hover scale not wired |
| character_creation | 2 | 1 | 1 | 2 | 2 | 0 | Best structured form; default gray bars |
| town | 2 | 1 | 1 | 2 | 1 | 0 | Best hub chrome; no secondary nav footer |
| world_map | 0 | 0 | 1 | 0 | 1 | 0 | Flat gray; two tall stub cards |
| exploration | 1 | 0 | 1 | 2 | 1 | 0 | HUD hierarchy OK; Explore disabled styling weak |
| combat | 1 | 2* | 1 | 2 | 1 | 2* | Portraits strong; *combat VFX exist; flat BG |
| victory | 1 | 0 | 1 | 1 | 1 | 0 | Stats OK; emoji trophies; plain gray |
| game_over | 1 | 0 | 1 | 2 | 1 | 0 | Danger title OK; plain gray |
| shop | 1 | 0 | 1 | 1 | 0 | 1 | Split view good; clip, no compare, translucent |
| inventory | 2 | 0 | 1 | 2 | 1 | 0 | Icons + equip work; no rarity/glow; no open anim |
| skills | 0 | 0 | 1 | 1 | 1 | 0 | Bare list; Unknown Skill; translucent |
| quest_log | 1 | 0 | 1 | 1 | 1 | 0 | Tabs OK; truncated titles; no details until click |
| dialogue | 2 | 2 | 2 | 2 | 2 | 1 | Best dialog polish; text “Select a response…” vs arrow |
| quest_complete | 1 | 0 | 1 | 1 | 1 | 0 | Readable; no celebration |
| options | 1 | 0 | 1 | 1 | 1 | 0 | Sparse placeholder; translucent |
| save_slot | 1 | 0 | 1 | 1 | 1 | 0 | Functional |
| game_menu | 0 | 0 | 1 | 1 | 1 | 0 | Weakest modal; full town visibility |
| codex | 1 | 0 | 1 | 1 | 1 | 0 | Tabs good; no selected entry content in capture |

\*Combat animation controller has particles/damage numbers; screenshot is static start of fight.

---

## Cross-cutting system recommendations

### 1. Dialog shell (P0 / M)

**Problem:** Shop, skills, quest log, game menu, codex, quest complete, options use semi-transparent panels. Town UI bleeds through and kills hierarchy.

**Recommend:** Shared component or scene pattern, e.g. `scripts/components/UIDialogShell.gd` + scene:

- Full-rect dimmer `ColorRect` (~`Color(0.08, 0.07, 0.06, 0.75)`)
- Centered panel: `background` ≥0.95 alpha, 2px `border_bronze`, 2px corner radius, 16px padding
- Optional title label using `title_gold` + shadow
- Optional close control consistently placed

Apply to every modal under `scenes/ui/*_dialog.tscn` and `dialogue_scene` (dialogue already stronger).

### 2. DialogAnimator (P1 / M)

Centralize open/close in one helper (respect `GameSettings.get_reduced_motion()`):

| Dialog family | Open | Close |
|---------------|------|-------|
| Shop, inventory | Slide up 24–40px + fade 300ms ease-out | Reverse ease-in |
| Quest log, codex | Scale 0.92→1.0 + fade | Scale down + fade |
| Game menu, options, skills | Fade + slight scale | Fade out |
| Quest complete | Scale from center + optional burst | Fade |

Reuse patterns from `DialogueScene._animate_panel_in()` and `MainMenu._animate_menu_in()`.

### 3. UIButton tactile feedback (P1 / S)

**Bug:** `play_hover_animation()` / `play_press_animation()` exist, but:

```gdscript
# UIButton.gd — hover never starts
func _on_mouse_entered():
    if not self.disabled:
        is_hovered = true  # missing play_hover_animation()
```

**Fix:**

- Call `play_hover_animation()` on enter / `play_press_animation()` on down
- Set `pivot_offset = size / 2` after layout so scale doesn’t jump
- Load accent from `UIThemeManager.get_accent_color()` (see next)

### 4. UIAnimationSystem theme colors (P1 / S)

`accent_color` is hardcoded teal-ish `Color(0.4, 0.95, 0.84)` — wrong for dark fantasy gold. Initialize from `UIThemeManager` in `_ready()`.

### 5. Theme consistency (P1 / M)

- Migrate remaining plain `Button`s → `UIButton` (open backlog item).
- Character creation / combat bars → `UIProgressBar` with success/danger thresholds.
- Add theme StyleBoxes for `ItemList`, `TabBar`, `LineEdit` so lists match bronze/gold.

### 6. Item rarity (P1 data, then UI / M)

`Item` has no rarity. For color-coded borders:

```gdscript
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
```

Suggested colors (map into theme tokens later):

| Rarity | Border |
|--------|--------|
| Common | bronze |
| Uncommon | success green |
| Rare | cool blue ~#5A8FD9 |
| Epic | purple ~#9B6BD9 |
| Legendary | accent gold |

Wire in `ItemFactory`, inventory slot borders, optional shop list icons.

### 7. Reduced motion discipline (P0 / S)

Main menu fixed. Audit every entrance tween for the same early-return pattern. Screenshot tour forces reduced motion — any future entrance that zeros alpha without restoring will ship invisible UI under accessibility settings.

---

## Per-screen recommendations

### Main menu — P1 polish

**Strengths:** Illustrated background, gold title, clear vertical CTA stack, reduced-motion entrance fixed.

**Recs:**

- Wire UIButton hover scale (system-wide).
- Optional subtle panel vignette so art remains readable without heavy black wash.
- Ensure Options cannot leave reduced-motion desynced with ProjectSettings mid-session (tour log showed `false` after options step).

### Character creation — P1

**Strengths:** Decorative bar, class icons, portrait preview, disabled Start until name entered.

**Recs:**

- Theme stat bars (not default gray ProgressBar).
- Animate class selection (portrait crossfade, bar value tween).
- Keep 8px spacing; already strong layout.

### Town — P1

**Strengths:** Welcome line, gem divider, three readable hub cards.

**Recs:**

- Secondary access (inventory / quests / menu) is only on exploration “More” — consider a compact footer or Escape → game menu on town for discoverability.
- Card hover lift (1.02 scale) when motion allowed.

### World map — P0 visual / M

**Strengths:** Simple two-destination choice.

**Recs:**

- Replace flat gray with themed map BG (parchment or illustrated map).
- Location cards as square/rectangle tiles with icons (town / forest), not full-height bars.
- Locked destinations: dim + lock icon + level requirement tooltip (pattern exists on exploration travel).

### Exploration — P1

**Strengths:** Status HUD (name/HP/gold), atmosphere line, action grid.

**Recs:**

- Stronger disabled style on Explore when not available.
- Atmosphere text could use caption size + secondary color consistently.
- Optional mini HP bar under status text.

### Combat — P1

**Strengths:** Portraits with bronze frames, HP bars, 2×2 action grid, combat animation stack in code.

**Recs:**

- Themed battlefield BG (dungeon/forest) instead of flat gray.
- Combat log panel uses solid panel chrome matching style guide.
- Ensure skill dialog opened mid-combat uses same shell as elsewhere.
- Fix Warrior skill list (below).

### Victory / Game over — P1

**Recs:**

- Replace emoji trophies with `assets/ui` icons.
- Shared “results screen” layout with themed background.
- Victory: soft gold glow / particle burst once (respect reduced motion).
- Game over: subtle desaturate or vignette, not pure flat gray.

### Shop — P1 (high priority)

**Strengths:** Side-by-side For Sale / Your Items; icons; toast feedback on buy/sell.

**Recs:**

| Item | Detail |
|------|--------|
| Modal shell | Opaque panel + dimmer |
| Layout | Wider list columns; no `"..."` clip on prices |
| Gold | Larger, `title_gold`, top-right of panel |
| Unaffordable | Dim row (modulate 0.5) + danger-tinted price |
| Stat compare | When selecting equipment: “ATK +5 → +10 (+5)” vs equipped |
| Juice | Coin fly to gold label + brief scale punch on gold |
| Open anim | Slide + fade |

Files: `scripts/ui/ShopDialog.gd`, `scenes/ui/shop_dialog.tscn`.

### Inventory — P1

**Strengths:** Stats left, equipment slots, icon grid, tooltips with stats, selection gold border, equipped weapon shown.

**Recs:**

| Item | Detail |
|------|--------|
| Equipped glow | Gold border/glow on equipment slots when filled; optional “E” badge on bag item that is equipped |
| Rarity borders | After `Item.rarity` lands |
| Action buttons | Clearer enabled vs disabled (Use/Equip currently look similarly dim) |
| Empty state | If bag empty, centered hint copy |
| Drag-drop | **P2** — click-to-equip is enough for now |
| Rich tooltip | Optional floating panel with rarity color (native tooltip is OK short-term) |
| Open anim | Slide + fade |

**Content bug (P0/S):** `Player.equip_item` applies `attack_bonus` to base `attack`, and `get_attack_power()` also adds weapon bonus → double count (inventory showed ATK 20 for +5 sword). Fix one path only.

Files: `scripts/ui/InventoryDialog.gd`, `scripts/models/Player.gd`.

### Skills — P0 content + P1 UI

**Content bug:** Warrior skills are `["slash", "charge"]` but `create_skill` has no `"charge"` (or `"lightning"`, `"backstab"`) → **Unknown Skill**.

**UI recs:**

- UIButton list with descriptions under names or tooltip
- Cooldown / MP cost color coding
- Modal shell + open animation
- Disable + dim skills that fail `can_use_skill`

Files: `scripts/utils/SkillFactory.gd`, `scripts/ui/SkillsDialog.gd`.

### Quest log — P1

**Strengths:** Active/Completed tabs; seeded quest appears.

**Recs:**

- Auto-select first quest on open / tab change so detail pane is never blank.
- Show full title (no clip); progress `2/5` in list row.
- Objectives as checklist lines with checkmark when met (animate draw on progress events).
- **Failed tab:** skip until quest failure exists in design/data (do not invent).
- Modal shell + scale-in animation.
- Completed tab should show seeded completed quests (verify list refresh).

Files: `scripts/ui/QuestLogDialog.gd`.

### Dialogue — P1 (already strongest)

**Strengths:** Typewriter, skip, panel slide-in, choice stagger, focus, portrait, pulsing hint.

**Recs:**

- Replace “Select a response…” / “Click or Space to continue…” with a **pulsing ▼** (or framed triangle) bottom-right; keep accessible text for screen readers via `tooltip_text` or hidden label.
- Stronger portrait frame (bronze 2px) matching combat portraits.
- Optional name plate bar under portrait.

Files: `scripts/ui/DialogueScene.gd`, `scenes/ui/dialogue_scene.tscn`.

### Quest complete — P1

**Strengths:** Clear title + rewards + OK.

**Recs:**

- Modal shell with solid panel.
- Scale-in from center.
- Short confetti / gold spark `CPUParticles2D` (kill after 0.8s; skip if reduced motion).
- Animate reward numbers counting up.
- Optional checkmark bounce via `UISuccessFeedback` / `UIAnimationSystem.show_success_feedback`.

Files: `scripts/ui/QuestCompletionDialog.gd`.

### Codex — P1

**Strengths:** Category tabs; discovery count; seeded entries.

**Recs:**

- Modal shell (major).
- Auto-select first entry in category so right pane shows content.
- Empty categories: single clear empty state (no dual “Select an entry” / “No entry selected” clutter).
- Entry open: brief fade of body text.

### Options / Save / Game menu — P1

- Same modal shell.
- Game menu: treat as pause overlay with stronger dim (highest urgency after shop).
- Options: remove placeholder-only feel when audio lands; until then, style the reduce-motion row as a proper settings list.

---

## Mapping to requested polish pillars

| Requested pillar | Current | Recommendation |
|------------------|---------|----------------|
| Consistent art style | Partial (town/menu strong; combat/map gray) | Dialog shell + themed BGs + UIButton/theme migration |
| Tweening / animation | Main menu, dialogue, combat; most dialogs pop | `DialogAnimator` per family; respect reduced motion |
| Tactile feedback | StyleBox hover color; scale methods dead | Wire UIButton hover/press; pivot center |
| Smart layouts | Inventory/exploration good; shop clips | Fix ItemList widths; gold emphasis; map cards |
| State changes | Select borders partial | Unaffordable, equipped glow, rarity, disabled skills |
| Juice / particles | Toasts + combat VFX | Shop coins, quest confetti, victory burst |
| Dialogue boxes | Typewriter + pulse text | ▼ indicator; keep typewriter |
| Inventory grids | Icons + tooltips | Rarity, equipped, optional DnD later |
| Shop screens | Split already | Stat compare + afford dim + shell |
| Quest menus | Active/Completed | Checklist + completion juice; no Failed until data |

---

## Suggested PR sequence

| PR | Scope | Effort |
|----|-------|--------|
| **A** Tour fidelity *(done in audit)* | MainMenu reduced motion; tour seed; dialogue/quest_complete steps | S |
| **B** Content bugs | SkillFactory missing skills; equip double-count ATK | S |
| **C** Dialog shell | Dimmer + solid panel on all modals | M |
| **D** Button feedback | Wire hover/press; theme accent color | S |
| **E** DialogAnimator | Open/close motion helper wired to modals | M |
| **F** Shop polish | Compare, afford state, layout, coin juice | M |
| **G** Inventory polish | Equipped glow, rarity data+borders, action clarity | M |
| **H** Quest + dialogue polish | Checklist, auto-select, confetti, ▼ arrow | M |
| **I** Scene theming | Combat/map/victory/game over BGs + bars | M |
| **J** (P2) | DnD inventory, UI SFX, grain shaders | L |

---

## Verification checklist

After each polish PR:

```powershell
.\tools\Run-ScreenshotTour.ps1 -Archive
gdlint scripts/ui/ scripts/components/ scripts/tools/ScreenshotTour.gd
```

Manual:

- [ ] Reduce Motion on: no invisible buttons/menus
- [ ] Shop: can’t-afford dim; buy coin juice; compare shows for weapons
- [ ] Inventory: equip glow; tooltips; no double ATK
- [ ] Dialogue: typewriter + ▼ when waiting
- [ ] Quest complete: particles only if motion allowed
- [ ] Keyboard: focus rings gold on all primary actions

---

## Files reference

| Area | Paths |
|------|-------|
| Tour | `scripts/tools/ScreenshotTour.gd`, `tools/Run-ScreenshotTour.ps1` |
| Style | `docs/style-guide.md`, `resources/ui_theme.tres`, `scripts/globals/UIThemeManager.gd` |
| Buttons / motion | `scripts/components/UIButton.gd`, `UIAnimationSystem.gd`, `UIToast.gd` |
| Dialogs | `scripts/ui/*Dialog*.gd`, `DialogueScene.gd`, matching `scenes/ui/*.tscn` |
| Data | `scripts/models/Item.gd`, `Player.gd`, `ItemFactory.gd`, `SkillFactory.gd`, `QuestFactory.gd` |
| Gallery | `screenshots/latest/`, `screenshots/latest/manifest.json` |

---

## Out of scope (explicit)

- Full audio / UI SFX system
- Designing a Failed-quest mechanic only for a tab
- Replacing Imagine asset pipeline
- Implementing every P1 in a single PR

---

**Next step:** Pick starting PR (**B** content bugs or **C** dialog shell recommended first for player-visible quality). Re-run the screenshot tour after each PR and diff against `screenshots/runs/`.
