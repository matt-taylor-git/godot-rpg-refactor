# Style Reference - Pyrpg-Godot Asset Generation

## Art Direction

**Target Style**: Stylized cartoon with clean lines, bold colors, and slightly
exaggerated proportions. Graphic novel illustration with hand-painted quality.

**References**: Slay the Spire, Darkest Dungeon (lighter tone), graphic novel illustration.

**NOT**: Photorealistic, anime, pixel art, minimalist flat design, 3D rendered.

## Color Guidance

Assets should use a dark fantasy palette:
- Warm amber/bronze tones for metals, armor, and highlights
- Deep charcoals and warm blacks for shadows (never pure black #000000)
- Rich saturated colors for magical effects (deep blues, emerald greens, crimson reds)
- Off-white parchment tones for light areas (never pure white #FFFFFF)
- Gold tones (#D9B359) for special, legendary, or magical items
- Earth tones (browns, olive greens, rusty oranges) for mundane equipment and creatures

## Visual Consistency Rules

1. **Facing**: Monsters face left (toward player). Characters face right (3/4 view)
2. **Lighting**: Upper-left light source, warm amber-tinted lighting (the quality of candlelight, but do NOT place actual candles, torches, or light sources on or near the subject)
3. **Outlines**: Bold dark outlines (2-3px equivalent at 512px resolution)
4. **Shading**: Cell-shaded with 2-3 distinct value steps, not smooth gradients
5. **Proportions**: Slightly heroic/exaggerated (larger hands, expressive faces, broader shoulders)
6. **Texture**: Hand-painted look with visible brush strokes, not airbrushed or smooth
7. **Mood**: Dark fantasy but not grimdark. Adventurous, mysterious, slightly dangerous

<!-- LOCKED_PROMPT_FRAGMENTS_START -->

## Prompt Fragments (auto-managed - edit with care)

### PREAMBLE
```
Stylized cartoon fantasy RPG game asset. Clean bold outlines, cell-shaded
coloring with 2-3 value steps, slightly exaggerated proportions. Hand-painted
look with visible brushwork. Warm amber-tinted lighting from upper-left (lighting quality only, do NOT add candles, torches, or light sources to the subject). Dark
fantasy aesthetic with rich saturated colors. Graphic novel illustration style
similar to Slay the Spire.
```

### STYLE_KEYWORDS
```
stylized cartoon, bold outlines, cell-shaded, hand-painted, dark fantasy,
graphic novel, game asset, warm lighting, exaggerated proportions,
rich saturated colors, visible brushwork
```

### NEGATIVE_PROMPT
```
Do NOT include: photorealistic rendering, anime style, pixel art, minimalist
flat design, pure white backgrounds, pure black, smooth airbrushed shading,
3D rendered look, stock photo style, watermark, text, signature, blurry,
low quality, deformed hands, extra fingers, candles on character,
torches attached to body, light sources as part of the subject
```

<!-- LOCKED_PROMPT_FRAGMENTS_END -->

## Revision History

- 2026-02-09: Initial style bible created
- 2026-02-10: Clarified "candlelight" means lighting quality only, not literal candles/torches on subjects. Added candles and light sources to negative prompt.
