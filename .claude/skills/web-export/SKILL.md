---
name: web-export
description: Export the Godot RPG to web format and serve it locally for browser testing. Use when you need to build/rebuild the game for web, start the local dev server, or test the game in a browser via agent-browser.
argument-hint: [--skip-export | --export-only | --serve-only | --full]
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
---

# Web Export & Serve Skill

Export the Godot RPG game to HTML5/WASM and serve it locally at `http://localhost:8060/rpg.html` for browser-based testing.

## Arguments

The user may pass arguments: $ARGUMENTS

Interpret them as follows:

| Argument | Meaning |
|----------|---------|
| (none) or `--full` | Full pipeline: export + serve |
| `--skip-export` or `--serve-only` | Skip Godot export, just start the server on existing build |
| `--export-only` | Run Godot export only, don't start the server |
| `--test` | Full pipeline + open with agent-browser to verify the game loads |

## Steps

### 1. Kill any existing server on port 8060

Run this PowerShell to clean up any prior server process:

```powershell
powershell -ExecutionPolicy Bypass -Command "try { Get-NetTCPConnection -LocalPort 8060 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force } } catch {}"
```

### 2. Export the game (unless --skip-export / --serve-only)

Create a temp PowerShell script and execute it. The script must:
- Refresh PATH: `$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')`
- Ensure `webexport/` directory exists
- Run: `godot.windows.opt.tools.64.exe --headless --path "D:\codeprojects\godot-rpg-refactor" --export-release "Web" "D:\codeprojects\godot-rpg-refactor\webexport\rpg.html"`
- Verify exit code is 0
- Verify these files exist in `webexport/`: `rpg.html`, `rpg.wasm`, `rpg.pck`

Report the result to the user (success + file sizes, or failure + error details).

### 3. Start the server (unless --export-only)

Start the Python server as a **background** process:

```bash
python D:\codeprojects\godot-rpg-refactor\serve_web.py --port 8060 --dir D:\codeprojects\godot-rpg-refactor\webexport
```

Use `run_in_background: true` for the Bash tool so the server stays running.

Wait briefly, then read the background task output to confirm `SERVER_READY` appears.

Then verify the server responds:

```powershell
powershell -ExecutionPolicy Bypass -Command "(Invoke-WebRequest -Uri 'http://localhost:8060/rpg.html' -UseBasicParsing).StatusCode"
```

Expected: `200`

### 4. Report to user

Tell the user:
- Whether export succeeded (with file sizes)
- Whether server is running
- The URL: `http://localhost:8060/rpg.html`
- How to stop the server (Ctrl+C or kill the background task)

### 5. Browser test (only if --test argument)

If the user passed `--test`, use the `agent-browser` skill to:
1. Navigate to `http://localhost:8060/rpg.html`
2. Take a screenshot
3. Report what's visible on screen

## Important Notes

- The Godot export preset "Web" is already configured in `export_presets.cfg`
- Threading is disabled in the export (no SharedArrayBuffer required, but COOP/COEP headers are included for future-proofing)
- The `webexport/` directory is gitignored
- Game viewport is 800x600
- The server binds to `127.0.0.1` only (localhost)
- `serve_web.py` sets correct MIME types for `.wasm`/`.pck` and adds COOP/COEP headers automatically

## Troubleshooting

- **Godot not found**: Ensure `D:\Steam2TB\steamapps\common\Godot Engine` is on PATH. The skill refreshes PATH from the environment before running.
- **Export fails**: Check that Godot editor is not open (it locks project files). Close it and retry.
- **Port in use**: The skill kills existing listeners on port 8060 before starting.
- **WASM won't load**: Verify COOP/COEP headers with `curl -I http://localhost:8060/rpg.html`.
