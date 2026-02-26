<# ============================================================================================
  Path:       D:\OneDrive\Git_Repositories\PS\BackgroundModifier\Source\Modules
  Module:     Validation.psm1
  Version:    1.000
  Author:     Rolf Bercht

  Purpose:
      Provides reusable validation helpers for scripts and modules.
============================================================================================ #>

function Test-FileExists {
    param(
        [string]$Path
    )

    return (Test-Path $Path)
}
