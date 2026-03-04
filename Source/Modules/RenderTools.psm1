# =================================================================================================
#  Module:      RenderTools.psm1
#  Path:        .\Source\Modules
#  Author:      Rolf Bercht
#  Version:     5.000
#  Purpose:     Shared helpers for image rendering, composition, and deterministic output handling.
#  Changelog:
#      5.000  –  Initial module creation for Consolidated Architecture (text rendering)
# =================================================================================================

function Merge-Image {
    param(
        [string]$BaseImage,
        [string]$OverlayImage,
        [string]$OutputPath
    )

    Add-Type -AssemblyName System.Drawing

    if (-not (Test-Path $BaseImage)) {
        Write-Host "[ERROR] Base image missing: $BaseImage"
        exit 1
    }

    if (-not (Test-Path $OverlayImage)) {
        Write-Host "[ERROR] Overlay image missing: $OverlayImage"
        exit 1
    }

    $base   = [System.Drawing.Image]::FromFile($BaseImage)
    $overlay = [System.Drawing.Image]::FromFile($OverlayImage)

    $bmp = New-Object System.Drawing.Bitmap $base.Width, $base.Height
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)

    $gfx.DrawImage($base, 0, 0, $base.Width, $base.Height)
    $gfx.DrawImage($overlay, 0, 0, $overlay.Width, $overlay.Height)

    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

    $gfx.Dispose()
    $bmp.Dispose()
    $base.Dispose()
    $overlay.Dispose()

    Write-Host "[OK] Rendered -> $OutputPath"
}
    Export-ModuleMember -Function *
