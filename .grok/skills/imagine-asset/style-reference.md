# Style Reference — Imagine Asset Workflow (Pyrpg-Godot)

Adapted for Grok Imagine (`image_gen` / `image_edit`). Use natural prose prompts;
do not dump long negative-keyword lists.

## Art Direction

**Target style**: Stylized cartoon with clean bold outlines, cell-shaded coloring
(2–3 value steps), slightly exaggerated proportions, hand-painted brushwork.
Graphic novel illustration quality similar to Slay the Spire.

**Avoid**: Photorealism, anime, pixel art, flat minimalism, 3D render look.

## Color Guidance

- Warm amber/bronze metals and highlights
- Deep charcoal shadows (never pure black)
- Rich saturated magics (crimson, deep blue, emerald)
- Parchment off-whites for lights (never pure white on the subject)
- Gold (`#D9B359`) for special/legendary accents
- Earth tones for mundane gear

**Critical for chroma key**: Do **not** paint magenta or hot pink on the subject.
Prompt for a solid pure magenta `#FF00FF` plate; if Imagine delivers a flat
rose/magenta instead, `process_asset.py` auto-samples corner pixels as the key.

## Consistency Rules

1. **Items**: Centered object, slight 3/4 angle, fills ~80% of frame, no hands
2. **Lighting**: Warm upper-left key light (quality of candlelight — no torches on subject)
3. **Outlines**: Bold dark outlines, readable at small inventory sizes
4. **Shading**: Cell-shaded, not smooth airbrush gradients
5. **Mood**: Dark fantasy, adventurous — not grimdark

## Combat Battlefield Backgrounds (`combat_bg`)

Exploration location art is a **postcard establishing shot** for the hub card.
Combat needs a separate **side-view battle arena**:

- Solid continuous ground plane in the **lower 35–45%** (dirt, moss, stone, rock)
- Horizon near mid-frame; open left/right zones for player vs monster figures
- Environment frames the edges; dramatic light/fog/embers OK
- **Not** vanishing-path postcards, cliff trails over void, or floating peaks in clouds
- Peak/mountain: fighters stand on a **plateau/ledge**; clouds only beyond the far rim
- No characters, creatures, UI, or text
- Town is a safe hub — no town combat BG; dangerous areas only (forest, mountain, cave, peak)

Prompt template:

> A dark fantasy [area] RPG battle arena background. Stylized cartoon graphic-novel
> illustration with clean bold outlines and cell-shaded coloring. Side-view combat
> stage with a solid continuous ground plane filling the lower third so fighters
> can stand on solid [dirt/stone]. Horizon near mid-frame, open center, trees or
> rock framing the sides. Dramatic atmosphere. No characters, creatures, or text.

## Imagine Prompt Template (items)

Compose 2–5 sentences of prose:

> A [subject], fantasy RPG inventory item icon. Stylized cartoon graphic-novel
> illustration with clean bold outlines and cell-shaded coloring in 2–3 value
> steps, slightly exaggerated proportions, hand-painted brushwork. Dark fantasy
> palette with warm amber and bronze metals. Object centered and slightly angled
> for depth, filling most of the frame. Solid pure magenta background. Warm
> upper-left lighting on the object only. Suitable for a small inventory grid.

## Batch Consistency

1. Generate the first icon with `image_gen` (1:1)
2. Process with chroma key
3. Generate siblings with `image_edit` using the approved first icon as `image`
4. Describe only what changes (new subject); keep style/lighting/outline the same
