---
name: generate-asset
description: Generate game assets using Gemini Nano Banana Pro with consistent stylized cartoon style. Use when asked to create monster sprites, character portraits, item icons, UI elements, or background art.
allowed-tools: Bash, Read, Write, Glob, Grep, Edit
argument-hint: "<type> <description> [--variations N] [--transparent] [--dry-run]"
user-invocable: true
---

# Generate Asset Skill

Generate game assets for Pyrpg-Godot using the Gemini Nano Banana Pro API (`gemini-3-pro-image-preview`) with a consistent stylized cartoon art style.

## Current Style Bible

!`type "D:\codeprojects\godot-rpg-refactor\.claude\skills\generate-asset\style-reference.md" 2>nul || echo "STYLE_BIBLE_MISSING"`

## Asset Type Configuration

!`type "D:\codeprojects\godot-rpg-refactor\.claude\skills\generate-asset\asset-types.json" 2>nul || echo "CONFIG_MISSING"`

## Arguments

The user passes: $ARGUMENTS

Parse as follows:
- **First word**: Asset type (`monster`, `character`, `item`, `ui`, `background`, `splash`)
- **Remaining text** (in quotes or not): Description of the asset
- **Optional flags**: `--variations N`, `--transparent`, `--no-transparent`, `--reference <path>`, `--dry-run`, `--update-style`

Examples:
- `/generate-asset monster "fire drake breathing flames"`
- `/generate-asset item health potion glowing green`
- `/generate-asset character "elven mage with crystal staff" --variations 3`
- `/generate-asset background "dark forest clearing at night"`
- `/generate-asset --update-style`

## Workflow

### 1. Check prerequisites

Verify `.env` exists at the project root:

```
D:\codeprojects\godot-rpg-refactor\.env
```

If missing, tell the user:

> Create `D:\codeprojects\godot-rpg-refactor\.env` with your Gemini API key:
> ```
> GEMINI_API_KEY=your_api_key_here
> ```
> Get a key at https://aistudio.google.com/apikey

Then **stop** - do not proceed without the API key.

### 2. Handle --update-style

If the user passed `--update-style`, instead of generating an asset:
1. Read the current `style-reference.md`
2. Read `assets/generated/manifest.json` to see recent generations
3. Ask the user what they want to change about the style
4. Update the non-locked sections of `style-reference.md` (art direction, color guidance, consistency rules)
5. Only update the locked prompt fragments (between `LOCKED_PROMPT_FRAGMENTS_START` and `LOCKED_PROMPT_FRAGMENTS_END`) if the user explicitly confirms
6. Add a revision history entry with today's date and what changed
7. Stop here - do not generate an asset

### 3. Parse arguments

Extract the asset type and description from `$ARGUMENTS`. If the type is not one of: `monster`, `character`, `item`, `ui`, `background`, `splash`, show the valid types and ask the user to clarify.

If no description is provided, ask the user what they want to generate.

### 4. Show the generation plan

Before calling the API, tell the user:
- **Asset type**: e.g., "Monster Sprite (512x512)"
- **Description**: what they asked for
- **Transparent background**: yes/no
- **Output location**: `assets/generated/<subdir>/`

Then proceed to generation.

### 5. Execute generation

Run the Python script:

```bash
python "D:\codeprojects\godot-rpg-refactor\.claude\skills\generate-asset\scripts\generate_asset.py" --type <TYPE> --description "<DESCRIPTION>" --output-dir "D:\codeprojects\godot-rpg-refactor\assets\generated" --project-root "D:\codeprojects\godot-rpg-refactor" [--variations N] [--transparent] [--reference <path>] [--dry-run]
```

**Important**: Always quote the description argument. Escape any quotes in the description.

### 6. Report results

After the script finishes:
1. Parse the JSON output after `=== GENERATION_RESULT ===`
2. Tell the user the file path(s) of generated assets
3. Show the dimensions and file size
4. If the model returned any text notes, share them
5. Read the generated image file(s) to show the user a preview

### 7. Offer promotion

Ask the user if they want to promote any generated asset into the main `assets/` directory. If yes:

1. Determine the target path (e.g., `assets/goblin.png` for a monster, `assets/ui/icons/warrior.png` for a character icon)
2. Copy the file from `assets/generated/<subdir>/` to the target path
3. Update `assets/generated/manifest.json`: set `promoted: true` and `promoted_to: "<target_path>"`
4. Tell the user the asset is now available for use in the game

## Error Handling

- **Script exits with error**: Read stderr output and relay the error message to the user with guidance
- **No image generated**: The model sometimes returns text-only responses. Suggest rephrasing the description or trying again
- **Rate limited**: The script auto-retries 3 times. If it still fails, tell the user to wait a minute and try again
- **Safety filter**: If the content was blocked, suggest a less violent/explicit description

## Notes

- All generated assets go to `assets/generated/` for review before promotion
- The `manifest.json` tracks every generation for reproducibility
- The style bible ensures visual consistency - the same preamble and style keywords are used for every generation
- The script uses only pre-installed Python packages (requests, Pillow, python-dotenv)
- For best consistency when generating related assets (e.g., all monsters), generate them in the same session
- Use `--reference <path>` to pass a previously generated asset as a style exemplar for tighter consistency
