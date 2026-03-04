# =================================================================================================
#  Module:      Cleanup.ps1
#  Path:        .\Install
#  Author:      Rolf Bercht
#  Version:     5.000
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (cleanup utility)
      WallpaperTools.psm1
      ProfileTools.psm1
      TimeTools.psm1
      SystemTools.psm1
      LoggingTools.psm1
      ValidationTools.psm1
      ErrorTools.psm1
============================================================================================ #>

$RepoRoot    = Split-Path $PSScriptRoot -Parent
$ModuleRoot  = Join-Path $RepoRoot "Source\Modules"

# Runtime root is explicitly outside the repo
$RuntimeRoot = "C:\BackgroundMotives"
$RenderRoot  = Join-Path $RuntimeRoot "rendered"
$LogRoot     = Join-Path $RuntimeRoot "logs"

$ExpectedModules = @(
    "SetFlagsTool.psm1",
    "InstallerTools.psm1",
    "RenderTools.psm1",
    "ImageTools.psm1",
    "SchedulerTools.psm1",
    "TaskTools.psm1",
    "CleanupTools.psm1",
    "ConfigTools.psm1",
    "WallpaperTools.psm1",
    "ProfileTools.psm1",
    "TimeTools.psm1",
    "SystemTools.psm1",
    "LoggingTools.psm1",
    "ValidationTools.psm1",
    "ErrorTools.psm1"
)

Write-Host "=== BackgroundModifier Module Verification ==="

if (-not (Test-Path $ModuleRoot)) {
    Write-Host "[ERROR] Module root not found: $ModuleRoot"
    exit 1
}

$ActualModules = Get-ChildItem -Path $ModuleRoot -Filter *.psm1 | Select-Object -ExpandProperty Name

$Missing = $ExpectedModules | Where-Object { $_ -notin $ActualModules }
if ($Missing.Count -gt 0) {
    Write-Host "`n[ERROR] Missing required modules:"
    $Missing | ForEach-Object { Write-Host "  - $_" }
} else {
    Write-Host "`n[OK] All required modules are present."
}

$Obsolete = $ActualModules | Where-Object { $_ -notin $ExpectedModules }
if ($Obsolete.Count -gt 0) {
    Write-Host "`n[INFO] Removing obsolete modules from Source\Modules:"
    foreach ($mod in $Obsolete) {
        $full = Join-Path $ModuleRoot $mod
        try {
            Remove-Item $full -Force
            Write-Host "  [OK] Removed $mod"
        }
        catch {
            Write-Host "  [ERROR] Failed to remove $mod : $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "`n[OK] No obsolete modules found in Source\Modules."
}

$CleanupModule = Join-Path $ModuleRoot "CleanupTools.psm1"
if (Test-Path $CleanupModule) {
    Import-Module $CleanupModule -Force

    Write-Host "`n=== Running CleanupTools against C:\BackgroundMotives (logs + rendered) ==="

    Clear-RenderFolder -RenderRoot $RenderRoot
    Remove-OldLogs     -LogRoot    $LogRoot -Days 7
}
else {
    Write-Host "[ERROR] CleanupTools.psm1 not found. Cannot run cleanup."
}

Write-Host "`n=== Cleanup Complete ==="
