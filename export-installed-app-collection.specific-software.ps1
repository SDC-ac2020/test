###############################################################################
# Export Installed Applications (Filtered by Keyword) for SCCM Collection
# Includes BOTH 32-bit and 64-bit software inventory
# Site Server: SDC-SCCM12
# Site Code: SD1
###############################################################################

$SiteCode    = "SD1"
$SiteServer  = "SDC-SCCM12"
$CollectionID = "SD100811"
$OutputFile  = "D:\Scripts\InstalledApplications.csv"

Write-Host "`n--- Starting Export ---`n" -ForegroundColor Cyan

# Prompt user for search keyword
$SearchWord = Read-Host "Enter software name keyword (example: Chrome, Adobe, VPN)"
if ([string]::IsNullOrWhiteSpace($SearchWord)) {
    Write-Host "ERROR: No keyword supplied. Exiting." -ForegroundColor Red
    exit
}

Write-Host "`nFiltering installed apps for names containing: '$SearchWord'" -ForegroundColor Yellow

# Validate collection
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

# Results
$AllApps = @()

foreach ($Device in $Devices) {

    Write-Host " → Processing $($Device.Name)..." -ForegroundColor Gray

    # Query 32-bit software
    $Apps32 = Get-CimInstance -ComputerName $SiteServer `
        -Namespace "root\SMS\site_$SiteCode" `
        -ClassName "SMS_G_System_ADD_REMOVE_PROGRAMS" `
        -Filter "ResourceID = '$($Device.ResourceID)'" `
        -ErrorAction SilentlyContinue

    # Query 64-bit software
    $Apps64 = Get-CimInstance -ComputerName $SiteServer `
        -Namespace "root\SMS\site_$SiteCode" `
        -ClassName "SMS_G_System_ADD_REMOVE_PROGRAMS_64" `
        -Filter "ResourceID = '$($Device.ResourceID)'" `
        -ErrorAction SilentlyContinue

    # Combine both lists
    $InstalledApps = @()
    if ($Apps32) { $InstalledApps += $Apps32 }
    if ($Apps64) { $InstalledApps += $Apps64 }

    if ($InstalledApps) {

        # Filter by keyword (case-insensitive)
        $FilteredApps = $InstalledApps | Where-Object {
            $_.DisplayName -and $_.DisplayName -like "*$SearchWord*"
        }

        foreach ($App in $FilteredApps) {
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
    Write-Host "`nNo applications matched the keyword '$SearchWord'." -ForegroundColor Yellow
} else {
    $AllApps |
        Sort-Object DeviceName, DisplayName |
        Export-Csv -Path $OutputFile -NoTypeInformation

    Write-Host "`nSUCCESS: Export complete!" -ForegroundColor Green
    Write-Host "Output file: $OutputFile`n"
}
