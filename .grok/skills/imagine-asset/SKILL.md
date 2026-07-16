---
name: imagine-asset
description: >
  Generate game assets (item icons, monsters, UI) with Grok Imagine image_gen
  and image_edit, then chroma-key and promote into assets/. Use when asked to
  generate item icons, inventory art, imagine assets, or /imagine-asset. Does
  not use Gemini.
---

# Imagine Asset

Generate game art with Grok Build Imagine tools and post-process into
inventory-ready transparent PNGs.

**Never use Gemini or `generate_asset.py` for this skill.**

## Prerequisites

- Imagine tools: `image_gen`, `image_edit`
- Python + Pillow
- Style bible: `.grok/skills/imagine-asset/style-reference.md`
- Type config: `.grok/skills/imagine-asset/asset-types.json`

## Arguments

Parse user args as:

- **First word**: type (`item`, `monster`, `ui`)
- **Rest**: subject description
- Optional: `--id <factory_id>` (e.g. `sword`), `--reference <path>`, `--promote`

Examples:

```
/imagine-asset item "sturdy iron longsword with leather-wrapped hilt" --id sword
/imagine-asset item "red health potion" --id health_potion --reference assets/items/sword.png
/imagine-asset item --promote --id sword
```

## Workflow

### 1. Load config

Read `asset-types.json` for size, aspect_ratio, chroma_key, framing, dirs.
Read `style-reference.md` for art direction.

### 2. Build prompt

Subject-first natural prose (2–5 sentences). Include:

- Subject description
- Style (stylized cartoon, bold outlines, cell-shade, hand-painted, dark fantasy)
- Framing from type config
- Solid pure magenta background (`#FF00FF`)
- Warm upper-left lighting on subject only
- No text, no hands holding item (for items)

Do not use long negative-prompt dumps; state what to include.

### 3. Generate

| Case | Tool |
|------|------|
| First of a set / no reference | `image_gen` with type `aspect_ratio` |
| Sibling / style lock | `image_edit` with `image` = reference path(s) |

Describe only subject changes when editing; keep style consistent.

### 4. Process

Run from project root:

```bash
python .grok/skills/imagine-asset/scripts/process_asset.py \
  --source "<path from image_gen/image_edit>" \
  --type item \
  --id sword \
  --description "sturdy iron longsword" \
  --source-tool image_gen
```

By default the script **auto-samples corner pixels** for chroma key (Imagine often
ignores pure `#FF00FF` and paints a flat rose/magenta plate). Override with
`--chroma RRGGBB` if needed. Raise `--tolerance` (default 55) if fringes remain.

This writes `assets/generated/<subdir>/…` and updates `assets/generated/manifest.json`.

### 5. Review

Read the processed PNG with the image viewer (`read_file` on the path).
If chroma fails or silhouette is weak, re-run `image_edit` and process again.

### 6. Promote

After approval:

```bash
python .grok/skills/imagine-asset/scripts/process_asset.py \
  --promote \
  --type item \
  --id sword \
  --from "assets/generated/items/item_sword_001.png"
```

Default promote path: `assets/items/<id>.png` for type `item`.

### 7. Wire into game (when implementing)

Map factory IDs via `ItemLookup` → `res://assets/items/<id>.png`.

## Inventory icon set (MVP IDs)

`sword`, `shield`, `health_potion`, `mana_potion`, `gold_coin`, `unknown`

Batch: generate `sword` first with `image_gen`, then siblings with `image_edit`
using the processed sword as reference.

## Error handling

- Moderation block: stop; do not paraphrase to evade
- Magenta on subject / incomplete key: re-edit with clearer “flat magenta bg only”
- Missing Pillow: `pip install Pillow`
