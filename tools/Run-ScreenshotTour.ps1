<#
.SYNOPSIS
    Run the Godot scene screenshot tour and write PNGs under screenshots/latest/.

.DESCRIPTION
    Boots the game windowed with --screenshot-tour, which walks scenes and dialogs
    via GameManager and saves an 800x600 gallery. Safe to re-run anytime; each run
    wipes and regenerates screenshots/latest/.

.PARAMETER Archive
    After a successful (or partial) run, copy screenshots/latest to
    screenshots/runs/<yyyyMMdd_HHmmss>/.

.EXAMPLE
    .\tools\Run-ScreenshotTour.ps1
    .\tools\Run-ScreenshotTour.ps1 -Archive
#>

param(
    [switch]$Archive
)

$ErrorActionPreference = "Stop"
# tools/ lives under the repo root
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "project.godot"))) {
    throw "project.godot not found at $ProjectRoot (expected tools/ next to project root)"
}

function Test-GodotAvailable {
    $godot = Get-Command "godot.windows.opt.tools.64.exe" -ErrorAction SilentlyContinue
    if (-not $godot) {
        throw "godot.windows.opt.tools.64.exe not found on PATH. Add Godot Engine to your PATH."
    }
    return $godot.Source
}

Write-Host "=== Screenshot Tour ===" -ForegroundColor Cyan
$godotExe = Test-GodotAvailable
Write-Host "Using Godot: $godotExe"
Write-Host "Project: $ProjectRoot"

$latestDir = Join-Path $ProjectRoot "screenshots\latest"

Write-Host "Launching tour (windowed 800x600)..."
$proc = Start-Process -FilePath $godotExe -ArgumentList @(
    "--path", $ProjectRoot,
    "--resolution", "800x600",
    "--",
    "--screenshot-tour"
) -Wait -PassThru -NoNewWindow

$exitCode = $proc.ExitCode
Write-Host "Godot exit code: $exitCode"

if (-not (Test-Path $latestDir)) {
    Write-Host "ERROR: screenshots/latest was not created." -ForegroundColor Red
    exit 1
}

$pngs = @(Get-ChildItem -Path $latestDir -Filter "*.png" -ErrorAction SilentlyContinue)
$manifestPath = Join-Path $latestDir "manifest.json"
Write-Host "PNGs written: $($pngs.Count) -> $latestDir"

if (Test-Path $manifestPath) {
    Write-Host "Manifest: $manifestPath"
    try {
        $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
        $ok = @($manifest.results | Where-Object { $_.ok }).Count
        $fail = @($manifest.results | Where-Object { -not $_.ok }).Count
        Write-Host "Summary: $ok ok, $fail failed"
        if ($fail -gt 0) {
            $manifest.results | Where-Object { -not $_.ok } | ForEach-Object {
                Write-Host "  FAIL $($_.id): $($_.error)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Could not parse manifest: $_" -ForegroundColor Yellow
    }
}

if ($Archive) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $runDir = Join-Path $ProjectRoot "screenshots\runs\$stamp"
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    Copy-Item -Path (Join-Path $latestDir "*") -Destination $runDir -Recurse -Force
    Write-Host "Archived copy: $runDir" -ForegroundColor Green
}

if ($pngs.Count -eq 0) {
    Write-Host "ERROR: no PNG files produced." -ForegroundColor Red
    exit 1
}

# Prefer Godot exit code; also fail if no success markers
if ($exitCode -ne 0) {
    exit $exitCode
}
exit 0
