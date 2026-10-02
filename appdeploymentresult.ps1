###############################################################################
#   SCCM Application Deployment Log Parser
#   Extracts deployment results from AppEnforce.log, AppDiscovery.log,
#   AppIntentEval.log, and exports to CSV
###############################################################################

$LogPath = "\\3082-03\c$\Windows\CCM\Logs"
$OutputCSV = "D:\Scripts\SCCM-AppDeploymentResults.csv"

Write-Host "`n--- Scanning SCCM Logs for Application Deployment Events ---`n" -ForegroundColor Cyan

# Define logs to scan
$Logs = @(
    "AppEnforce.log",
    "AppDiscovery.log",
    "AppIntentEval.log"
)

$Results = @()

foreach ($Log in $Logs) {
    $FullPath = Join-Path $LogPath $Log

    if (Test-Path $FullPath) {

        Write-Host "Reading $Log ..." -ForegroundColor Gray
        
        # CCM Logs use the CMTrace format, so use Select-String
        $Lines = Get-Content $FullPath -Encoding UTF8

        foreach ($Line in $Lines) {

            # Extract CMTrace timestamps [Format: <![LOG[message]LOG]!><Time="xx-xx" Date="xx xx" ...>]
            if ($Line -match 'Time="([^"]+)" Date="([^"]+)"') {
                $Time = $matches[1]
                $Date = $matches[2]
            }

            # Successful enforcement
            if ($Line -match 'Enforcement completed.*successfully|Installation successful') {

                $Results += [PSCustomObject]@{
                    Application    = ($Line -replace '.*LOG\[(.*?)\].*', '$1')
                    Status         = 'Success'
                    LogSource      = $Log
                    Date           = $Date
                    Time           = $Time
                    RawLine        = $Line.Trim()
                }
            }

            # Failed enforcement
            elseif ($Line -match 'Installation failed|enforcement failed|Detection failed') {

                $Results += [PSCustomObject]@{
                    Application    = ($Line -replace '.*LOG\[(.*?)\].*', '$1')
                    Status         = 'Failure'
                    LogSource      = $Log
                    Date           = $Date
                    Time           = $Time
                    RawLine        = $Line.Trim()
                }
            }
        }
    }
}

# Export results
if ($Results.Count -gt 0) {
    $Results |
        Sort-Object Date, Time |
        Export-Csv -Path $OutputCSV -NoTypeInformation

    Write-Host "`nSUCCESS: Deployment results exported to:`n$OutputCSV`n" -ForegroundColor Green
} else {
    Write-Host "`nNo deployment events found in logs.`n" -ForegroundColor Yellow
}
