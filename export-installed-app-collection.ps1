###############################################################################
# Export Installed Applications for All Devices in an SCCM Collection
# Author: Vince
# Site Server: SDC-SCCM12
# Site Code: SD1
# Must be run from SD1:
###############################################################################

$SiteCode    = "SD1"
$SiteServer  = "SDC-SCCM12"
$CollectionID = "SD100094"
$OutputFile  = "D:\Scripts\InstalledApplications2.csv"

Write-Host "`n--- Starting Export ---`n" -ForegroundColor Cyan

# Check collection exists
$Collection = Get-CMCollection -CollectionId $CollectionID
if (!$Collection) {
    Write-Host "ERROR: CollectionID not found: $CollectionID" -ForegroundColor Red
    exit
}

Write-Host "Using Collection: $($Collection.Name) [$CollectionID]"

# Get devices
$Devices = Get-CMDevice -CollectionId $CollectionID

if ($Devices.Count -eq 0) {
    Write-Host "ERROR: No devices found in this collection." -ForegroundColor Red
    exit
}

Write-Host "Found $($Devices.Count) devices. Querying installed apps..." -ForegroundColor Yellow

# Results container
$AllApps = @()

foreach ($Device in $Devices) {

    Write-Host " → Processing $($Device.Name)..." -ForegroundColor Gray

    # Query Installed Apps (32-bit + 64-bit)
    $InstalledApps = Get-CimInstance -ComputerName $SiteServer `
        -Namespace "root\SMS\site_$SiteCode" `
        -ClassName "SMS_G_System_ADD_REMOVE_PROGRAMS" `
        -Filter "ResourceID = '$($Device.ResourceID)'" `
        -ErrorAction SilentlyContinue

    if ($InstalledApps) {
        foreach ($App in $InstalledApps) {
            $AllApps += [PSCustomObject]@{
                DeviceName   = $Device.Name
                DisplayName  = $App.DisplayName
                Publisher    = $App.Publisher
                Version      = $App.Version
            }
        }
    }
}

if ($AllApps.Count -eq 0) {
    Write-Host "WARNING: No installed applications were returned." -ForegroundColor Yellow
} else {
    $AllApps | Sort-Object DeviceName, DisplayName |
        Export-Csv -Path $OutputFile -NoTypeInformation

    Write-Host "`nSUCCESS: Export complete!" -ForegroundColor Green
    Write-Host "Output file: $OutputFile`n"
}
