# Pyrpg-Godot Visual Style Guide

## Design Philosophy
Dark fantasy RPG aesthetic - warm candlelight ambiance, weathered materials, medieval atmosphere.
Think: old tavern at night, torchlit dungeon, ancient tome.

## Color System

### Core Palette
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `background` | #141210 | (0.08, 0.07, 0.06) | Screen backgrounds, panels |
| `text_primary` | #F2EBD9 | (0.95, 0.92, 0.85) | Body text, labels |
| `primary_action` | #59401A | (0.35, 0.25, 0.10) | Buttons, interactive elements |
| `secondary` | #948C80 | (0.58, 0.55, 0.50) | Muted text, disabled states |
| `accent` | #D9B359 | (0.85, 0.70, 0.35) | Gold highlights, titles, focus |
| `border_bronze` | #997333 | (0.60, 0.45, 0.20) | Panel borders, dividers |
| `title_gold` | #D9B359 | (0.85, 0.70, 0.35) | Title text (alias for accent) |
| `success` | #73BF73 | (0.45, 0.75, 0.45) | Health high, positive feedback |
| `danger` | #D9594D | (0.85, 0.35, 0.30) | Health low, errors, warnings |

### Semantic Colors
- **Interactive hover**: `primary_action` lightened 15%
- **Interactive pressed**: `primary_action` darkened 20%
- **Disabled**: `secondary` at 50% opacity
- **Focus ring**: `accent` (gold) - 2px outline

### Color Usage Rules
1. Never use pure white (#FFFFFF) - use `text_primary` for warmth
2. Never use pure black (#000000) for backgrounds - use `background`
3. Gold (`accent`) reserved for: titles, focus states, important highlights
4. Bronze (`border_bronze`) for all panel/button borders
5. Danger red only for: health critical, errors, destructive actions

## Typography

### Font Families
| Role | Face | Path |
|------|------|------|
| **Display / headings** | **Cinzel** — classical inscriptional serif | `assets/Cinzel-VariableFont_wght.ttf` |
| **Body / stats / UI copy** | **Source Serif 4** — readable classical companion | `assets/fonts/SourceSerif4-VariableFont_opsz_wght.ttf` |

Both are SIL Open Font License (OFL). Bundle `assets/fonts/OFL-SourceSerif4.txt` with Source Serif 4.

- Cinzel weights: 400 (regular), 600 (semibold), 700 (bold)
- Source Serif 4: prefer Regular/Medium for 12–14px UI on dark backgrounds
- Avoid long all-caps body copy; reserve Cinzel for titles, location names, primary CTAs
- Do **not** use `assets/fonts/default_font.ttf` for new UI body text

### Type Scale
| Style | Size | Face | Usage |
|-------|------|------|-------|
| H1 | 28px | Cinzel | Screen titles |
| H2 | 24px | Cinzel | Section headers |
| H3 | 20px | Cinzel | Subsection headers / location names |
| Body Large | 16px | Cinzel or Source Serif 4 | Primary actions, important text |
| Body Regular | 14px | Source Serif 4 | General content, stats, narrative |
| Caption | 12px | Source Serif 4 | Labels, chips, map marker names |

### Text Styling
- Titles: Gold color (`accent`) with 2px drop shadow
- Body: Parchment color (`text_primary`)
- Always use text shadow on dark backgrounds for readability
- Exploration hub: bright gold borders only for selected markers, focus, and primary CTAs — use subtle 1px separators elsewhere

## Spacing System

8px grid-based spacing:
| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight spacing, icon padding |
| sm | 8px | Default gap between elements |
| md | 16px | Section padding, button padding |
| lg | 24px | Panel margins, major sections |
| xl | 32px | Screen margins, large gaps |

## Component Styling

### Buttons (UIButton)
- Background: Dark brown `Color(0.12, 0.10, 0.08, 0.85)`
- Border: Bronze 2px, `Color(0.50, 0.38, 0.18)`
- Corner radius: 2px (sharp medieval look)
- Min height: 44px (accessibility)
- Hover: Background lightens, border brightens to gold
- Pressed: Background darkens, scale 0.95x

### Panels (PanelContainer)
- Use `frame_main.png` texture with 8px margins
- Or StyleBoxFlat with `background` color, bronze border

### Progress Bars
- Health high: Forest green `success`
- Health medium: Amber (warning)
- Health low: Blood red `danger`
- Background: Very dark, near-black

### Dialogs/Modals
- Center anchored
- Dark panel background with bronze border
- Gold title text
- 16px internal padding

## Animation Guidelines

### Timing
- Micro-interactions: 100ms
- Button feedback: 150ms
- Panel transitions: 300ms
- Screen transitions: 500ms

### Easing
- Enter: ease-out (decelerate)
- Exit: ease-in (accelerate)
- Hover: ease-in-out

### Effects
- Hover: Subtle scale (1.02-1.05x), color brighten
- Press: Scale down (0.95x)
- Background: Subtle grain texture, optional ember glow
- Respect `reduced_motion` accessibility setting

## Shader Effects

### Background Shaders
- Base gradient: Near-black to dark warm brown
- Grain texture: 3% intensity noise overlay
- Ember glow: Orange tint at bottom edge (optional, disable with reduced_motion)
- No bright colors, no tech-looking effects

## Iconography
- Style: Simple, solid fills
- Color: `text_primary` or `accent` for emphasis
- Size: 16px, 24px, 32px standard sizes

## Accessibility Requirements
- All text must meet WCAG AA contrast (4.5:1 minimum)
- Focus indicators must be clearly visible (gold 2px outline)
- Interactive elements minimum 44px touch target
- Support reduced motion preference
