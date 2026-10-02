###############################################################################
# Query Installed Applications (32 + 64 bit) for a Single Device (Filtered)
# Author: Copilot for Vince
# Site Server: SDC-SCCM12
# Site Code: SD1
###############################################################################

$SiteCode   = "SD1"
$SiteServer = "SDC-SCCM12"
$OutputFile = "D:\Scripts\SingleDevice-InstalledApps.csv"

Write-Host "`n--- SCCM Single Device Software Lookup (32/64-bit) ---`n" -ForegroundColor Cyan

# Prompt user for device name
$DeviceName = Read-Host "Enter device name"
if ([string]::IsNullOrWhiteSpace($DeviceName)) {
    Write-Host "ERROR: No device name supplied. Exiting." -ForegroundColor Red
    exit
}

# Prompt user for software keyword
$SearchWord = Read-Host "Enter software keyword (example: Chrome, Adobe, VPN)"
if ([string]::IsNullOrWhiteSpace($SearchWord)) {
    Write-Host "ERROR: No keyword supplied. Exiting." -ForegroundColor Red
    exit
}

Write-Host "`nSearching for '$SearchWord' on device '$DeviceName'..." -ForegroundColor Yellow

# Try to find the device in SCCM
$Device = Get-CMDevice -Name $DeviceName

if (!$Device) {
    Write-Host "ERROR: Device not found in SCCM: $DeviceName" -ForegroundColor Red
    exit
}

Write-Host "Found device: $($Device.Name) [ResourceID: $($Device.ResourceID)]"

# Query installed applications (32-bit)
$Apps32 = Get-CimInstance -ComputerName $SiteServer `
    -Namespace "root\SMS\site_$SiteCode" `
    -ClassName "SMS_G_System_ADD_REMOVE_PROGRAMS" `
    -Filter "ResourceID = '$($Device.ResourceID)'" `
    -ErrorAction SilentlyContinue

# Query installed applications (64-bit)
$Apps64 = Get-CimInstance -ComputerName $SiteServer `
    -Namespace "root\SMS\site_$SiteCode" `
    -ClassName "SMS_G_System_ADD_REMOVE_PROGRAMS_64" `
    -Filter "ResourceID = '$($Device.ResourceID)'" `
    -ErrorAction SilentlyContinue

# Merge results
$AllApps = @()
if ($Apps32) { $AllApps += $Apps32 }
if ($Apps64) { $AllApps += $Apps64 }

if ($AllApps.Count -eq 0) {
    Write-Host "No installed apps found for this device. Possibly no recent inventory." -ForegroundColor Yellow
    exit
}

# Apply keyword filter
$FilteredApps = $AllApps | Where-Object {
    $_.DisplayName -and $_.DisplayName -like "*$SearchWord*"
}

if ($FilteredApps.Count -eq 0) {
    Write-Host "`nNo applications found matching '$SearchWord' on $DeviceName." -ForegroundColor Yellow
    exit
}

Write-Host "`nFound $($FilteredApps.Count) matching applications:`n" -ForegroundColor Green

# Display results
$FilteredApps | 
    Select-Object DisplayName, Publisher, Version | 
    Format-Table -AutoSize

# Export to CSV
$FilteredApps |
    Select-Object @{Name="DeviceName"; Expression={$Device.Name}},
                  DisplayName, Publisher, Version |
    Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "`nResults exported to: $OutputFile" -ForegroundColor Cyan
Write-Host "`n--- Done ---`n"
