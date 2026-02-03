<#
.SYNOPSIS
    Export the Godot RPG to web format and serve it locally.

.DESCRIPTION
    Orchestrates the full web export pipeline:
    1. Kills any existing server on the target port
    2. Exports the game via Godot CLI (--headless --export-release)
    3. Verifies export artifacts exist
    4. Starts the Python HTTP server with correct WASM headers

.PARAMETER SkipExport
    Skip the Godot export step and only start the server.

.PARAMETER ExportOnly
    Only run the Godot export, don't start the server.

.PARAMETER Port
    Port for the HTTP server (default: 8060).

.EXAMPLE
    .\Export-AndServe.ps1                  # Full rebuild + serve
    .\Export-AndServe.ps1 -SkipExport      # Serve existing build
    .\Export-AndServe.ps1 -ExportOnly      # Export only
#>

param(
    [switch]$SkipExport,
    [switch]$ExportOnly,
    [int]$Port = 8060
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Stop-ExistingServer {
    param([int]$TargetPort)
    try {
        $connections = Get-NetTCPConnection -LocalPort $TargetPort -State Listen -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "Stopping existing process on port ${TargetPort}: $($proc.ProcessName) (PID $($proc.Id))"
                Stop-Process -Id $proc.Id -Force
            }
        }
    }
    catch {
        # No process on the port — nothing to do
    }
}

function Test-GodotAvailable {
    $godot = Get-Command "godot.windows.opt.tools.64.exe" -ErrorAction SilentlyContinue
    if (-not $godot) {
        throw "godot.windows.opt.tools.64.exe not found on PATH. Add 'D:\Steam2TB\steamapps\common\Godot Engine' to your PATH."
    }
    return $godot.Source
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

if (-not $SkipExport) {
    Write-Host "=== Godot Web Export ===" -ForegroundColor Cyan

    $godotExe = Test-GodotAvailable
    Write-Host "Using Godot: $godotExe"

    $exportDir = Join-Path $ProjectRoot "webexport"
    if (-not (Test-Path $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir | Out-Null
        Write-Host "Created $exportDir"
    }

    $exportPath = Join-Path $exportDir "rpg.html"
    Write-Host "Exporting to $exportPath ..."

    try {
        & $godotExe --headless --path $ProjectRoot --export-release "Web" $exportPath 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            throw "Godot export failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Host "ERROR: Godot export failed: $_" -ForegroundColor Red
        exit 1
    }

    # Verify required files
    $requiredFiles = @("rpg.html", "rpg.wasm", "rpg.pck")
    $missing = @()
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $exportDir $file
        if (-not (Test-Path $filePath)) {
            $missing += $file
        }
    }
    if ($missing.Count -gt 0) {
        Write-Host "ERROR: Missing export files: $($missing -join ', ')" -ForegroundColor Red
        exit 1
    }

    Write-Host "Export complete. Files verified." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Serve
# ---------------------------------------------------------------------------

if (-not $ExportOnly) {
    Write-Host ""
    Write-Host "=== Starting Web Server ===" -ForegroundColor Cyan

    Stop-ExistingServer -TargetPort $Port

    $serverScript = Join-Path $ProjectRoot "serve_web.py"
    if (-not (Test-Path $serverScript)) {
        throw "serve_web.py not found at $serverScript"
    }

    $webDir = Join-Path $ProjectRoot "webexport"
    if (-not (Test-Path $webDir)) {
        throw "webexport/ directory not found. Run without -SkipExport first."
    }

    Write-Host "Serving on http://localhost:${Port}/rpg.html"
    Write-Host "Press Ctrl+C to stop."
    Write-Host ""

    try {
        python $serverScript --port $Port --dir $webDir
    }
    catch {
        Write-Host "Server stopped: $_" -ForegroundColor Yellow
    }
}
