# =================================================================================================
#  Module:      Setup.ps1
#  Path:        .\Install
#  Author:      Rolf Bercht
#  Version:     5.000
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (installer)
# =================================================================================================

param(
    [switch]$t,
    [switch]$d
)

$ModuleRoot = Join-Path $PSScriptRoot "..\Source\Modules"
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
Import-Module (Join-Path $ModuleRoot "InstallerTools.psm1") -Force

$WarningPreference = $prev

$flags = Set-Flags -T:$t -D:$d
$TraceMode = $flags.TraceMode
$DebugMode = $flags.DebugMode

if ($TraceMode) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $TranscriptPath = Join-Path $Global:LogRoot "Setup_$timestamp.log"
    Start-Transcript -Path $TranscriptPath -Force | Out-Null
}

Write-Host "=== BackgroundModifier Setup Installer (v5.000) ==="

if ($DebugMode) { Write-Host "Debug mode enabled" }
if ($TraceMode) { Write-Host "Trace mode enabled - transcript recording started" }

# TODO: Implement installer per Requirements 4.1
Write-Host "Placeholder: Setup installation to be implemented"
