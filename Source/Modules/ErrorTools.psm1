# =================================================================================================
#  Module:      ErrorTools.psm1
#  Path:        .\Source\Modules
#  Author:      Rolf Bercht
#  Version:     5.000
#  Purpose:     Simple, deterministic error helpers without side effects.
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (error handling)
# =================================================================================================

function Throw-ToolError {
    param([string]$Message)
    throw $Message
}

function Write-ToolError {
    param([string]$Message)
    Write-Host "[ERROR] $Message"
}
Export-ModuleMember -Function *
