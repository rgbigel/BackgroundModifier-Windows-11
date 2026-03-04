# =================================================================================================
#  Module:      BackgroundRenderer.ps1
#  Path:        .\Source
#  Author:      Rolf Bercht
#  Version:     5.000
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (background rendering)
# =================================================================================================

param(
    [switch]$t,
    [switch]$d
)

$ModuleRoot = Join-Path $PSScriptRoot "Modules"
$prev = $WarningPreference
$WarningPreference = "SilentlyContinue"

Import-Module (Join-Path $ModuleRoot "Constants.psm1") -Force
Import-Module (Join-Path $ModuleRoot "Logging.psm1") -Force
Import-Module (Join-Path $ModuleRoot "TranscriptTools.psm1") -Force
Import-Module (Join-Path $ModuleRoot "PathTools.psm1") -Force
Import-Module (Join-Path $ModuleRoot "ErrorTools.psm1") -Force
Import-Module (Join-Path $ModuleRoot "Validation.psm1") -Force
Import-Module (Join-Path $ModuleRoot "ModeTools.psm1") -Force
Import-Module (Join-Path $ModuleRoot "SummaryTools.psm1") -Force
Import-Module (Join-Path $ModuleRoot "SetFlagsTool.psm1") -Force

$WarningPreference = $prev

$flags = Set-Flags -T:$t -D:$d
$TraceMode = $flags.TraceMode
$DebugMode = $flags.DebugMode

$LogRoot     = $Global:LogRoot
$AssetsRoot  = $Global:AssetsRoot
$RenderRoot  = $Global:RenderRoot

if ($TraceMode) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $TranscriptPath = Join-Path $LogRoot "Renderer_$timestamp.log"
    Start-Transcript -Path $TranscriptPath -Force | Out-Null
}

Write-Host "=== BackgroundModifier Renderer (v1.001) ==="

if ($DebugMode) { Write-Host "Debug mode enabled" }
if ($TraceMode) { Write-Host "Trace mode enabled - transcript recording started" }

$DesktopBase = Join-Path $AssetsRoot "DesktopBase.jpg"
$LogonBase   = Join-Path $AssetsRoot "LogonBase.jpg"

$OutputLogon   = Join-Path $RenderRoot "Logon.jpg"
$OutputDesktop = Join-Path $RenderRoot "Desktop.jpg"

Write-Host "--- Asset check ---"

if (-not (Test-Path $DesktopBase)) {
    Write-Host "[X] Missing DesktopBase -> $DesktopBase"
    if ($TraceMode) { Stop-Transcript | Out-Null }
    exit 1
}

if (-not (Test-Path $LogonBase)) {
    Write-Host "[X] Missing LogonBase -> $LogonBase"
    if ($TraceMode) { Stop-Transcript | Out-Null }
    exit 1
}

Write-Host "[OK] Base assets present"

Write-Host "--- Rendering images ---"

try {
    Copy-Item -Path $LogonBase -Destination $OutputLogon -Force
    Write-Host "[OK] Rendered logon image -> $OutputLogon"

    Copy-Item -Path $DesktopBase -Destination $OutputDesktop -Force
    Write-Host "[OK] Rendered desktop image -> $OutputDesktop"
}
catch {
    Write-Host "[X] Rendering failed: $($_.Exception.Message)"
    if ($TraceMode) { Stop-Transcript | Out-Null }
    exit 1
}

Write-Host "--- Summary ---"
Write-Host "[OK] Rendering completed successfully."

if ($TraceMode) {
    Stop-Transcript | Out-Null
    Write-Host "Log written to: $TranscriptPath"
}
