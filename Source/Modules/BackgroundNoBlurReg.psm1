# =================================================================================================
#  Module:      BackgroundNoBlurReg.psm1
#  Path:        .\Source\Modules
#  Author:      Rolf Bercht
#  Version:     5.000
#  Changelog:
#      5.000  –  Added registry helper functions to manage logon background blur behavior
# =================================================================================================

function Set-NoBlur {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
    $regName = "DisableLogonBackgroundImage"
    $regValue = 1

    # Check if the registry key exists
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set the registry value to disable the blur effect
    Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force
}

function Remove-NoBlur {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
    $regName = "DisableLogonBackgroundImage"

    # Check if the registry key exists and remove it
    if (Test-Path $regPath) {
        Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
    }
}

# Export the functions for use in other scripts
Export-ModuleMember -Function Set-NoBlur, Remove-NoBlur