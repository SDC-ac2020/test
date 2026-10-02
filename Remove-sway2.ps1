# Detect Win32 (EXE/MSI) MS Sway installs via registry
$win32 = Get-ChildItem -Path `
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", `
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like "Microsoft Sway*" }

# Detect Microsoft Store Appx/MSIX version

$appx = Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*Sway*" -or $_.PackageFullName -like "*Sway*"}


if ($win32 -or $appx) 
    {
    Write-Output "MS Sway installation detected."
    exit 1   # Detection FAILED → Remediation needed
    } 

    Write-Output "MS Sway not found."
    exit 0  # Detection PASSED
    