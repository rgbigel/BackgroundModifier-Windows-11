# =================================================================================================
#  Module:      Constants.psm1
#  Path:        .\Source\Modules
#  Author:      Rolf Bercht
#  Version:     5.000
#  Purpose:     Centralized constant paths and directory definitions for all components.
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (path constants)
# =================================================================================================

$Global:RootPath    = Split-Path (Split-Path $PSScriptRoot)
$Global:LogRoot     = Join-Path $Global:RootPath "Logs"
$Global:AssetsRoot  = Join-Path $Global:RootPath "Assets"
$Global:RenderRoot  = Join-Path $Global:RootPath "Render"
$Global:SystemRoot  = Join-Path $Global:RootPath "System"
Export-ModuleMember -Function *
